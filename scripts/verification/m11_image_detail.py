"""Compara os estágios e os limiares da demonstração de estacionamento no M11."""

import argparse
import hashlib
import json
import re
import subprocess
from dataclasses import asdict, replace
from pathlib import Path
from tempfile import mkdtemp

import numpy as np
from PIL import Image, ImageDraw, ImageOps

from model.golden import Config, process_frame, validate_config
from model.m2_vectors import INPUT_FIELDS, OUTPUT_FIELDS
from model.real_image_demo import fit_for_model
from scripts.verification.m11_real_image import CASE, instrument, verify

ROI = (88, 456, 376, 264)
DETAIL = (174, 620, 88, 40)
THRESHOLDS = (64, 96, 128, 160, 192)
RTL_CASES = ("grayscale", "crop_x1", "resize_x2", "t096_x1", "t128_x1", "t096_x2")


def configurations():
    base = Config(576, 1024)
    x, y, w, h = ROI
    crop = replace(base, crop_enable=True, x_start=x, y_start=y, crop_width=w, crop_height=h)
    resize = replace(crop, resize_x2=True, resize_y2=True)
    configs = {"grayscale": base, "crop_x1": crop, "resize_x2": resize}
    for factor, cfg in ((1, crop), (2, resize)):
        for threshold in THRESHOLDS:
            configs[f"t{threshold:03d}_x{factor}"] = replace(cfg, threshold_enable=True, threshold=threshold)
    return configs


def vectors(rgb, cfg, reference, folder):
    """Monta linhas no formato M2 sem alocar dicionários por pixel."""
    height, width = rgb.shape[:2]
    count = width * height
    cycles = count + 5  # dois ciclos de reset e três ciclos finais ociosos
    stim = np.zeros((cycles, len(INPUT_FIELDS)), dtype=np.int32)
    out = np.zeros((cycles, len(OUTPUT_FIELDS)), dtype=np.int32)
    ins = {field: i for i, field in enumerate(INPUT_FIELDS)}
    outs = {field: i for i, field in enumerate(OUTPUT_FIELDS)}
    for key, value in asdict(cfg).items():
        stim[:, ins["cfg_" + key]] = value
    stim[:, ins["cycle"]] = np.arange(cycles)
    stim[2:, ins["reset_n"]] = 1
    frame = stim[2:2 + count]
    frame[:, ins["pixel_valid"]] = 1
    frame[:, ins["pixel_r"]:ins["pixel_b"] + 1] = rgb.reshape(-1, 3)
    frame[0, ins["in_sof"]] = frame[-1, ins["in_eof"]] = 1
    frame[::width, ins["in_sol"]] = frame[width - 1::width, ins["in_eol"]] = 1

    x, y, w, h, ow, oh = validate_config(cfg)
    xs = x + np.arange(ow) * w // ow
    ys = y + np.arange(oh) * h // oh
    selected = 2 + (ys[:, None] * width + xs).ravel()
    out[:, outs["cycle"]] = np.arange(cycles)
    out[selected, outs["pixel_out_valid"]] = 1
    out[selected, outs["pixel_out"]] = reference.ravel()
    out[selected[0], outs["out_sof"]] = out[selected[-1], outs["out_eof"]] = 1
    out[selected[::ow], outs["out_sol"]] = out[selected[ow - 1::ow], outs["out_eol"]] = 1
    out[1:, outs["consume_valid"]] = out[:-1, outs["pixel_out_valid"]]

    for name, array, fields in (("stim", stim, INPUT_FIELDS), ("expect", out, OUTPUT_FIELDS)):
        np.savetxt(folder / f"{CASE}.{name}.txt", array, fmt="%d", header=" ".join(fields))
    (folder / "metadata.json").write_text(json.dumps({"output_size": [ow, oh]}) + "\n")
    return cycles


def run_rtl(repo, out, rgb, configs, references):
    work = out / "vcs"
    work.mkdir()
    tb = repo / "tb/tb_kuidamos_pixel_frontend.sv"
    instrument(tb, work / "tb_image.sv", "rtl")
    # Use a ordem do filelist oficial, substituindo apenas o topo do testbench.
    filelist = (repo / "tb/filelist.f").read_text().split()
    sources = [str(repo / name) for name in filelist if repo / name != tb]
    with (work / "version.txt").open("w") as log:
        subprocess.run(["vcs", "-full64", "-ID"], cwd=work, stdout=log, stderr=subprocess.STDOUT, check=True)
    with (work / "compile.log").open("w") as log:
        subprocess.run(["vcs", "-full64", "-sverilog", "-timescale=1ns/1ps",
                        "-top", "tb_kuidamos_pixel_frontend", *sources, "tb_image.sv", "-o", "simv"],
                       cwd=work, stdout=log, stderr=subprocess.STDOUT, timeout=180, check=True)
    results = {}
    for name in RTL_CASES:
        print(f"VCS {name}", flush=True)
        folder = out / "rtl" / name
        folder.mkdir(parents=True)
        cycles = vectors(rgb, configs[name], references[name], folder)
        Image.fromarray(references[name]).save(folder / "golden.png")
        with (folder / "simulation.log").open("w") as log:
            subprocess.run([str(work / "simv"), "-exitstatus", f"+VECTOR_DIR={folder}",
                            f"+CASE={CASE}", f"+EXPECT_CYCLES={cycles}"], cwd=folder,
                           stdout=log, stderr=subprocess.STDOUT, timeout=120, check=True)
        log = (folder / "simulation.log").read_text()
        pattern = (rf"cases_passed=1/1 \| cycles_checked={cycles} \| scoreboard_mismatches=0 "
                   r"\| sva_errors=0 \(sva_checks=([1-9]\d*)\)")
        match = re.search(pattern, log)
        if not match or "OVERALL RESULT: PASS" not in log:
            raise RuntimeError(f"Scoreboard ou SVA incompletos: {folder / 'simulation.log'}")
        verify(folder, folder, "rtl", render_comparison=False)
        results[name] = {**json.loads((folder / "result.json").read_text()), "sva_checks": int(match[1])}
    return results


