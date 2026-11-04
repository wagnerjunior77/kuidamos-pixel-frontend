import contextlib
import io
import tempfile
import unittest
from pathlib import Path

import numpy as np
from PIL import Image

from model.threshold_sweep import THRESHOLDS, run


class ThresholdSweepTests(unittest.TestCase):
    def test_pipeline_limiares_e_protecao_de_arquivos(self):
        with tempfile.TemporaryDirectory() as temporary, contextlib.redirect_stdout(io.StringIO()):
            root = Path(temporary)
            image_path = root / 'input.png'
            values = np.tile(np.arange(10, dtype=np.uint8) * 25, (8, 1))
            rgb = np.repeat(values[:, :, None], 3, axis=2)
            Image.fromarray(rgb).save(image_path)
            output = root / 'sweep'
            result = run(image_path, output)
            self.assertEqual(result['base']['resize_output_size'], [4, 3])
            self.assertEqual(set(result['thresholds']), {str(t) for t in THRESHOLDS})
            with Image.open(output / '04_resize_nearest.png') as image:
                grayscale = np.asarray(image).copy()
            white_counts = []
            for threshold in THRESHOLDS:
                with Image.open(output / f'threshold_{threshold}.png') as image:
                    pixels = np.asarray(image)
                    np.testing.assert_array_equal(pixels, np.where(grayscale >= threshold, 255, 0))
                white_counts.append(result['thresholds'][str(threshold)]['white_pixels'])
            self.assertEqual(white_counts, sorted(white_counts, reverse=True))
            self.assertTrue((output / 'comparativo_thresholds.png').is_file())
            before = {p.name: p.read_bytes() for p in output.iterdir()}
            with self.assertRaises(FileExistsError):
                run(image_path, output)
            self.assertEqual(before, {p.name: p.read_bytes() for p in output.iterdir()})


if __name__ == '__main__':
    unittest.main()
