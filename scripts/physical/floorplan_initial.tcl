# Executado pelo wrapper em uma cópia de kuidamos_preview.dlib.
set sh_continue_on_error false

proc require {condition message} {
    if {!$condition} {error $message}
}

proc report_geometry {dir} {
    set die [get_attribute [current_block] boundary_bbox]
    set core [get_attribute [get_core_area] bbox]
    set f [open $dir/geometry.tsv w]
    puts $f "area\tx0\ty0\tx1\ty1"
    foreach {label box} [list die $die core $core] {
        require [expr {[llength $box] == 2}] "Contorno $label ausente"
        puts $f [join [linsert [concat {*}$box] 0 $label] "\t"]
    }
    close $f

    set site [get_site_defs unit]
    set f [open $dir/site.tsv w]
    puts $f "site\twidth\theight"
    puts $f "unit\t[get_attribute $site width]\t[get_attribute $site height]"
    close $f
    set f [open $dir/rows.tsv w]
    puts $f "row\tsite\trow_orient\tsite_orient\tsites\tx0\ty0\tx1\ty1"
    foreach_in_collection row [get_site_rows *] {
        set box [get_attribute $row bbox]
        puts $f [join [concat [list [get_object_name $row] [get_attribute $row site_name] \
            [get_attribute $row orientation] [get_attribute $row site_orientation] \
            [get_attribute $row site_count]] {*}$box] "\t"]
    }
    close $f
    redirect -file $dir/floorplan.rpt {report_design -floorplan}
    redirect -file $dir/area.rpt {report_area -logical -significant_digits 4}
    write_def -units 1000 -include {rows_tracks cells ports scanchains} $dir/floorplan.def
}

proc report_handoff {dir} {
    set leaves [get_cells -hierarchical -filter {is_hierarchical == false}]
    set seq [filter_collection $leaves {is_sequential == true}]
    set scan [filter_collection $seq {ref_name == SDFFX1_RVT}]
    set placed [filter_collection $leaves {is_placed == true}]
    set unbound [filter_collection $leaves {is_unbound == true || is_unmapped == true || design_type == black_box}]
    puts "M10_INVENTORY leaf=[sizeof_collection $leaves] sdff=[sizeof_collection $scan] unbound=[sizeof_collection $unbound] placed=[sizeof_collection $placed]"
    require [expr {[sizeof_collection $leaves] == 1256 && [sizeof_collection $seq] == 115 &&
        [sizeof_collection $scan] == 115 && [sizeof_collection $placed] == 0 &&
        [sizeof_collection $unbound] == 0}] "Inventário lógico/físico inesperado"
    require [expr {[get_scan_chain_names -test_mode Internal_scan] eq "KUIDAMOS_CHAIN"}] "Cadeia ausente"
    redirect -file $dir/scan_path.rpt {report_scan_path -test_mode Internal_scan}
    redirect -variable scan_check {check_scan_chain}
    set f [open $dir/scan_check.rpt w]
    puts $f $scan_check
    close $f
    require [expr {[regexp -line {^\s*VALIDATED\s*:\s*1\s*$} $scan_check] &&
        [regexp -line {^\s*FAILED\s*:\s*0\s*$} $scan_check]}] "check_scan_chain falhou"
    write_verilog -hierarchy all [file normalize $dir/netlist.v]
}

proc plan_ports {dir} {
    set f [open $dir/port_plan.tsv w]
    puts $f "port\tdirection\tside\tlayer"
    set counts {}
    set_block_pin_constraints -self -allowed_layers {M3 M4} -corner_keepout_num_tracks 4 \
        -pin_spacing 2 -allow_feedthroughs false
    foreach_in_collection port [get_ports *] {
        set name [get_object_name $port]
        set direction [get_attribute $port direction]
        if {$name in {clk reset_n scan_enable scan_in scan_out}} {
            set side 2
            set layer M4
        } elseif {[string match cfg_* $name] && $direction eq "in"} {
            set side 4
            set layer M4
        } elseif {$direction eq "out"} {
            set side 3
            set layer M3
        } else {
            set side 1
            set layer M3
        }
        set_individual_pin_constraints -ports $port -sides $side -allowed_layers $layer
        puts $f "$name\t$direction\t$side\t$layer"
        dict incr counts $side
    }
    close $f
    puts "M10_PIN_PLAN $counts"
    redirect -file $dir/pin_constraints.rpt {report_pin_constraints -ports [get_ports *]}
    redirect -file $dir/ports.rpt {report_port -verbose}
}

