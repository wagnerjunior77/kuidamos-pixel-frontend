# Registro de decisões e pendências — 6C

Atualização inicial: 2026-10-28. **Este arquivo registra o estado do projeto e suas fontes.**

## Convenção de status
- **OFICIAL (PDF):** declarado no documento final enviado.
- **PROPOSTO:** sugestão de engenharia para a primeira versão, distinta de requisito oficial.
- **A DEFINIR:** ainda não há decisão documentada.
- **VALIDADO:** apenas com evidência real (teste, log, síntese, ata ou aceite explícito).

## Decisões oficialmente documentadas

| Tema | Status | Decisão/limite | Fonte |
|---|---|---|---|
| Tipo do IP | OFICIAL (PDF) | Pré-processamento de pixels em streaming; IP independente | PDF §2 e §6.2 |
| Entrada | OFICIAL (PDF) | RGB888, 3 canais unsigned de 8 bits, com `pixel_valid` | PDF §6.3–6.4 |
| Saída | OFICIAL (PDF) | 8 bits, validade e estrutura de linhas/quadros | PDF §6.3–6.4 |
| Sequência | OFICIAL (PDF) | Grayscale → Crop → Resize Nearest → Threshold | PDF §6.3 |
| Grayscale | OFICIAL (PDF) | floor((77R+150G+29B)/256) | PDF §6.3 |
| Crop | OFICIAL (PDF) | Retângulo configurável, limites superiores exclusivos, descarte fora da ROI | PDF §6.3 |
| Resize | OFICIAL (PDF) | Nearest-neighbor, foco inicial em downscaling, sem framebuffer completo | PDF §6.3–6.4 |
| Threshold | OFICIAL (PDF) | Limiar T de 8 bits; bypass permitido; 0/255 quando ligado | PDF §6.3 |
| Integração | OFICIAL (PDF) | Nenhuma dependência obrigatória de 6A/6B ou Luckfox/câmera real | PDF §2, §3, §6.5 |
| Implementação | OFICIAL (PDF) | SystemVerilog + Golden Model Python + TB/Scoreboard/SVA | PDF §6.5–6.7 |
| Fluxo EDA | OFICIAL (PDF) | VCS, Design Compiler, TestMAX DFT, Fusion Compiler; Verdi opcional | PDF §6.6 |
| Clock | OFICIAL (PDF) | 100 MHz como referência inicial de análise, sem garantia de timing | PDF §6.5–6.6 |
| Tecnologia | A DEFINIR | PDK/biblioteca reais do ambiente CIExpert | PDF §6.6 |

## Sugestões técnicas iniciais

Registro histórico: as sugestões desta seção e da revisão de 2026-10-28 foram atualizadas pela decisão interna de 2026-11-03, registrada ao final deste documento.

| Tema | Status | Sugestão inicial | Risco/observação |
|---|---|---|---|
| Crop bypass | PROPOSTO | `crop_enable`, desligado por padrão | O PDF define crop configurável, mas não exige bypass explícito para crop |
| Resize V1 | PROPOSTO | Validar fator 2 antes de razões arbitrárias | PDF prioriza downscale, mas não fixa fatores |
| Protocolo | A DEFINIR | Decidir `valid` apenas versus `valid/ready`, handshake e stalls | Afeta temporalidade e testes |
| Reset | A DEFINIR | Definir ativo-baixo e síncrono/assíncrono | PDF prevê `reset_n` sem cravar semântica temporal |
| Marker signals | A DEFINIR | Semântica precisa de SOF/EOL/EOF; primeiro/último pixel efetivo | Nunca passar marcadores da entrada sem ajuste |
| Configuração | A DEFINIR | Registrar no início de quadro (SOF); imutável no quadro | Impede frame com dimensões inconsistentes |
| Dimensões | A DEFINIR | Resolução máxima, largura de contadores, restrições de ROI/resize | Evitar overflow e absurdos para ASIC |
| Casos inválidos | A DEFINIR | Crop fora da imagem, largura/altura zero, output maior que input | Não assumir silêncio sem documentar |
| Latência | A DEFINIR | Declarar por operação e eventual pipeline | SVA/scoreboard dependem dela |
| ATPG | PROPOSTO | Stuck-at/transition e pattern sim quando houver TestMAX ATPG/licença | Extensão, não obrigação explícita no PDF |
| Physical | A DEFINIR | Estudar fluxo/limites da infraestrutura CIExpert | Etapa prevista, execução depende de ferramentas/PDK |

## Questões essenciais para a primeira revisão da especificação

