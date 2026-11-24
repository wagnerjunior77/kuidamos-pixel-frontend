# M10 — preparação para implementação física no Fusion Compiler

O diagnóstico usa a versão `X-2025.06-SP2` e uma cópia do handoff M9.
Os resultados observados e o estado das licenças estão na
[evidência de preparação](../../docs/evidencias/M10_preparacao_physical.md).

## Executar o diagnóstico

Carregue o ambiente Synopsys já configurado e execute na raiz do repositório.

```bash
export SAED32_REF_ROOT=/caminho/da/instalacao/ref
./scripts/physical/run_readiness.sh /caminho/da/execucao-de-insercao-m9
```

Use como argumento o diretório de inserção criado por `insert_scan.tcl`,
com `kuidamos_preview.dlib/scan_inserted` e os relatórios de M9. O guia de
M9 contém a receita de regeneração. A DLIB registra o caminho da NDM
referenciada. Se a biblioteca foi movida, regenere o handoff com o novo
caminho ou restabeleça a referência em uma cópia de trabalho. [Guia do M9](../dft/README.md)

O wrapper usa Bash, GNU coreutils, Python 3 e `fc_shell`. `FC_SHELL`
permite indicar o executável e `M10_TIMEOUT_SECONDS` define o timeout
(padrão 180 s). Cada execução cria um diretório novo ignorado pelo Git
em `outputs/physical/runs/`, copia a DLIB, valida netlist, SPF, Scan DEF e
inventário M9, e confere os hashes das entradas após o FC. O Tcl abre
`scan_inserted`, testa as licenças, examina tecnologia e PG, e ensaia
direções, RC e cenário de shift em memória. A cópia original do M9
permanece como fonte. O Tcl termina sem salvar as configurações do ensaio.

Consulte `fc.log`, `handoff.log`, `tool_exit_code.txt` e `reports/`.
`M10_READINESS_CHECKS_COMPLETED` significa que o diagnóstico chegou ao
fim. Os relatórios ainda mostram avisos e as lacunas de STA. O Scan DEF é
lido com `-syntax_only`. Os arquivos completos de tecnologia, DLIB, netlist,
SPF, Scan DEF e logs ficam no ambiente local.

## Executar o floorplan inicial

Com o mesmo ambiente e diretório de inserção M9:

```bash
./scripts/physical/run_floorplan.sh /caminho/da/execucao-de-insercao-m9
```

O Tcl deriva o contorno para aproximadamente 50% de utilização, cria
as rows, gera as trilhas e define as restrições das portas. O wrapper
salva e reabre `floorplan_initial`, compara a netlist com M9 e valida
a geometria contra o DEF. Consulte `validation.txt` e `floorplan.svg`
no diretório da execução. [Resultado do floorplan](../../docs/evidencias/M10_floorplan_inicial.md)

## Sequência planejada

| Etapa futura | Preparação e controles | Relatórios e métricas |
|---|---|---|
| Floorplan e PG | Derivar novo checkpoint de `scan_inserted`. Configurar direções de camada e RC, usar o site `unit`, definir die/core e margens, planejar pinos por interface e trilhos/mesh `VDD`/ `VSS`. Confirmar regra de tap/endcap da referência. Começar com núcleo aproximadamente quadrado e densidade nominal de 50% como hipótese de exploração. | Dimensões de die/core, área, utilização, site rows/tracks, acesso aos pinos, conectividade e DRC de PG, log e checkpoint. |
| Placement | Executar após validação de PG e da cobertura MMMC funcional e de teste. Manter a ordem M9 na primeira passagem e controlar a opção de reordenação. Verificar legalização. | Posicionadas/não posicionadas, `check_legality`, densidade, congestionamento, área, WNS/TNS, endpoints violados e DRVs por cenário, inventário e ordem de scan. |
| CTS | Confirmar referências de buffer/inversor e restrições em `clk`. Medir `scan_enable` como sinal de controle de alto fanout. Reavaliar hold de shift antes e depois de propagar clocks. | `report_clock_qor`, sinks, skew, latência, transição, área inserida, WNS/TNS e hold funcional e de teste. |
| Routing | Validar vias, regras e camadas, executar roteamento incremental e extrair RC para análise. Verificar continuidade e preservar pinos seriais/SE. | `check_routes`, DRC do roteador, opens/shorts, comprimento/vias, SPEF, área e WNS/TNS/DRV por corner e modo. |
| Verificações finais | Fechar coerência de netlist, Scan DEF e SPF. Se houver reordenação, reexportar e comparar a ordem, reconferir cadeia/DRC e rodar shift com a ordem final. Verificar metodologia, runsets e ferramentas de signoff conforme o ambiente. | Timing com parasitas, cobertura SDC, integridade de PG, hierarquia e scan. Potência com atividade e condições registradas. Distinguir verificação interna do FC de signoff independente. |

A referência funcional é 10 ns em `ss0p95v125c`. O modo funcional deve
fixar `scan_enable=0`. Para shift, o SPF fornece `clk` de 100 ns com
bordas 45/55 ns, `scan_enable=1` e reset síncrono inativo. Os delays/cargas
externos de `scan_in` e `scan_out` e as condições de captura ainda
precisam de especificação. Para análise min/max, selecionar PVT fast/slow
compatíveis com as bibliotecas e RC, revisar incertezas e medir cobertura.
Período de shift longo reduz pressão de setup, mas hold depende de skew,
caminhos curtos e parasitas. Congestionamento nas bordas, acesso ao PG e
carga de SE/clock devem orientar as primeiras iterações.
