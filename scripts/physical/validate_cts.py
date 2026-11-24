"""Valida pinos, preservação do scan e árvore de clock exportada pelo FC."""

import csv
import re
import sys
from collections import Counter, defaultdict
from pathlib import Path

from validate_floorplan import require
from validate_powerplan import pin_constraints, placement_lines, records, section


def validate_pins(def_text, constraints):
    pins = records(def_text, "PINS")
    signal = {name: data for name, data in pins.items() if name not in {"VDD", "VSS"}}
    units = re.search(r"^UNITS DISTANCE MICRONS (\d+) ;", def_text, re.M)
    require(units and units[1] == "1000", "Unidade inesperada no DEF")
    die = re.search(r"^DIEAREA (.+) ;", def_text, re.M)
    corners = [(int(x), int(y)) for x, y in re.findall(r"\( (\d+) (\d+) \)", die[1])]
    left, bottom = map(min, zip(*corners))
    right, top = map(max, zip(*corners))
    offsets = defaultdict(list)
    shapes = {}
    require(len(signal) == len(constraints) == 126 and set(signal) == set(constraints),
            "Cobertura de portas de sinal divergente")
    for name, data in signal.items():
        layer, side = constraints[name]
        coords = re.search(r"\+ LAYER (M[34]) \( (-?\d+) (-?\d+) \) \( (-?\d+) (-?\d+) \)"
                           r" \+ (?:PLACED|FIXED) \( (\d+) (\d+) \) N$", " ".join(data))
        require(coords and coords[1] == layer, f"Geometria ou camada incorreta de {name}")
        x0, y0, x1, y1, x, y = map(int, coords.groups()[1:])
        x0, x1, y0, y1 = x + x0, x + x1, y + y0, y + y1
        require(left <= x0 < x1 <= right and bottom <= y0 < y1 <= top,
                f"Shape fora do die: {name}")
        vertical_edge = side in {"1", "3"}
        axis = "Y" if vertical_edge else "X"
        center = (y0 + y1) // 2 if vertical_edge else (x0 + x1) // 2
        track = re.search(rf"^TRACKS {axis} (\d+) DO (\d+) STEP (\d+) LAYER {layer} ;", def_text, re.M)
        start, count, pitch = map(int, track.groups())
        require(0 <= center - start <= (count - 1) * pitch and (center - start) % pitch == 0,
                f"Shape fora da trilha: {name}")
        edges = {"1": (x0, left), "2": (y1, top), "3": (x1, right), "4": (y0, bottom)}
        require(edges[side][0] == edges[side][1], f"Borda incorreta de {name}")
        lo, hi = (bottom, top) if vertical_edge else (left, right)
        require(min(center - lo, hi - center) >= 4 * pitch, f"Pin dentro do keepout: {name}")
        offsets[side].append((center, pitch))
        shapes[name] = (x0, y0, x1, y1)

    for side, positions in offsets.items():
        ordered = sorted(positions)
        require(all(q - p >= 2 * pitch for (p, pitch), (q, _) in zip(ordered, ordered[1:])),
                f"Pinos próximos demais no lado {side}")
    print("PINS_VALIDATED " + " ".join(f"side_{side}={len(offsets[side])}" for side in sorted(offsets)))
    return (left, bottom, right, top), shapes


def instances(text):
    result = {}
    for module, body in re.findall(r"(?ms)^module (\w+)\b(.*?)^endmodule\b", text):
        for ref, instance, pins in re.findall(r"(?ms)^(\w+) (\w+) \(\s*(\..*?)\)\s*;", body):
            result[module, instance] = ref, dict(re.findall(r"\.(\w+)\s*\(\s*(\S+?)\s*\)", pins))
    return result


