# Driver de inserção lógica. Execute em diretório novo com M9_REPLACEMENT_RUN.
set m9_script_dir [file dirname [file normalize [info script]]]
set m9_preview_return_to_caller 1
source [file join $m9_script_dir preview_scan.tcl]

proc functional_signature {} {
    set signature {}
    foreach_in_collection cell [get_cells -hierarchical -filter {is_hierarchical == false}] {
        set name [get_object_name $cell]
        set reference [get_attribute $cell ref_name]
        set nets {}
        foreach_in_collection pin [get_pins -of_objects $cell] {
            set short [get_attribute $pin name]
            if {$reference eq "SDFFX1_RVT" && $short in {SI SE}} {continue}
            set net [connected_net $pin]
            if {$reference eq "SDFFX1_RVT" && $short in {Q QN} && $net eq "-"} {continue}
            lappend nets [list $short $net]
        }
        dict set signature $name [list $reference [lsort $nets]]
    }
    return $signature
}

proc validate_functional_signature {before after} {
    if {[lsort [dict keys $before]] ne [lsort [dict keys $after]]} {
        error "O insert_dft alterou o conjunto de células folha"
    }
    dict for {name previous} $before {
        lassign $previous old_ref old_nets
        lassign [dict get $after $name] new_ref new_nets
        if {$old_ref ne $new_ref} {error "Referência alterada em $name"}
        foreach pair $old_nets {
            if {$pair ni $new_nets} {error "Conexão funcional alterada em $name: $pair"}
        }
        foreach pair $new_nets {
            if {$pair ni $old_nets &&
                ($new_ref ne "SDFFX1_RVT" || [lindex $pair 0] ni {Q QN})} {
                error "Conexão funcional nova em $name: $pair"
            }
        }
    }
}

proc verify_chain {} {
    set chain_names [get_scan_chain_names -test_mode Internal_scan]
    if {$chain_names ne "KUIDAMOS_CHAIN" || [get_scan_chain_count] != 1} {
        error "Cadeias conectadas diferentes da arquitetura de referência: $chain_names"
    }
    set sequential [get_cells -hierarchical -filter {is_hierarchical == false && is_sequential == true}]
    set sdffs [filter_collection $sequential {ref_name == SDFFX1_RVT}]
    set chain_members [lsort [get_object_name $sdffs]]
    if {[sizeof_collection $sequential] != 115 || [llength $chain_members] != 115} {
        error "Inventário sequencial inesperado após inserção"
    }
    set start [connected_net [get_ports scan_in]]
    set stop [connected_net [get_ports scan_out]]
    set enable [connected_net [get_ports scan_enable]]
    if {"-" in [list $start $stop $enable] || [llength [lsort -unique [list $start $stop $enable]]] != 3} {
        error "Portas de teste sem três redes distintas"
    }
    set si_loads {}
    foreach_in_collection cell $sdffs {
        set name [get_object_name $cell]
        set input [connected_net [get_pins $name/SI]]
        if {$input in {- m9_scan_disabled} || [dict exists $si_loads $input]} {
            error "SI aberto, ligado à constante temporária ou compartilhado em $name"
        }
        if {[connected_net [get_pins $name/SE]] ne $enable ||
            [connected_net [get_pins $name/CLK]] ne "clk"} {
            error "SE ou CLK incorreto em $name"
        }
        dict set si_loads $input $name
    }

    set chain_file [open post/actual_chain.tsv w]
    puts $chain_file "position\tinstance\tSI_net\tSO_pin\tSO_net\tSE_net\tCLK_net"
    set visited {}
    set next $start
    for {set index 1} {$index <= 115} {incr index} {
        if {![dict exists $si_loads $next]} {error "Descontinuidade na posição $index"}
        set name [dict get $si_loads $next]
        if {$name in $visited} {error "Ciclo na cadeia em $name"}
        lappend visited $name
        set outputs {}
        foreach out_pin {Q QN} {
            set out_net [connected_net [get_pins $name/$out_pin]]
            if {$out_net eq $stop || [dict exists $si_loads $out_net]} {
                lappend outputs [list $out_pin $out_net]
            }
        }
        if {[llength $outputs] != 1} {error "Saída de scan ausente ou ambígua em $name"}
        lassign [lindex $outputs 0] out_pin out_net
        puts $chain_file [join [list $index $name $next $out_pin $out_net $enable clk] "\t"]
        set next $out_net
        if {$next eq $stop && $index != 115} {error "Cadeia terminou antes dos 115 SDFFs"}
    }
    close $chain_file
    if {$next ne $stop || [lsort $visited] ne $chain_members} {error "Fim ou cobertura da cadeia incorretos"}
    puts "M9_CHAIN_VERIFIED endpoints=2 internal_links=114 enable_pins=115"
}

