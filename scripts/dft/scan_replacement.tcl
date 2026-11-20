# Execute em um diretório novo com M9_PRE_DFT_LIB apontando para a biblioteca original.
set sh_continue_on_error false

proc pin_net {name} {
    set pin [get_pins -quiet $name]
    if {[sizeof_collection $pin] == 0} {return "-"}
    set nets [get_nets -quiet -of_objects $pin]
    if {[sizeof_collection $nets] == 0} {return "-"}
    return [get_object_name $nets]
}

proc capture_inventory {directory} {
    file mkdir $directory
    set leaves [get_cells -hierarchical -filter {is_hierarchical == false}]
    set sequential [filter_collection $leaves {is_sequential == true}]
    set sdffs [filter_collection $sequential {ref_name =~ *SDFF*}]
    set placed [filter_collection $leaves {is_placed == true}]
    set unresolved [filter_collection $leaves {is_unbound == true || is_unmapped == true || design_type == black_box}]
    set counts [dict create leaf [sizeof_collection $leaves] \
        sequential [sizeof_collection $sequential] \
        combinational [sizeof_collection [filter_collection $leaves {is_combinational == true}]] \
        dffx1 [sizeof_collection [filter_collection $sequential {ref_name == DFFX1_RVT}]] \
        sdff [sizeof_collection $sdffs] placed [sizeof_collection $placed] \
        unresolved [sizeof_collection $unresolved] clocks [sizeof_collection [get_clocks *]] \
        clock_gates [sizeof_collection [filter_collection $leaves {is_integrated_clock_gating_cell == true}]] \
        scandef_chains [get_scan_chain_count]]
    set summary [open [file join $directory inventory.tsv] w]
    dict for {name count} $counts {puts $summary "$name\t$count"}
    close $summary
    set instances [open [file join $directory sequential.tsv] w]
    puts $instances "instance\treference\tCLK\tD\tQ\tQN\tSE\tSI"
    foreach_in_collection cell $sequential {
        set name [get_object_name $cell]
        set row [list $name [get_attribute $cell ref_name]]
        foreach pin {CLK D Q QN SE SI} {lappend row [pin_net $name/$pin]}
        puts $instances [join $row "\t"]
    }
    close $instances
    redirect -file [file join $directory clocks.rpt] {report_clocks}
    redirect -file [file join $directory area.rpt] {report_area -logical -significant_digits 4}
    redirect -file [file join $directory design.rpt] {report_design -netlist -floorplan}
    # Em uma base sem scan paths, o relatório pode retornar erro de "not available".
    redirect -file [file join $directory scan_paths.rpt] {
        set status [catch {report_scan_path} result]
        puts "REPORT_SCAN_PATH_STATUS $status RETURN $result"
    }
    return $counts
}

proc capture_checks {directory} {
    redirect -file [file join $directory structure.rpt] {
        check_design -checks {netlist unbound} \
            -ems_database [file join $directory check_design.ems] \
            -log_file [file join $directory check_design.log]
    }
    redirect -file [file join $directory timing_checks.rpt] {check_timing -all}
    redirect -file [file join $directory setup.rpt] {report_timing -delay_type max -max_paths 10 -significant_digits 4}
    redirect -file [file join $directory hold.rpt] {report_timing -delay_type min -max_paths 10 -significant_digits 4}
    redirect -file [file join $directory pvt.rpt] {report_pvt}
}

proc sequential_functional_nets {cells} {
    set snapshot {}
    foreach name [lsort [get_object_name $cells]] {
        set row [list $name]
        foreach pin {CLK D Q QN} {lappend row [pin_net $name/$pin]}
        lappend snapshot $row
    }
    return $snapshot
}

