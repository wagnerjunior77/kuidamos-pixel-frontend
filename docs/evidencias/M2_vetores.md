# Vetores M2 — convenção temporal e evidências

## Convenção usada para os vetores

Esta convenção torna observável o contrato existente em `docs/spec_v1.md`; não modifica a especificação. Os ciclos são numerados a partir de zero e cada linha representa uma borda de subida `n`:

1. O testbench apresenta a entrada antes da borda `n`. Nessa borda, uma entrada é aceita somente com `reset_n=1` e `pixel_valid=1`.
2. A saída previamente registrada após `n-1` é consumida na borda `n` somente quando seu `pixel_out_valid=1` e `reset_n=1`. Se `reset_n=0`, não há transferência, mesmo que a saída anterior estivesse válida.
3. Após a atualização dos registradores na borda `n`, a linha `expected_after` registra a saída correspondente à entrada de `n`, caso selecionada, bem como `cfg_error`. Esses valores podem ser consumidos a partir da borda `n+1`. O testbench deve amostrar `expected_after` após a atualização dos registradores, evitando corrida de simulação.
4. Um SOF válido com configuração inválida produz `cfg_error=1` imediatamente após a mesma borda de captura e durante o ciclo seguinte, sem produzir pixel para esse SOF. O pulso é zero na próxima borda, exceto se houver outro SOF inválido. Um resultado de quadro anterior ainda pode ter sido consumido **antes** da atualização dessa borda.
5. Uma bolha ou um pixel descartado gera saída inválida e flags/dados zero na saída registrada após a borda correspondente. Reset síncrono limpa a saída após a borda, cancela qualquer transferência naquela borda e faz aguardar novo SOF.

Nos casos abaixo, apenas o subconjunto de quadros bem formados e recuperação após reset ou configuração inválida é exercitado. Fluxos malformados não são usados como evidência de detecção de erros. O modelo de quadros fornece valores e flags; o escalonador associa cada saída à coordenada de entrada selecionada pela equação oficial e à borda em que essa coordenada foi enviada. A representação é uma convenção de teste, não uma microarquitetura de RTL.

## Arquivos e casos

O gerador é `model/m2_vectors.py`. O conjunto pequeno em `vectors/m2/` contém **28 arquivos, aproximadamente 348 KiB**: `index.json` e, para cada um dos nove casos, `<nome>.json`, `<nome>.stim.txt` e `<nome>.expect.txt`. O Golden Model `model/golden.py` não foi alterado. `.gitattributes` fixa LF nos vetores para preservação dos bytes em Windows e Linux.

| Caso | Dimensão, configuração e cenário | Ciclos | Entrada válida | Saídas registradas / consumidas | `cfg_error` |
|---|---|---:|---:|---:|---:|
| `01_minimo_1x1` | 1×1, bypass, reset inicial | 3 | 1 | 1 / 1 | 0 |
| `02_primarias_4x4` | 4×4, preto, branco, primárias e tons; pixels consecutivos | 18 | 16 | 16 / 16 | 0 |
| `03_centro_f12_t0` | 8×8, ROI central 4×4, fatores (1,2), T=0 | 66 | 64 | 8 / 8 | 0 |
| `04_borda_f21_t255` | 8×8, ROI no canto inferior direito, fatores (2,1), T=255 | 66 | 64 | 8 / 8 | 0 |
| `05_impar_f22_t128_bolhas` | 5×3, ROI integral, fatores (2,2), T=128, bolhas | 22 | 15 | 2 / 2 | 0 |
| `06_aleatorio_16x16` | 16×16, RGB aleatório seed 606, fatores (1,1), threshold em bypass | 258 | 256 | 256 / 256 | 0 |
| `07_config_e_quadros_consecutivos` | Dois 4×4 sem bolha entre eles; threshold externo muda durante o primeiro e é capturado no segundo SOF | 34 | 32 | 32 / 32 | 0 |
| `08_reset_e_recuperacao` | 4×4 interrompido por reset, continuação sem SOF ignorada, novo 4×4 | 35 | 32 | 19 / 18 | 0 |
| `09_invalidos_e_recuperacao` | ROI fora da imagem; 1×1 com fator 2 e saída zero; novo 1×1 válido | 20 | 18 | 1 / 1 | 2 |

`output_registered` conta as saídas válidas após uma borda; `output_consumed` conta as efetivamente consumidas na borda seguinte. No caso 08 a diferença de uma saída é intencional: o reset cancela a transferência pendente. `input_valid` conta ciclos com `pixel_valid=1`, inclusive pixels posteriores ao reset que não têm SOF e são ignorados. Todos os casos começam com uma borda de reset e terminam com uma bolha para consumir a última saída válida. `index.json` fornece os totais e a seed de cada caso. Cada quadro em JSON inclui a sua seed, RGB, configuração, dimensões de saída, coordenadas selecionadas na imagem **original** e pixels/flags esperados. Nas imagens dirigidas de primárias a seed é registrada, mas a paleta é fixa e não a utiliza. Um quadro interrompido contém no JSON a referência funcional do quadro completo; para os ciclos efetivos, consultar `cycles` e os arquivos `.txt`.

