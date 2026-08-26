"""Regenerate water stream burst pieces — smooth, connected, glossy 2.5D water.

Key fixes vs v1:
- Rounded edges on all pieces so they blend seamlessly at tile boundaries
- Proper overlap zones so horizontal + vertical tiles connect without gaps
- Center piece is a full cross, not two crossing rectangles
- End caps have rounded bulb tips
- Gloss layer + specular highlight for water feel
"""

from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets" / "water_stream"
SIZE = 40

# ── colour palette ────────────────────────────────────────────────────
DEEP   = (8, 90, 210, 240)      # dark water core
FILL   = (40, 180, 255, 230)    # main water body
RIM    = (180, 240, 255, 255)   # bright rim / specular
GLOSS  = (255, 255, 255, 200)   # top specular highlight
SHADOW = (0, 50, 140, 160)      # shadow under water


def _new() -> Image.Image:
    return Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))


def _rounded_rect(draw: ImageDraw.ImageDraw, bbox, radius, **kw):
    """Draw a rounded rectangle."""
    draw.rounded_rectangle(bbox, radius=radius, **kw)


def _gloss_band(img: Image.Image, bbox, direction="h"):
    """Add a soft specular band across the water surface."""
    overlay = _new()
    od = ImageDraw.Draw(overlay, "RGBA")
    if direction == "h":
        # horizontal highlight band in upper third
        y0, y1 = bbox[1] + 3, bbox[1] + (bbox[3] - bbox[1]) // 3
        od.rounded_rectangle((bbox[0] + 2, y0, bbox[2] - 2, y1), radius=3, fill=GLOSS)
    else:
        x0, x1 = bbox[0] + 3, bbox[0] + (bbox[2] - bbox[0]) // 3
        od.rounded_rectangle((x0, bbox[1] + 2, x1, bbox[3] - 2), radius=3, fill=GLOSS)
    blurred = overlay.filter(ImageFilter.GaussianBlur(2))
    img.alpha_composite(blurred)


def _specular_dots(draw: ImageDraw.ImageDraw, cx, cy, count=3):
    """Small bright dots for wet specular feel."""
    import random
    rng = random.Random(cx * 100 + cy)
    for _ in range(count):
        dx = rng.randint(-6, 6)
        dy = rng.randint(-4, 4)
        r = rng.randint(1, 2)
        draw.ellipse((cx + dx - r, cy + dy - r, cx + dx + r, cy + dy + r), fill=GLOSS)


# ── piece builders ────────────────────────────────────────────────────

def build_horizontal() -> Image.Image:
    """Full-width horizontal water bar (36px tall, spans 0..39)."""
    img = _new()
    glow = _new()
    gd = ImageDraw.Draw(glow, "RGBA")
    # glow underlayer
    gd.rounded_rectangle((0, 3, 39, 36), radius=8, fill=(0, 140, 255, 100))
    img.alpha_composite(glow.filter(ImageFilter.GaussianBlur(4)))

    draw = ImageDraw.Draw(img, "RGBA")
    # shadow
    draw.rounded_rectangle((0, 6, 39, 36), radius=8, fill=SHADOW)
    # deep layer
    draw.rounded_rectangle((0, 4, 39, 34), radius=8, fill=DEEP)
    # fill
    draw.rounded_rectangle((0, 6, 39, 32), radius=7, fill=FILL)
    # top rim
    draw.line((4, 4, 35, 4), fill=RIM, width=2)
    # bottom shadow line
    draw.line((4, 33, 35, 33), fill=(0, 80, 200, 200), width=1)
    # gloss
    _gloss_band(img, (0, 4, 39, 34), "h")
    # specular dots
    _specular_dots(draw, 12, 14, 2)
    _specular_dots(draw, 28, 12, 2)
    return img


def build_vertical() -> Image.Image:
    """Full-height vertical water bar (36px wide, spans 0..39)."""
    img = _new()
    glow = _new()
    gd = ImageDraw.Draw(glow, "RGBA")
    gd.rounded_rectangle((3, 0, 36, 39), radius=8, fill=(0, 140, 255, 100))
    img.alpha_composite(glow.filter(ImageFilter.GaussianBlur(4)))

    draw = ImageDraw.Draw(img, "RGBA")
    draw.rounded_rectangle((6, 0, 36, 39), radius=8, fill=SHADOW)
    draw.rounded_rectangle((4, 0, 34, 39), radius=8, fill=DEEP)
    draw.rounded_rectangle((6, 0, 32, 39), radius=7, fill=FILL)
    draw.line((4, 4, 4, 35), fill=RIM, width=2)
    draw.line((33, 4, 33, 35), fill=(0, 80, 200, 200), width=1)
    _gloss_band(img, (4, 0, 34, 39), "v")
    _specular_dots(draw, 14, 12, 2)
    _specular_dots(draw, 12, 28, 2)
    return img


