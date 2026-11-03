# KUIDAMOS / CIExpert — Contexto técnico e plano completo do Grupo 6C

**Versão desta nota:** 0.1 — 2026-10-28  
**Status:** documento de apoio para implementação; **não substitui a proposta oficial**.  
**Fonte primária:** `docs/referencias/definicao_escopo_grupo_6_oficial.pdf`, 20 páginas; foco nas páginas 11–20 (seção 6). Se existir `pre-planejamento.md` completo extraído fielmente do Overleaf, consultá-lo em paralelo.  
**Público:** Codex, Wagner (DFT) e Thiago (RTL).

## 0. Como ler esta nota

Ao longo deste texto:

- **[PDF]** = requisito, intenção ou limite literalmente documentado no planejamento final submetido.
- **[ENG]** = consequência técnica, interpretação ou recomendação derivada da especificação; **ainda não é uma decisão aprovada**.
- **[ABERTO]** = questão que precisa ser documentada na especificação V1.
- **[EXTENSÃO]** = recurso possível após cumprir a entrega principal e verificar ambiente/licenças.

Não tratar `[ENG]`, `[ABERTO]` ou `[EXTENSÃO]` como exigência oficial. Esta distinção é crítica para que a IA não modifique silenciosamente o escopo do grupo.

## 1. Projeto geral e papel de cada grupo

**[PDF]** KUIDAMOS atua com visão computacional embarcada para segurança urbana: leitura automática de placas (LPR), detecção de pessoas, permanência/perambulação e detecção/captura de faces. A plataforma de referência citada é Luckfox Pico Pro Max, com processamento de vídeo e NPU; vídeo pode vir de câmera IP/RTSP ou sensor. O programa CIExpert busca exercício de projeto digital e fluxo de ferramentas Synopsys, com potencial de reaproveitamento no futuro.

**[PDF]** Os módulos são **IPs educacionais independentes**, não uma solução final com inferência:

| Grupo | Tema | Observação |
|---|---|---|
| 6A | Produto matricial 4×4 INT8→INT32 | Aritmética para redes neurais, sem dependência do 6C |
| 6B | FFT para áudio | Processamento espectral; **não é convolução 3×3 de imagem** na versão final |
| **6C** | **Front-end de pixels em streaming** | **Este repositório**: grayscale, crop, nearest resize e threshold |

**[PDF]** Equipe 6C: Wagner Cutrim Rabelo Junior — DFT; Thiago Fernandes Carvalho de Souza — RTL. Prazo estimado: cinco meses. Fluxo geral: especificar → RTL SystemVerilog → verificar → sintetizar → DFT → implementar fisicamente → relatar resultados.

**[PDF]** Não há exigência de integração entre 6A, 6B e 6C; não é para substituir NPU da Luckfox, fazer classificador, receber H.264 diretamente ou operar câmera física. Métricas de área, frequência e potência são medidas, **não metas pré-garantidas**.

## 2. O que exatamente o 6C deverá fazer

O 6C implementará uma transformação do **fluxo de pixels** antes de uma eventual análise por outros sistemas. Uma imagem é sequência de pixels organizados em linhas e quadros, acompanhada de sinalização. Não confundir stream de pixels decodificados com stream H.264, RTSP ou pacotes Ethernet.

**[PDF]** Diagrama lógico da V1:

```text
               pixels de entrada RGB888
                           |
                   [ Grayscale ]
                           |
               pixels cinza de 8 bits
                           |
                    [ Crop ROI ]
                           |
                    [ Resize NN ]
                           |
                  [ Threshold ]
                           |
             pixels de saída de 8 bits
     + valid e marcadores de linha/quadro
```

**[ENG]** Para evitar desperdício ou remoção indesejada de objetos, crop pode ser bypassável, como uma configuração; a proposta oficial **não define explicitamente** bypass de crop (ao contrário do threshold), portanto a V1 precisa decidir. A possibilidade de bypass **não exige duplicar frames**: pode-se apenas aceitar todos os pixels quando desativado. Câmera em cenário com objetos móveis e ROI desconhecida pode não se beneficiar do crop; por isso não prometer melhora para qualquer cena.

**[ENG]** Resize e grayscale podem reduzir o volume de dados enviados a um estágio seguinte, mas **não garantem** redução proporcional do tempo total do sistema, nem preservação da acurácia de uma IA; nenhum benchmark de LPR/face é exigido no projeto.

