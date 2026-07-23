from __future__ import annotations

from pathlib import Path
import math

import numpy as np
from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parents[1]
FIG1_DIR = ROOT / "图片" / "图2-1_不同ARMA模型的模拟序列"
FIG2_DIR = ROOT / "图片" / "图2-2_ACF与PACF模式"
FIG1_DIR.mkdir(parents=True, exist_ok=True)
FIG2_DIR.mkdir(parents=True, exist_ok=True)


def load_font(size: int, bold: bool = False) -> ImageFont.FreeTypeFont:
    candidates = [
        Path("C:/Windows/Fonts/msyhbd.ttc" if bold else "C:/Windows/Fonts/msyh.ttc"),
        Path("C:/Windows/Fonts/simhei.ttf"),
        Path("C:/Windows/Fonts/arial.ttf"),
    ]
    for path in candidates:
        if path.exists():
            return ImageFont.truetype(str(path), size=size)
    return ImageFont.load_default()


FONT_TITLE = load_font(30, bold=True)
FONT_SUBTITLE = load_font(22, bold=True)
FONT_AXIS = load_font(18)
FONT_SMALL = load_font(16)


MODELS = [
    {
        "label": "AR(1): y[t] = 0.7 y[t-1] + e[t]",
        "ar": [0.7],
        "ma": [],
    },
    {
        "label": "AR(1): y[t] = -0.7 y[t-1] + e[t]",
        "ar": [-0.7],
        "ma": [],
    },
    {
        "label": "MA(1): y[t] = e[t] - 0.7 e[t-1]",
        "ar": [],
        "ma": [-0.7],
    },
    {
        "label": "AR(2): y[t] = 0.7 y[t-1] - 0.49 y[t-2] + e[t]",
        "ar": [0.7, -0.49],
        "ma": [],
    },
    {
        "label": "ARMA(1,1): y[t] = -0.7 y[t-1] + e[t] - 0.7 e[t-1]",
        "ar": [-0.7],
        "ma": [-0.7],
    },
]


def simulate_arma(ar: list[float], ma: list[float], n: int = 500, burn: int = 300) -> np.ndarray:
    max_lag = max(len(ar), len(ma), 1)
    eps = np.random.normal(size=n + burn + max_lag + 1)
    y = np.zeros(n + burn + max_lag + 1)
    for t in range(max_lag, len(y)):
        ar_part = sum(phi * y[t - i - 1] for i, phi in enumerate(ar))
        ma_part = eps[t] + sum(theta * eps[t - j - 1] for j, theta in enumerate(ma))
        y[t] = ar_part + ma_part
    return y[-n:]


def acf_values(x: np.ndarray, max_lag: int) -> np.ndarray:
    z = x - np.mean(x)
    denom = float(np.sum(z * z))
    return np.array([np.sum(z[k:] * z[:-k]) / denom if k else 1.0 for k in range(max_lag + 1)])


def pacf_values(x: np.ndarray, max_lag: int) -> np.ndarray:
    acf = acf_values(x, max_lag)
    pacf = np.zeros(max_lag + 1)
    pacf[0] = 1.0
    for k in range(1, max_lag + 1):
        toeplitz = np.fromfunction(lambda i, j: acf[np.abs(i - j).astype(int)], (k, k))
        rhs = acf[1 : k + 1]
        try:
            coeff = np.linalg.solve(toeplitz, rhs)
            pacf[k] = coeff[-1]
        except np.linalg.LinAlgError:
            pacf[k] = np.nan
    return pacf


def draw_text_center(draw: ImageDraw.ImageDraw, xy: tuple[int, int], text: str, font, fill=(20, 20, 20)):
    bbox = draw.textbbox((0, 0), text, font=font)
    x = xy[0] - (bbox[2] - bbox[0]) // 2
    y = xy[1] - (bbox[3] - bbox[1]) // 2
    draw.text((x, y), text, font=font, fill=fill)


