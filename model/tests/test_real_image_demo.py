import contextlib
import io
import tempfile
import unittest
from pathlib import Path

import numpy as np
from PIL import Image

from model.golden import Config, process_frame
from model.real_image_demo import fit_for_model, run


class RealImageDemoTests(unittest.TestCase):
    def test_preparacao_proporcional_so_acima_do_limite(self):
        image = Image.new('RGB', (10, 8), (255, 0, 0))
        self.assertEqual(fit_for_model(image, 4).size, (4, 3))
        self.assertEqual(fit_for_model(image, 10).size, (10, 8))

    def test_pipeline_externo_arquivos_e_nao_sobrescrita(self):
        with tempfile.TemporaryDirectory() as temporary, contextlib.redirect_stdout(io.StringIO()):
            root = Path(temporary)
            source = root / 'input.png'
            pixels = np.zeros((8, 10, 3), dtype=np.uint8)
            pixels[:, :, 0] = np.arange(10, dtype=np.uint8) * 20
            Image.fromarray(pixels).save(source)
            result = run(source, root / 'result')
            self.assertEqual(result['original_size'], [10, 8])
            self.assertEqual(result['model_input_size'], [10, 8])
            self.assertEqual(result['crop'], {'x_start': 1, 'y_start': 1, 'width': 8, 'height': 6})
            self.assertEqual(result['resize_output_size'], [4, 3])
            expected = process_frame(pixels, Config(10, 8, True, 1, 1, 8, 6, True, True, True, 128)).image
            with Image.open(root / 'result' / '05_threshold.png') as output:
                np.testing.assert_array_equal(np.asarray(output), expected)
            self.assertTrue((root / 'result' / '06_comparativo.png').is_file())
            original_files = {name: (root / 'result' / name).read_bytes() for name in result['files']}
            with self.assertRaises(FileExistsError):
                run(source, root / 'result')
            self.assertEqual(original_files, {name: (root / 'result' / name).read_bytes() for name in result['files']})


if __name__ == '__main__':
    unittest.main()