if {[catch {
    # Confirme a arquitetura completa antes de chamar o motor de inserção.
    puts [exec env PYTHONIOENCODING=utf-8 python3 \
        [file join $m9_script_dir check_preview.py] --reports-only reports]
    redirect -file reports/help_insert_dft.rpt {help -verbose insert_dft}
    redirect -file reports/help_check_scan_chain.rpt {help -verbose check_scan_chain}
    redirect -file reports/help_set_dont_touch.rpt {help -verbose set_dont_touch}
    file mkdir post post_drc_work
    set before_insert [functional_signature]
    # Evite a simplificação de somadores observada durante o insert_dft.
    # Somente combinacionais e somente durante a inserção.
    set temporary_protection [get_cells -hierarchical -filter {
        is_hierarchical == false && is_combinational == true && dont_touch != true
    }]
    set protected_names [get_object_name $temporary_protection]
    puts "M9_TEMPORARY_COMB_PROTECTION [llength $protected_names]"
    if {[llength $protected_names] > 0 && [set_dont_touch $temporary_protection true] ne "1"} {
        error "Não foi possível proteger a lógica combinacional"
    }
    redirect -tee post/insert_dft.rpt {set insert_status [insert_dft]}
    puts "M9_INSERT_DFT_RETURN $insert_status"
    if {$insert_status ne "1"} {error "insert_dft retornou $insert_status"}
    write_snapshot post/scan_netlist.v
    redirect -file post/scan_paths.rpt {report_scan_path -test_mode Internal_scan}
    set leaves [get_cells -hierarchical -filter {is_hierarchical == false}]
    if {[sizeof_collection [filter_collection $leaves {is_placed == true}]] != 0 ||
        [get_object_name [get_clocks *]] ne "clk" ||
        [get_attribute [get_clocks clk] period] != 10.0} {
        error "Placement ou clock inesperado após a inserção"
    }
    validate_functional_signature $before_insert [functional_signature]
    if {[llength $protected_names] > 0} {
        set restored [get_cells -quiet $protected_names]
        if {[sizeof_collection $restored] != [llength $protected_names]} {
            error "Não foi possível localizar todas as combinacionais protegidas"
        }
        set_dont_touch $restored false
    }
    verify_chain
    redirect -file post/scan_check.rpt {check_scan_chain}
    # Nesta versão o comando imprime o resultado e seu retorno Tcl é vazio.
    set scan_check_file [open post/scan_check.rpt r]
    set scan_check [read $scan_check_file]
    close $scan_check_file
    if {![regexp -line {^\s*VALIDATED\s*:\s*1\s*$} $scan_check] ||
        ![regexp -line {^\s*FAILED\s*:\s*0\s*$} $scan_check]} {
        error "check_scan_chain não validou uma cadeia"
    }

    set_dft_drc_configuration -enhanced_dft_drc_report enable -log_dir [file normalize post_drc_work]
    redirect -tee post/dft_drc.rpt {set post_status [dft_drc -test_mode Internal_scan -verbose]}
    puts "M9_POST_DRC_RETURN $post_status"
    redirect -file post/dft_violations.rpt {report_dft_drc_violations -test_mode Internal_scan -summary}
    redirect -file post/dft_violations_details.rpt {report_dft_drc_violations -test_mode Internal_scan}
    redirect -file post/licenses.rpt {list_licenses}
    if {$post_status ne "1"} {error "DFT DRC pós-scan retornou $post_status"}
    write_test_protocol -test_mode Internal_scan -output [file normalize post/scan_protocol.spf]
    write_scan_def -output [file normalize post/scan.def]
    redirect -file post/structure.rpt {
        check_design -checks {netlist unbound} \
            -ems_database [file normalize post/check_design.ems] \
            -log_file [file normalize post/check_design.log]
    }
    redirect -file post/area.rpt {report_area -logical -significant_digits 4}
    redirect -file post/references.rpt {report_reference}
    redirect -file post/clocks.rpt {report_clocks}
    current_scenario functional::ss0p95v125c
    set_case_analysis 0 [get_ports scan_enable]
    redirect -file post/timing_checks.rpt {check_timing -all}
    redirect -file post/setup.rpt {report_timing -delay_type max -max_paths 10 -significant_digits 4}
    redirect -file post/hold.rpt {report_timing -delay_type min -max_paths 10 -significant_digits 4}
    remove_case_analysis [get_ports scan_enable]
    save_block -as scan_inserted
    save_lib
} message options]} {
    puts stderr "M9_INSERTION_INCOMPLETE $message"
    if {[dict exists $options -errorinfo]} {puts stderr [dict get $options -errorinfo]}
    exit 1
}
puts "M9_INSERTION_REPORTS_SAVED"
exit 0
