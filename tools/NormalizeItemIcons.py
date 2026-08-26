"""Normalize user-supplied item art into the game's 96x96 icon contract.

The original source files are copied beside the runtime outputs so future art
passes can be regenerated without repeatedly scaling an already-small icon.
"""

from __future__ import annotations

import shutil
from pathlib import Path

from PIL import Image


PROJECT = Path(__file__).resolve().parents[1]
OUTPUT_DIR = PROJECT / "assets" / "items"
SOURCE_DIR = OUTPUT_DIR / "source_user_2026_08_24"
CANVAS = 96
CONTENT = 84

SOURCES = {
    "item_bubble_pin.png": Path(
        r"C:\Users\khang\.codex\generated_images\01a008e1-1d38-7ac1-8026-462b54989736\exec-05e441df-811a-4f87-b0ae-99fe053bcbd2.png"
    ),
    "item_water_balloon_up.png": Path(
        r"C:\Users\khang\.codex\generated_images\01a008e1-1d38-7ac1-8026-462b54989736\exec-b9cfadb2-719c-4c78-8671-1f40b489bcb1.png"
    ),
    "item_shield.png": Path(r"C:\Users\khang\Downloads\Khiên ngôi sao nước lấp lánh.png"),
    "item_speed_up.png": Path(r"C:\Users\khang\Downloads\Codex Image Aug 24, 2026, 10_59_53 PM.png"),
    "item_water_power_up.png": Path(r"C:\Users\khang\Downloads\Codex Image Aug 24, 2026, 10_59_47 PM.png"),
}


def normalize(source: Path, destination: Path) -> None:
    image = Image.open(source).convert("RGBA")
    alpha_box = image.getchannel("A").getbbox()
    if alpha_box is None:
        raise RuntimeError(f"Source has no visible pixels: {source}")
    image = image.crop(alpha_box)
    scale = min(CONTENT / image.width, CONTENT / image.height)
    target = (
        max(1, round(image.width * scale)),
        max(1, round(image.height * scale)),
    )
    image = image.resize(target, Image.Resampling.LANCZOS)
    canvas = Image.new("RGBA", (CANVAS, CANVAS), (0, 0, 0, 0))
    offset = ((CANVAS - target[0]) // 2, (CANVAS - target[1]) // 2)
    canvas.alpha_composite(image, offset)
    canvas.save(destination, optimize=True)


def main() -> None:
    SOURCE_DIR.mkdir(parents=True, exist_ok=True)
    for runtime_name, source in SOURCES.items():
        if not source.exists():
            raise FileNotFoundError(source)
        shutil.copy2(source, SOURCE_DIR / runtime_name)
        normalize(source, OUTPUT_DIR / runtime_name)
        print(f"normalized {runtime_name}")


if __name__ == "__main__":
    main()