if {[catch {
    if {![info exists env(M9_PRE_DFT_LIB)] || ![file isdirectory $env(M9_PRE_DFT_LIB)]} {
        error "Defina M9_PRE_DFT_LIB para a biblioteca pré-DFT original"
    }
    set copy [file normalize kuidamos_replacement.dlib]
    if {[file exists $copy] || [file exists before] || [file exists after]} {
        error "Use um diretório inédito para cada tentativa"
    }
    file copy [file normalize $env(M9_PRE_DFT_LIB)] $copy
    open_lib $copy
    open_block pre_dft_protocol
    current_scenario functional::ss0p95v125c
    set before [capture_inventory before]
    if {[dict get $before dffx1] != 115 || [dict get $before sequential] != 115 ||
        [dict get $before sdff] != 0 || [dict get $before placed] != 0 ||
        [dict get $before unresolved] != 0} {
        error "Inventário de entrada diverge da base pré-DFT"
    }
    capture_checks before
    # initial_map remapeou lógica funcional durante a tentativa anterior.
    # Preserve a topologia com um ECO limitado às referências sequenciais.
    set dffs [get_cells -hierarchical -filter {ref_name == DFFX1_RVT}]
    set functional_nets [sequential_functional_nets $dffs]
    set scan_ref [get_lib_cells */SDFFX1_RVT]
    if {[sizeof_collection $scan_ref] != 1 || [get_attribute $scan_ref dont_use] ne "false"} {
        error "SDFFX1_RVT ausente, ambíguo ou indisponível"
    }
    set changed [set_reference -to_block $scan_ref -pin_map {D D CLK CLK Q Q QN QN} \
        -pin_rebind safe $dffs]
    puts "SET_REFERENCE_RETURN $changed"
    if {$changed != 115} {error "O ECO alterou $changed referências"}
    set sdffs [get_cells -hierarchical -filter {ref_name == SDFFX1_RVT}]
    if {[sequential_functional_nets $sdffs] ne $functional_nets} {
        error "A conectividade de D, CLK, Q ou QN mudou"
    }
    set inactive [create_net -tie_low m9_scan_disabled]
    foreach_in_collection cell $sdffs {
        set name [get_object_name $cell]
        connect_net -net $inactive [get_pins [list $name/SE $name/SI]]
    }
    set after [capture_inventory after]
    if {[dict get $after placed] != 0} {error "Células posicionadas após ECO"}
    capture_checks after
    write_verilog -hierarchy all [file normalize after/replacement_attempt.v]
    file mkdir drc_work
    set_dft_drc_configuration -enhanced_dft_drc_report enable -log_dir [file normalize drc_work]
    create_test_protocol
    redirect -tee [file normalize after/dft_drc.rpt] {set drc_rc [dft_drc -verbose]}
    puts "DFT_DRC_RETURN $drc_rc"
    redirect -file [file normalize after/dft_violations.rpt] {report_dft_drc_violations -summary}
    redirect -file [file normalize after/dft_violations_details.rpt] {report_dft_drc_violations}
    redirect -file [file normalize after/licenses.rpt] {list_licenses}
    if {[dict get $after dffx1] != 0 || [dict get $after sdff] != 115 ||
        [dict get $after sequential] != 115 || [dict get $after unresolved] != 0 ||
        [dict get $after clock_gates] != 0 || [dict get $after scandef_chains] != 0 ||
        [dict get $after clocks] != 1 ||
        [dict get $after combinational] != [dict get $before combinational]} {
        error "Conversão integral dos 115 flip-flops no domínio original não confirmada"
    }
    foreach_in_collection cell [get_cells -hierarchical -filter {ref_name =~ *SDFF*}] {
        set name [get_object_name $cell]
        if {[pin_net $name/CLK] ne "clk" ||
            [pin_net $name/SE] ne "m9_scan_disabled" || [pin_net $name/SI] ne "m9_scan_disabled"} {
            error "CLK, SE ou SI inesperado em $name"
        }
    }
    save_block -as replacement_candidate
    save_lib
} message options]} {
    puts stderr "REPLACEMENT_INCOMPLETE $message"
    if {[dict exists $options -errorinfo]} {puts stderr [dict get $options -errorinfo]}
    exit 1
}
puts "REPLACEMENT_CANDIDATE_SAVED"
exit 0
