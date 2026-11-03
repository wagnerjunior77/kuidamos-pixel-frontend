# Especificação técnica V1 — Grupo 6C

Data inicial: 2026-10-28; atualização: 2026-11-03. **Status: decisões de implementação V1 aprovadas internamente pelo usuário.** A restrição do resize permanece sujeita à validação do professor. Fonte primária: `referencias/definicao_escopo_grupo_6_oficial.pdf`, §§2–3 e 6.2–6.9. A nota `CONTEXTO_TECNICO_6C.md` é apoio, não substitui o PDF.

## 1. Proveniência e escopo

**OFICIAL (PDF):** IP independente, streaming de RGB888 previamente decodificado para pixels de 8 bits; sequência grayscale, crop retangular, resize nearest orientado a redução, threshold com habilitação/bypass; marcadores de início e fim de linha e quadro regenerados. Arquitetura de contadores, comparadores, aritmética inteira e armazenamento limitado, sem framebuffer, RAM externa, macros ou armazenamento completo de linhas na V1. Verificação, síntese, DFT/scan e físico conforme ambiente, com análise inicial de 100 MHz (10 ns), sem garantia de fechamento nem metas fixas de área/potência. Ver PDF §§6.3–6.8.

**Fora do escopo:** detecção ou identificação, IA/inferência/NPU, câmera/sensor, RTSP/RTP/Ethernet/MIPI, H.264/H.265, ISP/RAW/debayer, framebuffer/DRAM, upscale, interpolação bilinear/bicúbica e integração obrigatória entre grupos. 6A é multiplicação matricial; 6B é FFT de áudio.

**DECISÕES INTERNAS V1:** escolhas de interface, limites e políticas abaixo foram aprovadas pelo usuário em 2026-11-03. O PDF não exige bypass de crop, fator 2 nem resolução máxima específica. A restrição a fatores 1 e 2 é escolha de escopo da V1, sujeita à validação do professor; não é limitação expressa pelo PDF. A microarquitetura e a latência inicial permanecem sujeitas aos resultados de timing.

```text
RGB888 + marcadores -> grayscale -> crop -> resize NN -> threshold -> 8 bits + marcadores
                              controle de coordenadas e configuração por quadro
```

## 2. Interface V1

Todos os sinais são síncronos à borda de subida de `clk`, dados unsigned. Um bit tem largura 1. Não há `ready`; fonte deve respeitar o protocolo e destino aceitar toda saída válida. Não há backpressure nem stalls provocados pelo IP. Larguras são fixas na V1 proposta.

| Sinal | Direção | Largura | Significado |
|---|---|---:|---|
| `clk` | entrada | 1 | clock principal |
| `reset_n` | entrada | 1 | reset ativo baixo, síncrono |
| `pixel_r`, `pixel_g`, `pixel_b` | entrada | 8 cada | componentes RGB |
| `pixel_valid` | entrada | 1 | pixel aceito na borda se reset inativo |
| `in_sof`, `in_sol`, `in_eol`, `in_eof` | entrada | 1 cada | primeiro pixel de quadro, primeiro de linha, último de linha e último de quadro |
| `cfg_in_width`, `cfg_in_height` | entrada | 11 cada | dimensões do quadro de entrada |
| `cfg_crop_enable` | entrada | 1 | 1 seleciona ROI; 0 usa quadro inteiro |
| `cfg_x_start`, `cfg_y_start` | entrada | 11 cada | origem da ROI |
| `cfg_crop_width`, `cfg_crop_height` | entrada | 11 cada | dimensões da ROI |
| `cfg_resize_x2`, `cfg_resize_y2` | entrada | 1 cada | 0 = fator 1; 1 = fator 2 no eixo |
| `cfg_threshold_enable` | entrada | 1 | habilita limiar |
| `cfg_threshold` | entrada | 8 | limiar T |
| `pixel_out` | saída | 8 | resultado, significativo apenas com `pixel_out_valid` |
| `pixel_out_valid` | saída | 1 | resultado válido |
| `out_sof`, `out_sol`, `out_eol`, `out_eof` | saída | 1 cada | marcadores associados ao pixel de saída válido |
| `cfg_error` | saída | 1 | pulso registrado por um ciclo após SOF com configuração inválida |

Não há registradores de software, protocolo de barramento ou valores de configuração internos padrão. O integrador fornece os sinais, inclusive no primeiro SOF. Uma configuração conveniente para começar é crop desabilitado, fatores 1, threshold desabilitado e dimensões válidas fornecidas externamente; não são valores de reset das entradas.

## 3. Configuração e geometria

Largura e altura de entrada em `[1, 2047]`; coordenadas válidas de 0 a 2046. Os campos de 11 bits representam até 2047; 2048 não cabe. Valores 0 em dimensões são inválidos. Esse limite foi aprovado internamente e não é uma resolução fixada pelo PDF nem uma promessa de capacidade física.

