# Síntese Lógica e Análise de Timing — Grupo 6C (`scripts/synthesis/`)

Fluxo reproduzível de síntese lógica e análise de timing, área e potência para o marco **M8** do IP **KUIDAMOS Pixel Front-End** utilizando o **Synopsys Design Compiler (`dc_shell`)** e a biblioteca padrão **SAED32 (32/28 nm)**.

## Arquivos

| Arquivo | Descrição |
| :--- | :--- |
| [`dc_synth.tcl`](dc_synth.tcl) | Script TCL do Design Compiler (`analyze`, `elaborate`, `link`, `check_design`, aplicação do SDC, `compile_ultra -no_autoungroup`, geração de relatórios e exportação de `.ddc/.v/.sdf/.sdc` em `outputs/synthesis/`). |
| [`run_dc.sh`](run_dc.sh) | Script wrapper de linha de comando que valida o ambiente (`dc_shell` e `.db`), isola logs temporários em `outputs/synthesis/` e verifica erros de execução. |
| [`../../constraints/kuidamos_pixel_frontend.sdc`](../../constraints/kuidamos_pixel_frontend.sdc) | Restrições Synopsys Design Constraints (SDC) para a meta de análise de `100 MHz` (`10,0 ns`) definida em [`docs/spec_v1.md`](../../docs/spec_v1.md) §11. |

## Como Executar

Na raiz do repositório no ambiente Linux com Synopsys Design Compiler:

```bash
chmod +x scripts/synthesis/run_dc.sh
./scripts/synthesis/run_dc.sh
```

### Parâmetros Opcionais (Variáveis de Ambiente)

- `TARGET_LIB`: caminho para a biblioteca `.db` alvo (padrão: `/opt/synopsys/saed32/DBs/saed32rvt_ss0p95v125c.db`).
- `CLOCK_PERIOD_NS`: período de clock em nanossegundos (padrão: `10.0`, equivalente a `100 MHz`).
- `OUT_DIR`: diretório de saída para logs, relatórios e artefatos mapeados (padrão: `outputs/synthesis`).

## Relatórios e Artefatos Gerados (em `outputs/synthesis/`, fora do Git)

- `outputs/synthesis/dc_compile.log`: log completo da sessão do `dc_shell`.
- `outputs/synthesis/reports/qor.rpt`: resumo de Quality of Results (timing, células, área e violadores).
- `outputs/synthesis/reports/area_hierarchy.rpt`: área detalhada por submódulo (`u_grayscale`, `u_crop`, `u_resize_nn`, `u_threshold` e topo).
- `outputs/synthesis/reports/timing_max.rpt` e `timing_min.rpt`: 20 caminhos críticos de setup (`max`) e hold (`min`).
- `outputs/synthesis/reports/power.rpt`: estimativa de potência dinâmica (switching + internal) e leakage por hierarquia.
- `outputs/synthesis/reports/constraints.rpt`: verificação de violadores de timing/DRC (`-all_violators`).
- `outputs/synthesis/reports/check_design.rpt` e `registers.rpt`: verificação estrutural e comprovação de ausência de latches.
- `outputs/synthesis/kuidamos_pixel_frontend_mapped.{ddc,v,sdc,sdf}`: banco de dados e netlist gate-level prontos para a etapa de DFT (M9).
