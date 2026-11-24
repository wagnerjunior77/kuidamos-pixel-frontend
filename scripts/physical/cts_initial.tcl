# Pin placement e síntese da árvore em cópia do placement validado.
set sh_continue_on_error false
source [file join [file dirname [file normalize [info script]]] placement_timing.tcl]

proc require {condition message} {
    if {!$condition} {error $message}
}

proc read_report {path} {
    set stream [open $path r]
    set result [read $stream]
    close $stream
    return $result
}

proc check_geometry {} {
    set ports [get_ports -filter {port_type != power && port_type != ground} *]
    require [expr {[sizeof_collection $ports] == 126 && [sizeof_collection [get_site_rows *]] == 52}] "Inventário físico inesperado"
    foreach_in_collection port $ports {
        require [expr {[sizeof_collection [get_terminals -quiet -of_objects $port]] == 1}] "Shape ausente ou duplicado: [get_object_name $port]"
    }
    redirect -file reports/pins.rpt {
        check_pin_placement -self -ports $ports -missing true -layers true -wire_track true \
            -sides true -pin_spacing true -technology_spacing_rules true -shorts true -pre_route true -off_edge true
    }
    require [regexp -line {^Total Violations\s*\|\s*0\s*$} [read_report reports/pins.rpt]] "Violação de pino"
    redirect -file reports/legality.rpt {set legal [check_legality]}
    require [expr {$legal eq "1" && [regexp -line {^TOTAL 0 Violations\.$} [read_report reports/legality.rpt]]}] "Placement ilegal"

    redirect -file reports/pg_drc.rpt {
        check_pg_drc -nets {VDD VSS} -ignore_clock_nets false -no_gui -output reports/pg_drc.txt
    }
    redirect -file reports/pg_connectivity.rpt {
        set floating [check_pg_connectivity -nets {VDD VSS} -check_std_cell_pins all \
            -check_block_pins all -write_connectivity_file reports/pg_connectivity.txt]
    }
    set pg [read_report reports/pg_connectivity.txt]
    require [expr {[sizeof_collection $floating] == 0 &&
        [regexp -all {Number of disjoint networks: 1\y} $pg] == 2 &&
        [regexp -all {Number of floating std cells: 0\y} $pg] == 2 &&
        [regexp -all {Number of std cells with unconnected port: [1-9][0-9]*} $pg] == 0 &&
        [regexp -line {^No errors found\.$} [read_report reports/pg_drc.rpt]]}] "PG DRC ou conectividade falhou"
}

proc export_design {} {
    write_def -units 1000 -include {rows_tracks cells ports scanchains specialnets vias nets} reports/design.def
    write_verilog -hierarchy all [file normalize reports/netlist.v]
}

proc report_electrical {} {
    foreach_in_collection scenario [get_scenarios *] {
        set name [get_object_name $scenario]
        current_scenario $name
        set prefix reports/[string map {:: .} $name]
        redirect -file $prefix.drv.rpt {
            report_constraints -scenarios $name -all_violators -nosplit -significant_digits 4
        }
        set controls [get_nets -of_objects [get_ports {clk reset_n scan_enable}]]
        redirect -file $prefix.controls.rpt {report_net_fanout -connections $controls}
    }
    current_scenario functional::ss0p95v125c
}

proc verify_scenarios {} {
    set expected {}
    foreach {mode period} {functional 10 scan_shift 100 scan_capture_probe 100} {
        foreach corner {ss0p95v125c ff0p95vn40c} {
            set scenario ${mode}::${corner}
            lappend expected $scenario
            current_scenario $scenario
            require [expr {[sizeof_collection [get_clocks *]] == 1 &&
                [get_attribute [get_clocks clk] period] == $period}] "Clock incorreto em $scenario"
        }
    }
    require [expr {[lsort [get_object_name [get_scenarios *]]] eq [lsort $expected]}] "Cenários MMMC divergentes"
    current_scenario functional::ss0p95v125c
}

