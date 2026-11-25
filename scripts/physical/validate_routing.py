"""Confere o handoff pós-route e desenha as rotas gravadas no DEF."""

import csv
import re
import sys
from collections import Counter, defaultdict
from pathlib import Path

from validate_cts import instances
from validate_floorplan import require
from validate_powerplan import placement_lines, records, section


def transparent(ref):
    # A->Y não inversor nos modelos RVT usados neste fluxo.
    return re.fullmatch(r"(?:NBUFFX\d+|DELLN1X2)_RVT", ref) is not None


def logical_connections(text, cells):
    """Compara terminais, abstraindo nomes de redes e buffers não inversores."""
    result = {}
    for module, body in re.findall(r"(?ms)^module (\w+)\b(.*?)^endmodule\b", text):
        aliases = {}

        def root(net):
            while net in aliases:
                net = aliases[net]
            return net

        local = {name: (ref, pins) for (scope, name), (ref, pins) in cells.items() if scope == module}
        for ref, pins in local.values():
            if transparent(ref):
                require(set(pins) == {"A", "Y"}, "Pinos inesperados em buffer")
                upstream, downstream = root(pins["A"]), root(pins["Y"])
                if upstream != downstream:
                    aliases[downstream] = upstream

        endpoints = defaultdict(set)
        for name, (ref, pins) in local.items():
            if not transparent(ref):
                for pin, net in pins.items():
                    endpoints[root(net)].add((name, pin))
        declarations = re.findall(r"(?m)^(?:input|output|inout)\s+(?:\[(\d+):(\d+)\]\s+)?(\w+)\s*;", body)
        for msb, lsb, name in declarations:
            bits = [f"{name}[{i}]" for i in range(int(lsb), int(msb) + 1)] if msb else [name]
            for bit in bits:
                endpoints[root(bit)].add(("$port", bit))
        result[module] = {frozenset(group) for group in endpoints.values()}
    return result


def validate_netlist(original, routed, chain_file, report=None):
    before = instances(original)
    after = instances(routed)
    for key in before.keys() - after.keys():
        require(transparent(before[key][0]), f"Célula removida fora da lista de buffers: {key}")
    for key in after.keys() - before.keys():
        require(transparent(after[key][0]), f"Célula inserida fora da lista de buffers: {key}")
    changes = []
    for key in sorted(before.keys() | after.keys()):
        old_ref, old_pins = before.get(key, ("-", {}))
        new_ref, new_pins = after.get(key, ("-", {}))
        if old_ref != new_ref or old_pins != new_pins:
            changes.append((*key, old_ref, new_ref, ",".join(sorted(
                pin for pin in old_pins.keys() | new_pins.keys() if old_pins.get(pin) != new_pins.get(pin)))))
        if key in before and key in after and old_ref != new_ref:
            old_family = re.sub(r"X\d+_RVT$", "", old_ref)
            new_family = re.sub(r"X\d+_RVT$", "", new_ref)
            require(old_family == new_family or (transparent(old_ref) and transparent(new_ref)),
                    f"Função de célula alterada: {key}")
    for directive in ("module", "input", "output", "inout", "assign"):
        pattern = rf"(?m)^\s*{directive}\b[^;]*;"
        require(re.findall(pattern, original) == re.findall(pattern, routed), f"Declaração {directive} mudou")
    require(logical_connections(original, before) == logical_connections(routed, after),
            "Conectividade alterada após abstrair buffers não inversores")

    top = "kuidamos_pixel_frontend"
    with chain_file.open() as stream:
        chain = list(csv.DictReader(stream, delimiter="\t"))
    names = {name for (module, name), (ref, _) in after.items() if module == top and ref in {"SDFFX1_RVT", "SDFFX2_RVT"}}
    require(len(chain) == len(names) == 115 and {row["instance"] for row in chain} == names and
            [int(row["position"]) for row in chain] == list(range(1, 116)), "Inventário de scan divergente")
    prev = "scan_in"
    for row in chain:
        key = (top, row["instance"])
        _, pins = after[key]
        baseline_pins = before[key][1]
        require(before[key][0] in {"SDFFX1_RVT", "SDFFX2_RVT"} and all(
            pins.get(pin) == baseline_pins.get(pin) for pin in ("CLK", "SI", "SE", "Q", "QN")
        ), f"Scan ou CLK mudou: {key[1]}")
        require(pins["SI"] == prev and pins["SE"] == "scan_enable", f"Enlace de scan incorreto: {key[1]}")
        prev = pins[row["SO_pin"]]
    require(prev == "scan_out", "Saída da cadeia mudou")
    sizes = Counter(after[top, name][0] for name in names)
    print(f"SCAN_CELL_SIZES X1={sizes['SDFFX1_RVT']} X2={sizes['SDFFX2_RVT']}")
    if report is not None:
        with report.open("w") as stream:
            writer = csv.writer(stream, delimiter="\t", lineterminator="\n")
            writer.writerow(("module", "instance", "baseline_ref", "final_ref", "changed_pins"))
            writer.writerows(changes)
    print(f"ROUTED_NETLIST_VALIDATED sdff=115 added={len(after.keys() - before.keys())} "
          f"removed={len(before.keys() - after.keys())} resized="
          f"{sum(before[key][0] != after[key][0] for key in before.keys() & after.keys())}")


