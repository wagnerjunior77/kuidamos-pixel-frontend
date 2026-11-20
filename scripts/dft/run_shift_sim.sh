#!/usr/bin/env bash
set -euo pipefail
if [[ $# != 1 ]]; then
    echo "Uso: $0 <diretório da execução de inserção>" >&2
    exit 2
fi
: "${SAED32_REF_ROOT:?Defina SAED32_REF_ROOT para a SAED32}"
scripts=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
run=$(realpath -- "$1")
model=$(realpath -- "$SAED32_REF_ROOT/verilog/stdcell_rvt/saed32nm.v")
netlist="$run/post/scan_netlist.v"
order="$run/post/actual_chain.tsv"
[[ -s $model && -s $netlist && -s $order ]]
work=$(mktemp -d "$run/sim-shift-XXXXXX")
printf 'Simulação de shift em %s\n' "$work"
cd -- "$work"

python3 - "$order" <<'PY'
import csv
import re
import sys
from pathlib import Path

with Path(sys.argv[1]).open() as stream:
    rows = list(csv.DictReader(stream, delimiter="\t"))
assert len(rows) == 115
assert len({row["instance"] for row in rows}) == 115
assert [int(row["position"]) for row in rows] == list(range(1, 116))
assert all(row["SO_pin"] in {"Q", "QN"} for row in rows)
assert all(re.fullmatch(r"[a-zA-Z_][a-zA-Z0-9_]*", row["instance"]) for row in rows)
mask = sum((row["SO_pin"] == "QN") << i for i, row in enumerate(rows))
with Path("actual_chain.svh").open("w") as include:
    include.write("localparam int CHAIN_LENGTH = 115;\n")
    include.write("localparam logic [114:0] SCAN_OUT_INVERTED = 115'h{:x};\n".format(mask))
    include.write("wire [114:0] observed_q;\n")
    for i, row in enumerate(rows):
        include.write("assign observed_q[{}] = dut.{}.Q;\n".format(i, row["instance"]))
PY

sha256sum "$model" "$netlist" "$order" "$scripts/tb_scan_shift.sv" > inputs.sha256
vcs -full64 -ID > vcs_version.txt 2>&1
timeout -k 10s 180s vcs -full64 -sverilog +notimingcheck +incdir+. \
    -top tb_scan_shift -o simv "$model" "$netlist" "$scripts/tb_scan_shift.sv" -l compile.log
timeout -k 10s 120s ./simv -exitstatus -l simulation.log
rg -q '^SHIFT_PASS length=115 shift_clocks=460 ' simulation.log
