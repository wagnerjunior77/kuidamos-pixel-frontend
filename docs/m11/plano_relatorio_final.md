# Planejamento do relatório técnico final

M11 iniciado em 25/11/2026, a partir da `main` que integrou o M10 no
commit `3fb7875bcb8b8384203fadbcdb11a5fa0fbd7e10`. Este roteiro
registra o planejamento da redação e da revisão. A versão de entrega
inclui os resultados dos dois ensaios de imagem real e as figuras da
execução de detalhe. Em 27/11/2026, Wagner confirmou o retorno positivo
de Thiago. A matriz liga os requisitos oficiais aos resultados medidos.
[Matriz de rastreabilidade](matriz_rastreabilidade.md) · [Relatório PDF](KUIDAMOS_6C_relatorio_tecnico.pdf) · [Manual](manual_reproducao.md)

## Inventário da documentação existente

A base do merge tem 44 arquivos em `docs/`, incluindo o PDF oficial,
24 documentos Markdown e 19 imagens. Os guias ao lado do código
complementam o inventário.

| Conjunto | Arquivos e uso previsto |
|---|---|
| Escopo e gestão | [PDF oficial](../referencias/definicao_escopo_grupo_6_oficial.pdf), [Contexto 6C](../CONTEXTO_TECNICO_6C.md), [Spec V1](../spec_v1.md), [Plano](../plano_de_execucao.md), [Decisões e pendências](../DECISOES_E_PENDENCIAS.md), [README](../../README.md) e [AGENTS](../../AGENTS.md). O contexto preserva a numeração preliminar. Usar a numeração do plano vigente no relatório |
| M1–M2 | [Modelo](../evidencias/M1_modelo_python.md), [Imagem real](../evidencias/M1_imagem_real.md), [Vetores](../evidencias/M2_vetores.md), [Experimento de estacionamento](../experimentos/analise_preprocessamento_imagens.md), [guia Python](../../model/README.md) e [guia dos vetores](../../vectors/README.md) |
| Figuras de referência | [Microexemplo M1](../imagens/m1) com RGB, grayscale, crop, resize e threshold. [Estacionamento](../experimentos/estacionamento) com entradas, etapas intermediárias, cinco limiares e comparativos. Verificar escala, fonte e legenda antes de reutilizar |
| M3–M7 | [RTL](../../rtl/README.md), [testbench](../../tb/README.md) e [relatório dos 15 casos e oito SVA](../evidencias/M3_M7_verificacao_vcs.md). A pasta de saídas VCS mantém os logs selecionados |
| M8 | [Guia de síntese](../../scripts/synthesis/README.md) e [relatório DC](../evidencias/M8_sintese_dc.md), com SDC, netlist mapeada e relatórios selecionados em `outputs/synthesis/` |
| M9 | [Pré-DFT](../evidencias/M9_pre_dft_fc.md), [precheck de replacement](../evidencias/M9_scan_replacement_precheck.md), [replacement](../evidencias/M9_scan_replacement_fc.md), [preview](../evidencias/M9_preview_dft_fc.md), [inserção](../evidencias/M9_scan_insertion_fc.md), [resultado final](../evidencias/M9_resultado_final.md) e [guia DFT](../../scripts/dft/README.md) |
| M10 | [Preparação](../evidencias/M10_preparacao_physical.md), [floorplan](../evidencias/M10_floorplan_inicial.md), [power planning](../evidencias/M10_power_planning.md), [placement](../evidencias/M10_placement_inicial.md), [correção PG](../evidencias/M10_correcao_pg_placement.md), [CTS](../evidencias/M10_cts_inicial.md), [routing](../evidencias/M10_routing_inicial.md), [resultado final](../evidencias/M10_resultado_final.md) e [guia físico](../../scripts/physical/README.md) |
| Handoffs locais | `outputs/dft/` contém o checkpoint de scan, SPF, Scan DEF, netlist e relatórios M9. `outputs/physical/` contém checkpoints, inclusive `physical_final`, netlist final, DEF, Scan DEF, SVGs, SPEF, SDF, SAIF, logs e manifestos. A evidência M10 aponta a execução e os hashes |

## Estrutura proposta

