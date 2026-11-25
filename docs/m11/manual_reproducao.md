# Manual consolidado de reprodução

Baseline técnico M0–M10 na `main` do merge `3fb7875`. O caso
complementar e os documentos de M11 estão na branch de documentação.
Use o commit correspondente à evidência ao reproduzir uma etapa.
Os registros de versões, relatórios e manifests identificam a
execução que sustentou cada resultado.

## Pré-requisitos

| Uso | Ambiente verificado |
|---|---|
| Modelo e vetores | Python 3.10.6 na execução M1 e 3.11.13 na demonstração M11, com NumPy 2.2.6 e Pillow 10.2.0 de `model/requirements.txt` |
| Scripts EDA | Bash, GNU coreutils, Git, ripgrep, Python 3 e timeout. VCS Full64 com compilador C/C++, make e runtime local |
| RTL e gate-level | Synopsys VCS X-2025.06-SP2_Full64 |
| Síntese | Design Compiler X-2025.06-SP2, biblioteca SAED32 RVT `saed32rvt_ss0p95v125c.db` |
| DFT | Fusion Compiler X-2025.06-SP2 com motor de DRC TestMAX/TetraMAX X-2025.06-SP3 na execução M9 |
| Físico | Fusion Compiler X-2025.06-SP2 com as features NX, FE-NX e BE-NX verificadas. NDM RVT, tecnologia 1P9M e tabelas RC Cmin/Cmax |
| Instalação de referência | Rocky Linux 8.10 no CIExpert. Sessão Synopsys e licenças carregadas conforme o administrador do ambiente |

Use ambiente virtual local e caminhos absolutos para bibliotecas,
checkpoints e executáveis instalados. A obtenção da licença e dos
arquivos de tecnologia depende do acesso do participante ao CIExpert.
Mantenha-os fora do Git. Execute na raiz, em Bash:

```bash
python3.11 -m venv .venv
source .venv/bin/activate
python -m pip install -r model/requirements.txt
export PYTHON_BIN="$PWD/.venv/bin/python"
export SAED32_REF_ROOT=/caminho/saed32/ref
export TARGET_LIB="$SAED32_REF_ROOT/DBs/saed32rvt_ss0p95v125c.db"
# Caso o binário FC não esteja no PATH, configure FC_SHELL com seu caminho.
```

## M1 e M2 — modelo e vetores

```bash
python -m unittest discover -s model/tests -v
python -m model.m2_vectors --output-dir vectors/m2 --check
python -m model.real_image_demo --input docs/experimentos/estacionamento/carro.jpeg \
  --output-dir "$(mktemp -d "$PWD/outputs/m1-imagem-XXXXXX")"
```

M1 recebe matriz RGB888/configuração ou imagem externa via Pillow.
A regressão de referência pós-experimento registrou 32 testes
aprovados. O exemplo com imagem externa grava cada estágio e
metadata. M2 confere os **28 arquivos** oficiais byte a byte
em modo `--check`. Retire `--check` e escolha outro diretório
para criar uma cópia dos vetores. Compare o código de saída e
as contagens antes de usar a saída no VCS.
[Modelo](../../model/README.md) · [Imagem M1](../evidencias/M1_imagem_real.md) · [Vetores](../evidencias/M2_vetores.md)

## M3–M7 — RTL, scoreboard e SVA

```bash
vcs_run=$(mktemp -d "$PWD/outputs/m7-repro-XXXXXX")
OUT_DIR="$vcs_run" VECTOR_DIR="$PWD/vectors/m2" SIM_PLUSARGS='' \
  ./scripts/verification/run_vcs.sh
rg 'SUMMARY:|OVERALL RESULT:' "$vcs_run/vcs_sim.log"
```

Entradas são RTL, monitor de SVA, testbench e vetores M2. A suíte
executa nove casos por vetores e seis dirigidos. O aceite registrado
tem **15/15**, 2.618 ciclos, zero divergências e zero erros SVA.
Use `SIM_PLUSARGS='+CASE=<nome>'` só para diagnóstico de um caso.
[Guia do TB](../../tb/README.md) · [Evidência M7](../evidencias/M3_M7_verificacao_vcs.md)

## M8 — síntese lógica

