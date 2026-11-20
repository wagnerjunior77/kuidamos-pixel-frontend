set TOP kuidamos_pixel_frontend
set NDM [file join $SAED32_REF_ROOT CLIBs saed32_rvt.ndm]
set NETLIST [file join $REPO_ROOT outputs synthesis ${TOP}_mapped.v]
set SDC [file join $REPO_ROOT outputs synthesis ${TOP}_mapped.sdc]
set DESIGN_LIB [file join $DFT_RUN_DIR db kuidamos_pre_dft.dlib]
if {[file exists $DESIGN_LIB]} {error "Recusa sobrescrever biblioteca existente"}
create_lib $DESIGN_LIB -technology [file join $SAED32_REF_ROOT tech saed32nm_1p9m.tf] \
    -ref_libs [list $NDM]
read_verilog -top $TOP $NETLIST
require_true [link_block] "Link da netlist M8"
metric import_link_completed 1
set INPUT_SIGNATURE [cell_signature]
set LEAVES [get_cells -hierarchical -filter {is_hierarchical == false}]
set SEQUENTIAL [filter_collection $LEAVES {is_sequential == true}]
set UNRESOLVED [filter_collection $LEAVES {is_unbound == true || is_unmapped == true || design_type == black_box}]
metric leaf_cells [sizeof_collection $LEAVES]
metric sequential_cells [sizeof_collection $SEQUENTIAL]
metric unresolved_cells [sizeof_collection $UNRESOLVED]
metric clock_gating_cells [sizeof_collection [filter_collection $LEAVES {is_integrated_clock_gating_cell == true}]]
if {[sizeof_collection $UNRESOLVED] != 0} {error "Referências não resolvidas/black boxes"}
if {[sizeof_collection $LEAVES] != 1256 || [sizeof_collection $SEQUENTIAL] != 115 ||
    [sizeof_collection [filter_collection $SEQUENTIAL {ref_name == DFFX1_RVT}]] != 115} {
    error "Inventário diverge da baseline M8 revisada (1256 células, 115 DFFX1_RVT)"
}
set inventory [open [file join $RPT_DIR sequential_cells.tsv] w]
puts $inventory "instance\treference\tclock_net"
foreach_in_collection cell $SEQUENTIAL {
    set name [get_object_name $cell]
    set clock_net [get_object_name [get_nets -of_objects [get_pins $name/CLK]]]
    puts $inventory "$name\t[get_attribute $cell ref_name]\t$clock_net"
    if {$clock_net ne "clk"} {error "Clock inesperado em $name: $clock_net"}
}
close $inventory
redirect -file [file join $RPT_DIR library.rpt] {report_lib -include_db_mapping -cell_summary saed32_rvt}
redirect -file [file join $RPT_DIR scan_library_cells.rpt] {
    foreach name {DFFX1_RVT SDFFX1_RVT SDFFX2_RVT} {
        set cells [get_lib_cells */$name]
        if {[sizeof_collection $cells] != 1} {error "Célula RVT ausente/ambígua: $name"}
        puts "CELL [get_object_name $cells]"
        puts "PINS [get_object_name [get_lib_pins -of_objects $cells]]"
        puts "SEQUENTIAL [get_attribute $cells is_sequential]"
        puts "DONT_USE [get_attribute $cells dont_use]"
    }
}

# PVT da síntese M8 e pane da NDM: ss0p95v125c = slow/0.99, 0.95 V, 125 C.
remove_scenarios -all
remove_modes -all
remove_corners -all
create_corner ss0p95v125c
set_process_number 0.99
set_process_label slow
set_voltage 0.95
set_temperature 125
create_mode functional
create_scenario -mode functional -corner ss0p95v125c
current_scenario functional::ss0p95v125c
read_sdc $SDC
if {[sizeof_collection [get_clocks *]] != 1 || [get_attribute [get_clocks clk] period] != 10.0} {
    error "Clock funcional incompatível com M8"
}
metric functional_period_ns [get_attribute [get_clocks clk] period]
redirect -file [file join $RPT_DIR units.rpt] {report_units}
redirect -file [file join $RPT_DIR scenarios.rpt] {report_scenarios}
redirect -file [file join $RPT_DIR check_design.rpt] {
    set structural_result [check_design -checks {netlist unbound} \
        -ems_database [file join $RPT_DIR check_design.ems] \
        -log_file [file join $RPT_DIR check_design_details.log]]
}
metric check_design_return $structural_result
redirect -file [file join $RPT_DIR update_timing.rpt] {update_timing}
redirect -file [file join $RPT_DIR check_timing.rpt] {set timing_result [check_timing -all]}
metric check_timing_return $timing_result
redirect -file [file join $RPT_DIR timing_max.rpt] {report_timing -delay_type max -max_paths 10 -nosplit}
redirect -file [file join $RPT_DIR timing_min.rpt] {report_timing -delay_type min -max_paths 10 -nosplit}
redirect -file [file join $RPT_DIR pvt.rpt] {report_pvt -nosplit}
redirect -file [file join $RPT_DIR pvt_mismatches.rpt] {report_pvt -object_list $LEAVES -mismatched -nosplit}
set pvt_file [open [file join $RPT_DIR effective_pvt.tsv] w]
puts $pvt_file "instance\tprocess_early\tprocess_late\tvoltage_early\tvoltage_late\ttemperature_early\ttemperature_late"
foreach_in_collection cell $LEAVES {
    set row [list [get_object_name $cell]]
    foreach {attribute expected} {effective_process_number_early 0.99 effective_process_number_late 0.99
        effective_voltage_early 0.95 effective_voltage_late 0.95
        effective_temperature_early 125 effective_temperature_late 125} {
        set value [get_attribute $cell $attribute]
        lappend row $value
        if {![string is double -strict $value] || abs($value - $expected) > 0.0001} {
            error "PVT efetivo divergente: [get_object_name $cell], $attribute=$value"
        }
    }
    puts $pvt_file [join $row "\t"]
}
close $pvt_file
metric effective_pvt_verified_cells [sizeof_collection $LEAVES]
redirect -file [file join $RPT_DIR active_library.rpt] {report_lib -show_active_panes saed32_rvt}
# Sem floorplan/placement/RC extraído: timing diagnóstico, não fechamento físico.
metric timing_analysis_executed 1
