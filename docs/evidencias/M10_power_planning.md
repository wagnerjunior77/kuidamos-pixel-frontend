# KUIDAMOS 6C — power planning inicial

Execução de 2026-11-24 com Fusion Compiler `X-2025.06-SP2`.
O bloco `kuidamos_preview.dlib:powerplan_initial.design` foi salvo em
uma cópia de `floorplan_initial` e verificado em outra sessão do FC.
`check_pg_connectivity` confirmou uma rede física contínua por rail.
`check_pg_drc` registrou zero erros de PG no escopo pré-placement.

## Tecnologia e decisões de geometria

O checkpoint de entrada usa SAED32 RVT e `ss0p95v125c`. O FC confirmou
pitch, largura mínima e espaçamento mínimo das camadas selecionadas,
além das sete definições SAED32 com cortes VIA1–VIA7. Os valores
escolhidos são exploratórios para este bloco. Dimensionamento de
corrente, queda IR e electromigration permanecem pendentes.

| Estrutura | Direção e camada | Largura (µm) | Separação de arestas (µm) | Pitch ou offset (µm) |
|---|---|---:|---:|---|
| Anéis | Horizontal M7, vertical M8 | 0,608 | 0,608 | Offset 1,216 a partir do core |
| Mesh horizontal | M5 | 0,304 | 0,304 | Pitch de pares 13,376, offset 7,296 |
| Mesh vertical | M6 | 0,304 | 0,304 | Pitch de pares 14,592, offset 6,080 |
| Rails | M1 horizontal, `follow_pin` | 0,152 | 1,520 | Um rail por limite de row, passo 1,672 |

Os anéis usam meia trilha de largura e meia de espaçamento em
M7/M8, cujo pitch é 1,216 µm. Os conjuntos VDD/VSS ocupam a
margem exploratória de 6,688 µm. O metal mais externo fica a
3,648 µm da borda do die. As straps M5/M6 usam meia trilha de
largura e meia de espaçamento, com pitch tecnológico de 0,608 µm.
Em M5, o pitch de pares é múltiplo de 0,608 e de 1,672 µm.
O offset e a separação evitam alinhar uma strap sobre a projeção
do rail M1 de outra rede nos pontos de transição. Em M6, o pitch
de 24 trilhas distribui seis pares dentro do core.

O fluxo aplicou `connect_pg_net -automatic -pg` e verificou a
associação lógica dos **1.256 pinos VDD e 1.256 pinos VSS** às
redes da polaridade correspondente. `compile_pg` construiu
anéis, mesh, rails e as conexões superiores, com as verificações
de DRC habilitadas. A ligação dos rails com as straps M6 foi
realizada depois por `create_pg_vias`, com masters SAED32
`VIA12SQ_C` a `VIA56SQ_C`. O FC verificou DRC durante a geração
e registrou zero vias phantom na receita final. M2/M3/M4 têm
landings locais das pilhas de vias entre M1 e M6.

O ensaio inicial mostrou 53 rails flutuantes, embora o PG DRC
estivesse limpo. Um ensaio intermediário com a criação explícita
de vias deixou dois rails isolados. A receita final ajustou a
fase das straps M5 em relação às rows e separou a criação das
pilhas M1–M6 do `compile_pg`. Os ensaios permaneceram em cópias
separadas.

## Validação

| Rede | Anéis (segmentos) | Straps (M5 + M6) | Rails M1 | Vias físicas | Terminais M7 |
|---|---:|---:|---:|---:|---:|
| VDD | 1 (4) | 12 (6 + 6) | 27 | 898 | 2 |
| VSS | 1 (4) | 12 (6 + 6) | 26 | 868 | 2 |
| **Total** | **2 (8)** | **24** | **53** | **1.766** | **4** |

As vias são contadas como objetos da base, incluindo os níveis das
pilhas. Cada rede tem um terminal M7 sobre o anel superior e um
sobre o inferior. Cada terminal cobre 2,432 × 0,608 µm de metal.
Esses pontos são acessos PG para a integração do bloco. A ligação
à alimentação do nível superior permanece pendente.

