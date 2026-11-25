"""Confere o handoff físico de PG e gera uma planta da rede exportada pelo FC."""

import re
import sys
from collections import Counter
from pathlib import Path

from validate_floorplan import box, grid, require, table


def section(def_text, name):
    match = re.search(rf"^{name} (\d+)\s*;(.+?)^END {name}\b", def_text, re.M | re.S)
    require(match, f"Seção {name} ausente")
    return int(match[1]), match[2]


def records(def_text, section_name):
    count, data = section(def_text, section_name)
    rows = [line.split() for line in data.split(";") if line.strip()]
    require(count == len(rows), f"Contagem divergente em {section_name}")
    return {row[1]: row[2:] for row in rows}


def placement_lines(def_text):
    return re.findall(r"^(?:UNITS|DIEAREA|ROW|TRACKS) .+;", def_text, re.M)


def pin_constraints(report):
    return re.findall(r"^  (\S+):\n    \{allowed_layers \{(M[34])\}\} \{sides \{([1-4])\}\}",
                      report, re.M)


def summarize_geometry(stage, baseline):
    data = (stage / "powerplan.def").read_text()
    require(placement_lines(data) == placement_lines(baseline), "Contorno, rows ou tracks mudaram")
    require(records(data, "COMPONENTS") == records(baseline, "COMPONENTS"), "Componentes do DEF mudaram")
    require(section(data, "SCANCHAINS") == section(baseline, "SCANCHAINS"), "Cadeia do Scan DEF mudou")
    require(section(data, "SPECIALNETS")[0] == 2, "Quantidade incorreta de redes especiais")
    pg_ports = records(data, "PINS")
    for rail, use in (("VDD", "POWER"), ("VSS", "GROUND")):
        port = pg_ports.pop(rail, [])
        require(port[:2] == ["+", "NET"] and port[2] == rail and use in port and port.count("PORT") == 2,
                f"Acesso externo {rail} ausente")
    require(pg_ports == records(baseline, "PINS"), "Portas funcionais/scan mudaram")
    return tuple(sorted(Counter(tuple(sorted(row.items())) for row in table(stage / name)).items())
                 for name in ("wires.tsv", "vias.tsv", "terminals.tsv"))


def draw(path, die, core, wires, terminals):
    dx0, dy0, dx1, dy1 = die
    x0, y0, x1, y1 = core
    width, height = dx1 - dx0, dy1 - dy0
    border = 2000
    colors = {"VDD": "#ad162d", "VSS": "#245db5"}

    def rect(bounds, attributes):
        left, bottom, right, top = bounds
        return (f'<rect x="{left - dx0}" y="{dy1 - top}" width="{right - left}" '
                f'height="{top - bottom}" {attributes}/>')

    svg = [f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="-{border} -{border} '
           f'{width + 2 * border} {height + 8500}">',
           rect(die, 'fill="#fbfcfe" stroke="#283649" stroke-width="160"'),
           rect((x0, y0, x1, y1), 'fill="#f0f3f8" stroke="#a0aec0" stroke-width="110"')]
    for wire in sorted(wires, key=lambda row: row["layer"]):
        opacity = "0.46" if wire["layer"] == "M1" else "0.90"
        svg.append(rect(box(wire), f'fill="{colors[wire["net"]]}" opacity="{opacity}"'))
    for terminal in terminals:
        svg.append(rect(box(terminal), 'fill="#eef2f6" stroke="#151d2a" stroke-width="145"'))
    svg.append(f'<text x="{width // 2}" y="{height + 4400}" text-anchor="middle" '
               'font-family="sans-serif" font-size="2250">'
               '<tspan fill="#ad162d">VDD</tspan> · <tspan fill="#245db5">VSS</tspan>'
               ' · M1 rails, M5/M6 mesh, M7/M8 rings</text>')
    path.write_text("\n".join([*svg, "</svg>"]) + "\n", encoding="utf-8")


def validate(run, floorplan):
    base = (floorplan / "floorplan.def").read_text()
    stages = run / "build", run / "readback"
    models = [summarize_geometry(stage, base) for stage in stages]
    require(models[0] == models[1], "Geometria PG diverge após reabrir a base")
    pin_plan = pin_constraints((floorplan / "pin_constraints.rpt").read_text())
    require(len(pin_plan) == 126, "Plano de portas incompleto")
    for stage in stages:
        require(pin_constraints((stage / "pin_constraints.rpt").read_text()) == pin_plan,
                "O plano de acesso às portas mudou")

    build = stages[0]
    wires, vias, terminals = (table(build / name) for name in ("wires.tsv", "vias.tsv", "terminals.tsv"))
    geometry = {row["area"]: box(row) for row in table(floorplan / "geometry.tsv")}
    dx0, dy0, dx1, dy1 = geometry["die"]
    x0, y0, x1, y1 = geometry["core"]
    for row in (*wires, *vias, *terminals):
        xlo, ylo, xhi, yhi = box(row)
        require(dx0 <= xlo < xhi <= dx1 and dy0 <= ylo < yhi <= dy1, "Objeto PG fora do die")
    for via in vias:
        if {via["lower"], via["upper"]} & {"M3", "M4"}:
            xlo, ylo, xhi, yhi = box(via)
            # As rows externas ficam nos limites Y do core. A via pode
            # cobrir a largura do rail em torno desses limites.
            half_rail = grid("0.152") // 2
            require(x0 <= xlo < xhi <= x1 and y0 - half_rail <= ylo < yhi <= y1 + half_rail,
                    "Via PG invade a região periférica M3/M4")
    require(not any(wire["layer"] in {"M3", "M4"} for wire in wires),
            "Segmento PG na camada de acesso dos sinais")
    for net in ("VDD", "VSS"):
        layer_counts = Counter(row["layer"] for row in wires if row["net"] == net)
        require(set(layer_counts) == {"M1", "M5", "M6", "M7", "M8"} and
                layer_counts["M7"] == layer_counts["M8"] == 2, "Estrutura de anel inesperada")
        require(sum(term["net"] == net for term in terminals) == 2, "Terminais inesperados")
        via_counts = Counter((row["lower"], row["upper"]) for row in vias if row["net"] == net)
        require(set(via_counts) == {(f"M{k}", f"M{k + 1}") for k in range(1, 8)},
                "Pilha PG incompleta")
        print(f"{net}: 1 ring ({layer_counts['M7'] + layer_counts['M8']} segmentos), "
              f"{layer_counts['M5'] + layer_counts['M6']} straps, {layer_counts['M1']} rails, "
              f"{sum(via_counts.values())} vias, 2 terminais")
        print("  Vias por transição:", ", ".join(f"{lo}/{hi}={n}" for (lo, hi), n in sorted(via_counts.items())))
    rail_area = sum((xhi - xlo) * (yhi - ylo)
                    for xlo, ylo, xhi, yhi in (box(wire) for wire in wires if wire["layer"] == "M1"))
    require(sum(wire["layer"] == "M1" for wire in wires) == 53, "Trilhos não cobrem as 52 rows")
    print(f"Área geométrica dos rails M1 = {rail_area / 1e6:.4f} µm²")
    draw(run / "powerplan.svg", geometry["die"], geometry["core"], wires, terminals)
    print("POWERPLAN_VALIDATED")


if __name__ == "__main__":
    try:
        validate(Path(sys.argv[1]), Path(sys.argv[2]))
    except (OSError, ValueError, IndexError, KeyError) as error:
        sys.exit("Power plan não validado: " + str(error))
