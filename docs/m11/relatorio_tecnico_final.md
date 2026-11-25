# KUIDAMOS 6C — relatório técnico do front-end de pixels

**Versão 0.1 para revisão humana · 25/11/2026**

Wagner Cutrim Rabelo Junior — DFT · Thiago Fernandes Carvalho de Souza — RTL e síntese

O baseline de M0–M10 é o merge `3fb7875` da `main`. Esta versão
consolida as evidências desse baseline e o experimento complementar
do M11. [Escopo oficial do Grupo 6C](../referencias/definicao_escopo_grupo_6_oficial.pdf) · [Matriz de rastreabilidade](matriz_rastreabilidade.md)

## 1. Introdução e objetivos

O projeto KUIDAMOS–CIExpert avalia o desenvolvimento de IPs digitais
em um fluxo acadêmico de EDA. O Grupo 6C entrega um front-end que
recebe pixels RGB já decodificados e produz um fluxo de luminância
ou pixels binários. A transformação é adequada ao processamento em
raster, com controle explícito de quadros, linhas e validade.

O objetivo foi especificar, implementar e verificar o IP, sintetizá-lo,
inserir e validar scan e executar a implementação física até routing
com os recursos do CIExpert. O ponto de análise temporal adotado foi
100 MHz. Aquisição de vídeo, decodificação e inferência pertencem a
outros componentes do sistema. [Contexto do Grupo 6C](../CONTEXTO_TECNICO_6C.md)

## 2. Especificação do IP

A interface síncrona aceita um pixel RGB888 por borda válida de
`clk`. Bolhas congelam as coordenadas. A fonte fornece o quadro em
ordem raster e o destino aceita toda saída válida. O reset é
síncrono e ativo baixo. Um pixel selecionado na borda `n` aparece
registrado após essa borda e pode ser consumido em `n+1`. Assim,
a transferência borda a borda tem latência de um ciclo.

| Grupo de sinais | Contrato V1 |
|---|---|
| Entrada de dados e sincronismo | Três canais de 8 bits, `pixel_valid`, SOF, SOL, EOL e EOF |
| Configuração | Capturada no SOF válido. Dimensões de 1 a 2.047 por eixo, ROI, fatores de resize, habilitação e limiar de 8 bits |
| Saída | Pixel de 8 bits, `pixel_out_valid`, quatro marcadores regenerados e `cfg_error` |
| Configuração inválida | Pulso `cfg_error` e descarte do quadro. Um novo SOF válido permite recuperação |

O grayscale usa `floor((77R+150G+29B)/256)`. O crop mantém
coordenadas dentro da ROI com limites superiores exclusivos.
O resize aplica o mapeamento nearest-neighbor após o crop. A V1
deriva as dimensões por piso e aceita fatores 1 e 2 independentes
em X e Y. O threshold habilitado emite 255 quando `Y >= T` e
zero abaixo do limiar. Em bypass, preserva a luminância. O recorte
de resize foi aprovado internamente e aguarda confirmação do
professor. [Contrato completo da V1](../spec_v1.md)

## 3. Arquitetura e microarquitetura

```mermaid
flowchart LR
    RGB["RGB888 e valid"] --> G["Grayscale inteiro"]
    G --> C["Crop retangular"]
    C --> R["Resize nearest-neighbor"]
    R --> T["Threshold e bypass"]
    T --> O["Registradores de saída"]
    CFG["Configuração capturada no SOF"] --> CTRL["Controle de quadro e coordenadas"]
    CTRL --> C
    CTRL --> R
    CTRL --> T
    R --> F["Regeneração SOF SOL EOL EOF"]
    F --> O
    O --> OUT["Pixel de 8 bits e marcadores"]
```