def draw_line_panel(draw: ImageDraw.ImageDraw, box: tuple[int, int, int, int], data: np.ndarray, title: str):
    x0, y0, x1, y1 = box
    pad_l, pad_r, pad_t, pad_b = 56, 18, 42, 34
    px0, py0, px1, py1 = x0 + pad_l, y0 + pad_t, x1 - pad_r, y1 - pad_b
    draw.rectangle((x0, y0, x1, y1), fill=(255, 255, 255), outline=(215, 215, 215), width=1)
    draw_text_center(draw, ((x0 + x1) // 2, y0 + 20), title, FONT_SUBTITLE)
    y_min = float(np.percentile(data, 1))
    y_max = float(np.percentile(data, 99))
    bound = max(abs(y_min), abs(y_max), 1.0)
    y_min, y_max = -bound, bound
    y_zero = py1 - (0 - y_min) / (y_max - y_min) * (py1 - py0)
    draw.line((px0, y_zero, px1, y_zero), fill=(185, 185, 185), width=1)
    draw.line((px0, py0, px0, py1), fill=(80, 80, 80), width=1)
    draw.line((px0, py1, px1, py1), fill=(80, 80, 80), width=1)
    points = []
    for i, val in enumerate(data):
        x = px0 + i / (len(data) - 1) * (px1 - px0)
        y = py1 - (val - y_min) / (y_max - y_min) * (py1 - py0)
        points.append((x, y))
    draw.line(points, fill=(31, 78, 121), width=2)
    draw.text((x0 + 8, py0 - 8), f"{y_max:.1f}", font=FONT_SMALL, fill=(80, 80, 80))
    draw.text((x0 + 8, py1 - 14), f"{y_min:.1f}", font=FONT_SMALL, fill=(80, 80, 80))


def draw_bar_panel(draw: ImageDraw.ImageDraw, box: tuple[int, int, int, int], values: np.ndarray, title: str, max_lag: int):
    x0, y0, x1, y1 = box
    pad_l, pad_r, pad_t, pad_b = 54, 16, 42, 32
    px0, py0, px1, py1 = x0 + pad_l, y0 + pad_t, x1 - pad_r, y1 - pad_b
    draw.rectangle((x0, y0, x1, y1), fill=(255, 255, 255), outline=(215, 215, 215), width=1)
    draw_text_center(draw, ((x0 + x1) // 2, y0 + 20), title, FONT_SUBTITLE)
    draw.line((px0, py0, px0, py1), fill=(80, 80, 80), width=1)
    draw.line((px0, py1, px1, py1), fill=(80, 80, 80), width=1)
    zero_y = py0 + (py1 - py0) / 2
    draw.line((px0, zero_y, px1, zero_y), fill=(95, 95, 95), width=2)
    conf = 1.96 / math.sqrt(500)
    for c in (conf, -conf):
        y = zero_y - c / 2 * (py1 - py0)
        draw.line((px0, y, px1, y), fill=(160, 160, 160), width=1)
    draw.text((x0 + 10, py0 - 8), "1", font=FONT_SMALL, fill=(80, 80, 80))
    draw.text((x0 + 7, zero_y - 10), "0", font=FONT_SMALL, fill=(80, 80, 80))
    draw.text((x0 + 4, py1 - 14), "-1", font=FONT_SMALL, fill=(80, 80, 80))
    lags = np.arange(1, max_lag + 1)
    panel_w = px1 - px0
    step = panel_w / max_lag
    bar_w = max(6, int(step * 0.55))
    for lag in lags:
        val = float(values[lag])
        x = px0 + (lag - 0.5) * step
        y = zero_y - val / 2 * (py1 - py0)
        top, bottom = sorted([zero_y, y])
        draw.rectangle((x - bar_w / 2, top, x + bar_w / 2, bottom), fill=(55, 55, 55))
        if lag in (1, 4, 8, 12, 16):
            draw_text_center(draw, (int(x), py1 + 14), str(lag), FONT_SMALL, fill=(80, 80, 80))


def main() -> None:
    np.random.seed(20260723)
    series = [simulate_arma(m["ar"], m["ma"]) for m in MODELS]
    max_lag = 16

    fig1 = Image.new("RGB", (1800, 1500), (248, 248, 248))
    draw1 = ImageDraw.Draw(fig1)
    draw_text_center(draw1, (900, 36), "图2-1  不同 AR、MA 与 ARMA 模型的模拟序列", FONT_TITLE)
    top = 78
    h = 270
    for i, (m, x) in enumerate(zip(MODELS, series)):
        draw_line_panel(draw1, (70, top + i * h, 1730, top + i * h + 235), x, m["label"])
    fig1.save(FIG1_DIR / "图2-1_不同ARMA模型的模拟序列.png", quality=95)

    fig2 = Image.new("RGB", (1800, 2400), (248, 248, 248))
    draw2 = ImageDraw.Draw(fig2)
    draw_text_center(draw2, (900, 36), "图2-2  不同 AR、MA 与 ARMA 模型的样本 ACF 和 PACF", FONT_TITLE)
    top = 78
    row_h = 450
    for i, (m, x) in enumerate(zip(MODELS, series)):
        acf = acf_values(x, max_lag)
        pacf = pacf_values(x, max_lag)
        y = top + i * row_h
        draw_bar_panel(draw2, (70, y, 875, y + 400), acf, "ACF: " + m["label"], max_lag)
        draw_bar_panel(draw2, (925, y, 1730, y + 400), pacf, "PACF: " + m["label"], max_lag)
    fig2.save(FIG2_DIR / "图2-2_不同ARMA模型的样本ACF与PACF.png", quality=95)


if __name__ == "__main__":
    main()

