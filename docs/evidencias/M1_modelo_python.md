# Evidência de execução — Golden Model M1

Data: 2026-11-03. Execução local em Windows; Python 3.10.6 e NumPy 2.2.6. As verificações abaixo são de software e não constituem simulação ou síntese RTL.

Comando executado na raiz do projeto:

```text
python -m unittest discover -s model/tests -v
```

Saída observada:

```text
test_aleatorio_referencia_escalar_independente ... ok
test_bypass_ignora_roi ... ok
test_cadeia_crop_resize_e_threshold ... ok
test_configuracoes_invalidas ... ok
test_cores_e_truncamento ... ok
test_crop_centro_e_bordas_exclusivas ... ok
test_crop_na_borda_e_pixel_unico ... ok
test_flags_em_multiplas_linhas ... ok
test_formato_e_tipo_da_imagem ... ok
test_grayscale_aleatorio_sem_threshold ... ok
test_limite_de_largura_e_altura ... ok
test_quadro_invalido_nao_produz_resultado ... ok
test_resize_formula_dimensoes_ate_2047 ... ok
test_resize_par_e_impar_e_eixos_independentes ... ok
test_threshold_igualdade_e_extremos ... ok
test_vetor_reproduzivel_e_marcadores ... ok

Ran 16 tests in 0.172s
OK
```

Os identificadores de classe exibidos na saída original foram omitidos acima para facilitar a leitura; todos pertencem a `test_golden.GoldenTests`. Tempo varia por máquina.

Também foram executadas duas invocações de `python -m model.generate_vectors --seed 603` no stdout e uma com `--output` em arquivo temporário. Os três resultados foram idênticos em bytes: SHA-256 `84896794b995498b98c06da3efab469931565b3b0884e9a8ee265f128ca0b9df`, com 15 pixels de entrada e 2 de saída. O arquivo temporário foi criado pela própria verificação e removido ao final.

As suítes incluem uma comparação com referência escalar independente, ROI e limites, os quatro pares de fatores, casos 1×1, 4×4, 5×3, 8×8 e 16×16, dois eixos até 2047, RGB extremo, threshold e bypass, marcadores e configurações inválidas. A equivalência de índices para redução 2 foi verificada para N entre 2 e 2047. O teste dos eixos com 2047 não representa uma execução de imagem 2047×2047 completa.

Limitações: modelo por quadro; reset, validade ciclo a ciclo, pulso `cfg_error`, bolhas, latência e recuperação de quadros malformados não foram simulados. Imagens PNG reais, formato de vetores temporais e comparações com RTL pertencem aos próximos marcos. VCS, síntese, DFT e físico **NÃO EXECUTADOS**.

## Demonstração visual e regressão — 2026-11-03

Ambiente local: Windows, Python 3.10.6, NumPy 2.2.6 e Pillow 10.2.0. Comando `python -m unittest discover -s model/tests -v`: **18 testes executados, OK**, incluindo 16 testes do modelo e dois da demonstração visual, em 0,239 s. O teste de imagem externa usa um PNG sintético temporário 1×1; não foi usada imagem real de terceiros.

Comando executado na raiz:

```text
python -X utf8 -m model.visual_demo --output-dir outputs/m1_visual
```

Saída observada: ROI `x=40, y=30, largura=240, altura=180`, fatores `(2,2)` e `T=128`.

| Arquivo local | Dimensões | Modo | Mínimo/máximo |
|---|---:|---|---|
| `outputs/m1_visual/01_original_rgb.png` | 320×240 | RGB | 0/255 |
| `outputs/m1_visual/02_grayscale.png` | 320×240 | L | 0/255 |
| `outputs/m1_visual/03_crop.png` | 240×180 | L | 0/255 |
| `outputs/m1_visual/04_resize_nearest.png` | 120×90 | L | 0/255 |
| `outputs/m1_visual/05_threshold.png` | 120×90 | L | 0/255 |

O script comparou numericamente cada etapa às equações e conferiu os valores de todos os pixels dos PNGs após reabertura; os cinco arquivos foram também inspecionados visualmente. O teste automatizado verificou que a imagem binária contém apenas 0 e 255 e que uma segunda execução não sobrescreve os PNGs existentes. Esses resultados não substituem verificação de RTL ou simulação ciclo a ciclo. Os PNGs permanecem locais e são ignorados pelo Git.