Os núcleos de transformação são combinacionais. Os registradores
armazenam estado de quadro, contadores, parâmetros de configuração e
saída. A soma de luminância usa 16 bits, com máximo de 65.280 antes do
deslocamento. Coordenadas e dimensões usam 11 bits, enquanto limites
e comparações ampliados usam 12 bits. O resize de fator dois verifica
paridade e o limite de amostras exigido pelo piso. Os marcadores
decorrem das coordenadas de saída, inclusive quando o primeiro ou
último pixel da entrada é descartado. O datapath opera em streaming
sem armazenar linhas ou quadros. [Arquitetura no repositório](../../rtl/README.md)

## 4. Modelo de referência

O Golden Model usa Python/NumPy para calcular cada estágio de forma
independente do RTL. O nearest-neighbor usa os índices da equação
geral do PDF, calculados sobre a ROI. O gerador temporal M2 usa o
resultado por quadro para associar valores e flags aos ciclos, com
reset, descarte, bolhas e consumo no ciclo seguinte. Foram registrados
32 testes Python aprovados após o experimento M1 e 28 arquivos M2
conferidos byte a byte.

![Saída do exemplo sintético de threshold do Golden Model](../imagens/m1/05_threshold.png)

*Figura 1 — Saída do exemplo sintético já documentado no M1. A
montagem com fotografia e saída capturada do RTL tem rastreabilidade
própria no capítulo 6.*
[Modelo e figuras M1](../evidencias/M1_modelo_python.md) · [Vetores M2](../evidencias/M2_vetores.md)

## 5. Implementação RTL

| Módulo SystemVerilog | Implementação |
|---|---|
| `grayscale_core` | Soma ponderada RGB e redução para 8 bits |
| `crop_core` | Comparadores de ROI e coordenadas relativas |
| `resize_nn_core` | Seleção de amostras nos eixos e coordenadas da saída |
| `threshold_core` | Comparador sem sinal, saída binária e bypass |
| `kuidamos_pixel_frontend` | Captura e validação da configuração, controle de reset e quadro e registro de pixel, validade, flags e erro |

