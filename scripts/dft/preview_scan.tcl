# Execute em um diretório novo. M9_REPLACEMENT_RUN aponta para a execução
# que salvou replacement_candidate e after/sequential.tsv.
set sh_continue_on_error false

proc connected_net {term} {
    set nets [get_nets -quiet -of_objects $term]
    if {[sizeof_collection $nets] > 1} {error "Conexão ambígua em [get_object_name $term]"}
    if {[sizeof_collection $nets] == 0} {return "-"}
    return [get_object_name $nets]
}

proc read_candidate_inventory {path} {
    set f [open $path r]
    if {[gets $f] ne "instance\treference\tCLK\tD\tQ\tQN\tSE\tSI"} {
        close $f
        error "Cabeçalho inesperado no inventário de replacement"
    }
    set rows {}
    while {[gets $f line] >= 0} {lappend rows $line}
    close $f
    return [lsort $rows]
}

proc check_candidate {expected_tie report_path} {
    set leaves [get_cells -hierarchical -filter {is_hierarchical == false}]
    set sequential [filter_collection $leaves {is_sequential == true}]
    if {[sizeof_collection $leaves] != 1256 || [sizeof_collection $sequential] != 115 ||
        [sizeof_collection [filter_collection $sequential {ref_name == SDFFX1_RVT}]] != 115 ||
        [sizeof_collection [filter_collection $leaves {is_placed == true}]] != 0 ||
        [get_scan_chain_count] != 0} {
        error "Inventário, placement ou SCANDEF diferente do candidato pré-scan"
    }
    if {[get_object_name [get_clocks *]] ne "clk" || [get_attribute [get_clocks clk] period] != 10.0} {
        error "Clock funcional diferente de clk/10 ns"
    }
    foreach {name direction} {scan_enable in scan_in in scan_out out reset_n in} {
        set port [get_ports $name]
        if {[sizeof_collection $port] != 1 || [get_attribute $port direction] ne $direction} {
            error "Porta ou direção inesperada: $name"
        }
        if {$name ne "reset_n" && [connected_net $port] ne "-"} {
            error "Porta de scan já conectada: $name"
        }
    }
    set rows {}
    set functional_rows {}
    foreach_in_collection cell $sequential {
        set name [get_object_name $cell]
        set row [list $name [get_attribute $cell ref_name]]
        foreach pin {CLK D Q QN SE SI} {
            set terminal [get_pins $name/$pin]
            if {[sizeof_collection $terminal] != 1} {error "Pino ausente ou ambíguo: $name/$pin"}
            lappend row [connected_net $terminal]
        }
        if {[lindex $row 2] ne "clk" || [lindex $row 6] ne $expected_tie || [lindex $row 7] ne $expected_tie} {
            error "CLK, SE ou SI inesperado em $name"
        }
        lappend rows [join $row "\t"]
        lappend functional_rows [join [lrange $row 0 5] "\t"]
    }
    set rows [lsort $rows]
    set f [open $report_path w]
    puts $f "instance\treference\tCLK\tD\tQ\tQN\tSE\tSI"
    puts $f [join $rows "\n"]
    close $f
    return [list $rows [lsort $functional_rows]]
}

proc write_snapshot {file} {
    write_verilog -hierarchy all [file normalize $file]
    if {![file isfile $file] || [file size $file] == 0} {
        error "Netlist de diagnóstico ausente: $file"
    }
}