## 3. Formato de entrada, saída e equações

### 3.1 Pixels e interface — requisitos já declarados

**[PDF]** Entrada RGB888: `R`, `G`, `B` unsigned de 8 bits cada, valores inteiros em `[0,255]` (24 bits/pixel). Processar somente quando entrada válida. Saída de 8 bits (`pixel_out[7:0]`) com `pixel_out_valid`, acompanhada de informação de linha/quadro. Sinais iniciais citados no documento: `clk`, `reset_n`, `pixel_r[7:0]`, `pixel_g[7:0]`, `pixel_b[7:0]`, `pixel_valid`, marcadores de início/fim de linha/quadro e parâmetros de configuração. **Nomes precisos, handshakes e comportamento ciclo a ciclo ainda devem ser formalizados.**

**[ABERTO]** É preciso decidir se `pixel_valid` sozinho basta (sem backpressure) ou se haverá `in_ready`/`out_ready`. A escolha altera o contrato temporal e a implementação de stalls. Nunca inventar um ready sem ajustar teste e especificação.

**[ABERTO]** Definir origem `(0,0)` no canto superior esquerdo (recomendação), `x` crescente na linha, `y` crescente a cada linha; SOF, EOL, EOF e validade; reset; relação entre entrada e saída; como o módulo lida com linhas vazias e gaps válidos.

### 3.2 Grayscale — conversão inteira bit-exata

**[PDF]**

```text
Y = floor((77*R + 150*G + 29*B)/256)
```

- Os pesos somam 256; não há aritmética de ponto flutuante.
- `Y` é unsigned de 8 bits.
- O resultado inteiro é `((77*R + 150*G + 29*B) >> 8)` se todos os termos forem **unsigned** e o temporário tiver largura suficiente.
- Maior soma = `256*255 = 65280`; requer pelo menos **16 bits unsigned** antes do shift. Não truncar multiplicações parciais para 8 bits.
- O golden model Python deve reproduzir **essa fórmula**. Não usar `cv2.cvtColor()` como juiz bit-exato sem comprovar que o arredondamento coincide.

**[ENG]** Testes: RGB preto `(0,0,0)` → `0`; branco `(255,255,255)` → `255`; primárias, combinações, valores aleatórios reproduzíveis, variação de canal isolado. Nunca assumir que qualquer conversão cinza de biblioteca será bit-identical.

### 3.3 Crop — seleção de ROI por coordenadas

**[PDF]** Retângulo definido por `x_start`, `y_start`, `W_crop`, `H_crop`, com limites superiores exclusivos:

```text
x_start <= x < x_start + W_crop
AND
 y_start <= y < y_start + H_crop
```

Apenas pixels de dentro passam; os demais são **descartados** do fluxo. Crop não detecta placas, rostos, pessoas ou objetos: não existe IA nessa etapa. Se a janela errar, pode remover conteúdo importante; sua utilidade depende de ROI conhecida ou informada pelo sistema externo.

**[ENG]** Em fluxo contínuo, a seleção usa contadores de X/Y + comparadores + sinal de validade e marcadores regenerados; **não** é necessário armazenar duas imagens (nem mesmo uma imagem inteira). Se estiver habilitado, fluxo de saída representa a subimagem. Se bypass for aprovado, o circuito encaminha o quadro integral, sem uma segunda cópia de dados.

**[ABERTO]** Definir largura e validação das coordenadas; origin `(0,0)`; caso `W_crop/H_crop = 0`; ROI ultrapassando borda; possibilidade de região fora da imagem; bypass; transição de parâmetros no meio de frame. Não implementar clipping silencioso ou frame vazio sem documentar a política.

### 3.4 Resize nearest-neighbor — redução espacial

**[PDF]** Primeira versão prioriza **downscaling** por vizinho mais próximo, sem interpolação. Conceitualmente, coordenadas de saída selecionam o pixel-fonte:

```text
x_src = floor(x_out * W_in / W_out)
y_src = floor(y_out * H_in / H_out)
```

**Cuidado de interpretação:** na composição pipeline, `W_in/H_in` do resize se referem à dimensão **que sai do crop**, não necessariamente ao quadro RGB original. Se crop tiver bypass, entrada do resize é o quadro inteiro. Não usar as dimensões erradas.

