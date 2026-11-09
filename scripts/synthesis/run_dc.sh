#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# Script: scripts/synthesis/run_dc.sh
# Project: KUIDAMOS Pixel Front-End — Group 6C (Milestone M8)
# Description:
#   Wrapper script to execute Synopsys Design Compiler (dc_shell) synthesis
#   with SAED32 standard cell libraries and 100 MHz (10.0 ns) constraints.
#   All logs, reports, and gate-level artifacts remain inside outputs/synthesis/
#   (ignored by Git per AGENTS.md).
# -----------------------------------------------------------------------------

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
OUT_DIR="${OUT_DIR:-$REPO_ROOT/outputs/synthesis}"
TARGET_LIB="${TARGET_LIB:-/opt/synopsys/saed32/DBs/saed32rvt_ss0p95v125c.db}"
CLOCK_PERIOD_NS="${CLOCK_PERIOD_NS:-10.0}"

# Ensure Synopsys DC binary is on PATH if installed in standard /opt/synopsys path
if ! command -v dc_shell >/dev/null 2>&1; then
    if [ -x "/opt/synopsys/syn/X-2025.06-SP2/bin/dc_shell" ]; then
        export PATH="/opt/synopsys/syn/X-2025.06-SP2/bin:$PATH"
    else
        echo "[BLOCKED] Synopsys 'dc_shell' not found in PATH on $(hostname)." >&2
        exit 2
    fi
fi

if [ ! -f "$TARGET_LIB" ]; then
    echo "[BLOCKED] Target library '$TARGET_LIB' not found on $(hostname)." >&2
    exit 2
fi

# Resolve TARGET_LIB and OUT_DIR to absolute paths before changing directory
TARGET_LIB="$(cd "$(dirname "$TARGET_LIB")" && pwd)/$(basename "$TARGET_LIB")"

if [ -z "${SNPSLMD_LICENSE_FILE:-}" ] && [ -n "${LM_LICENSE_FILE:-}" ]; then
    export SNPSLMD_LICENSE_FILE="$LM_LICENSE_FILE"
fi

# Ensure /tmp exists with sticky permissions inside container environments
if [ ! -d /tmp ]; then
    mkdir -p /tmp && chmod 1777 /tmp || true
fi

mkdir -p "$OUT_DIR/reports" "$OUT_DIR/work"
OUT_DIR="$(cd "$OUT_DIR" && pwd)"

export REPO_ROOT
export OUT_DIR
export TARGET_LIB
export CLOCK_PERIOD_NS

echo "=== KUIDAMOS 6C — Design Compiler Synthesis Flow (M8) ==="
echo "Date:         $(date -Iseconds)"
echo "Host:         $(hostname)"
echo "Repository:   $REPO_ROOT"
echo "Target lib:   $TARGET_LIB"
echo "Clock period: ${CLOCK_PERIOD_NS} ns"
echo "Output dir:   $OUT_DIR"

dc_shell -64bit -version > "$OUT_DIR/dc_version.txt" 2>&1 || true

# Run inside OUT_DIR so dc_shell temporary files (command.log, filenames.log, clog*)
# do not pollute the repository root.
(
    cd "$OUT_DIR"
    dc_shell -64bit \
        -f "$REPO_ROOT/scripts/synthesis/dc_synth.tcl" \
        -output_log_file "$OUT_DIR/dc_compile.log"
)

if grep -q "^Error:" "$OUT_DIR/dc_compile.log"; then
    echo "[FAIL] Design Compiler reported errors in $OUT_DIR/dc_compile.log" >&2
    grep "^Error:" "$OUT_DIR/dc_compile.log" >&2
    exit 1
fi

echo "=== Design Compiler Synthesis Completed Successfully ==="
echo "Compile log:  $OUT_DIR/dc_compile.log"
echo "Reports dir:  $OUT_DIR/reports/"
