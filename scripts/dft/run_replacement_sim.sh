#!/usr/bin/env bash
# Executa o scoreboard M2/M7 com a netlist, usando os modelos RVT da SAED32.
set -euo pipefail

if [[ $# != 2 || ( $2 != m8 && $2 != replacement && $2 != post_scan ) ]]; then
    echo "Uso: $0 <diretório da execução FC> m8|replacement|post_scan" >&2
    exit 2
fi
: "${SAED32_REF_ROOT:?Defina SAED32_REF_ROOT para o diretório ref da SAED32}"
root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd -P)
fc_run=$(realpath -- "$1")
model=$(realpath -- "$SAED32_REF_ROOT/verilog/stdcell_rvt/saed32nm.v")
variant=$2
if [[ $variant == m8 ]]; then
    netlist="$root/outputs/synthesis/kuidamos_pixel_frontend_mapped.v"
elif [[ $variant == post_scan ]]; then
    netlist="$fc_run/post/scan_netlist.v"
else
    netlist="$fc_run/after/replacement_attempt.v"
fi
[[ -s $netlist && -s $model ]]
sim_run=$(mktemp -d "$fc_run/sim-$variant-XXXXXX")
printf 'Simulação em %s\n' "$sim_run"
cd -- "$sim_run"
sha256sum "$model" "$netlist" "$root/tb/tb_kuidamos_pixel_frontend.sv" > inputs.sha256

python3 - "$root/tb/tb_kuidamos_pixel_frontend.sv" "$variant" <<'PY'
import os
import re
import sys
from pathlib import Path

source = Path(sys.argv[1]).read_text()
# O monitor RTL observa sinais internos que o mapeamento pode eliminar.
source, count = re.subn(
    r"(?ms)^    kuidamos_pixel_frontend_sva u_sva \(.*?^    \);\n", "", source
)
if count != 1:
    sys.exit("Instância SVA não encontrada de forma inequívoca")
source = source.replace("u_sva.sva_error_count", "0").replace("u_sva.sva_check_count", "0")
if sys.argv[2] != "m8":
    anchor = "    kuidamos_pixel_frontend u_dut (\n"
    if source.count(anchor) != 1:
        sys.exit("Instância DUT não encontrada de forma inequívoca")
    source = source.replace(anchor, anchor + "        .scan_enable (1'b0),\n"
                            "        .scan_in (1'b0),\n"
                            "        .scan_out (),\n")
if os.environ.get("KUIDAMOS_ACTIVITY_SAIF") == "1":
    anchor = "    kuidamos_pixel_frontend u_dut (\n"
    finish = '            $display("OVERALL RESULT: PASS");'
    if source.count(anchor) != 1 or source.count(finish) != 1:
        sys.exit("Não foi possível instrumentar a regressão para SAIF.")
    source = source.replace(anchor, """    initial begin
        $set_toggle_region(u_dut);
        $toggle_start;
    end

""" + anchor)
    source = source.replace(finish, """            $toggle_stop;
            $toggle_report("activity.saif", 1.0e-9, u_dut);
""" + finish)
Path("tb_gate.sv").write_text(source)
PY

vcs -full64 -ID > vcs_version.txt 2>&1
timeout -k 10s 180s vcs -full64 -sverilog +notimingcheck \
    -top tb_kuidamos_pixel_frontend -o simv "$model" "$netlist" tb_gate.sv \
    -l compile.log
timeout -k 10s 120s ./simv -exitstatus "+VECTOR_DIR=$root/vectors/m2" -l simulation.log
rg -q 'cases_passed=15/15 .*cycles_checked=2618 .*scoreboard_mismatches=0' simulation.log
rg -q '^OVERALL RESULT: PASS$' simulation.log
if [[ ${KUIDAMOS_ACTIVITY_SAIF:-0} == 1 ]]; then
    [[ -s activity.saif ]]
    printf 'SAIF_FILE %s\n' "$PWD/activity.saif"
fi
