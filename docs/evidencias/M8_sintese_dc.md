# Evidência de execução — Síntese Lógica e Análise de Timing M8 (Synopsys Design Compiler)

Data: 2026-11-09. Execução realizada no ambiente Linux `ciexpert-rocky8` (Rocky Linux 8 `x86_64`, contêiner `rocky8-synopsys` na VM Lima `synopsys`) utilizando o **Synopsys Design Compiler (`dc_shell`) `X-2025.06-SP2`** (Build Date `Aug 27, 2025`) e a biblioteca padrão **Synopsys Educational PDK SAED32 (32/28 nm)**.

## 1. Ambiente, Ferramenta e Biblioteca Tecnológica

- **Ferramenta:** `dc_shell` versão `X-2025.06-SP2 for linux64 - Aug 27, 2025` (`/opt/synopsys/syn/X-2025.06-SP2/bin/dc_shell`).
- **Biblioteca Alvo (`target_library`):** `/opt/synopsys/saed32/DBs/saed32rvt_ss0p95v125c.db` (família Regular-$V_t$, corner **Slow-Slow `0,95 V`, `125 °C`**).
- **Biblioteca Sintética (`synthetic_library`):** `dw_foundation.sldb` (DesignWare Foundation).
- **Unidades da biblioteca (`outputs/synthesis/reports/units.rpt`):**
  - Tempo: `1 ns` (`1.0e-09 s`)
  - Capacitância: `1 fF` (`1.0e-15 F`)
  - Tensão: `1 V`
  - Resistência: `1 MOhm` (`1.0e+06 Ohm`)
  - Área: $\mu\text{m}^2$

## 2. Comandos Executados e Restrições Aplicadas (SDC)

Comando executado na raiz do repositório:

```bash
./scripts/synthesis/run_dc.sh
```

O script resolve `OUT_DIR` e `TARGET_LIB` para caminhos absolutos antes de mudar o diretório de trabalho para `OUT_DIR` e executa `dc_shell -64bit -f scripts/synthesis/dc_synth.tcl -output_log_file "$OUT_DIR/dc_compile.log"` (mantendo a raiz do repositório limpa e os artefatos mapeados fora do versionamento Git, conforme `AGENTS.md`).

Na revisão do script, `bash -n scripts/synthesis/run_dc.sh` passou. Um substituto local do `dc_shell` confirmou a resolução de `OUT_DIR` e `TARGET_LIB` nas quatro combinações de caminhos relativos e absolutos, incluindo nomes com espaços. Em cada caso, o processo encontrou a biblioteca pelo caminho absoluto e gravou o log no diretório esperado. A síntese registrada abaixo corresponde à execução original no Design Compiler.

### Restrições aplicadas ([`constraints/kuidamos_pixel_frontend.sdc`](../../constraints/kuidamos_pixel_frontend.sdc))

| Restrição | Valor aplicado | Justificativa / Referência |
|---|---|---|
| Período de clock (`clk`) | `10,0 ns` (`100 MHz`) | Referência inicial de análise de [`docs/spec_v1.md`](../spec_v1.md) §11 |
| Incerteza de clock (`setup` / `hold`) | `0,20 ns` / `0,05 ns` | Margem para jitter e skew de árvore de clock pré-CTS |
| Transição de clock | `0,10 ns` | Slew nominal de relógio na entrada |
| Atraso externo de entrada (`input_delay` max / min) | `2,00 ns` / `0,20 ns` | 20% do período de clock nas portas de entrada (exceto `clk`) |
| Atraso externo de saída (`output_delay` max / min) | `2,00 ns` / `0,20 ns` | 20% do período de clock em todas as portas de saída |
| Transição máxima de entrada / carga de saída | `0,15 ns` / `0,05 fF` (`set_load 0.05`) | Na biblioteca `saed32rvt_ss0p95v125c.db`, `Time_unit = 1 ns` e `Capacitive_load_unit = 1 fF`; portanto `set_load 0.05` aplica **0,05 fF** em todas as saídas |

## 3. Resumo de Quality of Results (`outputs/synthesis/reports/qor.rpt`)

```text
  Timing Path Group 'clk'
  -----------------------------------
  Levels of Logic:              39.00
  Critical Path Length:          4.56
  Critical Path Slack:           3.21
  Critical Path Clk Period:     10.00
  Total Negative Slack:          0.00
  No. of Violating Paths:        0.00
  Worst Hold Violation:          0.00
  Total Hold Violation:          0.00
  No. of Hold Violations:        0.00
  -----------------------------------

  Cell Count
  -----------------------------------
  Hierarchical Cell Count:          4
  Hierarchical Port Count:        287
  Leaf Cell Count:               1256
  Buf/Inv Cell Count:             266
  Buf Cell Count:                   9
  Inv Cell Count:                 257
  Combinational Cell Count:      1141
  Sequential Cell Count:          115
  Macro Count:                      0
  -----------------------------------

  Design Rules
  -----------------------------------
  Total Number of Nets:          1464
  Nets With Violations:             0
  Max Trans Violations:             0
  Max Cap Violations:               0
  -----------------------------------

  Design  WNS: 0.00  TNS: 0.00  Number of Violating Paths: 0
  Design (Hold)  WNS: 0.00  TNS: 0.00  Number of Violating Paths: 0
```

