# Evidência de execução — Verificação Funcional RTL M3–M7 (Synopsys VCS)

Data: 2026-11-08. Execução realizada no ambiente Linux `ciexpert-rocky8` (Rocky Linux 8 `x86_64`, contêiner `rocky8-synopsys` na VM Lima `synopsys`) com **Synopsys Chronologic VCS `X-2025.06-SP2_Full64`** (Build Date `Dec 01 2025 00:16:42`).

## 1. Ambiente e Versão da Ferramenta

Saída de `vcs -full64 -ID` (registrada em `outputs/vcs/vcs_version.txt`, fora do versionamento conforme `.gitignore`):

```text
vcs script version : X-2025.06
machine name = ciexpert-rocky8
machine type = linux64
machine os = Linux 7.0.0-42-generic
Compiler version = VCS X-2025.06-SP2_Full64
VCS Build Date = Dec 01 2025 00:16:42
```

> Observação: o aviso `Warning-[LINX_KRNL] Unsupported Linux kernel` é emitido pelo wrapper do VCS devido à versão do kernel da máquina virtual hospedeira (`7.0.0-42-generic`) e não afeta a compilação, linkagem ou execução da simulação `simv`.

## 2. Comandos Executados

Na raiz do repositório (`/Users/thigs/Documents/synopsys/kuidamos-pixel-frontend` montado no contêiner `rocky8-synopsys`):

```bash
./scripts/verification/run_vcs.sh
```

O script executa internamente os dois passos abaixo:

1. **Compilação e elaboração SystemVerilog (`rtl/` + `tb/` + SVA concorrente):**
   ```bash
   vcs -full64 -sverilog \
       -timescale=1ns/1ps \
       -debug_access+all \
       -Mdir="outputs/vcs/csrc" \
       -f tb/filelist.f \
       -top tb_kuidamos_pixel_frontend \
       -o "outputs/vcs/simv" \
       -l "outputs/vcs/vcs_compile.log"
   ```
   - Arquivos compilados: `rtl/grayscale_core.sv`, `rtl/crop_core.sv`, `rtl/resize_nn_core.sv`, `rtl/threshold_core.sv`, `rtl/kuidamos_pixel_frontend.sv`, `tb/kuidamos_pixel_frontend_sva.sv` (com as 8 propriedades concorrentes `assert property` ativas) e `tb/tb_kuidamos_pixel_frontend.sv`.
   - Tempo de compilação reportado pelo VCS: `CPU time: 1.690 seconds to compile + 1.198 seconds to elab + .658 seconds to link`.
   - Código de saída da compilação: `0` (sem erros de sintaxe ou elaboração).

2. **Simulação da regressão completa (Suíte 1: vetores M2 + Suíte 2: casos dirigidos M7):**
   ```bash
   outputs/vcs/simv \
       -exitstatus \
       +VECTOR_DIR=vectors/m2 \
       -k "outputs/vcs/ucli.key" \
       -l "outputs/vcs/vcs_sim.log"
   ```
   - A flag `-exitstatus` garante que qualquer chamada a `$fatal` ou `$error` (do Scoreboard ou das assertions SVA) propague código de retorno diferente de zero para o processo no sistema operacional.
   - Código de saída da simulação: `0`.

## 3. Saída Observada da Simulação (`outputs/vcs/vcs_sim.log`)

