"""Gera e verifica PNGs das etapas funcionais do Golden Model."""

import argparse
from dataclasses import replace
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw

from model.golden import Config, MAX_DIMENSION, process_frame


def synthetic_image() -> Image.Image:
    """Cria faixas RGB, gradiente, formas e detalhes com um pixel."""
    width, height = 320, 240
    image = Image.new('RGB', (width, height), 'black')
    draw = ImageDraw.Draw(image)
    colors = ('red', 'lime', 'blue', 'cyan', 'magenta', 'yellow', 'white', 'black')
    for i, color in enumerate(colors):
        draw.rectangle((i * 40, 0, i * 40 + 39, 59), fill=color)
    for x in range(width):
        shade = x * 255 // (width - 1)
        draw.line((x, 60, x, 99), fill=(shade, shade, shade))
    draw.rectangle((15, 110, 130, 210), fill=(255, 96, 0), outline='white', width=3)
    draw.ellipse((150, 105, 245, 200), fill=(0, 180, 255), outline='white', width=3)
    draw.polygon(((260, 210), (295, 110), (319, 210)), fill=(140, 30, 190))
    for x in range(0, width, 8):
        draw.point((x, 225), fill='white')
    return image


def make_demo(input_path: Path | None, output_dir: Path) -> dict[str, Path]:
    """Recalcula cada etapa pelo modelo, verifica matematicamente e grava PNGs novos."""
    if input_path is None:
        source = synthetic_image()
    else:
        with Image.open(input_path) as image:
            source = image.convert('RGB')
    rgb = np.asarray(source, dtype=np.uint8)
    height, width = rgb.shape[:2]
    if not (1 <= width <= MAX_DIMENSION and 1 <= height <= MAX_DIMENSION):
        raise ValueError('A imagem deve ter dimensões entre 1 e 2047 por eixo')

    x, y = width // 8, height // 8
    roi_width, roi_height = width - 2 * x, height - 2 * y
    base = Config(width, height)
    cropped = replace(base, crop_enable=True, x_start=x, y_start=y,
                      crop_width=roi_width, crop_height=roi_height)
    resized = replace(cropped, resize_x2=roi_width >= 2, resize_y2=roi_height >= 2)
    thresholded = replace(resized, threshold_enable=True, threshold=128)

    gray = process_frame(rgb, base).image
    crop = process_frame(rgb, cropped).image
    resize = process_frame(rgb, resized).image
    threshold = process_frame(rgb, thresholded).image

    # Referências independentes das chamadas do modelo; operandos alargados.
    wide = rgb.astype(np.uint32)
    expected_gray = ((77 * wide[:, :, 0] + 150 * wide[:, :, 1] + 29 * wide[:, :, 2]) // 256).astype(np.uint8)
    expected_crop = expected_gray[y:y + roi_height, x:x + roi_width]
    out_width = roi_width // (2 if resized.resize_x2 else 1)
    out_height = roi_height // (2 if resized.resize_y2 else 1)
    xs = np.arange(out_width, dtype=np.int64) * roi_width // out_width
    ys = np.arange(out_height, dtype=np.int64) * roi_height // out_height
    expected_resize = expected_crop[np.ix_(ys, xs)]
    expected_threshold = np.where(expected_resize >= 128, 255, 0).astype(np.uint8)
    for actual, expected in ((gray, expected_gray), (crop, expected_crop),
                             (resize, expected_resize), (threshold, expected_threshold)):
        np.testing.assert_array_equal(actual, expected)

    images = {
        '01_original_rgb.png': rgb,
        '02_grayscale.png': gray,
        '03_crop.png': crop,
        '04_resize_nearest.png': resize,
        '05_threshold.png': threshold,
    }
    output_dir.mkdir(parents=True, exist_ok=True)
    paths = {name: output_dir / name for name in images}
    existing = [str(path) for path in paths.values() if path.exists()]
    if existing:
        raise FileExistsError('Arquivos já existem; escolha outro diretório: ' + ', '.join(existing))
    print(f'ROI: x={x}, y={y}, largura={roi_width}, altura={roi_height}; '
          f'fatores=({2 if resized.resize_x2 else 1},{2 if resized.resize_y2 else 1}); T=128')
    for name, pixels in images.items():
        # A abertura exclusiva evita sobrescrever arquivos já existentes.
        with paths[name].open('xb') as stream:
            Image.fromarray(pixels).save(stream, format='PNG')
        with Image.open(paths[name]) as saved:
            actual = np.asarray(saved)
            np.testing.assert_array_equal(actual, pixels)
            print(f'{paths[name]}: {saved.width}x{saved.height}, modo={saved.mode}, '
                  f'min={int(actual.min())}, max={int(actual.max())}, pixels=OK')
    return paths


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--input', type=Path, help='imagem externa; omitido: padrão sintético')
    parser.add_argument('--output-dir', type=Path, default=Path('outputs/m1_visual'),
                        help='diretório dos PNGs; arquivos existentes não são sobrescritos')
    args = parser.parse_args()
    make_demo(args.input, args.output_dir)


if __name__ == '__main__':
    main()
