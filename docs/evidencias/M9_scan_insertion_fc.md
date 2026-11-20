# M9 — inserção e validação da cadeia de scan

Em 2026-11-20, o Fusion Compiler `X-2025.06-SP2` executou `insert_dft`
em uma cópia de `replacement_candidate`, na branch `feat/m9-dft-scan`
com base em `e416835`. O comando retornou `1` e o processo saiu com
código `0`. A regressão funcional e a simulação de shift passaram no VCS
`X-2025.06-SP2_Full64`.

## Procedimento e limites

A execução copiou a biblioteca do [replacement](M9_scan_replacement_fc.md),
liberou exatamente os 230 terminais de `m9_scan_disabled` e repetiu
o [pré-DFT DRC e preview](M9_preview_dft_fc.md). Antes de inserir, o validador
confirmou 115 instâncias únicas, zero exclusões e a configuração de uma cadeia
sem compressão. A ajuda instalada de `insert_dft` descreve a inserção de
estruturas DFT. O fluxo executou apenas o stitching lógico da cadeia, com
compressão, wrapper, OCC e test points desabilitados. O log e a contagem de
células posicionadas confirmam a ausência de placement, CTS e roteamento físico.

O comando contém uma fase interna de simplificação lógica. A primeira
inserção sem proteção (`20261120T142346Z-insertion-hGOQvL`) retornou `1` e
conectou a cadeia, mas substituiu 27 somadores cuja saída de carry não era
usada por XORs. A checagem bloqueou o aceite desse resultado. Nas novas
cópias, apliquei `set_dont_touch` temporário às 1.141 combinacionais, deixando
os pinos dos SDFFs disponíveis ao motor DFT. Após a inserção, a checagem
confirmou os mesmos nomes, referências e ligações funcionais nas células
folha, e a proteção temporária foi retirada. O Verilog exportado chama a
rede de Q do último SDFF de `scan_out` devido ao alias do porto. As cargas
funcionais dessa rede foram preservadas.

Os ensaios de preparação também registraram limitações dos scripts: o Python
chamado pelo FC exigiu UTF-8 para imprimir o resultado do preview,
`get_scan_cells_of_chain` não aceitou neste caso o nome arquitetural da
cadeia e `check_scan_chain` imprimiu o resultado com retorno Tcl vazio.
O fluxo final analisou `report_scan_path` e `check_scan_chain` e percorreu
as redes por pino. O motor DFT fez todas as conexões de scan.

## Cadeia efetivamente conectada

| Item | Resultado |
|---|---|
| Modo e cadeia | `Internal_scan`, uma `KUIDAMOS_CHAIN` |
| Participantes | 115 `SDFFX1_RVT`, zero excluídos e zero `DFFX1_RVT` |
| Cabeça | `scan_in` → `cfg_crop_enable_q_reg/SI` |
| Enlaces internos | 114 conexões Q → SI, sem ciclo, bifurcação em SI ou descontinuidade |
| Cauda | `y_q_reg_9_/Q` → `scan_out` |
| Scan enable | `scan_enable` controla os 115 pinos SE |
| Clock e reset | `clk` nos 115 FFs, 10 ns em modo funcional e 100 ns no protocolo, com `reset_n=1` durante o teste |
| Tie-offs | Nenhum pino SE/SI ligado a `m9_scan_disabled` ou em aberto |
| Checagem SCANDEF do FC | Uma cadeia validada, zero falhas |

O grafo de conectividade gerou `post/actual_chain.tsv`. A ordem medida
coincidiu com as 115 posições do `report_scan_path` e com a previsão, após
comparação explícita. O validador conferiu os 115 enlaces de entrada/shift
e a saída serial diretamente na netlist exportada, além do nome, comprimento,
portas, clock e reset do SPF e das instâncias, pinos e pontas do Scan DEF.
Reabri uma cópia do checkpoint salvo em outra sessão do FC. O corpo do
Verilog exportado e o relatório da cadeia coincidiram com as primeiras
exportações, descontados os cabeçalhos de geração. A conferência está em
`checkpoint-readback-xam0UY/` na execução final.

## DRC, área e timing

`dft_drc -test_mode Internal_scan -verbose` retornou `1`. O resumo tem
**zero violações**, com **115 elementos rastreados na cadeia e sem violações**.
O relatório detalhado mantém **91 avisos**:

