# KUIDAMOS 6C — resultado final do M9 no escopo de scan

Revisão de 2026-11-20. **M9 concluído no escopo de inserção e validação
lógica de scan.** A evidência cobre o DRC, uma cadeia de 115 células, a
conectividade pós-inserção e a simulação funcional e de shift. ATPG e
implementação física têm entregas e critérios próprios. [Escopo oficial,
seção 6C](../referencias/definicao_escopo_grupo_6_oficial.pdf).

## Metodologia e resultado

A base é a netlist mapeada e o SDC de M8, preservados com o RTL e o
testbench. O fluxo usou Rocky Linux 8.10, Fusion Compiler `X-2025.06-SP2`
com `Fusion-Compiler-NX` e `Fusion-Compiler-FE-NX`, motor DRC integrado
TestMAX/TetraMAX `X-2025.06-SP3` e VCS `X-2025.06-SP2_Full64`. A análise
lógica usou a SAED32 RVT `ss0p95v125c` (0,95 V, 125 °C, processo 0,99).

1. Importação de M8, configuração de sinais de teste e pré-DFT DRC. O FC
   rastreou os 115 DFFs e registrou zero violações no resumo.
   [Pré-DFT](M9_pre_dft_fc.md).
2. Precheck, troca de referência dos DFFs por `SDFFX1_RVT` com
   `set_reference -pin_rebind safe` e verificação funcional com SE e SI
   em zero. A troca preservou D, CLK, Q e QN. O ensaio com `initial_map`
   havia remapeado lógica e falhado na regressão.
   [Precheck](M9_scan_replacement_precheck.md) · [Replacement](M9_scan_replacement_fc.md).
3. Liberação dos 230 terminais SE/SI na cópia de trabalho, novo protocolo e
   `preview_dft`. O preview incluiu 115 instâncias únicas em uma cadeia sem
   compressão. [Preview](M9_preview_dft_fc.md).
4. `insert_dft` em uma cópia nova, com proteção temporária das 1.141 células
   combinacionais. A primeira inserção havia substituído 27 somadores por
   XORs e foi rejeitada pela conferência de integridade. A execução final
   preservou as referências e conexões funcionais e retirou a proteção
   antes de salvar. [Inserção e simulações](M9_scan_insertion_fc.md).

| Verificação | Resultado da execução final |
|---|---|
| Arquitetura | Uma `KUIDAMOS_CHAIN` de 115 `SDFFX1_RVT`, de `scan_in` a `scan_out`, com 114 enlaces Q→SI, zero excluídos e zero DFFs originais |
| Controle de scan | 115 SE em `scan_enable`, ativo alto. O `clk` é comum aos 115 SDFFs. O SPF mantém `reset_n=1` nos procedimentos de teste. Período de teste de 100 ns, bordas de 45 e 55 ns |
| DFT DRC `Internal_scan` | Zero violações no resumo, 115 elementos na cadeia sem violações e 91 avisos detalhados |
| Funcional no VCS com `scan_enable=0` | 15/15 cenários, 2.618 ciclos e zero divergências. Resumos por caso iguais aos do replacement |
| Shift no VCS com `scan_enable=1` | 460 pulsos verificados. Três blocos de 115 bits com zeros, uns e alternado, seguidos da extração de 115 bits após captura de pixel branco 1×1 |
| Área lógica | 3.757,2649 µm², igual ao replacement e 6,64% acima do M8 importado. 1.256 células folha, das quais 1.141 combinacionais |
| Timing funcional diagnóstico | Setup +3,1652 ns e hold +0,2239 ns, a 10 ns com `scan_enable=0`, sem parasitas e com atraso zero de interconexão |

## Revisão dos 91 avisos pós-scan

