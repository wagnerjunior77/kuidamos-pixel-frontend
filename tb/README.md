# Verificação Funcional SystemVerilog — Grupo 6C (`tb/`)

Ambiente de verificação funcional para os marcos **M3 a M7** do IP **KUIDAMOS Pixel Front-End**, composto por Testbench auto-verificável, leitor dos vetores M2, Scoreboard ciclo a ciclo, cenários dirigidos complementares de M7 e SystemVerilog Assertions (SVA).

## Arquivos

| Arquivo | Descrição |
| :--- | :--- |
| [`tb_kuidamos_pixel_frontend.sv`](tb_kuidamos_pixel_frontend.sv) | Topo do testbench (`100 MHz` / `10 ns`), driver de estímulos, leitor dos arquivos `.stim.txt` e `.expect.txt` de [`vectors/m2/`](../vectors/m2), Scoreboard ciclo a ciclo e suíte dirigida M7. |
| [`kuidamos_pixel_frontend_sva.sv`](kuidamos_pixel_frontend_sva.sv) | Monitor de propriedades SVA (reset síncrono, saídas inválidas zeradas, consistência `SOF/SOL` e `EOF/EOL`, exclusividade de `cfg_error`, congelamento em bolhas, estabilidade de `cfg_*_q` no quadro e limites de coordenadas). |
| [`filelist.f`](filelist.f) | Lista de compilação completa (`rtl/` + `tb/`) a partir da raiz do repositório. |
| [`../scripts/verification/run_vcs.sh`](../scripts/verification/run_vcs.sh) | Script de compilação e execução da regressão para o **Synopsys VCS**. |

## Cenários Verificados na Regressão

1. **Suíte 1 — Vetores Oficiais M2 (`vectors/m2/`, 9 cenários, 522 ciclos):**
   - `01_minimo_1x1`
   - `02_primarias_4x4`
   - `03_centro_f12_t0`
   - `04_borda_f21_t255`
   - `05_impar_f22_t128_bolhas`
   - `06_aleatorio_16x16`
   - `07_config_e_quadros_consecutivos`
   - `08_reset_e_recuperacao`
   - `09_invalidos_e_recuperacao`
2. **Suíte 2 — Cenários Dirigidos Complementares M7 (`docs/spec_v1.md §7`, 6 cenários, 2.096 ciclos):**
   - `m7_01_roi_1x1_discard_first_last`: ROI `1×1` interna (`x=1, y=1` em quadro `4×4`) descartando o primeiro `(0,0)` e o último `(3,3)` pixel da entrada e regenerando `out_sof=out_sol=out_eol=out_eof=1`.
   - `m7_02_threshold_neighborhood`: vizinhança exata de limiar (`Y = T-1 -> 0`, `Y = T -> 255`, `Y = T+1 -> 255`).
   - `m7_03_max_dim_2047_and_12bit_sum`: rejeição de `x_start=2047, crop_width=2047` (soma `4094`), rejeição de overflow de 12 bits com `x_start < in_width` no eixo horizontal (`in_width=2047, x_start=2046, crop_width=3`, soma `2049` que truncada em 11 bits viraria `1`) e no eixo vertical (`in_height=2047, y_start=2046, crop_height=3`), seguida de quadro válido `2047×1` com `resize_x2=1` gerando exatamente `1023` pixels (`0..2044` passo 2, descartando `2046`).
   - `m7_04_zero_input_dims`: rejeição de `cfg_in_width=0` e `cfg_in_height=0` com pulso `cfg_error=1` e recuperação posterior.
   - `m7_05_unexpected_sof_recovery`: reinício limpo de captura e coordenadas `(0,0)` quando um `in_sof=1` inesperado ocorre no meio de um quadro ativo (sem `reset_n`).
   - `m7_06_bubbles_all_positions`: bolhas (`pixel_valid=0`) antes do `in_sof`, após `in_sof`, após `in_eol`, antes do `in_eof` e após `in_eof`.

## Como Executar

### 1. No servidor Linux CIExpert (Synopsys VCS)

Na raiz do repositório:

```bash
chmod +x scripts/verification/run_vcs.sh
./scripts/verification/run_vcs.sh
```

Argumentos opcionais:
- Executar apenas um caso de `vectors/m2/`:
  ```bash
  SIM_PLUSARGS="+CASE=03_centro_f12_t0" ./scripts/verification/run_vcs.sh
  ```
- Gerar arquivo de ondas `.vcd` (para inspeção no Verdi/GTKWave):
  ```bash
  SIM_PLUSARGS="+DUMP_VCD +VCD_FILE=outputs/vcs/waves.vcd" ./scripts/verification/run_vcs.sh
  ```

### 2. Pré-validação local com Icarus Verilog (opcional antes do VCS)

Para validar localmente o RTL, o Scoreboard e os monitores SVA antes de rodar no servidor Synopsys:

```bash
mkdir -p outputs/local_sim
iverilog -g2012 -DNO_CONCURRENT_SVA -f tb/filelist.f -s tb_kuidamos_pixel_frontend -o outputs/local_sim/simv_iverilog
vvp outputs/local_sim/simv_iverilog
```

> Nota: a execução local com `-DNO_CONCURRENT_SVA` valida os monitores procedurais equivalentes; as assertions concorrentes (`assert property`) e o fluxo oficial de simulação ainda precisam de validação no **Synopsys VCS** no ambiente CIExpert.
