# Evidência M9 — importação e verificações pré-DFT no Fusion Compiler

Data: **2026-11-20**, America/Sao_Paulo. Responsável: Wagner (DFT), com execução
assistida pelo Codex. Thiago permanece responsável por RTL e síntese, conforme
orientação atual do responsável pelo projeto.

**Status: pré-DFT executado, com avisos registrados. M9/scan não concluído.**
Não foram executados scan replacement, `preview_dft`, scan insertion, ATPG ou físico.

## Proveniência e reprodução

- Baseline: `831812edd8291efbf9233698e326a6c125ba069b`, `main` local igual à remota.
- Branch criada: `feat/m9-dft-scan`; árvore inicialmente limpa; nenhum commit/push.
- Scripts e instruções: [`scripts/dft/README.md`](../../scripts/dft/README.md).
- Ambiente: Rocky Linux 8.10, kernel `4.18.0-553.124.1.el8_10.x86_64`.
- FC: `X-2025.06-SP2`, build 2025-10-15.
- Motor de DRC integrado: TestMAX/TetraMAX `X-2025.06-SP3`, build 2025-10-10,
  identificado no log do subprocesso. Seu uso foi exclusivamente para DRC.
- Execução final dos scripts: `outputs/dft/runs/20261120T133126Z-TW0Czt/`;
  retorno do FC e do wrapper **0**; marcador `COMPLETED`; duração reportada pelo FC
  de 11 s, memória máxima de 540,09 MB. O identificador do diretório está em UTC.
- Execução inicial de desenvolvimento preservada em `20261120T132937Z-E8JEGe`;
  a execução final acrescentou atualização explícita de timing, inventário do PVT
  efetivo e relatório detalhado de violações. Os principais resultados coincidiram.

Comando executado na raiz:

```bash
SAED32_REF_ROOT=/opt/synopsys/labs/FC-DFT-synthesis-lab-2022.12/ref \
  ./scripts/dft/run_pre_dft.sh
```

O wrapper usa `fc_shell -no_init -file scripts/dft/pre_dft.tcl` com caminho absoluto
e diretório de trabalho exclusivo. Ajuda nativa dos comandos está em `help/`;
os comandos efetivamente usados estão nos scripts e no log. Paths locais, hashes
das fontes e da tecnologia estão nos manifests locais. Não foram copiadas bibliotecas
tecnológicas para o Git.

## Entradas, bibliotecas e corner

Os relatórios M8 `area.rpt`, `power.rpt` e `timing_max.rpt` identificam
`saed32rvt_ss0p95v125c`: **SAED32 RVT, slow-slow, 0,95 V, 125 °C**.
O `report_lib -include_db_mapping` da NDM local confirma o mesmo corner, com
processo numérico `0.99` e label `slow`. O fluxo usa `CLIBs/saed32_rvt.ndm` e
`tech/saed32nm_1p9m.tf`. A `.db` local correspondente é inventariada por hash;
os modelos usados pelo FC vêm da NDM. Não existe hash da biblioteca original do
computador de Thiago para comprovar identidade binária entre ambientes.

| Entrada M8 | SHA-256 |
|---|---|
| `kuidamos_pixel_frontend_mapped.v` | `65ac135a4adac08f8e78271f282604727a2fde40038606fca20af59df20704a9` |
| `kuidamos_pixel_frontend_mapped.sdc` | `2c05eafb01194887c821b454697cec1068afbc090faced30bb76d028f950abac` |

Foi criado o cenário `functional::ss0p95v125c`, com setup e hold ativos.
O arquivo `effective_pvt.tsv` confirma early/late de **todas as 1.256 células**:
processo 0,99, tensão 0,95 V, temperatura 125 °C. `report_pvt` informa zero
divergências. O SDC original foi lido sem edição: clock 10 ns, unidades ns/fF,
incertezas setup/hold 0,20/0,05 ns, delays externos max/min 2,00/0,20 ns e carga
de saída 0,05 fF. Não houve mudança do reset funcional por case analysis.

## Importação e verificações estruturais

