"""Demonstra o Golden Model com imagem externa e resumo visual por etapas."""

import argparse
import json
import tempfile
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFont, ImageOps

from model.golden import MAX_DIMENSION
from model.visual_demo import make_demo


def fit_for_model(image: Image.Image, limit: int = MAX_DIMENSION) -> Image.Image:
    """Prepara fora do modelo um RGB proporcional que cabe nos limites da V1."""
    width, height = image.size
    longest = max(width, height)
    if longest <= limit:
        return image.copy()
    size = (max(1, width * limit // longest), max(1, height * limit // longest))
    return image.resize(size, Image.Resampling.LANCZOS)


def make_comparison(paths: dict[str, Path], target: Path) -> None:
    """Monta apenas uma visualização; arquivos de etapas mantêm resolução real."""
    items = [
        ('Original RGB', paths['00_original_rgb.png']),
        ('Grayscale', paths['02_grayscale.png']),
        ('Crop', paths['03_crop.png']),
        ('Resize NN', paths['04_resize_nearest.png']),
        ('Threshold', paths['05_threshold.png']),
    ]
    cell_width, cell_height, top, gap = 280, 500, 60, 12
    canvas = Image.new('RGB', (gap + (cell_width + gap) * len(items), top + cell_height + 42), (242, 244, 247))
    draw = ImageDraw.Draw(canvas)
    try:
        font = ImageFont.truetype('DejaVuSans.ttf', 17)
        small = ImageFont.truetype('DejaVuSans.ttf', 13)
    except OSError:
        font = small = ImageFont.load_default()
    for index, (title, path) in enumerate(items):
        x = gap + index * (cell_width + gap)
        with Image.open(path) as item:
            draw.text((x + 5, 8), title, fill=(20, 28, 40), font=font)
            draw.text((x + 5, 33), f'{item.width} x {item.height} px', fill=(55, 65, 80), font=small)
            preview = ImageOps.contain(item.convert('RGB'), (cell_width, cell_height), Image.Resampling.NEAREST)
            canvas.paste(preview, (x + (cell_width - preview.width) // 2,
                                   top + (cell_height - preview.height) // 2))
    draw.text((gap, top + cell_height + 12),
              'Original em resolucao de origem; etapas usam a entrada preparada para a V1.',
              fill=(55, 65, 80), font=small)
    with target.open('xb') as stream:
        canvas.save(stream, format='PNG')
    with Image.open(target) as check:
        check.load()
        if check.size != canvas.size or not np.array_equal(np.asarray(check), np.asarray(canvas)):
            raise ValueError('Erro ao verificar o comparativo gravado')


def run(input_path: Path, output_dir: Path) -> dict:
    if not input_path.is_file():
        raise FileNotFoundError(input_path)
    names = ['00_original_rgb.png', '01_original_rgb.png', '02_grayscale.png', '03_crop.png',
             '04_resize_nearest.png', '05_threshold.png', '06_comparativo.png', 'resultado.json']
    existing = [str(output_dir / name) for name in names if (output_dir / name).exists()]
    if existing:
        raise FileExistsError('Arquivos já existem; escolha outro diretório: ' + ', '.join(existing))
    with Image.open(input_path) as source:
        original = ImageOps.exif_transpose(source).convert('RGB')
    prepared = fit_for_model(original)
    width, height = prepared.size
    x, y = width // 8, height // 8
    crop_width, crop_height = width - 2 * x, height - 2 * y
    fx, fy = (2 if crop_width >= 2 else 1), (2 if crop_height >= 2 else 1)
    output_dir.mkdir(parents=True, exist_ok=True)
    original_path = output_dir / '00_original_rgb.png'
    with original_path.open('xb') as stream:
        original.save(stream, format='PNG')
    with Image.open(original_path) as check:
        if not np.array_equal(np.asarray(check.convert('RGB')), np.asarray(original)):
            raise ValueError('Erro ao verificar a imagem RGB original gravada')
    with tempfile.TemporaryDirectory(prefix='kuidamos_real_') as temporary:
        temp_input = Path(temporary) / 'entrada.png'
        prepared.save(temp_input, format='PNG')
        stage_paths = make_demo(temp_input, output_dir)
    paths = {'00_original_rgb.png': original_path, **stage_paths}
    make_comparison(paths, output_dir / '06_comparativo.png')
    result = {
        'input_path': str(input_path),
        'original_size': list(original.size),
        'model_input_size': list(prepared.size),
        'external_preparation': 'Pillow LANCZOS' if original.size != prepared.size else 'nenhuma',
        'crop': {'x_start': x, 'y_start': y, 'width': crop_width, 'height': crop_height},
        'resize_factors': [fx, fy],
        'resize_output_size': [crop_width // fx, crop_height // fy],
        'threshold': 128,
        'files': names,
    }
    with (output_dir / 'resultado.json').open('x', encoding='utf-8', newline='\n') as stream:
        json.dump(result, stream, indent=2, ensure_ascii=False)
        stream.write('\n')
    print(json.dumps(result, indent=2, ensure_ascii=False))
    return result


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--input', required=True, type=Path, help='caminho de imagem JPEG ou PNG')
    parser.add_argument('--output-dir', type=Path, default=Path('outputs/real_image_test'))
    args = parser.parse_args()
    run(args.input, args.output_dir)


if __name__ == '__main__':
    main()
