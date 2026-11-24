#!/usr/bin/env bash
# Executa PG em uma cópia exclusiva do floorplan já validado.
set -euo pipefail

if [[ $# != 1 ]]; then
    printf 'Uso: %s <diretório da execução do floorplan>\n' "$0" >&2
    exit 2
fi
scripts=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo=$(cd -- "$scripts/../.." && pwd -P)
floorplan=$(cd -- "$1" && pwd -P)
checkpoint="$floorplan/kuidamos_preview.dlib"
[[ -s "$checkpoint/floorplan_initial/design.ndm" ]] &&
    grep -Fxq 'FLOORPLAN_GEOMETRY_VALIDATED' "$floorplan/validation.txt" || {
    echo 'Checkpoint de floorplan validado ausente.' >&2
    exit 2
}

fc=$(realpath -- "$(command -v "${FC_SHELL:-fc_shell}")")
limit=${M10_TIMEOUT_SECONDS:-180}
[[ $limit =~ ^[1-9][0-9]*$ ]] || { echo 'M10_TIMEOUT_SECONDS inválido.' >&2; exit 2; }

mkdir -p -- "$repo/outputs/physical/runs"
run=$(mktemp -d "$repo/outputs/physical/runs/$(date -u +%Y%m%dT%H%M%SZ)-powerplan-XXXXXX")
printf 'Resultados em %s\n' "$run"
cd -- "$run"
snapshot() {
    {
        find "$repo/rtl" "$repo/tb" "$repo/constraints" "$repo/outputs/synthesis" \
            "$repo/outputs/dft" -type f -print0
        find "$repo/outputs/physical" "$floorplan" -path "$run" -prune -o -type f -print0
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

sha256sum "$scripts"/{run_powerplan.sh,powerplan_initial.tcl,validate_powerplan.py} \
    "$floorplan"/readback/{floorplan.def,body.v,pin_constraints.rpt,rc.rpt} > inputs.sha256
cp -a -- "$checkpoint" .
timeout -k 5s 30s "$fc" -version > version.log 2>&1
grep -q 'fc_shell version X-2025.06-SP2' version.log || { echo 'Versão diferente da validada.' >&2; exit 2; }

run_fc() {
    local label=$1 status=0
    timeout -k 10s "${limit}s" "$fc" -no_init -file "$scripts/powerplan_initial.tcl" > "$label.log" 2>&1 || status=$?
    printf '%s\n' "$status" > "$label.exit"
    [[ $status == 0 ]] && grep -Fxq "M10_POWERPLAN_COMPLETED $label" "$label.log" || {
        printf 'Execução incompleta. Consulte %s/%s.log\n' "$run" "$label" >&2
        return 1
    }
}
M10_POWERPLAN_STAGE=build run_fc build
M10_POWERPLAN_STAGE=readback run_fc readback
for stage in build readback; do
    sed -n '/^module /,$p' "$stage/netlist.v" > "$stage/body.v"
    [[ -s "$stage/body.v" ]]
    cmp "$floorplan/readback/body.v" "$stage/body.v"
    cmp "$floorplan/readback/rc.rpt" "$stage/rc.rpt"
done
printf 'FUNCTIONAL_NETLIST_AND_RC_MATCH\n' > handoff.log
python3 "$scripts/validate_powerplan.py" "$run" "$floorplan/readback" | tee validation.txt
printf 'Power plan e checkpoint gravados em %s\n' "$run"
