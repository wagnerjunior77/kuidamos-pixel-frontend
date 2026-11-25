# M10 — routing exploratório e extração pós-route

Em 24/11/2026, o Fusion Compiler X-2025.06-SP2 derivou a execução
`20261124T191401Z-routing-lYzSdE` do checkpoint `cts_initial`
validado no commit `3ffb45b`. A referência foi SAED32 RVT, com os
seis cenários STA e os modelos Cmin/Cmax que já estavam no checkpoint.
Os manifestos SHA-256 conferiram antes e depois para RTL, constraints,
M8, M9 e as execuções físicas anteriores.

## Roteamento e correções

1. `size_cell` trocou `U559` e `U316` de `NBUFFX2_RVT` para
   `NBUFFX8_RVT`, e `U321` de `INVX0_RVT` para `INVX4_RVT`.
   No CTS funcional slow, os três drivers tinham, respectivamente,
   41,4495 fF com limite de 16 fF, 39,0063 fF com limite de 16 fF e
   26,2679 fF com limite de 8 fF. A transição de `U321/Y` também
   excedia o limite de 0,4652 ns. As redes `n305`, `n304` e `n297`
   saíram dos relatórios de violadores após sizing e routing.
2. `route_group -all_clock_nets` roteou a árvore já sintetizada.
   As seis redes passaram no check de opens. O roteador reportou
   404 vias e 738 µm de fios roteados no estágio de clock, com
   zero DRC interno. O PG DRC continuou em zero e o fluxo salvou
   `clock_routed`. Com esse checkpoint, o máximo skew global foi
   21,8 ps e os holds funcional fast e shift fast foram +0,0645 ns
   e +0,0838 ns.
3. `route_auto` executou global routing, track assignment e detailed
   routing. O primeiro check completo já indicou zero opens e zero
   DRC interno. Os relatórios `pre_opt/` mostram 3 a 9 violações de
   transição e 64 a 65 de capacitância por cenário nessa fase.
4. `route_opt` operou com 123 redes protegidas, incluindo os enlaces
   diretos de scan, SE e todas as redes de clock. Os 115 SDFFs e os
   cinco buffers de clock também foram protegidos durante essa etapa.
   O resultado intermediário reduziu as violações de capacitância
   para 12 por cenário. As mudanças de dados foram examinadas
   individualmente em `eco.tsv`.
5. O ECO pós-route trocou nove `SDFFX1_RVT` por `SDFFX2_RVT` nos
   drivers com violações residuais mais relevantes, incluindo
   `pixel_out_valid_reg`. As variantes têm a mesma interface
   D/CLK/SE/SI/Q/QN. O fluxo associou VDD/VSS, legalizou e executou
   `route_eco -reroute modified_nets_first_then_others`. Todos os
   enlaces de scan continuaram diretos. `pixel_out_valid_reg/Q`,
   antes em 0,1226 ns com limite de 0,0856 ns e 12,4778 fF com
   limite de 8 fF no funcional slow pós-`route_opt`, saiu do
   relatório de violações após o ECO.

Um ensaio de buffer na porta `pixel_out_valid` deixou a violação no
Q do SDFF. O ensaio inicial de `route_opt` com seleção `footprint`
emitiu ROPT-017, executou otimização mais ampla e mudou a conectividade
de dados na rede da saída de scan de um SDFF. A variante aceita protege
as ligações diretas da cadeia e concentra o ajuste de drive nos nove
SDFFs medidos. Os diagnósticos desses ensaios ficam em `trials/`.

O inventário final frente ao CTS registra 61 trocas de referência,
incluindo os nove SDFFs, 16 buffers não inversores adicionados e dois
removidos. O verificador compara as conexões funcionais após abstrair
somente os buffers não inversores reconhecidos e exige os mesmos
terminais lógicos e famílias de células. Também exige identidade
literal das conexões de clock e scan dos SDFFs, confrontadas com a
ordem M9. Essa verificação estrutural tem cobertura distinta de uma
prova formal.

## Verificações físicas