def board(target, panels, columns):
    rows = [panels[start:start + columns] for start in range(0, len(panels), columns)]
    cell_width = max(im.width for _, im in panels) + 24
    row_heights = [max(im.height for _, im in row) + 44 for row in rows]
    canvas = Image.new("RGB", (cell_width * columns, sum(row_heights)), "#edf1f6")
    draw = ImageDraw.Draw(canvas)
    y = 0
    for row, height in zip(rows, row_heights):
        for column, (label, im) in enumerate(row):
            x = column * cell_width + 12
            draw.text((x, y + 10), label, fill="#1a2736")
            canvas.paste(im.convert("RGB"), (x, y + 29))
        y += height
    canvas.save(target)


def enlarge(image, times):
    return image.resize((image.width * times, image.height * times), Image.Resampling.NEAREST)


def galleries(out, prepared, references, rtl_cases):
    def sample(name):
        path = (out / "rtl" / name / "dut.png") if name in rtl_cases else (out / "golden" / f"{name}.png")
        with Image.open(path) as image:
            return image.copy()

    boxed = prepared.copy()
    draw = ImageDraw.Draw(boxed)
    for (x, y, w, h), color in ((ROI, "#00d8f5"), (DETAIL, "#ffd643")):
        draw.rectangle((x, y, x + w - 1, y + h - 1), outline=color, width=2)
    board(out / "comparativo_estagios.png", [
        ("RGB888 preparado 576 x 1024 | ROI azul, detalhe amarelo", boxed),
        ("Grayscale RTL 576 x 1024 | threshold desligado", sample("grayscale")),
        ("Crop RTL 376 x 264 | fator 1", sample("crop_x1")),
        ("Resize RTL 188 x 132 | exibido em 2x por replicacao", enlarge(sample("resize_x2"), 2)),
    ], 2)

    x, y, w, h = DETAIL
    dx, dy = x - ROI[0], y - ROI[1]
    for factor, gray in ((1, "crop_x1"), (2, "resize_x2")):
        names = [gray, *(f"t{t:03d}_x{factor}" for t in THRESHOLDS)]
        panels = []
        for index, name in enumerate(names):
            im = sample(name)
            box = dx // factor, dy // factor, (dx + w) // factor, (dy + h) // factor
            source = "RTL" if name in rtl_cases else "Golden Model"
            label = "Cinza" if index == 0 else f"T={THRESHOLDS[index - 1]}"
            panels.append((f"{label} | {source} | detalhe ampliado {3 * factor}x",
                           enlarge(im.crop(box), 3 * factor)))
        board(out / f"comparativo_thresholds_x{factor}.png", panels, 3)

    names = ("crop_x1", "resize_x2", "t096_x1", "t096_x2")
    labels = ("Cinza RTL fator 1", "Cinza RTL fator 2", "T=96 RTL fator 1", "T=96 RTL fator 2")
    panels = []
    for name, label in zip(names, labels):
        factor = 2 if name.endswith("x2") else 1
        im = sample(name)
        box = dx // factor, dy // factor, (dx + w) // factor, (dy + h) // factor
        panels.append((f"{label} | detalhe ampliado {3 * factor}x", enlarge(im.crop(box), 3 * factor)))
    board(out / "detalhe_placa_rtl.png", panels, 2)

    with Image.open(out / "rtl/crop_x1/diferencas.png") as diff:
        board(out / "comparativo_bit_a_bit_crop.png", [
            ("Golden Model | 376 x 264", Image.fromarray(references["crop_x1"])),
            ("RTL capturado | 376 x 264", sample("crop_x1")),
            ("Diferencas | preto: igual", diff.copy()),
        ], 3)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("image", type=Path, help="foto original de estacionamento usada no M11")
    args = parser.parse_args()
    repo = Path(__file__).resolve().parents[2]
    runs = repo / "outputs/m11"
    runs.mkdir(parents=True, exist_ok=True)
    with Image.open(args.image) as photo:
        source = ImageOps.exif_transpose(photo).convert("RGB")
    prepared = fit_for_model(source, 1024)
    if prepared.size != (576, 1024):
        parser.error("as coordenadas da demonstração exigem a foto em 576 x 1024 após preparação")
    out = Path(mkdtemp(prefix="visual-detail-", dir=runs))
    print(f"Execução visual em {out}", flush=True)
    prepared.save(out / "entrada_rgb.png")
    rgb = np.asarray(prepared)
    configs = configurations()
    references = {name: process_frame(rgb, cfg).image for name, cfg in configs.items()}
    (out / "golden").mkdir()
    golden_summary = {}
    for name, values in references.items():
        Image.fromarray(values).save(out / "golden" / f"{name}.png")
        golden_summary[name] = {"width": values.shape[1], "height": values.shape[0],
                                "white_pixels": int(np.count_nonzero(values == 255))}
    results = run_rtl(repo, out, rgb, configs, references)
    galleries(out, prepared, references, results)
    summary = {"source_sha256": hashlib.sha256(args.image.read_bytes()).hexdigest(),
               "original_size": source.size, "prepared_size": prepared.size, "crop": ROI, "detail": DETAIL,
               "golden": golden_summary, "rtl": results}
    (out / "summary.json").write_text(json.dumps(summary, indent=2) + "\n")
    print(f"Comparativos completos em {out}", flush=True)


if __name__ == "__main__":
    main()