def geometry(def_text, kinds):
    """Extrai segmentos e vias da sintaxe de rotas escrita pelo FC em DEF."""
    paths = defaultdict(list)
    vias = defaultdict(set)
    for section_name in ("NETS", "SPECIALNETS"):
        for raw in section(def_text, section_name)[1].split(";"):
            name = raw.split()[1] if raw.strip() else ""
            if name not in kinds:
                continue
            kind = kinds[name]
            for layer, path in re.findall(r"(?m)^\s*(?:\+ (?:ROUTED|FIXED|COVER)|NEW) (M\d+) ([^\n]+)", raw):
                point = None
                for token in re.finditer(r"\(\s*(-?\d+|\*)\s+(-?\d+|\*)(?:\s+\d+)?\s*\)|\b(VIA\w+)", path):
                    x, y, via = token.groups()
                    if via:
                        require(point is not None, f"Via sem coordenadas em {name}")
                        vias[kind].add((*point, via))
                        adjacent = re.match(r"VIA(\d)(\d)", via)
                        if adjacent and layer[-1] in adjacent.groups():
                            layer = "M" + next(i for i in adjacent.groups() if i != layer[-1])
                        continue
                    other = (point[0] if x == "*" else int(x), point[1] if y == "*" else int(y))
                    if point is not None and point != other:
                        paths[kind, layer].append((*point, *other))
                    point = other
    return paths, vias


def draw(path, def_text, kinds, clock_only=False):
    routes, vias = geometry(def_text, kinds)
    maximum = re.search(r"(?m)^DIEAREA (.*) ;", def_text)[1]
    points = [(int(x), int(y)) for x, y in re.findall(r"\( (\d+) (\d+) \)", maximum)]
    width, height = map(max, zip(*points))
    colors = {1: "#596385", 2: "#347a94", 3: "#239878", 4: "#9a8136", 5: "#bb6840", 6: "#903f62"}
    image = [f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {width} {height}">',
             '<rect width="100%" height="100%" fill="#f5f8fa"/>']
    for kind in ("pg", "signal", "clock"):
        if kind == "signal" and clock_only:
            continue
        for (family, layer), lines in sorted(routes.items()):
            if kind != family:
                continue
            color = {"pg": "#7f8a96", "signal": colors.get(int(layer[1:]), "#675886"),
                     "clock": "#981b44"}[kind]
            weight = {"pg": 110, "signal": 35, "clock": 135}[kind]
            coordinates = " ".join(f"M{x},{height - y}L{p},{height - q}" for x, y, p, q in lines)
            image.append(f'<path aria-label="{kind} {layer}" d="{coordinates}" fill="none" '
                         f'stroke="{color}" stroke-width="{weight}"/>')
    for x, y, _ in sorted(vias["clock"]):
        image.append(f'<circle cx="{x}" cy="{height-y}" r="135" fill="#681132"/>')
    path.write_text("\n".join([*image, "</svg>"]) + "\n", encoding="utf-8")
    clock_layers = sorted(layer for kind, layer in routes if kind == "clock")
    counts = Counter(via for x, y, via in vias["clock"])
    print(f"PHYSICAL_CLOCK layers={','.join(clock_layers)} vias={sum(counts.values())} "
          + " ".join(f"{name}={n}" for name, n in sorted(counts.items())))


