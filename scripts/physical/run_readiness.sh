#!/usr/bin/env bash
# Diagnóstico M10 sobre uma cópia local do M9.
set -euo pipefail

if [[ $# != 1 ]]; then
    printf 'Uso: %s <diretório da inserção M9>\n' "$0" >&2
    exit 2
fi
: "${SAED32_REF_ROOT:?Defina SAED32_REF_ROOT para o diretório ref da SAED32}"
scripts=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo=$(cd -- "$scripts/../.." && pwd -P)
m9=$(cd -- "$1" && pwd -P)
export SAED32_REF_ROOT
SAED32_REF_ROOT=$(cd -- "$SAED32_REF_ROOT" && pwd -P)
fc=$(realpath -- "$(command -v "${FC_SHELL:-fc_shell}")")
timeout_seconds=${M10_TIMEOUT_SECONDS:-180}
[[ $timeout_seconds =~ ^[1-9][0-9]*$ ]] || { echo 'M10_TIMEOUT_SECONDS inválido.' >&2; exit 2; }

for path in tech/saed32nm_1p9m.tf tech/saed32nm_tf_itf_tluplus.map \
    tech/saed32nm_1p9m_Cmin.lv.tluplus tech/saed32nm_1p9m_Cmax.lv.tluplus \
    CLIBs/saed32_rvt.ndm/reflib.ndm; do
    [[ -s "$SAED32_REF_ROOT/$path" ]] || { echo "Referência ausente: $path" >&2; exit 2; }
done
checkpoint="$m9/kuidamos_preview.dlib"
[[ -s "$checkpoint/scan_inserted/design.ndm" ]] || { echo 'Checkpoint scan_inserted ausente.' >&2; exit 2; }

mkdir -p -- "$repo/outputs/physical/runs"
run=$(mktemp -d "$repo/outputs/physical/runs/$(date -u +%Y%m%dT%H%M%SZ)-readiness-XXXXXX")
printf 'Resultados em %s\n' "$run"
cd -- "$run"
python3 "$repo/scripts/dft/check_scan_exports.py" "$m9" > handoff.log
sha256sum "$m9"/post/{scan_netlist.v,scan.def,scan_protocol.spf,actual_chain.tsv} > handoff.sha256
find "$checkpoint" -type f -print0 | sort -z | xargs -0 -r sha256sum > checkpoint.sha256
cp -a -- "$checkpoint" .
cp -- "$m9/post/scan.def" .
timeout -k 5s 30s "$fc" -version > version.log 2>&1
grep -q 'fc_shell version X-2025.06-SP2' version.log || {
    echo 'Versão diferente da validada. Consulte version.log.' >&2
    exit 2
}

status=0
timeout -k 10s "${timeout_seconds}s" "$fc" -no_init -file "$scripts/check_readiness.tcl" > fc.log 2>&1 || status=$?
printf '%s\n' "$status" > tool_exit_code.txt
sha256sum -c --quiet handoff.sha256 checkpoint.sha256
if [[ $status != 0 ]] || ! grep -Fxq 'M10_READINESS_CHECKS_COMPLETED' fc.log; then
    echo 'Diagnóstico incompleto. Consulte fc.log.' >&2
    exit 1
fi

# O Verilog Writer antepõe metadados do bloco e data. Compare o corpo.
sed -n '/^module /,$p' "$m9/post/scan_netlist.v" > m9_body.v
sed -n '/^module /,$p' reports/checkpoint_netlist.v > readback_body.v
[[ -s m9_body.v && -s readback_body.v ]]
cmp m9_body.v readback_body.v
printf 'CHECKPOINT_NETLIST_MATCH\n' >> handoff.log
printf 'Diagnóstico gravado em %s\n' "$run"
