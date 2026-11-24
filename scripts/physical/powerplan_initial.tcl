# PG exclusivamente sobre a cópia de floorplan_initial criada pelo wrapper.
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

proc bbox_columns {object} {
    return [concat {*}[get_attribute $object bbox]]
}

proc check_design_state {dir} {
    set leaves [get_cells -hierarchical -filter {is_hierarchical == false}]
    set seq [filter_collection $leaves {is_sequential == true}]
    set sdff [filter_collection $seq {ref_name == SDFFX1_RVT}]
    set placed [filter_collection $leaves {is_placed == true}]
    set unbound [filter_collection $leaves {is_unbound == true || is_unmapped == true || design_type == black_box}]
    set rows [get_site_rows *]
    require [expr {[sizeof_collection $leaves] == 1256 && [sizeof_collection $seq] == 115 &&
        [sizeof_collection $sdff] == 115 && [sizeof_collection $placed] == 0 &&
        [sizeof_collection $unbound] == 0 && [sizeof_collection $rows] == 52}] "Inventário físico/lógico mudou"
    current_scenario functional::ss0p95v125c
    require [expr {[get_attribute [get_clocks clk] period] == 10.0}] "Clock funcional inesperado"
    require [expr {[get_scan_chain_names -test_mode Internal_scan] eq "KUIDAMOS_CHAIN"}] "Cadeia ausente"
    redirect -file $dir/scan_check.rpt {check_scan_chain}
    set scan [contents $dir/scan_check.rpt]
    require [expr {[regexp -line {^\s*VALIDATED\s*:\s*1\s*$} $scan] &&
        [regexp -line {^\s*FAILED\s*:\s*0\s*$} $scan]}] "check_scan_chain falhou"
    set ports [get_ports -filter {port_type != power && port_type != ground} *]
    require [expr {[sizeof_collection $ports] == 126}] "Inventário de portas funcionais/scan mudou"
    redirect -file $dir/pin_constraints.rpt {report_pin_constraints -ports $ports}
    redirect -file $dir/rc.rpt {report_parasitic_parameters}
    redirect -file $dir/clocks.rpt {report_clocks}
    redirect -file $dir/floorplan.rpt {report_design -floorplan}
    redirect -file $dir/area.rpt {report_area -logical -significant_digits 4}
}

proc check_pg_pins {dir} {
    set leaves [get_cells -hierarchical -filter {is_hierarchical == false}]
    set f [open $dir/pg_pins.tsv w]
    puts $f "net\ttype\tlogical_pins"
    foreach {name type} {VDD power VSS ground} {
        set pgpins [get_pins -physical_context -of_objects $leaves -filter "name == $name && port_type == $type"]
        require [expr {[sizeof_collection $pgpins] == 1256}] "Inventário de pinos $name incompleto"
        foreach_in_collection pin $pgpins {
            set net [get_nets -physical_context -of_objects $pin]
            require [expr {[sizeof_collection $net] == 1 &&
                [file tail [get_object_name $net]] eq $name}] "Ligação PG incorreta em [get_object_name $pin]"
        }
        puts $f "$name\t$type\t[sizeof_collection $pgpins]"
    }
    close $f
}

proc create_pg_access {} {
    foreach net {VDD VSS} {
        set shapes [get_shapes -of_objects [get_nets -physical_context $net]]
        set horizontal [filter_collection $shapes {layer_name == M7 && shape_use == ring}]
        require [expr {[sizeof_collection $horizontal] == 2}] "Segmentos horizontais do anel inesperados"
        foreach_in_collection shape $horizontal {
            lassign [bbox_columns $shape] x0 y0 x1 y1
            set mid [expr {($x0 + $x1) / 2.0}]
            # Landing de dois pitches M7 dentro do metal do próprio anel.
            create_terminal -port [get_ports $net] -layer M7 \
                -boundary [list [list [expr {$mid - 1.216}] $y0] [list [expr {$mid + 1.216}] $y1]]
        }
    }
}