**[ENG]** Para *redução pura*, o IP pode emitir somente os pixels de entrada cujas coordenadas correspondem a posições-fonte selecionadas e descartar os demais, usando contadores e lógica de seleção. Isto é diferente de gerar todos os pixels na borda do clock; não deve emitir pixels duplicados nem linhas extras. É possível começar testando fator 2 (ex.: 8×8→4×4), mas fator 2 **é sugestão**, não requisito fechado.

**[ABERTO]** Definir fatores suportados, dimensões máximas, tratamento de dimensões ímpares, redução não inteira, razão horizontal distinta da vertical, política de última linha/coluna, número de pixels de saída esperado, custo de divisões no hardware. Se aceitar razões genéricas, demonstrar arquitetura de counters/accumulators comparators realizável sem divisores caros, macros ou framebuffer completo.

**[ENG]** Só a implementação do resize oferece risco de escopo: exigir todos os pares de resoluções ou upscale pode tornar o projeto grande. Formalizar subconjunto suportado e testar exatamente esse subconjunto.

### 3.5 Threshold — limiar de luminância

**[PDF]** Após grayscale/crop/resize, comparar o pixel de 8 bits a um limiar `T` (8 bits):

```text
se pixel >= T: saída = 255
se pixel <  T: saída =   0
```

**[PDF]** `threshold_enable` lógico/bypass: quando desabilitado, saída preserva a intensidade de cinza. Os nomes exatos do controle são `[ABERTO]`. A saída continua sendo 8 bits, **não** um pixel de 1 bit compactado.

**[ENG]** Threshold pode eliminar texturas e informações relevantes para detecção; por isso não impor que esteja sempre ativo. Testes de `T=0`, `T=255`, igualdade `Y==T`, vizinhança `T±1`, bypass.

## 4. Interface e microarquitetura — o que está aberto

O documento final é deliberadamente conceitual; por isso os pontos abaixo **não podem ser deixados implícitos** antes do RTL:

| Assunto | Definido no PDF? | Ação do Codex no primeiro ciclo |
|---|---|---|
| Barramento RGB888 e output 8 bits | Sim | Formalizar nomes e temporização sem redefinir bits |
| `clk`, `reset_n` | Mencionados | Propor sincronicidade, polaridade, tempos e reset de marcadores |
| `pixel_valid`, `pixel_out_valid` | Mencionados | Definir transferências, gaps, stalls, latência |
| Backpressure `ready` | Não | Comparar opções (sem ready vs. ready) e recomendar uma V1 |
| Início/fim de linha/quadro | Mencionados | Semântica exata no ciclo do primeiro/último pixel **emitido** |
| Configuração | Parametrizável em sinais/regs | Propor interface simples e sampling no início de quadro |
| Largura de contadores e resolução máxima | Não | Propor limite viável; pedir aprovação |
| Crop habilitado/desabilitado | Bypass de crop não explícito | Recomendar bypass, registrar como proposta |
| Threshold habilitado/desabilitado | Sim | Definir comportamento bit-exato |
| Resize fator 2 vs genérico | Prioridade downscale apenas | Comparar esforço/risco; propor milestone simples |
| FIFO/buffer/line buffer | Sem framebuffer ou macros; storage mínimo | Não criar armazenamento excessivo; justificar qualquer buffer |
| Carga de configuração inválida | Não | Definir rejeição/erro/no-frame e testes |
| Target 100 MHz | Referência inicial de análise | Criar 10 ns constraint quando ambiente conhecido |
| PDK/biblioteca | Não identificados | Descobrir na infraestrutura; nunca supor nome/versão |

**[ENG] Recomendações para análise, não contratos:**

1. **Frames**: manter parâmetros estáveis durante um quadro, preferencialmente capturados no SOF, para impedir mudança de resolução no meio de uma linha.
2. **Marcadores de saída**: se um pixel de entrada com `in_eol=1` for descartado, não copiar `eol=1` diretamente; gerar `out_eol` no último **pixel emitido** da linha de saída. Idem SOF/EOF após crop/resize. Evitar marcador desacompanhado de pixel se o contrato prevê marcador coincidente com `valid`.
3. **Crop**: a entrada da ROI é descrita em coordenadas da imagem original; a saída do crop deve ser renumerada para `(0,0)` quando seguir para resize.
4. **Sem framebuffers**: o caminho de pixels por registradores permite RTL menor e DFT mais acessível; line buffer só se um requisito técnico realmente exigir, e a necessidade deve ser demonstrada.
5. **Configuração**: teste de alteração de parâmetros entre quadros, e tentativa de mudança no meio do quadro segundo a política acordada.
6. **Latência**: definir explicitamente em ciclos, mesmo se ela variar entre operações ou se houver pipeline; scoreboard não pode supor zero ciclos.

