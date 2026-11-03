"""Modelo funcional por quadro, independente da microarquitetura RTL.

As imagens de entrada são arrays NumPy uint8 de formato (altura, largura, 3),
em ordem RGB. Uma configuração inválida gera ConfigError antes de qualquer
resultado; sinais ciclo a ciclo e reset pertencem à futura verificação de RTL.
"""

from dataclasses import dataclass
from typing import Iterator

import numpy as np

MAX_DIMENSION = 2047


class ConfigError(ValueError):
    """Configuração não suportada pela V1."""


@dataclass(frozen=True)
class Config:
    in_width: int
    in_height: int
    crop_enable: bool = False
    x_start: int = 0
    y_start: int = 0
    crop_width: int = 0
    crop_height: int = 0
    resize_x2: bool = False
    resize_y2: bool = False
    threshold_enable: bool = False
    threshold: int = 0


@dataclass(frozen=True)
class Pixel:
    value: int
    sof: bool
    sol: bool
    eol: bool
    eof: bool


@dataclass(frozen=True)
class Result:
    image: np.ndarray
    width: int
    height: int

    @property
    def pixels(self) -> Iterator[Pixel]:
        """Itera em ordem raster sem duplicar todos os objetos de pixel."""
        for oy in range(self.height):
            for ox in range(self.width):
                yield Pixel(int(self.image[oy, ox]), oy == 0 and ox == 0,
                            ox == 0, ox == self.width - 1,
                            oy == self.height - 1 and ox == self.width - 1)


def _integer(name: str, value: int, low: int, high: int) -> None:
    if isinstance(value, bool) or not isinstance(value, (int, np.integer)) or not low <= value <= high:
        raise ConfigError(f"{name} deve ser inteiro em [{low}, {high}]")


def _bit(name: str, value: bool) -> None:
    if not isinstance(value, (bool, int, np.integer)) or value not in (0, 1):
        raise ConfigError(f"{name} deve ser 0 ou 1")


def validate_config(config: Config) -> tuple[int, int, int, int, int, int]:
    """Valida e retorna x, y, largura/altura da ROI e dimensões de saída."""
    _integer("in_width", config.in_width, 1, MAX_DIMENSION)
    _integer("in_height", config.in_height, 1, MAX_DIMENSION)
    for name in ("crop_enable", "resize_x2", "resize_y2", "threshold_enable"):
        _bit(name, getattr(config, name))
    _integer("threshold", config.threshold, 0, 255)
    if config.crop_enable:
        _integer("x_start", config.x_start, 0, MAX_DIMENSION)
        _integer("y_start", config.y_start, 0, MAX_DIMENSION)
        _integer("crop_width", config.crop_width, 1, MAX_DIMENSION)
        _integer("crop_height", config.crop_height, 1, MAX_DIMENSION)
        x, y, width, height = config.x_start, config.y_start, config.crop_width, config.crop_height
        if x + width > config.in_width or y + height > config.in_height:
            raise ConfigError("ROI fora da imagem de entrada")
    else:
        # O contrato ignora os campos de ROI no bypass.
        x, y, width, height = 0, 0, config.in_width, config.in_height
    out_width = width // (2 if config.resize_x2 else 1)
    out_height = height // (2 if config.resize_y2 else 1)
    if out_width == 0 or out_height == 0:
        raise ConfigError("dimensão de saída zero")
    return int(x), int(y), int(width), int(height), int(out_width), int(out_height)


def process_frame(rgb: np.ndarray, config: Config) -> Result:
    """Produz pixels e marcadores esperados para um quadro válido.

    ConfigError representa rejeição da configuração. A exceção não simula o
    pulso cfg_error; ValueError indica imagem incompatível com a interface.
    """
    x, y, width, height, out_width, out_height = validate_config(config)
    if not isinstance(rgb, np.ndarray) or rgb.dtype != np.uint8:
        raise ValueError("imagem deve ser array NumPy de dtype uint8")
    if rgb.shape != (config.in_height, config.in_width, 3):
        raise ValueError("formato RGB deve ser (in_height, in_width, 3)")

    # uint32 garante soma e produtos sem overflow, inclusive antes do shift.
    wide = rgb.astype(np.uint32)
    gray = ((77 * wide[:, :, 0] + 150 * wide[:, :, 1] + 29 * wide[:, :, 2]) // 256).astype(np.uint8)
    roi = gray[y:y + height, x:x + width]
    # Implementar a definição geral do PDF, não a otimização par do RTL.
    xs = np.arange(out_width, dtype=np.int64) * width // out_width
    ys = np.arange(out_height, dtype=np.int64) * height // out_height
    output = roi[np.ix_(ys, xs)].copy()
    if config.threshold_enable:
        output = np.where(output >= config.threshold, 255, 0).astype(np.uint8)

    return Result(output, out_width, out_height)
