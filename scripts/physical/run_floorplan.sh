#!/usr/bin/env bash
set -euo pipefail

if [[ $# != 1 ]]; then
    printf 'Uso: %s <diretório da inserção M9>\n' "$0" >&2
    exit 2
fi
: "${SAED32_REF_ROOT:?Defina SAED32_REF_ROOT para o diretório ref da SAED32}"
scripts=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo=$(cd -- "$scripts/../.." && pwd -P)
m9=$(cd -- "$1" && pwd -P)
SAED32_REF_ROOT=$(cd -- "$SAED32_REF_ROOT" && pwd -P)
export SAED32_REF_ROOT
fc=$(realpath -- "$(command -v "${FC_SHELL:-fc_shell}")")
limit=${M10_TIMEOUT_SECONDS:-180}
[[ $limit =~ ^[1-9][0-9]*$ ]] || { echo 'M10_TIMEOUT_SECONDS inválido.' >&2; exit 2; }

tech="$SAED32_REF_ROOT/tech"
checkpoint="$m9/kuidamos_preview.dlib"
for input in "$checkpoint/scan_inserted/design.ndm" \
    "$SAED32_REF_ROOT/CLIBs/saed32_rvt.ndm/reflib.ndm" \
    "$tech"/saed32nm_{1p9m.tf,tf_itf_tluplus.map,1p9m_Cmin.lv.tluplus,1p9m_Cmax.lv.tluplus}; do
    [[ -s $input ]] || { printf 'Entrada ausente: %s\n' "$input" >&2; exit 2; }
done

mkdir -p -- "$repo/outputs/physical/runs"
run=$(mktemp -d "$repo/outputs/physical/runs/$(date -u +%Y%m%dT%H%M%SZ)-floorplan-XXXXXX")
printf 'Resultados em %s\n' "$run"
cd -- "$run"

snapshot() {
    {
        find "$repo/rtl" "$repo/outputs/synthesis" "$repo/outputs/dft" "$m9" -type f -print0
        find "$repo/outputs/physical" -path "$run" -prune -o -type f -print0
    } | sort -zu | xargs -0 -r sha256sum
}
snapshot > protected.before.sha256
check_protected() {
    local status=$?
    if ! snapshot > protected.after.sha256 || ! cmp -s protected.before.sha256 protected.after.sha256; then
        echo 'Manifestos de integridade diferem. Consulte protected.*.sha256.' >&2
        exit 3
    fi
    printf 'PROTECTED_INPUTS_MATCH\n' >> handoff.log
    exit "$status"
}
trap check_protected EXIT

python3 "$repo/scripts/dft/check_scan_exports.py" "$m9" > handoff.log
sha256sum "$scripts"/{floorplan_initial.tcl,validate_floorplan.py,run_floorplan.sh} \
    "$tech"/saed32nm_{1p9m.tf,tf_itf_tluplus.map,1p9m_Cmin.lv.tluplus,1p9m_Cmax.lv.tluplus} \
    "$m9"/post/{scan_netlist.v,scan.def,scan_protocol.spf} > inputs.sha256
cp -a -- "$checkpoint" .
timeout -k 5s 30s "$fc" -version > version.log 2>&1
grep -q 'fc_shell version X-2025.06-SP2' version.log || { echo 'Versão diferente da validada.' >&2; exit 2; }

run_fc() {
    local label=$1 status=0
    timeout -k 10s "${limit}s" "$fc" -no_init -file "$scripts/floorplan_initial.tcl" > "$label.log" 2>&1 || status=$?
    printf '%s\n' "$status" > "$label.exit"
    [[ $status == 0 ]] && grep -Fxq "M10_FLOORPLAN_COMPLETED $label" "$label.log" || {
        printf 'Execução incompleta. Consulte %s/%s.log\n' "$run" "$label" >&2
        return 1
    }
}
M10_FLOORPLAN_STAGE=build run_fc build
M10_FLOORPLAN_STAGE=readback run_fc readback
sed -n '/^module /,$p' "$m9/post/scan_netlist.v" > m9_body.v
for stage in build readback; do
    sed -n '/^module /,$p' "$stage/netlist.v" > "$stage/body.v"
    [[ -s "$stage/body.v" ]]
    cmp m9_body.v "$stage/body.v"
done
printf 'CHECKPOINT_NETLIST_MATCH\n' >> handoff.log
python3 "$scripts/validate_floorplan.py" "$run" | tee validation.txt
printf 'Diagnóstico e checkpoint gravados em %s\n' "$run"
