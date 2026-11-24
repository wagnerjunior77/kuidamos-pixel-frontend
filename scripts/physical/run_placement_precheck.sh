#!/usr/bin/env bash
# Inspeciona regras físicas e cenários em uma cópia do checkpoint PG.
set -euo pipefail

if [[ $# != 2 ]]; then
    printf 'Uso: %s <execução do power plan> <SPF pós-scan>\n' "$0" >&2
    exit 2
fi
scripts=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo=$(cd -- "$scripts/../.." && pwd -P)
powerplan=$(cd -- "$1" && pwd -P)
spf=$(realpath -- "$2")
checkpoint="$powerplan/kuidamos_preview.dlib"
[[ -s "$checkpoint/powerplan_initial/design.ndm" && -s "$spf" ]] &&
    grep -Fxq POWERPLAN_VALIDATED "$powerplan/validation.txt" || {
    echo 'Checkpoint PG validado ou SPF ausente.' >&2
    exit 2
}

fc=$(realpath -- "$(command -v "${FC_SHELL:-fc_shell}")")
limit=${M10_TIMEOUT_SECONDS:-180}
[[ $limit =~ ^[1-9][0-9]*$ ]] || { echo 'M10_TIMEOUT_SECONDS inválido.' >&2; exit 2; }
mkdir -p -- "$repo/outputs/physical/runs"
run=$(mktemp -d "$repo/outputs/physical/runs/$(date -u +%Y%m%dT%H%M%SZ)-placement-precheck-XXXXXX")
printf 'Resultados em %s\n' "$run"
cd -- "$run"
snapshot() {
    {
        find "$repo"/{rtl,tb,constraints,outputs/synthesis,outputs/dft} -type f -print0
        find "$repo/outputs/physical" "$powerplan" -path "$run" -prune -o -type f -print0
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

sha256sum "$scripts"/{run_placement_precheck.sh,placement_precheck.tcl,placement_timing.tcl} "$spf" > inputs.sha256
cp -a -- "$checkpoint" .
cp -- "$spf" protocol.spf
timeout -k 5s 30s "$fc" -version > version.log 2>&1
grep -q 'fc_shell version X-2025.06-SP2' version.log || { echo 'Versão diferente da validada.' >&2; exit 2; }

status=0
timeout -k 10s "${limit}s" "$fc" -no_init -file "$scripts/placement_precheck.tcl" > fc.log 2>&1 || status=$?
printf '%s\n' "$status" > tool_exit_code.txt
if [[ $status != 0 ]] || ! grep -Fxq M10_PLACEMENT_PRECHECK_COMPLETED fc.log; then
    echo 'Pré-verificação incompleta. Consulte fc.log.' >&2
    exit 1
fi
sed -n '/^module /,$p' reports/netlist.v > body.v
[[ -s body.v ]]
cmp "$powerplan/readback/body.v" body.v
printf 'FUNCTIONAL_NETLIST_MATCH\n' > handoff.log
printf 'Pré-verificação de placement gravada em %s\n' "$run"