## 4. Análise de Timing (Setup e Hold em `10,0 ns` / `100 MHz`)

| Métrica | Resultado (`ss0p95v125c`) | Status |
|---|---:|---|
| **Período alvo (`clk`)** | `10,00 ns` (`100,0 MHz`) | Referência V1 |
| **Caminho crítico (Setup — `max`)** | `in_sof` (porta de entrada) $\rightarrow$ `u_crop_core` $\rightarrow$ `u_resize_nn_core` $\rightarrow$ `out_eof_reg/D` (`DFFX1_RVT`) | 39 níveis lógicos |
| **Tempo de chegada de dados (`data arrival time`)** | `6,56 ns` (sendo `2,00 ns` de `input_delay` externo + `4,56 ns` de atraso combinacional interno) | — |
| **Tempo requerido (`data required time`)** | `9,78 ns` (`10,00 ns` $-$ `0,20 ns` uncertainty $-$ `0,02 ns` library setup) | — |
| **Folga de Setup (`Slack` / WNS)** | **`+3,21 ns`** (`TNS = 0,00 ns`, `0` caminhos violados) | **MET** |
| **Caminho crítico (Hold — `min`)** | `cfg_in_height_q_reg_10_/CLK` $\rightarrow$ `cfg_in_height_q_reg_10_/D` (`DFFX1_RVT`) | — |
| **Folga mínima de Hold (`Slack` / WNS Hold)** | **`+0,16 ns`** (`data arrival = 0,22 ns`, `data required = 0,06 ns`, `0` violações) | **MET** |
| **Estimativa apenas para o caminho observado (mantendo `input_delay = 2,00 ns` fixo)** | $10,00 - 3,21 = 6,79\text{ ns}$ ($\approx 147,3\text{ MHz}$) | Estimativa do caminho observado (ver nota abaixo) |

> **Nota sobre a estimativa de frequência máxima:** O valor de $6,79\text{ ns}$ ($\approx 147,3\text{ MHz}$) corresponde exclusivamente à subtração direta da folga observada ($10,00 - 3,21\text{ ns}$) no caminho crítico `in_sof -> out_eof_reg/D` sob as restrições fixas da execução a `100 MHz` (`input_delay = 2,00 ns`). Como o arquivo [`constraints/kuidamos_pixel_frontend.sdc`](../../constraints/kuidamos_pixel_frontend.sdc) recalcula `input_delay` e `output_delay` máximos como `20%` de `CLOCK_PERIOD_NS` e outro caminho interno (registrador a registrador) ou de I/O pode tornar-se dominante em períodos menores, a confirmação de operação em frequência superior exigiria nova análise de timing no período desejado. O resultado validado nesta evidência comprova o fechamento com folga a **100 MHz (`10,0 ns`)** sob as restrições documentadas.

## 5. Área e Contagem de Células por Hierarquia (`area_hierarchy.rpt` e `references.rpt`)

A síntese foi executada com `compile_ultra -no_autoungroup` para preservar a visibilidade dos 4 núcleos combinacionais dentro do topo `kuidamos_pixel_frontend`:

| Instância / Módulo | Células combinacionais ($\mu\text{m}^2$) | Células sequenciais ($\mu\text{m}^2$) | Área total de células ($\mu\text{m}^2$) | Participação (%) | Papel funcional |
|---|---:|---:|---:|---:|---|
| `kuidamos_pixel_frontend` (lógica local do topo) | `1.201,3387` | `759,8906` (`115` $\times$ `DFFX1_RVT`) | `1.961,2293` | `55,7%` | Captura/validação em `in_sof` (12 bits), contadores `(x_q, y_q)` e registradores de saída |
| `u_crop_core` (`crop_core`) | `553,0173` | `0,0000` | `553,0173` | `15,7%` | Somas de 12 bits (`x_end`, `y_end`), comparadores de ROI e coordenadas relativas `(u, v)` |
| `u_grayscale_core` (`grayscale_core`) | `479,0614` | `0,0000` | `479,0614` | `13,6%` | Árvore aritmética `77*R + 150*G + 29*B` em 16 bits (`58` `FADDX1_RVT` + `5` `HADDX1_RVT`) |
| `u_resize_nn_core` (`resize_nn_core`) | `471,1830` | `0,0000` | `471,1830` | `13,4%` | Seleção par `< 2*N_out` e regeneração de `out_sof/sol/eol/eof` |
| `u_threshold_core` (`threshold_core`) | `58,9614` | `0,0000` | `58,9614` | `1,7%` | Comparador de 8 bits `y_gray >= threshold` e mux de bypass |
| **Total de Células (`Cell Area`)** | **`2.763,5619`** | **`759,8906`** | **`3.523,4524`** | **`100,0%`** | **1.256 células folha (1.141 comb. + 115 FFs)** |
| **Área Estimada de Interconexão (`Net Area`)** | — | — | `853,3931` | — | Modelo de carga de fio `8000` / `ForQA` (`enclosed`) |
| **Área Total do Design (`Design Area`)** | — | — | **`4.376,8455`** | — | Células + interconexão estimada |