1. A V1 terá apenas razão de redução 2:1 em cada eixo ou proporções configuráveis? Se configurável, quais limites e algoritmo **bit-exato**?
2. Qual é a dimensão máxima da imagem de entrada (por exemplo, apenas testes pequenos, 640×480, outra)? Definir e documentar a resolução suportada.
3. Crop terá bypass? Os parâmetros serão travados em SOF? O que ocorre em retângulo inválido?
4. O fluxo terá `ready` para backpressure ou apenas pixels válidos que devem ser aceitos? Como tratar gaps em `pixel_valid`?
5. Quais marcadores (SOF/EOL/EOF) exatamente, sua polaridade, relação com `valid` e o que acontece quando crop/resize descartam o último pixel de uma linha?
6. Como os dados/marcadores são encaminhados com latência variável ou fixa? Qual formato de arquivos de vetores?
7. Qual é a máquina Linux de Synopsys, versões instaladas, licenças, PDK e bibliotecas disponíveis? Documentar evidência, não suposição.
8. Quais entregáveis esperados além do mínimo do PDF (ATPG/pattern sim)?

## Diário de execução (preencher, não supor)

| Data | Mudança/decisão | Responsável | Evidência/arquivo | Status |
|---|---|---|---|---|
| 2026-10-28 | Documentos de orientação para início do 6C preparados a partir do PDF oficial | Assistente de IA | `AGENTS.md`, `docs/CONTEXTO_TECNICO_6C.md` | Documentação inicial |


## Revisão técnica V1 — 2026-10-28

O histórico acima permanece como registro inicial; as propostas seguintes detalham e substituem apenas as sugestões genéricas para registrar a evolução técnica. Fonte: PDF oficial §§6.2–6.9, confrontado diretamente; `pre-planejamento.md` ausente. Evidência documental: `docs/spec_v1.md` e `docs/plano_de_execucao.md`. Nenhum teste funcional/EDA foi executado nesta revisão.

| Tema e opções | Recomendação — status | Motivação e riscos / revisão |
|---|---|---|
| Resolução: 640×480, 2047×2047 ou outro limite | 2047 por eixo, dimensões e coordenadas em 11 bits — **PROPOSTO** | Limite simples sem assumir necessidade de aplicação; somas em 12 bits; custo e timing desconhecidos. Há implicações para a interface e o DFT. |
| Crop: sempre ativo com ROI integral ou bypass dedicado | `crop_enable`, ROI ignorada no bypass — **PROPOSTO** | Prático para quadro integral; não exigido pelo PDF. |
| Resize: arbitrário ou subconjunto | Fatores 1 ou 2 independentes por eixo, saída piso, conforme equação do PDF — **PROPOSTO** | Atende diferentes fatores com seleção simples; restringe dimensões configuráveis em relação à proposta conceitual. A adequação depende das resoluções necessárias ao projeto. Dimensões ímpares e mapeamento exigem testes. |
| Fluxo: somente valid ou valid/ready | Apenas valid, destino sempre aceita — **PROPOSTO** | Baixa complexidade; integração não tolera backpressure. |
| Reset e flags: síncrono ou assíncrono; 3 ou 4 flags | Reset síncrono ativo baixo e SOF/SOL/EOL/EOF por pixel — **PROPOSTO** | PDF prevê início/fim de linha e quadro; reset síncrono requer clock durante reset e afeta a testabilidade. |
| Latência e pipeline | Registro de saída, 1 ciclo borda a borda — **PROPOSTO** | Simples; caminho combinacional pode violar 10 ns e demandar nova decisão. |
| Configuração | Capturar no SOF, primeiro pixel usa sinais atuais — **PROPOSTO** | Evita mudança no meio do quadro; quadros consecutivos exigem isolar controles em trânsito. |
| Inválidos/vazios | Rejeitar quadro e pulsar `cfg_error`, sem pixels ou flags; sem clipping — **PROPOSTO** | Recuperar no próximo SOF; sistema precisa observar erro; não há marcador de quadro vazio. |
| Fluxo malformado | Sem detecção completa; SOF inesperado reinicia — **PROPOSTO** | Pode ter saídas parciais já emitidas, consumidor descarta quadro interrompido; especificar responsabilidade do sistema. |
| Marcadores | Regenerar quatro flags pelas coordenadas de saída — **PROPOSTO** | EOF de saída pode preceder o de entrada. Scoreboard/SVA verificam inclusive pixels de entrada finais descartados. |
| Tecnologia e ferramenta | Identificar no CIExpert — **A DEFINIR** | Não há PDK, biblioteca, licença ou versão confirmados; Wagner verifica DFT e fluxo; físico depende da infraestrutura. |
| ATPG | Extensão condicional — **PROPOSTO** | Não é entrega explicitamente obrigatória em 6C; Wagner verifica expectativa, licença e fluxo. |

### Inventário inicial — 2026-10-28

- Raiz: `AGENTS.md`, `PROMPT_INICIAL_CODEX.md`, `README_COMO_COMECAR.md`, `VERIFIQUE_ARQUIVOS.txt`.
- `docs/`: `CONTEXTO_TECNICO_6C.md`, `DECISOES_E_PENDENCIAS.md`, `referencias/definicao_escopo_grupo_6_oficial.pdf` (20 páginas).
- No inventário inicial não havia `pre-planejamento.md`, RTL, modelo, testbench ou scripts de fluxo. Naquela data, o diretório ainda não era um repositório Git; `git status --short` retornou erro e não havia baseline Git para diff.
- Na etapa inicial foram criados `docs/spec_v1.md` e `docs/plano_de_execucao.md` e acrescentadas informações a este registro. O PDF e as demais fontes permaneceram inalterados.

