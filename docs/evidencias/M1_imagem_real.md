# Teste do Golden Model com imagem real

Data: 2026-11-04. Entrada local: `docs/assets/input/carro.jpeg` (JPEG RGB, 2268×4032). A imagem é utilizada como estímulo de teste; sua presença no Git não é pressuposta. SHA-256 do arquivo de entrada usado: `06a4bb6782f9c13060762c294cc0f731d6ad74adf3cb6bc0a42caa620a9171a4`.

O limite V1 é 2047 pixels por eixo. Para executar o teste com a imagem inteira, uma etapa externa de preparação com Pillow/Lanczos reduziu proporcionalmente a entrada para 1151×2047. Essa etapa ocorre antes do Golden Model e não constitui função do IP. O resize nearest-neighbor dentro do modelo continua a usar a equação especificada.

| Etapa | Arquivo em `outputs/real_image_test/` | Dimensão |
|---|---|---:|
| RGB da imagem de origem | `00_original_rgb.png` | 2268×4032 |
| RGB preparado para o modelo | `01_original_rgb.png` | 1151×2047 |
| Grayscale | `02_grayscale.png` | 1151×2047 |
| Crop | `03_crop.png` | 865×1537 |
| Resize nearest-neighbor | `04_resize_nearest.png` | 432×768 |
| Threshold | `05_threshold.png` | 432×768 |
| Comparativo visual | `06_comparativo.png` | 1472×602 |

Parâmetros de crop **relativos à entrada preparada**: `x_start=143`, `y_start=255`, `crop_width=865`, `crop_height=1537`. Fatores de resize: horizontal 2, vertical 2; dimensões de saída com piso. Threshold habilitado com `T=128`. O arquivo `resultado.json` registra esses parâmetros. As imagens do comparativo são redimensionadas apenas para apresentação; os PNGs de cada etapa mantêm os valores e dimensões do resultado.

Comando executado a partir da raiz:

```text
python -X utf8 -m model.real_image_demo --input docs/assets/input/carro.jpeg --output-dir outputs/real_image_test
```

Para executar novamente, substitua o diretório de saída por um novo; o script não sobrescreve os arquivos existentes. O arquivo de entrada deve ser disponibilizado localmente no caminho indicado ou informado por `--input`.

## Resultados

O script comparou numericamente os arrays de cada operação às equações e conferiu os PNGs após reabertura. Uma verificação adicional abriu os sete PNGs, confirmou as dimensões da tabela e verificou que o threshold contém apenas 0 e 255. O comparativo foi inspecionado visualmente. A suíte `python -m unittest discover -s model/tests -v` executou **31 testes, todos aprovados**, incluindo dois testes do fluxo externo. A verificação `python -X utf8 -m model.m2_vectors --output-dir vectors/m2 --check` confirmou **28 arquivos idênticos**.

O teste é de software e de apresentação visual. Não foram executados RTL, VCS, síntese, DFT ou testes com câmera. Os resultados em `outputs/` são locais e ignorados pelo Git.

## Comparação de thresholds

Na mesma data, foi executado o comando abaixo com a mesma imagem e configuração de crop e resize:

```text
python -X utf8 -m model.threshold_sweep --input docs/assets/input/carro.jpeg --output-dir outputs/real_image_threshold_sweep
```

Para repetir, utilize um diretório novo: o script recusa sobrescrever arquivos existentes. O pipeline sem threshold está em `04_resize_nearest.png`; os limiares estão em `threshold_64.png`, `threshold_96.png`, `threshold_128.png`, `threshold_160.png` e `threshold_192.png`, todos com 432×768 pixels. `comparativo_thresholds.png` mostra original, grayscale, crop, resize e os cinco limiares lado a lado. `sweep_result.json` registra parâmetros e contagens.

| Threshold | Pixels brancos | Pixels pretos |
|---:|---:|---:|
| 64 | 237223 | 94553 |
| 96 | 207331 | 124445 |
| 128 | 144611 | 187165 |
| 160 | 60906 | 270870 |
| 192 | 38289 | 293487 |

Os PNGs foram reabertos e os valores comparados à regra `pixel >= T`; a saída com T=128 e as etapas anteriores são idênticas às do teste anterior. O comparativo foi inspecionado visualmente. A regressão executou **32 testes, todos aprovados**; a verificação de M2 confirmou 28 arquivos idênticos. A variação de limiar é uma análise visual e funcional em software, sem inferência sobre a acurácia de sistemas posteriores.