- **Continuidade:** uma componente conectada por rede, sem wires,
  vias ou terminais flutuantes, confirmada no build e no readback.
  As 1.256 standard cells continuam `UNPLACED`. A verificação de
  geometria e continuidade excluiu os pinos físicos dessas células.
  As ligações lógicas conferem. O contato físico pin–rail será
  verificado após placement.
- **PG DRC:** `No errors found` no build e readback. O check examina
  as duas redes e seus terminais para violações de tecnologia e
  sobreposição ilegal. Nenhum curto VDD/VSS foi reportado. O escopo
  é o PG desta base pré-placement.
- **Acesso de sinais:** as restrições das 126 portas permaneceram
  idênticas. Os anéis ocupam a margem em M7/M8 e as portas têm
  M3/M4 reservadas. Não há straps PG nessas camadas. Os landings
  M3/M4 ficaram na zona interna, inclusive sobre os rails externos
  no limite do core. Não foi detectada invasão da faixa periférica
  de acesso nas camadas planejadas. O acesso real e a congestionabilidade
  deverão ser medidos após criar shapes de sinal.
- **Preservação:** die, core, 52 rows, tracks e 1.256 componentes
  conferem com o DEF do floorplan. A área lógica de 3.757,2649 µm²
  e a utilização calculada de 49,9662% mantiveram-se. Os rails
  representam 696,7473 µm² de metal M1, sem redução da área geométrica
  das rows. O impacto em recursos de roteamento será medido após placement.
  O corpo da netlist funcional coincide com a base M9 reexportada
  no floorplan. O Scan DEF conservou a ordem e o FC validou uma cadeia
  de 115 SDFFs com zero falhas. Os manifestos SHA-256 antes/depois
  conferiram em 2.490 arquivos protegidos.
- **Condições herdadas:** os dois TLUP-012 de `DIFF` e o DPCHK-008
  do floorplan permanecem documentados. O PG reutilizou a base com
  o mesmo RC e não recarregou o mapa TLU+ nem repetiu o check de
  grade FinFET. Os resultados reais de DRC e conectividade PG foram
  obtidos nesta etapa. [Evidência do floorplan](M10_floorplan_inicial.md)

## Pendências antes de placement

A NDM oferece `DCAP_RVT`, fillers e ties. A busca do floorplan não
encontrou referência marcada como `is_tap_cell`. Isso não bloqueou
a rede PG inicial. Antes de inserir células físicas, confirmar com
as regras SAED32 se são necessários taps dedicados e definir endcaps,
fillers e ties conforme a etapa. Nenhuma célula física dessa classe
foi inserida no power plan.

O cenário funcional mantém clock de 10 ns e o RC de
`ss0p95v125c`. Para STA de teste, a referência de shift é o SPF,
com 100 ns, bordas 45/55 ns, `scan_enable=1` e `reset_n=1`.
O cenário de captura deve representar a sequência escolhida de
launch/capture e a transição de `scan_enable` para seleção funcional
durante a captura, com reset inativo. Ainda é preciso definir
orçamentos de entrada e saída de scan, cargas, incertezas, frequência
e forma de onda de captura, corners min/max e hipóteses de controle
do testador. Não foram aplicados delays ou exceções de teste nesta
etapa. Timing pós-route, potência, IR drop e electromigration
permanecem pendentes.

A rede PG passa no escopo pré-placement e pode ser usada como base
da próxima etapa. Completar a política de células físicas e os
cenários MMMC de teste antes de aceitar placement. Após a legalização,
repetir PG DRC e checar a conexão física de cada pino de alimentação.
Preservar a ordem scan na primeira passagem.

## Reprodução e saídas locais

```bash
./scripts/physical/run_powerplan.sh outputs/physical/runs/20261124T180302Z-floorplan-n4qeIQ
```

Execução validada em
`outputs/physical/runs/20261124T181500Z-powerplan-lugkw9/`.
`build/` contém a ajuda capturada, `powerplan.def`, relatórios de
DRC/conectividade e inventários `wires.tsv`, `vias.tsv` e
`terminals.tsv`. `readback/` confirma a persistência da geometria,
RC e PG. `powerplan.svg` foi desenhado a partir das caixas medidas
pelo FC. `validation.txt` registra `POWERPLAN_VALIDATED`.
Esses artefatos permanecem locais. A execução não acionou placement,
CTS, signal routing, otimização lógica ou reordenação de scan.
