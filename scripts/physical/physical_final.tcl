# ECO, verificações e potência em cópias do checkpoint roteado.
set ::m10_routing_procedures_only true
source [file join [file dirname [file normalize [info script]]] routing_initial.tcl]
unset ::m10_routing_procedures_only

proc close_drvs {} {
    foreach {name from to} {
        u_resize_nn_core/ropt_mc_inst_138 DELLN1X2_RVT NBUFFX4_RVT
        ropt_mt_inst_129 DELLN1X2_RVT NBUFFX4_RVT
        u_crop_core/U142 AO22X1_RVT AO22X2_RVT
        pixel_out_reg_7_ SDFFX1_RVT SDFFX2_RVT
    } {
        set cell [get_cells $name]
        set ref [get_lib_cells */$to]
        require [expr {[get_attribute $cell ref_name] eq $from && [sizeof_collection $ref] == 1}] "Referência inesperada: $name"
        set protected [get_attribute $cell dont_touch]
        if {$protected eq "true"} {set_dont_touch $cell false}
        require [expr {[size_cell $cell -lib_cell $ref] eq "1" &&
            [get_attribute $cell ref_name] eq $to}] "ECO de sizing falhou: $name"
        if {$protected eq "true"} {set_dont_touch $cell true}
        puts "FINAL_RESIZE $name $from $to"
    }

    # NOR4X1_RVT é o NOR4 de maior drive da referência disponível.
    # A carga de n421 passa a ser dirigida por um buffer próximo a U717/Y.
    set driver [get_pins U717/Y]
    require [expr {[get_object_name [get_nets -of_objects $driver]] eq "n421"}] "Driver de n421 mudou"
    set new [insert_buffer -new_cell_names FINAL_N421_BUF -new_net_names final_n421_buffered         -snap $driver -lib_cell [get_lib_cells */NBUFFX2_RVT]]
    require [expr {[sizeof_collection $new] == 1}] "Buffering de n421 falhou"
    connect_pg_net -automatic -pg -report_connection_summary true
    redirect -file reports/eco_legalize.rpt {set legal [legalize_placement]}
    require [expr {$legal eq "1"}] "Legalização do ECO falhou"
    redirect -tee -file reports/route_eco.rpt {route_eco -reroute modified_nets_first_then_others}
}

proc verify_drvs {} {
    foreach_in_collection sc [get_scenarios *] {
        set tag [string map {:: .} [get_object_name $sc]]
        set report [report_text reports/$tag.drv.rpt]
        foreach kind {max_transition max_capacitance} {
            require [regexp -line [format {^\s*Number of %s violation\(s\): 0\s*$} $kind] $report] "DRV em $tag: $kind"
        }
    }
}

proc close_design {} {
    close_drvs
    verify_design
    report_drv
    verify_drvs
    report_clock
    report_scenario_timing
    redirect -file reports/area.rpt {report_area -logical -significant_digits 4}
    redirect -file reports/utilization.rpt {report_utilization -verbose}
    redirect -file reports/congestion.rpt {report_congestion -mode summary -honor_ignored_layers}
    redirect -file reports/units.rpt {report_units}
    foreach_in_collection sc [get_scenarios *] {
        set scenario [get_object_name $sc]
        set tag [string map {:: .} $scenario]
        redirect -file reports/$tag.coverage.rpt {
            check_timing -scenarios $scenario -override_defaults {no_clock no_input_delay unconstrained_endpoints} -format detail
        }
    }
    foreach_in_collection corner [get_corners *] {
        set name [get_object_name $corner]
        write_parasitics -corner $name -format spef -output reports/$name
        foreach mode {functional scan_shift} {
            write_sdf -corner $name -mode $mode -significant_digits 4 reports/$mode.$name.sdf
        }
    }
    save_block -as physical_candidate
    save_lib
}

proc power_analysis {} {
    set scenario functional::ss0p95v125c
    set corner [get_corners ss0p95v125c]
    set_scenario_status $scenario -dynamic_power true -leakage_power true
    current_scenario $scenario
    # A tensão nominal da SAED32 RVT e do corner ss0p95v125c é 0,95 V.
    # As atribuições valem apenas na cópia usada para estimar potência.
    set_voltage 0.95 -corners $corner
    set_voltage 0.95 -corners $corner -object_list [get_nets VDD]
    set_voltage 0.0 -corners $corner -object_list [get_nets VSS]
    redirect -file reports/pvt.rpt {report_pvt}
    redirect -file reports/units.rpt {report_units}
    redirect -tee -file reports/read_saif.rpt {
        read_saif $::env(M10_PHYSICAL_SAIF) -strip_path tb_kuidamos_pixel_frontend/u_dut -scenarios $scenario -report
    }
    redirect -tee -file reports/power.rpt {
        report_power -scenarios $scenario -significant_digits 6
    }
    redirect -file reports/coverage.rpt {report_activity -driver -scenarios $scenario}
    redirect -file reports/activity_statistics.rpt {report_activity_statistics -scenarios $scenario}
}

if {[catch {
    file mkdir reports
    foreach feature {Fusion-Compiler-NX Fusion-Compiler-FE-NX Fusion-Compiler-BE-NX} {
        require [expr {[get_licenses $feature] eq "1"}] "Checkout falhou: $feature"
    }
    open_lib [file normalize $::env(M10_PHYSICAL_DLIB)]
    switch -- $::env(M10_PHYSICAL_STAGE) {
        signals {
            copy_block -from_block routing_initial -to_block physical_work
            open_linked physical_work
            close_design
        }
        power {
            copy_block -from_block physical_candidate -to_block physical_power_work
            open_linked physical_power_work
            power_analysis
        }
        promote {
            copy_block -from_block physical_candidate -to_block physical_final
            save_lib
        }
        readback {
            open_linked physical_final
            verify_design
        }
        default {error "Etapa física inválida"}
    }
} message options]} {
    puts stderr "M10_PHYSICAL_INCOMPLETE $message"
    puts stderr [dict get $options -errorinfo]
    exit 1
}
puts M10_PHYSICAL_STAGE_COMPLETED
exit 0