O `report_dft_drc_violations` separa avisos de netlist/modelagem e de build.
A documentação instalada de `dft_drc` explica que avisos exigem análise e
podem excluir células, enquanto ocorrências fatais podem impedir comandos.
Na revisão atual, `report_rules -verbose` do TestMAX foi consultado sem
carregar o design ou gerar padrões. B7, B8, B10 e N20 constam como
`warning`. A consulta isolada mostra a definição das regras. As contagens
abaixo vêm da execução pós-scan. Referências locais:
`dft_drc.2`, `report_dft_drc_violations.2` e
`outputs/dft/runs/20261120T143629Z-m9-review-WiIXAv/native_rules.log`.

| Aviso | Classificação | Evidência e justificativa |
|---|---|---|
| B7 (44) | Não impeditivo para scan | Quatro saídas diagnósticas de 11 bits de `resize_nn_core`: `out_width`, `out_height`, `x_out`, `y_out`. Os 44 bits sem driver não alimentam a cadeia nem as saídas funcionais do topo. A ocorrência de `scan_out` desapareceu após a ligação. |
| B8 (2) | Não impeditivo para scan | `in_sol` e `in_eol` existem na interface, sem cargas na netlist. As ocorrências de `scan_in` e `scan_enable` desapareceram. |
| B10 (44) | Não impeditivo para scan | As 44 redes `SYNOPSYS_UNCONNECTED_*` no modelo do DRC correspondem, uma a uma, aos mesmos bits diagnósticos de B7. A inspeção não encontrou outra ligação de instância para essas redes. |
| N20 (1) | Não impeditivo para o scan validado. Impacto em ATPG ainda não esclarecido | A tabela do UDP sequencial gerado para `SDFFX1_RVT` está subespecificada quando o clock sobe com `SE=X`. O DRC rastreou as 115 células e o VCS passou com SE definido. O caso com SE desconhecido e o efeito na geração de padrões permanecem fora da validação. |

B12 caiu de 230 para **zero** após a conexão. A netlist exportada também
está livre da rede temporária `m9_scan_disabled`. Nenhum aviso foi
suprimido e os modelos tecnológicos foram usados como fornecidos.

### N20 e a condição com SE desconhecido

O aviso referencia a linha 594 de `post_drc_work/comboLib_31330.1000.v`.
O arquivo foi gerado pelo FC para o checker. A célula é `SDFFX1_RVT` e
o UDP sinalizado é `p_sdffx1_rvt_0`, que implementa Q com entradas na
ordem CLK, SE, D e SI. O outro UDP da célula, para QN, fica fora desse
aviso. A mensagem do motor indica a condição de borda positiva com
SE desconhecido. A tabela tem casos de captura para SE=0 e SE=1,
mas omite tratamento explícito para essa borda com SE=X. O retorno
indicado pelo checker para o caso omitido é X.

O VCS usou a biblioteca Verilog RVT fornecida pela SAED32, na qual o
SDFF é modelado por um mux seguido de flip-flop. O mux do modelo Verilog
pode resolver o caso de seletor desconhecido se D e SI estiverem
iguais e definidos. A tabela do UDP gerado pelo FC e o modelo de
simulação são representações diferentes. Isso explica por que o N20
merece acompanhamento mesmo com os testes de VCS aprovados. A
regressão e o shift mantiveram SE em 0 ou 1 nas bordas relevantes.
Em um fluxo ATPG, um SE indeterminado pode propagar X ou reduzir
observabilidade na simulação de falhas, dependendo do modelo e do
protocolo carregados. Nenhum efeito em cobertura foi medido ou inferido.

## Auditoria dos artefatos e reprodução

A execução original está em
`outputs/dft/runs/20261120T142703Z-insertion-jTvumJ/`. O script
`check_scan_exports.py` cruzou as 115 instâncias e a ordem medida com
`report_scan_path` e a netlist. Verificou ainda os 115 SEs, a conexão
das duas pontas, o comprimento e sinais do SPF e os membros e pinos do
Scan DEF. A ordem medida também coincidiu com o preview. O checkpoint
`kuidamos_preview.dlib:scan_inserted.design` foi reaberto em cópia
separada. A netlist e o relatório de cadeia reexportados conferiram.

