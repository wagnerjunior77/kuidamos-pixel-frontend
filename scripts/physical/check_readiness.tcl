# M10, abertura e verificações em cópia da dlib, em diretório novo.
set sh_continue_on_error false

proc must {condition message} {
    if {!$condition} {error $message}
}

if {[catch {
    file mkdir reports
    redirect -file reports/licenses_before.rpt {list_licenses}
    foreach feature {Fusion-Compiler-NX Fusion-Compiler-FE-NX Fusion-Compiler-BE-NX} {
        set present [check_license $feature -quiet]
        puts "M10_FEATURE $feature $present"
        must [expr {$present eq "1"}] "Feature indisponível: $feature"
        set acquired [get_licenses $feature]
        puts "M10_CHECKOUT $feature $acquired"
        must [expr {$acquired eq "1"}] "Checkout falhou: $feature"
    }
    redirect -file reports/licenses_after.rpt {list_licenses}

    open_lib [file normalize kuidamos_preview.dlib]
    open_block scan_inserted
    puts "M10_BLOCK [get_object_name [current_block]]"
    must [expr {[link_block] eq "1"}] "Falha no vínculo do checkpoint"
    set ref [file normalize $env(SAED32_REF_ROOT)]
    set expected_ndm [file join $ref CLIBs saed32_rvt.ndm]
    redirect -variable ref_report {report_ref_libs}
    set output [open reports/ref_libs.rpt w]
    puts $output $ref_report
    close $output
    must [expr {[string first $expected_ndm $ref_report] >= 0}] "A NDM vinculada difere de SAED32_REF_ROOT"

    set leaves [get_cells -hierarchical -filter {is_hierarchical == false}]
    set unbound [filter_collection $leaves {is_unbound == true || is_unmapped == true || design_type == black_box}]
    set sequential [filter_collection $leaves {is_sequential == true}]
    set sdffs [filter_collection $sequential {ref_name == SDFFX1_RVT}]
    set placed [filter_collection $leaves {is_placed == true}]
    puts "M10_INVENTORY leaf=[sizeof_collection $leaves] sdff=[sizeof_collection $sdffs] unbound=[sizeof_collection $unbound] placed=[sizeof_collection $placed]"
    must [expr {[sizeof_collection $leaves] == 1256 && [sizeof_collection $unbound] == 0 &&
        [sizeof_collection $sequential] == 115 && [sizeof_collection $sdffs] == 115 &&
        [sizeof_collection $placed] == 0}] "Inventário físico/lógico difere da referência M9"

    must [expr {[get_scan_chain_names -test_mode Internal_scan] eq "KUIDAMOS_CHAIN"}] "Cadeia M9 ausente"
    redirect -file reports/scan_path.rpt {report_scan_path -test_mode Internal_scan}
    redirect -file reports/scan_check.rpt {check_scan_chain}
    set report [open reports/scan_check.rpt r]
    set scan_check [read $report]
    close $report
    must [expr {[regexp -line {^\s*VALIDATED\s*:\s*1\s*$} $scan_check] &&
        [regexp -line {^\s*FAILED\s*:\s*0\s*$} $scan_check]}] "Cadeia do checkpoint inválida"
    set def_status [read_def -syntax_only [file normalize scan.def]]
    puts "M10_SCAN_DEF_SYNTAX $def_status"
    must [expr {$def_status eq "1"}] "Scan DEF recusado"
    write_verilog -hierarchy all [file normalize reports/checkpoint_netlist.v]

    set tech [get_techs]
    set metals [get_layers {M1 M2 M3 M4 M5 M6 M7 M8 M9}]
    set cuts [get_layers {VIA1 VIA2 VIA3 VIA4 VIA5 VIA6 VIA7 VIA8}]
    set vias [get_via_defs -tech $tech *]
    set sites [get_site_defs unit]
    set rows [get_site_rows -quiet *]
    puts "M10_TECH [get_object_name $tech] metals=[sizeof_collection $metals] cuts=[sizeof_collection $cuts] vias=[sizeof_collection $vias] site=[get_object_name $sites] rows=[sizeof_collection $rows]"
    must [expr {[sizeof_collection $metals] == 9 && [sizeof_collection $cuts] == 8 &&
        [sizeof_collection $vias] > 0 && [sizeof_collection $sites] == 1}] "Tecnologia física incompleta"
    set output [open reports/geometry.tsv w]
    puts $output "reference\tsite\tboundary"
    set refs [get_lib_cells -of_objects $leaves]
    foreach_in_collection cell $refs {
        set site [get_attribute -quiet $cell site_name]
        set boundary [get_attribute -quiet $cell boundary_bbox]
        must [expr {$site eq "unit" && [llength $boundary] == 2}] "Geometria ausente: [get_object_name $cell]"
        puts $output "[get_object_name $cell]\t$site\t$boundary"
    }
    close $output
    puts "M10_REFERENCE_GEOMETRY [sizeof_collection $refs]"
    foreach rail {VDD VSS} {
        set pins [get_pins -physical_context -of_objects $leaves -filter "name == $rail"]
        puts "M10_PG_PIN $rail [sizeof_collection $pins]"
        must [expr {[sizeof_collection $pins] == [sizeof_collection $leaves]}] "Pinos $rail incompletos"
    }
    redirect -file reports/power_domains.rpt {report_power_domains}
    puts "M10_PHYSICAL_PG_NETS [get_object_name [get_nets -physical_context -quiet {VDD VSS}]]"
    puts "M10_CLOCK_CANDIDATES [get_object_name [get_lib_cells -quiet {*/NBUFF* */INV*}]]"
    puts "M10_FILL_TIE_CANDIDATES [get_object_name [get_lib_cells -quiet {*/SHFILL* */TIE*}]]"

    set routing_layers [get_layers {M1 M2 M3 M4 M5 M6 M7 M8 M9 MRDL}]
    foreach_in_collection layer $routing_layers {
        puts "M10_LAYER_BEFORE [get_object_name $layer] [get_attribute $layer routing_direction] pitch=[get_attribute $layer pitch]"
    }
    # Política do laboratório SAED32, ensaiada só em memória na cópia.
    set_attribute [get_layers {M1 M3 M5 M7 M9}] routing_direction horizontal
    set_attribute [get_layers {M2 M4 M6 M8 MRDL}] routing_direction vertical
    set_ignored_layers -max_routing_layer M9
    redirect -file reports/ignored_layers_trial.rpt {report_ignored_layers}
    foreach_in_collection layer $routing_layers {
        puts "M10_LAYER_TRIAL [get_object_name $layer] [get_attribute $layer routing_direction]"
    }

    redirect -file reports/rc_before.rpt {report_parasitic_parameters}
    set techdir [file join $ref tech]
    set layermap [file join $techdir saed32nm_tf_itf_tluplus.map]
    foreach model {Cmin Cmax} {
        set loaded [read_parasitic_tech -tlup [file join $techdir saed32nm_1p9m_${model}.lv.tluplus] \
            -layermap $layermap -name M10_$model -sanity_check advanced]
        puts "M10_RC_IMPORT $model $loaded"
        must [expr {$loaded eq "1"}] "Importação RC falhou: $model"
    }
    set rc_status [set_parasitic_parameters -corners ss0p95v125c -early_spec M10_Cmin -late_spec M10_Cmax]
    must [expr {$rc_status eq "1"}] "Associação RC ao corner falhou"
    redirect -file reports/rc_trial.rpt {report_parasitic_parameters}
    redirect -file reports/check_design.rpt {
        set design_status [check_design -checks {netlist unbound dp_pre_floorplan} \
            -ems_database [file normalize reports/check_design.ems] \
            -log_file [file normalize reports/check_design.log]]
    }
    puts "M10_PRE_FLOORPLAN_CHECK $design_status"
    must [expr {$design_status eq "1"}] "check_design não concluiu o precheck"

    redirect -file reports/scenarios_checkpoint.rpt {report_scenarios}
    current_scenario functional::ss0p95v125c
    redirect -file reports/functional_clocks.rpt {report_clocks}
    redirect -file reports/functional_case_checkpoint.rpt {report_case_analysis}
    must [expr {[get_attribute [get_clocks clk] period] == 10.0}] "Clock funcional difere do M8"
    set_case_analysis 0 [get_ports scan_enable]

    # Prova da configuração básica de shift do SPF. Delays de I/O e
    # restrições de captura devem ser definidos antes de STA de teste.
    create_mode scan_shift_probe
    create_scenario -mode scan_shift_probe -corner ss0p95v125c
    create_clock -name clk -period 100 -waveform {45 55} [get_ports clk]
    set_case_analysis 1 [get_ports {scan_enable reset_n}]
    redirect -file reports/shift_clock.rpt {report_clocks}
    redirect -file reports/shift_case.rpt {report_case_analysis}
    redirect -file reports/shift_timing_checks.rpt {check_timing -all}
    redirect -file reports/scenarios_trial.rpt {report_scenarios}
    current_scenario functional::ss0p95v125c
    redirect -file reports/functional_case_trial.rpt {report_case_analysis}
    must [expr {[get_attribute [get_clocks clk] period] == 10.0}] "Modo de shift contaminou o clock funcional"
} message options]} {
    puts stderr "M10_READINESS_INCOMPLETE $message"
    if {[dict exists $options -errorinfo]} {puts stderr [dict get $options -errorinfo]}
    exit 1
}
puts "M10_READINESS_CHECKS_COMPLETED"
exit 0