| Medida pós-route | Resultado observado |
|---|---:|
| Redes lógicas no DEF | 1.487 |
| Redes com fios roteados, incluindo seis de clock | 1.485 |
| Portas de sinal com rota necessária atendidas | 124 de 124 |
| Redes que exigem conexão e ficaram sem rota | 0 |
| Opens, shorts e DRC interno do roteador | 0 |
| Comprimento reportado de fios roteados | 27.304 µm |
| Vias reportadas nas rotas | 11.351 |
| Estimativa de overflow global | 0,72% (52 GRCs) |
| Células legalizadas | 1.275 |
| PG DRC, células flutuantes e pinos PG desconectados | 0 |
| Área de células | 3.881,2871 µm² (+2,46% contra CTS) |
| Utilização do core | 51,62% |

`in_sol` e `in_eol` mantêm pinos físicos no DEF e aparecem como redes de
um único terminal, sem cargas na netlist. Os checks detectaram zero
portas excluídas na verificação do roteamento. O DEF preservou os
contornos, 52 rows, trilhas, 126 shapes de sinal e a geometria de
VDD/VSS. O relatório interno não contabilizou violações em nenhuma
regra ou camada. O roteador indicou a ausência de regras de antena e
não verificou as regras de tie-to-rail nesse comando.

As rotas de sinais ocupam M1–M7. Na árvore final, o acesso aos pinos
usa M1/M2 e a distribuição usa a faixa M3–M6 configurada no CTS.
O DEF contém 409 vias únicas nas seis redes de clock, incluindo
125 VIA12, 127 VIA23, 148 VIA34, 7 VIA45 e 2 VIA56. A continuidade
das seis redes e o PG DRC foram verificados novamente após as
intervenções. O relatório `clock_qor.rpt` mediu 748,074 µm na árvore.

## Extração e timing pós-route

O FC extraiu RC das rotas detalhadas e escreveu quatro SPEFs, Cmin e
Cmax em `ss0p95v125c` e `ff0p95vn40c`. Cada SPEF contém 1.485
registros de rede marcados `DR` e árvores de resistência e capacitância.
Por exemplo, a capacitância extraída de `clk` no corner slow foi
3,1156 fF com Cmin e 3,6708 fF com Cmax. A atribuição observada foi
Cmin para early e Cmax para late em ambos os corners. O escritor
registrou a conversão da unidade da resistência para ohms.

A referência de mapeamento herdada mantém `DIFF`, uma camada ativa
que está fora das categorias aceitas nesse mapa, conforme a ajuda
nativa de TLUP-012. Os dois avisos foram emitidos no carregamento
original, registrado na [evidência de floorplan](M10_floorplan_inicial.md). Não houve recarga
ou edição do mapa no routing. Os SPEFs foram produzidos com RC
não nulo das rotas de metal e vias e sem indicação de nets
detalhadas não extraídas. O aviso demonstrou ser não impeditivo
para a extração de interconexão executada. A calibração da tecnologia
e a correlação independente seguem fora da validação.

| Cenário | Pior setup (ns) | Pior hold (ns) | TNS setup/hold (ns) | Endpoints setup/hold violados | Skew global (ps) |
|---|---:|---:|---:|---:|---:|
| Funcional slow | +1,8649 | +0,1861 | 0/0 | 0/0 | 20,6 |
| Funcional fast | +5,3615 | +0,0639 | 0/0 | 0/0 | 10,9 |
| Shift slow | +99,6606 | +0,2119 | 0/0 | 0/0 | 20,6 |
| Shift fast | +99,8550 | +0,0827 | 0/0 | 0/0 | 10,9 |
| Captura estática slow | +94,4063 | +0,2761 | 0/0 | 0/0 | 20,6 |
| Captura estática fast | +97,7191 | +0,1136 | 0/0 | 0/0 | 10,9 |

Com clocks propagados e RC pós-route, a latência nos sinks foi
39,4–50,3 ps em fast e 84,4–105,0 ps em slow, nos três modos.
A maior transição de sink reportada foi 20,9 ps em fast e 41,4 ps
em slow. O resumo da árvore indicou zero DRVs de transição e
capacitância. O hold funcional fast caiu 0,5 ps frente ao CTS e
o hold de shift fast caiu 1,1 ps.