```bash
m8_run=$(mktemp -d "$PWD/outputs/m8-repro-XXXXXX")
OUT_DIR="$m8_run" CLOCK_PERIOD_NS=10.0 TARGET_LIB="$TARGET_LIB" \
  ./scripts/synthesis/run_dc.sh
rg 'Total cell area' "$m8_run/reports/area.rpt"
```

Entradas são RTL, constraints e DB slow. O DC exporta netlist,
SDC, DDC, SDF, SVF e relatórios. Confira retorno, latches,
pior setup/hold e unidade de área. A síntese registrada tem
1.256 células, zero latches e folgas de +3,21 ns de setup e
+0,16 ns de hold no cenário analisado.

O pré-DFT M9 procura a netlist e o SDC mapeados em `outputs/synthesis/`.
Para reproduzir M9 a partir da entrega, use os arquivos de referência
desse diretório. Para encadear uma nova síntese, use um checkout
separado e grave o M8 regenerado em `outputs/synthesis/` desse
checkout antes de seguir para M9.
[Guia de síntese](../../scripts/synthesis/README.md) · [Relatório M8](../evidencias/M8_sintese_dc.md)

## M9 — pré-DFT, replacement, preview e inserção

```bash
./scripts/dft/run_pre_dft.sh
# Aponte PRE_DFT_RUN para o diretório retornado acima.
PRE_DFT_RUN=/caminho/da/execucao-pre-dft
repo=$(pwd -P)
export M9_PRE_DFT_LIB="$PRE_DFT_RUN/db/kuidamos_pre_dft.dlib"
replacement=$(mktemp -d "$repo/outputs/dft/runs/replacement-XXXXXX")
(
  cd "$replacement"
  timeout -k 10s 180s "${FC_SHELL:-fc_shell}" -no_init \
    -file "$repo/scripts/dft/scan_replacement.tcl" > replacement.log 2>&1
)
./scripts/dft/run_replacement_sim.sh "$replacement" replacement

export M9_REPLACEMENT_RUN="$replacement"
insertion=$(mktemp -d "$repo/outputs/dft/runs/insertion-XXXXXX")
(
  cd "$insertion"
  status=0
  timeout -k 10s 240s "${FC_SHELL:-fc_shell}" -no_init \
    -file "$repo/scripts/dft/insert_scan.tcl" > insertion.log 2>&1 || status=$?
  printf '%s\n' "$status" > tool_exit_code.txt
)
python3 scripts/dft/check_scan_exports.py "$insertion"
./scripts/dft/run_replacement_sim.sh "$insertion" post_scan
./scripts/dft/run_shift_sim.sh "$insertion"
```

A inserção faz o preview em memória. O guia DFT mostra a opção de
executar preview isolado em uma cópia nova. Vínculo, protocolo e
contagens devem conferir em cada etapa. No resultado registrado,
uma cadeia liga 115 SDFFs com zero exclusões, VCS funcional 15/15
e shift com 460 pulsos. O resumo do DFT DRC tem zero violações e a
revisão detalhada registra 91 avisos. O handoff contém
`scan_inserted`, netlist pós-scan, SPF, Scan DEF e inventário.
[Guia DFT](../../scripts/dft/README.md) · [Relatório M9](../evidencias/M9_resultado_final.md)

## M10 — implementação física até o readback

Use o caminho de uma execução M9 validada. Após cada comando,
anote o diretório novo que ele imprimir. Os caminhos abaixo
são variáveis a preencher com o resultado da etapa precedente.

```bash
insertion=/caminho/da/execucao-insertion-m9
chain="$insertion/post/actual_chain.tsv"
spf="$insertion/post/scan_protocol.spf"
./scripts/physical/run_readiness.sh "$insertion"
./scripts/physical/run_floorplan.sh "$insertion"

floorplan=/caminho/da/execucao-floorplan
./scripts/physical/run_powerplan.sh "$floorplan"

powerplan=/caminho/da/execucao-powerplan
./scripts/physical/run_placement_precheck.sh "$powerplan" "$spf"
./scripts/physical/run_placement.sh "$powerplan" "$spf" --correct-m1

placement=/caminho/da/execucao-placement-validada
./scripts/physical/run_cts.sh "$placement" "$chain"

cts=/caminho/da/execucao-cts-validada
./scripts/physical/run_routing.sh "$cts" "$chain"

routing=/caminho/da/execucao-routing-validada
./scripts/physical/run_physical_final.sh "$routing" "$chain"
```