`read_verilog` leu cinco módulos e `link_block` retornou 1, com mensagem de vínculo
bem-sucedido. A contagem de 1.260 instâncias inclui quatro instâncias hierárquicas;
o número de células folha é 1.256.

| Métrica | Resultado real |
|---|---:|
| Células folha | 1.256 |
| Sequenciais | 115, todas `DFFX1_RVT` |
| Referências não resolvidas, lógica não mapeada ou black boxes | 0 |
| Latches / clock gates detectados pelo DRC | 0 / 0 |
| Clocks dos 115 FFs | `clk` |
| `check_design -checks {netlist unbound}` | 0 erros, **136 warnings** |

Distribuição dos avisos estruturais: DCHK-009: 46; DCHK-010: 44; DCHK-017: 2;
DCHK-021: 44. As interfaces diagnósticas de `resize_nn_core` preservadas na netlist
contêm saídas de 11 bits `x_out`, `y_out`, `out_width` e `out_height` sem uso pelo
topo; `in_sol` e `in_eol` também não têm carga funcional. Os relatórios foram
preservados, sem remover portas ou modificar a netlist para eliminar avisos.

As células `SDFFX1_RVT` e `SDFFX2_RVT` estão disponíveis, sequenciais,
com `dont_use=false` e pinos `D/CLK/SE/SI/Q/QN`. O inventário das referências de
todas as células antes e depois do diagnóstico é idêntico: nenhum DFF foi substituído.

## Timing diagnóstico

Executados: `update_timing`, `check_timing -all`, `report_timing -delay_type max`
e `report_timing -delay_type min`, com até dez caminhos por relatório.

- Menor slack reportado de setup: **+3,24 ns**.
- Menor slack reportado de hold: **+0,16 ns**.
- `check_timing -all`: **1.256 warnings TCK-014**, um por célula sem grupo de
  biblioteca de scaling definido; nenhum erro no resumo. O aviso agregado não
  é contado como uma célula adicional.
- `NEX-018`, `TIM-101` e `TIM-102`: ausência de parasitas/físico e uso de **atraso
  zero de interconexão**. Nenhum floorplan ou posicionamento foi executado.
- O FC também emitiu `LGL-397` durante protocolo/DRC por ausência de site rows.

Estes valores não demonstram fechamento físico nem melhoria sobre M8. M8 usava
wire-load; o modelo de interconexão desta execução é diferente. O PVT exato foi
confirmado, mas os avisos de scaling permanecem abertos, sem waiver ou supressão.

## Arquitetura candidata e protocolo

Hipótese avaliada: **uma cadeia sem compressão**, inicialmente 115 FFs, todos no
mesmo clock. Justificativa: circuito pequeno, ausência de múltiplos domínios e
clock gating, três pinos dedicados e nenhum requisito documentado de redução do
tempo de shift que compense cadeias adicionais. A cadeia não está implementada;
ordem e comprimento finais dependem de replacement/preview e revisão.

Foram criadas somente na base derivada as portas `scan_enable`, `scan_in` e
`scan_out`. `scan_enable` é ativo alto. `clk` tem período de teste 100 ns e bordas
em 45/55 ns. `reset_n` é uma **constante de teste 1**, pois o reset original é
síncrono ativo baixo e está implementado na lógica de D, não em pino assíncrono.
Configuração externa, `pixel_valid` e `in_sof` não foram fixados pelo protocolo.
Não foi adicionado `test_mode`, OCC, compressão, wrapper ou test points.

`create_test_protocol` e `write_test_protocol` foram executados. O SPF gerado
contém setup/captura preliminares, sem cadeia implementada ou procedimento final
de shift. Não é um handoff pronto para ATPG. Não foi realizada simulação funcional
do design nem simulação de padrões nesta etapa.

## Resultado real do DFT DRC

Executado `dft_drc -verbose`, com relatório aprimorado e arquivos do motor em
`drc_work/`. O protocolo foi lido e simulado internamente pelo checker sem erros.
O FC retornou 1 para `dft_drc` e reportou:

```text
0 TOTAL VIOLATIONS
Sequential Elements Detected      : 115
Excluded Scan Elements            : 0
Violated Scan Elements (Excluded) : 0
Traced Scan Elements (Percent)    : 115 (100.0%)
```

