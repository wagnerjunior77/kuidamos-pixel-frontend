"""Vetores M2: cenários por quadro e escalonamento independente do RTL."""

import argparse
import json
import random
from dataclasses import asdict, dataclass, replace
from pathlib import Path

import numpy as np

from model.golden import Config, ConfigError, process_frame, validate_config


INPUT_FIELDS = (
    'cycle', 'reset_n', 'pixel_valid', 'pixel_r', 'pixel_g', 'pixel_b',
    'in_sof', 'in_sol', 'in_eol', 'in_eof', 'cfg_in_width', 'cfg_in_height',
    'cfg_crop_enable', 'cfg_x_start', 'cfg_y_start', 'cfg_crop_width',
    'cfg_crop_height', 'cfg_resize_x2', 'cfg_resize_y2',
    'cfg_threshold_enable', 'cfg_threshold',
)
OUTPUT_FIELDS = (
    'cycle', 'pixel_out_valid', 'pixel_out', 'out_sof', 'out_sol',
    'out_eol', 'out_eof', 'cfg_error', 'consume_valid',
)


@dataclass(frozen=True)
class Frame:
    name: str
    rgb: np.ndarray
    config: Config
    seed: int


def pattern(width: int, height: int, seed: int, primaries: bool = False) -> np.ndarray:
    if primaries:
        palette = [(0, 0, 0), (255, 0, 0), (0, 255, 0), (0, 0, 255),
                   (255, 255, 255), (128, 128, 128), (127, 127, 127), (1, 1, 1)]
        values = [palette[i % len(palette)] for i in range(width * height)]
    else:
        rng = random.Random(seed)
        values = [(rng.randrange(256), rng.randrange(256), rng.randrange(256))
                  for _ in range(width * height)]
    return np.array(values, dtype=np.uint8).reshape(height, width, 3)


