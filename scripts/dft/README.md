# M9 — DFT e scan no Fusion Compiler

Fluxo executado no Rocky Linux 8.10 com Fusion Compiler `X-2025.06-SP2`.
O wrapper pré-DFT importa a netlist mapeada e o SDC de M8. Os drivers
separados executam replacement, preview, inserção e validação VCS.
O resultado e a revisão dos avisos estão na
[evidência final](../../docs/evidencias/M9_resultado_final.md).

## Executar

Na raiz do repositório, com o ambiente Synopsys já disponível no terminal:

```bash
export SAED32_REF_ROOT=/opt/synopsys/labs/FC-DFT-synthesis-lab-2022.12/ref
./scripts/dft/run_pre_dft.sh
```

O caminho acima foi verificado neste computador; os scripts recebem a localização
por variável e não incorporam caminhos pessoais ou configuração de licenças.
`FC_SHELL` pode indicar outro caminho para o executável da mesma versão.
`DFT_TIMEOUT_SECONDS` define o limite de execução, em segundos (padrão: 600).
O wrapper requer Bash, Python 3 com biblioteca padrão, Git e utilitários GNU já
existentes no Rocky. Não instala dependências nem altera configurações do sistema.

Entradas obrigatórias:

- `outputs/synthesis/kuidamos_pixel_frontend_mapped.v` e `_mapped.sdc`;
- `$SAED32_REF_ROOT/CLIBs/saed32_rvt.ndm`;
- `$SAED32_REF_ROOT/tech/saed32nm_1p9m.tf`;
- `$SAED32_REF_ROOT/DBs/saed32rvt_ss0p95v125c.db`, para identificação/hash da referência M8.

A NDM fornece os modelos ao FC; a `.db` não é importada diretamente pelo fluxo.
O corner é `ss0p95v125c`: processo `slow`, número `0.99`, tensão `0.95 V`, temperatura
`125 °C`. O script verifica o PVT efetivo early/late de cada célula, além do período
de clock de 10 ns e das unidades ns/fF carregadas pelo SDC original.

## Scripts e sequência

| Arquivo | Função |
|---|---|
| `run_pre_dft.sh` | Verifica entradas/versão, cria diretório exclusivo, registra hashes, executa FC com timeout e verifica a integridade de RTL/M8. |
| `pre_dft.tcl` | Captura ajuda nativa, solicita licença, coordena as etapas, registra métricas e salva somente a base derivada. |
| `01_import_check.tcl` | Importa/linka, inventaria células/clocks, confirma SDFF, configura PVT, lê SDC e executa checks/timing. |
| `02_protocol_drc.tcl` | Define sinais e hipótese de scan, gera protocolo, executa DFT DRC e exporta SPF preliminar. |
| `summarize_pre_dft.py` | Resume relatórios reais, mantendo separadas violações de scan e avisos de build/modelagem; rejeita relatórios incompletos/inconsistentes. |

O inventário esperado é específico da baseline M8 revisada: 1.256 células folha,
115 `DFFX1_RVT`, nenhuma referência não resolvida e todos os FFs em `clk`.
Uma mudança desses números exige revisão explícita da entrada, não ajuste automático
das expectativas. Os scripts não restauram nem descartam alterações locais.

## Hipótese de arquitetura e protocolo

Uma cadeia sem compressão é a hipótese inicial: há apenas 115 FFs, um clock,
nenhum latch e nenhum clock gate. Isso requer três novos pinos, `scan_enable`,
`scan_in` e `scan_out`, e evita hardware de compressão sem necessidade demonstrada.
Duas cadeias reduziriam o comprimento máximo ideal para 58 elementos, ao custo de
mais dois pinos de dados; não há orçamento de tempo de teste que justifique isso agora.
A contagem e a ordem finais dependerão de replacement, preview e revisão humana.

As portas são criadas somente no design derivado em `outputs/dft/`. Permanecem
sem conexão de scan nesta etapa. O RTL e a interface da netlist M8 são preservados.