proc run_cts {} {
    set refs [get_lib_cells -quiet {*/NBUFFX2_RVT */NBUFFX4_RVT */NBUFFX8_RVT */NBUFFX16_RVT */NBUFFX32_RVT
        */INVX1_RVT */INVX2_RVT */INVX4_RVT */INVX8_RVT}]
    require [expr {[sizeof_collection $refs] == 9}] "Referências CTS incompletas"
    puts "CTS_REFS [get_object_name $refs]"
    set_lib_cell_purpose -exclude cts [get_lib_cells */*]
    set_lib_cell_purpose -include cts $refs
    set_app_options -name cts.common.enable_auto_skew_target_for_local_skew -value false
    foreach_in_collection mode [get_modes *] {
        current_mode [get_object_name $mode]
        set_clock_tree_options -clocks [get_clocks clk] -corners [get_corners *] -target_skew 0.050
        set_clock_routing_rules -clocks [get_clocks clk] -net_type all -default_rule \
            -min_routing_layer M3 -max_routing_layer M6
    }
    current_scenario functional::ss0p95v125c
    # Um driver interno limita a carga direta da porta ideal a uma entrada.
    set root [insert_buffer -new_cell_names CTS_ROOT -new_net_names cts_root_net \
        [get_ports clk] -lib_cell [get_lib_cells */NBUFFX16_RVT]]
    require [expr {[sizeof_collection $root] == 1}] "Inserção do driver raiz falhou"
    set_dont_touch $root true
    redirect -file reports/root_legalize.rpt {set root_legal [legalize_placement]}
    require [expr {$root_legal eq "1"}] "Legalização do driver raiz falhou"
    synthesize_clock_trees -clocks [get_clocks clk]
    redirect -file reports/connect_new_pg.rpt {connect_pg_net -automatic -pg -report_connection_summary true}
    redirect -file reports/legalize.rpt {set legalized [legalize_placement]}
    require [expr {$legalized eq "1"}] "Legalização pós-CTS falhou"
    foreach_in_collection scenario [get_scenarios *] {
        set name [get_object_name $scenario]
        current_scenario $name
        set_propagated_clock [get_clocks clk]
        set prefix reports/[string map {:: .} $name]
        foreach type {latency transition skew} {
            redirect -file $prefix.clock_$type.rpt {
                report_clock_timing -type $type -scenarios $name -nworst 115 -significant_digits 4
            }
        }
    }
    redirect -file reports/clock_capacitance.rpt {
        report_clock_qor -histogram_type capacitance -scenarios [get_scenarios *] -significant_digits 4
    }
    redirect -file reports/clock_summary.rpt {
        report_clock_qor -type summary -scenarios [get_scenarios *] -significant_digits 4
    }
    report_scenario_timing
    report_electrical
    redirect -file reports/area.rpt {report_area -logical -significant_digits 4}
    redirect -file reports/utilization.rpt {report_utilization -verbose}
    redirect -file reports/congestion.rpt {report_congestion -mode summary -honor_ignored_layers -rerun_global_router}
    redirect -file reports/scan.rpt {check_scan_chain}
    export_design
    check_geometry
    save_block -as cts_candidate
    save_lib
}

if {[catch {
    file mkdir reports
    foreach feature {Fusion-Compiler-NX Fusion-Compiler-FE-NX Fusion-Compiler-BE-NX} {
        require [expr {[get_licenses $feature] eq "1"}] "Checkout falhou: $feature"
    }
    foreach command {place_pins check_pin_placement synthesize_clock_trees clock_opt
        set_clock_tree_options set_clock_routing_rules set_lib_cell_purpose insert_buffer report_clock_timing report_clock_qor} {
        redirect -file reports/help_$command.rpt {help -verbose $command}
    }
    open_lib [file normalize $::env(M10_CTS_DLIB)]
    switch -- $::env(M10_CTS_STAGE) {
        pins {
            copy_block -from_block placement_initial -to_block pins_work
            open_block pins_work
            require [expr {[link_block] eq "1"}] "Vínculo do placement falhou"
            verify_scenarios
            set ports [get_ports -filter {port_type != power && port_type != ground} *]
            redirect -file reports/place_pins.rpt {set result [place_pins -self -ports $ports]}
            require [expr {$result eq "1"}] "place_pins falhou"
            check_geometry
            report_electrical
            export_design
            save_block -as pins_initial
            save_lib
        }
        cts {
            copy_block -from_block pins_initial -to_block cts_work
            open_block cts_work
            require [expr {[link_block] eq "1"}] "Vínculo dos pinos falhou"
            verify_scenarios
            run_cts
        }
        promote {
            copy_block -from_block cts_candidate -to_block cts_initial
            save_lib
        }
        readback {
            open_block cts_initial
            require [expr {[link_block] eq "1"}] "Readback CTS falhou"
            verify_scenarios
            check_geometry
            export_design
        }
        default {error "Etapa CTS inválida"}
    }
} message options]} {
    puts stderr "M10_CTS_INCOMPLETE $message"
    puts stderr [dict get $options -errorinfo]
    exit 1
}
puts M10_CTS_STAGE_COMPLETED
exit 0