### Pontos técnicos para desenvolvimento

A V1 documenta limite de resolução, fatores 1/2 com piso, ausência de ready, reset, flags, latência, erro e bypass. Mudanças nessas opções devem ser registradas para manter modelo e RTL consistentes. O acesso ao CIExpert permanece necessário para os marcos EDA.

| Data | Mudança/decisão | Responsável | Evidência/arquivo | Status |
|---|---|---|---|---|
| 2026-10-28 | Leitura do PDF e proposta de interface, políticas e plano V1 | Codex (ferramenta de IA) | `docs/spec_v1.md`, `docs/plano_de_execucao.md` | PROPOSTO; testes EDA NÃO EXECUTADOS |

## Revisão final de M0 — 2026-11-03

**Status à época da revisão: análise e recomendações; nenhuma nova decisão validada.** Fontes: `spec_v1.md`, `plano_de_execucao.md` e PDF oficial §§6.3–6.9. As opções abaixo mantêm a distinção entre a referência oficial e as escolhas de engenharia. A disponibilidade do PDK e das ferramentas é uma pendência para o fluxo EDA, não um bloqueio para o modelo funcional Python.

| Ponto | Recomendação e alternativa | Consequência e evidência |
|---|---|---|
| Resolução | Manter 1–2047 por eixo com campos de 11 bits; alternativa: outro limite ou 12 bits para 2048. | 2048 não cabe em 11 bits; custo/timing do limite não foram medidos. A resolução máxima é omitida pelo PDF. |
| Crop | Manter bypass por `crop_enable`; alternativa: ROI integral, sem sinal de bypass. | Bypass adiciona controle e teste; não é exigência oficial. |
| Resize | Fatores independentes 1 ou 2 e saída `floor(N/F)`; alternativa: dimensões de saída configuráveis genericamente. | Seleção sem divisor genérico para o subconjunto proposto. O PDF prevê parâmetros de dimensões de saída; o uso exclusivo de fatores e dimensões derivadas é uma restrição de interface e escopo a considerar. Para N ímpar, a última amostra de saída não necessariamente alcança a borda da ROI. |
| Streaming e marcadores | Apenas `valid`; SOF/SOL/EOL/EOF coincidem com pixels; regenerar os quatro na saída. Alternativa: `valid/ready`. | O destino deve aceitar cada saída e não pode interromper o IP; bolhas de entrada são aceitas. EOF de saída pode ocorrer antes de EOF de entrada. |
| Reset e latência | Reset síncrono ativo baixo; um ciclo de transferência borda a borda. Alternativas: reset assíncrono ou mais estágios de pipeline. | O reset exige clock; DFT deve avaliar controlabilidade. Um ciclo pode não fechar 10 ns; a frequência só será conhecida por relatórios. Transferência de saída já válida na borda de reset deve ser tratada de forma inequívoca no contrato e no testbench. |
| Configuração | Capturar parâmetros no SOF e usar a configuração nova no primeiro pixel; alternativa: interface de configuração separada. | Mudanças externas no quadro são ignoradas. Controles e metadados de quadros consecutivos não podem se misturar. |
| Erros | Configuração inválida no SOF: pulso de `cfg_error` e quadro sem saída; alternativa: erro persistente com reconhecimento. | Pulso precisa ser observado pelo sistema. Quadro inválido não tem marcador de saída e a interface não informa por si só quando ele termina. |
| Fluxo malformado | Recomenda-se tratar marcadores incoerentes como violação de contrato da fonte, sem garantia de detecção; aceitar SOF inesperado como início de novo quadro. Alternativa: adicionar sinal de erro/aborto e lógica de detecção. | A saída pode ter sido parcialmente ou completamente consumida antes da descoberta de erro de entrada; marcadores de saída isolados não permitem desfazer nem identificar sempre o quadro corrompido. Definir responsabilidade do sistema e comportamento após reset antes do RTL. |

Para grayscale, foi verificada por cálculo a sequência preto, vermelho, verde, azul e branco: 0, 76, 149, 28 e 255. Para resize fator 2, um cálculo em Python comparou `floor(k*N/floor(N/2))` com `2*k` em 1.047.552 índices, N de 2 a 2047, sem divergências. Estes cálculos não constituem verificação de RTL, síntese ou prova de timing. Nenhum fluxo EDA foi executado na revisão.

## Decisão interna M0 — 2026-11-03

**M0 concluído internamente; decisões V1 aprovadas pelo responsável pelo projeto para implementação.** Evidência: aprovação explícita do usuário em conversa de 2026-11-03; especificação atualizada em `docs/spec_v1.md`. Histórico anterior preservado. A aprovação interna não comprova resultados de ferramentas nem substitui a validação do professor.

