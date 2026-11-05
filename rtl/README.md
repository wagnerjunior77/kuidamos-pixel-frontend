# RTL SystemVerilog — Grupo 6C (`rtl/`)

Implementação sintetizável do IP **KUIDAMOS Pixel Front-End** conforme a especificação [`docs/spec_v1.md`](../docs/spec_v1.md).

## Módulos e Marcos Correspondentes

| Arquivo | Marco | Tipo | Descrição |
| :--- | :---: | :--- | :--- |
| [`grayscale_core.sv`](grayscale_core.sv) | **M3** | Combinacional | Conversão inteira bit-exata `Y = (77*R + 150*G + 29*B) >> 8` em 16 bits unsigned. |
| [`crop_core.sv`](crop_core.sv) | **M4** | Combinacional | Seleção retangular de ROI (`x_start`, `y_start`, `crop_width`, `crop_height`) em 12 bits unsigned com suporte a bypass (`crop_enable = 0`). |
| [`resize_nn_core.sv`](resize_nn_core.sv) | **M5** | Combinacional | Redução espacial Nearest-Neighbor para fatores independentes 1 e 2 (`N_out = floor(N/F)`) e regeneração de marcadores (`out_sof`, `out_sol`, `out_eol`, `out_eof`). |
| [`threshold_core.sv`](threshold_core.sv) | **M6** | Combinacional | Comparação `y_gray >= threshold` (`255` ou `0`) com bypass (`threshold_enable = 0`). |
| [`kuidamos_pixel_frontend.sv`](kuidamos_pixel_frontend.sv) | **M3–M6** | Topo Sequencial | Interface oficial V1, captura e validação atômica de configuração em `in_sof`, pulso `cfg_error`, contadores `(x, y)` e estágio de saída com 1 ciclo de latência. |
| [`filelist.f`](filelist.f) | **M3–M6** | Lista EDA | Ordem de compilação dos arquivos RTL a partir da raiz do repositório. |

## Características de Síntese e DFT

- **Apenas registradores e lógica combinacional:** sem framebuffers, line buffers ou macros de SRAM.
- **Domínio único de clock (`clk`)** na borda de subida e **reset síncrono ativo-baixo (`reset_n`)** em todos os flip-flops.
- **Zero latches inferidos:** blocos `always_comb` atribuem todos os sinais em todos os caminhos.

