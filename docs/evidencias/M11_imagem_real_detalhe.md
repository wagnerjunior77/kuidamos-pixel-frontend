# M11 — demonstração visual em 576 × 1024

A demonstração de detalhe usa a [mesma foto do estacionamento](../experimentos/estacionamento/carro.jpeg)
e complementa o [ensaio original de 144 × 256](M11_imagem_real_vcs.md).
A finalidade é mostrar o efeito visual de cada estágio e conferir
as configurações selecionadas bit a bit no RTL.

## Preparação e região de interesse

A foto original de 2.268 × 4.032 foi orientada pelo EXIF, convertida
para RGB888 e reduzida externamente para **576 × 1024** com
Pillow/Lanczos. A preparação fornece 589.824 pixels de entrada a cada
caso. O IP recebe esse quadro já preparado. Seu resize usa a seleção
nearest-neighbor da V1. A ROI foi selecionada manualmente nas
coordenadas da entrada preparada.

| Região | Origem (x, y) | Dimensões |
|---|---:|---:|
| Crop do carro | (88, 456) | 376 × 264 |
| Detalhe de apresentação da placa | (174, 620) | 88 × 40 |

O retângulo de detalhe é uma janela de inspeção dentro do crop
produzido e usa a mesma região da cena para os dois fatores. Nos
PNGs individuais, todas as imagens ficam nas dimensões nativas dos
respectivos estágios. Nos painéis, quando aplicado, o zoom inteiro
por replicação de pixels facilita a inspeção sem misturar amostras.
O detalhe tem 88 × 40 amostras no fator 1 e 44 × 20 no fator 2.

## Comparação por estágio

| Estágio | Configuração | Dimensão | Observação visual |
|---|---|---:|---|
| Grayscale | Crop e threshold desligados, fator (1,1) | 576 × 1024 | Quadro inteiro em luminância, com detalhes ainda presentes |
| Crop em grayscale | ROI do carro, fator (1,1), threshold desligado | 376 × 264 | Mantém as amostras da ROI e concentra a visualização no carro |
| Resize em grayscale | Mesma ROI, fator (2,2), threshold desligado | 188 × 132 | Conserva um quarto das amostras. Linhas finas e bordas de caracteres ficam menos definidas |
| Threshold | Mesma ROI, fatores (1,1) e (2,2), cinco valores de T | 376 × 264 ou 188 × 132 | A binarização remove tons intermediários. A visibilidade depende do limiar e das amostras preservadas |

O **crop em grayscale com fator (1,1)** é a saída mais informativa
para observar os contornos da placa nesta cena. **T=96 com fator
(1,1)** foi escolhido como destaque binário após inspeção visual.
T=64 deixa mais reflexos e regiões do entorno brancos. T=128
reduz áreas claras do entorno e serve de comparação. Em T=160
e T=192, áreas claras e traços finos sofrem descarte adicional.
O ensaio com T=96 em fator (2,2) mostra como a perda anterior de
amostras limita a visualização mesmo com o mesmo limiar.

A varredura completa pelo Golden Model está abaixo. As contagens
de pixels brancos usam a ROI inteira.

| T | Fator (1,1), de 99.264 pixels | Fator (2,2), de 24.816 pixels |
|---:|---:|---:|
| 64 | 33.281 | 8.373 |
| 96 | 22.454 | 5.652 |
| 128 | 16.998 | 4.290 |
| 160 | 12.761 | 3.230 |
| 192 | 8.473 | 2.121 |

## Verificação no VCS

O script reutiliza o formato de vetores M2 e o scoreboard M7.
Cada quadro tem dois ciclos iniciais de reset e três ciclos
finais ociosos. Os valores esperados vêm do Golden Model. A
cópia temporária do testbench captura os sinais reais do DUT
após a atualização dos registradores. O verificador compara
ciclos, validade, valor, quantidade e marcadores. O PNG `dut.png`
é reconstruído com os pixels válidos capturados, em ordem raster.
O ensaio avalia concordância dos pixels e detalhes visuais nesta foto.

| Caso no RTL | Saída nativa | Pixels comparados | Divergências de valor, marcador ou ciclo |
|---|---:|---:|---:|
| Grayscale sem crop | 576 × 1024 | 589.824 | 0 |
| Crop em grayscale, fator (1,1) | 376 × 264 | 99.264 | 0 |
| Resize em grayscale, fator (2,2) | 188 × 132 | 24.816 | 0 |
| T=96, fator (1,1) | 376 × 264 | 99.264 | 0 |
| T=128, fator (1,1) | 376 × 264 | 99.264 | 0 |
| T=96, fator (2,2) | 188 × 132 | 24.816 | 0 |
| Total | Seis configurações aprovadas | 937.248 | 0 |

O VCS X-2025.06-SP2_Full64 registrou 589.829 ciclos, 589.828
checagens pós-borda e zero erros SVA em cada caso. Os arquivos
capturados também foram cruzados entre os estágios. O crop
conferiu com a fatia do grayscale, o resize com as amostras
pares do crop para esta geometria e os resultados binários
com a aplicação do limiar sobre o grayscale já capturado.
O complemento em alta resolução foi executado no RTL. O
ensaio gate-level pertence à demonstração original.

## Artefatos locais e reprodução

A execução de referência está em `outputs/m11/visual-detail-eim1agqf/`.
Os PNGs de entrada e de saída, as montagens e os logs ficam nesse
diretório ignorado pelo Git.

| Arquivo local | Conteúdo |
|---|---|
| `entrada_rgb.png` | Entrada preparada sem anotações |
| `comparativo_estagios.png` | RGB com regiões marcadas, grayscale, crop e resize |
| `detalhe_placa_rtl.png` | Comparação do detalhe no grayscale e em T=96, nos dois fatores, a partir do RTL |
| `comparativo_thresholds_x1.png`, `comparativo_thresholds_x2.png` | Cinco limiares e referência em cinza, com identificação RTL ou Golden Model em cada painel |
| `comparativo_bit_a_bit_crop.png` | Golden Model, RTL e mapa de diferenças do crop em grayscale |
| `rtl/<caso>/dut.png` e `diferencas.png` | PNG capturado e mapa na resolução nativa de cada caso VCS |
| `summary.json`, `rtl/<caso>/result.json` e `simulation.log` | Configurações e resultados da comparação |

Com VCS no PATH, execute a partir da raiz:

```bash
.venv/bin/python -m scripts.verification.m11_image_detail \
  docs/experimentos/estacionamento/carro.jpeg
```

O script cria um diretório novo, prepara a entrada, gera a varredura
Golden e compila uma cópia temporária do testbench. Ele reutiliza o
mesmo executável para os seis casos, com vetores e capturas isolados.
A comparação visual é descritiva para esta foto e esta ROI. A
validação bit a bit mede a implementação do pré-processamento e
não mede reconhecimento de caracteres.