| Tema | Decisão aprovada para V1 | Pendência/limitação |
|---|---|---|
| Dimensões | 1–2047 por eixo; 11 bits; somas de limites com largura suficiente, no mínimo 12 bits | O PDF não fixa resolução máxima; custo e timing não medidos. |
| Crop | `crop_enable`; bypass usa quadro integral, sem framebuffer ou duas imagens no IP | Bypass não é exigência explícita do PDF. |
| Resize | Fatores 1 ou 2 independentes; saída `floor(N/F)`; mapeamento nearest conforme fórmula oficial | Restrição de fatores e interface derivada ainda sujeitas à validação do professor. |
| Fluxo e flags | `pixel_valid` sem `ready`; bolhas; SOF/SOL/EOL/EOF reconstruídos sobre pixels efetivos | Destino deve aceitar toda saída válida. |
| Reset e latência | Reset síncrono ativo baixo; transferências somente com `reset_n=1`; aguardar SOF. Meta inicial: um ciclo | Se timing exigir pipeline, documentar e atualizar contrato e testes antes de alterar. |
| Configuração | Captura no SOF, incluindo o primeiro pixel; cópia interna constante no quadro | Mudanças externas durante o quadro não alteram a configuração capturada. |
| Configuração inválida | Pulso `cfg_error` e descarte do quadro, inclusive saída de dimensão zero | Sistema deve observar o pulso; quadro sem pixels não tem marcadores de saída. |
| Quadros malformados | Violam contrato da fonte; recuperação no SOF seguinte, sem promessa de detecção completa | Pixels já transferidos não podem ser retirados; o sistema trata o quadro incompleto. |

**Infraestrutura A DEFINIR:** PDK, bibliotecas, versões, licenças e executor Synopsys; DFT, ATPG e físico dependem da disponibilidade e do escopo pertinente. Nenhum resultado EDA é presumido.

| Data | Mudança | Evidência | Status |
|---|---|---|---|
| 2026-11-03 | Golden Model por quadro, testes e vetor funcional inicial | `model/README.md`, `docs/evidencias/M1_modelo_python.md` | 16 testes Python passaram; RTL e EDA não executados; M2 temporal pendente |
| 2026-11-03 | Regressão e demonstração visual por etapas; proposta de responsáveis | `docs/evidencias/M1_modelo_python.md`, `docs/plano_de_execucao.md` | 18 testes Python passaram; divisão de responsáveis pendente de alinhamento com Thiago; RTL e EDA não executados |

## Progresso M2 — 2026-11-04

Vetores funcionais e temporais gerados por `model/m2_vectors.py`, com valores e marcadores de quadro do Golden Model e associação independente às coordenadas de entrada; nove casos em `vectors/m2/`. A convenção por borda, inclusive saída pós-borda, transferência na borda seguinte e cancelamento pelo reset, está descrita em `docs/evidencias/M2_vetores.md` sem alteração da especificação V1. A regressão local registrou 29 testes Python aprovados e a comparação de 28 arquivos gerados idênticos. A integração dos vetores ao futuro testbench VCS, o RTL e as ferramentas Synopsys permanecem não executados. A restrição dos fatores de resize continua sujeita à validação do professor.

## Teste complementar com imagem real — 2026-11-04

O Golden Model foi executado com uma imagem JPEG local, após redução proporcional externa de 2268×4032 para 1151×2047 para respeitar o limite V1. Parâmetros, resultados e distinção entre preparação externa e resize do modelo constam em `docs/evidencias/M1_imagem_real.md`. A regressão Python registrou 31 testes aprovados; RTL e ferramentas EDA não foram executados.

Uma análise complementar comparou a saída sem threshold com os limiares 64, 96, 128, 160 e 192; as contagens e verificações estão em `docs/evidencias/M1_imagem_real.md`. A regressão registrou 32 testes aprovados; as imagens permanecem locais em `outputs/`.

## Implementação RTL M3–M6 — 2026-11-05

Os módulos RTL sintetizáveis em SystemVerilog (`rtl/grayscale_core.sv`, `rtl/crop_core.sv`, `rtl/resize_nn_core.sv`, `rtl/threshold_core.sv` e o topo `rtl/kuidamos_pixel_frontend.sv`) foram implementados conforme `docs/spec_v1.md`, com captura e validação atômica de configuração em `in_sof`, pulso `cfg_error`, contadores de coordenadas de 11 bits, aritmética de 12/16 bits sem overflow, regeneração dos marcadores `out_sof/sol/eol/eof` e registro de saída com 1 ciclo de latência. Testbench SystemVerilog (`tb/`), compilação/simulação em VCS e demais ferramentas Synopsys **NÃO EXECUTADOS**.

## Implementação do Testbench, Scoreboard e SVA (Fase 4A — M3 a M7) — 2026-11-06

