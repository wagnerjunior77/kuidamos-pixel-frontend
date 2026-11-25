# M10 — entrega acadêmica da implementação física

**Resultado em 25/11/2026 — concluído no escopo acadêmico.** O Fusion
Compiler implementou o bloco até o roteamento, extraiu parasitas e
produziu resultados de área, temporização e potência. A execução
`20261125T172651Z-physical-final-gHPSc7` salvou e reabriu
`physical_final`. O signoff para fabricação permanece pendente.

## Escopo oficial e critério de entrega

A seção 6C, §§6.6–6.8, exige executar a implementação física de forma
reproduzível conforme o ambiente CIExpert, analisar e documentar área,
temporização e potência quando disponíveis, identificar tecnologia e
versões e registrar restrições e limitações. O ponto de análise é
100 MHz, com demonstração por relatórios e registro de eventuais
violações. As atividades e os artefatos executados satisfazem o
critério de M10 do plano original. [Escopo oficial](../referencias/definicao_escopo_grupo_6_oficial.pdf) · [Plano de execução](../plano_de_execucao.md)

- **Obrigatórios para M10.** Implementação reproduzível na extensão
  suportada, constraints de referência, relatórios obtidos de área,
  timing e potência e rastreabilidade da base M9. O handoff final,
  o quadro de métricas e os comandos abaixo atendem a esses itens.
- **Condicionados ao ambiente.** A seção 6C condiciona as etapas físicas
  e DFT à configuração educacional e a potência à disponibilidade
  dos dados. A análise de potência foi viável e integra esta entrega.
- **Extensões.** ATPG, regressão pós-layout com SDF, equivalência
  formal e signoff independente de fabricação permanecem atividades
  adicionais. A verificação RTL com scoreboard e SVA é obrigatória
  para o projeto e tem evidência própria em M7.

## Trajetória física

| Etapa | Evidência |
|---|---|
| Preparação | Checkpoint pós-scan e referência SAED32 RVT, tecnologia 1P9M, corners `ss0p95v125c` e `ff0p95vn40c`. [Preparação](M10_preparacao_physical.md) |
| Floorplan | Aproximadamente 50% de utilização inicial e 52 rows `unit`. [Floorplan](M10_floorplan_inicial.md) |
| PG e placement | Anéis M7/M8, malha M5/M6 e 53 rails M1. Rails ajustados para 0,060 µm após investigar o DRC. 1.256 células originais legalizadas. [PG](M10_power_planning.md) · [Correção e placement](M10_correcao_pg_placement.md) |
| Pinos e CTS | 126 portas em M3/M4. Cinco buffers e 115 sinks. [Pinos e CTS](M10_cts_inicial.md) |
| Routing | Seis redes de clock e todos os sinais com carga roteados. Otimização de dados com proteção da topologia de scan e clock. [Routing](M10_routing_inicial.md) |
| Fechamento | ECO incremental em cópia de `routing_initial` de `eda3e24`, com exportação e verificação independentes do readback. |

## ECO de fechamento

O Fusion Compiler trocou os dois drivers `DELLN1X2_RVT` por
`NBUFFX4_RVT` em `u_resize_nn_core/ropt_net_18` e `ropt_net_9`,
reforçou `u_crop_core/U142` de `AO22X1_RVT` para `AO22X2_RVT`
e redimensionou `pixel_out_reg_7_` de `SDFFX1_RVT` para
`SDFFX2_RVT`. As variantes preservaram os pinos e a função.
A primeira tentativa zerou as violações originais, mas em fast
`U717/Y` passou a dirigir 8,0444 fF em `n421`, com limite de 8 fF.
Como a referência oferece `NOR4X1_RVT` como o NOR4 de maior drive,
o fluxo inseriu um `NBUFFX2_RVT` junto à saída de U717 para dirigir
a carga. Cada intervenção foi seguida de conexão PG, legalização
e `route_eco`. Os seis relatórios finais registraram **zero
violações de transição e capacitância**, com os limites originais.

A comparação de netlists confirmou a preservação dos terminais
funcionais ao abstrair os buffers não inversores e a identidade das
ligações diretas SI, SE, Q/QN e CLK dos SDFFs. As rotas das seis
redes de clock conferiram exatamente nas duas seções do DEF. O
verificador registrou quatro redimensionamentos e um buffer
adicionado, sem remoção de células. Essa verificação é estrutural.
A prova formal permanece pendente.