**São 115 FFs elegíveis para scan; não são 115 SDFFs já inseridos.** O inventário
continua com 115 `DFFX1_RVT`. O percentual também não é cobertura ATPG.

O comando adicional `report_dft_drc_violations -summary` registra **94 avisos de
build/modelagem**, mesmo com zero violações no resumo de regras pré-scan:

| Regra | Quantidade | Contexto confirmado no relatório detalhado |
|---|---:|---|
| B10 | 44 | Nets `SYNOPSYS_UNCONNECTED_*` relacionados às saídas diagnósticas sem uso. |
| B7 | 45 | 44 bits de saída de `resize_nn_core` sem driver na netlist otimizada e `scan_out` ainda desconectado. |
| B8 | 4 | `in_sol`, `in_eol`, `scan_enable` e `scan_in` sem carga; as duas últimas são portas futuras de teste. |
| N20 | 1 | UDP `p_dffx1_rvt_0`, gerado pelo FC em `comboLib_*.v`, com uma transição X subespecificada. |

O N20 é do modelo gerado para a célula tecnológica, não um UDP no RTL do projeto.
Precisa de revisão de modelagem antes do aceite de scan/padrões; não foi corrigido
nem silenciado. B7/B8 das portas de scan devem ser reavaliados após a conexão real.
Os avisos de saídas diagnósticas são rastreáveis à baseline M8 e não foram apagados.
**Não se declara DRC globalmente limpo ou M9 aprovado.**

## Licenças, integridade e testes do fluxo

`licenses_before.rpt` registra checkout de `Fusion-Compiler-NX`;
`licenses_after.rpt` registra `Fusion-Compiler-NX` e `Fusion-Compiler-FE-NX`.
Não houve bloqueio de licença para importação, timing, protocolo ou pré-DFT DRC.
A execução do motor integrado não comprova disponibilidade de ATPG independente:
no diagnóstico anterior a solicitação de `Test-ATPG` foi negada (`SEC-51`).
Nenhum teste ATPG ou novo checkout dessa feature foi realizado nesta etapa.
A licença necessária à futura execução de replacement/insertion será registrada
quando essas operações forem autorizadas e executadas.

Os manifests SHA-256 de **todos os arquivos versionados em `rtl/` e
`outputs/synthesis/`** foram idênticos antes/depois. `git diff` nesses diretórios
também ficou vazio. Os projetos independentes foram preservados; o repositório
`ufe8-dft-flow` continua com as alterações locais que já existiam.

Validação dos scripts:

- `bash -n scripts/dft/run_pre_dft.sh`: aprovado;
- análise de sintaxe Python com `ast.parse`: aprovada, inclusive no Python 3.6 local;
- execução real do wrapper e dos Tcl no FC: concluída, códigos 0;
- testes negativos em cópias locais: relatório DRC truncado, total que oculta os
  94 avisos e manifesto de entrada alterado foram rejeitados pelo resumidor,
  todos com código 1;
- biblioteca tecnológica ausente foi rejeitada pelo wrapper com código 2 antes
  de iniciar FC. Logs em `outputs/dft/validation-77nabzc9/checks.txt`.

Não foram refeitos testes Python do Golden Model, regressão VCS, síntese M8,
scan replacement, scan insertion, ATPG ou físico.

## Próximo passo

Revisar os avisos acima e a cadeia candidata; preparar **uma nova execução** a
partir de uma cópia da base `pre_dft_protocol`. O primeiro passo técnico é o
precheck documentado de `compile_fusion` com `compile.seqmap.scan=true`, limitado
a `initial_map`→`logic_opto`, para determinar se a base gate-level atende às
precondições de replacement. Não executar otimização física implicitamente.
As condições e a sequência planejada estão no [README do fluxo](../../scripts/dft/README.md#próxima-execução-ainda-não-realizada).

Somente após replacement comprovado, comparação funcional e novo DRC, executar
`preview_dft`, revisar a arquitetura e então `insert_dft`, com DRC pós-scan e
exportação consistente. Nenhuma dessas operações está implementada no wrapper
pré-DFT, e nenhuma foi executada nesta entrega.
