#!/usr/bin/env bash
# M9: importação, diagnóstico e DRC; nenhuma transformação de scan.
set -euo pipefail

if [[ ${1:-} == --help ]]; then
    cat <<'USAGE'
Uso: SAED32_REF_ROOT=/caminho/saed32/ref ./scripts/dft/run_pre_dft.sh
Requer FC X-2025.06-SP2 no PATH (ou FC_SHELL=/caminho/fc_shell).
DFT_TIMEOUT_SECONDS: limite da execução, em segundos (padrão: 600).
Cada execução cria outputs/dft/runs/<data-UTC>-<identificador>/.
Não executa scan replacement, insertion, ATPG ou implementação física.
Retorno 0 significa execução completa, não PASS de timing ou DFT.
USAGE
    exit 0
fi
[[ $# == 0 ]] || { echo 'Argumento inválido; use --help.' >&2; exit 2; }
: "${SAED32_REF_ROOT:?Defina SAED32_REF_ROOT para o diretório ref da SAED32}"
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
REPO_ROOT=$(cd -- "$SCRIPT_DIR/../.." && pwd -P)
SAED32_REF_ROOT=$(cd -- "$SAED32_REF_ROOT" && pwd -P)
FC_BIN=$(command -v "${FC_SHELL:-fc_shell}")
FC_BIN=$(realpath -- "$FC_BIN")
DFT_TIMEOUT_SECONDS=${DFT_TIMEOUT_SECONDS:-600}
[[ $DFT_TIMEOUT_SECONDS =~ ^[1-9][0-9]*$ ]] || { echo 'Timeout inválido.' >&2; exit 2; }
for tool in timeout sha256sum tee git realpath python3; do command -v "$tool" >/dev/null; done
for file in tech/saed32nm_1p9m.tf CLIBs/saed32_rvt.ndm/reflib.ndm DBs/saed32rvt_ss0p95v125c.db; do
    [[ -r "$SAED32_REF_ROOT/$file" ]] || { echo "Arquivo ausente: $file" >&2; exit 2; }
done
for file in kuidamos_pixel_frontend_mapped.v kuidamos_pixel_frontend_mapped.sdc; do
    [[ -s "$REPO_ROOT/outputs/synthesis/$file" ]] || { echo "Artefato M8 ausente: $file" >&2; exit 2; }
done

mkdir -p -- "$REPO_ROOT/outputs/dft/runs"
DFT_RUN_DIR=$(mktemp -d "$REPO_ROOT/outputs/dft/runs/$(date -u +%Y%m%dT%H%M%SZ)-XXXXXX")
export REPO_ROOT SAED32_REF_ROOT DFT_RUN_DIR
cd -- "$DFT_RUN_DIR"
printf 'Resultados: %s\n' "$DFT_RUN_DIR"

snapshot_protected() {
    (cd -- "$REPO_ROOT"; git ls-files -z -- rtl outputs/synthesis | xargs -0 sha256sum)
}
snapshot_protected > protected.before.sha256
{
    printf 'utc_started=%s\n' "$(date -u +%FT%TZ)"
    printf 'fc_binary=%s\nsaed32_ref_root=%s\n' "$FC_BIN" "$SAED32_REF_ROOT"
    git -C "$REPO_ROOT" rev-parse HEAD
    git -C "$REPO_ROOT" status --short --branch
    uname -sr
    cat /etc/rocky-release
} > environment.txt
sha256sum "$SCRIPT_DIR"/*.tcl "$SCRIPT_DIR"/*.py "$SCRIPT_DIR/run_pre_dft.sh" > scripts.sha256
find "$SAED32_REF_ROOT/CLIBs/saed32_rvt.ndm" -type f -print0 |
    sort -z | xargs -0 sha256sum > technology.sha256
sha256sum "$SAED32_REF_ROOT/tech/saed32nm_1p9m.tf" \
    "$SAED32_REF_ROOT/DBs/saed32rvt_ss0p95v125c.db" >> technology.sha256

timeout -k 5s 30s "$FC_BIN" -version > version.txt 2>&1
grep -q 'fc_shell version X-2025.06-SP2' version.txt || {
    echo 'Versão diferente da validada; consulte version.txt.' >&2; exit 2;
}
set +e
timeout -k 10s "${DFT_TIMEOUT_SECONDS}s" "$FC_BIN" -no_init \
    -file "$SCRIPT_DIR/pre_dft.tcl" 2>&1 | tee pre_dft.log
pipeline_status=("${PIPESTATUS[@]}")
fc_status=${pipeline_status[0]}
set -e
snapshot_protected > protected.after.sha256
if ! cmp -s protected.before.sha256 protected.after.sha256; then
    echo 'ERRO: a integridade dos arquivos protegidos mudou; não foi feita reversão automática.' >&2
    exit 3
fi
printf '%s\n' "$fc_status" > tool_exit_code.txt
if [[ $fc_status != 0 ]]; then
    echo "Execução interrompida (código $fc_status). Consulte $DFT_RUN_DIR" >&2
    exit "$fc_status"
fi
[[ ${pipeline_status[1]} == 0 ]] || { echo 'Falha na gravação do log.' >&2; exit 2; }
[[ -f execution.status ]] && grep -qx 'COMPLETED' execution.status || {
    echo 'Execução incompleta: marcador final ausente.' >&2; exit 2;
}
if grep -Eq '^[[:space:]]*(Error:|Fatal:)' pre_dft.log reports/*.rpt drc_work/*.stdout.log; then
    echo 'O FC emitiu erro apesar de retornar zero; consulte o log.' >&2; exit 2
fi
python3 "$SCRIPT_DIR/summarize_pre_dft.py" "$DFT_RUN_DIR"
printf 'Execução completa; arquivos M8/RTL preservados. Isto não declara PASS de timing/DFT.\nResultados: %s\n' "$DFT_RUN_DIR"