## Formato estável para SystemVerilog

Os arquivos são texto ASCII decimal, uma linha de cabeçalho começando com `#`, seguida por **uma linha por borda**. Números são unsigned em decimal, separados por um espaço; bits usam 0 ou 1. Não há representação de `X`/`Z`. Os dois arquivos de um caso têm os mesmos números de ciclo e número de linhas. O cabeçalho contém os nomes das colunas na ordem abaixo:

```text
stim:   cycle reset_n pixel_valid pixel_r pixel_g pixel_b in_sof in_sol in_eol in_eof cfg_in_width cfg_in_height cfg_crop_enable cfg_x_start cfg_y_start cfg_crop_width cfg_crop_height cfg_resize_x2 cfg_resize_y2 cfg_threshold_enable cfg_threshold
expect: cycle pixel_out_valid pixel_out out_sof out_sol out_eol out_eof cfg_error consume_valid
```

`stim` contém os sinais amostrados na borda `cycle`. Em `expect`, `pixel_out_valid`, `pixel_out`, flags e `cfg_error` são os valores **após** a borda dessa linha. `consume_valid` é um marcador de referência para a **borda atual**, não é uma porta do DUT: vale `reset_n[n] && pixel_out_valid_after[n-1]`. Caso seja 1, o valor e os marcadores consumidos são os da linha anterior; a primeira linha começa com reset e `consume_valid=0`. O `cycle` é um índice de teste, não um sinal do DUT. A configuração é fornecida em todas as linhas e capturada no SOF. Os bits `cfg_resize_x2/y2=0` significam fator 1; valor 1 significa fator 2.

No caso 01, a borda 0 aplica reset, a borda 1 recebe o único pixel e registra os quatro marcadores após a borda; a linha 2 apresenta saída pós-borda inválida, mas `consume_valid=1` para a saída registrada na linha 1. Comparar `expected_after` de `n` com a saída amostrada **antes** da borda `n` provocaria um erro de alinhamento de um ciclo.

Para o futuro testbench, Thiago poderá abrir os dois arquivos correspondentes, ler e descartar os cabeçalhos com `$fgets`, interpretar cada linha decimal com `$sscanf`, dirigir estímulos antes da borda e comparar as expectativas após a atualização dos registradores. Deve conferir quantidade de campos, ciclos, dados, valid, flags e erro; para consumo na borda, aplicar a regra da linha anterior. Isso é uma orientação de integração, **não** um testbench implementado ou validado com VCS.

## Geração e validação

Ambiente efetivamente usado: Windows, Python 3.10.6 e NumPy 2.2.6; dependências em `model/requirements.txt`. Na raiz do projeto:

```text
python -m pip install -r model/requirements.txt
python -X utf8 -m model.m2_vectors --output-dir vectors/m2 --check
python -m unittest discover -s model/tests -v
```

Para gerar novamente sem sobrescrever o conjunto existente, escolha um diretório novo, por exemplo:

```text
python -X utf8 -m model.m2_vectors --output-dir outputs/m2_regenerado
python -X utf8 -m model.m2_vectors --output-dir outputs/m2_regenerado --check
```

O gerador recusa sobrescrever seus arquivos existentes; `--check` compara os 28 arquivos esperados por bytes e não altera arquivos. O formato JSON tem `format_version=1`, `seed`, `summary`, `frames` e `cycles`; cada ciclo contém `input`, `expected_after` e a posição/fonte do estímulo para depuração. A seed do caso e as seeds individuais dos quadros estão no JSON. Para reprodução por bytes, usar a versão de Python/NumPy registrada e preservar LF; mudanças intencionais no modelo ou gerador exigirão regeneração em diretório separado e revisão.

## Resultados e limites

Em 2026-11-04 foram executados `python -m unittest discover -s model/tests -v` (**29 testes, OK**, incluindo 11 testes M2) e `python -X utf8 -m model.m2_vectors --output-dir vectors/m2 --check` (**28 arquivos idênticos**). Os testes compararam o Golden Model com uma referência escalar, coordenadas, marcadores, bolhas, reset, erro e alinhamento temporal, além da equivalência JSON/texto, determinismo e proteção contra sobrescrita. A execução registrada levou 1,182 s; o tempo varia por máquina.

Na verificação anterior ao versionamento, em 2026-11-04, os mesmos dois comandos foram executados novamente: **29 testes, OK** em 1,121 s e **28 arquivos idênticos**. A revisão incluiu os casos funcionais e temporais e a consistência entre JSON e texto.

Limites: as expectativas temporais seguem a meta inicial de um ciclo da V1, sujeita a atualização se a arquitetura mudar. Os testes não demonstram correção ou sintetizabilidade de um DUT. O comportamento de fluxo malformado não é coberto, e não há arquivos com X/Z ou imagens reais. A restrição dos fatores de resize permanece sujeita à validação do professor. VCS, RTL e ferramentas Synopsys **NÃO EXECUTADOS**; ainda é necessário integrar e validar o leitor no futuro ambiente real.