| Etapa | Checkpoint ou handoff | Conferir antes de prosseguir |
|---|---|---|
| Readiness e floorplan | `scan_inserted` → `floorplan_initial` | Referências, lib/tech, geometria e readback, 52 rows |
| PG e placement | `powerplan_initial` → `powerplan_corrected` e `placement_initial` | Comparação dos rails, DRC PG após placement e células legais |
| Pinos e CTS | `pins_initial` → `cts_initial` | 126 portas de sinal, cinco buffers, 115 sinks, PG, cadeia e VCS |
| Routing | `clock_routed` → `routing_initial` | Zero opens/shorts, DRC interno, PG, preservação da cadeia, SPEF e VCS |
| Fechamento | `routing_initial` → `physical_final` | `PHYSICAL_FINAL_VALIDATED`, `PROTECTED_INPUTS_MATCH`, readback, DRVs, STA, regressões e potência com SAIF |

A execução final guarda DEF, Scan DEF, netlist, quatro SPEFs,
quatro SDFs, SAIF, SVGs, relatórios e hashes. Cruze TNS e
slacks por cenário, a contagem das redes com cargas, o clock,
a cadeia e a cobertura SAIF. Quando o manifesto estiver
disponível, valide-o no diretório correspondente:

```bash
physical=/caminho/da/execucao-physical-final
(cd "$physical" && sha256sum -c delivery.sha256)
```

[Guia de implementação física](../../scripts/physical/README.md) · [Resultado M10 e inventário](../evidencias/M10_resultado_final.md)

## Complemento M11 — imagem real no RTL e na netlist

```bash
./scripts/verification/run_m11_real_image.sh docs/experimentos/estacionamento/carro.jpeg
# Opcional, com a execução física e o modelo Verilog RVT disponíveis.
./scripts/verification/run_m11_real_image.sh docs/experimentos/estacionamento/carro.jpeg \
  "$physical/signals/reports/netlist.v"
```

O diretório informado em `outputs/m11/` reúne estímulos, capturas,
logs, PNGs e resultados. Confira **5.035 pixels** e zero divergências
para o estímulo documentado. O diagnóstico gate-level executa
comparação funcional, e o RTL mantém o monitor SVA.
[Dados e comandos do M11](../evidencias/M11_imagem_real_vcs.md)

## Problemas já observados

| Sintoma | Diagnóstico e ação |
|---|---|
| Biblioteca NDM ausente ou checkpoint com referências quebradas | Verifique `SAED32_REF_ROOT` e `report_ref_libs`. Recrie o pré-DFT na instalação ou restabeleça a referência em uma cópia. Preserve a base anterior |
| Wrapper roda no diretório errado ou com binário incompatível | Execute na raiz e confira `command -v`, versões registradas e caminhos de entrada. Use `FC_SHELL` e os timeouts da etapa, conforme os guias |
| M2 local difere byte a byte | Compare versões Python/NumPy, seed e LF com a evidência. Regere em outra pasta e investigue o diff |
| M1 ou M11 falha com importação Python | Use o interpretador da venv com `model/requirements.txt`. No M11, ajuste `PYTHON_BIN` para esse interpretador |
| Células de scan ou pinos de teste diferentes | Confira M8, SPF, arquivo de ordem, estado de SE/SI e relatórios DFT DRC. Preserve o encadeamento entre checkpoints |
| PG DRC em M1 depois do placement | Confira a correção documentada para rails de 0,060 µm e execute o caminho `--correct-m1` sobre cópia da base validada |
| TLUP-012 para DIFF | A evidência pós-route registra extração DR das redes de interconexão. Preserve o aviso e verifique SPEF e modelos RC na nova instalação |
| SDF com portas não encontradas ou SDFCOM_UHICD | Use `probe_routing_sdf.sh` com a cópia de diagnóstico. A normalização dos barramentos eliminou os erros de porta associados aos seletores e deixou 15 interconexões ignoradas. A regressão temporal permanece pendente |
| ICV, PrimeTime ou StarRC indisponível | Registre o diagnóstico no ambiente. Use as evidências internas do FC com as respectivas limitações |
