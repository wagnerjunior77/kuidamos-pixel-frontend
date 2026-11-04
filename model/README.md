# Golden Model — Grupo 6C

Modelo funcional independente em Python/NumPy da V1 descrita em `docs/spec_v1.md`. Entrada RGB888 e saída são matrizes por quadro; o modelo usa memória de quadro no computador de teste. Essa escolha não altera a restrição de streaming e ausência de framebuffer no futuro IP.

## Ambiente e execução

Python 3.10.6, NumPy 2.2.6 e Pillow 10.2.0 foram usados na execução registrada em `docs/evidencias/M1_modelo_python.md`. Em Windows PowerShell ou no terminal Linux, a partir da raiz do repositório, com Python instalado:

```text
python -m venv .venv
```

Ative o ambiente usando o procedimento do seu shell. Em seguida:

```text
python -m pip install -r model/requirements.txt
python -m unittest discover -s model/tests -v
python -m model.generate_vectors --seed 603 --output vetor_603.json
```

O gerador recusa sobrescrever um arquivo existente. Sem `--output`, grava JSON no stdout; com `--output`, usa UTF-8 e LF. JSON tem `format_version`, `seed`, `config`, `input_rgb`, `input_pixels` em ordem raster com RGB e SOF/SOL/EOL/EOF, dimensões de saída e `output_pixels` com valor e os quatro marcadores. Cada registro representa um pixel válido; esse formato **não representa ciclos, bolhas, reset, `cfg_error` nem latência**. Os vetores temporais de M2 utilizam uma camada separada.

## Demonstração visual

Na raiz do projeto, gere os cinco PNGs com uma imagem sintética:

```text
python -X utf8 -m model.visual_demo --output-dir outputs/m1_visual
```

Para uma imagem externa, forneça seu caminho, mantendo-a fora do repositório se for privada:

```text
python -X utf8 -m model.visual_demo --input CAMINHO_DA_IMAGEM --output-dir outputs/m1_visual_externa
```

A entrada é convertida para RGB888 e deve ter entre 1 e 2047 pixels por eixo. O script escolhe uma ROI central retirando `floor(N/8)` pixels de cada borda, usa fator 2 nos eixos cuja ROI tenha pelo menos dois pixels e aplica `T=128`. Cada etapa é obtida por uma chamada ao Golden Model com configuração apropriada. O script compara os arrays a cálculos numéricos das equações, grava os PNGs e os relê para comparar dimensão e cada valor de pixel. A saída em `outputs/` é ignorada pelo Git. Arquivos de mesmo nome não são sobrescritos; use outro diretório para uma nova execução. A análise visual complementa os testes numéricos e não verifica o futuro RTL.

## API

```python
import numpy as np
from model.golden import Config, ConfigError, process_frame

rgb = np.array([[[255, 0, 0], [255, 255, 255]]], dtype=np.uint8)
result = process_frame(rgb, Config(in_width=2, in_height=1))
assert result.image.tolist() == [[76, 255]]
pixels = list(result.pixels)  # Pixel(value, sof, sol, eol, eof), ordem raster
```

`Config` aceita dimensões de entrada, campos de ROI, `crop_enable`, `resize_x2`, `resize_y2`, `threshold_enable` e `threshold`. Os bits de configuração aceitam `bool` ou inteiros 0/1. A imagem deve ser um array NumPy `uint8` de formato `(in_height, in_width, 3)` em RGB. `Result` contém `image` uint8 2D, `width`, `height` e o iterador `pixels`, que pode ser percorrido novamente. O conteúdo de `result.image` deve ser tratado como somente leitura; o iterador reflete seu conteúdo atual.

Configuração inválida gera `ConfigError` antes de resultado, inclusive dimensão de saída zero; a exceção representa a rejeição funcional do quadro, sem simular o pulso de hardware. Campos de ROI são ignorados com crop desabilitado. Imagem com dtype ou formato incompatível gera `ValueError`, pois representa erro de estímulo, não um campo de configuração do IP. O threshold é validado como inteiro 0–255 mesmo no bypass. Não há suporte a upscale nem a fatores além de 1 e 2.

O modelo aplica grayscale inteiro em `uint32`, ROI com limites superiores exclusivos, seleção pela fórmula geral `floor(k*N/N_out)` e threshold `>= T`. Marcadores correspondem ao quadro produzido, incluindo a coincidência de todas as flags no quadro 1×1. Não é modelo ciclo a ciclo e não comprova comportamento de reset, stalls, `cfg_error` ou timing do futuro RTL.

Os vetores funcionais e temporais M2 utilizam uma camada separada: veja `docs/evidencias/M2_vetores.md` e `python -m model.m2_vectors --help`.