```text
Command: /Users/thigs/Documents/synopsys/kuidamos-pixel-frontend/outputs/vcs/simv -exitstatus +VECTOR_DIR=vectors/m2 -k outputs/vcs/ucli.key -l outputs/vcs/vcs_sim.log
Chronologic VCS simulator copyright 1991-2025
Contains Synopsys proprietary information.
Compiler version X-2025.06-SP2_Full64; Runtime version X-2025.06-SP2_Full64;  Nov  8 09:05 2026
====================================================================================
 KUIDAMOS Pixel Front-End (Group 6C) — Functional Verification & Scoreboard (M3–M7)
====================================================================================
--- [Suite 1] Official M2 Vector Scenarios (vectors/m2) ---
[PASS] 01_minimo_1x1                        | cycles=   3 in_valid=   1 out_reg=   1 out_cons=   1 cfg_err=0
[PASS] 02_primarias_4x4                     | cycles=  18 in_valid=  16 out_reg=  16 out_cons=  16 cfg_err=0
[PASS] 03_centro_f12_t0                     | cycles=  66 in_valid=  64 out_reg=   8 out_cons=   8 cfg_err=0
[PASS] 04_borda_f21_t255                    | cycles=  66 in_valid=  64 out_reg=   8 out_cons=   8 cfg_err=0
[PASS] 05_impar_f22_t128_bolhas             | cycles=  22 in_valid=  15 out_reg=   2 out_cons=   2 cfg_err=0
[PASS] 06_aleatorio_16x16                   | cycles= 258 in_valid= 256 out_reg= 256 out_cons= 256 cfg_err=0
[PASS] 07_config_e_quadros_consecutivos     | cycles=  34 in_valid=  32 out_reg=  32 out_cons=  32 cfg_err=0
[PASS] 08_reset_e_recuperacao               | cycles=  35 in_valid=  32 out_reg=  19 out_cons=  18 cfg_err=0
[PASS] 09_invalidos_e_recuperacao           | cycles=  20 in_valid=  18 out_reg=   1 out_cons=   1 cfg_err=2
--- [Suite 2] Directed M7 Edge-Case Scenarios (docs/spec_v1.md §7) ---
[PASS] m7_01_roi_1x1_discard_first_last     | cycles=  18 in_valid=  16 out_reg=   1 out_cons=   1 cfg_err=0
[PASS] m7_02_threshold_neighborhood         | cycles=   5 in_valid=   3 out_reg=   3 out_cons=   3 cfg_err=0
[PASS] m7_03_max_dim_2047_and_12bit_sum     | cycles=2052 in_valid=2050 out_reg=1023 out_cons=1023 cfg_err=3
[PASS] m7_04_zero_input_dims                | cycles=   5 in_valid=   3 out_reg=   1 out_cons=   1 cfg_err=2
[PASS] m7_05_unexpected_sof_recovery        | cycles=   6 in_valid=   4 out_reg=   4 out_cons=   4 cfg_err=0
[PASS] m7_06_bubbles_all_positions          | cycles=  10 in_valid=   4 out_reg=   4 out_cons=   4 cfg_err=0
====================================================================================
 SUMMARY: cases_passed=15/15 | cycles_checked=2618 | scoreboard_mismatches=0 | sva_errors=0 (sva_checks=2617)
====================================================================================
OVERALL RESULT: PASS
           V C S   S i m u l a t i o n   R e p o r t 
Time: 26176000 ps
```

## 4. Resumo Consolidado por Marco e Cenário

| Suíte | Caso | Escopo verificado (M3–M7) | Ciclos | Entradas válidas | Saídas reg. / cons. | Pulsos `cfg_error` | Resultado VCS |
|---|---|---|---:|---:|---:|---:|---|
| M2 | `01_minimo_1x1` | M3/M6: quadro mínimo `1×1`, bypass, os 4 marcadores simultâneos | 3 | 1 | 1 / 1 | 0 | **PASS** |
| M2 | `02_primarias_4x4` | M3: exatidão `floor((77R+150G+29B)/256)` em preto, branco, primárias e tons | 18 | 16 | 16 / 16 | 0 | **PASS** |
| M2 | `03_centro_f12_t0` | M4/M5/M6: ROI central `4×4` em `8×8`, fatores `(1,2)`, `T=0` | 66 | 64 | 8 / 8 | 0 | **PASS** |
| M2 | `04_borda_f21_t255` | M4/M5/M6: ROI no canto inferior direito, fatores `(2,1)`, `T=255` | 66 | 64 | 8 / 8 | 0 | **PASS** |
| M2 | `05_impar_f22_t128_bolhas` | M5/M6/M7: dimensão ímpar `5×3`, fatores `(2,2)`, `T=128`, bolhas | 22 | 15 | 2 / 2 | 0 | **PASS** |
| M2 | `06_aleatorio_16x16` | M3/M6/M7: `16×16` aleatório (`seed=606`), bypass de crop/resize/threshold | 258 | 256 | 256 / 256 | 0 | **PASS** |
| M2 | `07_config_e_quadros_consecutivos` | M6/M7: dois quadros `4×4` consecutivos sem bolha; imutabilidade de config no quadro | 34 | 32 | 32 / 32 | 0 | **PASS** |
| M2 | `08_reset_e_recuperacao` | M3/M7: reset síncrono no meio do quadro, cancelamento de consumo e espera por novo `in_sof` | 35 | 32 | 19 / 18 | 0 | **PASS** |
| M2 | `09_invalidos_e_recuperacao` | M4/M5/M7: ROI fora da imagem e saída zero (`1×1` com fator 2), pulso `cfg_error` e recuperação | 20 | 18 | 1 / 1 | 2 | **PASS** |
| M7 | `m7_01_roi_1x1_discard_first_last` | M4/M7: ROI `1×1` interna descartando `(0,0)` e `(3,3)` da entrada e regenerando `SOF/SOL/EOL/EOF=1` | 18 | 16 | 1 / 1 | 0 | **PASS** |
| M7 | `m7_02_threshold_neighborhood` | M6/M7: vizinhança exata `T-1 -> 0`, `T -> 255`, `T+1 -> 255` | 5 | 3 | 3 / 3 | 0 | **PASS** |
| M7 | `m7_03_max_dim_2047_and_12bit_sum` | M4/M5/M7: somas de 12 bits (`2047+2047=4094`, `2046+3=2049` em X e Y) e quadro `2047×1` com fator 2 (`1023` saídas) | 2052 | 2050 | 1023 / 1023 | 3 | **PASS** |
| M7 | `m7_04_zero_input_dims` | M4/M7: rejeição de `cfg_in_width=0` e `cfg_in_height=0` com `cfg_error=1` e recuperação | 5 | 3 | 1 / 1 | 2 | **PASS** |
| M7 | `m7_05_unexpected_sof_recovery` | M7: recuperação por `in_sof=1` inesperado no meio de quadro ativo sem `reset_n` | 6 | 4 | 4 / 4 | 0 | **PASS** |
| M7 | `m7_06_bubbles_all_positions` | M7: bolhas (`pixel_valid=0`) antes/após `in_sof`, após `in_eol` e antes/após `in_eof` | 10 | 4 | 4 / 4 | 0 | **PASS** |
| **Total** | **15 cenários** | **Cobertura funcional e temporal M3–M7** | **2.618** | **2.562** | **1.379 / 1.378** | **7** | **15/15 PASS** |