proc build_floorplan {dir} {
    # A dlib traz a tecnologia SAED32 e a referência NDM usadas em M9.
    set ref [file normalize $::env(SAED32_REF_ROOT)]
    redirect -variable reference {report_ref_libs}
    require [expr {[string first [file join $ref CLIBs saed32_rvt.ndm] $reference] >= 0}] \
        "Referência NDM diferente de SAED32_REF_ROOT"
    redirect -file $dir/library.rpt {report_design -library}

    foreach command {initialize_floorplan set_individual_pin_constraints set_block_pin_constraints \
        read_parasitic_tech set_parasitic_parameters get_core_area get_site_rows write_def check_design} {
        redirect -file $dir/help_${command}.rpt {help -verbose $command}
    }
    set_attribute [get_layers {M1 M3 M5 M7 M9}] routing_direction horizontal
    set_attribute [get_layers {M2 M4 M6 M8 MRDL}] routing_direction vertical
    set_ignored_layers -max_routing_layer M9
    redirect -file $dir/layer_limits.rpt {report_ignored_layers}
    set f [open $dir/technology.tsv w]
    puts $f "layer\ttype\tdirection\tpitch_um"
    foreach_in_collection layer [get_layers {M1 M2 M3 M4 M5 M6 M7 M8 M9 MRDL VIA1 VIA2 VIA3 VIA4 VIA5 VIA6 VIA7 VIA8 DIFF}] {
        puts $f "[get_object_name $layer]\t[get_attribute $layer layer_type]\t[get_attribute $layer routing_direction]\t[get_attribute $layer pitch]"
    }
    close $f
    set vias [get_via_defs -tech [get_techs] *]
    puts "M10_VIA_DEFS [sizeof_collection $vias]"
    set f [open $dir/vias.txt w]
    puts $f [join [get_object_name $vias] "\n"]
    close $f

    set tech [file join $ref tech]
    foreach model {Cmin Cmax} {
        set status [read_parasitic_tech -tlup [file join $tech saed32nm_1p9m_${model}.lv.tluplus] \
            -layermap [file join $tech saed32nm_tf_itf_tluplus.map] -name M10_$model -sanity_check advanced]
        require [expr {$status eq "1"}] "Falha ao carregar $model"
    }
    set status [set_parasitic_parameters -corners ss0p95v125c -early_spec M10_Cmin -late_spec M10_Cmax]
    require [expr {$status eq "1"}] "Falha ao aplicar RC"
    redirect -file $dir/rc.rpt {report_parasitic_parameters}

    current_scenario functional::ss0p95v125c
    require [expr {[get_attribute [get_clocks clk] period] == 10.0}] "Clock funcional inesperado"
    redirect -variable area {report_area -logical -significant_digits 4}
    require [regexp {Total cell area:\s+([0-9.]+)} $area match cell_area] "Área lógica não encontrada"
    set site [get_site_defs unit]
    set sw [get_attribute $site width]
    set sh [get_attribute $site height]
    set target 0.50
    set target_area [expr {$cell_area / $target}]
    # Altura mais próxima da raiz na grade Y. Largura arredondada para
    # cima na grade X para preservar pelo menos a área alvo.
    set height [expr {round(sqrt($target_area) / $sh) * $sh}]
    set width [expr {ceil($target_area / ($height * $sw)) * $sw}]
    # Reserve quatro alturas de row ou dois pitches M9 na borda,
    # arredondando para cima a cada eixo na grade do site.
    set margin [expr {max(4 * $sh, 2 * [get_attribute [get_layers M9] pitch])}]
    set xmargin [expr {ceil($margin / $sw - 1.0e-9) * $sw}]
    set ymargin [expr {ceil($margin / $sh - 1.0e-9) * $sh}]
    set f [open $dir/plan.tsv w]
    puts $f "cell_area_um2\ttarget_utilization\ttarget_area_um2\twidth_um\theight_um\txmargin_um\tymargin_um"
    puts $f [join [list $cell_area $target $target_area $width $height $xmargin $ymargin] "\t"]
    close $f

    initialize_floorplan -control_type core -shape R -side_length [list $width $height] \
        -core_offset [list $xmargin $ymargin] -site_def unit -use_site_row
    # O comando completa com retorno vazio nesta versão. Confira os objetos.
    require [expr {[sizeof_collection [get_core_area]] == 1 &&
        [sizeof_collection [get_site_rows -quiet *]] > 0}] "Inicialização sem core ou rows"
    plan_ports $dir
    redirect -file $dir/check_design.rpt {
        set check [check_design -checks {netlist unbound dp_floorplan_rules} \
            -ems_database $dir/check_design.ems -log_file $dir/check_design.log]
    }
    require [expr {$check eq "1"}] "check_design não concluiu"

    set lib [get_lib_cells saed32_rvt*/*]
    set f [open $dir/physical_cells.txt w]
    foreach {label filter} {tap {is_tap_cell == true} endcap {design_type == end_cap} filler {is_filler_cell == true}} {
        set candidates [filter_collection $lib $filter]
        puts $f "$label: [sizeof_collection $candidates] [get_object_name $candidates]"
    }
    puts $f "tie: [get_object_name [get_lib_cells -quiet {*/TIEH_RVT */TIEL_RVT}]]"
    close $f
    redirect -file $dir/power_domains.rpt {report_power_domains}
    redirect -file $dir/clocks.rpt {report_clocks}
    set_case_analysis 0 [get_ports scan_enable]
    redirect -file $dir/setup.rpt {report_timing -delay_type max -max_paths 5 -significant_digits 4}
    redirect -file $dir/hold.rpt {report_timing -delay_type min -max_paths 5 -significant_digits 4}
    redirect -file $dir/check_timing.rpt {check_timing -all}
    remove_case_analysis [get_ports scan_enable]
}

