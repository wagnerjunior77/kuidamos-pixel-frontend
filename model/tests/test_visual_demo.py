import contextlib
import io
import tempfile
import unittest
from pathlib import Path

import numpy as np
from PIL import Image

from model.visual_demo import make_demo


class VisualDemoTests(unittest.TestCase):
    def test_imagem_sintetica_e_protecao_contra_sobrescrita(self):
        with tempfile.TemporaryDirectory() as temporary, contextlib.redirect_stdout(io.StringIO()):
            output = Path(temporary) / 'out'
            paths = make_demo(None, output)
            self.assertEqual(len(paths), 5)
            with Image.open(paths['01_original_rgb.png']) as original:
                self.assertEqual((original.mode, original.size), ('RGB', (320, 240)))
            with Image.open(paths['05_threshold.png']) as threshold:
                self.assertEqual(threshold.size, (120, 90))
                self.assertEqual(set(np.unique(np.asarray(threshold))), {0, 255})
            before = {name: path.read_bytes() for name, path in paths.items()}
            with self.assertRaises(FileExistsError):
                make_demo(None, output)
            self.assertEqual(before, {name: path.read_bytes() for name, path in paths.items()})

    def test_imagem_externa_um_pixel(self):
        with tempfile.TemporaryDirectory() as temporary, contextlib.redirect_stdout(io.StringIO()):
            root = Path(temporary)
            original = root / 'input.png'
            Image.new('RGB', (1, 1), (255, 0, 0)).save(original)
            paths = make_demo(original, root / 'out')
            with Image.open(paths['01_original_rgb.png']) as saved:
                self.assertEqual(saved.getpixel((0, 0)), (255, 0, 0))
            with Image.open(paths['02_grayscale.png']) as gray:
                self.assertEqual(gray.getpixel((0, 0)), 76)
            with Image.open(paths['05_threshold.png']) as threshold:
                self.assertEqual(threshold.getpixel((0, 0)), 0)


if __name__ == '__main__':
    unittest.main()
