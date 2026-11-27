# Plano de execução — Grupo 6C

Data: 2026-10-28. Horizonte aproximado de cinco meses, sujeito a revisão e disponibilidade do CIExpert. A especificação `spec_v1.md` é a base da V1. Caminhos de etapas futuras são sugestões; resultados executados estão identificados nas respectivas evidências.

Atualização em 2026-11-03: **M0 concluído**, por decisão explícita do responsável pelo projeto. A V1 adotou fatores 1 e 2 independentes por eixo. **M1 funcional executado**, com 18 testes Python aprovados e evidência em `docs/evidencias/M1_modelo_python.md`. O gerador oferece vetor funcional inicial; a ampliação e os vetores temporais pertencem a M2. As etapas EDA dependem de infraestrutura identificada e evidências reais.

Atualização em 2026-11-04: **M2 implementado e validado localmente** com nove cenários e 29 testes Python na regressão completa. Os arquivos, formato e limitações estão em `docs/evidencias/M2_vetores.md`. A integração com o futuro testbench e VCS ainda não foi executada; M3 não foi iniciado.

Atualização em 2026-11-05: **RTL de M3–M6 implementado em `rtl/`** (`grayscale_core.sv`, `crop_core.sv`, `resize_nn_core.sv`, `threshold_core.sv`, `kuidamos_pixel_frontend.sv`). Testbench SystemVerilog (`tb/`), simulação em VCS e ferramentas Synopsys ainda **NÃO EXECUTADOS**.

Atualização em 2026-11-06: **Testbench, Scoreboard, SVA e script VCS de M3–M7 implementados em `tb/` e `scripts/verification/run_vcs.sh`**. Em pré-validação local com Icarus Verilog 13.0 (`-DNO_CONCURRENT_SVA`), todos os 15 cenários (9 casos M2 + 6 casos dirigidos M7, totalizando 2.618 ciclos) passaram com 0 divergências de Scoreboard e 0 erros nos monitores procedurais de SVA, além de testes com injeção de falhas confirmando retorno diferente de zero (`$fatal(1, ...)`), detecção de vetores vazios/truncados/com linhas extras e detecção de truncamento de 11 bits nas somas de validação X/Y.

Atualização em 2026-11-08: **Verificação funcional de M3–M7 executada e aprovada no Synopsys VCS `X-2025.06-SP2_Full64`** (host `ciexpert-rocky8`, contêiner Rocky Linux 8 `x86_64`). Todos os **15 cenários (9 casos oficiais M2 + 6 casos dirigidos M7, 2.618 ciclos)** passaram com `0` divergências no Scoreboard e `0` violações nas 8 propriedades concorrentes `assert property` e nos monitores procedurais (`2.617` checagens pós-borda), além de validação negativa de falha de Scoreboard e de SVA concorrente com `simv -exitstatus` (retorno `3`). Evidência completa registrada em `docs/evidencias/M3_M7_verificacao_vcs.md`. Síntese lógica (M8), DFT (M9) e implementação física (M10) permanecem **NÃO EXECUTADOS**.

Atualização em 2026-11-09: **Síntese lógica e análise de timing (M8) executadas e aprovadas no Synopsys Design Compiler (`dc_shell` `X-2025.06-SP2`)** com a biblioteca padrão **SAED32 (`saed32rvt_ss0p95v125c.db`)** e restrições SDC de `100 MHz` (`10,0 ns`) em `constraints/kuidamos_pixel_frontend.sdc` e `scripts/synthesis/`. O circuito mapeou `1.256` células folha (`1.141` combinacionais + `115` flip-flops `DFFX1_RVT`, `0` latches), área total de células de `3.523,45` $\mu\text{m}^2$ (`4.376,85` $\mu\text{m}^2$ incluindo interconexão estimada), fechando timing em `10,0 ns` com folga de setup **`+3,21 ns` (MET)**, folga de hold **`+0,16 ns` (MET)**, `0` violações de DRC e potência total estimada de `267,27` $\mu\text{W}$ a `125 °C`. Evidência completa registrada em `docs/evidencias/M8_sintese_dc.md`. DFT (M9) e implementação física (M10) permanecem **NÃO EXECUTADOS**.

