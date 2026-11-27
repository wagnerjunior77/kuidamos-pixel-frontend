"""Gera o caso complementar M11 e confronta a captura do DUT com a referência."""

import argparse
import hashlib
import json
import re
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageOps

from model.golden import Config
from model.m2_vectors import INPUT_FIELDS, OUTPUT_FIELDS, Frame, build_case, frame_events, idle
from model.real_image_demo import fit_for_model

CASE = "m11_imagem_real"


def prepare(image_path, out):
    with Image.open(image_path) as photo:
        source = ImageOps.exif_transpose(photo).convert("RGB")
    prepared = fit_for_model(source, 256)
    width, height = prepared.size
    if min(width, height) < 8:
        raise ValueError("A imagem preparada precisa ter pelo menos 8 pixels em cada eixo")
    x, y = width // 8, height // 8
    config = Config(width, height, crop_enable=True, x_start=x, y_start=y,
                    crop_width=width - 2 * x - 1, crop_height=height - 2 * y - 1,
                    resize_x2=True, resize_y2=True, threshold_enable=True, threshold=128)
    frame = Frame("estacionamento", np.asarray(prepared), config, seed=0)
    bubbles = (0, y * width + x, width * height - 1)
    events = [idle(config, reset_n=0)] * 2 + frame_events(frame, bubbles=bubbles) + [idle(config)] * 3
    case = build_case(CASE, 0, [frame], events)
    for suffix, key, fields in (("stim", "input", INPUT_FIELDS), ("expect", "expected_after", OUTPUT_FIELDS)):
        with (out / f"{CASE}.{suffix}.txt").open("x", encoding="ascii") as stream:
            stream.write("# " + " ".join(fields) + "\n")
            for row in case["cycles"]:
                stream.write(" ".join(str(row[key][field]) for field in fields) + "\n")
    reference = case["frames"][0]
    shape = (reference["output_height"], reference["output_width"])
    golden = np.array([pixel["value"] for pixel in reference["output_pixels"]], dtype=np.uint8).reshape(shape)
    prepared.save(out / "rgb.png")
    Image.fromarray(golden).save(out / "golden.png")
    metadata = {
        "image_sha256": hashlib.sha256(image_path.read_bytes()).hexdigest(),
        "original_size": source.size, "prepared_size": prepared.size, "externally_resampled": source.size != prepared.size,
        "config": reference["config"], "bubbles_before_input_indices": bubbles, "output_size": [shape[1], shape[0]],
        "reference_white_pixels": int(np.count_nonzero(golden)), "cycles": case["summary"],
    }
    (out / "metadata.json").write_text(json.dumps(metadata, indent=2) + "\n")
    print(case["summary"]["cycles"])


def instrument(source, target, mode):
    text = source.read_text()
    module = "module tb_kuidamos_pixel_frontend;\n"
    sample = "        #1ns;\n"
    for anchor in (module, sample):
        if text.count(anchor) != 1:
            raise ValueError(f"Ponto de instrumentação mudou: {anchor.strip()}")
    text = text.replace(module, module + """
    integer capture;
    initial begin
        capture = $fopen("captured.tsv", "w");
        if (capture == 0) $fatal(1, "Erro ao abrir captura M11");
    end
    final if (capture != 0) $fclose(capture);
""")
    text = text.replace(sample, sample + r"""
        $fdisplay(capture, "%0d\t%0d\t%0d\t%0d\t%0d\t%0d\t%0d\t%0d",
                  cyc, pixel_out_valid, pixel_out, out_sof, out_sol, out_eol, out_eof, cfg_error);
""")
    if mode == "gate":
        # A netlist não mantém as sondas RTL que alimentam este monitor.
        text, count = re.subn(r"(?ms)^    kuidamos_pixel_frontend_sva u_sva \(.*?^    \);\n", "", text)
        instance = "    kuidamos_pixel_frontend u_dut (\n"
        if count != 1 or text.count(instance) != 1:
            raise ValueError("Interface do testbench para gate-level mudou")
        text = text.replace(instance, instance + "        .scan_enable (1'b0),\n"
                            "        .scan_in (1'b0),\n        .scan_out (),\n")
        text = text.replace("u_sva.sva_error_count", "0").replace("u_sva.sva_check_count", "0")
    with target.open("x") as out:
        out.write(text)