Foram implementados `tb/tb_kuidamos_pixel_frontend.sv`, `tb/kuidamos_pixel_frontend_sva.sv`, `tb/filelist.f`, `tb/README.md` e `scripts/verification/run_vcs.sh`. O testbench consome os 9 casos oficiais de `vectors/m2/` intactos (validando cabeçalho, sequência de ciclos, ausência de linhas extras e contagem esperada de ciclos por caso para impedir truncamento silencioso) e executa 6 cenários dirigidos complementares exigidos por `docs/spec_v1.md §7` (ROI 1×1 interna descartando `in_sof/in_eof`, vizinhança `T-1/T/T+1`, limite 2047×1 com fator 2 e somas de 12 bits `4094` e `2046+3=2049` nos eixos X e Y, dimensões de entrada zero, recuperação por `in_sof` inesperado no meio do quadro e bolhas em todas as fronteiras), encerrando com `$fatal(1, ...)` em qualquer falha. Em pré-validação local no macOS com `iverilog 13.0` (`-g2012 -DNO_CONCURRENT_SVA`), os 15 cenários (2.618 ciclos) passaram sem avisos de compilação, com código de saída 0, 0 divergências no Scoreboard e 0 violações nos monitores procedurais (2.617 verificações pós-borda); 7 testes negativos em cópias temporárias confirmaram retorno não-zero (`exit code = 1`). As assertions concorrentes (`assert property`) e a execução oficial no **Synopsys VCS** (ambiente Linux CIExpert) permanecem **NÃO EXECUTADAS**.

## Execução da Verificação Funcional M3–M7 no Synopsys VCS (Fase 4B) — 2026-11-08

A regressão completa de verificação funcional e temporal dos marcos **M3 a M7** foi compilada e executada no **Synopsys Chronologic VCS `X-2025.06-SP2_Full64`** (Build Date `Dec 01 2025 00:16:42`, host `ciexpert-rocky8`, contêiner Rocky Linux 8 `x86_64`) por meio do script `./scripts/verification/run_vcs.sh` (com `simv -exitstatus`). Os **15 cenários** (9 cenários de `vectors/m2/` intactos + 6 cenários dirigidos M7, totalizando `2.618` ciclos verificados) passaram integralmente (`cases_passed=15/15 | cycles_checked=2618 | scoreboard_mismatches=0 | sva_errors=0 (sva_checks=2617)`, `OVERALL RESULT: PASS`, código de saída `0`). As 8 assertions concorrentes (`assert property`) em `tb/kuidamos_pixel_frontend_sva.sv` foram compiladas e avaliadas ativamente pelo VCS sem violações; testes negativos em cópias temporárias confirmaram que tanto divergências no Scoreboard quanto violações de `assert property` encerram a simulação no VCS com código de saída diferente de zero (`3`). A evidência detalhada está em `docs/evidencias/M3_M7_verificacao_vcs.md`. O visualizador opcional Synopsys Verdi e as ferramentas de síntese lógica (Design Compiler — M8), DFT (TestMAX — M9) e implementação física (Fusion Compiler — M10) permanecem **NÃO EXECUTADOS**.

## Execução da Síntese Lógica e Análise de Timing M8 no Synopsys Design Compiler (Etapa 5) — 2026-11-09

Foram implementados `constraints/kuidamos_pixel_frontend.sdc`, `scripts/synthesis/dc_synth.tcl`, `scripts/synthesis/run_dc.sh` e `scripts/synthesis/README.md`, e executada a síntese lógica do IP `kuidamos_pixel_frontend` no **Synopsys Design Compiler (`dc_shell` `X-2025.06-SP2`, Build Date `Aug 27, 2025`)** em `ciexpert-rocky8`, utilizando a biblioteca padrão **SAED32 (32/28 nm)** no corner conservador `saed32rvt_ss0p95v125c.db` (`0,95 V`, `125 °C`) e restrição de clock de `100 MHz` (`10,0 ns`). O design foi sintetizado com `compile_ultra -no_autoungroup` sem erros (`exit code = 0`), resultando em `1.256` células folha (`1.141` combinacionais e `115` flip-flops `DFFX1_RVT`, `0` latches inferidos), área de células de `3.523,45` $\mu\text{m}^2$ (`4.376,85` $\mu\text{m}^2$ com interconexão estimada), **fechamento de timing em `10,0 ns` com folga de setup `WNS = +3,21 ns` (`TNS = 0,00 ns`, 39 níveis lógicos no caminho crítico `in_sof -> u_crop_core -> u_resize_nn_core -> out_eof_reg/D`) e folga de hold `WNS = +0,16 ns` (`0` caminhos violados)**, `0` violações de DRC (`max_transition` / `max_capacitance`) e potência total estimada de `267,27` $\mu\text{W}$ (`104,07` $\mu\text{W}$ dinâmica + `163,20` $\mu\text{W}$ leakage a `125 °C`). Os artefatos mapeados (`.ddc`, `.v`, `.sdc`, `.sdf`, `.svf`) e relatórios brutos permanecem em `outputs/synthesis/` (fora do versionamento Git), e a evidência completa está registrada em `docs/evidencias/M8_sintese_dc.md`. As etapas de DFT/Scan (M9) e implementação física (M10) permanecem **NÃO EXECUTADAS**.