## Área, integridade física e scan

| Marco | Área de células (µm²) | Células folha |
|---|---:|---:|
| M8 — síntese lógica | 3.523,4524 | 1.256 |
| M9 — pós-scan | 3.757,2649 | 1.256 |
| M10 — pós-route final | 3.878,9998 | 1.276 |

M10 tem área de células **10,09% acima de M8** e **3,24% acima de
M9**. A área compara células, sem o valor de interconexão estimado
separadamente em M8. A utilização final foi **51,59%**.

- **Roteamento.** 1.486/1.486 redes que exigem conexão com rota
  detalhada. As duas redes restantes no DEF correspondem a
  `in_sol` e `in_eol`, entradas intencionalmente sem cargas.
  Foram registrados zero opens, shorts e DRC interno, 27.312 µm de
  fios, 11.360 vias e estimativa global de overflow de 0,81%.
- **Legalidade, PG e interfaces.** 1.276 células legalizadas, zero
  erros de PG DRC e zero pinos PG desconectados. A geometria dos
  rails, die, 52 rows, trilhas e 126 shapes de portas conferiu com
  o routing original. A continuidade das seis redes de clock foi
  verificada após o ECO e no readback.
- **Scan.** Uma cadeia de 115 células, 105 X1 e dez X2, com 114
  enlaces diretos, os mesmos extremos, a mesma ordem e zero
  exclusões. O Scan DEF integrado e o separado conferiram.
  A regressão funcional da netlist final passou **15/15 cenários
  em 2.618 ciclos**, com zero divergências no scoreboard. O
  teste de shift passou **460 pulsos**, mantendo a ordem M9.
  Ambos são testes gate-level lógicos, com os modelos RVT
  e checks temporais desativados.

## Timing e parasitas

O FC registrou extração em modo DR das 1.486 redes roteadas. Foram
exportados quatro SPEFs, com Cmin para early e Cmax para late nos
dois corners. O clock propagado manteve a referência de 10 ns no
funcional e 100 ns no shift e na captura estática. A configuração
de extração agrega a capacitância de acoplamento ao terra. A
análise de SI e a correlação independente ficam pendentes.

| Cenário | Pior setup (ns) | Pior hold (ns) | TNS setup / hold (ns) | Endpoints violados | Skew global (ps) |
|---|---:|---:|---:|---:|---:|
| Funcional slow | +1,8647 | +0,1861 | 0 / 0 | 0 / 0 | 20,6 |
| Funcional fast | +5,3614 | +0,0639 | 0 / 0 | 0 / 0 | 10,9 |
| Shift slow | +99,6606 | +0,2119 | 0 / 0 | 0 / 0 | 20,6 |
| Shift fast | +99,8550 | +0,0827 | 0 / 0 | 0 / 0 | 10,9 |
| Captura estática slow | +94,4061 | +0,2761 | 0 / 0 | 0 / 0 | 20,6 |
| Captura estática fast | +97,7190 | +0,1136 | 0 / 0 | 0 / 0 | 10,9 |

A folga funcional slow variou −0,2 ps frente a `routing_initial`
e os holds fast funcional e shift permaneceram iguais na precisão
dos relatórios. O clock alcançou os 115 sinks. Sua latência foi
39,4–50,3 ps em fast e 84,4–105,0 ps em slow. O MMMC cobre os
caminhos restringidos pelos cenários herdados. O modo funcional
tem 231 endpoints desabilitados, constantes ou sem check por
corner. Os dois modos de teste têm 246 por corner, além de
`scan_in` sem atraso no shift e 105 entradas sem atraso na captura
estática. Budgets de I/O e captura at-speed requerem especificação.

## Potência pós-route

O VCS coletou SAIF a partir dos 15 cenários funcionais da netlist
gate-level final, por 26.176 ns, com resets, períodos ociosos e
estímulos da regressão. A frequência foi 100 MHz. O Fusion Compiler
importou essa atividade na cópia de análise e usou o RC detalhado.
O cenário foi `functional::ss0p95v125c`, com VDD a 0,95 V, VSS a
0 V e temperatura de 125 °C, conforme a biblioteca RVT e o PVT.
A estimativa não inclui uma carga temporal de glitches medida em
simulação com SDF.

| Componente | Potência estimada (µW) |
|---|---:|
| Interna | 138,3041 |
| Switching | 30,3132 |
| Dinâmica total | 168,6173 |
| Leakage | 189,7378 |
| **Total** | **358,3551** |