| Sinal/configuração | Definição nesta execução |
|---|---|
| `clk` | `ScanClock`, período de teste 100 ns, subida em 45 ns e descida em 55 ns. |
| `reset_n` | Constante 1 no protocolo de teste; reset síncrono inativo. Não declarado como reset assíncrono. |
| `scan_enable` | `ScanEnable` ativo alto, especificação de conexão futura. |
| `scan_in`, `scan_out` | Portas dedicadas de dados de scan, especificação de conexão futura. |
| Configuração | Uma cadeia, `no_mix`, compressão/OCC/wrapper/test points desabilitados. |

O cenário funcional mantém o reset temporizado pelo SDC original. Não há
`set_case_analysis` no reset funcional nem restrições extras em `pixel_valid`,
`in_sof` ou `cfg_*`. Não se adiciona `test_mode` sem necessidade de controle extra.
O SPF pré-DFT não contém uma cadeia implementada nem protocolo final de shift;
não é uma entrada pronta para ATPG. O modo de DRC pré-scan pode classificar um
`DFFX1_RVT` como elegível mesmo antes da substituição por uma célula SDFF.

## Saídas e interpretação

Cada execução cria `outputs/dft/runs/<data-UTC>-<identificador>/`; nenhuma execução
anterior é sobrescrita e não há publicação automática. `outputs/dft/` já é ignorado
pelo Git. Logs e bibliotecas geradas pelo motor DRC podem conter modelos proprietários
e devem permanecer locais.

- `pre_dft.log`, `version.txt`, `environment.txt`, `tool_exit_code.txt`;
- `scripts.sha256`, `technology.sha256`, `protected.before.sha256` e `protected.after.sha256`;
- `metrics.tsv`, `execution.status`, `summary.txt`;
- `help/`: sintaxe fornecida pela versão instalada;
- `reports/`: estrutura, PVT efetivo, timing, licenças, células SDFF, DRC resumido e detalhado;
- `protocol/kuidamos_pixel_frontend_pre_dft.spf`;
- `db/kuidamos_pre_dft.dlib`, bloco `pre_dft_protocol`;
- `drc_work/`: entradas e logs do TestMAX/TetraMAX chamado internamente pelo FC somente para DRC.

Retorno **0 significa execução completa**, não ausência de warnings nem aceite de
M9. Falha de ferramenta, relatório incompleto, versão incompatível ou alteração dos
arquivos protegidos resulta em retorno diferente de zero. O resumo distingue
`scan_drc_violations` de `all_reported_dft_violations`: na execução registrada são
**0 e 94**, respectivamente. Não classificar o resultado como DRC globalmente limpo.

Sem floorplan/placement ou RC extraído, o FC usa atraso zero de interconexão.
Os slacks são diagnósticos e não substituem a análise M8 com wire-load, nem validam
timing físico ou pós-scan. `check_timing -all` também reporta ausência de grupos de
scaling; nenhuma regra foi silenciada para eliminar avisos.

## Replacement, inserção e simulações

| Entrada | Driver e saída esperada |
|---|---|
| `M9_PRE_DFT_LIB` aponta para a `.dlib` com `pre_dft_protocol` | `scan_replacement.tcl` copia a biblioteca e salva `kuidamos_replacement.dlib:replacement_candidate.design`, com inventário em `after/sequential.tsv`. |
| `M9_REPLACEMENT_RUN` aponta para o diretório com essa `.dlib` e o inventário | `preview_scan.tcl` verifica a arquitetura em uma cópia. `check_preview.py` cruza o relatório e registra `planned_chain.tsv`. |
| Mesmo `M9_REPLACEMENT_RUN`, em outro diretório de trabalho novo | `insert_scan.tcl` chama e valida o preview em memória, insere a cadeia e exporta `post/scan_netlist.v`, `scan_protocol.spf`, `scan.def` e o checkpoint `scan_inserted`. |
| Diretório da execução de inserção | `check_scan_exports.py` cruza ordem, netlist, SPF e Scan DEF. `run_replacement_sim.sh … post_scan` roda o scoreboard M2/M7. `run_shift_sim.sh` usa a ordem medida para testar o deslocamento. |

