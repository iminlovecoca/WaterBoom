from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageOps


ROOT = Path(__file__).resolve().parents[1]


def transparent_subject(path: Path) -> Image.Image:
    image = Image.open(path).convert("RGBA")
    # Generated transparent PNGs can retain an opaque black RGB fringe. Alpha
    # is authoritative; crop strictly to it and keep the transparent pixels.
    bbox = image.getchannel("A").getbbox()
    return image.crop(bbox) if bbox else image


def build_mast() -> None:
    source = transparent_subject(ROOT / "assets/boss_arena/source/pirate_mast_master.png")
    fitted = ImageOps.contain(source, (150, 150), Image.Resampling.LANCZOS)
    canvas = Image.new("RGBA", (160, 160), (0, 0, 0, 0))
    shadow_mask = fitted.getchannel("A").filter(ImageFilter.GaussianBlur(5))
    shadow = Image.new("RGBA", fitted.size, (3, 8, 20, 0))
    shadow.putalpha(shadow_mask.point(lambda a: int(a * 0.38)))
    x = (160 - fitted.width) // 2
    y = 156 - fitted.height
    canvas.alpha_composite(shadow, (x + 5, y + 7))
    canvas.alpha_composite(fitted, (x, y))
    out = ROOT / "assets/boss_arena/runtime"
    out.mkdir(parents=True, exist_ok=True)
    canvas.save(out / "pirate_mast.png", optimize=True)


def build_pin() -> None:
    source = transparent_subject(ROOT / "assets/items/source/item_bubble_pin_master.png")
    fitted = ImageOps.contain(source, (34, 34), Image.Resampling.LANCZOS)
    canvas = Image.new("RGBA", (40, 40), (0, 0, 0, 0))
    canvas.alpha_composite(fitted, ((40 - fitted.width) // 2, (40 - fitted.height) // 2))
    canvas.save(ROOT / "assets/items/item_bubble_pin.png", optimize=True)


if __name__ == "__main__":
    build_mast()
    build_pin()
    print("Built pirate mast and bubble pin runtime assets")