def build_center() -> Image.Image:
    """Full cross — water fills all four arms at the intersection."""
    img = _new()
    glow = _new()
    gd = ImageDraw.Draw(glow, "RGBA")
    # horizontal arm glow
    gd.rounded_rectangle((0, 3, 39, 36), radius=8, fill=(0, 140, 255, 100))
    # vertical arm glow
    gd.rounded_rectangle((3, 0, 36, 39), radius=8, fill=(0, 140, 255, 100))
    img.alpha_composite(glow.filter(ImageFilter.GaussianBlur(4)))

    draw = ImageDraw.Draw(img, "RGBA")
    # shadows
    draw.rounded_rectangle((0, 6, 39, 36), radius=8, fill=SHADOW)
    draw.rounded_rectangle((6, 0, 36, 39), radius=8, fill=SHADOW)
    # deep
    draw.rounded_rectangle((0, 4, 39, 34), radius=8, fill=DEEP)
    draw.rounded_rectangle((4, 0, 34, 39), radius=8, fill=DEEP)
    # fill
    draw.rounded_rectangle((0, 6, 39, 32), radius=7, fill=FILL)
    draw.rounded_rectangle((6, 0, 32, 39), radius=7, fill=FILL)
    # center circle overlay for smooth intersection
    draw.ellipse((6, 6, 33, 33), fill=FILL, outline=RIM, width=1)
    # rim highlights
    draw.line((4, 4, 35, 4), fill=RIM, width=2)
    draw.line((4, 4, 4, 35), fill=RIM, width=2)
    draw.line((4, 33, 35, 33), fill=(0, 80, 200, 200), width=1)
    draw.line((33, 4, 33, 35), fill=(0, 80, 200, 200), width=1)
    # gloss
    _gloss_band(img, (0, 4, 39, 34), "h")
    _specular_dots(draw, 14, 14, 3)
    _specular_dots(draw, 26, 14, 2)
    _specular_dots(draw, 14, 26, 2)
    return img


def build_end_left() -> Image.Image:
    """Horizontal bar with rounded cap on the left end, flush right edge."""
    img = build_horizontal()
    draw = ImageDraw.Draw(img, "RGBA")
    # erase right edge (will join with next tile)
    draw.rectangle((36, 4, 39, 34), fill=(0, 0, 0, 0))
    # redraw clean right edge
    draw.line((36, 4, 36, 34), fill=DEEP, width=2)
    # rounded cap on left
    draw.ellipse((0, 4, 18, 34), fill=DEEP, outline=RIM, width=2)
    draw.ellipse((2, 6, 17, 32), fill=FILL)
    _gloss_band(img, (0, 4, 18, 34), "h")
    _specular_dots(draw, 8, 14, 2)
    return img


def build_end_right() -> Image.Image:
    """Horizontal bar with rounded cap on the right end, flush left edge."""
    img = build_horizontal()
    draw = ImageDraw.Draw(img, "RGBA")
    # erase left edge
    draw.rectangle((0, 4, 3, 34), fill=(0, 0, 0, 0))
    draw.line((3, 4, 3, 34), fill=DEEP, width=2)
    # rounded cap on right
    draw.ellipse((21, 4, 39, 34), fill=DEEP, outline=RIM, width=2)
    draw.ellipse((22, 6, 37, 32), fill=FILL)
    _gloss_band(img, (21, 4, 39, 34), "h")
    _specular_dots(draw, 31, 14, 2)
    return img


def build_end_up() -> Image.Image:
    """Vertical bar with rounded cap on top, flush bottom edge."""
    img = build_vertical()
    draw = ImageDraw.Draw(img, "RGBA")
    # erase bottom edge
    draw.rectangle((4, 36, 34, 39), fill=(0, 0, 0, 0))
    draw.line((4, 36, 34, 36), fill=DEEP, width=2)
    # rounded cap on top
    draw.ellipse((4, 0, 34, 18), fill=DEEP, outline=RIM, width=2)
    draw.ellipse((6, 2, 32, 17), fill=FILL)
    _gloss_band(img, (4, 0, 34, 18), "v")
    _specular_dots(draw, 14, 8, 2)
    return img


def build_end_down() -> Image.Image:
    """Vertical bar with rounded cap on bottom, flush top edge."""
    img = build_vertical()
    draw = ImageDraw.Draw(img, "RGBA")
    # erase top edge
    draw.rectangle((4, 0, 34, 3), fill=(0, 0, 0, 0))
    draw.line((4, 3, 34, 3), fill=DEEP, width=2)
    # rounded cap on bottom
    draw.ellipse((4, 21, 34, 39), fill=DEEP, outline=RIM, width=2)
    draw.ellipse((6, 22, 32, 37), fill=FILL)
    _gloss_band(img, (4, 21, 34, 39), "v")
    _specular_dots(draw, 14, 31, 2)
    return img


def build_cross() -> Image.Image:
    """Overlay piece for when horizontal + vertical overlap at same cell."""
    img = _new()
    draw = ImageDraw.Draw(img, "RGBA")
    # soft glow ring
    draw.ellipse((2, 2, 37, 37), fill=(40, 180, 255, 80))
    blurred = img.filter(ImageFilter.GaussianBlur(3))
    img = blurred
    draw = ImageDraw.Draw(img, "RGBA")
    # concentric rings
    draw.ellipse((4, 4, 35, 35), fill=FILL, outline=RIM, width=2)
    draw.ellipse((8, 8, 31, 31), fill=(60, 200, 255, 200), outline=RIM, width=1)
    # center bright spot
    draw.ellipse((14, 14, 25, 25), fill=(100, 220, 255, 180))
    _specular_dots(draw, 16, 14, 2)
    _specular_dots(draw, 24, 20, 1)
    return img


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    pieces = {
        "center":    build_center,
        "horizontal": build_horizontal,
        "vertical":  build_vertical,
        "end_left":  build_end_left,
        "end_right": build_end_right,
        "end_up":    build_end_up,
        "end_down":  build_end_down,
        "cross":     build_cross,
    }
    for name, fn in pieces.items():
        img = fn()
        img.save(OUT / f"water_{name}.png", optimize=True)
        print(f"  water_{name}.png  {img.size}")
    print(f"\nBuilt {len(pieces)} smooth 2.5D water burst pieces → {OUT}")


if __name__ == "__main__":
    main()
