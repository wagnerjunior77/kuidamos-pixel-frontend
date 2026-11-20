# M9 — precheck de scan replacement

Em 2026-11-20, o Fusion Compiler `X-2025.06-SP2` concluiu com sucesso o
precheck de `initial_map` a `logic_opto`. A execução usou uma cópia do bloco
`pre_dft_protocol` da [execução pré-DFT](M9_pre_dft_fc.md), na branch
`feat/m9-dft-scan` e no commit `e41683582be41b2da12d7cdf14ef90ea50844c3d`.

A referência instalada de `compile.seqmap.scan` descreve a substituição por
células scan equivalentes durante a compilação quando a biblioteca oferece
suporte. A referência de `compile_fusion` confirma que `-check_only` verifica
design e biblioteca para o intervalo de estágios indicado. Sobre a cópia
do checkpoint, executei:

```tcl
open_lib [file normalize kuidamos_pre_dft.dlib]
open_block pre_dft_protocol
set_app_options -name compile.seqmap.scan -value true
compile_fusion -check_only -from initial_map -to logic_opto
```

- O comando retornou `1`, sem exceção Tcl. O processo encerrou com código `0`.
- O bloco permaneceu mapeado. Os nomes e referências das 1.256 células folha
  coincidiram antes e depois, incluindo 115 `DFFX1_RVT` e zero instâncias SDFF.
- As referências `SDFFX1_RVT` e `SDFFX2_RVT` estavam disponíveis na SAED32 RVT
  com `dont_use=false`. Após o precheck, o FC reportou `Fusion-Compiler-NX`
  e `Fusion-Compiler-FE-NX` em uso.
- O resumo registrou 32 avisos e zero erros. Foram 12 ocorrências de
  `LGL-397` (ausência de site rows) e 20 de `NEX-001` (direção de
  roteamento das camadas M1–M9 e MRDL, reportada duas vezes). Essas condições
  não bloquearam a checagem lógica. Seu efeito nas etapas posteriores permanece
  por verificar.

Classificação dos avisos registrados pelo DRC anterior:

| Aviso | Origem e efeito esperado |
|---|---|
| B7 (45) | 44 bits de saída diagnóstica do resize sem driver e `scan_out` ainda desconectado. As saídas diagnósticas estão fora dos caminhos funcionais. `scan_out` precisa estar conectado na cadeia inserida. |
| B8 (4) | `in_sol` e `in_eol` sem carga por arquitetura, além de `scan_in` e `scan_enable` ainda desconectados. As portas de scan precisam de conexão para a cadeia funcionar. |
| B10 (44) | Nets `SYNOPSYS_UNCONNECTED_*` ligadas às saídas diagnósticas sem uso do resize. Sem bloqueio identificado para substituição ou inserção. |
| N20 (1) | Transição subespecificada no UDP `p_dffx1_rvt_0`, do modelo gerado de `DFFX1_RVT`. O DRC anterior ainda classificou os 115 FFs como elegíveis. É uma pendência de modelagem a reavaliar no DRC após a substituição e antes de aceitar a cadeia inserida. |

O precheck não identificou bloqueio de licença, biblioteca, mapeamento ou
floorplan para **tentar a substituição lógica** em uma nova cópia. Ele não
confirma que a compilação efetiva converterá os 115 DFFs. Essa etapa deve
conferir a contagem de SDFFs, a equivalência funcional e os avisos do novo DRC
antes de seguir para a inserção.

O log e o Tcl efetivamente executado estão em
`outputs/dft/runs/20261120T135533Z-replacement-precheck-D5QIF1/`.
Os hashes do RTL, dos artefatos M8 e dos arquivos da execução pré-DFT original
conferiram antes e depois. Replacement, inserção, ATPG, placement e otimização
física ficaram fora da execução.