## M9 — importação, protocolo e pré-DFT DRC — 2026-11-20

Por autorização do usuário, foi criada a branch `feat/m9-dft-scan` a partir da
`main` limpa, baseline `831812e`, e implementado `scripts/dft/`. Thiago é o
responsável por RTL/síntese e Wagner por DFT, conforme confirmação nesta sessão.
Os artefatos M8 estão versionados desde os commits de 2026-11-10; referências
anteriores a esses artefatos como não versionados são históricas.

Execução real: Fusion Compiler `X-2025.06-SP2` no Rocky Linux 8.10, usando SAED32
RVT `ss0p95v125c` (slow/0,99, 0,95 V, 125 °C), confirmada no PVT efetivo das
1.256 células. Netlist e SDC importados sem edição; 115 `DFFX1_RVT`, todos em
`clk`, nenhuma referência não resolvida. O reset síncrono ativo baixo é mantido
inativo no protocolo, sem alterar o cenário funcional. Células `SDFFX1_RVT` e
`SDFFX2_RVT` estão disponíveis e sem `dont_use`.

**Resultado pré-scan:** `dft_drc -verbose` executado, 115 FFs elegíveis/traced,
zero elementos excluídos e zero violações de scan. O relatório completo registra
94 avisos de build/modelagem (B10=44, B7=45, B8=4, N20=1). `check_design` registra
136 warnings e zero erros; `check_timing -all` registra 1.256 warnings TCK-014.
Os slacks +3,24 ns/+0,16 ns foram calculados com atraso zero de interconexão:
não representam fechamento físico ou pós-scan. Nenhum aviso foi silenciado.

Uma cadeia sem compressão e três portas dedicadas foram configuradas somente
como hipótese na base derivada. A escolha é motivada pelos 115 FFs, clock único
e ausência de clock gating; arquitetura final ainda depende de revisão e preview.
Protocolo de teste de 100 ns, com bordas 45/55 ns. O SPF é preliminar, sem cadeia
implementada. Não se declara cobertura ATPG nem M9 concluído.

Licenças observadas nesta execução: `Fusion-Compiler-NX` e
`Fusion-Compiler-FE-NX`, sem impedimento para pré-DFT. Replacement/insertion e
ATPG ainda requerem validação operacional própria. **Scan replacement, preview,
scan insertion, ATPG e físico NÃO EXECUTADOS**, conforme o limite solicitado.

Evidência: [M9_pre_dft_fc.md](evidencias/M9_pre_dft_fc.md). Execução final local:
`outputs/dft/runs/20261120T133126Z-TW0Czt/`, códigos de saída 0, manifests de
RTL/M8 idênticos antes/depois. Scripts, resumo e quatro casos negativos de
integridade/incompletude foram verificados. Nenhum commit/push realizado.

Próximo passo: revisar B7/B8/B10/N20 e limitações de timing, validar as
precondições de replacement com o FC em uma nova cópia do checkpoint e somente
então executar replacement, novo DRC, preview e insertion em etapa separada.

## M9 — precheck de scan replacement — 2026-11-20

`compile_fusion -check_only -from initial_map -to logic_opto` concluiu no
Fusion Compiler `X-2025.06-SP2`, em uma cópia de `pre_dft_protocol`, com
`compile.seqmap.scan=true`. O FC retornou `1` e o processo saiu com código
`0`. Os 115 DFFs permaneceram intactos. O precheck identificou avisos de
site rows e direção de roteamento, sem bloqueio nesta checagem lógica.
A substituição efetiva fica para uma execução separada. A classificação de
B7, B8, B10 e N20 e os detalhes do teste constam na
[evidência complementar](evidencias/M9_scan_replacement_precheck.md).

## M9 — substituição por células scan — 2026-11-20

O FC substituiu os 115 `DFFX1_RVT` por 115 `SDFFX1_RVT` em uma cópia
de `pre_dft_protocol` com `set_reference -pin_rebind safe`. O mapeamento
direto foi adotado após `initial_map` alterar a lógica combinacional e o
scoreboard rejeitar a sua saída. O candidato manteve 1.141 combinacionais,
o clock funcional de 10 ns e as conexões D/CLK/Q/QN. Com SE/SI em zero,
o VCS aprovou 15/15 cenários e o pré-DFT DRC manteve 115 elementos rastreados,
zero violações de scan e 94 avisos de build/modelagem. A área lógica cresceu
6,64% e o setup reportado caiu de +3,2354 para +3,1652 ns, com atraso zero
na interconexão. A base candidata tem zero cadeias. O próximo passo é
`preview_dft` em uma cópia do candidato.
[Evidência e reprodução](evidencias/M9_scan_replacement_fc.md).

## M9 — preview da cadeia de scan — 2026-11-20

