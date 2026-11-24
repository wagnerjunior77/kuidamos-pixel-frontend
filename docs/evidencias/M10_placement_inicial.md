# KUIDAMOS 6C — preparação para placement

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