proc build_powerplan {dir} {
    foreach command {connect_pg_net create_pg_ring_pattern create_pg_mesh_pattern create_pg_std_cell_conn_pattern \
        set_pg_strategy set_pg_strategy_via_rule compile_pg create_pg_vias create_terminal check_pg_connectivity check_pg_drc} {
        redirect -file $dir/help_${command}.rpt {help -verbose $command}
    }
    set f [open $dir/rules.tsv w]
    puts $f "layer\tpitch_um\tmin_width_um\tmin_spacing_um"
    foreach {layer pitch width spacing} {M1 .152 .152 1.520 M5 .608 .304 .304 M6 .608 .304 .304 M7 1.216 .608 .608 M8 1.216 .608 .608} {
        set object [get_layers $layer]
        set min_width [get_attribute $object min_width]
        set min_spacing [get_attribute $object min_spacing]
        require [expr {abs([get_attribute $object pitch] - $pitch) < 1e-6 &&
            $width >= $min_width && $spacing >= $min_spacing}] "Regra de $layer divergente"
        puts $f "$layer\t$pitch\t$min_width\t$min_spacing"
    }
    close $f
    set tech [get_techs]
    foreach code {VIA12SQ_C VIA23SQ_C VIA34SQ_C VIA45SQ_C VIA56SQ_C VIA67SQ_C VIA78SQ_C} {
        require [expr {[sizeof_collection [get_via_defs -tech $tech $code]] == 1}] "Via SAED32 ausente: $code"
    }

    connect_pg_net -automatic -pg -report_connection_summary true
    foreach {net type} {VDD power VSS ground} {
        require [expr {[sizeof_collection [get_nets -physical_context $net]] == 1}] "Rede $net ausente"
        set port [get_ports -quiet $net]
        if {[sizeof_collection $port] == 0} {
            set port [create_port -direction inout -port_type $type $net]
        }
        require [expr {[get_attribute $port port_type] eq $type}] "Tipo do porto PG $net incorreto"
        connect_pg_net -net $net $port
    }
    check_pg_pins $dir

    create_pg_ring_pattern m10_ring -horizontal_layer M7 -vertical_layer M8 \
        -horizontal_width 0.608 -vertical_width 0.608 -horizontal_spacing 0.608 -vertical_spacing 0.608 \
        -corner_bridge false -track_alignment none -via_rule {{intersection: all} {via_master: default}}
    set_pg_strategy m10_rings -core -pattern {{name: m10_ring} {nets: {VDD VSS}} {offset: {1.216 1.216}}}
    create_pg_mesh_pattern m10_mesh -layers {
        {{horizontal_layer: M5} {width: 0.304} {spacing: 0.304} {pitch: 13.376} {offset: 7.296} {trim: false}}
        {{vertical_layer: M6} {width: 0.304} {spacing: 0.304} {pitch: 14.592} {offset: 6.080} {trim: false}}
    } -via_rule {{{layers: M5} {layers: M6} {via_master: default}}}
    set_pg_strategy m10_straps -core -pattern {{name: m10_mesh} {nets: {VDD VSS}}} \
        -extension {{stop: outermost_ring}}
    create_pg_std_cell_conn_pattern m10_rail -layers M1 -rail_width {0.152 0.152} -mark_as_follow_pin true
    set_pg_strategy m10_rails -core -pattern {{name: m10_rail} {nets: {VDD VSS}}}
    set_pg_strategy_via_rule m10_stack -via_rule {
        {{{strategies: m10_straps} {layers: M5}} {{strategies: m10_rings} {layers: M8}} {via_master: default}}
        {{{strategies: m10_straps} {layers: M6}} {{strategies: m10_rings} {layers: M7}} {via_master: default}}
        {{intersection: undefined} {via_master: NIL}}
    } -tag m10_pg
    set status [compile_pg -strategies {m10_rings m10_straps m10_rails} -via_rule m10_stack -tag m10_pg]
    require [expr {$status eq "1"}] "compile_pg falhou"
    create_pg_vias -nets {VDD VSS} -from_layers M1 -to_layers M6 \
        -via_masters {VIA12SQ_C VIA23SQ_C VIA34SQ_C VIA45SQ_C VIA56SQ_C} -show_phantom
    create_pg_access
}