Em uma cópia de `replacement_candidate`, o FC previu uma cadeia sem
compressão de 115 `SDFFX1_RVT`, sem exclusões, de `scan_in` a `scan_out`,
com `scan_enable` ativo em 1 e clock `clk`. O fluxo reaproveitou as células
existentes e liberou explicitamente os 230 pinos SE/SI da constante
`m9_scan_disabled`. As conexões funcionais e o inventário coincidiram antes
e depois. O DRC reportou zero violações no resumo e 324 avisos detalhados,
incluindo 230 B12 esperados pelos pinos liberados. A base continuou sem
cadeias conectadas. A próxima etapa é repetir essa preparação em nova cópia
e validar a conexão efetiva durante a inserção.
[Evidência e reprodução](evidencias/M9_preview_dft_fc.md).

## M9 — inserção e validação da cadeia — 2026-11-20

O Fusion Compiler executou `insert_dft` em uma cópia de
`replacement_candidate`, com proteção temporária das 1.141 células
combinacionais. A cadeia real conecta os 115 SDFFs, sem exclusões, com 114
enlaces internos, as duas pontas e 115 SEs verificados. O DRC pós-scan
registrou zero violações no resumo e 91 avisos detalhados
(B7=44, B8=2, B10=44, N20=1 e B12=0). O VCS passou 15/15 cenários
funcionais e 460 pulsos de shift, incluindo captura e extração. A área
lógica ficou em 3.757,2649 µm². Setup e hold diagnósticos foram +3,1652 ns
e +0,2239 ns. Os artefatos pós-scan foram verificados em conjunto. Revisão
dos avisos e validações de ATPG/físico seguem separadas desta entrega.
[Evidência e reprodução](evidencias/M9_scan_insertion_fc.md).

## M9 — revisão técnica e entrega de scan — 2026-11-20

A revisão conferiu os artefatos exportados, os hashes das entradas e os
resultados VCS já gravados. B7, B8 e B10 não afetam a cadeia. N20 ocorre no
UDP gerado para `SDFFX1_RVT`, na borda de subida com SE desconhecido.
O aviso não impediu o scan validado com SE definido. Seu efeito sobre
ATPG permanece em aberto. M9 fica concluído no escopo de inserção e
validação lógica de scan. M10, análise temporal física e ATPG ficam
pendentes em seus escopos. [Revisão e rastreabilidade](evidencias/M9_resultado_final.md).

## M10 — preparação física — 2026-11-20

O PR #2 integrou o M9. A branch local `feat/m10-physical-design` parte
desse merge. O FC abriu uma cópia de `scan_inserted`, validou o handoff
da cadeia e obteve checkout `Fusion-Compiler-BE-NX`. O precheck de
floorplan terminou com zero erros e 139 avisos estruturais. A SAED32
forneceu site, metais, vias e RC; a preparação confirmou a convenção de
direções das camadas e o limite M9. O floorplan exploratório é a próxima
execução. Definir PG físico, completar MMMC de teste e validar hold de
shift antes da otimização. Floorplan, placement, CTS e routing ainda não
foram executados. [Evidência M10](evidencias/M10_preparacao_physical.md).

## M10 — floorplan inicial — 2026-11-24

O FC salvou e reabriu `floorplan_initial`, derivado de `scan_inserted`.
O core mede 86,488 × 86,944 µm, com utilização calculada de 49,9662%,
margem de 6,688 µm e 52 site rows verificadas. As 126 portas receberam
restrições de borda e camada. A conectividade dos 115 SDFFs foi
preservada. As checagens reportaram zero erros, com os avisos
residuais documentados. O próximo passo é power planning e validação
de PG/STA antes de placement. [Evidência](evidencias/M10_floorplan_inicial.md).

## M10 — power planning inicial — 2026-11-24

O FC salvou e reabriu `powerplan_initial` com dois anéis M7/M8,
24 straps M5/M6, 53 rails M1, 1.766 vias e quatro terminais M7.
PG DRC registrou zero erros e cada rede ficou contínua, sem
objetos flutuantes. As 52 rows e a cadeia de 115 SDFFs foram
preservadas. A conexão física por célula depende de placement.
Antes de aceitar placement, definir a política de células físicas e
completar os cenários de shift e captura.
[Evidência](evidencias/M10_power_planning.md).

## M10 — pré-verificação de placement — 2026-11-24

A análise confirmou `DCAP_RVT` como endcap e encontrou ties e fillers.
A NDM RVT não apresentou taps dedicados nem views de layout para
demonstrar contatos integrados. A política de tap e a orientação de
endcaps continuam pendentes com a referência tecnológica. Placement
não foi acionado. O FC ensaiou em memória os modos funcional, shift
e captura estática em dois corners. Cobertura de I/O de teste e
sequência de captura permanecem incompletas.
[Evidência](evidencias/M10_placement_inicial.md).

## M10 — placement exploratório bloqueado no PG DRC — 2026-11-24

