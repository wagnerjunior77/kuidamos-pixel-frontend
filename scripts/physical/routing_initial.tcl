# Routing de clock, sinais e otimização pós-route em uma DLIB derivada.
set sh_continue_on_error false
source [file join [file dirname [file normalize [info script]]] placement_timing.tcl]

proc require {condition message} {
    if {!$condition} {error $message}
}

proc report_text {path} {
    set input [open $path]
    set result [read $input]
    close $input
    return $result
}

proc open_linked {block} {
    open_block $block
    require [expr {[link_block] eq "1"}] "Vínculo falhou: $block"
    require [expr {[sizeof_collection [get_scenarios *]] == 6}] "Cenários herdados incompletos"
    foreach_in_collection sc [get_scenarios *] {
        set name [get_object_name $sc]
        current_scenario $name
        set period [expr {[string match functional::* $name] ? 10 : 100}]
        require [expr {[sizeof_collection [get_clocks *]] == 1 &&
            [get_attribute [get_clocks clk] period] == $period}] "Clock inesperado: $name"
        set_propagated_clock [get_clocks clk]
    }
    current_scenario functional::ss0p95v125c
}

proc pg_and_placement {} {
    set cells [get_cells -hierarchical -filter {is_hierarchical == false}]
    set count [sizeof_collection $cells]
    require [expr {[sizeof_collection [filter_collection $cells {is_placed == true}]] == $count &&
        [sizeof_collection [filter_collection $cells {ref_name == SDFFX1_RVT || ref_name == SDFFX2_RVT}]] == 115 &&
        [sizeof_collection [get_site_rows *]] == 52}] "Inventário ou placement divergente"
    redirect -file reports/legality.rpt {set legal [check_legality]}
    require [expr {$legal eq "1" && [regexp -line {^TOTAL 0 Violations\.$} [report_text reports/legality.rpt]]}] "Placement ilegal"
    redirect -file reports/pg_drc.rpt {
        check_pg_drc -nets {VDD VSS} -ignore_clock_nets false -no_gui -output reports/pg_drc.txt
    }
    require [regexp -line {^No errors found\.$} [report_text reports/pg_drc.rpt]] "PG DRC falhou"
    redirect -file reports/pg_conn.rpt {
        set floating [check_pg_connectivity -nets {VDD VSS} -check_std_cell_pins all \
            -check_block_pins all -write_connectivity_file reports/pg_conn.txt]
    }
    set pg [report_text reports/pg_conn.txt]
    require [expr {[sizeof_collection $floating] == 0 &&
        [regexp -all "Number of std cells: $count\\y" $pg] == 2 &&
        [regexp -all {Number of disjoint networks: 1\y} $pg] == 2 &&
        [regexp -all {Number of floating std cells: 0\y} $pg] == 2 &&
        [regexp -all {Number of std cells with unconnected port: [1-9][0-9]*} $pg] == 0}] "Conectividade PG incompleta"
}

proc check_clock_routes {} {
    set clocks [get_nets -hier -filter {net_type == clock}]
    require [expr {[sizeof_collection $clocks] == 6}] "Inventário de nets de clock divergente"
    redirect -file reports/clock_routes.rpt {
        check_routes -nets $clocks -open_net true -report_all_open_nets true
    }
    require [regexp -line {^Total number of open nets = 0,} [report_text reports/clock_routes.rpt]] "Clock com open"
    return $clocks
}

proc check_all_routes {tag} {
    set path reports/$tag.rpt
    redirect -file $path {check_routes -open_net true -report_all_open_nets true -drc true}
    set summary [report_text $path]
    require [expr {[regexp -line {^Total number of open nets = 0,} $summary] &&
        [regexp -line {^Total number of DRCs = 0\s*$} $summary]}] "Opens ou DRC remanescentes em $tag"
}

proc export_design {} {
    write_def -units 1000 -include {rows_tracks cells ports scanchains specialnets vias nets} reports/design.def
    write_def -units 1000 -include {scanchains} reports/scan.def
    write_verilog -hierarchy all [file normalize reports/netlist.v]
}