- No SOF válido são amostrados atomicamente todos os campos de configuração. O primeiro pixel usa a configuração presente nessa mesma borda. Alterações posteriores nos sinais externos são ignoradas até o próximo SOF; não há exigência de estabilidade externa após a captura. Testar mudanças durante o quadro. Cada pixel em trânsito carrega os controles/metadados necessários: mudança no SOF seguinte não altera saídas anteriores.
- Com crop habilitado: `1 <= crop_width <= in_width`, `1 <= crop_height <= in_height`, `x_start < in_width`, `y_start < in_height`, `x_start + crop_width <= in_width`, `y_start + crop_height <= in_height`. Comparações de soma usam 12 bits unsigned, sem wrap. Limites superiores são exclusivos. Com crop desabilitado, ROI efetiva é `(0,0,in_width,in_height)` e campos de ROI são ignorados, mesmo se inválidos.
- Denote dimensões efetivas da ROI por `W,H`. Para cada eixo, fator `F=1` ou `2`; dimensão de saída é `floor(W/F)` ou `floor(H/F)`. Qualquer configuração que produza largura ou altura de saída zero é inválida, inclusive fator 2 em dimensão 1. Os fatores são independentes; identidade é bypass funcional do resize. Apenas as dimensões decorrentes destes fatores são suportadas; não há campos arbitrários `W_out/H_out` na V1. Esse recorte de interface permanece sujeito à validação do professor.
- Parâmetros inválidos no SOF: emitir `cfg_error` por um ciclo, descartar integralmente o quadro e emitir zero pixels/marcadores para ele. Continuar aceitando a entrada; novo SOF inicia nova avaliação. Não há clipping, divisão por zero, frame vazio sinalizado nem deadlock. Nenhum `cfg_error` indica conclusão de processamento. Reset cancela o estado e o pulso. Frames válidos sempre geram ao menos um pixel.

## 4. Função bit-exata

- **Grayscale [PDF §6.3]:** `Y = floor((77*R + 150*G + 29*B)/256)`. Termos e soma unsigned; produtos e soma estendidos a 16 bits antes de somar; máximo 65280, `Y = soma >> 8`, sem arredondamento ou saturação. Nenhuma operação deve truncar antes do deslocamento.
- **Crop [PDF §6.3]:** manter `x_start <= x < x_start + crop_width` e `y_start <= y < y_start + crop_height`; coordenadas relativas são `u=x-x_start`, `v=y-y_start`. Em bypass `u=x`, `v=y`.
- **Resize [PDF §6.3; conjunto V1]:** `x_src=floor(x_out*W/W_out)`, `y_src=floor(y_out*H/H_out)`, com dimensões após crop. Se fator 1, selecionar todas as coordenadas; se fator 2, selecionar `floor(k*N/floor(N/2))` para `k=0..floor(N/2)-1`. Para fator 2, os índices selecionados são pares a partir de zero, limitados ao número de saídas: N=5 produz `0,2`, N=7 produz `0,2,4` e N=3 produz `0`; esta propriedade é específica de fator 2 com piso. Os eixos são independentes, sem repetição, interpolação ou framebuffer. Para este conjunto a regra equivale a selecionar coordenadas pares até `2*(floor(N/2)-1)`; a última coordenada ímpar e, em N ímpar, a última coordenada par também são descartadas. Testes devem verificar diretamente a fórmula, não apenas a paridade.
- **Threshold [PDF §6.3]:** se habilitado, resultado `255` quando `Y >= T`, senão `0`; desabilitado mantém `Y` de 8 bits. `T=0` produz 255 para todo pixel, `T=255` só para Y=255.

Exemplos: vermelho `(255,0,0)` — 76, verde → 149, azul → 28, branco → 255. Entrada 8×6 com ROI `(2,1,5,3)` e fatores (2,2): saída 2×1; coordenadas relativas X=[0,2], Y=[0], absolutas (2,1),(4,1). Com `T=76`, Y=76 → 255 e Y=75 → 0. Para 1×1, todos os quatro marcadores de saída são 1 no mesmo pixel.

## 5. Contrato temporal e recuperação

Meta inicial de latência: entrada é amostrada na borda `n`; se selecionada, resultado e marcadores são registrados imediatamente após essa borda e estão disponíveis durante o ciclo seguinte, sendo amostrados pelo consumidor na borda `n+1`. Assim a latência de transferência borda a borda é **1 ciclo**; descartar entrada gera `pixel_out_valid=0` no ciclo correspondente. O caminho combinacional pode não fechar 10 ns; eventual pipeline adicional exige atualizar e documentar o contrato e os testes antes da alteração. No SOF a lógica usa configuração corrente validada, sem usar por engano a configuração registrada do quadro anterior. Nenhuma bolha ou descarte altera a latência dos pixels selecionados.

