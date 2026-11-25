# Placement geométrico exploratório, sem otimização funcional.
set sh_continue_on_error false
source [file join [file dirname [file normalize [info script]]] placement_timing.tcl]

source [file join [file dirname [file normalize [info script]]] pg_rail_correction.tcl]

proc require {condition message} {
    if {!$condition} {error $message}
}

proc contents {path} {
    set f [open $path r]
    set text [read $f]
    close $f
    return $text
}

proc inventory {expected_placed} {
    set leaves [get_cells -hierarchical -filter {is_hierarchical == false}]
    set placed [filter_collection $leaves {is_placed == true}]
    set sdff [filter_collection $leaves {ref_name == SDFFX1_RVT}]
    require [expr {[sizeof_collection $leaves] == 1256 && [sizeof_collection $placed] == $expected_placed &&
        [sizeof_collection $sdff] == 115 && [sizeof_collection [get_site_rows *]] == 52}] "Inventário inesperado"
    puts "M10_PLACEMENT_INVENTORY placed=[sizeof_collection $placed] leaf=[sizeof_collection $leaves] sdff=[sizeof_collection $sdff]"
    return $leaves
}

proc write_placement_cells {leaves} {
    set f [open reports/cells.tsv w]
    puts $f "cell\tref\torientation\tx0\ty0\tx1\ty1"
    foreach_in_collection cell $leaves {
        set box [get_attribute $cell boundary_bbox]
        puts $f [join [concat [list [get_object_name $cell] [get_attribute $cell ref_name] \
            [get_attribute $cell orientation]] {*}$box] "\t"]
    }
    close $f
}

proc check_placed_power_grid {} {
    redirect -file reports/pg_connectivity.rpt {
        set floating [check_pg_connectivity -nets {VDD VSS} -check_std_cell_pins all \
            -check_block_pins all -write_connectivity_file reports/pg_connectivity.txt]
    }
    set report [contents reports/pg_connectivity.txt]
    require [expr {[sizeof_collection $floating] == 0 &&
        [regexp -all {Number of disjoint networks: 1\y} $report] == 2 &&
        [regexp -all {Number of floating std cells: 0\y} $report] == 2 &&
        [regexp -all {Number of std cells with unconnected port: [1-9][0-9]*} $report] == 0}] "Conectividade PG incompleta"
    redirect -file reports/pg_drc.rpt {
        check_pg_drc -nets {VDD VSS} -ignore_clock_nets false -no_gui -output reports/pg_drc.txt
    }
    return [regexp -line {^No errors found\.$} [contents reports/pg_drc.rpt]]
}

if {[catch {
    file mkdir reports
    foreach cmd {create_placement legalize_placement check_legality report_congestion report_constraints
        check_pg_drc check_pg_connectivity check_pin_placement} {
        redirect -file reports/help_${cmd}.rpt {help -verbose $cmd}
    }
    redirect -file reports/licenses.rpt {
        foreach feature {Fusion-Compiler-NX Fusion-Compiler-FE-NX Fusion-Compiler-BE-NX} {
            require [expr {[get_licenses $feature] eq "1"}] "Checkout falhou: $feature"
        }
        list_licenses
    }
    require [regexp {WaveformTable "_default_WFT_"\s*\{\s*Period '100ns';\s*Waveforms\s*\{\s*"clk"\s*\{\s*P\s*\{\s*'0ns' D;\s*'45ns' U;\s*'55ns' D;} [contents protocol.spf]] "Clock de shift difere do SPF esperado"
    open_lib [file normalize kuidamos_preview.dlib]
    open_block powerplan_initial
    require [expr {[link_block] eq "1"}] "Checkpoint não vinculado"
    inventory 0
    if {$env(M10_CORRECT_M1) eq "1"} {
        correct_m1_rails
        copy_block -from_block powerplan_corrected -to_block placement_work
        open_block placement_work
        require [expr {[link_block] eq "1"}] "Vínculo do PG corrigido falhou"
    }
    puts "M10_SCAN_CHAINS_BEFORE [get_scan_chain_names -test_mode Internal_scan]"
    configure_timing
    current_scenario functional::ss0p95v125c
    redirect -file reports/placement.rpt {set place [create_placement -floorplan -effort high]}
    require [expr {$place eq "1"}] "create_placement não concluiu"
    redirect -file reports/legalize.rpt {set status [legalize_placement]}
    require [expr {$status eq "1"}] "legalize_placement não concluiu"
    set leaves [inventory 1256]
    redirect -file reports/legality.rpt {set legal [check_legality]}
    require [expr {$legal eq "1" && [regexp -line {^TOTAL 0 Violations\.$} [contents reports/legality.rpt]]}] "Placement ilegal"
    write_placement_cells $leaves
    redirect -file reports/utilization.rpt {report_utilization -verbose}
    redirect -file reports/area.rpt {report_area -logical -significant_digits 4}

    # Colete todas as evidências de diagnóstico mesmo com DRC PG não nulo.
    set pg_clean [check_placed_power_grid]
    # A análise funcional mantém SE=0. Libere o case analysis para o
    # rastreamento estrutural da cadeia no modo interno de teste.
    remove_case_analysis [get_ports scan_enable]
    set chain_names [get_scan_chain_names -test_mode Internal_scan]
    puts "M10_SCAN_CHAINS $chain_names"
    require [expr {[llength $chain_names] == 1}] "Quantidade de cadeias inesperada"
    redirect -file reports/scan_check.rpt {check_scan_chain}
    set scan [contents reports/scan_check.rpt]
    require [expr {[regexp -line {^\s*VALIDATED\s*:\s*1\s*$} $scan] &&
        [regexp -line {^\s*FAILED\s*:\s*0\s*$} $scan]}] "check_scan_chain falhou"
    redirect -file reports/scan_path.rpt {report_scan_path -test_mode Internal_scan}
    set_case_analysis 0 [get_ports scan_enable]
    set control_nets [get_nets -of_objects [get_ports {clk reset_n scan_enable}]]
    redirect -file reports/control_fanout.rpt {report_net_fanout -connections $control_nets}
    set ports [get_ports -filter {port_type != power && port_type != ground} *]
    redirect -file reports/pin_constraints.rpt {report_pin_constraints -ports $ports}
    # O relatório de missing registra portas sem shapes no layout atual.
    redirect -file reports/pin_access.rpt {check_pin_placement -self -ports $ports -missing true}
    report_scenario_timing
    foreach_in_collection scenario [get_scenarios *] {
        set name [get_object_name $scenario]
        set filename [string map {:: .} $name]
        redirect -file reports/$filename.drv.rpt {
            report_constraints -scenarios $name -all_violators -nosplit
        }
    }
    current_scenario functional::ss0p95v125c

    # Mapa global só para estimativa de congestionamento.
    redirect -file reports/congestion.rpt {report_congestion -mode summary -honor_ignored_layers -rerun_global_router}
    write_def -units 1000 -include {rows_tracks cells ports scanchains specialnets vias nets} reports/placement.def
    write_verilog -hierarchy all [file normalize reports/netlist.v]
    if {$pg_clean} {
        save_block -as placement_initial
        save_lib
    } else {
        puts M10_PLACEMENT_PG_DRC_BLOCKED
    }
} message options]} {
    puts stderr "M10_PLACEMENT_INCOMPLETE $message"
    if {[dict exists $options -errorinfo]} {puts stderr [dict get $options -errorinfo]}
    exit 1
}
puts M10_PLACEMENT_DIAGNOSTICS_COMPLETED
exit 0