Os drivers Tcl posteriores chamam o FC em diretórios de trabalho distintos,
com referências SAED32 já disponíveis no checkpoint. Ao mover a biblioteca
derivada para outro computador, confira também os caminhos das bibliotecas NDM
gravados no checkpoint (`report_ref_libs`). Copiar só a `.dlib` pode deixar
referências inacessíveis. Recriar a base pré-DFT com `SAED32_REF_ROOT` correto
é o caminho reproduzível em outra instalação. Os IDs de execução nas evidências
são exemplos históricos. Os drivers recebem seus caminhos por variável ou
argumento.

O fluxo de inserção requer `python3` (3.6 ou superior, biblioteca padrão) no
PATH do FC, além de Bash e utilitários GNU. Os wrappers VCS usam `rg`.
Os parsers conferem o formato dos
relatórios da versão validada, o topo, a cadeia e as contagens esperadas de M8.
Mudanças de versão, nomes, avisos ou inventário exigem revisão dos relatórios
e dos validadores. O driver fixa a saída do Python em UTF-8 ao chamá-lo pelo
FC. Para simular, o VCS Full64 precisa da licença ativa, do compilador C/C++
e do `make` usados pelo toolchain, das bibliotecas de runtime da instalação
(incluindo `libnuma` no ambiente testado) e do modelo
`$SAED32_REF_ROOT/verilog/stdcell_rvt/saed32nm.v`. O teste funcional também
usa `tb/tb_kuidamos_pixel_frontend.sv` e `vectors/m2/` do repositório. A
consulta isolada às regras TestMAX pode precisar de `embedit/bin` no PATH
para localizar `snps_platform`.

Com o ambiente carregado, obtenha o caminho pré-DFT pelo log do wrapper
acima. Defina `PRE_DFT_RUN` com o caminho absoluto desse diretório e
execute na raiz do repositório:

```bash
set -euo pipefail
root=$(pwd -P)
export M9_PRE_DFT_LIB="$PRE_DFT_RUN/db/kuidamos_pre_dft.dlib"
replacement=$(mktemp -d "$root/outputs/dft/runs/replacement-XXXXXX")
(
    cd "$replacement"
    timeout -k 10s 180s "${FC_SHELL:-fc_shell}" -no_init \
        -file "$root/scripts/dft/scan_replacement.tcl" > replacement.log 2>&1
)
scripts/dft/run_replacement_sim.sh "$replacement" replacement

export M9_REPLACEMENT_RUN="$replacement"
insertion=$(mktemp -d "$root/outputs/dft/runs/insertion-XXXXXX")
(
    cd "$insertion"
    result=0
    timeout -k 10s 240s "${FC_SHELL:-fc_shell}" -no_init \
        -file "$root/scripts/dft/insert_scan.tcl" > insertion.log 2>&1 || result=$?
    printf '%s\n' "$result" > tool_exit_code.txt
)
python3 scripts/dft/check_scan_exports.py "$insertion"
scripts/dft/run_replacement_sim.sh "$insertion" post_scan
scripts/dft/run_shift_sim.sh "$insertion"
```

Para rodar apenas o preview, abra um diretório novo, execute `preview_scan.tcl`
com o mesmo `M9_REPLACEMENT_RUN`, registre o retorno em `tool_exit_code.txt`
e a saída em `preview.log`. Valide com `check_preview.py <diretório>`.
A inserção já inclui essa verificação no mesmo processo FC, por isso um
preview separado é opcional.

Para auditar uma execução existente sem rodar FC ou VCS:

```bash
python3 scripts/dft/check_scan_exports.py "$insertion"
rg 'SUMMARY:|OVERALL RESULT:|SHIFT_PASS' "$insertion"/sim-*/simulation.log
```

Resultados, logs integrais, modelos e checkpoints permanecem em
`outputs/dft/`, ignorado pelo Git. ATPG, simulação temporal e implementação
física são etapas adicionais. [Limites e pendências](../../docs/evidencias/M9_resultado_final.md#limites-acadêmicos-e-trabalho-posterior).