## 5. Plano de verificação / Golden Model

### 5.1 Princípio

**[PDF]** Construir golden model Python com NumPy e opcional OpenCV, independente do RTL, além de geração de vetores, testbench SystemVerilog, scoreboard, SVA e relatório dos casos. O golden model deve receber parâmetros e matriz RGB, devolver matriz de 8 bits **e metadados de dimensões**; os vetores de streaming devem conter marcadores, e o testbench deve conferir toda a sequência.

**[ENG]** Priorizar uma implementação Python pura com `//` e seleção explícita de índices para garantir fidelidade bit-exata; OpenCV fica útil para carregar/salvar PNG, exibir comparações e fazer referência qualitativa quando apropriado. Jamais escolher `cv2.resize()` como autoridade sem testar a convenção de amostragem.

### 5.2 Casos direcionados

| Categoria | Exemplo | O que verificar |
|---|---|---|
| Sem transformação espacial | 4×4, crop total, resize igual | Dados/ordem/marcadores preservados (após grayscale) |
| RGB extremos | preto, branco, primárias RGB | Fórmula inteira, largura intermediária |
| Crop centro/borda | 8×8 ROI x=2 y=1 w=4 h=5 | Quantidade, bordas, origem de saída |
| ROI de tamanho 1 | ROI 1×1 | Não emitir pixel extra; markers corretos |
| ROI inválida | dimensões zero ou fora da imagem | Política documentada, não crash/hang |
| Crop bypass (se aprovado) | full frame com `crop_enable=0` | Passar tudo sem cópia de framebuffer |
| Resize fator 2 | 8×8→4×4 | Posição-fonte, perda controlada de pixels |
| Dimensões ímpares | 5×3→? admissível | Regra clara para piso/último pixel |
| Downscale assimétrico | 8×6→4×2, se suportado | Índices X/Y independentes |
| Threshold | T=0, 128, 255 | `>=`, saída 0/255 e bypass |
| Streaming com gaps | `pixel_valid` alterna | Counters só em transferências válidas |
| Marcador coincidente com pixel descartado | crop e resize | Regeneração de SOF/EOL/EOF |
| Mudança de parâmetros | entre quadros e no meio | Política de sample/erro respeitada |
| Reset | durante fluxo ou entre frames | Estado limpo, sem dados espúrios |
| Frames consecutivos | quadro A seguido de B | Sem mistura de dados/param. |
| Aleatórios | seed fixa documentada | Regressão reproduzível |
| Imagens reais PNG | textura, objetos variados | Teste complementar; não substituir casos sintéticos |

**[ENG]** Incluir assertions de: não emitir `out_valid` fora de política; SOF no primeiro output válido e EOL no último output válido de cada linha; comportamento de reset; coordenadas dentro do intervalo; configuração estável; contagem de pixels por quadro/linha quando aplicável. Sem overconstraints falsas antes de fixar handshake.

### 5.3 Evidência de aceite

- Scripts de geração de vetores com seed fixa, formato descrito e arquivos de teste pequenos rastreáveis.
- VCS compile + simulation exit status real, relatório PASS/FAIL, número de cenários e mismatches.
- Scoreboard automático (comparar **sequência de bytes + sinais** com golden model). Não basta visualizar imagem que "parece correta".
- SVA sem violações injustificadas nos cenários obrigatórios.
- Se ferramenta/feature não existir, reportar bloqueio objetivamente; nunca declarar que rodou.

## 6. Fluxo EDA / DFT / implementação física

**[PDF]** Requisitos e metodologia do CIExpert (seção 6.5–6.8):

1. Especificação formal de formato, parâmetros, reset, sincronismo, temporização.
2. Golden Model e vetores.
3. RTL incremental em SystemVerilog (começar por `pass-through`, depois grayscale, crop, resize, threshold).
4. TB SystemVerilog com Scoreboard e SVA; testes direcionados e reprodução.
5. Síntese com Design Compiler e **referência inicial** de 100 MHz/10 ns; coletar área, caminhos críticos e violações.
6. DFT em TestMAX DFT: verificações estruturais, `dft_drc`, `preview_dft`, inserção de scan quando suportada; documentar violações/limitações.
7. Físico com Fusion Compiler (`fc_shell`) conforme PDK, bibliotecas e licenças reais; documentar área, timing e potência quando disponíveis.
8. Relatórios: decisões, versões, arquivos de constraints, scripts, configurações, resultados de cada etapa.

