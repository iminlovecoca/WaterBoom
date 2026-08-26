from __future__ import annotations

import json
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont, ImageStat


ROOT = Path(__file__).resolve().parents[1]
CAPTURE_DIR = ROOT / "tests/artifacts/tileset_validation"
OUTPUT = CAPTURE_DIR / "MAP_STANDARDIZATION_COMPARISON.png"
METRICS = CAPTURE_DIR / "map_standardization_metrics.json"

MAPS = (
    ("training_plaza", "PLANNING PLAZA"),
    ("lego_city", "LEGO CITY"),
    ("egypt_temple", "EGYPT TEMPLE"),
    ("aqua_park", "AQUA PARK"),
    ("pirate_harbor", "PIRATE HARBOR"),
    ("snow_village", "SNOW VILLAGE"),
)


def _font(size: int) -> ImageFont.ImageFont:
    candidates = (
        Path("C:/Windows/Fonts/arialbd.ttf"),
        Path("C:/Windows/Fonts/segoeuib.ttf"),
    )
    for candidate in candidates:
        if candidate.exists():
            return ImageFont.truetype(str(candidate), size)
    return ImageFont.load_default()


def _arena_crop(image: Image.Image) -> Image.Image:
    # MatchFrameUI at the capture fixture's fixed 1280x720 viewport:
    # 16 cells x 40px, centered in the left arena panel.
    if image.width <= 1000:
        return image.crop((18, 0, 18 + 720, 720))
    left = 215
    return image.crop((left, 40, left + 640, 40 + 640))


def _visual_metrics(image: Image.Image) -> dict[str, float]:
    arena = _arena_crop(image).convert("RGB")
    red, green, blue = ImageStat.Stat(arena).mean
    brightness = (0.2126 * red + 0.7152 * green + 0.0722 * blue) / 255.0 * 100.0
    saturation = ImageStat.Stat(arena.convert("HSV").getchannel("S")).mean[0] / 255.0 * 100.0
    return {"brightness_percent": round(brightness, 1), "saturation_percent": round(saturation, 1)}


def main() -> None:
    tile_size = (960, 540)
    header_height = 52
    margin = 18
    canvas = Image.new(
        "RGB",
        (tile_size[0] * 3 + margin * 4, (tile_size[1] + header_height) * 2 + margin * 3),
        "#071525",
    )
    draw = ImageDraw.Draw(canvas)
    title_font = _font(27)
    metrics: dict[str, dict[str, float | int | str]] = {}

    for index, (map_id, title) in enumerate(MAPS):
        source = CAPTURE_DIR / f"map_{map_id}.png"
        if not source.exists():
            raise FileNotFoundError(source)
        capture = Image.open(source).convert("RGB")
        capture.thumbnail(tile_size, Image.Resampling.LANCZOS)
        column = index % 3
        row = index // 3
        x = margin + column * tile_size[0] + column * margin
        y = margin + row * (tile_size[1] + header_height) + row * margin
        draw.rounded_rectangle(
            (x - 3, y - 3, x + tile_size[0] + 3, y + header_height + tile_size[1] + 3),
            radius=12,
            fill="#0b2844",
            outline="#4ad5ff",
            width=3,
        )
        label = f"{title}  |  FULL 16x16  |  160 BREAKABLES  |  L SPAWNS"
        draw.text((x + 18, y + 10), label, font=title_font, fill="#f2fbff")
        canvas.paste(capture, (x, y + header_height))
        metrics[map_id] = {
            "style": "V2",
            "grid": "16x16",
            "cell_px": 40,
            "breakables": 160,
            "center_footprint": "4x4 hard/soft blocks",
            **_visual_metrics(Image.open(source)),
        }

    canvas.save(OUTPUT, optimize=True)
    METRICS.write_text(json.dumps(metrics, indent=2), encoding="utf-8")
    print(f"Wrote {OUTPUT}")
    print(f"Wrote {METRICS}")


if __name__ == "__main__":
    main()