proc report_clock {} {
    redirect -file reports/clock_qor.rpt {
        report_clock_qor -type summary -scenarios [get_scenarios *] -significant_digits 4
    }
    foreach_in_collection sc [get_scenarios *] {
        set scenario [get_object_name $sc]
        current_scenario $scenario
        set tag [string map {:: .} $scenario]
        foreach type {latency transition skew} {
            redirect -file reports/$tag.clock_$type.rpt {
                report_clock_timing -type $type -scenarios $scenario -nworst 115 -significant_digits 4
            }
        }
    }
    current_scenario functional::ss0p95v125c
}

proc report_drv {{directory reports}} {
    file mkdir $directory
    foreach_in_collection sc [get_scenarios *] {
        set scenario [get_object_name $sc]
        current_scenario $scenario
        set tag [string map {:: .} $scenario]
        redirect -file $directory/$tag.drv.rpt {
            report_constraints -scenarios $scenario -all_violators -nosplit -significant_digits 4
        }
        redirect -file $directory/$tag.control_fanout.rpt {
            report_net_fanout -connections [get_nets -of_objects [get_ports {clk reset_n scan_enable}]]
        }
    }
    current_scenario functional::ss0p95v125c
}

proc verify_design {} {
    check_all_routes routes
    check_clock_routes
    pg_and_placement
    redirect -file reports/scan.rpt {check_scan_chain}
    set scan [report_text reports/scan.rpt]
    require [expr {[regexp {VALIDATED\s*:\s*1\y} $scan] && [regexp {FAILED\s*:\s*0\y} $scan]}] "Scan DEF inválido"
    export_design
}

proc route_clock_stage {} {
    foreach {name expected target} {
        U559 NBUFFX2_RVT NBUFFX8_RVT
        U316 NBUFFX2_RVT NBUFFX8_RVT
        U321 INVX0_RVT INVX4_RVT
    } {
        set cell [get_cells $name]
        set ref [get_lib_cells */$target]
        require [expr {[get_attribute $cell ref_name] eq $expected && [sizeof_collection $ref] == 1}] "Sizing incompatível: $name"
        set result [size_cell $cell -lib_cell $ref]
        require [expr {$result eq "1" && [get_attribute $cell ref_name] eq $target}] "Sizing falhou: $name"
        puts "ROUTE_RESIZE $name $expected $target"
    }
    connect_pg_net -automatic -pg -report_connection_summary true
    redirect -file reports/legalize.rpt {set legal [legalize_placement]}
    require [expr {$legal eq "1"}] "Legalização após sizing falhou"
    pg_and_placement
    redirect -tee -file reports/route_group.rpt {route_group -all_clock_nets}
    require [regexp -line {^Total number of DRCs = 0\s*$} [report_text reports/route_group.rpt]] "DRC no roteamento de clock"
    check_clock_routes
    pg_and_placement
    report_clock
    report_scenario_timing
    report_drv
    export_design
    save_block -as clock_routed
    save_lib
}

proc resize_scan_drivers {} {
    set target [get_lib_cells */SDFFX2_RVT]
    require [expr {[sizeof_collection $target] == 1}] "Referência SDFFX2_RVT indisponível"
    foreach name {pixel_out_valid_reg frame_active_q_reg cfg_x_start_q_reg_9_ pixel_out_reg_5_ cfg_error_reg
                  pixel_out_reg_4_ pixel_out_reg_6_ cfg_crop_enable_q_reg pixel_out_reg_1_} {
        set cell [get_cells $name]
        require [expr {[get_attribute $cell ref_name] eq "SDFFX1_RVT"}] "Referência SDFF inicial inesperada: $name"
        set_dont_touch $cell false
        require [expr {[size_cell $cell -lib_cell $target] eq "1" &&
            [get_attribute $cell ref_name] eq "SDFFX2_RVT"}] "Sizing SDFF falhou: $name"
        set_dont_touch $cell true
        puts "ROUTE_RESIZE $name SDFFX1_RVT SDFFX2_RVT"
    }
    connect_pg_net -automatic -pg -report_connection_summary true
    redirect -file reports/eco_legalize.rpt {set legal [legalize_placement]}
    require [expr {$legal eq "1"}] "Legalização após ECO de SDFF falhou"
    redirect -tee -file reports/route_eco.rpt {route_eco -reroute modified_nets_first_then_others}
}

