# M9 — importação e verificações pré-DFT no Fusion Compiler

Fluxo executado no Rocky Linux 8.10 com Fusion Compiler `X-2025.06-SP2`.
Importa exclusivamente a netlist mapeada e o SDC de M8. Não executa
`compile_fusion`, scan replacement, `preview_dft`, `insert_dft`, ATPG ou físico.
A evidência e os avisos estão em [M9_pre_dft_fc.md](../../docs/evidencias/M9_pre_dft_fc.md).

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

## Próxima execução, ainda não realizada

1. Revisar os avisos B7/B8/B10 e N20, a arquitetura proposta e a limitação de timing.
2. Copiar a base pré-DFT para um novo diretório e abrir o bloco `pre_dft_protocol`.
3. Validar as precondições do caminho nativo de replacement. A ajuda instalada de
   `compile.seqmap.scan` documenta substituição durante `compile_fusion`. O primeiro
   comando de diagnóstico planejado é `compile_fusion -check_only -from initial_map
   -to logic_opto`, com `compile.seqmap.scan=true`. Esse comando **não foi executado**.
   Se exigir entradas RTL, floorplan ou recursos adicionais, registrar a limitação
   antes de ampliar o fluxo; não pressupor que a netlist DC seja suficiente.
4. Somente com essas precondições atendidas, executar o estágio lógico de replacement
   em uma base nova, auditar DFF→SDFF, eventuais mudanças combinacionais, equivalência
   funcional e timing. A disponibilidade de `SDFFX1_RVT` não prova replacement realizado.
5. Recriar/verificar protocolo e DRC, definir a cadeia revisada e executar `preview_dft`.
   Só após essa revisão executar `insert_dft`, DRC pós-scan e exportação de netlist,
   SPF e scan DEF consistentes. Os comandos existem nesta versão; sua execução sobre
   o KUIDAMOS pós-replacement e suas licenças ainda precisam de evidência.

Não há comando de insertion ou replacement neste wrapper. ATPG e físico também
permanecem fora desta execução; a licença ATPG é uma pendência separada.
