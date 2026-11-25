"""Confere a geometria do FC com o DEF e desenha a planta resultante."""

import csv
import re
import sys
from collections import Counter
from decimal import Decimal
from pathlib import Path


def table(path):
    with path.open() as source:
        return list(csv.DictReader(source, delimiter="\t"))


def require(condition, message):
    if not condition:
        raise ValueError(message)


def grid(value):
    dbu = Decimal(value) * 1000
    require(dbu == int(dbu), "Coordenada fora da grade de 1 nm: " + value)
    return int(dbu)


def box(row):
    return tuple(grid(row[key]) for key in ("x0", "y0", "x1", "y1"))


def orient(value):
    return {"R0": "N", "MX": "FS", "N": "N", "FS": "FS"}[value]


def inspect(dirpath, site, plan):
    geometry = {row["area"]: box(row) for row in table(dirpath / "geometry.tsv")}
    require(set(geometry) == {"die", "core"}, "Contornos incompletos")
    dx0, dy0, dx1, dy1 = geometry["die"]
    x0, y0, x1, y1 = geometry["core"]
    sw, sh = grid(site["width"]), grid(site["height"])
    require(x1 - x0 == grid(plan["width_um"]) and y1 - y0 == grid(plan["height_um"]),
            "Dimensões do core diferem do plano ligado à grade")
    mx, my = grid(plan["xmargin_um"]), grid(plan["ymargin_um"])
    require((x0 - dx0, y0 - dy0, dx1 - x1, dy1 - y1) == (mx, my, mx, my),
            "Margens do die diferem do plano")
    require(x0 % sw == x1 % sw == y0 % sh == y1 % sh == 0,
            "Core desalinhado ao site")
    rows = sorted(table(dirpath / "rows.tsv"), key=lambda row: grid(row["y0"]))
    require(len(rows) == (y1 - y0) // sh and len(rows) > 0, "Número incorreto de rows")
    expected = []
    last_orientation = None
    for index, row in enumerate(rows):
        _, ry0, _, ry1 = box(row)
        require(box(row) == (x0, y0 + index * sh, x1, y0 + (index + 1) * sh),
                "Row se sobrepõe ou deixa lacuna")
        require(orient(row["row_orient"]) == "N", "Eixo da row não é horizontal")
        row_orientation = orient(row["site_orient"])
        sites = int(row["sites"])
        require(row["site"] == "unit" and row_orientation != last_orientation and
                sites * sw == x1 - x0 and ry1 - ry0 == sh, "Site ou orientação incorreta")
        expected.append((row["row"], "unit", x0, ry0, row_orientation, sites, 1, sw, 0))
        last_orientation = row_orientation

    data = (dirpath / "floorplan.def").read_text()
    require(re.search(r"^UNITS DISTANCE MICRONS 1000\s*;", data, re.M), "Unidade DEF incompatível")
    die = re.search(r"^DIEAREA\s+([^;]+);", data, re.M)
    require(die, "DIEAREA ausente")
    vertices = {tuple(map(int, pair)) for pair in re.findall(r"\(\s*(-?\d+)\s+(-?\d+)\s*\)", die[1])}
    corners = {(dx0, dy0), (dx0, dy1), (dx1, dy0), (dx1, dy1)}
    require(vertices in ({(dx0, dy0), (dx1, dy1)}, corners), "DIEAREA diverge do FC")
    pattern = r"^ROW\s+(\S+)\s+(\S+)\s+(-?\d+)\s+(-?\d+)\s+(\S+)\s+DO\s+(\d+)\s+BY\s+(\d+)\s+STEP\s+(\d+)\s+(\d+)\s*;"
    def_rows = [(name, site_name, int(x), int(y), orientation, int(nx), int(ny), int(sx), int(sy))
                for name, site_name, x, y, orientation, nx, ny, sx, sy in re.findall(pattern, data, re.M)]
    require(sorted(def_rows) == sorted(expected), "Rows do DEF divergem dos objetos FC")
    tracks = {}
    track_pattern = r"^TRACKS\s+([XY])\s+(-?\d+)\s+DO\s+(\d+)\s+STEP\s+(\d+)\s+LAYER\s+(\S+)\s*;"
    for axis, offset, count, pitch, layer in re.findall(track_pattern, data, re.M):
        tracks[layer, axis] = tuple(map(int, (offset, count, pitch)))
    require(all((f"M{number}", axis) in tracks for number in range(1, 10) for axis in "XY"),
            "Tracks ausentes em M1–M9")
    for (_, axis), (offset, count, pitch) in tracks.items():
        low, high = (dx0, dx1) if axis == "X" else (dy0, dy1)
        require(count > 0 and pitch > 0 and low <= offset <= offset + (count - 1) * pitch <= high,
                "Tracks inválidas ou fora do die")
    require(not re.search(r"\+\s+(?:PLACED|FIXED|COVER)\b", data), "DEF contém objeto colocado")
    require(re.search(r"^COMPONENTS 1256\s*;", data, re.M) and
            len(re.findall(r"\+ UNPLACED\s*;", data)) == 1256, "Inventário físico DEF divergente")
    pins = re.search(r"^PINS (\d+)\s*;(.+?)^END PINS", data, re.M | re.S)
    require(pins and int(pins[1]) == len(re.findall(r"^\s*-\s+(\S+)\s+\+ NET", pins[2], re.M)),
            "Inventário de portas DEF ausente ou incompleto")
    require(re.search(r"^SCANCHAINS 1\s*;", data, re.M) and "+ START PIN scan_in" in data and
            "+ STOP PIN scan_out" in data and
            len(re.findall(r"\( IN SI \) \( OUT QN? \)", data)) == 115, "Scan DEF físico divergente")
    return geometry, expected, tracks


def draw(path, geometry, rows, ports):
    dx0, dy0, dx1, dy1 = geometry["die"]
    x0, _, x1, _ = geometry["core"]
    die_width = dx1 - dx0
    die_height = dy1 - dy0
    pad = max(die_width, die_height) // 6
    width = die_width + 2 * pad
    height = die_height + 2 * pad
    counts = Counter(row["side"] for row in ports)
    drawings = [f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {width} {height}">',
                f'<rect width="{width}" height="{height}" fill="#f8fafc"/>',
                f'<rect x="{pad}" y="{pad}" width="{die_width}" height="{die_height}" '
                'fill="#dbeafe" stroke="#1e3a5f" stroke-width="250"/>']
    site_height = (geometry["core"][3] - geometry["core"][1]) // len(rows)
    for index, row in enumerate(rows):
        y0 = row[3]
        color = "#a7d8d1" if index % 2 else "#d2ebe6"
        drawings.append(f'<rect x="{pad + x0 - dx0}" y="{pad + dy1 - y0 - site_height}" '
                        f'width="{x1 - x0}" height="{site_height}" fill="{color}"/>')
    drawings.append('<g text-anchor="middle" font-family="sans-serif" font-size="2600" fill="#153047">')
    for x, y, text in (
        (width // 2, pad // 2, f"Clock, reset e scan · {counts['2']} em M4"),
        (width // 2, height - pad // 3, f"Configuração · {counts['4']} em M4"),
        (pad // 2, height // 2, f"In · {counts['1']}"),
        (width - pad // 2, height // 2, f"Out · {counts['3']}"),
        (width // 2, height // 2, f"Core · {len(rows)} site rows"),
    ):
        drawings.append(f'<text x="{x}" y="{y}">{text}</text>')
    drawings.append("</g></svg>")
    path.write_text("\n".join(drawings) + "\n", encoding="utf-8")


def validate(run):
    build = run / "build"
    site, = table(build / "site.tsv")
    plan, = table(build / "plan.tsv")
    geometry, rows, tracks = inspect(build, site, plan)
    readback = run / "readback"
    require(table(readback / "site.tsv") == [site], "Site alterado ao reabrir")
    require(inspect(readback, site, plan) == (geometry, rows, tracks), "Readback físico diverge")
    ports = table(build / "port_plan.tsv")
    expected_pins = {port["port"]: (port["layer"], port["side"]) for port in ports}
    require(len(expected_pins) == len(ports), "Plano de portas duplicado")
    for stage in (build, readback):
        reported = (stage / "pin_constraints.rpt").read_text()
        pattern = r"^  (\S+):\n    \{allowed_layers \{(M[34])\}\} \{sides \{([1-4])\}\}"
        actual = {pin: (layer, side) for pin, layer, side in re.findall(pattern, reported, re.M)}
        require(actual == expected_pins, "Restrições de portas divergem em " + stage.name)
        data = (stage / "floorplan.def").read_text()
        def_pins = set(re.findall(r"^\s*-\s+(\S+)\s+\+ NET", data, re.M))
        require(def_pins == expected_pins.keys(), "Portas do DEF divergem em " + stage.name)
    for side, layer, axis in (("1", "M3", "Y"), ("2", "M4", "X"), ("3", "M3", "Y"), ("4", "M4", "X")):
        _, track_count, _ = tracks[layer, axis]
        # Quatro tracks de folga em cada canto e duas tracks livres entre pinos.
        capacity = (track_count - 8 + 2) // 3
        demand = sum(value == (layer, side) for value in expected_pins.values())
        require(0 < demand <= capacity, "Demanda de portas excede a estimativa de acesso")
        print(f"side={side} layer={layer} ports={demand} estimated_slots={capacity}")
    area_report = (build / "area.rpt").read_text()
    area_match = re.search(r"Total cell area:\s+([0-9.]+)", area_report)
    require(area_match and Decimal(area_match[1]) == Decimal(plan["cell_area_um2"]),
            "Área lógica mudou no floorplan")
    checks = (build / "check_design.rpt").read_text()
    summaries = re.findall(r"^\s*Total \d+ (?:non-)?EMS messages\s*:\s*(\d+) errors", checks, re.M)
    require(len(summaries) == 2 and all(count == "0" for count in summaries),
            "Há erros no check_design ou o resumo está ausente")
    for key, (x0, y0, x1, y1) in geometry.items():
        width, height = (x1 - x0) / 1000, (y1 - y0) / 1000
        area = width * height
        print(f"{key}: {width:.3f} × {height:.3f} µm, {area:.6f} µm²")
        if key == "core":
            print(f"aspect_ratio={width / height:.5f} utilization={float(plan['cell_area_um2']) / area:.5%}")
    print(f"rows={len(rows)} sites_per_row={rows[0][5]} track_records={len(tracks)} ports={len(ports)}")
    draw(run / "floorplan.svg", geometry, rows, ports)
    print("FLOORPLAN_GEOMETRY_VALIDATED")


if __name__ == "__main__":
    try:
        validate(Path(sys.argv[1]))
    except (OSError, ValueError, KeyError, IndexError) as error:
        sys.exit("Floorplan não validado: " + str(error))
