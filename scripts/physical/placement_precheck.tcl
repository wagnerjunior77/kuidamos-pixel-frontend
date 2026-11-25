# Diagnóstico em memória a partir da cópia de powerplan_initial.
set sh_continue_on_error false
source [file join [file dirname [file normalize [info script]]] placement_timing.tcl]

proc require {condition message} {
    if {!$condition} {error $message}
}

proc inspect_protocol {} {
    set f [open protocol.spf r]
    set protocol [read $f]
    close $f
    set captures {_multiclock_capture_WFT_ _allclock_capture_WFT_ _allclock_launch_WFT_ _allclock_launch_capture_WFT_}
    foreach waveform [linsert $captures 0 _default_WFT_] {
        set pattern [format {WaveformTable "%s"\s*\{\s*Period '100ns';\s*Waveforms\s*\{\s*"clk"\s*\{\s*P\s*\{\s*'0ns' D;\s*'45ns' U;\s*'55ns' D;} $waveform]
        require [regexp $pattern $protocol] "Waveform inesperada em $waveform"
    }
    foreach requirement {{ScanLength 115;} {ScanEnable "scan_enable";} {"scan_enable" = 1;} {"reset_n" = 1;}} {
        require [expr {[string first $requirement $protocol] >= 0}] "Controle do SPF ausente: $requirement"
    }
    puts "M10_SPF_CLOCK 100ns {45 55}"
}

proc inspect_library {} {
    set lib [get_libs saed32_rvt]
    redirect -file reports/library.rpt {report_lib -physical -cell_summary $lib}
    set refs [get_lib_cells saed32_rvt*/*]
    set f [open reports/physical_references.tsv w]
    puts $f "group\tcount\treferences"
    foreach {label filter} {tap {is_tap_cell == true} well_tap {design_type == well_tap}
        endcap {design_type == end_cap} filler {is_filler_cell == true} tie {name =~ TIE*}} {
        set cells [filter_collection $refs $filter]
        puts $f "$label\t[sizeof_collection $cells]\t[get_object_name $cells]"
    }
    close $f

    set blocks [get_blocks -lib_cells -of_objects $lib]
    set counts {}
    foreach_in_collection block $blocks {
        dict incr counts [file extension [get_object_name $block]]
    }
    puts "M10_RVT_VIEWS $counts"
    return $blocks
}

proc inspect_frames {blocks} {
    set f [open reports/frame_geometry.txt w]
    foreach ref {DCAP_RVT INVX1_RVT SDFFX1_RVT} {
        set matches [filter_collection $blocks "name == ${ref}.frame"]
        if {[sizeof_collection $matches] == 1} {
            set name [get_object_name $matches]
        } else {
            set name "saed32_rvt|saed32_rvt_std:${ref}.frame"
        }
        open_block -read $name
        set counts {}
        foreach_in_collection shape [get_shapes -quiet *] {
            dict incr counts [get_attribute $shape layer_name]
        }
        puts $f "$ref layers=$counts"
        foreach_in_collection port [get_ports -physical_context -quiet {VDD VSS}] {
            foreach_in_collection term [get_terminals -of_objects $port] {
                puts $f "$ref [get_object_name $port] [get_attribute $term bbox]"
            }
        }
    }
    close $f
}

if {[catch {
    file mkdir reports
    inspect_protocol
    open_lib [file normalize kuidamos_preview.dlib]
    open_block powerplan_initial
    require [expr {[link_block] eq "1"}] "Vínculo do checkpoint PG falhou"
    set leaves [get_cells -hierarchical -filter {is_hierarchical == false}]
    set placed [filter_collection $leaves {is_placed == true}]
    set sdffs [filter_collection $leaves {ref_name == SDFFX1_RVT}]
    require [expr {[sizeof_collection $leaves] == 1256 && [sizeof_collection $placed] == 0 &&
        [sizeof_collection $sdffs] == 115 && [sizeof_collection [get_site_rows *]] == 52}] "Inventário de origem inesperado"
    require [expr {[get_scan_chain_names -test_mode Internal_scan] eq "KUIDAMOS_CHAIN"}] "Cadeia scan ausente"
    redirect -file reports/scan_check.rpt {check_scan_chain}
    foreach cmd {create_boundary_cells check_boundary_cells create_tap_cells create_placement legalize_placement
        check_legality report_congestion report_global_timing set_scenario_status} {
        redirect -file reports/help_${cmd}.rpt {help -verbose $cmd}
    }
    set blocks [inspect_library]
    configure_timing
    report_scenario_timing
    current_scenario functional::ss0p95v125c
    write_verilog -hierarchy all [file normalize reports/netlist.v]
    inspect_frames $blocks
} message options]} {
    puts stderr "M10_PLACEMENT_PRECHECK_INCOMPLETE $message"
    if {[dict exists $options -errorinfo]} {puts stderr [dict get $options -errorinfo]}
    exit 1
}
puts M10_PLACEMENT_PRECHECK_COMPLETED
exit 0