def verify_exports(reports):
    for suffix, label in (("hold", "hold"), ("setup", "setup")):
        reports_sta = sorted(reports.glob(f"*.{suffix}.global.rpt"))
        require(len(reports_sta) == 6, "STA incompleta")
        for path in reports_sta:
            require(f"No {label} violations found." in path.read_text(), f"Violações temporais em {path.name}")
            timing = (reports / path.name.replace(".global", "")).read_text()
            require("clock network delay (propagated)" in timing and "slack (MET)" in timing,
                    f"STA sem caminho propagado coberto em {path.name}")
    spefs = sorted(reports.glob("*.spef"))
    require(len(spefs) == 4, "SPEF Cmin/Cmax incompleto")
    for path in spefs:
        content = path.read_text()
        count = len(re.findall(r"(?m)^\*D_NET .* //LENGTH .* DR\s*$", content))
        require(count > 1400 and "*RES\n" in content and "*CAP\n" in content,
                f"Extração de rotas ausente: {path.name}")
        print(f"SPEF_VALIDATED {path.name} detail_routed_nets={count}")
    sdfs = sorted(reports.glob("*.sdf"))
    require(len(sdfs) == 4 and all("(INTERCONNECT " in path.read_text() for path in sdfs),
            "SDF de interconexão incompleto")


def validate(run, baseline, chain, stage):
    reports = run / stage / "reports"
    original_def = (baseline / "readback/reports/design.def").read_text()
    original_v = (baseline / "readback/reports/netlist.v").read_text()
    routed = (reports / "design.def").read_text()
    netlist = (reports / "netlist.v").read_text()
    require(placement_lines(original_def) == placement_lines(routed), "Die, rows ou tracks mudaram")
    for key in ("PINS", "SCANCHAINS"):
        require(records(original_def, key) == records(routed, key), f"{key} mudou")
    require(section(routed, "SCANCHAINS") == section((reports / "scan.def").read_text(), "SCANCHAINS"),
            "Scan DEF separado divergiu")

    specials = records(routed, "SPECIALNETS")
    old_power = records(original_def, "SPECIALNETS")
    require(all(specials[name] == old_power[name] for name in ("VDD", "VSS")), "Geometria PG mudou")
    nets = records(routed, "NETS")
    clocks = {name for name, data in nets.items() if "CLOCK" in data}
    require(len(clocks) == 6, "Quantidade de redes de clock divergente")
    original_nets = records(original_def, "NETS")
    if all("ROUTED" in original_nets.get(name, ()) for name in clocks):
        require(all(nets[name] == original_nets[name] and
                    specials.get(name) == old_power.get(name) for name in clocks),
                "Geometria do clock já roteado mudou")
        print("ROUTED_CLOCK_GEOMETRY_MATCH")
    routed_nets = {name for name, data in nets.items() if
                   {"ROUTED", "FIXED", "COVER"} & set(data + specials.get(name, []))}
    require(clocks <= routed_nets, "Clock sem rota gravada")
    if stage == "clock":
        require(routed_nets == clocks, "Geometria de sinais inesperada na primeira etapa")
    else:
        unloaded = set(nets) - routed_nets
        require(unloaded == {"in_sol", "in_eol"} and all(
            nets[name] == ["(", "PIN", name, ")", "+", "USE", "SIGNAL"] for name in unloaded
        ), f"Redes efetivamente sem roteamento: {sorted(unloaded)}")
    print(f"ROUTES_VALIDATED clock={len(clocks)} routed={len(routed_nets)} logical_nets={len(nets)}")

    validate_netlist(original_v, netlist, chain, reports / "eco.tsv")
    if stage == "readback":
        final_reports = run / "signals/reports"
        final_def = (final_reports / "design.def").read_text()
        for key in ("COMPONENTS", "VIAS", "NETS", "SPECIALNETS"):
            require(records(final_def, key) == records(routed, key), f"Readback alterou {key}")
        require(instances(netlist) == instances((final_reports / "netlist.v").read_text()), "Netlist mudou no readback")
        print("ROUTING_READBACK_VALIDATED")
    else:
        power = {"VDD", "VSS"}
        kinds = {name: "pg" if name in power else "clock" if name in clocks else "signal"
                 for name in nets.keys() | power}
        draw(run / f"{stage}_layout.svg", routed, kinds, clock_only=(stage == "clock"))
        if stage == "signals":
            verify_exports(reports)


if __name__ == "__main__":
    run_path, base_path, chain_path = map(Path, sys.argv[1:4])
    validate(run_path, base_path, chain_path, sys.argv[4])
