"""Build a composite sheet for visual QA of active water-balloon sprites.

The sheet intentionally composites the runtime RGBA sprites onto a dark blue
game-like matte and a light checkerboard. It is a diagnostic artifact only.
"""

from __future__ import annotations

from pathlib import Path
from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parents[1]
SKINS = ROOT / "assets" / "water_balloons" / "skins"
OUT = ROOT / "tests" / "artifacts" / "water_balloon_alpha_qa.png"


def checker(size: tuple[int, int], cell: int = 12) -> Image.Image:
    image = Image.new("RGBA", size, (238, 238, 238, 255))
    draw = ImageDraw.Draw(image)
    for y in range(0, size[1], cell):
        for x in range(0, size[0], cell):
            if ((x // cell) + (y // cell)) % 2:
                draw.rectangle((x, y, x + cell - 1, y + cell - 1), fill=(210, 210, 210, 255))
    return image


def main() -> None:
    ids = [f"skin_{index:03d}" for index in range(66, 82)]
    card_w, card_h = 168, 190
    cols = 4
    rows = (len(ids) + cols - 1) // cols
    sheet = Image.new("RGBA", (cols * card_w, rows * card_h), (5, 32, 61, 255))
    font = ImageFont.load_default()

    for i, skin_id in enumerate(ids):
        icon_path = SKINS / skin_id / "icon.png"
        icon = Image.open(icon_path).convert("RGBA").resize((112, 112), Image.Resampling.NEAREST)
        card = Image.new("RGBA", (card_w, card_h), (11, 52, 91, 255))
        card.alpha_composite(checker((card_w, card_h)), (0, 0))
        blue = Image.new("RGBA", (card_w, card_h), (11, 52, 91, 255))
        card.alpha_composite(blue, (0, 0))
        card.alpha_composite(icon, ((card_w - icon.width) // 2, 10))
        draw = ImageDraw.Draw(card)
        draw.text((8, 132), skin_id, font=font, fill=(255, 255, 255, 255))
        cell = sheet.crop((0, 0, card_w, card_h))
        x, y = (i % cols) * card_w, (i // cols) * card_h
        sheet.alpha_composite(card, (x, y))

    OUT.parent.mkdir(parents=True, exist_ok=True)
    sheet.convert("RGB").save(OUT, format="PNG", optimize=True)
    print(OUT)


if __name__ == "__main__":
    main()
