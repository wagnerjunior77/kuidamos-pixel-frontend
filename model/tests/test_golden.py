import unittest
from dataclasses import replace

import numpy as np

from model.golden import Config, ConfigError, process_frame, validate_config
from model.generate_vectors import generate


def mono(rows):
    """Para R=G=B=v, a fórmula devolve exatamente v."""
    a = np.array(rows, dtype=np.uint8)
    return np.repeat(a[:, :, None], 3, axis=2)


class GoldenTests(unittest.TestCase):
    def test_cores_e_truncamento(self):
        rgb = np.array([[[0, 0, 0], [255, 0, 0], [0, 255, 0],
                         [0, 0, 255], [255, 255, 255], [1, 1, 1]]], dtype=np.uint8)
        result = process_frame(rgb, Config(6, 1))
        self.assertEqual(result.image.tolist(), [[0, 76, 149, 28, 255, 1]])

    def test_crop_centro_e_bordas_exclusivas(self):
        rgb = mono(np.arange(48).reshape(6, 8))
        cfg = Config(8, 6, crop_enable=True, x_start=2, y_start=1, crop_width=5, crop_height=3)
        self.assertEqual(process_frame(rgb, cfg).image.tolist(),
                         [[10, 11, 12, 13, 14], [18, 19, 20, 21, 22], [26, 27, 28, 29, 30]])

    def test_crop_na_borda_e_pixel_unico(self):
        rgb = mono([[1, 2], [3, 4]])
        cfg = Config(2, 2, crop_enable=True, x_start=1, y_start=1, crop_width=1, crop_height=1)
        result = process_frame(rgb, cfg)
        self.assertEqual(result.image.tolist(), [[4]])
        p = list(result.pixels)[0]
        self.assertEqual((p.sof, p.sol, p.eol, p.eof), (True, True, True, True))

    def test_bypass_ignora_roi(self):
        rgb = mono([[1, 2], [3, 4]])
        cfg = Config(2, 2, x_start=99999, crop_width=0, crop_height=-1)
        np.testing.assert_array_equal(process_frame(rgb, cfg).image, rgb[:, :, 0])

    def test_resize_par_e_impar_e_eixos_independentes(self):
        rgb = mono(np.arange(15).reshape(3, 5))
        self.assertEqual(process_frame(rgb, Config(5, 3, resize_x2=True)).image.tolist(),
                         [[0, 2], [5, 7], [10, 12]])
        self.assertEqual(process_frame(rgb, Config(5, 3, resize_y2=True)).image.tolist(), [[0, 1, 2, 3, 4]])
        self.assertEqual(process_frame(rgb, Config(5, 3, resize_x2=True, resize_y2=True)).image.tolist(), [[0, 2]])
        even = mono(np.arange(64).reshape(8, 8))
        self.assertEqual(process_frame(even, Config(8, 8, resize_x2=True, resize_y2=True)).image.tolist(),
                         [[0, 2, 4, 6], [16, 18, 20, 22], [32, 34, 36, 38], [48, 50, 52, 54]])

    def test_cadeia_crop_resize_e_threshold(self):
        rgb = mono(np.arange(48).reshape(6, 8))
        cfg = Config(8, 6, True, 2, 1, 5, 3, True, True, True, 12)
        result = process_frame(rgb, cfg)
        self.assertEqual((result.width, result.height), (2, 1))
        self.assertEqual(result.image.tolist(), [[0, 255]])
        self.assertEqual([(p.sof, p.sol, p.eol, p.eof) for p in result.pixels],
                         [(True, True, False, False), (False, False, True, True)])

    def test_threshold_igualdade_e_extremos(self):
        rgb = mono([[0, 127, 128, 129, 255]])
        self.assertEqual(process_frame(rgb, Config(5, 1, threshold_enable=True, threshold=128)).image.tolist(),
                         [[0, 0, 255, 255, 255]])
        self.assertEqual(process_frame(rgb, Config(5, 1, threshold_enable=True, threshold=0)).image.tolist(),
                         [[255] * 5])
        self.assertEqual(process_frame(rgb, Config(5, 1, threshold_enable=True, threshold=255)).image.tolist(),
                         [[0, 0, 0, 0, 255]])
        self.assertEqual(process_frame(rgb, Config(5, 1, threshold=128)).image.tolist(), [[0, 127, 128, 129, 255]])

    def test_flags_em_multiplas_linhas(self):
        result = process_frame(mono([[1, 2, 3], [4, 5, 6]]), Config(3, 2))
        self.assertEqual([(p.sof, p.sol, p.eol, p.eof) for p in result.pixels], [
            (True, True, False, False), (False, False, False, False), (False, False, True, False),
            (False, True, False, False), (False, False, False, False), (False, False, True, True)])

    def test_limite_de_largura_e_altura(self):
        self.assertEqual(validate_config(Config(2047, 2047, resize_x2=True, resize_y2=True))[-2:], (1023, 1023))
        rgb = np.zeros((1, 2047, 3), dtype=np.uint8)
        self.assertEqual(process_frame(rgb, Config(2047, 1, resize_x2=True)).width, 1023)
        rgb = np.zeros((2047, 1, 3), dtype=np.uint8)
        self.assertEqual(process_frame(rgb, Config(1, 2047, resize_y2=True)).height, 1023)

    def test_configuracoes_invalidas(self):
        base = Config(4, 4)
        invalid = [replace(base, in_width=0), replace(base, in_height=2048),
                   replace(base, in_width=-1), replace(base, in_width=4.0),
                   replace(base, crop_enable=True, crop_width=0, crop_height=1),
                   replace(base, crop_enable=True, x_start=3, crop_width=2, crop_height=1),
                   replace(base, crop_enable=True, y_start=2047, crop_width=1, crop_height=2047),
                   replace(base, threshold=256), replace(base, threshold=-1),
                   replace(base, resize_x2=2), replace(base, threshold_enable=0.0),
                   Config(1, 4, resize_x2=True), Config(4, 1, resize_y2=True)]
        for cfg in invalid:
            with self.subTest(cfg=cfg), self.assertRaises(ConfigError):
                validate_config(cfg)

    def test_formato_e_tipo_da_imagem(self):
        with self.assertRaises(ValueError):
            process_frame(np.zeros((2, 2, 3), dtype=np.int32), Config(2, 2))
        with self.assertRaises(ValueError):
            process_frame(np.zeros((2, 2, 4), dtype=np.uint8), Config(2, 2))
        with self.assertRaises(ValueError):
            process_frame(np.zeros((2, 2, 3), dtype=np.uint8), Config(3, 2))

    def test_quadro_invalido_nao_produz_resultado(self):
        with self.assertRaises(ConfigError):
            process_frame(mono([[9]]), Config(1, 1, resize_x2=True))

    def test_grayscale_aleatorio_sem_threshold(self):
        rng = np.random.default_rng(77)
        rgb = rng.integers(0, 256, size=(16, 16, 3), dtype=np.uint8)
        result = process_frame(rgb, Config(16, 16))
        expected = [[(77 * int(r) + 150 * int(g) + 29 * int(b)) // 256
                     for r, g, b in row] for row in rgb]
        self.assertEqual(result.image.tolist(), expected)

    def test_resize_formula_dimensoes_ate_2047(self):
        for n in range(2, 2048):
            out = n // 2
            with self.subTest(n=n):
                self.assertEqual([k * n // out for k in range(out)], list(range(0, out * 2, 2)))

    def test_aleatorio_referencia_escalar_independente(self):
        rng = np.random.default_rng(603)
        for width, height in [(4, 4), (5, 3), (8, 8), (16, 16)]:
            rgb = rng.integers(0, 256, size=(height, width, 3), dtype=np.uint8)
            for fx in (1, 2):
                for fy in (1, 2):
                    cfg = Config(width, height, resize_x2=fx == 2, resize_y2=fy == 2,
                                 threshold_enable=True, threshold=123)
                    result = process_frame(rgb, cfg)
                    expected = []
                    for oy in range(height // fy):
                        row = []
                        for ox in range(width // fx):
                            sy, sx = oy * height // (height // fy), ox * width // (width // fx)
                            r, g, b = (int(v) for v in rgb[sy, sx])
                            value = (77 * r + 150 * g + 29 * b) // 256
                            row.append(255 if value >= 123 else 0)
                        expected.append(row)
                    self.assertEqual(result.image.tolist(), expected)
                    self.assertEqual(len(list(result.pixels)), (width // fx) * (height // fy))

    def test_vetor_reproduzivel_e_marcadores(self):
        first = generate(603)
        self.assertEqual(first, generate(603))
        self.assertNotEqual(first['input_rgb'], generate(604)['input_rgb'])
        self.assertEqual((first['output_width'], first['output_height']), (2, 1))
        self.assertEqual(len(first['input_pixels']), 15)
        self.assertTrue(first['input_pixels'][0]['sof'])
        self.assertTrue(first['input_pixels'][-1]['eof'])
        self.assertEqual(len(first['output_pixels']), 2)
        self.assertEqual([(p['sof'], p['sol'], p['eol'], p['eof']) for p in first['output_pixels']],
                         [(True, True, False, False), (False, False, True, True)])


if __name__ == '__main__':
    unittest.main()
