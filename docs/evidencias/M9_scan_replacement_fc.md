# M9 — substituição de flip-flops por células scan

Em 2026-11-20, na branch `feat/m9-dft-scan`, o Fusion Compiler
`X-2025.06-SP2` substituiu **115 `DFFX1_RVT` por 115 `SDFFX1_RVT`**
em uma cópia de `pre_dft_protocol`. O candidato foi salvo como
`kuidamos_replacement.dlib:replacement_candidate.design`. O relatório de
scan paths indica zero cadeias. O VCS aprovou os 15 cenários funcionais
com scan desabilitado.

## Limites e tentativas

Consultei os manuais instalados de `compile_fusion`, `compile.seqmap.scan`,
`insert_dft` e `set_reference`. O estágio `initial_map` faz mapeamento e
otimização lógica. A receita local de `logic_opto` pode incluir auto-floorplan
e placement antecipado, como mostra o log do projeto UFE8 nesta máquina.
Por isso limitei as tentativas de compilação ao mesmo estágio de início e fim.
O log do precheck anterior cobria um intervalo maior em modo `-check_only`.

| Tentativa em cópia separada | Resultado observado |
|---|---|
| `compile_fusion -from initial_map -to initial_map` com scan habilitado | Converteu os 115 DFFs em 93 `SDFFSSRX1_RVT` e 22 `SDFFX1_RVT`, introduziu quatro ICGs e gerou V14. A validação rejeitou os 119 elementos sequenciais reportados. |
| Mesmo estágio, excluindo ICGs e `SDFFSSRX*` da seleção | Produziu 115 `SDFFX1_RVT` em `clk` e remapeou 1.141 para 990 combinacionais. O VCS registrou **3/15 cenários e 2.510 divergências**, com valores X aparecendo na saída. A causa detalhada da divergência do remapeamento continua em aberto. Esta base fica fora do preview. |
| Troca direta de referência no FC | Alterou as 115 referências e preservou as conexões de D, CLK, Q e QN. O VCS aprovou os 15 cenários. Esta é a base candidata para preview. |

Uma chamada inicial a `report_scan_path -test_mode all` falhou antes da
transformação com DFT-1546. Corrigi a chamada para `report_scan_path`, que
reportou a ausência de cadeias no ensaio final. Nas duas compilações, o
inventário reportou zero células posicionadas. A troca direta usa apenas os
comandos de edição lógica `set_reference`, `create_net` e `connect_net`.

## Inventário, função e timing

| Medida | Pré-DFT | Após troca direta |
|---|---:|---:|
| Células folha | 1.256 | 1.256 |
| Combinacionais | 1.141 | 1.141 |
| Sequenciais | 115 | 115 |
| `DFFX1_RVT` | 115 | 0 |
| `SDFFX1_RVT` | 0 | 115 |
| Clocks | 1 (`clk`, 10 ns) | 1 (`clk`, 10 ns) |
| ICGs, cadeias e células posicionadas | 0 | 0 |
| Referências não resolvidas | 0 | 0 |
| Área lógica de células (µm²) | 3.523,4524 | 3.757,2649 |
| Menor slack de setup reportado (ns) | +3,2354 | +3,1652 |
| Menor slack de hold reportado (ns) | +0,1641 | +0,2200 |

A área de células aumentou **233,8125 µm² (+6,64%)**. A folga de setup
diminuiu **0,0702 ns** e a de hold aumentou **0,0559 ns**. A comparação usou
`functional::ss0p95v125c` (SAED32 RVT, 0,95 V, 125 °C). O FC reportou
atraso zero de interconexão por falta de dados físicos. Os valores servem
para comparação lógica antes da conexão de scan.