def comparison(vectors, out, actual, delta, mode):
    with Image.open(vectors / "rgb.png") as rgb, Image.open(vectors / "golden.png") as golden:
        panels = [("Entrada RGB888", rgb), ("Golden Model", golden),
                  ("Saida RTL" if mode == "rtl" else "Saida gate-level", actual), ("Mapa de diferencas", delta)]
        canvas = Image.new("RGB", (1008, 351), "#f3f5f8")
        draw = ImageDraw.Draw(canvas)
        for i, (label, panel) in enumerate(panels):
            x = 12 + i * 249
            draw.text((x, 14), label, fill="#152437")
            draw.text((x, 30), f"{panel.width} x {panel.height} px", fill="#40576e")
            preview = ImageOps.contain(panel.convert("RGB"), (233, 282), Image.Resampling.NEAREST)
            canvas.paste(preview, (x + (233 - preview.width) // 2, 50 + (282 - preview.height) // 2))
        draw.text((12, 335), "Mapa de diferencas: preto = igual; branco = pixel diferente.", fill="#152437")
        canvas.save(out / "comparativo.png")


def verify(vectors, out, mode, *, render_comparison=True):
    metadata = json.loads((vectors / "metadata.json").read_text())
    shape = tuple(reversed(metadata["output_size"]))
    expected = np.loadtxt(vectors / f"{CASE}.expect.txt", dtype=np.int64, ndmin=2)[:, :-1]
    seen = np.loadtxt(out / "captured.tsv", dtype=np.int64, ndmin=2)
    if seen.shape != expected.shape or not np.array_equal(seen[:, 0], np.arange(len(expected))):
        raise ValueError(f"Captura incompleta ou fora da ordem de ciclos: {seen.shape}, esperado {expected.shape}")
    if np.any((seen[:, 1] < 0) | (seen[:, 1] > 1)) or np.any((seen[:, 2] < 0) | (seen[:, 2] > 255)):
        raise ValueError("Valor inválido na captura")
    received = seen[seen[:, 1] == 1, 2:7]
    reference = expected[expected[:, 1] == 1, 2:7]
    if len(received) != len(reference):
        raise ValueError(f"Quantidade divergente: esperado {len(reference)}, emitido {len(received)}")
    actual_pixels = received[:, 0].astype(np.uint8).reshape(shape)
    with Image.open(vectors / "golden.png") as golden:
        golden_pixels = np.asarray(golden)
    if not np.array_equal(golden_pixels.ravel(), reference[:, 0]):
        raise ValueError("PNG e vetor esperado não correspondem")
    difference = actual_pixels != golden_pixels
    rtl_image = Image.fromarray(actual_pixels)
    diff_image = Image.fromarray(difference.astype(np.uint8) * 255)
    rtl_image.save(out / "dut.png")
    diff_image.save(out / "diferencas.png")
    if render_comparison:
        comparison(vectors, out, rtl_image, diff_image, mode)
    result = {
        "mode": mode, "cycles": len(seen), "pixels": len(received),
        "white_pixels": int(np.count_nonzero(actual_pixels == 255)),
        "pixel_mismatches": int(np.count_nonzero(difference)),
        "marker_mismatches": int(np.count_nonzero(np.any(received[:, 1:] != reference[:, 1:], axis=1))),
        "cycle_mismatches": int(np.count_nonzero(np.any(seen != expected, axis=1))),
    }
    rendered = json.dumps(result, indent=2)
    (out / "result.json").write_text(rendered + "\n")
    print(rendered)
    if any(result[k] for k in ("pixel_mismatches", "marker_mismatches", "cycle_mismatches")):
        raise SystemExit("Captura do DUT diverge do Golden Model")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("action", choices=("prepare", "instrument", "verify"))
    parser.add_argument("source", type=Path)
    parser.add_argument("target", type=Path)
    parser.add_argument("--mode", choices=("rtl", "gate"), default="rtl")
    args = parser.parse_args()
    if args.action == "prepare":
        prepare(args.source, args.target)
    elif args.action == "instrument":
        instrument(args.source, args.target, args.mode)
    else:
        verify(args.source, args.target, args.mode)


if __name__ == "__main__":
    main()
