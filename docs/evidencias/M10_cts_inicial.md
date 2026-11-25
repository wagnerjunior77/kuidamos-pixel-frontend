# M10 — pin placement e CTS exploratório

Execução de 24/11/2026 no Fusion Compiler X-2025.06-SP2 com SAED32 RVT.
A entrada foi o `placement_initial` validado em `9fa74f3`, com os seis
cenários STA, 52 site rows, rails M1 de 0,060 µm e uma cadeia de 115 SDFFs.
A execução `20261124T185502Z-cts-EVbYma` trabalhou em uma cópia da DLIB.
Os manifestos SHA-256 antes e depois conferiram para RTL, M8, M9, constraints
e execuções físicas anteriores. Os artefatos desta execução ficam em
`outputs/physical/runs/`, ignorado pelo Git.

## Pinos e acesso

`place_pins -self -ports` criou 126 shapes. O DEF confirmou 29 portas à
esquerda e 14 à direita em M3, 5 no topo e 78 na base em M4. O topo recebeu
`clk`, `reset_n`, `scan_enable`, `scan_in` e `scan_out`. Todos os shapes
tocam a borda esperada, estão centrados sobre trilhas, respeitam espaçamento
de pelo menos duas trilhas e keepout de quatro trilhas nos cantos.
`check_pin_placement` registrou zero violações de borda, camada, trilha,
espaçamento, curto ou sobreposição com pré-roteamento. Essa é uma validação
geométrica de acesso. A conexão do pino pela rota detalhada será checada no
routing. `in_sol` e `in_eol` têm shapes e seguem sem cargas internas, como
no placement de origem.

As 1.256 células, a netlist, as 52 rows e a seção de scan do DEF
conferiram com a origem. O PG DRC ficou em zero, com uma rede conectada
por rail e zero pinos PG desconectados. O ponto intermediário foi salvo
como `pins_initial`.

## Diagnóstico elétrico antes do CTS

Depois de posicionar os pinos, os seis relatórios registraram 7 violações
de transição e 74 de capacitância por cenário fast, e 16 de transição e 71
de capacitância por cenário slow. O relatório usa limites distintos por
driver e condição. Exemplos no modo funcional slow:

| Rede e driver | Verificação | Limite | Medido |
|---|---|---:|---:|
| `pixel_out_valid`, `pixel_out_valid_reg/Q` | Transição | 0,0856 ns | 0,1393 ns |
| `n475`, `U744/Y` (`NOR3X0_RVT`) | Transição | 0,1009 ns | 0,1356 ns |
| `n297`, `U321/Y` (`INVX0_RVT`) | Transição | 0,4652 ns | 0,4801 ns |
| `n305`, `U559/Y` (`NBUFFX2_RVT`) | Capacitância | 16,0000 fF | 41,3039 fF |
| `n304`, `U316/Y` (`NBUFFX2_RVT`) | Capacitância | 16,0000 fF | 38,7564 fF |
| `n297`, `U321/Y` (`INVX0_RVT`) | Capacitância | 8,0000 fF | 26,2373 fF |

Os fanouts na entrada eram 115 para `clk`, 4 para `reset_n` e 115 para
`scan_enable` (rede `test_se0`). Os relatórios de violadores não
atribuíram violações a essas três redes. O CTS distribuiu a carga de
`clk` por drivers internos, e as redes de clock apresentaram zero
violações de transição e capacitância no resumo pós-CTS. Reset e SE
mantiveram o fanout original. O fanout de SE merece nova análise quando
o modelo de acionamento externo estiver disponível.

O CTS não corrige os DRVs de dados. Os casos `n305` e `n304` são
candidatos a reforço de driver ou segmentação de carga. Em nets dirigidas
por SDFF e suas saídas funcionais, qualquer correção deve identificar a
derivação de scan para preservar a ligação SI/Q/QN e repetir a validação
de shift. Os limites e a netlist de dados foram preservados nesta
execução. Os relatórios `pins/reports/*.drv.rpt` e
`cts/reports/*.drv.rpt` listam os drivers, limites e valores por cenário.