if {[catch {
    set stage $env(M10_FLOORPLAN_STAGE)
    file mkdir $stage
    redirect -file $stage/licenses.rpt {
        foreach feature {Fusion-Compiler-NX Fusion-Compiler-FE-NX Fusion-Compiler-BE-NX} {
            require [expr {[get_licenses $feature] eq "1"}] "Checkout falhou: $feature"
        }
        list_licenses
    }
    open_lib [file normalize kuidamos_preview.dlib]
    if {$stage eq "build"} {
        open_block scan_inserted
        require [expr {[link_block] eq "1"}] "Checkpoint M9 não vinculado"
        build_floorplan $stage
    } elseif {$stage eq "readback"} {
        open_block -read floorplan_initial
        require [expr {[link_block] eq "1"}] "Checkpoint físico não vinculado"
        redirect -file $stage/rc.rpt {report_parasitic_parameters}
        redirect -file $stage/pin_constraints.rpt {report_pin_constraints -ports [get_ports *]}
        redirect -file $stage/clocks.rpt {report_clocks}
    } else {
        error "Etapa desconhecida: $stage"
    }
    report_geometry $stage
    report_handoff $stage
    if {$stage eq "build"} {
        save_block -as floorplan_initial
        save_lib
    }
} message options]} {
    puts stderr "M10_FLOORPLAN_INCOMPLETE $message"
    if {[dict exists $options -errorinfo]} {puts stderr [dict get $options -errorinfo]}
    exit 1
}
puts "M10_FLOORPLAN_COMPLETED $stage"
exit 0