Em cópia da rede PG, o FC posicionou e legalizou as 1.256 células,
com zero sobreposições. A malha continuou conectada a todos os pinos
PG checados, mas o DRC colocado reportou 5.892 erros de espaçamento
em M1. Os rails de 0,152 µm aparecem diretamente em 5.399 ocorrências.
A tentativa mantém a cadeia de 115 SDFFs e os 52 sites rows. Corrigir
a compatibilidade célula–rail em base derivada e repetir a verificação
antes de CTS. A política de tap e endcap segue pendente para signoff.
[Evidência](evidencias/M10_placement_inicial.md#segunda-execução--placement-exploratório).

## M10 — correção M1 e placement validado — 2026-11-24

Em cópia do power plan, os 53 rails M1 foram reduzidos de 0,152
para 0,060 µm, com eixos, malha superior e 1.766 vias preservados.
A nova colocação legalizou as 1.256 células, com PG DRC zero e
contato físico de todos os pinos VDD/VSS. As 52 rows e a cadeia
de 115 SDFFs conferiram. `powerplan_corrected` e `placement_initial`
foram salvos e reabertos. Liberada a preparação de CTS exploratório,
com acesso a pinos, DRVs, MMMC de teste e política de taps/endcaps
pendentes. [Evidência](evidencias/M10_correcao_pg_placement.md).

## M10 — pinos e CTS exploratório — 2026-11-24

Foram validadas 126 portas em M3/M4, com zero violações no check de pinos.
O ensaio inicial de CTS preservava 115 cargas diretamente na porta
ideal. Foi escolhido um driver RVT na raiz para distribuir a carga com
buffers internos. A topologia de cinco buffers e 115 sinks passou nos
checks de legalização, PG e scan. A ordem M9 conferiu, e as simulações
VCS passaram 15/15 cenários funcionais e 460 pulsos de shift. O checkpoint
`cts_initial` foi reaberto. O hold funcional fast de +0,0644 ns e os
DRVs remanescentes orientam a preparação do routing. A cobertura MMMC,
os parasitas pós-route, taps/endcaps, latch-up, IR/EM e signoff físico
permanecem pendentes. [Evidência](evidencias/M10_cts_inicial.md)

## M10 — routing exploratório e extração — 2026-11-24

A topologia de CTS foi roteada em seis redes. O fluxo de sinais
roteou 1.485 das 1.487 redes lógicas, com duas entradas sem cargas,
zero opens, zero DRC interno e zero PG DRC. O `route_opt` preservou
os enlaces diretos protegidos e o ECO trocou nove SDFFs pela variante
X2 sem alterar sua ordem. A regressão funcional VCS passou 15/15
cenários e o shift verificou 460 pulsos. O fluxo extraiu quatro SPEFs
Cmin/Cmax, reabriu `routing_initial` e confirmou o handoff. Permanecem
duas violações de transição e quatro de capacitância por cenário,
limites de MMMC e de anotação SDF, ATPG, taps/endcaps, latch-up,
IR/EM e signoff independente. [Evidência](evidencias/M10_routing_inicial.md)

## M10 — fechamento acadêmico — 2026-11-25

O ECO final zerou transição e capacitância nos seis cenários, com
zero opens, DRC interno e PG DRC. A topologia e geometria da árvore
de clock e a ordem dos 115 SDFFs conferiram. O VCS passou 15/15
cenários e 460 pulsos de shift sobre a netlist final. A estimativa
pós-route com SAIF foi 358,3551 µW a 0,95 V e 125 °C. O
`physical_final` foi reaberto e os artefatos têm hashes registrados.
O escopo acadêmico de M10 foi atendido. Permanecem pendentes a
regressão temporal com anotação SDF completa, ATPG, MMMC integral
de teste, células físicas de signoff, latch-up, antena, IR/EM e
verificação independente. [Resultado final e reprodução](evidencias/M10_resultado_final.md)

## M11 — planejamento da documentação final — 2026-11-25

O M10 foi integrado pelo PR #3. O merge `3fb7875` é a base da
branch local `docs/m11-final-documentation`. O M11 começou com o
inventário da documentação, a matriz de requisitos oficiais e
o roteiro dos 13 capítulos. O recorte do resize V1 ainda requer
registro de validação do professor. O experimento de imagem real
tem evidência no Golden Model e a regressão RTL registrada usa
estímulos sintéticos. Permanecem a redação, o manual consolidado
e a revisão dos responsáveis. [Matriz](m11/matriz_rastreabilidade.md) · [Plano do relatório](m11/plano_relatorio_final.md)

### Demonstração complementar e versão 0.1 — 2026-11-25

O caso de imagem real passou no RTL e na netlist de `physical_final`.
Cada execução comparou 5.035 pixels, com zero divergências de valor,
ordem ou marcador. A captura do DUT gerou a imagem reconstruída e
o mapa de diferenças. Os comparativos fotográficos ficaram locais
porque a autoria e a licença não constam das fontes do repositório.
O relatório de 13 capítulos, a matriz atualizada e o manual estão
prontos para revisão humana. A validação do recorte de resize pelo
professor permanece pendente. [Evidência VCS](evidencias/M11_imagem_real_vcs.md) · [Relatório 0.1](m11/relatorio_tecnico_final.md)