Atualização em 2026-11-20: **M9 concluído no escopo de scan** no Fusion Compiler `X-2025.06-SP2`. Uma cadeia conecta os 115 `SDFFX1_RVT` sem exclusões. O DFT DRC pós-scan registra zero violações no resumo e 91 avisos detalhados. O VCS passou 15/15 cenários funcionais e verificou 460 pulsos de shift, incluindo captura e extração. ATPG e M10 continuam pendentes. Thiago responde por RTL/síntese e Wagner por DFT. [Resultado final de M9](evidencias/M9_resultado_final.md).

Atualização em 2026-11-25. **M10 concluído no escopo acadêmico da seção 6C.** O Fusion Compiler executou a implementação física e as análises pós-route, incluindo área, STA e estimativa de potência com SAIF da regressão. Os checks internos, os DRVs e o handoff de scan foram validados. Anotação temporal completa, ATPG e signoff independente permanecem pendentes. [Resultado final de M10](evidencias/M10_resultado_final.md).

## Dependências e evidências

`M0 especificação → M1 modelo → M2 vetores → M3 passagem/grayscale → M4 crop → M5 resize → M6 threshold/integração → M7 regressão → M8 síntese → M9 DFT → M10 físico → M11 documentação`. Scoreboard e assertions crescem desde M3; M7 consolida. Diagnóstico de ferramentas pode ocorrer cedo, sem pressupor licenças ou bibliotecas. Cada marco registra versões, comando, data, configurações, código de saída, logs e limitações; dados protegidos ficam fora do versionamento.

## Responsáveis propostos

Divisão interna proposta por Wagner, **pendente de alinhamento com Thiago**; não é requisito do PDF oficial.

| Marco | Responsável e colaboração | Situação |
|---|---|---|
| M0 | Wagner (DFT), com revisão de Thiago | Concluído no escopo V1 |
| M1 | Wagner (DFT), com revisão de Thiago | Implementação inicial concluída |
| M2 | Wagner, com revisão de Thiago | Implementado e validado localmente; integrado ao TB/VCS |
| M3, M4, M5 e M6 | Thiago (RTL), com revisão de Wagner | RTL implementado em `rtl/` e validado no Synopsys VCS (`X-2025.06-SP2_Full64`) |
| M7 | Thiago (RTL), com apoio de Wagner | TB/Scoreboard/SVA implementados em `tb/` e validados no Synopsys VCS (15/15 PASS) |
| M8 | Thiago (RTL/síntese), conforme confirmação de 2026-11-20 | Implementado e validado no Synopsys Design Compiler (`X-2025.06-SP2`, SAED32, 100 MHz MET) |
| M9 | Wagner (DFT) | Concluído no escopo de scan. Cadeia validada estruturalmente e no VCS. |
| M10 | Wagner e Thiago | Entrega acadêmica consolidada |
| M11 | Wagner e Thiago | [Relatório PDF](m11/KUIDAMOS_6C_relatorio_tecnico.pdf), [manual](m11/manual_reproducao.md), [matriz](m11/matriz_rastreabilidade.md) e pacote final preparados. Wagner confirmou revisão positiva de Thiago. Entrega documental concluída. |

**M0–M11 concluídos no escopo acadêmico adotado em 27/11/2026.** Wagner ratificou os fatores 1 e 2 independentes por eixo como decisão de engenharia que simplifica o hardware. As atribuições descrevem a organização do trabalho. As revisões confirmadas constam do registro de decisões.

