# Plano de execução — Grupo 6C

Data: 2026-10-28. Horizonte aproximado de cinco meses, sujeito a revisão e disponibilidade do CIExpert. A especificação `spec_v1.md` é a base da V1. Caminhos de etapas futuras são sugestões; resultados executados estão identificados nas respectivas evidências.

Atualização em 2026-11-03: **M0 concluído internamente**, por decisão explícita do responsável pelo projeto; restrição de resize sujeita à validação do professor. **M1 funcional executado**, com 18 testes Python aprovados e evidência em `docs/evidencias/M1_modelo_python.md`. O gerador oferece vetor funcional inicial; a ampliação e os vetores temporais pertencem a M2. As etapas EDA dependem de infraestrutura identificada e evidências reais.

Atualização em 2026-11-04: **M2 implementado e validado localmente** com nove cenários e 29 testes Python na regressão completa. Os arquivos, formato e limitações estão em `docs/evidencias/M2_vetores.md`. A integração com o futuro testbench e VCS ainda não foi executada; M3 não foi iniciado.

## Dependências e evidências

`M0 especificação → M1 modelo → M2 vetores → M3 passagem/grayscale → M4 crop → M5 resize → M6 threshold/integração → M7 regressão → M8 síntese → M9 DFT → M10 físico → M11 documentação`. Scoreboard e assertions crescem desde M3; M7 consolida. Diagnóstico de ferramentas pode ocorrer cedo, sem pressupor licenças ou bibliotecas. Cada marco registra versões, comando, data, configurações, código de saída, logs e limitações; dados protegidos ficam fora do versionamento.

## Responsáveis propostos

Divisão interna proposta por Wagner, **pendente de alinhamento com Thiago**; não é requisito do PDF oficial.

| Marco | Responsável e colaboração | Situação |
|---|---|---|
| M0 | Wagner (DFT), com revisão de Thiago | Concluído internamente |
| M1 | Wagner (DFT), com revisão de Thiago | Implementação inicial concluída |
| M2 | Wagner, com revisão de Thiago | Implementado e validado localmente; revisão de Thiago pendente |
| M3, M4, M5 e M6 | Thiago (RTL), com revisão de Wagner | A realizar |
| M7 | Thiago (RTL), com apoio de Wagner | A realizar |
| M8 | Wagner (DFT), com apoio de Thiago | A realizar |
| M9 | Wagner (DFT) | A realizar |
| M10 | Wagner e Thiago | A realizar |
| M11 | Wagner e Thiago | A realizar |

As atribuições de revisão descrevem a proposta de organização; não afirmam que a revisão já ocorreu.

| Marco | Entrega e dependência | Comando indicativo e PASS | Evidência esperada |
|---|---|---|---|
| M0 — especificação — CONCLUÍDO INTERNAMENTE | `docs/spec_v1.md`, registro de decisões e plano; definição dos limites e protocolo | Decisões internas V1 aprovadas pelo responsável pelo projeto | Decisões registradas em `docs/DECISOES_E_PENDENCIAS.md`; validação do professor para resize pendente |
| M1 — Golden Model | `model/golden.py`, `model/tests/`, `model/README.md`; operações inteiras e fórmula geral independente | `python -m unittest discover -s model/tests -v`; 18 testes passaram na execução registrada | `docs/evidencias/M1_modelo_python.md` |
| M2 — vetores | `model/m2_vectors.py`, `model/tests/test_m2_vectors.py`, nove casos em `vectors/m2/` | `python -m model.m2_vectors --output-dir vectors/m2 --check` e regressão Python; 28 arquivos idênticos e 29 testes passaram localmente | `docs/evidencias/M2_vetores.md`; integração VCS ainda não executada |
| M3 — passagem e grayscale | `rtl/`, `tb/` iniciais após M2; caminho RGB para cinza; passagem é marco temporário de infraestrutura | Em Linux CIExpert, comando VCS exato será documentado após versão e arquivos existirem; PASS = compilação e scoreboard de valores, flags, latência, bolhas e reset | Logs de compilação e simulação, versão VCS, cenários e divergências |
| M4 — crop | M3 + seleção ROI e bypass conforme a especificação | Regressão VCS documentada no marco; PASS = contagens, bordas, ROI 1×1 e flags corretos; inválidos rejeitados | Logs e vetores centro/borda/bypass/inválidos |
| M5 — resize NN | M4 + fatores especificados | Regressão VCS; PASS = seleção conforme fórmula geral, casos pares/ímpares, eixos independentes, contagens e marcadores | Log comparando cada pixel e flags com modelo independente |
| M6 — threshold e integração | M5 + comparador e bypass | Regressão VCS; PASS = T=0/255, igualdade e vizinhança, bypass e composição completa | Logs de casos e divergências, versões e seed |
| M7 — verificação consolidada | `tb/` com scoreboard, SVA e `reports/verification/`; depende M6 | Regressão VCS com comando reproduzível documentado; PASS = todos os cenários obrigatórios, nenhuma divergência ou violação SVA não justificada | Resumo total de casos, falhas, propriedades, logs e hashes dos vetores; PNG complementares |
| M8 — síntese/timing | `scripts/synthesis/`, `constraints/`, relatórios DC; após M7 e identificação do ambiente | Comando DC/constraints conforme versão e fluxo reais; PASS de execução = síntese sem erro impeditivo e relatórios de área, caminhos e violações com 10 ns; fechamento é resultado separado | Versão, biblioteca/PDK identificados, constraints, log e relatórios; não impor meta de área/potência |
| M9 — DFT/scan | `dft/`, relatórios de pré/pós DFT; depende M8 e ambiente | Comandos reais do fluxo TestMAX DFT, incluindo `dft_drc`, `preview_dft` e inserção quando suportada; PASS = execução reproduzível, DRC/violações e scan documentados | Logs, configuração e relatórios antes/depois; limitações explícitas. ATPG/pattern sim são extensão, somente após confirmação de escopo, ferramenta e licença |
| M10 — físico | `physical/`, relatórios Fusion Compiler; depende M9 e tecnologia disponível | Fluxo `fc_shell` documentado conforme ambiente; PASS = execução reproduzível até onde suportado e relatórios disponíveis de área/timing/potência, com restrições e falhas | Logs, versões, constraints, PDK/biblioteca identificados e relatórios permitidos |
| M11 — documentação | Manual de execução e resultados, `docs/DECISOES_E_PENDENCIAS.md`; depende M7–M10 ou limitações justificadas | Outra pessoa reproduz etapas possíveis com comandos e dependências registrados; PASS = evidências e limitações auditáveis | Documentação, inventário de artefatos, registros de revisão e resultados reais |

Em M8–M10 uma etapa não executada por falta de ambiente é **NÃO EXECUTADA/BLOQUEADA**, não PASS. A disponibilidade e versões de VCS, DC, TestMAX DFT, Fusion Compiler, PDK e bibliotecas serão verificadas no executor real. A edição e os testes Python registrados foram realizados em Windows; Rocky Linux/SSH são possibilidades para o fluxo EDA, ainda não confirmadas. Não há comandos definitivos de ferramenta EDA. A restrição 10 ns não prova timing fechado; potência só será reportada quando calculada com metodologia e dados disponíveis. Não versionar licença, tokens, PDK ou netlists restritos.

Sequenciamento sugerido: mês 1 M0–M2; mês 2 M3–M4; mês 3 M5–M7; mês 4 M8–M9; mês 5 M10–M11 e contingência. Estimativa de planejamento, não compromisso de prazo nem garantia de acesso às ferramentas.
