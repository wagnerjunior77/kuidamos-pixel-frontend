# Registro de decisões e pendências — 6C

Atualização inicial: 2026-10-28. **Este arquivo registra o estado do projeto, não inventa aprovação do professor.**

## Convenção de status
- **OFICIAL (PDF):** declarado no documento final enviado.
- **PROPOSTO:** sugestão de engenharia para a primeira versão, requer aceitação dos responsáveis.
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

## Sugestões não aprovadas — validar com Wagner e Thiago

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
2. Qual é a dimensão máxima da imagem de entrada (por exemplo, apenas testes pequenos, 640×480, outra)? Não impor uma resolução sem aprovação.
3. Crop terá bypass? Os parâmetros serão travados em SOF? O que ocorre em retângulo inválido?
4. O fluxo terá `ready` para backpressure ou apenas pixels válidos que devem ser aceitos? Como tratar gaps em `pixel_valid`?
5. Quais marcadores (SOF/EOL/EOF) exatamente, sua polaridade, relação com `valid` e o que acontece quando crop/resize descartam o último pixel de uma linha?
6. Como os dados/marcadores são encaminhados com latência variável ou fixa? Qual formato de arquivos de vetores?
7. Qual é a máquina Linux de Synopsys, versões instaladas, licenças, PDK e bibliotecas disponíveis? Documentar evidência, não suposição.
8. Quais entregáveis esperados além do mínimo do PDF (ATPG/pattern sim)?

## Diário de execução (preencher, não supor)

| Data | Mudança/decisão | Responsável | Evidência/arquivo | Status |
|---|---|---|---|---|
| 2026-10-28 | Documentos de orientação para início do 6C preparados a partir do PDF oficial | Assistente | `AGENTS.md`, `docs/CONTEXTO_TECNICO_6C.md` | Documentação inicial |


## Revisão técnica V1 — 2026-10-28

O histórico acima permanece como registro inicial; as propostas seguintes detalham e substituem apenas as sugestões genéricas para fins de revisão, sem constituir aprovação. Fonte: PDF oficial §§6.2–6.9, confrontado diretamente; `pre-planejamento.md` ausente. Evidência documental: `docs/spec_v1.md` e `docs/plano_de_execucao.md`. Nenhum teste funcional/EDA foi executado nesta revisão.

| Tema e opções | Recomendação — status | Motivação e riscos / revisão |
|---|---|---|
| Resolução: 640×480, 2047×2047 ou outro limite | 2047 por eixo, dimensões e coordenadas em 11 bits — **PROPOSTO — AGUARDANDO APROVAÇÃO** | Limite simples sem assumir necessidade de aplicação; somas em 12 bits; custo e timing desconhecidos. Thiago valida interface/limite, Wagner avalia implicações DFT. |
| Crop: sempre ativo com ROI integral ou bypass dedicado | `crop_enable`, ROI ignorada no bypass — **PROPOSTO — AGUARDANDO APROVAÇÃO** | Prático para quadro integral; não exigido pelo PDF. Thiago revisa. |
| Resize: arbitrário ou subconjunto | Fatores 1 ou 2 independentes por eixo, saída piso, conforme equação do PDF — **PROPOSTO — AGUARDANDO APROVAÇÃO** | Atende diferentes fatores com seleção simples; restringe dimensões configuráveis em relação à proposta conceitual. Confirmar adequação com responsáveis/professor quando necessário. Thiago revisa ímpares e mapeamento. |
| Fluxo: somente valid ou valid/ready | Apenas valid, destino sempre aceita — **PROPOSTO — AGUARDANDO APROVAÇÃO** | Baixa complexidade; integração não tolera backpressure. Thiago valida capacidade do sistema. |
| Reset e flags: síncrono ou assíncrono; 3 ou 4 flags | Reset síncrono ativo baixo e SOF/SOL/EOL/EOF por pixel — **PROPOSTO — AGUARDANDO APROVAÇÃO** | PDF prevê início/fim de linha e quadro; reset síncrono requer clock durante reset; Wagner revisa testabilidade e Thiago protocolo. |
| Latência e pipeline | Registro de saída, 1 ciclo borda a borda — **PROPOSTO — AGUARDANDO APROVAÇÃO** | Simples; caminho combinacional pode violar 10 ns e demandar nova decisão. Thiago revisa, Wagner avalia scan. |
| Configuração | Capturar no SOF, primeiro pixel usa sinais atuais — **PROPOSTO — AGUARDANDO APROVAÇÃO** | Evita mudança no meio do quadro; quadros consecutivos exigem isolar controles em trânsito. Thiago revisa. |
| Inválidos/vazios | Rejeitar quadro e pulsar `cfg_error`, sem pixels ou flags; sem clipping — **PROPOSTO — AGUARDANDO APROVAÇÃO** | Recuperar no próximo SOF; sistema precisa observar erro; não há marcador de quadro vazio. Thiago revisa. |
| Fluxo malformado | Sem detecção completa; SOF inesperado reinicia — **PROPOSTO — AGUARDANDO APROVAÇÃO** | Pode ter saídas parciais já emitidas, consumidor descarta quadro interrompido; especificar responsabilidade do sistema. Thiago revisa. |
| Marcadores | Regenerar quatro flags pelas coordenadas de saída — **PROPOSTO — AGUARDANDO APROVAÇÃO** | EOF de saída pode preceder o de entrada. Scoreboard/SVA verificam inclusive pixels de entrada finais descartados. Thiago revisa. |
| Tecnologia e ferramenta | Identificar no CIExpert — **A DEFINIR** | Não há PDK, biblioteca, licença ou versão confirmados; Wagner verifica DFT e fluxo; físico depende da infraestrutura. |
| ATPG | Extensão condicional — **PROPOSTO — AGUARDANDO APROVAÇÃO** | Não é entrega explicitamente obrigatória em 6C; Wagner verifica expectativa, licença e fluxo. |

### Inventário antes das alterações desta sessão

- Raiz: `AGENTS.md`, `PROMPT_INICIAL_CODEX.md`, `README_COMO_COMECAR.md`, `VERIFIQUE_ARQUIVOS.txt`.
- `docs/`: `CONTEXTO_TECNICO_6C.md`, `DECISOES_E_PENDENCIAS.md`, `referencias/definicao_escopo_grupo_6_oficial.pdf` (20 páginas).
- Não havia `pre-planejamento.md`, RTL, modelo, testbench ou scripts de fluxo no inventário de arquivos. O diretório não é repositório Git; `git status --short` retornou erro, portanto não há baseline Git para diff.
- Nesta sessão criados `docs/spec_v1.md` e `docs/plano_de_execucao.md`; este registro recebeu acréscimos. PDF e demais fontes não foram alterados.

### Revisão bloqueante antes do modelo/RTL

Solicitar aceite conjunto da V1, especialmente limite de resolução, fatores 1/2 com piso e ausência de ready; os demais defaults estão explícitos para revisão conjunta, incluindo reset, flags, latência, erro e bypass. Mudanças necessárias devem ser registradas antes do modelo; início de RTL requer aprovação explícita. O acesso ao CIExpert é pendência para marcos EDA, não para a revisão documental.

| Data | Mudança/decisão | Responsável | Evidência/arquivo | Status |
|---|---|---|---|---|
| 2026-10-28 | Leitura do PDF e proposta de interface, políticas e plano V1 | Codex | `docs/spec_v1.md`, `docs/plano_de_execucao.md` | PROPOSTO — AGUARDANDO APROVAÇÃO; testes EDA NÃO EXECUTADOS |
