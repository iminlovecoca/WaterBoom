"""Build a blue-background before/after board for the conservative despill pass."""

from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[1]
BEFORE = ROOT / "tests" / "artifacts" / "water_balloon_before_despill"
AFTER = ROOT / "assets" / "water_balloons" / "skins"
OUT = ROOT / "tests" / "artifacts" / "water_balloon_despill_before_after.png"
TARGETS = ["skin_078", "skin_079", "skin_080", "skin_081"]
LABELS = {
    "skin_078": "Prism Pearl",
    "skin_079": "Jellyfish Bubble",
    "skin_080": "Bubble Star",
    "skin_081": "Cloud Pearl",
}


def board() -> Image.Image:
    card_w, card_h = 220, 210
    pad = 16
    width = pad + len(TARGETS) * (card_w + pad)
    height = pad + 2 * (card_h + pad)
    image = Image.new("RGBA", (width, height), (8, 52, 91, 255))
    draw = ImageDraw.Draw(image)
    for row, base in enumerate([BEFORE, AFTER]):
        for col, skin_id in enumerate(TARGETS):
            x = pad + col * (card_w + pad)
            y = pad + row * (card_h + pad)
            draw.rounded_rectangle((x, y, x + card_w, y + card_h), radius=12, fill=(13, 67, 111), outline=(30, 125, 191), width=3)
            sprite = Image.open(base / skin_id / "idle_0.png").convert("RGBA")
            sprite.thumbnail((150, 150), Image.Resampling.LANCZOS)
            sx = x + (card_w - sprite.width) // 2
            sy = y + 12
            image.alpha_composite(sprite, (sx, sy))
            label = ("BEFORE  " if row == 0 else "AFTER   ") + LABELS[skin_id]
            draw.text((x + 10, y + card_h - 28), label, fill=(235, 248, 255, 255))
    return image


def main() -> None:
    OUT.parent.mkdir(parents=True, exist_ok=True)
    board().save(OUT, format="PNG", optimize=True)
    print(OUT)


if __name__ == "__main__":
    main()