if {[catch {
    if {![info exists env(M9_REPLACEMENT_RUN)]} {error "Defina M9_REPLACEMENT_RUN"}
    set source_dir [file normalize $env(M9_REPLACEMENT_RUN)]
    set original [file join $source_dir kuidamos_replacement.dlib]
    set copy [file normalize kuidamos_preview.dlib]
    if {[file exists $copy] || [file exists reports] || [file exists drc_work]} {
        error "Use um diretório inédito para o preview"
    }
    file mkdir reports drc_work
    file copy $original $copy
    open_lib $copy
    open_block replacement_candidate
    current_scenario functional::ss0p95v125c
    foreach command {preview_dft set_scan_configuration set_scan_path set_dft_signal
        set_dft_insertion_configuration disconnect_net create_test_protocol dft_drc} {
        redirect -file reports/help_${command}.rpt {help -verbose $command}
    }
    redirect -file reports/keep_connected_enable.rpt {
        report_app_options dft.scan.test_keep_connected_scan_en
        puts "VALUE [get_app_option_value -name dft.scan.test_keep_connected_scan_en]"
    }
    lassign [check_candidate m9_scan_disabled reports/sequential_input.tsv] input_rows input_functional
    if {$input_rows ne [read_candidate_inventory [file join $source_dir after sequential.tsv]]} {
        error "Conectividade diferente do inventário salvo no replacement"
    }
    redirect -file reports/clocks.rpt {report_clocks}
    write_snapshot reports/input_with_ties.v

    # Retire apenas os 230 terminais de teste auditados. O candidato original
    # mantém seus tie-offs e a base de preview é descartável.
    set tie [get_nets m9_scan_disabled]
    set sdffs [get_cells -hierarchical -filter {ref_name == SDFFX1_RVT}]
    set pins [get_pins -of_objects $sdffs -filter {name == SE || name == SI}]
    set expected_names [lsort [get_object_name $pins]]
    set actual_names [lsort [get_object_name [all_connected $tie]]]
    if {[llength $expected_names] != 230 || $expected_names ne $actual_names} {
        error "A constante de teste tem terminais diferentes dos SE/SI esperados"
    }
    set disconnected [disconnect_net -net $tie $pins]
    puts "SCAN_TIE_TERMINALS_DISCONNECTED $disconnected"
    if {$disconnected != 230} {error "Desconexão parcial de SE/SI"}
    lassign [check_candidate "-" reports/sequential_preview_input.tsv] prepared_rows prepared_functional
    if {$input_functional ne $prepared_functional} {error "Conectividade funcional alterada na preparação"}
    write_snapshot reports/before_preview.v

    set_dft_configuration -scan enable -scan_compression disable \
        -clock_controller disable -wrapper disable -testability disable
    set_scan_configuration -chain_count 1 -clock_mixing no_mix
    set test_default_period 100
    set_dft_signal -view existing_dft -type ScanClock -port clk -timing {45 55}
    set_dft_signal -view existing_dft -type Constant -port reset_n -active_state 1
    set_dft_signal -view spec -type ScanEnable -port scan_enable -active_state 1
    set_dft_signal -view spec -type ScanDataIn -port scan_in
    set_dft_signal -view spec -type ScanDataOut -port scan_out
    set_scan_path KUIDAMOS_CHAIN -scan_data_in scan_in -scan_data_out scan_out -scan_enable scan_enable
    create_test_protocol
    write_test_protocol -output [file normalize reports/preview_protocol.spf]
    redirect -file reports/dft_signals.rpt {report_dft_signal}
    redirect -file reports/dft_configuration.rpt {report_dft_configuration}
    redirect -file reports/scan_configuration.rpt {report_scan_configuration}
    set_dft_drc_configuration -enhanced_dft_drc_report enable -log_dir [file normalize drc_work]
    redirect -tee reports/pre_preview_drc.rpt {set drc_status [dft_drc -verbose]}
    puts "PREVIEW_INPUT_DRC_RETURN $drc_status"
    if {$drc_status ne "1"} {error "DFT DRC não concluído"}
    redirect -file reports/dft_violations.rpt {report_dft_drc_violations -summary}
    redirect -file reports/dft_violations_details.rpt {report_dft_drc_violations}
    redirect -tee reports/preview_dft.rpt {set preview_status [preview_dft]}
    puts "PREVIEW_DFT_RETURN $preview_status"
    lassign [check_candidate "-" reports/sequential_after_preview.tsv] final_rows final_functional
    if {$prepared_rows ne $final_rows} {error "Conectividade sequencial alterada pelo preview"}
    redirect -file reports/physical_scan_paths.rpt {report_scan_path}
    write_snapshot reports/after_preview.v
    redirect -file reports/licenses.rpt {list_licenses}
    if {$preview_status ne "1"} {error "preview_dft retornou $preview_status"}
} message options]} {
    puts stderr "M9_PREVIEW_INCOMPLETE $message"
    if {[dict exists $options -errorinfo]} {puts stderr [dict get $options -errorinfo]}
    exit 1
}
puts "M9_PREVIEW_COMMAND_COMPLETED"
if {![info exists m9_preview_return_to_caller]} {exit 0}
