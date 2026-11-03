"""Gera um vetor funcional pequeno e reproduzível em JSON UTF-8."""

import argparse
import json
import random
import sys
from dataclasses import asdict
from pathlib import Path

import numpy as np

from model.golden import Config, process_frame


def generate(seed: int) -> dict:
    rng = random.Random(seed)
    cfg = Config(5, 3, crop_enable=True, x_start=0, y_start=0, crop_width=5,
                 crop_height=3, resize_x2=True, resize_y2=True,
                 threshold_enable=True, threshold=128)
    rgb = np.array([rng.randrange(256) for _ in range(5 * 3 * 3)], dtype=np.uint8).reshape(3, 5, 3)
    result = process_frame(rgb, cfg)
    return {
        'format_version': 1,
        'seed': seed,
        'config': asdict(cfg),
        'input_rgb': rgb.tolist(),
        'input_pixels': [
            {'r': int(rgb[y, x, 0]), 'g': int(rgb[y, x, 1]), 'b': int(rgb[y, x, 2]),
             'sof': y == 0 and x == 0, 'sol': x == 0,
             'eol': x == cfg.in_width - 1,
             'eof': y == cfg.in_height - 1 and x == cfg.in_width - 1}
            for y in range(cfg.in_height) for x in range(cfg.in_width)
        ],
        'output_width': result.width,
        'output_height': result.height,
        'output_pixels': [asdict(pixel) for pixel in result.pixels],
    }


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--seed', type=int, default=603)
    parser.add_argument('--output', type=Path, help='arquivo novo; sem esta opção imprime no stdout')
    args = parser.parse_args()
    data = json.dumps(generate(args.seed), indent=2, ensure_ascii=True) + '\n'
    if args.output is None:
        # bytes evitam conversão de LF para CRLF no stdout do Windows.
        sys.stdout.buffer.write(data.encode('utf-8'))
    else:
        with args.output.open('x', encoding='utf-8', newline='\n') as f:
            f.write(data)


if __name__ == '__main__':
    main()
