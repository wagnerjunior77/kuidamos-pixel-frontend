#!/usr/bin/env bash
# Roteia uma cópia de cts_initial e valida o handoff físico e lógico.
set -euo pipefail
if [[ $# != 2 ]]; then
    echo "Uso: $0 <execução CTS validada> <actual_chain.tsv de M9>" >&2
    exit 2
fi
: "${SAED32_REF_ROOT:?Defina SAED32_REF_ROOT para o diretório ref da SAED32}"
scripts=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo=$(cd -- "$scripts/../.." && pwd -P)
base=$(cd -- "$1" && pwd -P)
chain=$(realpath -- "$2")
fc=$(realpath -- "$(command -v "${FC_SHELL:-fc_shell}")")
command -v vcs >/dev/null
grep -Fxq CTS_VALIDATED "$base/handoff.log"
[[ -s "$base/kuidamos_preview.dlib/cts_initial/design.ndm" && -s $chain ]]
limit=${M10_TIMEOUT_SECONDS:-240}
[[ $limit =~ ^[1-9][0-9]*$ ]]

mkdir -p -- "$repo/outputs/physical/runs"
run=$(mktemp -d "$repo/outputs/physical/runs/$(date -u +%Y%m%dT%H%M%SZ)-routing-XXXXXX")
printf 'Resultados em %s\n' "$run"
cd -- "$run"
snapshot() {
    {
        find "$repo"/{rtl,tb,constraints,outputs/synthesis,outputs/dft} -type f -print0
        find "$repo/outputs/physical" "$base" -path "$run" -prune -o -type f -print0
        printf '%s\0' "$chain"
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

sha256sum "$scripts"/{run_routing.sh,routing_initial.tcl,placement_timing.tcl,validate_routing.py,validate_cts.py} \
    "$base"/readback/reports/{design.def,netlist.v} "$chain" > inputs.sha256
cp -a -- "$base/kuidamos_preview.dlib" .
export M10_ROUTING_DLIB="$run/kuidamos_preview.dlib"
timeout -k 5s 30s "$fc" -version > version.log 2>&1
grep -q 'fc_shell version X-2025.06-SP2' version.log
fc_stage() (
    export M10_ROUTING_STAGE=$1
    mkdir -- "$1"
    cd -- "$1"
    timeout -k 10s "${limit}s" "$fc" -no_init -file "$scripts/routing_initial.tcl" > fc.log 2>&1
    grep -Fxq M10_ROUTING_STAGE_COMPLETED fc.log
)

fc_stage clock
python3 "$scripts/validate_routing.py" "$run" "$base" "$chain" clock | tee clock/validation.txt
fc_stage signals
python3 "$scripts/validate_routing.py" "$run" "$base" "$chain" signals | tee signals/validation.txt
mkdir -p sim_handoff/post
cp -- signals/reports/netlist.v sim_handoff/post/scan_netlist.v
cp -- "$chain" sim_handoff/post/actual_chain.tsv
"$repo/scripts/dft/run_replacement_sim.sh" "$run/sim_handoff" post_scan > functional_vcs.log 2>&1
"$repo/scripts/dft/run_shift_sim.sh" "$run/sim_handoff" > shift_vcs.log 2>&1
fc_stage promote
fc_stage readback
python3 "$scripts/validate_routing.py" "$run" "$base" "$chain" readback | tee readback/validation.txt
printf 'ROUTING_VALIDATED\n' >> handoff.log
