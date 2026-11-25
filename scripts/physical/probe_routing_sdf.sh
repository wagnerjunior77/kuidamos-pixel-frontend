#!/usr/bin/env bash
# Exercita a anotação SDF no VCS em uma pasta local, sem estímulos temporais.
set -euo pipefail
if [[ $# != 2 && ( $# != 3 || ${3:-} != --normalize-bus ) ]]; then
    echo "Uso: $0 <execução de routing> <arquivo SDF> [--normalize-bus]" >&2
    exit 2
fi
: "${SAED32_REF_ROOT:?Defina SAED32_REF_ROOT para o diretório ref da SAED32}"
run=$(realpath -- "$1")
sdf=$(realpath -- "$2")
model=$(realpath -- "$SAED32_REF_ROOT/verilog/stdcell_rvt/saed32nm.v")
netlist="$run/signals/reports/netlist.v"
[[ -s $sdf && -s $model && -s $netlist ]]
work=$(mktemp -d "$run/sdf-check-XXXXXX")
printf 'Diagnóstico SDF em %s\n' "$work"
cd -- "$work"
sha256sum "$model" "$netlist" "$sdf" > inputs.sha256
if [[ $# == 3 ]]; then
    # Converte seletores de bits escapados em INTERCONNECT nesta cópia.
    python3 - "$sdf" <<'PY' > normalization.log
import re
import sys
from pathlib import Path

source = Path(sys.argv[1]).read_text()
lines = []
total = 0
for line in source.splitlines(keepends=True):
    if "(INTERCONNECT " in line:
        line, count = re.subn(r"(?<=\s)([A-Za-z_]\w*)\\\[(\d+)\\\](?=\s)", r"\1[\2]", line)
        total += count
    lines.append(line)
Path("candidate.sdf").write_text("".join(lines))
print(f"INTERCONNECT_BUS_SELECTS_NORMALIZED {total}")
PY
else
    ln -s -- "$sdf" candidate.sdf
fi
cat > tb_sdf.sv <<'SV'
`timescale 1ns/1ps
module tb_sdf;
    kuidamos_pixel_frontend dut(.clk(1'b0), .reset_n(1'b0),
        .scan_enable(1'b0), .scan_in(1'b0), .scan_out());
    initial begin
        $sdf_annotate("candidate.sdf", dut, , "annotation.log", "MAXIMUM");
        #1;
        $display("SDF_ANNOTATION_PROBE_COMPLETED");
        $finish;
    end
endmodule
SV
timeout -k 10s 90s vcs -full64 -sverilog +neg_tchk -negdelay \
    -top tb_sdf -o simv "$model" "$netlist" tb_sdf.sv > compile.log 2>&1
timeout -k 10s 45s ./simv -exitstatus +sdfverbose > simulation.log 2>&1
grep -Fxq SDF_ANNOTATION_PROBE_COMPLETED simulation.log
python3 - <<'PY'
import re
from pathlib import Path

report = Path("annotation.log").read_text()
counts = dict(re.findall(r"Total (errors|warnings):\s*(\d+)", report))
if counts.keys() != {"errors", "warnings"}:
    raise SystemExit("Resumo da anotação SDF ausente")
print(f"SDF_ANNOTATION_SUMMARY errors={counts['errors']} warnings={counts['warnings']}")
if any(map(int, counts.values())):
    raise SystemExit(4)
PY
