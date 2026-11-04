import json
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

import numpy as np

from model.golden import Config, ConfigError, process_frame
from model.m2_vectors import artifacts, pattern, scenarios


class M2VectorTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.cases = {case['name']: case for case in scenarios()}

    def test_casos_e_cobertura_funcional(self):
        self.assertEqual(len(self.cases), 9)
        frames = [f for case in self.cases.values() for f in case['frames']]
        sizes = {(f['config']['in_width'], f['config']['in_height']) for f in frames}
        self.assertTrue({(1, 1), (4, 4), (5, 3), (8, 8), (16, 16)} <= sizes)
        valid = [f['config'] for f in frames if f['valid_config']]
        self.assertEqual({(int(c['resize_x2']), int(c['resize_y2'])) for c in valid},
                         {(0, 0), (0, 1), (1, 0), (1, 1)})
        self.assertTrue({0, 128, 255} <= {c['threshold'] for c in valid if c['threshold_enable']})
        self.assertEqual({c['crop_enable'] for c in valid}, {False, True})
        self.assertEqual({c['threshold_enable'] for c in valid}, {False, True})

    def test_resultados_funcionais_e_coordenadas(self):
        for case in self.cases.values():
            for frame in case['frames']:
                cfg = Config(**frame['config'])
                rgb = np.array(frame['rgb'], dtype=np.uint8)
                with self.subTest(case=case['name'], frame=frame['name']):
                    if not frame['valid_config']:
                        with self.assertRaises(ConfigError):
                            process_frame(rgb, cfg)
                        self.assertEqual(frame['output_pixels'], [])
                        continue
                    result = process_frame(rgb, cfg)
                    self.assertEqual((result.width, result.height), (frame['output_width'], frame['output_height']))
                    self.assertEqual([p.value for p in result.pixels], [p['value'] for p in frame['output_pixels']])
                    w = cfg.crop_width if cfg.crop_enable else cfg.in_width
                    h = cfg.crop_height if cfg.crop_enable else cfg.in_height
                    x0 = cfg.x_start if cfg.crop_enable else 0
                    y0 = cfg.y_start if cfg.crop_enable else 0
                    expected_coords = [[x0 + ox * w // result.width, y0 + oy * h // result.height]
                                       for oy in range(result.height) for ox in range(result.width)]
                    self.assertEqual(frame['selected'], expected_coords)
                    for coord, pixel in zip(expected_coords, frame['output_pixels']):
                        x, y = coord
                        r, g, b = map(int, rgb[y, x])
                        value = (77 * r + 150 * g + 29 * b) // 256
                        if cfg.threshold_enable:
                            value = 255 if value >= cfg.threshold else 0
                        self.assertEqual(pixel['value'], value)

    def test_marcadores_e_quantidade_por_quadro(self):
        for case in self.cases.values():
            for frame in case['frames']:
                if not frame['valid_config']:
                    continue
                w, h = frame['output_width'], frame['output_height']
                pixels = frame['output_pixels']
                self.assertEqual(len(pixels), w * h)
                for i, p in enumerate(pixels):
                    y, x = divmod(i, w)
                    self.assertEqual((p['sof'], p['sol'], p['eol'], p['eof']),
                                     (x == 0 and y == 0, x == 0, x == w - 1, x == w - 1 and y == h - 1))

    def test_caso_minimo_latencia_marcadores(self):
        rows = self.cases['01_minimo_1x1']['cycles']
        self.assertEqual(len(rows), 3)
        self.assertEqual(rows[0]['input']['reset_n'], 0)
        self.assertEqual(rows[0]['expected_after']['pixel_out_valid'], 0)
        self.assertEqual(rows[1]['expected_after']['pixel_out_valid'], 1)
        self.assertEqual([rows[1]['expected_after'][x] for x in ('out_sof', 'out_sol', 'out_eol', 'out_eof')], [1, 1, 1, 1])
        self.assertEqual(rows[1]['expected_after']['consume_valid'], 0)
        self.assertEqual(rows[2]['expected_after']['pixel_out_valid'], 0)
        self.assertEqual(rows[2]['expected_after']['consume_valid'], 1)

    def test_bolhas_descartes_e_mapeamento_temporal(self):
        case = self.cases['05_impar_f22_t128_bolhas']
        frame = case['frames'][0]
        self.assertEqual(frame['selected'], [[0, 0], [2, 0]])
        emitted = []
        for row in case['cycles']:
            inp, out = row['input'], row['expected_after']
            if not inp['pixel_valid']:
                self.assertEqual(out['pixel_out_valid'], 0)
                self.assertEqual([out[k] for k in ('pixel_out', 'out_sof', 'out_sol', 'out_eol', 'out_eof')], [0] * 5)
            if out['pixel_out_valid']:
                emitted.append((row['source']['coordinate'], out['pixel_out']))
        self.assertEqual(emitted, [(coord, p['value']) for coord, p in zip(frame['selected'], frame['output_pixels'])])

    def test_todos_ciclos_correspondem_a_posicao_e_consumo(self):
        for case in self.cases.values():
            refs = {f['name']: {tuple(xy): p for xy, p in zip(f['selected'], f['output_pixels'])}
                    for f in case['frames']}
            active = None
            previous_valid = 0
            for row in case['cycles']:
                inp, out, src = row['input'], row['expected_after'], row['source']
                with self.subTest(case=case['name'], cycle=inp['cycle']):
                    self.assertEqual(out['consume_valid'], int(bool(inp['reset_n'] and previous_valid)))
                    if not inp['reset_n']:
                        active = None
                    elif inp['pixel_valid'] and inp['in_sof']:
                        active = src['frame']
                    expected_pixel = None
                    if inp['reset_n'] and inp['pixel_valid'] and src['frame'] == active and active is not None:
                        expected_pixel = refs[active].get(tuple(src['coordinate']))
                    self.assertEqual(out['pixel_out_valid'], int(expected_pixel is not None))
                    if expected_pixel is not None:
                        self.assertEqual([out['pixel_out'], out['out_sof'], out['out_sol'], out['out_eol'], out['out_eof']],
                                         [expected_pixel['value'], int(expected_pixel['sof']), int(expected_pixel['sol']),
                                          int(expected_pixel['eol']), int(expected_pixel['eof'])])
                    else:
                        self.assertEqual([out[k] for k in ('pixel_out', 'out_sof', 'out_sol', 'out_eol', 'out_eof')], [0] * 5)
                    if inp['reset_n'] and inp['pixel_valid'] and inp['in_eof'] and active == src['frame']:
                        active = None
                    previous_valid = out['pixel_out_valid']

    def test_configuracao_em_sof_e_quadros_consecutivos(self):
        case = self.cases['07_config_e_quadros_consecutivos']
        rows = case['cycles']
        self.assertEqual(rows[4]['input']['cfg_threshold_enable'], 1)
        outputs = {frame['name']: [] for frame in case['frames']}
        for row in rows:
            if row['expected_after']['pixel_out_valid']:
                outputs[row['source']['frame']].append(row['expected_after']['pixel_out'])
        for frame in case['frames']:
            self.assertEqual(outputs[frame['name']], [p['value'] for p in frame['output_pixels']])
        second_sof = next(r for r in rows if r['source']['frame'] == 'frame1')
        self.assertEqual(second_sof['input']['in_sof'], 1)
        self.assertEqual(second_sof['expected_after']['consume_valid'], 1)

    def test_reset_cancela_transferencia_e_recupera(self):
        rows = self.cases['08_reset_e_recuperacao']['cycles']
        self.assertEqual(rows[3]['expected_after']['pixel_out_valid'], 1)
        self.assertEqual(rows[4]['input']['reset_n'], 0)
        self.assertEqual(rows[4]['expected_after']['consume_valid'], 0)
        self.assertEqual(rows[4]['expected_after']['pixel_out_valid'], 0)
        leftovers = [r for r in rows[5:] if r['source']['frame'] == 'interrompido']
        self.assertTrue(leftovers)
        self.assertTrue(all(not r['expected_after']['pixel_out_valid'] for r in leftovers))
        recovered = [r for r in rows if r['source']['frame'] == 'recuperado' and r['expected_after']['pixel_out_valid']]
        self.assertEqual(len(recovered), 16)
        self.assertEqual(recovered[0]['expected_after']['out_sof'], 1)
        self.assertEqual(recovered[-1]['expected_after']['out_eof'], 1)

    def test_invalidos_pulso_e_recuperacao(self):
        case = self.cases['09_invalidos_e_recuperacao']
        rows = case['cycles']
        self.assertEqual([r['input']['cycle'] for r in rows if r['expected_after']['cfg_error']], [1, 17])
        self.assertTrue(all(not r['expected_after']['pixel_out_valid'] for r in rows
                            if r['source']['frame'] in ('roi_invalida', 'saida_zero')))
        self.assertEqual(rows[18]['expected_after']['pixel_out_valid'], 1)
        self.assertEqual(rows[18]['expected_after']['cfg_error'], 0)
        self.assertEqual(rows[19]['expected_after']['consume_valid'], 1)

    def test_json_consistente_com_texto_e_contagens(self):
        files = artifacts()
        for case in self.cases.values():
            name = case['name']
            stored = json.loads(files[name + '.json'])
            self.assertEqual(stored, case)
            for suffix, kind in (('.stim.txt', 'input'), ('.expect.txt', 'expected_after')):
                lines = files[name + suffix].decode('ascii').splitlines()
                fields = lines[0][2:].split()
                self.assertEqual(len(fields), 21 if kind == 'input' else 9)
                self.assertEqual(len(lines) - 1, case['summary']['cycles'])
                self.assertTrue(all(len(line.split()) == len(fields) for line in lines[1:]))
                parsed = [dict(zip(fields, map(int, line.split()))) for line in lines[1:]]
                self.assertEqual(parsed, [row[kind] for row in case['cycles']])
            self.assertEqual(case['summary']['output_registered'], sum(r['expected_after']['pixel_out_valid'] for r in case['cycles']))
            self.assertEqual(case['summary']['output_consumed'], sum(r['expected_after']['consume_valid'] for r in case['cycles']))
            self.assertEqual(case['summary']['input_valid'], sum(r['input']['pixel_valid'] for r in case['cycles']))
            self.assertEqual(case['summary']['cfg_error_pulses'], sum(r['expected_after']['cfg_error'] for r in case['cycles']))
            for row in case['cycles']:
                inp, out = row['input'], row['expected_after']
                for key in ('pixel_r', 'pixel_g', 'pixel_b', 'cfg_threshold'):
                    self.assertGreaterEqual(inp[key], 0)
                    self.assertLessEqual(inp[key], 255)
                for key in ('cfg_in_width', 'cfg_in_height', 'cfg_x_start', 'cfg_y_start', 'cfg_crop_width', 'cfg_crop_height'):
                    self.assertGreaterEqual(inp[key], 0)
                    self.assertLessEqual(inp[key], 2047)
                for key in ('reset_n', 'pixel_valid', 'in_sof', 'in_sol', 'in_eol', 'in_eof',
                            'cfg_crop_enable', 'cfg_resize_x2', 'cfg_resize_y2', 'cfg_threshold_enable'):
                    self.assertIn(inp[key], (0, 1))
                for key in ('pixel_out_valid', 'out_sof', 'out_sol', 'out_eol', 'out_eof', 'cfg_error', 'consume_valid'):
                    self.assertIn(out[key], (0, 1))

    def test_reproducibilidade_e_sem_sobrescrita(self):
        self.assertEqual(artifacts(), artifacts())
        self.assertTrue(np.array_equal(pattern(4, 4, 123), pattern(4, 4, 123)))
        self.assertFalse(np.array_equal(pattern(4, 4, 123), pattern(4, 4, 124)))
        with tempfile.TemporaryDirectory() as temporary:
            out = Path(temporary) / 'vectors'
            cmd = [sys.executable, '-m', 'model.m2_vectors', '--output-dir', str(out)]
            subprocess.run(cmd, check=True, capture_output=True)
            before = {p.name: p.read_bytes() for p in out.iterdir()}
            self.assertNotEqual(subprocess.run(cmd, capture_output=True).returncode, 0)
            subprocess.run(cmd + ['--check'], check=True, capture_output=True)
            self.assertEqual(before, {p.name: p.read_bytes() for p in out.iterdir()})


if __name__ == '__main__':
    unittest.main()