| Marco | Entrega e dependência | Comando indicativo e PASS | Evidência esperada |
|---|---|---|---|
| M0 — especificação — CONCLUÍDO | `docs/spec_v1.md`, registro de decisões e plano; definição dos limites e protocolo | Decisões internas V1 aprovadas pelo responsável pelo projeto | Decisões de engenharia e limites da V1 registrados em `docs/DECISOES_E_PENDENCIAS.md` |
| M1 — Golden Model | `model/golden.py`, `model/tests/`, `model/README.md`; operações inteiras e fórmula geral independente | `python -m unittest discover -s model/tests -v`; 18 testes passaram na execução registrada | `docs/evidencias/M1_modelo_python.md` |
| M2 — vetores | `model/m2_vectors.py`, `model/tests/test_m2_vectors.py`, nove casos em `vectors/m2/` | `python -m model.m2_vectors --output-dir vectors/m2 --check` e regressão Python; 28 arquivos idênticos e 29 testes passaram localmente | `docs/evidencias/M2_vetores.md`; integrado e validado no VCS em M7 |
| M3 — passagem e grayscale — VALIDADO EM VCS | `rtl/grayscale_core.sv`, `rtl/kuidamos_pixel_frontend.sv`, `tb/` | `./scripts/verification/run_vcs.sh`; PASS = compilação e scoreboard de valores, flags, latência, bolhas e reset | `docs/evidencias/M3_M7_verificacao_vcs.md` |
| M4 — crop — VALIDADO EM VCS | `rtl/crop_core.sv` + validação 12 bits em `in_sof` | `./scripts/verification/run_vcs.sh`; PASS = contagens, bordas, ROI 1×1, somas de 12 bits e inválidos rejeitados | `docs/evidencias/M3_M7_verificacao_vcs.md` |
| M5 — resize NN — VALIDADO EM VCS | `rtl/resize_nn_core.sv` com fatores 1 e 2 independentes | `./scripts/verification/run_vcs.sh`; PASS = seleção conforme fórmula geral, pares/ímpares, 2047×1 com fator 2 e marcadores | `docs/evidencias/M3_M7_verificacao_vcs.md` |
| M6 — threshold e integração — VALIDADO EM VCS | `rtl/threshold_core.sv` e topo integrado | `./scripts/verification/run_vcs.sh`; PASS = T=0/255, vizinhança `T-1/T/T+1`, bypass e quadros consecutivos | `docs/evidencias/M3_M7_verificacao_vcs.md` |
| M7 — verificação consolidada — VALIDADO EM VCS | `tb/` com scoreboard, SVA concorrente/procedural e `scripts/verification/run_vcs.sh` | `./scripts/verification/run_vcs.sh` no Synopsys VCS `X-2025.06-SP2_Full64`; PASS = 15/15 cenários, 2.618 ciclos, 0 divergências e 0 erros SVA | `docs/evidencias/M3_M7_verificacao_vcs.md` |
| M8 — síntese/timing — VALIDADO EM DC | `scripts/synthesis/`, `constraints/kuidamos_pixel_frontend.sdc`, relatórios DC | `./scripts/synthesis/run_dc.sh` no `dc_shell X-2025.06-SP2` (`saed32rvt_ss0p95v125c.db`); PASS = 0 erros, 0 latches, 0 violações DRC, setup slack `+3,21 ns` e hold slack `+0,16 ns` em `10,0 ns` | `docs/evidencias/M8_sintese_dc.md` |
| M9 — DFT/scan | `scripts/dft/` e artefatos locais em `outputs/dft/` | Pré-DFT, replacement, preview e inserção validados. Um caminho de 115 SDFFs, 15/15 cenários funcionais e 460 pulsos de shift verificados | [Resultado, rastreabilidade e avisos](evidencias/M9_resultado_final.md). ATPG é extensão condicionada a escopo e licença. |
| M10 — físico | `scripts/physical/` e relatórios Fusion Compiler; depende M9 e tecnologia disponível | Fluxo `fc_shell` documentado conforme ambiente; PASS = execução reproduzível até onde suportado e relatórios disponíveis de área/timing/potência, com restrições e falhas | Logs, versões, constraints, PDK/biblioteca identificados e relatórios permitidos |
| M11 — documentação | Manual de execução e resultados, `docs/DECISOES_E_PENDENCIAS.md`; depende M7–M10 ou limitações justificadas | Outra pessoa reproduz etapas possíveis com comandos e dependências registrados; PASS = evidências e limitações auditáveis | Documentação, inventário de artefatos, registros de revisão e resultados reais |

Em M8–M10 uma etapa não executada por falta de ambiente é **NÃO EXECUTADA/BLOQUEADA**, não PASS. Os ambientes e comandos já executados estão nas evidências M8, M9 e M10; os resultados de outro computador não comprovam disponibilidade local. A restrição 10 ns não prova timing fechado; potência só será reportada quando calculada com metodologia e dados disponíveis. Não versionar licença, tokens, PDK ou netlists restritos.

Sequenciamento sugerido: mês 1 M0–M2; mês 2 M3–M4; mês 3 M5–M7; mês 4 M8–M9; mês 5 M10–M11 e contingência. Estimativa de planejamento, não compromisso de prazo nem garantia de acesso às ferramentas.
