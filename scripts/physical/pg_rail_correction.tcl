# Correção localizada para o powerplan_initial SAED32 RVT do KUIDAMOS.
proc correct_m1_rails {} {
    redirect -file reports/help_set_attribute.rpt {help -verbose set_attribute}
    redirect -file reports/help_create_pg_std_cell_conn_pattern.rpt {help -verbose create_pg_std_cell_conn_pattern}
    redirect -file reports/help_create_pg_vias.rpt {help -verbose create_pg_vias}

    set nets [get_nets -physical_context {VDD VSS}]
    set rails [get_shapes -of_objects $nets -filter {layer_name == M1 && shape_use == follow_pin}]
    require [expr {[sizeof_collection $rails] == 53 &&
        [sizeof_collection [get_vias -of_objects $nets]] == 1766}] "Malha de origem diferente do power plan validado"
    set width 0.060
    require [expr {$width >= [get_attribute [get_layers M1] min_width]}] "Largura abaixo do mínimo M1"
    set centers {}
    foreach_in_collection rail $rails {
        set name [get_object_name $rail]
        require [expr {abs([get_attribute $rail width] - 0.152) < 1.0e-6}] "Largura de origem inesperada"
        dict set centers $name [get_attribute $rail bbox]
    }
    set_attribute $rails width $width
    set report [open reports/m1_rails.tsv w]
    puts $report "name\told_lx\told_ly\told_ux\told_uy\tnew_lx\tnew_ly\tnew_ux\tnew_uy"
    foreach_in_collection rail $rails {
        set name [get_object_name $rail]
        set before [concat {*}[dict get $centers $name]]
        set after [concat {*}[get_attribute $rail bbox]]
        lassign $before old_lx old_ly old_ux old_uy
        lassign $after new_lx new_ly new_ux new_uy
        require [expr {$old_lx == $new_lx && $old_ux == $new_ux &&
            abs($old_ly + $old_uy - $new_ly - $new_uy) < 1.0e-6 &&
            abs($new_uy - $new_ly - $width) < 1.0e-6}] "Eixo ou extremos de rail mudaram"
        puts $report [join [concat [list $name] $before $after] "\t"]
    }
    close $report

    redirect -file reports/corrected_pg_connectivity.rpt {
        set floating [check_pg_connectivity -nets $nets -check_std_cell_pins none \
            -check_block_pins all -write_connectivity_file reports/corrected_pg_connectivity.txt]
    }
    require [expr {[sizeof_collection $floating] == 0 &&
        [regexp -all {Number of disjoint networks: 1\y} [contents reports/corrected_pg_connectivity.txt]] == 2}] \
        "Rede PG corrigida incompleta"
    redirect -file reports/corrected_pg_drc.rpt {
        check_pg_drc -nets $nets -ignore_clock_nets false -no_gui -output reports/corrected_pg_drc.txt
    }
    require [regexp -line {^No errors found\.$} [contents reports/corrected_pg_drc.rpt]] "PG DRC pré-placement com erros"
    save_block -as powerplan_corrected
    save_lib
}