| Código | Pré-inserção → pós-inserção | Situação |
|---|---:|---|
| B7 | 45 → 44 | Saídas diagnósticas do resize sem driver. O aviso de `scan_out` desapareceu. |
| B8 | 4 → 2 | `in_sol` e `in_eol` sem uso. Os avisos de `scan_in` e `scan_enable` desapareceram. |
| B10 | 44 → 44 | Redes diagnósticas sem uso do resize. |
| B12 | 230 → 0 | Todos os SE/SI passaram a ter driver. |
| N20 | 1 → 1 | UDP `p_sdffx1_rvt_0` gerado pelo FC. Permanece registrado para revisão de modelagem. |

`check_design` reportou zero erros. Os 139 avisos estruturais incluem três
DCHK-026 sobre nomes das redes dos portos de scan. `check_timing -all`
reportou zero erros, 1.256 TCK-014 associados aos grupos de scaling e 231
TCK-001 de endpoints de scan no modo funcional: 115 SI, 115 SE e `scan_out`.
O script mediu setup/hold com `scan_enable=0` por case analysis no cenário
funcional e retirou essa configuração temporária antes de salvar.
O FC reportou `Fusion-Compiler-NX` e `Fusion-Compiler-FE-NX` em uso.

| Medida | M8 importado | Replacement | Pós-stitching |
|---|---:|---:|---:|
| Área lógica de células (µm²) | 3.523,4524 | 3.757,2649 | 3.757,2649 |
| Menor slack de setup reportado (ns) | +3,2354 | +3,1652 | +3,1652 |
| Menor slack de hold reportado (ns) | +0,1641 | +0,2200 | +0,2239 |

O stitching acrescentou zero área de células e manteve 1.256 células folha
(1.141 combinacionais e 115 sequenciais). A área permanece 6,64% acima do M8
importado, efeito do replacement. O timing usa o corner `ss0p95v125c` e
atraso zero de interconexão. A variação de hold de +0,0039 ns é diagnóstica.

## Simulações

- **Funcional** — VCS com `scan_enable=0` na netlist pós-scan.
  **15/15 cenários, 2.618 ciclos e zero divergências**. As linhas de resumo
  por caso coincidiram com a baseline de replacement. O scoreboard porta
  a porta verifica dados, controle e marcadores. Os monitores SVA dependentes
  de sinais internos permaneceram fora desse teste gate-level.
- **Shift** — **460 pulsos verificados**, em quatro fases de 115. O teste
  aplicou zeros, uns e alternado, depois capturou funcionalmente um pixel
  branco 1×1 e extraiu o estado capturado. Comparou `scan_out` antes de cada
  borda e o Q dos 115 SDFFs depois da borda, seguindo a ordem medida.
  Durante o shift, `scan_enable=1` e `reset_n=1`.

Ambas as simulações retornaram `0`. Foram executadas com o modelo Verilog
SAED32 RVT e `+notimingcheck`. A evidência cobre comportamento lógico
gate-level e segue sem validação temporal com SDF.

## Reprodução e artefatos

Na raiz do repositório, com as ferramentas e bibliotecas já configuradas:

```bash
root=$(pwd -P)
export M9_REPLACEMENT_RUN="$root/outputs/dft/runs/20261120T140923Z-replacement-iV7Cbl"
export SAED32_REF_ROOT=/opt/synopsys/labs/FC-DFT-synthesis-lab-2022.12/ref
run=$(mktemp -d "$root/outputs/dft/runs/insertion-XXXXXX")
(
    cd "$run"
    result=0
    timeout -k 10s 240s fc_shell -no_init -file "$root/scripts/dft/insert_scan.tcl" \
        > insertion.log 2>&1 || result=$?
    printf '%s\n' "$result" > tool_exit_code.txt
)
python3 "$root/scripts/dft/check_scan_exports.py" "$run" &&
    "$root/scripts/dft/run_replacement_sim.sh" "$run" post_scan &&
    "$root/scripts/dft/run_shift_sim.sh" "$run"
```

A execução validada está em `outputs/dft/runs/20261120T142703Z-insertion-jTvumJ/`.
Foram gerados:

- `kuidamos_preview.dlib:scan_inserted.design`, checkpoint derivado.
- `post/scan_netlist.v`, `post/scan_protocol.spf` e `post/scan.def`.
- Relatórios de inserção, DRC, cadeia, conectividade, área, referências,
  estrutura, timing e licenças em `post/`.
- Ordem medida, validação cruzada de exportação e logs em `post/`,
  `sim-post_scan-*/` e `sim-shift-*/`.

Os hashes de RTL, testbench, artefatos M8 e execuções anteriores conferiram.
Os arquivos de execução ficam em `outputs/dft/`, ignorado pelo Git.
Os 91 avisos foram preservados para revisão. A etapa de conexão e validação
lógica está demonstrada. ATPG, simulação temporal e implementação física
continuam separados desta entrega.
