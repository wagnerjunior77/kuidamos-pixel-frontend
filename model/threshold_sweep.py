"""Compara limiares usando o Golden Model com uma imagem externa."""

import argparse
import json
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFont, ImageOps

from model.golden import Config, process_frame
from model.real_image_demo import run as run_real_image


THRESHOLDS = (64, 96, 128, 160, 192)


def montage(output_dir: Path, target: Path) -> None:
    items = [
        ('Original RGB', '00_original_rgb.png'),
        ('Grayscale', '02_grayscale.png'),
        ('Crop', '03_crop.png'),
        ('Resize sem threshold', '04_resize_nearest.png'),
    ] + [(f'Threshold T={t}', f'threshold_{t}.png') for t in THRESHOLDS]
    width, height, gap, top = 210, 370, 10, 55
    canvas = Image.new('RGB', (gap + len(items) * (width + gap), top + height + 42), (242, 244, 247))
    draw = ImageDraw.Draw(canvas)
    try:
        font = ImageFont.truetype('DejaVuSans.ttf', 15)
        small = ImageFont.truetype('DejaVuSans.ttf', 12)
    except OSError:
        font = small = ImageFont.load_default()
    for index, (title, filename) in enumerate(items):
        x = gap + index * (width + gap)
        with Image.open(output_dir / filename) as image:
            draw.text((x + 2, 7), title, font=font, fill=(20, 28, 40))
            draw.text((x + 2, 30), f'{image.width} x {image.height} px', font=small, fill=(55, 65, 80))
            preview = ImageOps.contain(image.convert('RGB'), (width, height), Image.Resampling.NEAREST)
            canvas.paste(preview, (x + (width - preview.width) // 2,
                                   top + (height - preview.height) // 2))
    draw.text((gap, top + height + 12),
              'Original em resolucao de origem; modelo usa entrada preparada para a V1.',
              font=small, fill=(55, 65, 80))
    with target.open('xb') as stream:
        canvas.save(stream, format='PNG')
    with Image.open(target) as saved:
        saved.load()
        np.testing.assert_array_equal(np.asarray(saved), np.asarray(canvas))


def run(input_path: Path, output_dir: Path) -> dict:
    sweep_names = [f'threshold_{t}.png' for t in THRESHOLDS]
    sweep_names += ['comparativo_thresholds.png', 'sweep_result.json']
    existing = [str(output_dir / name) for name in sweep_names if (output_dir / name).exists()]
    if existing:
        raise FileExistsError('Arquivos já existem; escolha outro diretório: ' + ', '.join(existing))

    # O fluxo original prepara a imagem dentro dos limites V1 e verifica as etapas.
    base = run_real_image(input_path, output_dir)
    with Image.open(output_dir / '01_original_rgb.png') as image:
        rgb = np.asarray(image.convert('RGB'))
    with Image.open(output_dir / '04_resize_nearest.png') as image:
        bypass = np.asarray(image).copy()
    width, height = base['model_input_size']
    roi = base['crop']
    factors = base['resize_factors']
    results = {}
    for threshold in THRESHOLDS:
        config = Config(width, height, crop_enable=True, x_start=roi['x_start'],
                        y_start=roi['y_start'], crop_width=roi['width'], crop_height=roi['height'],
                        resize_x2=factors[0] == 2, resize_y2=factors[1] == 2,
                        threshold_enable=True, threshold=threshold)
        output = process_frame(rgb, config).image
        np.testing.assert_array_equal(output, np.where(bypass >= threshold, 255, 0).astype(np.uint8))
        path = output_dir / f'threshold_{threshold}.png'
        with path.open('xb') as stream:
            Image.fromarray(output).save(stream, format='PNG')
        with Image.open(path) as saved:
            np.testing.assert_array_equal(np.asarray(saved), output)
        white = int(np.count_nonzero(output == 255))
        results[str(threshold)] = {'file': path.name, 'white_pixels': white,
                                   'black_pixels': int(output.size - white)}
        print(f'{path}: {output.shape[1]}x{output.shape[0]}, T={threshold}, '
              f'pretos={output.size - white}, brancos={white}, pixels=OK')
    with Image.open(output_dir / '05_threshold.png') as first, Image.open(output_dir / 'threshold_128.png') as second:
        np.testing.assert_array_equal(np.asarray(first), np.asarray(second))
    montage(output_dir, output_dir / 'comparativo_thresholds.png')
    summary = {'base': base, 'thresholds': results, 'comparison': 'comparativo_thresholds.png'}
    with (output_dir / 'sweep_result.json').open('x', encoding='utf-8', newline='\n') as stream:
        json.dump(summary, stream, ensure_ascii=False, indent=2)
        stream.write('\n')
    return summary


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--input', required=True, type=Path)
    parser.add_argument('--output-dir', type=Path, default=Path('outputs/real_image_threshold_sweep'))
    args = parser.parse_args()
    run(args.input, args.output_dir)


if __name__ == '__main__':
    main()
