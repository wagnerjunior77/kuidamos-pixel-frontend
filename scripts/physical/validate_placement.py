"""Valida coordenadas, handoff lógico, PG e resultados da tentativa de placement."""

import re
import sys
from collections import Counter, defaultdict
from pathlib import Path

from validate_floorplan import box, grid, require, table
from validate_powerplan import draw as draw_powerplan
from validate_powerplan import pin_constraints, placement_lines, records, section


def pg_errors(report, rails):
    data = report.read_text()
    rules = Counter(re.findall(r"^Violated rule:\s*(\S+)\s*$", data, re.M))
    layers = Counter(re.findall(r"^Layer:\s*(\S+)\s*$", data, re.M))
    boxes = r"box\s*=\s*\{(-?[0-9.]+) (-?[0-9.]+)\}\s*\{(-?[0-9.]+) (-?[0-9.]+)\}"
    rail_rows = set()
    with_rail = 0
    for item in data.split("=================\n"):
        if not item.startswith("Error type:"):
            continue
        bounds = {tuple(grid(value) for value in match) for match in re.findall(boxes, item)}
        matches = bounds & rails
        with_rail += bool(matches)
        rail_rows.update(matches)
    return rules, layers, with_rail, len(rail_rows)


def check_cells(cells, original, placed, core):
    require(original.keys() == placed.keys() and len(cells) == len(original) == 1256,
            "Inventário lógico de componentes mudou")
    require({row["cell"] for row in cells} == placed.keys(), "Nomes das células divergem do DEF")
    row_cells = defaultdict(list)
    area = 0
    x0, y0, x1, y1 = core
    sw, sh = grid("0.152"), grid("1.672")
    for row in cells:
        name = row["cell"]
        require(original[name][0] == placed[name][0] == row["ref"],
                "Referência de célula mudou: " + name)
        lx, ly, ux, uy = box(row)
        require(x0 <= lx < ux <= x1 and y0 <= ly < uy <= y1 and (ly - y0) % sh == 0 and
                (lx - x0) % sw == 0 and (ux - x0) % sw == 0 and uy - ly == sh,
                "Célula fora do site: " + name)
        coords = placed[name]
        require("+ PLACED" in " ".join(coords) and coords[4:6] == [str(lx), str(ly)],
                "Localização diverge do DEF: " + name)
        row_cells[ly].append((lx, ux))
        area += (ux - lx) * (uy - ly)
    max_row = 0
    for spans in row_cells.values():
        stop = x0
        taken = 0
        for left, right in sorted(spans):
            require(left >= stop, "Sobreposição de células")
            stop = right
            taken += right - left
        max_row = max(max_row, taken / (x1 - x0))
    return area / ((x1 - x0) * (y1 - y0)), len(row_cells), max_row


def draw(path, die, core, cells):
    dx0, dy0, dx1, dy1 = die
    width, height = dx1 - dx0, dy1 - dy0

    def rect(bounds, style):
        x0, y0, x1, y1 = bounds
        return (f'<rect x="{x0 - dx0}" y="{dy1 - y1}" width="{x1 - x0}" '
                f'height="{y1 - y0}" {style}/>')

    image = [f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="-1800 -1800 {width + 3600} {height + 8200}">',
             rect(die, 'fill="#f9fafb" stroke="#203046" stroke-width="150"'),
             rect(core, 'fill="#e9eef5" stroke="#8792a2" stroke-width="120"')]
    for row in cells:
        color = "#bc6127" if row["ref"] == "SDFFX1_RVT" else "#42869a"
        image.append(rect(box(row), f'fill="{color}" stroke="#ffffff" stroke-width="45"'))
    image.append(f'<text x="{width // 2}" y="{height + 3900}" text-anchor="middle" '
                 'font-family="sans-serif" font-size="2350" fill="#203046">'
                 'Combinacionais em azul · SDFFs em laranja · placement exploratório</text>')
    path.write_text("\n".join([*image, "</svg>"]) + "\n", encoding="utf-8")


def expected_pg(original, correction):
    count, wires = section(original, "SPECIALNETS")
    if correction:
        wires, changed = re.subn(r"(^\s*(?:\+ ROUTED|NEW) M1 )152( \+ SHAPE FOLLOWPIN\b)",
                                 r"\g<1>60\2", wires, flags=re.M)
        require(changed == 53, "O DEF de origem não contém os 53 rails esperados")
    return count, wires