| Capítulo | Conteúdo a preparar | Fonte principal e material a reaproveitar |
|---|---|---|
| 1. Introdução e objetivos | Contexto KUIDAMOS/CIExpert, problema, posição do IP a jusante da decodificação e objetivos acadêmicos | PDF §§6.1–6.2 e README. Apresentar a contribuição do grupo e a independência do IP |
| 2. Especificação do IP | Formatos, sinais, reset, latência, configuração por SOF, geometria válida, rejeição e recuperação | Tabela de interface e exemplos da Spec V1. Registrar a motivação de engenharia e o contrato dos fatores 1 e 2 por eixo |
| 3. Arquitetura e microarquitetura | Caminho de dados, controle e contadores, aritmética inteira, retenção de configuração e regeneração dos marcadores | Diagrama textual do README e do contexto. Desdobrar em figura funcional e em um exemplo temporal anotado a partir da Spec V1 |
| 4. Modelo de referência | Equações, origem dos índices, entradas, saídas, seeds e geração temporal. Experimento visual como caso complementar | Guias Python/M2 e comparativo de estacionamento. Mostrar uma figura de etapas e a condição do experimento |
| 5. Implementação RTL | Módulos SystemVerilog, larguras, interfaces, contadores de 11 bits, somas de 12 bits e registradores de saída | RTL, guia RTL e Spec V1. Cruzar fórmulas e decisões da V1 com os nomes realmente implementados |
| 6. Verificação funcional | Arquitetura do testbench, vetores, scoreboard, cobertura dos casos, reset, flags, SVA e testes negativos | Tabelas VCS M3–M7, documentação TB e vetores. Identificar o que o VCS RTL e os testes gate-level exercitam |
| 7. Síntese lógica | Preparação, biblioteca, corner, SDC de 10 ns, mapeamento, área, caminhos e potência estimada | Relatório DC de M8. Registrar versão, modelo de carga de fio e comparabilidade dos números |
| 8. DFT e scan insertion | Pré-DRC, replacement, preview, inserção, protocolo, cadeia de 115 elementos e testes de shift | Evidências M9, SPF e Scan DEF locais. Preparar um esquema de `scan_in → 115 SDFFs → scan_out`, com SE, clock e reset |
| 9. Implementação física | Handoff, floorplan, PG, rails M1, placement, pinos, CTS, routing, ECO e readback de `physical_final` | Evidências M10. Consultar os SVGs locais de floorplan, clock e routing para selecionar figuras que possam ser divulgadas |
| 10. Resultados de área, timing e potência | Uma tabela M8/M9/M10 de área de células, STA por cenário, DRVs, cobertura e composição de potência M10 | Evidências finais com identificação de PVT, frequência, estimativa de carga, RC extraído, SAIF e limites. Manter o PVT e a metodologia na legenda |
| 11. Manual de reprodução | Pré-requisitos, versões, comandos, diretórios de trabalho, dependências entre marcos, critérios de sucesso e hashes | Guias Python, vetores, RTL, VCS, síntese, DFT e físico. Indicar licença, referência SAED32 e uso de checkpoints em cópia |
| 12. Limitações e trabalhos futuros | Restrições V1 e pendências de validação, DRC residual M9, SDF/MMMC, ATPG, equivalência e qualificação física | Matriz e evidências M9/M10. Explicar o impacto de cada limitação e a condição necessária para reavaliá-la |
| 13. Conclusão | Retomar objetivos, resultados demonstrados, cobertura e fronteira da entrega acadêmica | Matriz revisada, tabelas consolidadas e conclusão de M0–M11 no escopo acadêmico |

## Sequência de redação e revisão

1. Fixar o baseline de revisão, as fontes oficiais e a tabela de resultados. Conferir unidades e condições de cada relatório, especialmente SAIF/RC do M10 e atividade estimada do M8.
2. Registrar a decisão de engenharia do resize V1 e a demonstração principal em (1,1). Conferir o ensaio inicial RTL e gate-level e os seis casos da demonstração de detalhe RTL. A licença da foto fica registrada como desconhecida.
3. Redigir os capítulos e preparar legendas com origem, configuração e limite de cada figura. Manter o material restrito no handoff local com referências e hashes.
4. Consolidar o manual do teste Python ao readback físico. Usar a ordem M0–M11 vigente. Marcar os pontos que exigem Synopsys, SAED32 e dados locais, incluindo a cadeia M9 para o fluxo M10.
5. Fazer leitura cruzada da parte de RTL/síntese com Thiago e da parte de DFT com Wagner. Conferir conjuntamente as métricas físicas e revisar o alinhamento do texto com o PDF. A revisão do projeto relatada por Wagner está registrada no checklist.
6. Fechar o M11 quando os 13 capítulos, referências, matriz, manual e limitações estiverem conferidos e a revisão final estiver registrada.
