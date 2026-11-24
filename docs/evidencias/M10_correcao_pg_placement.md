# KUIDAMOS 6C — correção dos rails M1 e validação do placement

Execução em 2026-11-24 no Fusion Compiler `X-2025.06-SP2`.
**O candidato geométrico de placement passou.** Em cópia de
`powerplan_initial`, os 53 rails contínuos M1 foram ajustados de
0,152 para 0,060 µm. A nova execução confirmou **zero violações de
PG DRC**, zero violações de legalidade e contato físico VDD/VSS nas
1.256 células. `powerplan_corrected` e `placement_initial` foram
salvos e reabertos em outra sessão.

## Causa raiz

A colocação aproximou o metal dos frames de célula dos rails de
0,152 µm. Esses rails estavam centrados corretamente nas fronteiras
das rows, mas sua meia-largura de 0,076 µm avançava sobre o espaço
lateral reservado aos shapes das células. O relatório colocado
`20261124T183431Z-placement-EGZHsv` registrou:

| Geometria PG no marcador | Regra M1 | Mínimo exigido | Menor folga medida | Ocorrências |
|---|---|---:|---:|---:|
| Rail contínuo | `Min-Spacing-On-Layer` | 0,050 µm | 0,012 µm | 4.274 |
| Rail contínuo | `Fat-Metal-Spacing-Table-Rule` | 0,060 µm | 0,012 µm | 1.125 |
| Retângulo PG local junto ao rail | `Min-Spacing-On-Layer` | 0,050 µm | 0,012 µm | 493 |

Dos 5.892 marcadores, 5.890 foram classificados pelo FC como
espaçamento entre shapes de redes distintas. Os rótulos do relatório
são sinal conhecido em 2.588 casos e `unknown` em 3.302. O rótulo
`unknown` indica metal do frame sem identificação de rede no marcador.
Esse grupo pode conter geometria interna ou obstruções sem nome.
Dois casos foram VSS contra VSS na vizinhança de um `XOR2X1_RVT`.
O relatório aponta espaçamento e não contém marcadores de curto.

- **Rail VDD × pino CLK.** O marcador sobre `out_sof_reg`
  (`SDFFX1_RVT`, orientação `MX`) mediu 0,020 µm para uma exigência
  de 0,060 µm. A consulta do frame confirmou o retângulo M1 associado
  a `out_sof_reg/CLK` no lado voltado para o rail. No mesmo flip-flop,
  outro marcador tem a mesma distância para metal sem rede identificada.
- **Rail × sinal de lógica.** O marcador em
  `u_resize_nn_core/U157` (`OAI22X1_RVT`, `MX`) mediu 0,020 µm
  onde eram exigidos 0,050 µm, entre VDD e metal de `roi_v[2]`.
- **Os 493 retângulos locais.** Todos os retângulos PG desse grupo
  têm 0,050 µm de largura, cruzam um rail da mesma rede e compartilham
  uma aresta Y com ele. Foram 265 ocorrências contra metal `unknown`
  e 228 contra sinais nomeados. Em um par de rows adjacentes, o
  marcador mediu 0,019 µm entre PG VSS local e metal sem nome do
  `OA22X1_RVT` em R0. A caixa de PG local é consistente com o
  metal de pino recortado na região de junção com o rail pelo
  verificador. Nenhum desses retângulos coincidiu com um landing
  M1 das vias existentes. O ensaio de largura isolado eliminou
  também esse grupo, com todas as vias mantidas.

As 52 rows alternam `R0/MX` e compartilham rails nas fronteiras.
Entre as 5.399 ocorrências em 52 rails, as células vizinhas estavam
em `MX` em 2.840 casos e `R0` em 2.559. A ocorrência em ambos os
sentidos e o DRC limpo com os eixos mantidos descartam troca de
polaridade por espelhamento como causa principal. O frame mostra
pinos PG compatíveis com a fronteira e metal M1 próximo aos rails.
A geometria instalada continua insuficiente para concluir a política
de well taps e latch-up.

## Alternativas verificadas e correção

A ajuda nativa de `create_pg_std_cell_conn_pattern` documenta largura
baseada nos pinos, alinhamento padrão com os pinos e
`-check_std_cell_drc true` para considerar células posicionadas na
construção. `-mark_as_follow_pin true` preserva a função do rail.
A geração inicial da malha foi feita antes do placement.
O ensaio reprodutível manteve o tipo `follow_pin` e alterou somente
`width` nos paths M1 já existentes.

| Teste | Resultado colocado |
|---|---|
| Origem com 0,152 µm e as vias originais | 5.892 erros M1, conectividade PG contínua. |
| Somente a largura dos 53 paths passou a 0,060 µm | Zero erros e continuidade para todos os pinos PG. |
| Em seguida, na cópia de ensaio, troca das 1.590 vias de pilha de rail por geração com master M1/M2 unitário | O FC rejeitou a geração com `PGR-051` e 318 vias phantom. Os 53 rails ficaram flutuantes. Variante descartada. |

