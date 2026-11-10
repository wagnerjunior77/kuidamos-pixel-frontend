# -----------------------------------------------------------------------------
# Script: scripts/synthesis/dc_synth.tcl
# Project: KUIDAMOS Pixel Front-End — Group 6C (Milestone M8)
# Description:
#   Reproducible logic synthesis and static timing/area/power analysis flow
#   for Synopsys Design Compiler (dc_shell).
#   All generated netlists, databases, and tool reports are written inside
#   OUT_DIR (default: outputs/synthesis), outside Git tracking per AGENTS.md.
# -----------------------------------------------------------------------------

set TOP_MODULE "kuidamos_pixel_frontend"

if {[info exists ::env(REPO_ROOT)] && $::env(REPO_ROOT) ne ""} {
    set REPO_ROOT $::env(REPO_ROOT)
} else {
    set REPO_ROOT [pwd]
}

if {[info exists ::env(OUT_DIR)] && $::env(OUT_DIR) ne ""} {
    set OUT_DIR $::env(OUT_DIR)
} else {
    set OUT_DIR "$REPO_ROOT/outputs/synthesis"
}

if {[info exists ::env(TARGET_LIB)] && $::env(TARGET_LIB) ne ""} {
    set TARGET_LIB $::env(TARGET_LIB)
} else {
    set TARGET_LIB "/opt/synopsys/saed32/DBs/saed32rvt_ss0p95v125c.db"
}

if {[info exists ::env(CLOCK_PERIOD_NS)] && $::env(CLOCK_PERIOD_NS) ne ""} {
    set CLOCK_PERIOD_NS $::env(CLOCK_PERIOD_NS)
} else {
    set CLOCK_PERIOD_NS 10.0
}

set RPT_DIR  "$OUT_DIR/reports"
set WORK_DIR "$OUT_DIR/work"

file mkdir $OUT_DIR
file mkdir $RPT_DIR
file mkdir $WORK_DIR

puts "======================================================================"
puts " KUIDAMOS 6C — Logic Synthesis Flow (Milestone M8)"
puts " Top Module   : $TOP_MODULE"
puts " Target Lib   : $TARGET_LIB"
puts " Clock Period : ${CLOCK_PERIOD_NS} ns"
puts " Output Dir   : $OUT_DIR"
puts "======================================================================"

# -----------------------------------------------------------------------------
# 1. Library and Environment Setup
# -----------------------------------------------------------------------------
set LIB_DIR [file dirname $TARGET_LIB]
set LIB_FILE [file tail $TARGET_LIB]

set_app_var search_path       [list "." $LIB_DIR "$REPO_ROOT/rtl" "$REPO_ROOT/constraints"]
set_app_var target_library    [list $TARGET_LIB]
set_app_var synthetic_library [list dw_foundation.sldb]
set_app_var link_library      [list "*" $TARGET_LIB dw_foundation.sldb]

set_svf "$OUT_DIR/${TOP_MODULE}.svf"
define_design_lib WORK -path $WORK_DIR

# -----------------------------------------------------------------------------
# 2. Read, Analyze, Elaborate, and Link RTL
# -----------------------------------------------------------------------------
set RTL_FILES [list \
    "$REPO_ROOT/rtl/grayscale_core.sv" \
    "$REPO_ROOT/rtl/crop_core.sv" \
    "$REPO_ROOT/rtl/resize_nn_core.sv" \
    "$REPO_ROOT/rtl/threshold_core.sv" \
    "$REPO_ROOT/rtl/kuidamos_pixel_frontend.sv" \
]

if {![analyze -format sverilog -work WORK $RTL_FILES]} {
    puts "ERROR: RTL analyze failed."
    exit 1
}

if {![elaborate $TOP_MODULE -work WORK]} {
    puts "ERROR: RTL elaborate failed."
    exit 1
}

current_design $TOP_MODULE

if {![link]} {
    puts "ERROR: Design link failed."
    exit 1
}

uniquify

# -----------------------------------------------------------------------------
# 3. Pre-Synthesis Structural Checks
# -----------------------------------------------------------------------------
redirect "$RPT_DIR/check_design.rpt" { check_design }
redirect "$RPT_DIR/units.rpt"        { report_units }

# -----------------------------------------------------------------------------
# 4. Apply Timing and Electrical Constraints (SDC)
# -----------------------------------------------------------------------------
source "$REPO_ROOT/constraints/kuidamos_pixel_frontend.sdc"

set_fix_multiple_port_nets -all -buffer_constants [get_designs *]

redirect "$RPT_DIR/check_timing.rpt" { check_timing }
redirect "$RPT_DIR/clocks.rpt"       { report_clock -attributes }

# -----------------------------------------------------------------------------
# 5. Logic Synthesis & Optimization (preserving submodule hierarchy for area)
# -----------------------------------------------------------------------------
if {![compile_ultra -no_autoungroup]} {
    puts "ERROR: compile_ultra failed."
    exit 1
}

change_names -rules verilog -hierarchy

# -----------------------------------------------------------------------------
# 6. Post-Synthesis Reports (QoR, Area, Timing, Power, DRC, Latches)
# -----------------------------------------------------------------------------
redirect "$RPT_DIR/qor.rpt"            { report_qor }
redirect "$RPT_DIR/area.rpt"           { report_area -nosplit }
redirect "$RPT_DIR/area_hierarchy.rpt" { report_area -hierarchy -designware -nosplit }
redirect "$RPT_DIR/timing_max.rpt"     { report_timing -delay_type max -max_paths 20 -input_pins -nets -transition_time -capacitance -nosplit }
redirect "$RPT_DIR/timing_min.rpt"     { report_timing -delay_type min -max_paths 20 -input_pins -nets -nosplit }
redirect "$RPT_DIR/power.rpt"          { report_power -analysis_effort medium -hierarchy -nosplit }
redirect "$RPT_DIR/constraints.rpt"    { report_constraint -all_violators -nosplit }
redirect "$RPT_DIR/resources.rpt"      { report_resources -hierarchy -nosplit }
redirect "$RPT_DIR/registers.rpt"      { report_register -level_sensitive -nosplit }
redirect "$RPT_DIR/references.rpt"     { report_reference -hierarchy -nosplit }

# -----------------------------------------------------------------------------
# 7. Export Unversioned Gate-Level Artifacts (for M9 DFT & Post-Synth Flow)
# -----------------------------------------------------------------------------
write -format ddc     -hierarchy -output "$OUT_DIR/${TOP_MODULE}_mapped.ddc"
write -format verilog -hierarchy -output "$OUT_DIR/${TOP_MODULE}_mapped.v"
write_sdc -nosplit "$OUT_DIR/${TOP_MODULE}_mapped.sdc"
write_sdf "$OUT_DIR/${TOP_MODULE}_mapped.sdf"

set_svf -off

puts "======================================================================"
puts " KUIDAMOS 6C — Synthesis Completed Successfully"
puts " Reports Dir  : $RPT_DIR"
puts "======================================================================"
exit 0