- **Verificação de Latches (`outputs/synthesis/reports/registers.rpt`):** `Total 0 cells` — nenhum latch sensível a nível foi inferido em nenhum módulo.
- **Verificação de DRC (`outputs/synthesis/reports/constraints.rpt`):** `This design has no violated constraints.`

## 6. Estimativa de Potência (`outputs/synthesis/reports/power.rpt`)

Estimativa obtida no corner `ss0p95v125c` ($V_{DD} = 0,95\text{ V}$, $T = 125\text{ }^\circ\text{C}$, clock de `100 MHz`) com propagação de atividade `medium effort` do Design Compiler (sem anotação SAIF/VCD gate-level):

| Bloco Hierárquico | Switching Power ($\mu\text{W}$) | Internal Power ($\mu\text{W}$) | Leakage Power ($\text{pW}$) | Total Power ($\mu\text{W}$) | Participação (%) |
|---|---:|---:|---:|---:|---:|
| `kuidamos_pixel_frontend` (total do IP) | `10,746` | `93,325` | `1,63e+08` (`163,196` $\mu\text{W}$) | **`267,267`** | **`100,0%`** |
| └─ Topo local (registradores + controle) | `2,983` | `73,845` | `1,00e+08` (`100,490` $\mu\text{W}$) | `177,321` | `66,3%` |
| └─ `u_grayscale_core` | `4,856` | `14,045` | `2,21e+07` (`22,129` $\mu\text{W}$) | `41,030` | `15,4%` |
| └─ `u_crop_core` | `1,353` | `2,359` | `1,95e+07` (`19,506` $\mu\text{W}$) | `23,218` | `8,7%` |
| └─ `u_resize_nn_core` | `1,030` | `2,191` | `1,91e+07` (`19,071` $\mu\text{W}$) | `22,292` | `8,3%` |
| └─ `u_threshold_core` | `0,524` | `0,885` | `2,00e+06` (`1,997` $\mu\text{W}$) | `3,406` | `1,3%` |

> Observação sobre potência: a parcela de *leakage* (`163,2` $\mu\text{W}$ de `267,3` $\mu\text{W}$) é elevada porque a biblioteca `saed32rvt_ss0p95v125c.db` é caracterizada a **`125 °C`**. A potência dinâmica foi estimada com atividade de chaveamento padrão (*default toggle rate*) sem arquivo SAIF pós-síntese (`PWR-414` / `PWR-415`).

## 7. Observações Estruturais (`check_design.rpt`) e Artefatos para M9 (DFT)

- O relatório `check_design.rpt` não apontou erros estruturais. Os avisos informativos `LINT-28` (`in_sol` e `in_eol` sem carga interna) e `LINT-2` (saídas diagnósticas `x_out`, `y_out`, `out_width`, `out_height` de `u_resize_nn_core` não conectadas a pinos externos do topo) refletem fielmente a decisão da especificação V1 ([`docs/spec_v1.md`](../spec_v1.md) §10), segundo a qual o IP reconstrói as coordenadas internamente a partir de `in_sof`, `pixel_valid`, `cfg_in_width` e `cfg_in_height`.
- Os artefatos pós-síntese para a etapa seguinte de **DFT / Scan Insertion (Marco M9)** foram gerados em `outputs/synthesis/` (fora do versionamento Git):
  - `outputs/synthesis/kuidamos_pixel_frontend_mapped.ddc`
  - `outputs/synthesis/kuidamos_pixel_frontend_mapped.v`
  - `outputs/synthesis/kuidamos_pixel_frontend_mapped.sdc`
  - `outputs/synthesis/kuidamos_pixel_frontend_mapped.sdf`
  - `outputs/synthesis/kuidamos_pixel_frontend.svf`

## 8. Limitações e Próximas Etapas

- A análise de timing e área de M8 utiliza modelos de carga de fio (*Wire Load Model* `8000` / `ForQA` em modo `enclosed`) antes da inserção de scan (M9) e antes do *placement & routing* físico (M10).
- As etapas de **DFT e inserção de cadeia de scan (Marco M9)** e **Implementação Física (Marco M10)** permanecem **NÃO EXECUTADAS**.
