# Hipótese inicial: uma cadeia, 115 FFs, um clock e três pinos dedicados.
# Portas criadas somente na base local; nenhuma conexão de scan é inserida.
foreach {name direction} {scan_enable in scan_in in scan_out out} {
    if {[sizeof_collection [get_ports -quiet $name]]} {error "Porta já existe: $name"}
    create_port -direction $direction $name
}
set_dft_configuration -scan enable -scan_compression disable \
    -clock_controller disable -wrapper disable -testability disable
set_scan_configuration -chain_count 1 -clock_mixing no_mix
set test_default_period 100
set_dft_signal -view existing_dft -type ScanClock -port clk -timing {45 55}
# Reset síncrono em M8: lógica no D dos FFs, não pino de reset assíncrono.
# A restrição é do protocolo de teste, sem case_analysis no modo funcional.
set_dft_signal -view existing_dft -type Constant -port reset_n -active_state 1
set_dft_signal -view spec -type ScanEnable -port scan_enable -active_state 1
set_dft_signal -view spec -type ScanDataIn -port scan_in
set_dft_signal -view spec -type ScanDataOut -port scan_out
create_test_protocol
metric test_protocol_created 1
metric proposed_chain_count 1
metric test_period_ns 100
redirect -file [file join $RPT_DIR dft_signals.rpt] {report_dft_signal}
redirect -file [file join $RPT_DIR dft_configuration.rpt] {report_dft_configuration}
redirect -file [file join $RPT_DIR scan_configuration.rpt] {report_scan_configuration}
set_dft_drc_configuration -enhanced_dft_drc_report enable \
    -log_dir [file join $DFT_RUN_DIR drc_work]
redirect -tee [file join $RPT_DIR pre_dft_drc.rpt] {set drc_result [dft_drc -verbose]}
metric dft_drc_executed 1
metric dft_drc_return $drc_result
redirect -file [file join $RPT_DIR dft_violations.rpt] {report_dft_drc_violations -summary}
redirect -file [file join $RPT_DIR dft_violations_details.rpt] {report_dft_drc_violations}
write_test_protocol -output [file join $DFT_RUN_DIR protocol ${TOP}_pre_dft.spf]
if {![file exists [file join $DFT_RUN_DIR protocol ${TOP}_pre_dft.spf]] ||
    [file size [file join $DFT_RUN_DIR protocol ${TOP}_pre_dft.spf]] == 0} {
    error "Protocolo SPF não foi gravado"
}