def _frame_reference(frame: Frame) -> tuple[dict, dict]:
    """Associa coordenadas da imagem original aos pixels do Golden Model."""
    metadata = {'name': frame.name, 'seed': frame.seed, 'config': asdict(frame.config), 'rgb': frame.rgb.tolist()}
    try:
        x, y, width, height, out_width, out_height = validate_config(frame.config)
        result = process_frame(frame.rgb, frame.config)
    except ConfigError as exc:
        metadata.update({'valid_config': False, 'error': str(exc), 'output_width': 0,
                         'output_height': 0, 'selected': [], 'output_pixels': []})
        return metadata, {}
    selected = [(x + ox * width // out_width, y + oy * height // out_height)
                for oy in range(out_height) for ox in range(out_width)]
    pixels = [asdict(p) for p in result.pixels]
    metadata.update({'valid_config': True, 'error': None, 'output_width': out_width,
                     'output_height': out_height, 'selected': [list(c) for c in selected],
                     'output_pixels': pixels})
    return metadata, dict(zip(selected, pixels))


def _config_signals(config: Config) -> dict:
    return {'cfg_' + name: int(value) for name, value in asdict(config).items()}


def idle(config: Config, reset_n: int = 1) -> dict:
    return {'reset_n': reset_n, 'pixel_valid': 0, 'pixel_r': 0, 'pixel_g': 0,
            'pixel_b': 0, 'in_sof': 0, 'in_sol': 0, 'in_eol': 0, 'in_eof': 0,
            **_config_signals(config), '_frame': None, '_coordinate': None}


def frame_events(frame: Frame, start: int = 0, end: int | None = None,
                 bubbles: tuple[int, ...] = (), change_at: int | None = None,
                 changed_config: Config | None = None) -> list[dict]:
    """Escalona posições de entrada explícitas; bolha ocorre antes do índice."""
    height, width = frame.rgb.shape[:2]
    if end is None:
        end = width * height
    events = []
    for index in range(start, end):
        config = changed_config if change_at is not None and index >= change_at else frame.config
        if index in bubbles:
            events.append(idle(config))
        y, x = divmod(index, width)
        red, green, blue = (int(v) for v in frame.rgb[y, x])
        events.append({'reset_n': 1, 'pixel_valid': 1, 'pixel_r': red, 'pixel_g': green,
                       'pixel_b': blue, 'in_sof': int(index == 0), 'in_sol': int(x == 0),
                       'in_eol': int(x == width - 1), 'in_eof': int(index == width * height - 1),
                       **_config_signals(config), '_frame': frame.name, '_coordinate': [x, y]})
    return events


def build_case(name: str, seed: int, frames: list[Frame], events: list[dict]) -> dict:
    """Gera expectativas a partir de resultados por quadro e posições agendadas."""
    references = {f.name: _frame_reference(f) for f in frames}
    if len(references) != len(frames):
        raise ValueError('nomes de quadros duplicados')
    zero = {'pixel_out_valid': 0, 'pixel_out': 0, 'out_sof': 0, 'out_sol': 0,
            'out_eol': 0, 'out_eof': 0, 'cfg_error': 0}
    previous = zero
    active = None
    rows = []
    for number, event in enumerate(events):
        after = dict(zero)
        consume = int(bool(event['reset_n'] and previous['pixel_out_valid']))
        if not event['reset_n']:
            active = None
        elif event['pixel_valid']:
            frame_name = event['_frame']
            if event['in_sof']:
                active = frame_name
                frame = next(f for f in frames if f.name == frame_name)
                if any(event['cfg_' + key] != int(value) for key, value in asdict(frame.config).items()):
                    raise ValueError('configuração no SOF difere do quadro declarado')
                if not references[active][0]['valid_config']:
                    after['cfg_error'] = 1
            if active == frame_name:
                pixel = references[active][1].get(tuple(event['_coordinate']))
                if pixel is not None:
                    after.update({'pixel_out_valid': 1, 'pixel_out': pixel['value'],
                                  'out_sof': int(pixel['sof']), 'out_sol': int(pixel['sol']),
                                  'out_eol': int(pixel['eol']), 'out_eof': int(pixel['eof'])})
                if event['in_eof']:
                    active = None
        inputs = {key: number if key == 'cycle' else int(event[key]) for key in INPUT_FIELDS}
        expected = {'cycle': number, **after, 'consume_valid': consume}
        rows.append({'input': inputs, 'expected_after': expected,
                     'source': {'frame': event['_frame'], 'coordinate': event['_coordinate']}})
        previous = after
    summary = {'cycles': len(rows), 'input_valid': sum(r['input']['pixel_valid'] for r in rows),
               'output_registered': sum(r['expected_after']['pixel_out_valid'] for r in rows),
               'output_consumed': sum(r['expected_after']['consume_valid'] for r in rows),
               'cfg_error_pulses': sum(r['expected_after']['cfg_error'] for r in rows)}
    return {'format_version': 1, 'name': name, 'seed': seed, 'summary': summary,
            'frames': [references[f.name][0] for f in frames], 'cycles': rows}


def scenarios() -> list[dict]:
    """Cenários pequenos dirigidos; sementes registradas por caso."""
    cases = []

    def one(name, width, height, cfg, seed, primaries=False, bubbles=()):
        f = Frame('frame0', pattern(width, height, seed, primaries), cfg, seed)
        cases.append(build_case(name, seed, [f], [idle(cfg, 0)] + frame_events(f, bubbles=bubbles) + [idle(cfg)]))

    one('01_minimo_1x1', 1, 1, Config(1, 1), 101, True)
    one('02_primarias_4x4', 4, 4, Config(4, 4), 102, True)
    one('03_centro_f12_t0', 8, 8, Config(8, 8, True, 2, 2, 4, 4, False, True, True, 0), 103)
    one('04_borda_f21_t255', 8, 8, Config(8, 8, True, 4, 4, 4, 4, True, False, True, 255), 104)
    one('05_impar_f22_t128_bolhas', 5, 3, Config(5, 3, True, 0, 0, 5, 3, True, True, True, 128), 105, bubbles=(0, 2, 4, 8, 14))
    one('06_aleatorio_16x16', 16, 16, Config(16, 16), 606)

    cfg = Config(4, 4)
    changed = replace(cfg, threshold_enable=True, threshold=128)
    a = Frame('frame0', pattern(4, 4, 107), cfg, 107)
    b = Frame('frame1', pattern(4, 4, 108), changed, 108)
    cases.append(build_case('07_config_e_quadros_consecutivos', 107, [a, b],
                            [idle(cfg, 0)] + frame_events(a, change_at=3, changed_config=changed)
                            + frame_events(b) + [idle(changed)]))

    a = Frame('interrompido', pattern(4, 4, 109), cfg, 109)
    b = Frame('recuperado', pattern(4, 4, 110), cfg, 110)
    cases.append(build_case('08_reset_e_recuperacao', 109, [a, b],
                            [idle(cfg, 0)] + frame_events(a, end=3) + [idle(cfg, 0)]
                            + frame_events(a, start=3) + frame_events(b) + [idle(cfg)]))

    bad_roi = Config(4, 4, True, 3, 0, 2, 1)
    bad_zero = Config(1, 1, resize_x2=True)
    valid = Config(1, 1)
    a = Frame('roi_invalida', pattern(4, 4, 111), bad_roi, 111)
    b = Frame('saida_zero', pattern(1, 1, 112), bad_zero, 112)
    c = Frame('recuperado', pattern(1, 1, 113), valid, 113)
    cases.append(build_case('09_invalidos_e_recuperacao', 111, [a, b, c],
                            [idle(bad_roi, 0)] + frame_events(a) + frame_events(b)
                            + frame_events(c) + [idle(valid)]))
    return cases


def _text_rows(case: dict, kind: str, fields: tuple[str, ...]) -> bytes:
    lines = ['# ' + ' '.join(fields)]
    lines += [' '.join(str(row[kind][field]) for field in fields) for row in case['cycles']]
    return ('\n'.join(lines) + '\n').encode('ascii')


def artifacts() -> dict[str, bytes]:
    files = {}
    cases = scenarios()
    index = {'format_version': 1, 'cases': [{'name': c['name'], 'seed': c['seed'], **c['summary']} for c in cases]}
    files['index.json'] = (json.dumps(index, indent=2, sort_keys=True) + '\n').encode('utf-8')
    for case in cases:
        name = case['name']
        files[name + '.json'] = (json.dumps(case, sort_keys=True, separators=(',', ':')) + '\n').encode('utf-8')
        files[name + '.stim.txt'] = _text_rows(case, 'input', INPUT_FIELDS)
        files[name + '.expect.txt'] = _text_rows(case, 'expected_after', OUTPUT_FIELDS)
    return files


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output-dir', type=Path, default=Path('vectors/m2'))
    parser.add_argument('--check', action='store_true', help='compara arquivos existentes sem modificá-los')
    args = parser.parse_args()
    files = artifacts()
    if args.check:
        errors = [name for name, content in files.items()
                  if not (args.output_dir / name).is_file() or (args.output_dir / name).read_bytes() != content]
        if errors:
            raise SystemExit('Arquivos ausentes ou divergentes: ' + ', '.join(errors))
        print(f'OK: {len(files)} arquivos idênticos em {args.output_dir}')
        return
    existing = [name for name in files if (args.output_dir / name).exists()]
    if existing:
        raise SystemExit('Arquivos já existem; use --check ou outro diretório: ' + ', '.join(existing))
    args.output_dir.mkdir(parents=True, exist_ok=True)
    for name, content in files.items():
        with (args.output_dir / name).open('xb') as f:
            f.write(content)
    print(f'Gerados {len(files)} arquivos em {args.output_dir}')


if __name__ == '__main__':
    main()
