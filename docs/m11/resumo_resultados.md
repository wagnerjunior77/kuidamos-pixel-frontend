# KUIDAMOS 6C — resumo dos resultados da entrega

| Marco | Resultado documentado | Evidência |
|---|---|---|
| M0 | Especificação V1 de um pipeline RGB888 em streaming. Transferência borda a borda em um ciclo | [Contrato V1](../spec_v1.md) |
| M1–M2 | 32 testes Python na execução registrada após a imagem real e 28 arquivos de referência reproduzidos byte a byte | [Modelo](../evidencias/M1_modelo_python.md) · [Vetores](../evidencias/M2_vetores.md) |
| M3–M7 | VCS 15/15, 2.618 ciclos, 2.617 checagens pós-borda e zero erros SVA | [Regressão RTL](../evidencias/M3_M7_verificacao_vcs.md) |
| M8 | Design Compiler, SAED32 RVT slow, 10 ns. 1.256 células folha, área de 3.523,4524 µm², setup +3,21 ns e hold +0,16 ns com carga de fios estimada | [Síntese](../evidencias/M8_sintese_dc.md) |
| M9 | Uma cadeia com 115 SDFFs e 114 enlaces. Zero exclusões e zero violações no resumo DFT DRC, com 91 avisos detalhados. VCS funcional 15/15 e 460 pulsos de shift | [Resultado DFT](../evidencias/M9_resultado_final.md) |
| M10 | 1.276 células legalizadas, 1.486/1.486 redes requeridas roteadas, zero opens, shorts, DRC interno e PG DRC. Cadeia de 115 preservada e VCS final 15/15 mais 460 pulsos de shift | [Resultado físico](../evidencias/M10_resultado_final.md) |
| M10 | Área de células 3.878,9998 µm², utilização de 51,59%, setup funcional slow +1,8647 ns e hold funcional fast +0,0639 ns. Potência de 358,3551 µW a 100 MHz, com SAIF e RC extraído no cenário slow | [Área, STA e potência](../evidencias/M10_resultado_final.md) |
| M11 | Imagem inicial com 5.035 pixels por execução em RTL e gate-level. Ensaio de detalhe com 937.248 pixels em 6/6 configurações RTL. Zero divergências e zero erros SVA nas execuções RTL | [Imagem inicial](../evidencias/M11_imagem_real_vcs.md) · [Imagem de detalhe](../evidencias/M11_imagem_real_detalhe.md) |

A demonstração principal usa entrada de 576 × 1024, crop de 376 × 264
em (88, 456), grayscale, resize (1,1) e threshold em bypass. As
99.264 amostras dessa saída conferiram com o Golden Model. A comparação
com (2,2) gerou 188 × 132. A preferência por T=96 entre as alternativas
binárias aplica-se à cena analisada.

Wagner confirmou em 27/11/2026 que Thiago revisou o projeto e deu
retorno positivo. O aceite do professor para o recorte de resize
permanece pendente. Wagner autorizou a publicação do PDF. A licença da
fotografia ainda não foi identificada. O escopo acadêmico validado tem
limitações de MMMC de teste, SDF, ATPG, equivalência formal e signoff
físico independente.