Na revisão, a validação de exportação foi repetida sobre os arquivos já
gravados. Os manifests de entrada de VCS, os hashes de RTL/M8/testbench e
os das execuções anteriores conferiram. Não houve nova síntese,
inserção ou regressão. Use os SHA-256 abaixo para identificar os arquivos
da execução original. Relatórios integrais, netlist, SPF, Scan DEF,
banco, modelos temporários e logs de simulador ficam em `outputs/dft/`
local. O Git recebe scripts e evidência textual.

| Arquivo relativo à execução | SHA-256 |
|---|---|
| `post/scan_netlist.v` | `6e086a05ad9fa61d34258b7ef070d1d811b8ee5ec8b6c2381fc209ceee32d29d` |
| `post/scan_protocol.spf` | `885d527feaf92d5d919934a7aa0e2737f16a5b91a2b3d66c82bbcac3ae3ed91f` |
| `post/scan.def` | `80d6ae1d36d2051ffda9105cc6434b4d97d53ce6ed8bc6935bb413b259ef48db` |
| `post/actual_chain.tsv` | `d69948ee1d973eba0777de18732d3f70936006c5a86eac882a8d57380e36e30b` |
| `post/dft_drc.rpt` | `fe5fbba3cfeb69a3f699c72e6dbff25aa8ab002f89a0214a668f92499d25815d` |
| `post/dft_violations_details.rpt` | `50cfd92913087218f805deed54f45dfdb6dd8a3760be173c45996ba1f4b346e4` |
| `sim-post_scan-4EbeDG/simulation.log` | `cbd71719d108733e9d4ed26d5052571441e8f9c09a2e82c271ea746869f006e5` |
| `sim-shift-bE01Bw/simulation.log` | `4f4118e3786699a8ec2c90a416aed8c5e3fe108135622f15e122c4a2d7ac9139` |

As instruções parametrizadas, pré-requisitos e pressupostos sobre a
biblioteca e a versão da ferramenta estão no [guia do fluxo](../../scripts/dft/README.md).

## Limites acadêmicos e trabalho posterior

- **Simulação lógica gate-level.** Os 15 cenários e os quatro blocos de
  shift verificaram comportamento com sinais de teste definidos, sem
  SDF e com `+notimingcheck`. A regressão gate-level usou o scoreboard
  de portas. O monitor SVA dependente de sinais internos permaneceu
  fora da execução. Equivalência formal e comportamento com SE=X não
  foram demonstrados.
- **Timing diagnóstico.** Setup e hold usam atraso zero de
  interconexão. A checagem reportou 1.256 avisos TCK-014 pela ausência de
  grupos de scaling e 231 TCK-001 em endpoints de scan no modo funcional
  (115 SI, 115 SE e `scan_out`). Os valores não sustentam frequência
  física, timing de shift pós-layout nem signoff.
- **ATPG.** Pendente confirmar a feature de geração no CIExpert. A
  consulta anterior a `Test-ATPG` retornou SEC-51, apesar de o shell
  abrir com `Test-Analysis-P4`. Com licença confirmada, carregar netlist,
  modelos e SPF correspondentes, validar construção e DRC, reexaminar
  N20 e a controlabilidade de SE, gerar padrões stuck-at e registrar
  cobertura e contagens reais. Transition exige protocolo de captura
  adequado. Cobertura de falhas e simulação de padrões ATPG não foram
  medidas.
- **M10.** Usar o checkpoint e Scan DEF como entrada para floorplan,
  placement, eventual reordenação de scan, CTS, roteamento e extração.
  Revalidar a cadeia, a correspondência do SPF e o timing funcional e de
  teste com parasitas. A ordem física pode mudar com reordenação.