- Com `reset_n=0` em uma borda, limpar estado, contadores, valid, marcadores e `cfg_error` imediatamente após essa borda; nenhuma transferência de entrada ou saída ocorre nessa borda, mesmo se `valid` estiver alto. Dados de saída inválidos são zero; após reset aguardar SOF válido. Reset entre bordas não tem efeito até a próxima borda. Reset interrompe o quadro e descarta pixels ainda não transferidos; após reset a fonte reinicia em SOF.
- `pixel_valid=1` aceita exatamente um pixel por borda, até um por ciclo; `pixel_valid=0` é bolha e congela coordenadas e estado de quadro. Marcadores de entrada devem ser zero quando `pixel_valid=0`. Marcadores de saída são zero quando `pixel_out_valid=0`; `pixel_out` é zero nesse caso. Não existe stall: a fonte pode inserir bolhas, mas não pode exigir que o destino pare.
- Em quadros bem formados, ordem raster: (0,0) no canto superior esquerdo, X cresce primeiro; `in_sof` somente em (0,0), `in_sol` em x=0, `in_eol` em x=width-1, `in_eof` em (width-1,height-1). Sinais podem coincidir. Contadores avançam apenas na aceitação válida e conforme dimensões capturadas; não dependem de marcadores para contar. A fonte deve fornecer exatamente width×height pixels e os marcadores corretos. Não há garantia de detecção de todos os erros de protocolo nem saída correta para fluxo malformado. SOF válido inesperado reinicia a captura e o controle para o novo quadro; pixels já emitidos do quadro anterior não são retratados. O sistema deve descartar o quadro incompleto. Quando fora de quadro, pixels sem SOF são ignorados.
- Marcadores de saída são gerados pelas coordenadas de saída dos pixels selecionados: SOF `(0,0)`, SOL `x_out=0`, EOL `x_out=W_out-1`, EOF `(W_out-1,H_out-1)`; só com `pixel_out_valid`. Assim o último pixel emitido pode preceder EOL/EOF de entrada, e a saída pode terminar antes de a entrada terminar. A aceitação de quadros consecutivos e a configuração do próximo quadro não devem corromper o resultado anterior.

## 6. Microarquitetura e limites

Proposta: combinacional grayscale, detecção de ROI, seleção de coordenadas, threshold e geração de marcadores; um registrador de saída para dados/valid/flags e registradores para configuração e controle. Sem FIFO, line buffer ou multiplicador/divisor genérico por pixel. Para fator 2 usar comparação de coordenadas pares com limite `2*floor(N/2)`; fator 1 passa todas. Contadores de entrada X/Y de 11 bits cobrem 0..2046; dimensões/índices de saída também 11 bits. Cálculos de limites, multiplicação por 2 e comparações são estendidos para 12 bits antes de operar; condições de último pixel evitam incremento além do limite. Testar explicitamente 2047 e somas fora do limite. Para 2047, fator 2 gera 1023 pixels com índices 0..2044 passo 2. O ganho de simplicidade deve ser confirmado em síntese, não presumido.

Conferência de limites: o maior valor representável em cada campo de 11 bits é 2047; portanto até uma soma inválida de origem e tamanho pode alcançar `2047+2047=4094`, representável em 12 bits unsigned. Para N ímpar `N=2m+1`, fator 2 resulta em `N_out=m` e `floor(k*N/N_out)=2k` para `0<=k<m`; nenhum índice é duplicado ou ultrapassa `N-1`. Para saída válida de dimensões `W_out×H_out`, há exatamente um SOF e um EOF por quadro e um SOL e um EOL por linha; as flags podem coincidir no mesmo pixel.

## 7. Verificação e aceite

Testes obrigatórios propostos: matrizes 4×4, 5×3, 8×8, 16×16; preto/branco/primárias/aleatórios com seed; crop total, centro, bordas e 1×1, bypass e ROI inválida; fatores (1,1), (2,1), (1,2), (2,2), dimensões pares/ímpares e limite 2047; T=0/255, igualdade e T±1, bypass; bolhas em todas as posições, frames consecutivos, mudança de configuração em quadro, reset no fluxo, SOF de recuperação; RGB com primeiro/último pixel de entrada descartado; PNG reais complementares.

O Golden Model independente usa inteiros e índices explícitos da equação geral; não tomar OpenCV como referência bit-exata sem comparação. Para cada quadro válido, scoreboard deve conferir número, ordem, valor e os quatro marcadores em cada pixel, ausência de pixels extras e de flags sem valid; conferir também latência, bolhas, reset, erro e quadros inválidos. SVA cobrem reset, validade, coordenadas e sincronismo, além da estabilidade **dos registradores capturados**, não da configuração externa. Aceite: todos os cenários obrigatórios passam com logs reprodutíveis e sem violações não justificadas; RTL sintetiza sem erros impeditivos e estrutura incompatível. 100 MHz é restrição de análise e só será considerado atendido com relatório. DFT/físico dependem do ambiente; ausência é registrada, nunca simulada como sucesso.