## 5. Propriedades SVA Verificadas no VCS e Testes com Injeção de Falhas

As 8 assertions concorrentes (`assert property` em [`tb/kuidamos_pixel_frontend_sva.sv`](../../tb/kuidamos_pixel_frontend_sva.sv)) e seus monitores procedurais equivalentes permaneceram ativos durante todos os `2.618` ciclos (`2.617` verificações pós-borda, `0` violações):

1. `a_reset_clears_all`: `reset_n=0` limpa `pixel_out_valid`, `pixel_out`, `out_sof/sol/eol/eof`, `cfg_error`, `frame_active_q` e `(x_q, y_q)`.
2. `a_invalid_out_zero`: `pixel_out_valid=0` implica `pixel_out=0` e `out_sof=out_sol=out_eol=out_eof=0`.
3. `a_sof_implies_sol`: `out_sof=1` implica `pixel_out_valid=1` e `out_sol=1`.
4. `a_eof_implies_eol`: `out_eof=1` implica `pixel_out_valid=1` e `out_eol=1`.
5. `a_cfg_error_exclusivity`: `cfg_error=1` implica `pixel_out_valid=0`, `frame_active_q=0` e ocorrência de `reset_n && pixel_valid && in_sof` na borda anterior.
6. `a_bubble_freeze`: bolha de entrada (`reset_n=1 && pixel_valid=0`) mantém estáveis `frame_active_q`, `x_q` e `y_q` e produz `pixel_out_valid=0` e `cfg_error=0`.
7. `a_cfg_stable_in_frame`: registradores `cfg_*_q` permanecem constantes durante todo o quadro ativo até novo `in_sof` ou `reset_n=0`.
8. `a_coord_bounds`: quando `frame_active_q=1`, valem `x_q < cfg_in_width_q` e `y_q < cfg_in_height_q`.

Foram também executados testes negativos em cópias temporárias (`/tmp`) no próprio **Synopsys VCS**:
- **Mutação no comparador de threshold (`>=` para `>`):** detectada pelo Scoreboard em `m7_02_threshold_neighborhood`, encerrando com `$fatal(1, ...)` e código de saída `3` (`simv -exitstatus`).
- **Mutação de estabilidade de configuração interna (`cfg_threshold_q` alterado durante `frame_active_q=1`):** detectada imediatamente pela assertion concorrente `[SVA] a_cfg_stable_in_frame failed` e pelo monitor procedural no VCS, encerrando com código de saída `3`.
- **Geração de formas de onda VCD (`+DUMP_VCD +VCD_FILE=outputs/vcs/waves.vcd`):** executada no VCS com geração do arquivo `outputs/vcs/waves.vcd` (`1,9 MiB`, mantido fora do versionamento).

## 6. Limitações e Pendências

- **Integridade dos vetores M2:** os 28 arquivos em `vectors/m2/` permaneceram intactos byte a byte (`python3 -X utf8 -m model.m2_vectors --output-dir vectors/m2 --check`).
- **Synopsys Verdi:** o visualizador gráfico opcional Verdi não está instalado em `/opt/synopsys` no contêiner atual; a inspeção de ondas é suportada via geração de arquivo `.vcd` (`+DUMP_VCD`).
- **Etapas subsequentes (M8–M10):** esta evidência comprova apenas a verificação funcional e temporal do RTL no **Synopsys VCS** (M3–M7). Síntese lógica (Design Compiler — M8), DFT/Scan (TestMAX DFT — M9) e implementação física (Fusion Compiler — M10) permanecem **NÃO EXECUTADAS**.

