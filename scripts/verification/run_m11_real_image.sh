#!/usr/bin/env bash
# Caso isolado que usa as rotinas do scoreboard M7 em uma cópia do testbench.
set -euo pipefail
if [[ $# != 1 && $# != 2 ]]; then
    echo "Uso: $0 <imagem RGB> [netlist de physical_final]" >&2
    exit 2
fi
image=$(realpath -- "$1")
netlist=""
if [[ $# == 2 ]]; then
    netlist=$(realpath -- "$2")
    : "${SAED32_REF_ROOT:?Defina SAED32_REF_ROOT para o modelo gate-level}"
    library=$(realpath -- "$SAED32_REF_ROOT/verilog/stdcell_rvt/saed32nm.v")
    [[ -s $library && -s $netlist ]]
fi
[[ -s $image ]]
repo=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd -P)
cd -- "$repo"
python=$(command -v "${PYTHON_BIN:-python3}")
command -v vcs >/dev/null
export PYTHONPATH="$repo${PYTHONPATH:+:$PYTHONPATH}"
mkdir -p outputs/m11
run=$(mktemp -d "$repo/outputs/m11/real-image-XXXXXX")
printf 'Execução M11 em %s\n' "$run"
mkdir -- "$run/vectors"
cycles=$("$python" -m scripts.verification.m11_real_image prepare "$image" "$run/vectors")
"$python" -c 'import sys, numpy, PIL; print(sys.version); print(numpy.__version__, PIL.__version__)' > "$run/python_version.txt"
vcs -full64 -ID > "$run/vcs_version.txt" 2>&1

tb="$repo/tb/tb_kuidamos_pixel_frontend.sv"
sha256sum "$image" "$tb" "$repo"/rtl/*.sv "$repo"/model/{golden,m2_vectors,real_image_demo}.py > "$run/inputs.sha256"
[[ -z $netlist ]] || sha256sum "$netlist" "$library" >> "$run/inputs.sha256"

simulate() (
    mode=$1
    shift
    mkdir -- "$run/$mode"
    cd -- "$run/$mode"
    "$python" -m scripts.verification.m11_real_image instrument "$tb" tb_image.sv --mode "$mode"
    timeout -k 10s 180s vcs -full64 -sverilog -timescale=1ns/1ps -top tb_kuidamos_pixel_frontend \
        "$@" tb_image.sv -o simv -l compile.log > compile.console.txt 2>&1
    timeout -k 10s 120s ./simv -exitstatus "+VECTOR_DIR=$run/vectors" +CASE=m11_imagem_real \
        "+EXPECT_CYCLES=$cycles" -l simulation.log | tee simulation.console.txt
    rg -q '^OVERALL RESULT: PASS$' simulation.log
    rg -q "cases_passed=1/1 .*cycles_checked=$cycles .*scoreboard_mismatches=0 .*sva_errors=0" simulation.log
    if [[ $mode == rtl ]]; then
        rg -q 'sva_checks=[1-9][0-9]*' simulation.log
    fi
    "$python" -m scripts.verification.m11_real_image verify "$run/vectors" "$PWD" --mode "$mode"
)

simulate rtl "$repo"/rtl/{grayscale_core,crop_core,resize_nn_core,threshold_core,kuidamos_pixel_frontend}.sv \
    "$repo/tb/kuidamos_pixel_frontend_sva.sv"
if [[ -n $netlist ]]; then
    simulate gate +notimingcheck "$library" "$netlist"
fi
sha256sum -c "$run/inputs.sha256" > "$run/input_check.txt"