def validate_clock(baseline, current, chain):
    old = instances(baseline)
    new = instances(current)
    top = "kuidamos_pixel_frontend"
    by_name = {name: pins for (module, name), (ref, pins) in new.items()
               if module == top and ref == "SDFFX1_RVT"}
    require(sum(ref.endswith("_RVT") for ref, _ in old.values()) == 1256 and len(by_name) == 115 and old.keys() <= new.keys(),
            "Inventário lógico inesperado")
    for (module, name), (ref, pins) in old.items():
        current_ref, current_pins = new[module, name]
        ignored = {"CLK"} if ref == "SDFFX1_RVT" else set()
        require(current_ref == ref and {p: n for p, n in current_pins.items() if p not in ignored} ==
                {p: n for p, n in pins.items() if p not in ignored}, f"Referência ou pinos de dados mudaram: {name}")
    for declaration in ("module", "input", "output", "inout", "assign"):
        pattern = rf"(?m)^\s*{declaration}\b[^;]*;"
        require(re.findall(pattern, baseline) == re.findall(pattern, current),
                f"Declarações {declaration} mudaram")

    repeaters = {}
    kinds = Counter()
    for module, name in new.keys() - old.keys():
        ref, pins = new[module, name]
        match = re.fullmatch(r"(NBUFF|INV)X\d+_RVT", ref)
        require(module == top and match and set(pins) == {"A", "Y"}, f"Célula extra inesperada: {name}")
        require(pins["Y"] not in repeaters and pins["Y"] != "clk", "Múltiplos drivers na árvore")
        repeaters[pins["Y"]] = (name, pins["A"], match[1] == "INV")
        kinds[match[1]] += 1
    require(repeaters, "Árvore de clock vazia")
    expected_order = [row["instance"] for row in chain]
    require(len(expected_order) == 115 and len(set(expected_order)) == 115 and
            set(expected_order) == by_name.keys(), "Inventário de scan divergente")
    require([int(row["position"]) for row in chain] == list(range(1, 116)), "Posições de scan inválidas")
    branches = {"clk": []}
    branches.update({net: [] for net in sorted(repeaters)})
    for net, (name, parent, _) in sorted(repeaters.items()):
        require(parent in branches, f"Clock sem raiz em {name}")
        branches[parent].append(name)

    depths = []
    visited = set()
    previous = "scan_in"
    for row in chain:
        name = row["instance"]
        pins = by_name[name]
        require(pins["SI"] == previous and pins["SE"] == "scan_enable", f"Scan mudou em {name}")
        previous = pins[row["SO_pin"]]
        net = pins["CLK"]
        require(net in branches, f"Clock ausente em {name}")
        branches[net].append(name)
        path = set()
        inv = 0
        while net != "clk":
            require(net not in path and net in repeaters, f"Clock desconectado ou cíclico em {name}")
            path.add(net)
            _, net, inverter = repeaters[net]
            inv += inverter
        require(inv % 2 == 0, f"Polaridade de clock mudou em {name}")
        visited.update(path)
        depths.append(len(path))
    require(previous == "scan_out" and visited == repeaters.keys(), "Saída scan ou ramo CTS inconsistente")
    print(f"CLOCK_AND_SCAN_VALIDATED sinks=115 buffers={kinds['NBUFF']} inverters={kinds['INV']} "
          f"max_depth={max(depths)} min_depth={min(depths)} cells={1256 + len(repeaters)}")
    return repeaters, branches