## Construção da árvore

A ajuda local confirmou `synthesize_clock_trees`, `clock_opt`,
`set_clock_tree_options`, `set_clock_routing_rules` e `insert_buffer`.
A execução aceitou nove referências RVT para CTS, cinco buffers
`NBUFFX2/4/8/16/32_RVT` e quatro inversores `INVX1/2/4/8_RVT`. Usou
regra padrão M3–M6, acesso aos pinos de célula nas camadas locais e alvo
de skew de 0,050 ns. O alvo é exploratório, escolhido abaixo da folga
de hold funcional fast de origem (+0,0776 ns). A definição foi aplicada
aos seis cenários e confirmada no log do motor CTS.

Um ensaio isolado de `clock_opt -from build_clock -to route_clock`
executou a etapa de roteamento de clock e alterou o inventário de dados
durante a otimização. A alternativa adotada foi `synthesize_clock_trees`
para controlar as mudanças na netlist e preservar os caminhos de scan.
O ensaio de `clock_opt` foi descartado após a coleta de diagnóstico.

No primeiro ensaio com `synthesize_clock_trees`, o otimizador removeu os
repetidores, deixando 115 cargas no porto de clock ideal. Na execução
aceita, `insert_buffer` criou `CTS_ROOT` (`NBUFFX16_RVT`) para
definir um driver interno e limitar a porta a uma carga. O FC inseriu
quatro buffers adicionais. O inventário final contém três
`NBUFFX16_RVT`, um `NBUFFX32_RVT`, um `NBUFFX2_RVT` e zero inversores
novos. O grafo exportado confirma dois buffers entre a porta e cada um
dos 115 sinks. O relatório nativo usa outra contagem de níveis, em que
a árvore tem três níveis.

Um ensaio com os cinco buffers ainda sem associação a VDD/VSS apresentou
283 marcadores `No-Illegal-Overlaps-Rule` (147 em M1 e 136 em CO),
incluindo sobreposições de PG com shapes de rede desconhecida nas novas
células. A execução aceita aplicou
`connect_pg_net -automatic -pg -report_connection_summary true`, que
associou dez pinos. A geometria da rede PG conferiu com o DEF de entrada.
A legalização incremental moveu 16 células originais. Todas as 1.261
células ficaram legalizadas, com zero violações de legalidade, zero PG
DRC, uma rede por rail, zero células flutuantes e zero pinos PG
desconectados. O check de pinos continuou com zero violações.

A área de células passou de 3.757,2649 para 3.788,2704 µm² (+0,83%).
A utilização passou de 49,9662% para aproximadamente 50,38%. O overflow
global estimado passou de 0,49% para 0,39%. O DEF da execução aceita
contém os nets da árvore e os shapes de PG. A geometria das rotas de
clock e de sinais ainda está pendente. O mapa global coletado foi usado
para estimar congestionamento.

## Clock propagado e STA

O clock funcional manteve 10 ns. Shift e captura estática mantiveram
100 ns, com bordas 45/55 ns. Shift usou SE=1 e captura estática, SE=0,
com reset síncrono inativo no teste. Os seis cenários usaram os corners
`ss0p95v125c` e `ff0p95vn40c` e as referências RC herdadas do placement.

| Modo | Corner | Pior folga setup (ns) | Pior folga hold (ns) | TNS setup/hold (ns) | Skew global (ns) | Trans./cap. violadas |
|---|---|---:|---:|---:|---:|---:|
| Funcional | slow | +1,5506 | +0,1855 | 0/0 | 0,0224 | 16/71 |
| Funcional | fast | +5,2020 | +0,0644 | 0/0 | 0,0118 | 7/74 |
| Shift | slow | +99,6055 | +0,2146 | 0/0 | 0,0224 | 16/71 |
| Shift | fast | +99,8280 | +0,0838 | 0/0 | 0,0118 | 7/74 |
| Captura estática | slow | +94,8225 | +0,2775 | 0/0 | 0,0224 | 16/71 |
| Captura estática | fast | +97,8686 | +0,1143 | 0/0 | 0,0118 | 7/74 |

