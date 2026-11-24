# Cenários diagnósticos compartilhados entre a preparação e o placement.
proc configure_timing {} {
    current_scenario functional::ss0p95v125c
    require [expr {[get_attribute [get_clocks clk] period] == 10}] "Clock funcional de origem incorreto"
    set_case_analysis 0 [get_ports scan_enable]
    foreach {mode se} {scan_shift 1 scan_capture_probe 0} {
        create_mode $mode
        create_scenario -mode $mode -corner ss0p95v125c
        create_clock -name clk -period 100 -waveform {45 55} [get_ports clk]
        set_case_analysis $se [get_ports scan_enable]
        set_case_analysis 1 [get_ports reset_n]
    }

    # Painel fast nominal da NDM RVT. Usa o par RC já carregado no power plan.
    create_corner ff0p95vn40c
    set_process_number -corners ff0p95vn40c 1.01
    set_process_label -corners ff0p95vn40c fast
    set_voltage -corners ff0p95vn40c 0.95
    set_temperature -corners ff0p95vn40c -40
    set_parasitic_parameters -corners ff0p95vn40c -early_spec M10_Cmin -late_spec M10_Cmax
    foreach mode {functional scan_shift scan_capture_probe} {
        create_scenario -mode $mode -corner ff0p95vn40c -init_from ${mode}::ss0p95v125c
    }
}

proc report_scenario_timing {} {
    redirect -file reports/scenarios.rpt {report_scenarios}
    redirect -file reports/rc.rpt {report_parasitic_parameters}
    redirect -file reports/pvt.rpt {report_pvt}
    foreach mode {functional scan_shift scan_capture_probe} {
        foreach corner {ss0p95v125c ff0p95vn40c} {
            set scenario ${mode}::${corner}
            current_scenario $scenario
            set file reports/${mode}.${corner}
            redirect -file $file.clocks.rpt {report_clocks}
            redirect -file $file.case.rpt {report_case_analysis}
            foreach {label delay} {setup max hold min} {
                redirect -file $file.$label.rpt {
                    report_timing -scenarios $scenario -delay_type $delay -max_paths 1 -significant_digits 4
                }
                redirect -file $file.$label.global.rpt {
                    report_global_timing -scenarios $scenario -delay_type $delay -significant_digits 4
                }
            }
        }
    }
    redirect -file reports/coverage.rpt {check_timing -all}
}
