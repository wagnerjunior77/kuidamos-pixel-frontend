# KUIDAMOS 6C — preparação e placement exploratório

O placement exploratório posicionou e legalizou 1.256 células.
O PG DRC pós-placement bloqueou o aceite por espaçamento em M1.
A pré-verificação publicada anteriormente está preservada abaixo.
[Resultado da execução](#segunda-execução--placement-exploratório)

## Histórico da pré-verificação

Pré-verificação executada em 2026-11-24 no Fusion Compiler
`X-2025.06-SP2`, em uma cópia de `powerplan_initial`.
**Placement não executado.** A política de contato de poços das células
RVT da instalação precisa ser confirmada para liberar a etapa física.
Os resultados abaixo são de inventário, geometria de referência e
STA pré-placement.

## Tap, endcap e compatibilidade PG

A NDM RVT carregada retornou zero células em `is_tap_cell` e em
`design_type == well_tap`. O inventário expôs apenas views de timing
e frame para essa referência. Os frames amostrados de `DCAP_RVT`,
`INVX1_RVT` e `SDFFX1_RVT` têm geometria M1, CO e NWELL. A geometria
abstrata permite inspecionar o acesso PG, mas não permite identificar
os implantes e verificar a rede de contato de poços por referência.

O deck local `saed32nm_1p9m_drc_rules.rs` distingue PTAP e NTAP e
contém regras de enclosure em poço e implante. A revisão não encontrou
nele uma política de inserção, espaçamento de taps entre células
ou confirmação de cobertura por taps internos na revisão RVT usada.
Também não foram localizadas views de layout de referência que
permitissem demonstrar essa cobertura. O exemplo SAED32 do laboratório
ilustra um fluxo de placement sem etapa dedicada de taps, mas não
especifica os critérios de contato dos poços. A documentação pública
da Synopsys situa a biblioteca no contexto de ensino, sem definir essas
regras. [FAQ acadêmico da Synopsys](https://sara.synopsys.com.tw/api/File/Download/PageContent/22/64cb7ebb-2efb-4ecf-92c7-31ae6b8a7d43.pdf)

| Referência | Observação |
|---|---|
| `DCAP_RVT` | A NDM classifica como `end_cap`. Site `unit`, 0,760 × 1,672 µm, com acesso PG junto aos limites superior e inferior do frame. Compatível geometricamente com o passo das rows e o alinhamento dos rails M1. O contato após colocação e o uso nas duas extremidades ainda requerem validação. |
| `TIEH_RVT` e `TIEL_RVT` | As duas referências estão disponíveis. Associar eventuais inserções aos requisitos de sinais constantes em uma etapa com autorização para alterar a netlist. |
| Fillers | Oito referências marcadas, cinco variantes `SHFILL` de uma altura e três `DHFILL` de duas alturas. Verificar orientação, altura de row e continuidade PG na seleção. |

A ajuda instalada confirma que `create_boundary_cells` usa as opções
`-left_boundary_cell` e `-right_boundary_cell` para início e fim de
cada row. A ferramenta também oferece espelhamento separado nas
bordas. A classificação da célula é evidência para avaliá-la como
endcap. Ela não demonstra que `DCAP_RVT` substitui um tap ou que a
mesma orientação serve para ambas as bordas. Nenhuma célula física
foi inserida.

**Condição para avançar:** obter, para a revisão SAED32 RVT usada, a
confirmação de que os contatos integrados cobrem as células selecionadas,
ou a regra de espaçamento e a referência aprovada para taps dedicados.
Confirmar também a orientação de endcaps nos dois extremos das rows
alternadas e verificar o contato VDD/VSS após legalização. A ausência
de uma célula dedicada na NDM é um resultado de inventário, sem concluir
que taps dedicados são dispensados ou obrigatórios. A lacuna de política
física bloqueou esta execução de placement.

## Cenários STA ensaiados

Foram configurados em memória `functional`, `scan_shift` e
`scan_capture_probe` para dois corners SAED32:

- `ss0p95v125c`, slow, processo 0,99, 0,95 V, 125 °C.
- `ff0p95vn40c`, fast, processo 1,01, 0,95 V, −40 °C.

O FC confirmou ausência de divergências PVT nos dois corners. O par RC
carregado no power plan foi associado como early `M10_Cmin` e late
`M10_Cmax` em ambos. O funcional preservou o clock de 10 ns e os
delays/cargas existentes do M8, com `scan_enable=0` aplicado ao modo.
Shift usou `scan_enable=1`, `reset_n=1` e o clock de 100 ns do SPF,
com bordas 45/55 ns.

As tabelas do SPF de shift, capture, launch e launch/capture inspecionadas
usam 100 ns e a mesma forma de onda. O procedimento de shift força
`scan_enable=1`. Os procedimentos de captura mantêm reset inativo e
deixam a seleção de scan no vetor de entradas do padrão. Para medir
os caminhos internos selecionados na captura, o probe aplicou
`scan_enable=0`, `reset_n=1` e waveform do SPF. É um caso estático.
A transição entre shift e captura, o alinhamento de SE à sequência de
launch/capture e eventual captura at-speed ainda precisam de definição.

### Pior folga dos caminhos analisados

| Cenário | Corner | Setup (ns) | Hold (ns) |
|---|---|---:|---:|
| Funcional | slow | +3,1640 | +0,2239 |
| Funcional | fast | +5,8486 | +0,0690 |
| Shift | slow | +99,6618 | +0,2073 |
| Shift | fast | +99,8503 | +0,0805 |
| Captura estática | slow | +95,7677 | +0,2574 |
| Captura estática | fast | +98,2695 | +0,1009 |

`report_global_timing` não encontrou violações de setup/hold entre
os caminhos cobertos nesses seis cenários. `check_timing -all` registrou
723 avisos TCK-001 de endpoints sem restrição, 212 TCK-012 de entradas
sem delays relativos ao clock e 2.512 TCK-014 de bibliotecas sem scaling.
A cobertura de teste é parcial. Faltam orçamentos externos de entrada
e saída de teste, cargas, incertezas e sequência validada de captura.
Nenhum valor de I/O ou exceção temporal foi acrescentado. Os números
são pré-placement, com clocks ideais e RC estimado. O hold funcional
fast de +0,0690 ns é um ponto de atenção quando clocks forem propagados.

## Integridade, estado físico e reprodução

A cópia abriu com 1.256 células, zero posicionadas, 52 rows e 115
`SDFFX1_RVT`. O FC validou uma cadeia, com zero falhas, e a netlist
reexportada coincide com o corpo da netlist do power plan. Os manifestos
SHA-256 antes/depois dos 2.867 arquivos protegidos conferiram.

O checkpoint físico de referência continua `powerplan_initial`.
Ausentes desta execução estão placement e legalização, métricas de
congestionamento pós-placement, verificação física célula–rail,
colocação dos 126 pinos, CTS e routing. A última validação de PG DRC
e continuidade da malha é a do power plan. [Evidência de PG](M10_power_planning.md)

Com o ambiente do FC carregado, a pré-verificação pode ser repetida:

```bash
./scripts/physical/run_placement_precheck.sh \
  outputs/physical/runs/20261124T181500Z-powerplan-lugkw9 \
  outputs/dft/runs/20261120T142703Z-insertion-jTvumJ/post/scan_protocol.spf
```

Execução validada em
`outputs/physical/runs/20261124T182348Z-placement-precheck-OgcYDY/`.
O FC saiu com código 0 e registrou `M10_PLACEMENT_PRECHECK_COMPLETED`.
Os relatórios de STA, ajuda nativa, frames, verificações e hashes
permanecem locais. As configurações de STA ficaram em memória e
nenhum checkpoint `placement_initial` foi salvo.
[Guia do fluxo físico](../../scripts/physical/README.md).

## Segunda execução — placement exploratório

Em 2026-11-24, o Fusion Compiler `X-2025.06-SP2` executou
`create_placement -floorplan -effort high`, `legalize_placement` e
`check_legality` em uma cópia nova de `powerplan_initial`. O ensaio
posicionou **1.256 células**, com **zero não posicionadas, zero
sobreposições e zero violações de legalidade**. O PG DRC bloqueou
o aceite por **5.892 violações de espaçamento em M1**.

### Decisão sobre taps e endcaps

- **Evidência direta da tecnologia.** A NDM RVT tem zero referências
  marcadas `is_tap_cell` ou `well_tap`. Os frames permitem inspecionar
  M1, CO, NWELL e terminais PG. O deck local distingue PTAP e NTAP, mas
  não estabelece a política de espaçamento de taps para as células
  mapeadas. Não foram encontrados LEF, GDS ou CDL do kit local que
  esclarecessem a presença e a cobertura de contatos integrados.
- **Endcap.** A NDM identifica `DCAP_RVT` como `end_cap`. O relatório de
  biblioteca também a descreve como decap. Ela ocupa cinco sites em uma
  única row de 1,672 µm. A referência lista `R0 R90 R180 R270 MX MXR90 MY
  MYR90` como orientações admissíveis da célula. O site `unit` não
  declara simetria X/Y, e a legalização reportou `LGL-031`, limitando
  as orientações efetivas. As rows de origem alternam `MX/R0`. O
  alinhamento M1 nessas orientações é uma indicação geométrica. A
  orientação de abutment à esquerda e à direita depende da configuração
  de boundary cells e da verificação de well/implantes. O ensaio
  preservou as rows e não inseriu endcaps, taps, ties ou fillers.
- **Referência acadêmica.** O script local `02-floorplan.tcl` do exemplo
  `santiago_cpu/1_synopsys_saed32_flow_dft/4_layout` coloca e legaliza
  standard cells após PG, sem uma etapa de inserção de well taps ou
  endcaps. A ajuda instalada confirma os comandos disponíveis na versão
  usada. O exemplo fundamenta o ensaio acadêmico. A política de well
  taps e a prevenção de latch-up continuam pendentes de signoff.

### Geometria, congestionamento e scan

A utilização das rows foi **49,9662%**, com 3.757,2649 µm² de área de
células em 7.519,6127 µm² de core. Foram ocupadas 50 das 52 rows.
A row mais ocupada ficou em **73,638%**. O verificador cruzou DEF e
bounding boxes do FC, confirmou alinhamento ao site e ausência de
sobreposições. Die, core, 52 rows, tracks, vias e `SPECIALNETS`
coincidiram com o checkpoint de PG. A estimativa global de
congestionamento registrou 34 unidades de overflow em 34 GRCs
(**0,47%** no agregado), todas na direção horizontal. O DEF exportado
ficou sem roteamento de sinal.

A netlist funcional reexportada coincide com a do power plan. O FC
preservou as 115 `SDFFX1_RVT`. `check_scan_chain` validou a cadeia
física `NN0` com 115 bits, de `scan_in` a `scan_out`, sem falhas.
A seção `SCANCHAINS` do DEF ficou idêntica. O comando de nomes lógicos
retornou a cadeia numerada, e `report_scan_path` registrou
`DFT-3005` após o comando de back-end. A conectividade e a ordem
foram confirmadas pelo DEF, pelo check estrutural e pela netlist
inalterada. Os fanouts medidos são 115 em `clk`, 115 em
`scan_enable` (alias `test_se0`) e 4 em `reset_n`.

As restrições de borda e camada das 126 portas permanecem iguais.
O check de pinos registrou 123 pinos ausentes. O DEF confirmou que as
126 portas de sinal, incluindo as três de scan, continuam sem shapes.
O acesso físico de sinal permanece pendente. Os quatro terminais
físicos PG foram preservados.

### PG colocado

O `check_pg_connectivity -check_std_cell_pins all` carregou as 1.256
células posicionadas. Confirmou um componente conectado por rede,
zero células com pino PG desconectado e zero trilhos, vias ou terminais
flutuantes. O contato físico célula–rail passou no escopo desse check.

O `check_pg_drc` com as geometrias das células incluídas reportou
**5.892 erros M1**. Foram 4.767 `Min-Spacing-On-Layer` e 1.125
`Fat-Metal-Spacing-Table-Rule`. O cruzamento com as caixas dos
trilhos mostra que **5.399 ocorrências** envolvem diretamente **52 de
53 rails contínuos** de 0,152 µm. Em um caso, a folga observada entre
o rail e o metal da célula foi 0,020 µm para um mínimo de 0,060 µm.
A violação aparece após o placer trazer as geometrias das células
para as rows. A aprovação de continuidade e a legalidade do site
não cobrem essa regra de espaçamento. O PG original foi preservado.

### STA após o placement

| Modo | Corner | Pior setup (ns) | Pior hold (ns) | Max transition | Max capacitance |
|---|---|---:|---:|---:|---:|
| Funcional | slow | +1,4430 | +0,2428 | 11 | 66 |
| Funcional | fast | +5,1454 | +0,0776 | 4 | 68 |
| Shift | slow | +99,6367 | +0,2173 | 12 | 66 |
| Shift | fast | +99,8378 | +0,0848 | 4 | 68 |
| Captura estática | slow | +94,8409 | +0,2768 | 12 | 66 |
| Captura estática | fast | +97,8783 | +0,1101 | 4 | 68 |

Para os caminhos cobertos, os seis cenários reportaram zero violações
de setup/hold e TNS 0. Em relação ao pré-placement, o setup funcional
slow caiu 1,7210 ns e o hold funcional fast subiu 0,0086 ns. A folga de
hold fast continua pequena com clock ideal. A análise usou o par
Cmin/Cmax herdado e RC estimado. Faltam budgets de I/O de teste e a
sequência de launch/capture. O check de cobertura manteve os avisos
TCK-001, TCK-012 e TCK-014. Os relatórios de fanout registram cargas
medidas. O SDC de origem não define um limite explícito de fanout.

### Reprodução e critério para continuar

```bash
./scripts/physical/run_placement.sh \
  outputs/physical/runs/20261124T181500Z-powerplan-lugkw9 \
  outputs/dft/runs/20261120T142703Z-insertion-jTvumJ/post/scan_protocol.spf
```

A execução em `outputs/physical/runs/20261124T183431Z-placement-EGZHsv/`
guardou `reports/placement.def`, `placement.svg`, os relatórios FC
e os manifestos SHA-256. O FC terminou a coleta e o wrapper retornou
4 para indicar o bloqueio de PG DRC. O checkpoint de origem, a netlist
e as execuções anteriores foram preservados. A tentativa ficou sem
checkpoint aceito `placement_initial`.

Para liberar CTS exploratório, resolver a compatibilidade geométrica
dos rails M1 e dos landings com as células posicionadas numa cópia
derivada de PG. Reexecutar placement, DRC e continuidade nesse ponto.
Aprovação física exige ainda política de taps/endcaps, acesso de pinos,
STA de teste, CTS, routing, extração e verificações de signoff.

## Atualização — correção PG validada

A tentativa acima permanece registrada como rejeitada. A execução
posterior ajustou apenas a largura dos rails M1 para 0,060 µm e
obteve PG DRC limpo com as 1.256 células legalizadas e alimentadas.
Os checkpoints `powerplan_corrected` e `placement_initial` foram
reabertos. [Causa raiz, testes e resultado](M10_correcao_pg_placement.md).