def check_readback(run, base, original, result, die, core):
    pg_dir = run / "readback" / "powerplan_corrected"
    pg_def = (pg_dir / "design.def").read_text()
    placement_def = (run / "readback" / "placement_initial" / "design.def").read_text()
    require(placement_lines(pg_def) == placement_lines(original), "Rows/contorno do PG corrigido mudaram")
    for name in ("VIAS", "PINS", "COMPONENTS", "SCANCHAINS"):
        require(section(pg_def, name) == section(original, name), f"Readback PG: seção {name} mudou")
    require(section(pg_def, "SPECIALNETS") == expected_pg(original, True), "Readback PG: geometria inesperada")
    for name in ("VIAS", "PINS", "COMPONENTS", "SCANCHAINS", "SPECIALNETS", "NETS"):
        require(section(placement_def, name) == section(result, name), f"Readback placement: seção {name} mudou")
    require(placement_lines(placement_def) == placement_lines(result), "Rows/contorno mudaram no readback")
    draw_powerplan(run / "powerplan_corrected.svg", die, core, table(pg_dir / "wires.tsv"),
                   table(base / "terminals.tsv"))
    print("CORRECTED_CHECKPOINTS_READBACK_OK")


def validate(run, base, correction=False):
    rpt = run / "reports"
    original = (base / "powerplan.def").read_text()
    result = (rpt / "placement.def").read_text()
    require(placement_lines(original) == placement_lines(result), "Contorno, rows ou tracks mudaram")
    for name in ("PINS", "SCANCHAINS", "VIAS"):
        require(section(original, name) == section(result, name), f"Seção {name} mudou")
    require(section(result, "SPECIALNETS") == expected_pg(original, correction), "Geometria PG inesperada")
    ports = records(result, "PINS")
    signal_ports = [fields for name, fields in ports.items() if name not in {"VDD", "VSS"}]
    require(len(signal_ports) == 126, "Inventário de portas inesperado")
    physical_ports = sum("LAYER" in fields for fields in signal_ports)
    print(f"signal_ports={len(signal_ports)} with_physical_shape={physical_ports}")
    require(pin_constraints((base / "pin_constraints.rpt").read_text()) ==
            pin_constraints((rpt / "pin_constraints.rpt").read_text()), "Restrições de portas mudaram")
    require(not re.search(r"\+\s+(?:ROUTED|FIXED|COVER)\b", section(result, "NETS")[1]),
            "DEF contém roteamento de sinal")

    baseline_geometry = re.findall(r"^DIEAREA\s+([^;]+)", original, re.M)
    vertices = re.findall(r"\(\s*(-?\d+)\s+(-?\d+)\s*\)", baseline_geometry[0])
    xs, ys = zip(*(tuple(map(int, item)) for item in vertices))
    die = min(xs), min(ys), max(xs), max(ys)
    rows = re.findall(r"^ROW\s+\S+\s+unit\s+(-?\d+)\s+(-?\d+)\s+\S+\s+DO\s+(\d+)\s+BY\s+1\s+STEP\s+(\d+)", original, re.M)
    require(len(rows) == 52, "Inventário de rows inesperado")
    rows = [tuple(map(int, item)) for item in rows]
    core = (min(item[0] for item in rows), min(item[1] for item in rows),
            max(x + count * step for x, _, count, step in rows),
            max(item[1] for item in rows) + grid("1.672"))
    cells = table(rpt / "cells.tsv")
    utilization, occupied, max_row = check_cells(cells, records(original, "COMPONENTS"),
                                                  records(result, "COMPONENTS"), core)
    print(f"placed={len(cells)} row_utilization={utilization:.5%} occupied_rows={occupied} max_row_density={max_row:.5%}")
    rails = {box(row) for row in table(base / "wires.tsv") if row["layer"] == "M1"}
    rules, layers, with_rail, rail_count = pg_errors(rpt / "pg_drc.txt", rails)
    drc_report = (rpt / "pg_drc.rpt").read_text()
    if "No errors found." in drc_report:
        require(not rules, "O resumo do PG DRC diverge do relatório detalhado")
    else:
        total = re.search(r"Total number of errors found:\s*(\d+)", drc_report)
        require(total and int(total[1]) == sum(rules.values()) == sum(layers.values()) > 0,
                "Contagem do PG DRC ausente ou divergente")
    print(f"PG DRC: {sum(rules.values())} erros; regras={dict(rules)} camadas={dict(layers)}")
    print(f"Erros com um rail M1 de largura integral: {with_rail}; rails envolvidos: {rail_count}/{len(rails)}")
    draw(run / "placement.svg", die, core, cells)
    if correction and not rules:
        check_readback(run, base, original, result, die, core)
    print("PLACEMENT_PG_DRC_BLOCKED" if rules else "PLACEMENT_VALIDATED")


if __name__ == "__main__":
    try:
        validate(Path(sys.argv[1]), Path(sys.argv[2]), "--correct-m1" in sys.argv[3:])
    except (OSError, ValueError, IndexError, KeyError) as error:
        sys.exit("Placement não validado: " + str(error))