proc route_signal_stage {} {
    redirect -tee -file reports/route_auto.rpt {route_auto}
    check_all_routes before_opt
    report_drv reports/pre_opt

    # Preserve a ordem serial, as derivações Q/QN e a topologia de clock.
    set seq [get_cells -hier -filter {ref_name == SDFFX1_RVT}]
    set protected_cells [get_cells -hier -filter {ref_name == SDFFX1_RVT || full_name =~ *CTS* || full_name =~ ctosc*}]
    set_dont_touch $protected_cells true
    set scan_pins [get_pins -of_objects $seq -filter {name == SI || name == SE || name == CLK}]
    set protected [add_to_collection -unique [get_nets -of_objects $scan_pins] [get_nets -of_objects [get_ports scan_out]]]
    set protected [add_to_collection -unique $protected [get_nets -hier -filter {net_type == clock}]]
    require [expr {[sizeof_collection $protected] == 123 && [sizeof_collection $protected_cells] == 120}] "Proteção de scan e clock incompleta"
    set_dont_touch $protected true
    redirect -tee -file reports/route_opt.rpt {route_opt}
    connect_pg_net -automatic -pg -report_connection_summary true
    check_all_routes after_opt
    pg_and_placement
    report_drv reports/post_opt
    resize_scan_drivers
    verify_design
    redirect -file reports/area.rpt {report_area -logical -significant_digits 4}
    redirect -file reports/utilization.rpt {report_utilization -verbose}
    redirect -file reports/congestion.rpt {report_congestion -mode summary -honor_ignored_layers}

    report_drv
    report_clock
    report_scenario_timing
    foreach_in_collection sc [get_scenarios *] {
        set scenario [get_object_name $sc]
        set tag [string map {:: .} $scenario]
        redirect -file reports/$tag.coverage.rpt {
            check_timing -scenarios $scenario -override_defaults {no_clock no_input_delay unconstrained_endpoints} -format detail
        }
    }
    redirect -file reports/units.rpt {report_units}
    foreach_in_collection corner [get_corners *] {
        set name [get_object_name $corner]
        write_parasitics -corner $name -format spef -output reports/$name
        foreach mode {functional scan_shift} {
            write_sdf -corner $name -mode $mode -significant_digits 4 reports/$mode.$name.sdf
        }
    }
    save_block -as routing_candidate
    save_lib
}

# Carrega os procedimentos de validação em outros estágios físicos.
if {[info exists ::m10_routing_procedures_only] && $::m10_routing_procedures_only} {
    return
}

if {[catch {
    file mkdir reports
    foreach feature {Fusion-Compiler-NX Fusion-Compiler-FE-NX Fusion-Compiler-BE-NX} {
        require [expr {[get_licenses $feature] eq "1"}] "Checkout falhou: $feature"
    }
    open_lib [file normalize $::env(M10_ROUTING_DLIB)]
    switch -- $::env(M10_ROUTING_STAGE) {
        clock {
            foreach cmd {route_group route_auto route_opt route_eco check_routes write_parasitics write_sdf size_cell} {
                redirect -file reports/help_$cmd.rpt {help -verbose $cmd}
            }
            copy_block -from_block cts_initial -to_block clock_route_work
            open_linked clock_route_work
            route_clock_stage
        }
        signals {
            copy_block -from_block clock_routed -to_block signal_route_work
            open_linked signal_route_work
            route_signal_stage
        }
        promote {
            copy_block -from_block routing_candidate -to_block routing_initial
            save_lib
        }
        readback {
            open_linked routing_initial
            verify_design
        }
        default {error "Etapa de routing inválida"}
    }
} message options]} {
    puts stderr "M10_ROUTING_INCOMPLETE $message"
    puts stderr [dict get $options -errorinfo]
    exit 1
}
puts M10_ROUTING_STAGE_COMPLETED
exit 0
