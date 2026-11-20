# M9 — preview da cadeia de scan no Fusion Compiler

Em 2026-11-20, `preview_dft` retornou `1` no Fusion Compiler
`X-2025.06-SP2`. O processo saiu com código `0`. A execução usou uma cópia
de `replacement_candidate` da [execução de replacement](M9_scan_replacement_fc.md),
na branch `feat/m9-dft-scan`, com base em `e416835`.

| Item | Resultado |
|---|---|
| Cadeia prevista | Uma cadeia sem compressão, `KUIDAMOS_CHAIN`, no modo `Internal_scan` |
| Comprimento e cobertura | 115 `SDFFX1_RVT`, cada instância do inventário presente exatamente uma vez |
| Excluídos | 0 |
| Entrada e saída | `scan_in` → `scan_out` |
| Enable | `scan_enable`, ativo em 1 |
| Clock | `clk`, borda de subida em 45 ns no protocolo de teste, descida em 55 ns e período de 100 ns |
| Cenário funcional | Clock único `clk`, período de 10 ns |
| Reset síncrono | `reset_n=1` no setup do teste e nas quatro declarações de captura/launch do SPF preliminar |
| Cadeias conectadas no bloco | 0, conforme `report_scan_path` e `get_scan_chain_count` |

A ordem completa está em `reports/planned_chain.tsv`. O primeiro elemento é
`cfg_crop_enable_q_reg` e o último é `y_q_reg_9_`. O preview relatou zero
células que violaram as regras DFT. Os termos da cadeia foram comparados por
nome com o inventário dos 115 SDFFs, inclusive para detectar duplicatas.

## Configuração e tratamento dos tie-offs

A ajuda instalada de `set_scan_configuration` (manual e `help -verbose`)
não lista `-replace`. O fluxo usou `-chain_count 1 -clock_mixing no_mix` e
`set_scan_path KUIDAMOS_CHAIN -scan_data_in scan_in -scan_data_out scan_out
-scan_enable scan_enable`. O DRC aceitou os SDFFs existentes e o preview os
usou sem compilação, remapeamento ou nova troca de referência.

O manual de `dft.scan.test_keep_connected_scan_en` documenta que o motor de
inserção pode desconectar conexões anteriores nos pinos identificados como
alvos de scan enable quando a opção vale `false`, como neste checkpoint.
Essa opção trata SE. A ajuda consultada não dá a mesma garantia para os
tie-offs em SI. O procedimento validado evita depender de desconexão automática:

1. Abrir uma cópia nova de `replacement_candidate` e conferir que a rede
   `m9_scan_disabled` tem exatamente os 115 pinos SE e os 115 pinos SI.
2. Desconectar esses terminais com
   `disconnect_net -net $tie $pins`. O comando retornou **230**. As redes
   de D, CLK, Q e QN coincidiram com o inventário salvo no replacement.
3. Configurar sinais, caminho e protocolo e executar `dft_drc -verbose`
   e `preview_dft` na mesma sessão. Usar a cópia com SE/SI liberados apenas
   para o fluxo DFT. O candidato original conserva a constante zero para
   regressão funcional.

O preview registrou uma fase interna chamada `Scan Stitching`. O inventário
sequencial antes e depois é idêntico, o corpo da netlist exportada também e o
bloco continuou sem cadeias. O Tcl não salva um novo checkpoint com SE/SI
flutuantes. A ordem prevista precisa ser comparada à cadeia conectada em
uma execução futura.

## Avisos e decisão

O DRC de entrada retornou `1`. O resumo registra **zero violações e zero FFs
excluídos**, com 115 elementos rastreados. Os relatórios detalhados registram:

| Código | Antes → após liberar SE/SI | Observação |
|---|---:|---|
| B7 | 45 → 45 | Inclui `scan_out` sem driver. |
| B8 | 4 → 4 | Inclui `scan_in` e `scan_enable` sem carga. |
| B10 | 44 → 44 | Redes das saídas diagnósticas sem uso. |
| N20 | 1 → 1 | UDP gerado de `SDFFX1_RVT`, a revisar após a conexão da cadeia. |
| B12 | 0 → 230 | Exatamente os pinos SE e SI liberados. |

Total detalhado de **324 avisos**, dos quais 230 são esperados nessa preparação.
O log também registra DFT-2004 pela reaplicação dos sinais, LGL-397 pela
ausência de site rows e POW-034 durante a estimativa interna de potência do
preview. A configuração funcional e o relatório de cadeia mantiveram `clk`.
As licenças reportadas foram `Fusion-Compiler-NX` e `Fusion-Compiler-FE-NX`.

A arquitetura está pronta para uma tentativa controlada de inserção em
uma nova cópia. Repetir a preparação e o preview, prosseguir para
`insert_dft` somente na etapa autorizada e comprovar no resultado que todos
os SE recebem `scan_enable`, a cabeça recebe `scan_in`, os 114 enlaces
internos e a saída fecham a cadeia e nenhum SE/SI permanece em tie-off ou
sem driver. Verificar D/CLK/Q/QN funcionais, repetir DRC e simular shift e
modo funcional. A inserção ainda depende dessa validação real.

## Reprodução

```bash
root=$(pwd -P)
export M9_REPLACEMENT_RUN="$root/outputs/dft/runs/20261120T140923Z-replacement-iV7Cbl"
run=$(mktemp -d "$root/outputs/dft/runs/preview-XXXXXX")
(
    cd "$run"
    result=0
    timeout -k 10s 180s fc_shell -no_init -file "$root/scripts/dft/preview_scan.tcl" \
        > preview.log 2>&1 || result=$?
    printf '%s\n' "$result" > tool_exit_code.txt
)
python3 "$root/scripts/dft/check_preview.py" "$run"
```

A execução registrada está em `outputs/dft/runs/20261120T141512Z-preview-GLHrxy/`.
Consulte `preview.log`, `reports/preview_dft.rpt`,
`reports/pre_preview_drc.rpt`, `reports/dft_violations_details.rpt` e
`reports/physical_scan_paths.rpt`. Os resultados e a cópia da biblioteca
ficam em `outputs/dft/`, ignorado pelo Git.

Os hashes dos arquivos versionados de RTL e M8 e das execuções de
pré-DFT, precheck e replacement conferiram após o preview. Inserção, ATPG
e implementação física permanecem pendentes.