def draw_clock(path, geometry, pins, components, repeaters, branches):
    x0, y0, x1, y1 = geometry
    corners = (x1 - x0, y1 - y0)
    lines = [f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {corners[0]} {corners[1]}">',
             '<rect width="100%" height="100%" fill="#eef3f6"/>']
    positions = {name: (int(x) - x0, y1 - int(y)) for name, data in components.items()
                 for x, y in [re.search(r"\+ (?:FIXED|PLACED) \( (\d+) (\d+) \)", " ".join(data)).groups()]}
    pin = pins["clk"]
    positions["clk"] = ((pin[0] + pin[2]) // 2 - x0, y1 - (pin[1] + pin[3]) // 2)
    for name, (x, y) in sorted(positions.items()):
        lines.append(f'<circle cx="{x}" cy="{y}" r="165" fill="#9aabbd"/>')
    for net, children in branches.items():
        parent = "clk" if net == "clk" else repeaters[net][0]
        a, b = positions[parent]
        for child in children:
            x, y = positions[child]
            lines.append(f'<line x1="{a}" y1="{b}" x2="{x}" y2="{y}" stroke="#195b84" stroke-width="78"/>')
            lines.append(f'<circle cx="{x}" cy="{y}" r="240" fill="#c25b2f"/>')
        lines.append(f'<circle cx="{a}" cy="{b}" r="440" fill="#184569"/>')
    path.write_text("\n".join([*lines, "</svg>"]) + "\n", encoding="utf-8")


def validate(run, base, chain_file, stage):
    report_dir = run / stage / "reports"
    source_def = (base / "reports/placement.def").read_text()
    current_def = (report_dir / "design.def").read_text()
    source_v = (base / "reports/netlist.v").read_text()
    current_v = (report_dir / "netlist.v").read_text()
    constraints = {name: (layer, side) for name, layer, side in
                   pin_constraints((base / "reports/pin_constraints.rpt").read_text())}
    die, pins = validate_pins(current_def, constraints)
    require(placement_lines(current_def) == placement_lines(source_def), "Die, rows ou tracks mudaram")
    require(section(current_def, "SCANCHAINS") == section(source_def, "SCANCHAINS"), "Scan DEF mudou")
    require(section(current_def, "SPECIALNETS") == section(source_def, "SPECIALNETS"), "Geometria PG mudou")
    components = records(current_def, "COMPONENTS")
    require(all(not {"ROUTED", "FIXED", "COVER"} & set(net) for net in records(current_def, "NETS").values()),
            "Geometria de roteamento inesperada em NETS")
    if stage == "pins":
        require(components == records(source_def, "COMPONENTS"), "Placement original mudou")
        require(source_v.split("\nmodule ", 1)[1] == current_v.split("\nmodule ", 1)[1], "Netlist mudou")
        return
    pins_def = (run / "pins/reports/design.def").read_text()
    pin_signals = records(pins_def, "PINS")
    for name, record in records(current_def, "PINS").items():
        before = pin_signals[name]
        if name == "clk":
            before = ["CLOCK" if token == "SIGNAL" else token for token in before]
        require(record == before, f"Porta mudou após CTS: {name}")
    with chain_file.open() as chain:
        repeaters, branches = validate_clock(source_v, current_v, list(csv.DictReader(chain, delimiter="\t")))
    require(len(components) == 1256 + len(repeaters) and
            all({"PLACED", "FIXED"} & set(data) for data in components.values()),
            "Inventário físico de placement divergente")
    if stage == "readback":
        cts_def = (run / "cts/reports/design.def").read_text()
        for name in ("VIAS", "PINS", "COMPONENTS", "SCANCHAINS", "SPECIALNETS", "NETS"):
            require(section(current_def, name) == section(cts_def, name), f"Readback alterou {name}")
        require(instances(current_v) == instances((run / "cts/reports/netlist.v").read_text()),
                "Readback alterou netlist")
        print("CTS_READBACK_VALIDATED")
    else:
        paths = sorted(report_dir.glob("*.global.rpt"))
        require(len(paths) == 12, "Relatórios STA incompletos")
        for path in paths:
            check = path.name.split(".")[-3]
            require(f"No {check} violations found." in path.read_text(), f"Slack negativo em {path.name}")
            timing = (report_dir / path.name.replace(".global", "")).read_text()
            require("slack (MET)" in timing and "clock network delay (propagated)" in timing,
                    f"Sem caminho propagado coberto em {path.name}")
        scan = (report_dir / "scan.rpt").read_text()
        require(re.search(r"VALIDATED\s*:\s*1\b", scan) and re.search(r"FAILED\s*:\s*0\b", scan),
                "Check nativo do Scan DEF falhou")
        draw_clock(run / "cts_tree.svg", die, pins, components, repeaters, branches)


if __name__ == "__main__":
    run, base, chain = map(Path, sys.argv[1:4])
    validate(run, base, chain, sys.argv[4])
