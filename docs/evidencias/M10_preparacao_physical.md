# KUIDAMOS 6C — preparação do M10 físico

Revisão de 2026-11-20. **Pronto para iniciar um floorplan exploratório em
cópia do M9.** O Fusion Compiler abriu o handoff, validou a infraestrutura
SAED32 e concluiu o precheck de floorplan. A rede física de alimentação e
as constraints de teste permanecem trabalho de M10. Floorplan,
placement, CTS, routing e signoff seguem sem execução.

## Integração e integridade

O PR #2 foi integrado por merge commit
`2740f35f5ad807a0348d7b1441c1fe0a693463b5`, com os dois commits
originais e os 23 arquivos verificados na `main`. A `main` local foi
atualizada por fast-forward e serviu de base para a branch local
`feat/m10-physical-design`. O tip de `feat/m9-dft-scan` segue disponível
localmente e em `origin`. [PR #2](https://github.com/wagnerjunior77/kuidamos-pixel-frontend/pull/2)

O handoff é `outputs/dft/runs/20261120T142703Z-insertion-jTvumJ/`.
No diagnóstico foi aberta a cópia de `kuidamos_preview.dlib:scan_inserted.design`.
`link_block` retornou 1. Foram encontradas 1.256 células folha, 115
`SDFFX1_RVT`, zero células sem referência e zero posicionadas.
O `check_scan_chain` validou uma cadeia e registrou zero falhas.
`read_def -syntax_only` retornou 1. O corpo Verilog reexportado do
checkpoint coincidiu byte a byte com o da netlist pós-scan. O writer
reportou três `VW-007` por aliases de rede, presentes na exportação
equivalente. O verificador M9 confirmou 114 enlaces internos, 115 SEs,
as duas pontas, a ordem e a coerência de Scan DEF e SPF. Os 91 avisos
do DFT DRC são os resultados M9 já gravados.

A comparação SHA-256 antes/depois conferiu os 357 arquivos da execução M9,
incluindo checkpoint, netlist, SPF, Scan DEF e logs. O manifesto de
RTL, testbench e artefatos M8 também conferiu. O diagnóstico não
reexecutou síntese, DFT DRC ou simulações. [Evidência M9](M9_resultado_final.md)

## Tecnologia e alimentação

| Recurso | Observação |
|---|---|
| Referência | O checkpoint abriu com `CLIBs/saed32_rvt.ndm` do `SAED32_REF_ROOT`, tecnologia `saed32` proveniente de `tech/saed32nm_1p9m.tf`. As 38 referências utilizadas têm geometria e site `unit`. Há NDM de tecnologia e referência frame no mesmo conjunto SAED32. |
| Camadas, vias e site | M1–M9 com pitch definido, VIA1–VIA8 e 45 definições de via consultadas com `get_via_defs -tech`. O site `unit` existe e há zero rows no checkpoint. As direções das camadas vieram indefinidas. O ensaio definiu horizontal nas ímpares, vertical nas pares e em MRDL, limitando o roteamento a M9. Essa é a convenção da referência do laboratório. Com MRDL indefinida, o primeiro precheck emitiu nove `DPUI-924`. A configuração completa fez o aviso deixar de ocorrer. |
| RC | O checkpoint chegou sem associação de RC. O FC aceitou `saed32nm_1p9m_Cmin.lv.tluplus` e `saed32nm_1p9m_Cmax.lv.tluplus` com o mapa `saed32nm_tf_itf_tluplus.map`, usando a checagem avançada. Atribuição early Cmin e late Cmax a `ss0p95v125c` confirmada em memória. Cada importação emitiu `TLUP-012` pela entrada `DIFF` do mapa. Há também variantes Cmin/Cmax em `.nxtgrd`, identificadas em disco. A execução ainda não mediu extração em fios roteados. |
| PG e células físicas | O domínio padrão reporta `VDD` a 0,95 V e `VSS`. Há 1.256 pinos físicos de cada rail, sem redes físicas PG correspondentes no bloco. Foram localizados buffers `NBUFF*`, inversores `INV*`, fillers `SHFILL*` e tie cells `TIEH_RVT`/`TIEL_RVT`. As referências para CTS, a regra de tap/endcap e a estratégia PG serão definidas na preparação de implementação. |

`check_design -checks {netlist unbound dp_pre_floorplan}` retornou 1,
com **0 erros e 139 avisos estruturais** na execução final (DCHK-009 = 46,
DCHK-010 = 44, DCHK-017 = 2, DCHK-021 = 44 e DCHK-026 = 3).
Essa contagem vem de um check diferente do DFT DRC de M9. O teste
confirma o ponto de partida para inicializar o floorplan, com direções
e limites de roteamento explícitos.

## Licenças e ferramentas

`check_license` retornou 1 para `Fusion-Compiler-NX`,
`Fusion-Compiler-FE-NX` e `Fusion-Compiler-BE-NX`. A consulta verifica
a existência da feature. `get_licenses` retornou 1 para as três e
`list_licenses` confirmou os checkouts na sessão, incluindo o back-end.
A feature legada `Fusion-Compiler-BE` retornou 0 na consulta exploratória.
A operação de cada etapa física ainda terá seu próprio teste, pois um
checkout bem-sucedido cobre o acesso atual à feature.

PrimeTime, StarRC e IC Validator dedicados não foram localizados no PATH
ou nas instalações consultadas em `/opt/synopsys`. As consultas pelos
nomes `PrimeTime`, `StarRC` e `ICValidator` retornaram 0, sem teste
de checkout por pacote ou token alternativo. As licenças de signoff
dedicado permanecem incertas. O FC e a tecnologia local atendem ao
floorplan e à preparação inicial. O FC oferece STA e extração
com tabelas RC para análise interna. Uma exigência de signoff independente
requer confirmar a ferramenta e a licença correspondentes. Por exemplo,
`signoff_check_drc` depende de IC Validator e runset adequado. O ambiente
tem runsets SAED32 de DRC e metal fill em disco, ainda sem validação de
execução. Referências consultadas no FC instalado:
`check_license.2`, `get_licenses.2`, `read_parasitic_tech.2` e
`signoff_check_drc.2`.

## Restrições e próximo passo

O checkpoint carrega somente o cenário de STA `functional::ss0p95v125c`,
com clock de 10 ns, waveform {0 5} e delays/cargas funcionais do SDC M8.
O `scan_enable=0` usado para os relatórios M9 foi retirado antes do
checkpoint. O diagnóstico confirmou que o case analysis pode ser
aplicado de forma isolada ao modo funcional.

Foi criado apenas em memória `scan_shift_probe::ss0p95v125c` com
clock de 100 ns, waveform {45 55}, `scan_enable=1` e `reset_n=1`,
coerentes com o SPF. O check de timing sinalizou `scan_in` sem delay
relativo ao clock e `scan_out` sem restrição. O SPF é o protocolo de DFT.
Para STA são necessários cenários próprios de shift/captura, orçamento
de I/O da interface de teste, waveform e PVT min/max coerentes. A cópia
de entrada continua sem essas alterações salvas.

Execute o floorplan em uma nova cópia, aplicando o setup SAED32 verificado.
Registre dimensões, utilização, site rows, tracks, acesso aos pinos e
estratégia `VDD`/`VSS`. Resolva cobertura SDC, PG e critérios de
reordenação antes de otimização física. [Scripts, sequência e métricas](../../scripts/physical/README.md)

## Evidência local

Execução final em `outputs/physical/runs/20261120T150924Z-readiness-GuN6Bh/`,
retorno FC 0. Consulte `fc.log`, `handoff.log`,
`reports/check_design.rpt`, `reports/rc_trial.rpt`,
`reports/ignored_layers_trial.rpt`, `reports/scenarios_checkpoint.rpt`,
`reports/shift_timing_checks.rpt` e `reports/licenses_after.rpt`.
O wrapper roda exclusivamente o diagnóstico e mantém os resultados
nessa área ignorada pelo Git.
