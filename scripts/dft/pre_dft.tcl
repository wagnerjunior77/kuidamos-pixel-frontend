# Driver M9. Comandos confirmados na ajuda do FC X-2025.06-SP2.
set sh_continue_on_error false
set SCRIPT_DIR [file dirname [file normalize [info script]]]
foreach variable {REPO_ROOT SAED32_REF_ROOT DFT_RUN_DIR} {
    if {![info exists env($variable)] || $env($variable) eq ""} {
        puts stderr "ERROR: variável obrigatória ausente: $variable"
        exit 1
    }
    set $variable [file normalize $env($variable)]
}
set RPT_DIR [file join $DFT_RUN_DIR reports]
foreach directory {reports help protocol db drc_work} {
    file mkdir [file join $DFT_RUN_DIR $directory]
}
set metrics [open [file join $DFT_RUN_DIR metrics.tsv] w]
puts $metrics "metric\tvalue"
proc metric {name value} {
    global metrics
    puts $metrics "$name\t$value"
    flush $metrics
}
proc require_true {value description} {
    if {$value ne "1"} {error "$description: retorno '$value'"}
}
proc cell_signature {} {
    set rows {}
    foreach_in_collection cell [get_cells -hierarchical -filter {is_hierarchical == false}] {
        lappend rows "[get_object_name $cell]\t[get_attribute $cell ref_name]"
    }
    return [lsort $rows]
}
set failed [catch {
    foreach command {create_lib read_verilog link_block read_sdc check_design check_timing
        update_timing report_timing report_pvt report_lib set_process_number set_process_label
        set_voltage set_temperature set_dft_signal set_dft_configuration
        set_scan_configuration create_test_protocol set_dft_drc_configuration
        dft_drc report_dft_drc_violations write_test_protocol} {
        if {[llength [info commands $command]] == 0} {error "Comando indisponível: $command"}
        redirect -file [file join $DFT_RUN_DIR help $command.rpt] {help -verbose $command}
    }
    require_true [get_licenses Fusion-Compiler-NX] "Checkout Fusion-Compiler-NX"
    redirect -file [file join $RPT_DIR licenses_before.rpt] {list_licenses}
    source [file join $SCRIPT_DIR 01_import_check.tcl]
    source [file join $SCRIPT_DIR 02_protocol_drc.tcl]
    if {$INPUT_SIGNATURE ne [cell_signature]} {error "As células/referências mudaram durante o diagnóstico"}
    metric unchanged_cell_references 1
    metric scan_replacement_executed 0
    metric scan_insertion_executed 0
    metric atpg_executed 0
    metric physical_implementation_executed 0
    redirect -file [file join $RPT_DIR licenses_after.rpt] {list_licenses}
    save_block -as pre_dft_protocol
    save_lib
} message options]
close $metrics
set status_file [open [file join $DFT_RUN_DIR execution.status] w]
if {$failed} {
    puts $status_file "INCOMPLETE"
    close $status_file
    puts stderr "ERROR: M9 pré-DFT interrompido: $message"
    if {[dict exists $options -errorinfo]} {puts stderr [dict get $options -errorinfo]}
    exit 1
}
puts $status_file "COMPLETED"
close $status_file
puts "M9_PRE_DFT_EXECUTION_COMPLETED: examinar violações; não implica PASS."
exit 0
