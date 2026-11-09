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