A captura no SOF permite alterações externas na configuração durante
o restante do quadro sem afetar seus pixels. O topo usa `in_sof`
e as dimensões capturadas para delimitar a progressão raster.
`in_sol` e `in_eol` permanecem na interface sem cargas internas.
A saída preserva a ordem dos pixels selecionados e o protocolo
define a recuperação no próximo SOF válido.
[RTL e arquivos de compilação](../../rtl/README.md) · [Temporização da interface](../spec_v1.md#5-contrato-temporal-e-recuperação)

## 6. Verificação funcional

A regressão oficial no VCS executou nove casos produzidos pelo
gerador M2 e seis casos dirigidos M7, com **15/15 aprovados em
2.618 ciclos**. O scoreboard comparou valores, quantidade,
ordem, marcadores e sinais inválidos. O monitor executou oito
propriedades concorrentes e verificações procedurais. Foram registradas
2.617 checagens pós-borda e zero divergências ou erros SVA.
Os testes negativos de scoreboard e assertion também foram
exercitados no M7. [Relatório VCS M3–M7](../evidencias/M3_M7_verificacao_vcs.md)

No complemento M11, uma fotografia já usada pelo Golden Model foi
preparada externamente para **144 × 256** pixels. O fluxo usou
grayscale, ROI de 107 × 191 em (18, 32), resize (2, 2) e threshold
128. O RTL e a netlist `physical_final` emitiram **5.035 pixels**
em um quadro de **53 × 95**, sem divergências de valor, ordem ou
marcador em 36.872 ciclos por execução. O monitor RTL registrou
36.871 checagens pós-borda sem erro. A netlist foi exercitada no
modo funcional com o scoreboard. A validação temporal com SDF
continua pendente.

A reconstrução usou os pixels efetivamente amostrados do DUT.
O comparativo tem quatro painéis com RGB de entrada, referência,
resultado do DUT e diferenças. O mapa ficou integralmente preto,
indicando zero diferenças, e o PNG reconstruído foi idêntico
ao esperado. A montagem fotográfica permanece no handoff local.
[Evidência, hashes e reprodução M11](../evidencias/M11_imagem_real_vcs.md)

## 7. Síntese lógica

O Design Compiler X-2025.06-SP2 mapeou o RTL para SAED32 RVT no
corner `ss0p95v125c`, a 0,95 V e 125 °C, com SDC de 10 ns.
O resultado teve 1.256 células folha, incluindo 115 flip-flops e
zero latches. Foram exportados netlist e SDC para o DFT, além de
DDC, SDF e outros relatórios. O setup de +3,21 ns e o hold de
+0,16 ns usam o modelo de carga de fios da síntese.
[Relatório M8](../evidencias/M8_sintese_dc.md)

## 8. DFT e scan insertion

O fluxo importou a netlist e o SDC de M8 no Fusion Compiler. Foram
feitos pré-DFT DRC, precheck, replacement, preview e inserção com o
motor de DRC TestMAX integrado. O caminho funcional foi preservado
e o protocolo de teste define `clk` a 100 ns, com bordas em 45 ns
e 55 ns e reset síncrono inativo.

```mermaid
flowchart LR
    SI["scan_in"] --> S["115 SDFFs em uma cadeia"]
    S --> SO["scan_out"]
    SE["scan_enable"] --> S
    CK["clk comum"] --> S
```

O M9 conectou 114 enlaces internos, sem compressão e sem exclusões.
O DFT DRC indicou zero violações no resumo e 91 avisos detalhados.
O N20 aponta uma condição de SE desconhecido no modelo usado pelo
checker. O funcional VCS passou **15/15 cenários** e o teste de shift
conferiu **460 pulsos**. O M10 preservou a ordem e os enlaces, mesmo
após dez células passarem à variante X2. [Resultado e avisos M9](../evidencias/M9_resultado_final.md) · [Revalidação M10](../evidencias/M10_resultado_final.md)

## 9. Implementação física

| Etapa | Resultado observado |
|---|---|
| Floorplan | 52 rows `unit` e utilização nominal inicial próxima de 50% |
| Power planning e placement | Anéis M7/M8, malha M5/M6 e rails M1. A correção M1 de 0,152 para 0,060 µm removeu violações de espaçamento com células colocadas |
| Pinos e CTS | 126 portas em M3/M4. Cinco buffers alcançaram os 115 sinks nas seis redes de clock |
| Routing e ECO | Clock físico, roteamento de sinais, extração Cmin/Cmax, proteção da cadeia e fechamento dos DRVs |
| Readback | `physical_final` salvo e reaberto. Netlist, geometria, PG e cadeia conferiram. VCS 15/15 e shift 460 foram reexecutados na netlist final |

Foram legalizadas **1.276 células**, com **1.486 redes necessárias
roteadas**. As duas entradas sem carga ficaram sem rota. Os checks
registraram zero opens, shorts, DRC interno, PG DRC, pinos PG
desconectados e violações de transição ou capacitância. Os exports
locais incluem DEF, Scan DEF, netlist, SPEF, SDF, SAIF e SVGs.
[Floorplan](../evidencias/M10_floorplan_inicial.md) · [Correção do PG](../evidencias/M10_correcao_pg_placement.md) · [Resultado final M10](../evidencias/M10_resultado_final.md)

## 10. Resultados de área, timing e potência

A comparação usa a **área de células**, sem a área de interconexão
estimada pelo DC. No M10, o core de 86,488 × 86,944 µm tem
**7.519,612672 µm²**, e o die de 99,864 × 100,320 µm tem
**10.018,356480 µm²**. A área de células divide-se pela área do core
para obter a utilização de **51,59%**.

| Marco | Células | Área de células (µm²) | Contexto |
|---|---:|---:|---|
| M8 | 1.256 | 3.523,4524 | Síntese lógica SAED32 RVT |
| M9 | 1.256 | 3.757,2649 | Pós-scan, área lógica |
| M10 | 1.276 | 3.878,9998 | Implementação física após ECO |

| STA do M10 | Pior setup (ns) | Pior hold (ns) |
|---|---:|---:|
| Funcional slow | +1,8647 | +0,1861 |
| Funcional fast | +5,3614 | +0,0639 |
| Shift slow | +99,6606 | +0,2119 |
| Shift fast | +99,8550 | +0,0827 |
| Captura estática slow | +94,4061 | +0,2761 |
| Captura estática fast | +97,7190 | +0,1136 |

O TNS foi zero nos caminhos cobertos. O clock propagado usou
10 ns no funcional e 100 ns nos modos de teste. No físico,
o skew global foi de 10,9 ps em fast e 20,6 ps em slow. A
referência de 100 MHz tem suporte nos relatórios desse cenário e
nas condições de análise registradas.

| Estimativa de potência M10 | µW |
|---|---:|
| Interna | 138,3041 |
| Switching | 30,3132 |
| Dinâmica total | 168,6173 |
| Leakage | 189,7378 |
| Total | **358,3551** |

A potência pós-route corresponde a SAED32 RVT slow, 0,95 V,
125 °C e 100 MHz, usando RC extraído e SAIF dos 15 cenários
funcionais do VCS. A atividade simulada alcançou **99,40% dos
drivers**. M8 registrou 267,27 µW com atividade propagada pelo
DC e carga de fios estimada. Atividade, modelo de interconexão
e netlist variam entre os dois ensaios. A diferença entre os totais
não isola o efeito da implementação física.
[Estimativa de M8](../evidencias/M8_sintese_dc.md) · [RC, STA e potência de M10](../evidencias/M10_resultado_final.md)

## 11. Manual de reprodução

O [manual consolidado](manual_reproducao.md) lista dependências,
versões, comandos e critérios de M1 a M10, e o caso complementar
M11. Em uma instalação com acesso ao CIExpert, a sequência de
checkpoint parte do `scan_inserted`, passa pelo floorplan, PG,
placement, CTS e routing e chega ao `physical_final`. Cada estágio
usa sua própria pasta de trabalho. Os diretórios e manifests dos
handoffs permitem relacionar relatórios, netlists e exports
à versão usada no ensaio. A reprodução completa depende das
licenças e referências tecnológicas disponíveis à pessoa revisora.

## 12. Limitações e trabalhos futuros

- **Resize V1.** Os fatores 1 e 2 por eixo estão implementados e
  verificados. O aceite do recorte em relação à interface conceitual
  do PDF aguarda manifestação do professor.
- **MMMC de teste.** Os cenários cobrem caminhos restringidos.
  Faltam parâmetros externos de I/O de teste e especificação de
  captura at-speed. A captura estática registrada não cobre esse caso.
- **SDF, DFT e equivalência.** O VCS ignorou 15 interconexões na
  anotação diagnóstica. Regressão temporal completa, ATPG,
  cobertura de falhas e equivalência formal permanecem pendentes.
- **Qualificação física.** Taps, endcaps, fillers, ties, antena,
  latch-up e IR/EM exigem dados e regras adicionais. DRC/LVS e
  correlação independente da extração e do STA também permanecem
  pendentes. Os checks deste relatório são os internos do FC.
- **Demonstração visual.** O M11 usa uma fotografia e uma
  configuração. Os resultados medem concordância do pipeline nesse
  ensaio. A cobertura mais ampla vem da regressão oficial e dos
  testes do modelo.

## 13. Conclusão

O Grupo 6C implementou e verificou um front-end de pixels em
streaming com processamento bit-exato nos casos exercitados.
As evidências incluem síntese a 100 MHz, uma cadeia de 115 SDFFs
validada e implementação física com routing, extração e potência
estimada. O caso complementar reconstruiu o quadro produzido pelo
RTL e pela netlist, com zero divergências frente ao Golden Model.

O M10 está consolidado no escopo acadêmico. Esta primeira versão
do relatório oferece um roteiro reprodutível e resultados
rastreáveis. O M11 fica em revisão, com o aceite do recorte da
V1 e a revisão dos responsáveis ainda por registrar.