Em cada cenário permaneceram **2 violações de transição e 4 de
capacitância** em redes de dados. No funcional slow, os maiores
excedentes foram 0,0007 ns e 0,1872 fF, ambos no driver de
`u_resize_nn_core/ropt_net_18`. As demais violações de capacitância
incluem `ropt_net_9`, `roi_height[9]` e `pixel_out[7]`. O
`report_constraints` da versão apresenta transição e capacitância,
sem check de limite máximo de fanout. A ajuda de `set_max_fanout`
registra o comando como indisponível. Foram medidos os fanouts de
`clk` na raiz (1), `reset_n` (4) e `scan_enable` (115).
Os limites existentes foram mantidos.

O `check_timing` detalhado registrou zero registradores sem clock
nos seis cenários. Por corner, o modo funcional listou 231
endpoints sem restrição, incluindo os 115 SI desabilitados,
os 115 SE constantes e `scan_out`. Os modos shift e captura
estática registraram 246 endpoints sem restrição por cenário,
incluindo checks inativos e saídas de teste sem budget. O shift
também reconheceu `scan_in` sem atraso de entrada. O modo de
captura estática registrou 105 entradas sem atraso. O funcional
mantém 10 ns e o shift, 100 ns, com bordas 45/55 ns. A captura
estática a 100 ns tem SE=0 e reset inativo. Os valores dos caminhos
cobertos têm escopo diagnóstico. Faltam parâmetros externos de
I/O e de captura at-speed.

## Scan, VCS e SDF

O Scan DEF, a netlist e o check nativo conferiram uma cadeia com
115 elementos, 106 `SDFFX1_RVT` e nove `SDFFX2_RVT`, sem exclusões.
O verificador confirmou os 114 enlaces internos, a ordem M9,
`scan_in`, `scan_out`, os 115 pinos SE e o mesmo caminho de clock
até cada CLK. O VCS X-2025.06-SP2 passou 15/15 cenários funcionais,
2.618 ciclos e zero divergências no scoreboard. O teste de shift
verificou 460 pulsos com a ordem original. Os dois testes usaram
a netlist pós-route e o modelo RVT com checks temporais desligados.

O FC também escreveu quatro SDFs, dois corners nos modos funcional
e shift. Um teste estático separado no VCS anotou o SDF funcional
slow original e encontrou 372 erros de porta, por seletores de
barramento escapados em `INTERCONNECT`, e 7 avisos de anotação de
interconexão entre níveis. Em cópia com os seletores normalizados,
houve zero erros e 15 avisos de interconexão ascendente ignorada
(`SDFCOM_UHICD`). A anotação temporal completa requer resolver ou
validar essa semântica antes de uma regressão dinâmica. Os resultados
funcionais e de shift acima são gate-level, e ATPG e equivalência
formal ficam pendentes.

## Handoff, reprodução e limites

Depois dos checks e do VCS, o fluxo promoveu `routing_initial` e o
reabriu em novo processo. A geometria de rotas, Scan DEF, netlist,
PG e legalidade conferiram. A execução local tem DEF, Scan DEF
separado, netlist, quatro SPEFs, quatro SDFs, relatórios e SVGs
`clock_layout.svg` e `signals_layout.svg`, desenhados com os
segmentos exportados. Bancos físicos e artefatos derivados ficam
em `outputs/physical/runs/`, ignorado pelo Git.

Com FC e VCS no PATH, a referência NDM acessível pelo checkpoint e
`SAED32_REF_ROOT` apontando para a referência Verilog:

```bash
./scripts/physical/run_routing.sh \
  outputs/physical/runs/20261124T185502Z-cts-EVbYma \
  outputs/dft/runs/20261120T142703Z-insertion-jTvumJ/post/actual_chain.tsv
```

Use `scripts/physical/probe_routing_sdf.sh` com a pasta gerada e
`signals/reports/functional.ss0p95v125c.sdf` dessa execução. A opção
`--normalize-bus` preserva o arquivo original e grava a variante
diagnóstica. O wrapper de routing aceita `FC_SHELL` e
`M10_TIMEOUT_SECONDS` e registra `ROUTING_VALIDATED` e
`PROTECTED_INPUTS_MATCH` no handoff aceito.

O candidato atende ao escopo exploratório. Para concluir o M10,
restam DRVs e cobertura MMMC de teste, verificação independente de
extração/STA e DRC/LVS, antena, política de taps e endcaps,
prevenção de latch-up e avaliação IR/EM. A revisão física deve
considerar esses limites junto com os resultados pós-route.
