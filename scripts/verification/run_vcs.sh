#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# Script: scripts/verification/run_vcs.sh
# Project: KUIDAMOS Pixel Front-End — Group 6C (Milestones M3–M7)
# Description:
#   Compiles and runs the SystemVerilog testbench, Scoreboard, and SVA suite
#   using Synopsys VCS in the CIExpert Linux environment.
#   Produces real compile and simulation logs in OUT_DIR (default: outputs/vcs).
# -----------------------------------------------------------------------------

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REPO_ROOT"

OUT_DIR="${OUT_DIR:-outputs/vcs}"
VECTOR_DIR="${VECTOR_DIR:-vectors/m2}"
SIM_PLUSARGS="${SIM_PLUSARGS:-}"

mkdir -p "$OUT_DIR"

if ! command -v vcs >/dev/null 2>&1; then
    echo "[BLOCKED] Synopsys 'vcs' not found in PATH on $(hostname)." >&2
    echo "Run this script on the CIExpert Linux server with Synopsys environment loaded." >&2
    exit 2
fi

if [ -z "${SNPSLMD_LICENSE_FILE:-}" ] && [ -n "${LM_LICENSE_FILE:-}" ]; then
    export SNPSLMD_LICENSE_FILE="$LM_LICENSE_FILE"
fi

echo "=== KUIDAMOS 6C — VCS Verification Flow ==="
echo "Date:       $(date -Iseconds)"
echo "Host:       $(hostname)"
echo "Repository: $REPO_ROOT"
echo "Output dir: $OUT_DIR"

vcs -full64 -ID > "$OUT_DIR/vcs_version.txt" 2>&1 || true

echo "[1/2] Compiling RTL + SVA + Testbench with Synopsys VCS..."
vcs -full64 -sverilog \
    -timescale=1ns/1ps \
    -debug_access+all \
    -Mdir="$OUT_DIR/csrc" \
    -f tb/filelist.f \
    -top tb_kuidamos_pixel_frontend \
    -o "$OUT_DIR/simv" \
    -l "$OUT_DIR/vcs_compile.log"

echo "[2/2] Running regression simulation (M2 vectors + M7 directed suite)..."
"$OUT_DIR/simv" \
    -exitstatus \
    "+VECTOR_DIR=$VECTOR_DIR" \
    $SIM_PLUSARGS \
    -k "$OUT_DIR/ucli.key" \
    -l "$OUT_DIR/vcs_sim.log"

echo "=== VCS Simulation Completed Successfully ==="
echo "Compile log: $OUT_DIR/vcs_compile.log"
echo "Sim log:     $OUT_DIR/vcs_sim.log"