A largura de 0,060 µm coincide com a usada pelo padrão de rail sem
largura explícita nos primeiros ensaios de PG e supera o mínimo M1 de
0,050 µm. O recuo de 0,046 µm por lado recupera o espaçamento lateral.
As 318 caixas inferiores M1/M2 da rede de origem também medem
0,060 µm na direção transversal ao rail. Na solução final, as **1.766
vias**, os dois anéis M7/M8, as 24 straps M5/M6 e os quatro terminais
PG mantiveram geometria e posição. O DEF confirma alteração somente
no campo de largura dos 53 rails em `SPECIALNETS`. O PG DRC final
incluiu os shapes das células no placement e os nets de clock na
verificação. Nenhuma regra de DRC foi desabilitada para obter o resultado.

## Validação dos checkpoints

- `powerplan_corrected` reabriu com **1.256 células não posicionadas**.
  Duas redes PG contínuas, sem elementos flutuantes e com PG DRC limpo.
- `placement_initial` reabriu com **1.256 células posicionadas e
  legalizadas**, sem sobreposições e com as mesmas **52 site rows**.
  `check_pg_connectivity -check_std_cell_pins all` confirmou
  zero pinos PG desconectados e uma rede contínua por rail. PG DRC
  registrou **zero erros** no build e no readback.
- O Scan DEF está idêntico ao do power plan de origem. O FC validou
  uma cadeia com **115 SDFFs**, sem falhas. A netlist funcional do
  placement e dos dois readbacks coincide com a base M9. O DEF de
  sinais não contém roteamento.
- A utilização de **49,9662%** e a densidade máxima de **73,638%**
  mantiveram-se. Foram ocupadas 50 rows. O overflow global estimado
  ficou em **35 GRCs (0,49%)**, ante 34 (0,47%).
- As 126 portas mantiveram borda e camada previstas. Os recursos PG
  em M3/M4 nas faixas de acesso são os mesmos do power plan.
  O DEF ainda mostra zero shapes de sinal no contorno. O acesso real
  depende da colocação de pinos. O check nativo de pinos ausentes
  listou 123 portas sem shape, e o inventário DEF inclui também as
  três portas de scan sem shape.
- Os manifestos antes/depois conferiram para 4.301 arquivos
  protegidos. As bibliotecas, bancos, DEFs, SVGs e logs permanecem locais.

## Comparação STA dos caminhos cobertos

Mesmos seis cenários, clocks ideais e RC estimado. Nenhum delay
ou exceção de teste foi acrescentado.

| Cenário | Setup anterior → atual (ns) | Hold anterior → atual (ns) | Max transition atual | Max capacitance atual |
|---|---:|---:|---:|---:|
| Funcional slow | +1,4430 → +1,4464 | +0,2428 → +0,2428 | 11 | 66 |
| Funcional fast | +5,1454 → +5,1467 | +0,0776 → +0,0776 | 4 | 68 |
| Shift slow | +99,6367 → +99,6370 | +0,2173 → +0,2174 | 12 | 66 |
| Shift fast | +99,8378 → +99,8380 | +0,0848 → +0,0848 | 4 | 68 |
| Captura estática slow | +94,8409 → +94,8424 | +0,2768 → +0,2768 | 12 | 66 |
| Captura estática fast | +97,8783 → +97,8789 | +0,1101 → +0,1101 | 4 | 68 |

O TNS permanece em 0 e o FC não reportou caminhos violados nos
relatórios globais. As contagens de transição e capacitância
permaneceram iguais. O hold funcional fast ainda tem margem
reduzida de 0,0776 ns. A cobertura de shift e captura segue parcial,
com I/O de teste, sequência temporal de captura e incertezas por
definir. Os resultados não constituem signoff.

## Reprodução e próxima etapa

```bash
python3 scripts/physical/analyze_m1_spacing.py \
  outputs/physical/runs/20261124T183431Z-placement-EGZHsv/reports \
  outputs/physical/runs/20261124T181500Z-powerplan-lugkw9/readback/wires.tsv

./scripts/physical/run_placement.sh \
  outputs/physical/runs/20261124T181500Z-powerplan-lugkw9 \
  outputs/dft/runs/20261120T142703Z-insertion-jTvumJ/post/scan_protocol.spf \
  --correct-m1
```

Execução validada em
`outputs/physical/runs/20261124T184151Z-placement-VPBjaK/`.
`reports/placement.def`, `readback/*/design.def`,
`placement.svg`, `powerplan_corrected.svg` e `validation.txt`
registram a geometria verificada. O primeiro teste controlado,
incluindo a variante descartada de vias, está em
`outputs/physical/runs/20261124T183747Z-pg-correction-probe-9KjUfU/`.
Uma primeira tentativa de salvamento fez `save_lib` gravar
também o bloco PG aberto durante placement. A solução cria um
bloco de trabalho separado com `copy_block` antes de posicionar
e verifica que o checkpoint PG reabre sem células posicionadas.

O candidato libera **a preparação de CTS exploratório**. Resolver
acesso físico de `clk` e demais pinos, revisar as violações de
transição/capacitância e completar os cenários de teste antes
de aceitar resultados de CTS. Permanecem pendentes a política
de taps/endcaps, a validação de latch-up, signoff físico, IR/EM
e timing com clocks propagados e parasitas extraídos.
