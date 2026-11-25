# Sessão independente para conferir persistência dos dois checkpoints.
set sh_continue_on_error false

proc require {condition message} {
    if {!$condition} {error $message}
}

proc contents {path} {
    set f [open $path r]
    set text [read $f]
    close $f
    return $text
}

if {[catch {
    get_licenses Fusion-Compiler-NX
    get_licenses Fusion-Compiler-BE-NX
    open_lib [file normalize kuidamos_preview.dlib]
    foreach {name expected pin_check} {powerplan_corrected 0 none placement_initial 1256 all} {
        set dir readback/$name
        file mkdir $dir
        open_block -read $name
        require [expr {[link_block] eq "1"}] "Vínculo de $name falhou"
        set leaves [get_cells -hierarchical -filter {is_hierarchical == false}]
        set placed [filter_collection $leaves {is_placed == true}]
        puts "M10_READBACK_BLOCK $name placed=[sizeof_collection $placed] cells=[sizeof_collection $leaves]"
        require [expr {[sizeof_collection $leaves] == 1256 && [sizeof_collection $placed] == $expected}] "Inventário de $name mudou"
        redirect -file $dir/scan.rpt {check_scan_chain}
        set scan [contents $dir/scan.rpt]
        require [expr {[regexp -line {^\s*VALIDATED\s*:\s*1\s*$} $scan] &&
            [regexp -line {^\s*FAILED\s*:\s*0\s*$} $scan]}] "Cadeia de $name inválida"
        redirect -file $dir/pg_connectivity.rpt {
            set floating [check_pg_connectivity -nets {VDD VSS} -check_std_cell_pins $pin_check \
                -check_block_pins all -write_connectivity_file $dir/pg_connectivity.txt]
        }
        set connectivity [contents $dir/pg_connectivity.txt]
        require [expr {[sizeof_collection $floating] == 0 &&
            [regexp -all {Number of disjoint networks: 1\y} $connectivity] == 2 &&
            [regexp -all {Number of floating std cells: 0\y} $connectivity] == 2 &&
            [regexp -all {Number of std cells with unconnected port: [1-9][0-9]*} $connectivity] == 0}] \
            "Conectividade de $name inválida"
        redirect -file $dir/pg_drc.rpt {
            check_pg_drc -nets {VDD VSS} -ignore_clock_nets false -no_gui -output $dir/pg_drc.txt
        }
        require [regexp -line {^No errors found\.$} [contents $dir/pg_drc.rpt]] "PG DRC de $name com erros"
        if {$expected == 1256} {
            redirect -file $dir/legality.rpt {set legal [check_legality]}
            require [expr {$legal eq "1" && [regexp -line {^TOTAL 0 Violations\.$} [contents $dir/legality.rpt]]}] "Readback ilegal"
            require [expr {[sizeof_collection [get_scenarios *]] == 6}] "Cenários de STA foram perdidos"
            redirect -file $dir/scenarios.rpt {report_scenarios}
        }
        set f [open $dir/wires.tsv w]
        puts $f "net\tuse\tlayer\tx0\ty0\tx1\ty1"
        foreach rail {VDD VSS} {
            foreach_in_collection shape [get_shapes -of_objects [get_nets -physical_context $rail]] {
                puts $f [join [concat [list $rail [get_attribute $shape shape_use] \
                    [get_attribute $shape layer_name]] {*}[get_attribute $shape bbox]] "\t"]
            }
        }
        close $f
        write_def -units 1000 -include {rows_tracks cells ports scanchains specialnets vias nets} $dir/design.def
        write_verilog -hierarchy all [file normalize $dir/netlist.v]
    }
} message options]} {
    puts stderr "M10_READBACK_INCOMPLETE $message"
    if {[dict exists $options -errorinfo]} {puts stderr [dict get $options -errorinfo]}
    exit 1
}
puts M10_CORRECTED_PLACEMENT_READBACK_COMPLETED
exit 0
