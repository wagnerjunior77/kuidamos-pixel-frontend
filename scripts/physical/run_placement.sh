#!/usr/bin/env bash
# Placement exploratório numa nova cópia do checkpoint PG já validado.
set -euo pipefail

if [[ $# != 2 && ( $# != 3 || ${3:-} != --correct-m1 ) ]]; then
    printf 'Uso: %s <execução do power plan> <SPF pós-scan> [--correct-m1]\n' "$0" >&2
    exit 2
fi
export M10_CORRECT_M1=0
if [[ $# == 3 ]]; then
    M10_CORRECT_M1=1
fi
scripts=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo=$(cd -- "$scripts/../.." && pwd -P)
base=$(cd -- "$1" && pwd -P)
spf=$(realpath -- "$2")
checkpoint="$base/kuidamos_preview.dlib"
[[ -s "$checkpoint/powerplan_initial/design.ndm" && -s "$spf" ]] &&
    grep -Fxq POWERPLAN_VALIDATED "$base/validation.txt" || {
    echo 'Checkpoint PG validado ou SPF ausente.' >&2
    exit 2
}

fc=$(realpath -- "$(command -v "${FC_SHELL:-fc_shell}")")
limit=${M10_TIMEOUT_SECONDS:-180}
[[ $limit =~ ^[1-9][0-9]*$ ]] || { echo 'M10_TIMEOUT_SECONDS inválido.' >&2; exit 2; }

mkdir -p -- "$repo/outputs/physical/runs"
run=$(mktemp -d "$repo/outputs/physical/runs/$(date -u +%Y%m%dT%H%M%SZ)-placement-XXXXXX")
printf 'Resultados em %s\n' "$run"
cd -- "$run"
snapshot() {
    {
        find "$repo"/{rtl,tb,constraints,outputs/synthesis,outputs/dft} -type f -print0
        find "$repo/outputs/physical" "$base" -path "$run" -prune -o -type f -print0
        printf '%s\0' "$spf"
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

sha256sum "$scripts"/{run_placement.sh,placement_initial.tcl,placement_timing.tcl,pg_rail_correction.tcl,placement_readback.tcl,validate_placement.py,validate_powerplan.py,validate_floorplan.py} \
    "$base"/readback/{powerplan.def,body.v,wires.tsv,terminals.tsv} "$spf" > inputs.sha256
cp -a -- "$checkpoint" .
cp -- "$spf" protocol.spf
timeout -k 5s 30s "$fc" -version > version.log 2>&1
grep -q 'fc_shell version X-2025.06-SP2' version.log || { echo 'Versão diferente da validada.' >&2; exit 2; }

status=0
timeout -k 10s "${limit}s" "$fc" -no_init -file "$scripts/placement_initial.tcl" > fc.log 2>&1 || status=$?
printf '%s\n' "$status" > tool_exit_code.txt
if [[ $status != 0 ]] || ! grep -Fxq M10_PLACEMENT_DIAGNOSTICS_COMPLETED fc.log; then
    echo 'Execução incompleta. Consulte fc.log.' >&2
    exit 1
fi
sed -n '/^module /,$p' reports/netlist.v > body.v
[[ -s body.v ]]
cmp "$base/readback/body.v" body.v
printf 'FUNCTIONAL_NETLIST_MATCH\n' > handoff.log
if [[ $M10_CORRECT_M1 == 1 && -s kuidamos_preview.dlib/placement_initial/design.ndm ]]; then
    status=0
    timeout -k 10s "${limit}s" "$fc" -no_init -file "$scripts/placement_readback.tcl" > readback.log 2>&1 || status=$?
    printf '%s\n' "$status" > readback.exit
    if [[ $status != 0 ]] || ! grep -Fxq M10_CORRECTED_PLACEMENT_READBACK_COMPLETED readback.log; then
        echo 'Readback incompleto. Consulte readback.log.' >&2
        exit 1
    fi
    for block in powerplan_corrected placement_initial; do
        sed -n '/^module /,$p' "readback/$block/netlist.v" > "readback/$block/body.v"
        cmp "$base/readback/body.v" "readback/$block/body.v"
    done
fi
python3 "$scripts/validate_placement.py" "$run" "$base/readback" "${@:3}" | tee validation.txt
grep -Fxq PLACEMENT_VALIDATED validation.txt || {
    echo 'Placement exploratório coletado. Aceite bloqueado pelo PG DRC.' >&2
    exit 4
}