**[ENG]** Seguir preferência por lógica registrador/combinacional; evitar macros de SRAM/memória para não introduzir necessidade de MBIST no escopo V1. DFT deve ser pensado durante o RTL, principalmente resets, clock, test modes, condições de controle que tornam registradores não escaneáveis.

**[EXTENSÃO]** Se o ambiente tiver TestMAX ATPG/licença e o mentor solicitar: ATPG stuck-at/transition, reportar fault coverage/test coverage e validar padrões por simulação. **Não é promessa de escopo oficial escrita no texto 6C do PDF**, que trata explicitamente de DFT e inserção de scan.

**[ABERTO]** Nem o nó tecnológico, PDK, standard cells, configurações de licença nem versões exatas estão fixados no documento. SAED32 e versões pessoais anteriores **não constituem confirmação** para o 6C. Verificar antes de tentar executar scripts definitivos.

**[ENG]** No Windows + VS Code, possível editar localmente; executar Synopsys no Rocky Linux (via terminal/SSH) após confirmar instalação, shell, variáveis, licenças e paths. Nada de atribuir sucesso se só existe TCL escrito e não executado. Não versionar artefatos proprietários.

## 7. Entregáveis exigidos no PDF (seção 6.7)

1. Especificação técnica completa do módulo, interface, configuração, dimensões, reset, temporização, marcadores.
2. RTL sintetizável de quatro operações + controle do pipeline.
3. Golden Model, imagens e vetores reprodutíveis.
4. Testbench, scoreboard, SVA e relatório de verificação.
5. Scripts/constraints/relatórios de síntese com área e timing.
6. Evidências de DFT e inserção de scan no ambiente real.
7. Resultados de implementação física, inclusive área/timing/potência se disponíveis.
8. Documentação reprodutível: decisões, versões, scripts, limitações.

## 8. Critérios de aceitação oficiais (PDF §6.8)

- Grayscale bate exatamente com o Golden Model nos vetores obrigatórios.
- Crop só emite pixels na ROI; bordas explicitamente exercitadas.
- Resize bate com a convenção de nearest-neighbor do Golden Model para as resoluções aprovadas.
- Threshold 0/255 quando ligado, passthrough de cinza quando desligado.
- Marcadores de linha/quadro refletem a imagem realmente produzida; não há pixels válidos além dos limites.
- Scoreboard compara todos os pixels válidos; SVA sem violações obrigatórias não justificadas.
- RTL sintetizável sem erros impeditivos e sem estrutura diferente da especificada.
- Relatório de timing com alvo inicial de 100 MHz, registrando violações; **rodar análise não prova timing fechado**.
- DFT/scan/físico executados até onde o ambiente suporta, com limitações explicitadas.
- Rastreabilidade: parâmetros, PDK, versões, vetores, relatórios, scripts.
- Área/potência/frequência reportadas apenas com base no que ferramentas realmente calcularam.

## 9. Riscos documentados (PDF §6.9) e mitigação

| Risco | Mitigação |
|---|---|
| Formatos/sincronismo ambíguos | Especificar RGB888, output 8 bits, reset, valid e marcadores antes do RTL |
| Diferença golden model vs RTL | Golden Model independente, seeds fixas, scoreboard automatizado |
| Crop seleciona coordenadas erradas | Imagens sintéticas pequenas, ROI na borda e centro |
| Resize cresce demais | Nearest only, priorizar downscale; definir subconjunto de fatores |
| Marcadores inválidos após crop/resize | Regerar de acordo com pixels emitidos e validar com SVA |
| Caminho crítico no grayscale | Examinar reports; ajustar soma/registradores sem alterar função |
| Excesso de registradores/buffer | Sem framebuffer completo; storage mínimo |
| Licenças e ferramentas EDA | Diagnóstico no início; ambiente mínimo validado antes de fluxo extenso |
| PDK não identificado | Confirmar antes da síntese/físico definitivos |
| Scan difícil | Pré-DFT DRC incremental, circuitos registradores simples |
| Cobertura de casos fraca | Testes sintéticos, extremos, resoluções, ROI, thresholds, reais complementares |

## 10. Organização sugerida do repositório

Esta **é uma proposta**, não parte da especificação oficial; adaptar à pasta já criada sem apagar arquivos.