O Tcl verificou os nomes das 115 instâncias e as redes em D, CLK, Q e QN
antes e depois. Todos os SDFFs têm pinos SE e SI, ambos conectados à constante
zero `m9_scan_disabled`. A porta `scan_enable` ainda está sem carga. O modelo
RVT seleciona D com SE baixo. Na simulação gate-level, mantive `scan_enable=0`
e `scan_in=0` e rodei o mesmo scoreboard M2/M7 no M8 e na netlist derivada
com VCS `X-2025.06-SP2_Full64`. **15/15 cenários, 2.618 ciclos e zero
divergências** em cada base. A adaptação retirou os monitores SVA que
dependem de sinais internos do RTL. A regressão apoia a preservação funcional
para os estímulos exercitados. Equivalência formal e timing com SDF ficaram
fora da verificação.

## Checks e DFT DRC

`check_design` reportou zero erros e 139 avisos antes e depois. A base contém
as três portas de teste ainda soltas, enquanto os 136 avisos históricos foram
contados antes da criação dessas portas. `check_timing -all` manteve os
1.256 avisos de scaling `TCK-014`, com zero erros. O FC retornou `1` no DRC,
com **115 elementos rastreados, zero excluídos e zero violações no resumo
pré-scan**. O relatório detalhado manteve **94 avisos**:

| Código | Pré-DFT → candidato | Interpretação |
|---|---:|---|
| B7 | 45 → 45 | Saídas diagnósticas sem driver e `scan_out` sem conexão. |
| B8 | 4 → 4 | Entradas funcionais sem uso e portas `scan_in` e `scan_enable` disponíveis para a próxima etapa. |
| B10 | 44 → 44 | Redes das saídas diagnósticas sem uso. |
| N20 | 1 → 1 | A ocorrência passou do UDP de `DFFX1_RVT` para `p_sdffx1_rvt_0`, modelo gerado de `SDFFX1_RVT`. |

V14 ocorreu apenas no ensaio com ICG. A troca direta não acrescentou classes
de avisos ao DRC pré-DFT. As licenças em uso foram
`Fusion-Compiler-NX` e `Fusion-Compiler-FE-NX`. O retorno do processo FC
e da simulação do candidato foi `0`.

## Reprodução

Use a raiz do repositório e a biblioteca da execução pré-DFT aprovada.
O Tcl cria a sua própria cópia em um diretório de trabalho novo.

```bash
root=$(pwd -P)
export SAED32_REF_ROOT=/opt/synopsys/labs/FC-DFT-synthesis-lab-2022.12/ref
export M9_PRE_DFT_LIB="$root/outputs/dft/runs/20261120T133126Z-TW0Czt/db/kuidamos_pre_dft.dlib"
run=$(mktemp -d "$root/outputs/dft/runs/replacement-XXXXXX")
(
    cd "$run"
    fc_shell -no_init -file "$root/scripts/dft/scan_replacement.tcl" > replacement.log 2>&1
)
"$root/scripts/dft/run_replacement_sim.sh" "$run" m8
"$root/scripts/dft/run_replacement_sim.sh" "$run" replacement
```

Na execução registrada, o candidato e os relatórios `before/`, `after/`
e `drc_work/` ficaram em
`outputs/dft/runs/20261120T140923Z-replacement-iV7Cbl/`. As tentativas de
`initial_map` ficaram em `20261120T140539Z-replacement-BrG5Er/`
e `20261120T140713Z-replacement-8KwlGH/`. Cada diretório guarda o Tcl
efetivamente executado. Os hashes de RTL, M8, execução pré-DFT e precheck
conferiram após as tentativas. Esses resultados permanecem no diretório
ignorado pelo Git.

**Próxima etapa** — abrir uma cópia nova de `replacement_candidate` e
executar `preview_dft` para verificar se o FC planeja a cadeia de 115 células
e as conexões futuras de SE e SI a partir das portas dedicadas. O preview
deve confirmar que as conexões temporárias a zero podem ser substituídas
pelas de scan. Revisar N20 no DRC e B7/B8 das portas após conexão real.
Nesta execução, preview, inserção, ATPG, placement e implementação física
ficaram pendentes.
