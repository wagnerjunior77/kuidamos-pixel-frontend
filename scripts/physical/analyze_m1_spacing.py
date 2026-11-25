"""Cruza os marcadores M1 com os rails e bounding boxes do placement de origem."""

import re
import sys
from collections import Counter
from pathlib import Path

from validate_floorplan import box, grid, require, table


def diagnose(reports, wires):
    rails = {box(row): row["net"] for row in table(wires) if row["layer"] == "M1"}
    cells = [(box(row), row["cell"], row["ref"], row["orientation"]) for row in table(reports / "cells.tsv")]
    marker_text = (reports / "pg_drc.txt").read_text()
    summary = (reports / "pg_drc.rpt").read_text()
    total = re.search(r"Total number of errors found:\s*(\d+)", summary)
    require(total, "O relatório de origem precisa conter violações")
    kinds, nets, orientations, widths = (Counter() for _ in range(4))
    min_gap, examples = {}, {}
    touched_rails = set()

    for marker in marker_text.split("=================\n")[1:]:
        pattern = r"Shape #\d+:\s+box = \{([^}]+)\} \{([^}]+)\}\s+net = ([^\n]+)"
        shapes = [(tuple(map(grid, (ll + " " + ur).split())), net.strip())
                  for ll, ur, net in re.findall(pattern, marker)]
        if not marker.startswith("Error type:"):
            continue
        require(len(shapes) == 2 and re.search(r"^Layer:\s*M1\s*$", marker, re.M), "Marcador inesperado")
        exact = {bounds for bounds, net in shapes if rails.get(bounds) == net}
        category = "rail" if exact else "PG local"
        touched_rails.update(exact)
        rule = re.search(r"Violated rule:\s+(\S+)", marker)[1]
        spacing = re.search(r"Minimal spacing:\s+([.\d]+)\s+Actual\s+spacing:\s+([.\d]+)", marker)
        required, measured = map(grid, spacing.groups())
        kinds[category, rule, required] += 1
        min_gap[category] = min(measured, min_gap.get(category, measured))
        net_types = tuple(sorted(net if net in {"VDD", "VSS", "unknown"} else "sinal" for _, net in shapes))
        nets[category, net_types] += 1
        if exact:
            other, _ = next((bounds, net) for bounds, net in shapes if bounds not in exact)
        else:
            pg, name = next((bounds, net) for bounds, net in shapes if net in {"VDD", "VSS"})
            other, _ = next((bounds, net) for bounds, net in shapes if net not in {"VDD", "VSS"})
            # O retângulo PG local cruza o rail e herda uma das suas arestas.
            edge_matches = [rail for rail, net in rails.items()
                            if net == name and rail[0] <= pg[0] < pg[2] <= rail[2]
                            and max(rail[1], pg[1]) < min(rail[3], pg[3])
                            and (rail[1] == pg[1] or rail[3] == pg[3])]
            require(edge_matches, "Origem do retângulo PG local ficou sem classificação")
            widths[pg[2] - pg[0]] += 1
        owner = [item for item in cells
                 if item[0][0] <= other[0] < other[2] <= item[0][2]
                 and item[0][1] <= other[1] < other[3] <= item[0][3]]
        if exact and len(owner) == 1:
            orientations[owner[0][3]] += 1
        examples.setdefault((category, net_types, rule), (required, measured, shapes, owner))

    require(sum(kinds.values()) == int(total[1]), "Contagem do relatório detalhado diverge do resumo")
    for (category, rule, required), count in kinds.most_common():
        print(f"{category} | {rule} | mínimo {required} nm | {count}")
    print("Espaçamento medido mínimo [nm]:", min_gap)
    print(f"Rails diretamente envolvidos: {len(touched_rails)}/{len(rails)}")
    print("Orientações das células vizinhas de rails:", dict(orientations))
    print("Larguras dos retângulos PG locais [nm]:", dict(widths))
    for (category, net_types), count in nets.most_common():
        print(f"{category} | {' + '.join(net_types)} | {count}")
    for key, detail in examples.items():
        print(key, detail)


if __name__ == "__main__":
    try:
        diagnose(Path(sys.argv[1]), Path(sys.argv[2]))
    except (OSError, ValueError, IndexError, TypeError, KeyError) as error:
        sys.exit("Diagnóstico M1 incompleto: " + str(error))