O FC associou 1.954 entradas de net e 139 instâncias do SAIF. Entre
os 1.488 drivers reportados, **1.479 (99,40%)** têm atividade
simulada, 2 derivada e 7 calculada. O SAIF original foi preservado.
A primeira importação encontrou conflito entre `scan_out` e o
bit órfão `y_q[9]`, que ficava em X durante toda a janela no
Verilog exportado. A análise final removeu somente a entrada
órfã na cópia do SAIF, após confirmar sua ausência nas conexões
do Verilog e seus contadores sempre-X. A potência bruta era
358,6667 µW. A importação final eliminou POW-076 e manteve um
aviso POW-091 de palavra-chave desconhecida. O resultado é uma
estimativa da regressão, com cobertura relatada e sem medição
de bancada ou análise de IR/EM.

M8 registrou 267,27 µW no mesmo PVT e frequência. A atividade
era propagada pelo Design Compiler sem SAIF, com carga de fios
estimada, sem scan ou árvore de clock implementada. A diferença
entre os dois totais agrega mudanças de estímulo e de modelo e
não isola o efeito de M10. [Metodologia de potência de M8](M8_sintese_dc.md#6-estimativa-de-potência-outputssynthesisreportspowerrpt)

## SDF e verificações independentes

Os quatro SDFs originais foram preservados. O diagnóstico de
`routing_initial` mostrou 372 erros em seletores de barramento
escapados. A normalização dos seletores numa cópia eliminou esses
erros. O VCS da execução final anotou a cópia funcional slow com
zero erros e **15 avisos SDFCOM_UHICD**. Os trechos afetados são
interconexões ascendentes dos pinos Q dos SDFFs para `scan_out`,
`pixel_out[7:0]`, `pixel_out_valid`, os quatro marcadores de
vídeo e `cfg_error`. O VCS informou que ignorou os trechos
`INTERCONNECT` e aplicou atraso `DEVICE` ao Q. Há derivações
de scan nas mesmas saídas, portanto essa aproximação não
demonstra equivalência da anotação por destino.

A opção documentada `+multisource_int_delays` foi ensaiada
sobre o candidato de routing anterior e manteve os 15 avisos.
A opção `+vcs+mipdexpand` da ajuda instalada cobre entradas
`PORT` por bit e não esses trechos `INTERCONNECT` ascendentes.
A anotação disponível é parcial. A regressão temporal dinâmica
com checks habilitados permanece bloqueada por essa lacuna.

| Ferramenta ou verificação | Resultado operacional |
|---|---|
| Fusion Compiler X-2025.06-SP2 | Checkout com sucesso de `Fusion-Compiler-NX`, `Fusion-Compiler-FE-NX` e `Fusion-Compiler-BE-NX`. Executou ECO, roteamento, PG, extração, STA e potência. |
| VCS X-2025.06-SP2_Full64 | Compilação e simulação operacionais. Funcional, shift, geração SAIF e diagnóstico SDF efetivamente executados. |
| PrimeTime e StarRC standalone | Executáveis não localizados no PATH ou na instalação Synopsys inspecionada. STA e extração foram feitas no FC. Licenças standalone não foram verificadas por checkout. |
| IC Validator | O FC tentou `signoff_check_drc -check_all_runset_layers true` em cópia, com o runset SAED32 local. O comando parou com RT-120 pela ausência do executável. |
| Runsets e antena | A referência contém runsets DRC e metal fill. Não foi localizado deck LVS na mesma referência. O roteador indicou ausência de regras de antena ativas. |
| Verificações independentes viáveis | VCS gate-level e comparação Python de DEF, netlist, conectividade e cadeia. DRC/LVS e correlação de STA, RC e potência por ferramenta independente seguem pendentes. |

A referência RVT disponibiliza `DCAP_RVT`, fillers e ties,
mas as views disponíveis não demonstram cobertura de contatos
de poço ou política de inserção de taps. Faltam critérios de
implantação e qualificação de endcaps e células físicas. A base
continua sem inserção de taps, endcaps, fillers e ties físicos.
Latch-up e IR/EM exigem vistas, regras, condições de alimentação
e análises próprias. ATPG e equivalência formal também seguem
pendentes. Essas limitações não anulam os resultados acadêmicos
registrados e devem acompanhar qualquer uso da base física.

## Reprodução e inventário local

Com `fc_shell` e `vcs` no PATH, o mesmo checkpoint e a referência
SAED32 RVT disponíveis, exporte `SAED32_REF_ROOT` e execute:

```bash
./scripts/physical/run_physical_final.sh \
  outputs/physical/runs/20261124T191401Z-routing-lYzSdE \
  outputs/dft/runs/20261120T142703Z-insertion-jTvumJ/post/actual_chain.tsv
```

O wrapper cria uma DLIB independente e registra versões, hashes
dos insumos, regressões, área, potência e readback. O diagnóstico de
SDF usa `probe_routing_sdf.sh <execução> <SDF> --normalize-bus`.
Os manifestos `protected.before.sha256` e `protected.after.sha256`
conferiram para RTL, constraints, M8, M9 e execuções anteriores.

A execução `20261125T172651Z-physical-final-gHPSc7`, sob
`outputs/physical/runs/`, guarda o checkpoint, DEF/Scan DEF,
netlist, SPEFs, SDFs, SAIF original e tratado, SVG, resultados
de VCS e relatórios. Os artefatos e relatórios restritos
permanecem locais. Os hashes abaixo identificam os arquivos
dessa execução.

| Arquivo local | SHA-256 |
|---|---|
| `kuidamos_preview.dlib/physical_final/design.ndm` | `3460782a4344cad6d3820ddf5a30ebc78076a2e5b0614d28869da5903517300a` |
| `signals/reports/design.def` | `ee88876c7a478092fc16a6bab501987c29c8338bcf2c6c9e3322025851bbc5e7` |
| `signals/reports/scan.def` | `4adbb5e983b0df9a14990079d7cd7a77774cc2662ad8f1f6df38b1eb88c72f83` |
| `signals/reports/netlist.v` | `f0a0f2b3985d299a58b35adfb55aba6effa3c99bd27702238e7fb6da63ede3b2` |
| `signals/reports/ff0p95vn40c.M10_Cmax_-40.spef` | `6fe771c6141ef02f9d3d1dd94e581c2074b1587f7330d3eaec4096b235db4304` |
| `signals/reports/ff0p95vn40c.M10_Cmin_-40.spef` | `ade870c0402d82f0c887b60d25bd095e7ccfc5b1874358d2b9d3ee6b16fc7e81` |
| `signals/reports/ss0p95v125c.M10_Cmax_125.spef` | `508b34716ec9c1b2a9e15e6b6a8e3f9cc418460841cc3e578aacfc61dbf88d1b` |
| `signals/reports/ss0p95v125c.M10_Cmin_125.spef` | `61b53612ee105ab803de675c790e6faba97f5443f915d0473932f9b3357194ec` |
| `signals/reports/functional.ff0p95vn40c.sdf` | `f543a4ce4eb740643c9c915e9773fef0d780c12e89b049f3eba01e2d0d6a7957` |
| `signals/reports/functional.ss0p95v125c.sdf` | `334beaaa9cf74e3d8348f69f8ece6cfff40060237b20751b954bf234720b433a` |
| `signals/reports/scan_shift.ff0p95vn40c.sdf` | `463795ee01e2c93ceef743b4fa4927e2cb3afc5431b66daf2355821e516cb330` |
| `signals/reports/scan_shift.ss0p95v125c.sdf` | `5fcc2e82e13e73a1da63f1131f10a8e96ecd7eb5f7c0ca9d89a8eb6b103df323` |
| `sim_handoff/sim-post_scan-1XTLE4/activity.saif` | `564e6786503fcf282e991e9ac580863e3790a37f6a845dbea2281cc07a2f60f7` |
| `activity_for_power.saif` | `4bb2b15ea9281f46f4041726d9c2a11796da84a7c9a9493100e08db96648b4d5` |
| `signals_layout.svg` | `f2c9e23579fccb3fd414e558023afe90973bb3cdee231e5e65f736d417a01733` |
| `power/reports/power.rpt` | `c5a3692e47c6055665462fa959541c237836b9a039cbfa5893b227d501a20c47` |
| `inputs.sha256` | `fe9963167682027d9ebdac3eb7f601ffaa3ad3602e7e2c6195095bba4121faed` |
| `protected.after.sha256` | `8bd322d12c5c39835253ecb6f8f9bd094750ce619ec45fef8379024f23531187` |
