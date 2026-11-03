# AGENTS.md — Instruções permanentes para o Codex | KUIDAMOS / CIExpert / Grupo 6C

> Leia este arquivo **antes de qualquer alteração**. Este repositório implementará exclusivamente o **IP Front-End de Pré-Processamento de Pixels do Grupo 6C**. Português brasileiro nas explicações, documentação e relatórios; nomes de sinais/código em inglês técnico consistente.

## 1. Leitura obrigatória e fontes de verdade

1. `pre-planejamento.md` **se estiver completo e atualizado** com a seção 6C. Se o arquivo estiver ausente, truncado ou tiver só os grupos anteriores, use `docs/referencias/definicao_escopo_grupo_6_oficial.pdf`, cópia integral do PDF de 20 páginas entregue pelo usuário.
2. `docs/CONTEXTO_TECNICO_6C.md`, síntese técnica detalhada do projeto, incluindo decisões pendentes, riscos e plano de trabalho.
3. `docs/DECISOES_E_PENDENCIAS.md`, registro vivo do que foi decidido, do que está aberto e das evidências de validação.
4. Este `AGENTS.md` como instrução de execução. Se houver diferença entre **requisito oficialmente descrito** e **sugestão de engenharia**, não apague a distinção e não transforme sugestões em requisitos. Sinalize conflitos ao usuário.

**Regra de precedência de conteúdo:** documento final aprovado/enviado ao professor > decisões posteriormente confirmadas explicitamente pelos responsáveis > notas e propostas deste repositório > preferências gerais do agente. Quando a especificação for omissa, recomende a solução mais simples e registre que ela está pendente de aprovação.

## 2. Objetivo e escopo estrito

Implementar um IP digital educacional de pré-processamento de imagens em **streaming**; entrada de pixels **RGB888** (R/G/B sem sinal, 8 bits por canal), saída de **8 bits por pixel** e marcadores/sinais de validade de linha/quadro. Ordem funcional de referência:

`RGB888 -> grayscale -> crop -> nearest-neighbor resize (downscaling) -> threshold -> saída`

Operações previstas no documento oficial:
- **Grayscale** por aritmética inteira, valor exato de referência `Y = (77*R + 150*G + 29*B) // 256`, com truncamento para baixo, operandos sem sinal e intermediários sem overflow.
- **Crop** retangular por `x_start`, `y_start`, `crop_width`, `crop_height`; só passam pixels cuja coordenada está na região `[x_start, x_start + width)` × `[y_start, y_start + height)`.
- **Resize nearest-neighbor** com prioridade inicial a **redução de resolução**, seleção/descarte de pixels e linhas, sem interpolação de valores e sem framebuffer completo. Modelo conceitual `x_src=floor(x_out*W_in/W_out)` e `y_src=floor(y_out*H_in/H_out)` aplicado às dimensões **após crop**.
- **Threshold** configurável e com **bypass explicitamente previsto**. Quando habilitado, saída 0 ou 255 segundo `pixel >= T`; caso contrário, preserva o pixel cinza. A saída continua sendo um barramento de 8 bits.

**Não implementar por iniciativa própria:** identificação de placas, rostos ou pessoas; modelos de IA; NPU; CNN; RTSP/RTP; Ethernet; H.264/H.265; MIPI; interface física de câmera; ISP, debayer, balanço de branco; framebuffers completos, DRAM, RAM externa ou macros; integração obrigatória com 6A ou 6B; upscale ou interpolação bilinear/bicúbica.

**Importante:** o grupo 6A faz multiplicação matricial 4×4, o 6B faz FFT para áudio, e o 6C faz front-end de pixels. Os IPs são **independentes**; não pressupor cadeia obrigatória 6C→6B→6A.

## 3. Pessoas e responsabilidades

- Grupo 6C: **Wagner Cutrim Rabelo Junior (DFT)** e **Thiago Fernandes Carvalho de Souza (RTL)**.
- Codex pode implementar arquivos e automação sob supervisão; **não afirmar que validação foi feita sem logs reais**.
- O humano aprova interface, limitações e decisões de arquitetura. Não inferir autorização para mudar o escopo ao executar uma tarefa.

## 4. Primeira sessão do Codex: NÃO começar implementando RTL

A primeira tarefa é **inspecionar** os documentos e a pasta de trabalho, levantar as decisões abertas e produzir a especificação técnica V1 e um plano de entregas. Só então pedir validação do usuário para iniciar RTL. Criar, no máximo, documentação, checklist, esqueleto de diretórios vazio e scripts de diagnóstico **não destrutivos** se solicitado. Não escrever módulos, testbenches ou scripts EDA definitivos na primeira sessão, salvo instrução explícita posterior do usuário.