proc report_pg_geometry {dir} {
    set wires [open $dir/wires.tsv w]
    set vias [open $dir/vias.tsv w]
    set terminals [open $dir/terminals.tsv w]
    puts $wires "net\tuse\tlayer\tx0\ty0\tx1\ty1"
    puts $vias "net\tlower\tupper\tdefinition\tx0\ty0\tx1\ty1"
    puts $terminals "net\tx0\ty0\tx1\ty1"
    foreach name {VDD VSS} {
        set net [get_nets -physical_context $name]
        foreach_in_collection shape [get_shapes -of_objects $net] {
            puts $wires [join [concat [list $name [get_attribute $shape shape_use] \
                [get_attribute $shape layer_name]] [bbox_columns $shape]] "\t"]
        }
        foreach_in_collection via [get_vias -of_objects $net] {
            puts $vias [join [concat [list $name [get_attribute $via lower_layer_name] \
                [get_attribute $via upper_layer_name] [get_attribute $via via_def_name]] [bbox_columns $via]] "\t"]
        }
        foreach_in_collection term [get_terminals -of_objects [get_ports $name]] {
            puts $terminals [join [linsert [bbox_columns $term] 0 $name] "\t"]
        }
    }
    foreach handle [list $wires $vias $terminals] {close $handle}
}

if {[catch {
    set stage $env(M10_POWERPLAN_STAGE)
    file mkdir $stage
    redirect -file $stage/licenses.rpt {
        foreach feature {Fusion-Compiler-NX Fusion-Compiler-FE-NX Fusion-Compiler-BE-NX} {
            require [expr {[get_licenses $feature] eq "1"}] "Checkout falhou: $feature"
        }
        list_licenses
    }
    open_lib [file normalize kuidamos_preview.dlib]
    if {$stage eq "build"} {
        open_block floorplan_initial
    } elseif {$stage eq "readback"} {
        open_block -read powerplan_initial
    } else {
        error "Etapa desconhecida: $stage"
    }
    require [expr {[link_block] eq "1"}] "Checkpoint não vinculado"
    if {$stage eq "build"} {build_powerplan $stage}
    check_design_state $stage
    check_pg_pins $stage
    # Os checks desta etapa cobrem a rede e seus terminais. As células
    # não posicionadas ficam fora dos checks de geometria PG individual.
    redirect -file $stage/connectivity.rpt {
        set floating [check_pg_connectivity -nets {VDD VSS} -check_std_cell_pins none \
            -check_block_pins all -write_connectivity_file $stage/connectivity.txt]
    }
    require [expr {[sizeof_collection $floating] == 0}] "Rede PG tem objetos flutuantes"
    set connectivity [contents $stage/connectivity.txt]
    require [expr {[regexp -all {Number of disjoint networks: 1\y} $connectivity] == 2 &&
        [regexp -all {Number of floating terminals: 0\y} $connectivity] == 2}] "Rede PG ou terminais desconectados"
    redirect -file $stage/drc.rpt {
        check_pg_drc -nets {VDD VSS} -ignore_std_cells -no_gui -output $stage/drc.txt
    }
    require [regexp -line {^No errors found\.$} [contents $stage/drc.rpt]] "PG DRC com erros ou incompleto"
    report_pg_geometry $stage
    write_def -units 1000 -include {rows_tracks cells ports scanchains specialnets vias} $stage/powerplan.def
    write_verilog -hierarchy all [file normalize $stage/netlist.v]
    if {$stage eq "build"} {
        save_block -as powerplan_initial
        save_lib
    }
} message options]} {
    puts stderr "M10_POWERPLAN_INCOMPLETE $message"
    if {[dict exists $options -errorinfo]} {puts stderr [dict get $options -errorinfo]}
    exit 1
}
puts "M10_POWERPLAN_COMPLETED $stage"
exit 0