```text
.
├── AGENTS.md                          # Codex lê primeiro
├── PROMPT_INICIAL_CODEX.md             # mensagem para a primeira sessão
├── pre-planejamento.md                 # usuário adicionará a versão FINAL do Overleaf
├── docs/
│   ├── CONTEXTO_TECNICO_6C.md         # esta nota
│   ├── DECISOES_E_PENDENCIAS.md       # registro de decisões
│   ├── spec_v1.md                     # Codex criará na PRIMEIRA SESSÃO
│   ├── plano_de_execucao.md           # Codex criará na PRIMEIRA SESSÃO
│   └── referencias/
│       └── definicao_escopo_grupo_6_oficial.pdf
├── rtl/                                # apenas após aprovação da spec
├── tb/
├── model/
├── scripts/
├── constraints/
├── dft/
├── physical/
└── reports/
```

A primeira sessão deve **criar `docs/spec_v1.md`, `docs/plano_de_execucao.md` e atualizar `docs/DECISOES_E_PENDENCIAS.md`**. As outras pastas podem ser criadas vazias se for útil, mas não gerar centenas de arquivos antes de a especificação estar fechada.

## 11. Caminho de execução em marcos

| Marco | Resultado verificável | Pode avançar quando... |
|---|---|---|
| M0 — Spec V1 | Interface ciclo a ciclo; dimensões; bypass; saída e flags; riscos | Wagner/Thiago revisaram decisões abertas |
| M1 — Python | Modelo inteiro bit-exato + dados pequenos | Testes independentes do RTL passam |
| M2 — RTL pass-through / grayscale | DUT sintetizável + TB | VCS compara vetores e flags |
| M3 — Crop | ROI/bordas/bypass se aprovado | Check de pixels e markers por frame |
| M4 — Resize | Downscaling NN validado | Testes pares/ímpares/fatores aprovados |
| M5 — Threshold / full pipeline | Bypass e composição correta | Regressão e scoreboard/SVA passam |
| M6 — Síntese | DC/constraints/relatórios reais | Sem erro bloqueador, violações documentadas |
| M7 — DFT | DRC, scan, reports (ou limitação documentada) | Execução reproduzível e logs coletados |
| M8 — Físico | Fusion Compiler e relatórios possíveis | Limitações explícitas se licença/PDK impedir |
| M9 — Final | Manual, resultados, scripts, versões, riscos | Outro integrante reproduz resultados |

**[ENG]** O Codex deve poder executar a maior parte das tarefas, mas os responsáveis humanos revisam interfaces, conclusões e aceitação, especialmente licenças, timing, DFT e estimativas físicas.

## 12. Checklist para a resposta inicial do Codex

A primeira resposta de trabalho deve entregar:

- Inventário dos arquivos presentes e detecção de planejamento parcial versus final.
- Resumo curto do escopo oficial do grupo 6C e das diferenças 6A/6B.
- Uma proposta concreta de `docs/spec_v1.md` com tabela completa de I/O, timing, contadores, configurações, comportamentos e casos inválidos, distinguindo itens confirmados/abertos.
- `docs/plano_de_execucao.md` com implementação modular e evidências de aceite por marco.
- Atualização de `docs/DECISOES_E_PENDENCIAS.md` com recomendações justificadas e perguntas **apenas de decisões que realmente bloqueiam a implementação**.
- Não implementar RTL, golden model ou TCL definitivo até a especificação V1 receber aval explícito; não declarar ferramentas testadas sem executar.

## 13. Resumo de frases que o agente NÃO deve dizer sem evidência

- "Já está aprovado o crop bypass" (não está explícito no PDF).
- "O projeto precisa identificar placas" (não é tarefa do IP 6C).
- "Temos que integrar 6C→6B→6A" (6B trabalha com FFT de áudio; integração não é obrigatória).
- "ATPG stuck-at/transition é entrega obrigatória" (é extensão possível; confirmar escopo).
- "PDK é SAED32" (a tecnologia está em aberto).
- "Rodou VCS/Design Compiler/TestMAX/Fusion e passou" sem saída real da ferramenta.
- "Resize não precisa de lógica para sincronismo" (marcadores após descarte são parte central do trabalho).
- "Crop ocupa duas imagens" (seleção de pixels no stream não requer guardar duas imagens).
- "Reduzir dados garante aumento de acurácia ou FPS" (não há medição que sustente isso).