O menor hold coberto foi o funcional fast, que perdeu 0,0132 ns em
relação ao placement. O hold de shift fast foi de +0,0848 para +0,0838 ns.
Os relatórios globais não indicaram violações de setup ou hold nos
caminhos cobertos. Os relatórios de caminho mostram clock propagado.

| Corner, nos três modos | Latência de rede nos sinks (ns) | Maior transição reportada nos sinks (ns) |
|---|---:|---:|
| Fast | 0,0392–0,0510 | 0,0218 |
| Slow | 0,0840–0,1064 | 0,0432 |

O skew global ficou entre 0,0118 e 0,0224 ns. No relatório de skew local
de setup, a pior magnitude individual foi 0,0052 ns em funcional/captura
fast, 0,0113 ns em funcional/captura slow, 0,0111 ns em shift fast e
0,0237 ns em shift slow. O histograma de clock reportou 77,8224 fF
distribuídos pelos seis nets da árvore, com máximo de 34,3971 fF.
Os valores refletem RC estimado com relógios propagados.

## Scan, persistência e reprodução

A seção `SCANCHAINS` do DEF permaneceu idêntica à origem. O
`check_scan_chain` validou 115 bits na cadeia `NN0` (nome físico da
cadeia M9). A netlist foi comparada ao placement e à ordem M9, incluindo
SI, Q/QN, SE e extremidades `scan_in`/`scan_out`. Cada CLK chega à
raiz com a polaridade original. Entre as 1.256 células de origem, só mudaram as conexões dos pinos CLK
dos SDFFs.

O VCS X-2025.06-SP2 passou 15/15 cenários funcionais em 2.618 ciclos,
com zero divergências no scoreboard, e verificou 460 pulsos de shift
com a ordem original, incluindo descarregamento após captura. A
simulação gate-level usou os modelos SAED32, sem checks temporais.
O monitor de assertions internas do RTL fica fora desse teste.

Após as verificações e o VCS, o fluxo salvou `cts_initial` e reabriu o
checkpoint em outro processo. Netlist, seções do DEF, legalidade, pinos
e PG conferiram. A DLIB, a netlist, o DEF com Scan DEF, a visualização
`cts_tree.svg`, os logs e os relatórios permanecem na pasta local da
execução. Os segmentos no SVG representam conectividade e posições
exportadas, sem inferir o traçado físico do clock.

Com `fc_shell` e `vcs` no PATH, a referência SAED32 acessível pelos
caminhos persistidos na DLIB e `SAED32_REF_ROOT` exportada para o
modelo Verilog do VCS:

```bash
./scripts/physical/run_cts.sh \
  outputs/physical/runs/20261124T184151Z-placement-VPBjaK \
  outputs/dft/runs/20261120T142703Z-insertion-jTvumJ/post/actual_chain.tsv
```

O wrapper aceita `FC_SHELL` para indicar o binário e
`M10_TIMEOUT_SECONDS` para limitar cada sessão FC. Cada execução
cria uma nova pasta, com `pins/`, `cts/`, `readback/`,
`sim_handoff/` e manifestos locais. O log final registra
`CTS_VALIDATED` e `PROTECTED_INPUTS_MATCH`.

## Pendências físicas

O checkpoint permite preparar uma tentativa de routing exploratório em
nova cópia, começando pela árvore de clock, acesso aos pinos e correções
de DRV orientadas pelos relatórios. O hold funcional fast e o hold de
shift devem ser reavaliados a cada mudança e com parasitas extraídos.
A cobertura MMMC segue parcial. Faltam parâmetros externos de
`scan_in`/`scan_out`, acionamento de SE e especificação de captura
at-speed. O FC ainda registrou avisos de contatos CO, ties no modelo do
roteador e tensão padrão ausente para cálculos de potência. Os checks
de PG cobrem conectividade geométrica e os checks internos da ferramenta.
Política de taps e endcaps, prevenção de latch-up, IR/EM, extração
pós-route, DRC/LVS e signoff físico permanecem pendentes.