Obrigatório esclarecer/registrar antes da implementação: dimensões e resolução máxima suportadas; largura dos parâmetros; controle de fluxo (com ou sem `ready`); semântica de SOF/EOL/EOF e latência; reset e aceitação de pixels; semântica e modo bypass do crop; escala(s) de resize, inclusive dimensões ímpares e razões não inteiras; conjunto de configurações válidas; amostragem de parâmetros no início do quadro; tratamento de configuração inválida; marcadores de **saída** reconstruídos sobre pixels efetivamente emitidos; política de quadros vazios; clock inicial e critérios de teste.

## 5. Regras de engenharia e verificação

- Escrever RTL sintetizável em SystemVerilog, sem `#delay`, `$display`/`$fopen` no DUT, sem comportamento indefinido ou latches acidentais. Testbench pode usar construções não sintetizáveis.
- Explicitamente definir largura, signedness, overflow, rounding/truncamento, reset e estabilidade de configuração; não confundir redução de resolução com compressão de dados.
- Preferir arquitetura pequena de contadores, comparadores, registradores e lógica combinacional. **Não adicionar line buffers** sem prova de necessidade para a V1 de downscale por descarte.
- Golden Model independente do RTL em Python/NumPy; preferir operação inteira bit-exata sobre comportamento padrão de OpenCV, que pode ter critérios diferentes de arredondamento/interpolação.
- Testar primeiro matrizes sintéticas pequenas (`4×4`, `5×3`, `8×8`, `16×16`) e casos de borda; depois imagens PNG reais como entradas de teste, sem câmera física.
- Comparar **valores, quantidades, ordem dos pixels e SOF/EOL/EOF**, não só aparência visual. O Scoreboard e SVA devem revelar perdas, duplicações e saída incorreta em ciclos inválidos.
- Evoluir por etapas: pass-through, grayscale, crop, resize, threshold, integração, regressão, síntese, DFT e físico. Cada marco exige evidência reprodutível.
- Alvo **inicial de análise**: 100 MHz (10 ns) segundo o documento oficial, **não garantia de fechamento** nem meta mandatória de potência/área. Reportar o que os relatórios mostrarem.
- Biblioteca tecnológica/PDK: **não especificados oficialmente**. Identificar no ambiente CIExpert; não fixar SAED32/GPDK45 por suposição.

## 6. Ferramentas Synopsys e limites operacionais

- Funcional: VCS; Verdi opcional se instalado.
- Síntese: Design Compiler conforme proposta; alternativa somente se confirmada pelo usuário/ambiente.
- DFT: TestMAX DFT para DRC, `preview_dft` e scan; documentar antes/depois e resultados reais.
- Implementação física: Fusion Compiler (`fc_shell`), quando disponível.
- ATPG stuck-at/transition e pattern simulation: **extensões desejáveis**, não prometidas como requisito oficial de 6C no PDF. Verificar TestMAX ATPG, licença e fluxo antes de planejar execução.
- Nunca inventar licenças, PDK, comandos suportados, paths, cobertura, área, frequência, potência, warnings, logs ou sucesso de ferramenta. Quando indisponível, deixar scripts como rascunho e marcar **NÃO EXECUTADO**.
- Preferir scripts TCL e comandos repetíveis; não incorporar caminhos absolutos pessoais quando se pode usar variáveis de ambiente. Se o Windows é editor e Rocky Linux é executor, detectar e documentar claramente onde cada comando roda.
- Nunca versionar chaves de licença, tokens, arquivos proprietários do PDK, bibliotecas Synopsys ou netlists restritos. Não apagar nem sobrescrever arquivos pessoais e não executar operações destrutivas sem pedido explícito.

## 7. Entregas, manutenção e comunicação

- Manter `docs/DECISOES_E_PENDENCIAS.md` atualizado com status, data, motivação, alternativas, decisão e evidência.
- Escrever orientações precisas para rodar os testes, dependências, versões e resultado esperado.
- Em cada resposta: **(a)** o que foi encontrado/feito, **(b)** arquivos alterados, **(c)** testes realmente executados e seus resultados, **(d)** bloqueios, **(e)** próximo passo concreto.
- Ao concluir tarefa maior, verificar `git diff` e destacar modificações que não deveriam ocorrer; manter mudanças pequenas e reversíveis.
- Se houver contradição ou uma decisão relevante em aberto, trazer uma recomendação concreta e pedir aprovação, em vez de escolher silenciosamente.
