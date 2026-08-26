"""Remove only residual magenta matte pixels from final balloon PNGs.

The generated source sheets use magenta as a temporary chroma-key color.  The
runtime PNGs are already RGBA; this pass intentionally touches only nearly
transparent pixels that still carry the matte color.  Opaque interior pixels
(including the lavender glass tint) are left untouched.
"""

from pathlib import Path
from PIL import Image


ROOT = Path(__file__).resolve().parents[1] / "assets" / "water_balloons" / "skins"
IDS = [f"skin_{index:03d}" for index in range(66, 82)]


def is_matte(r: int, g: int, b: int) -> bool:
    return r >= 220 and b >= 220 and g <= 35


def clean(path: Path) -> tuple[int, int]:
    image = Image.open(path).convert("RGBA")
    pixels = image.load()
    removed = 0
    for y in range(image.height):
        for x in range(image.width):
            r, g, b, a = pixels[x, y]
            # Matte contamination is only trustworthy at very low alpha.  Do
            # not touch opaque purple/blue/red artwork inside the balloon.
            if 0 < a <= 32 and is_matte(r, g, b):
                pixels[x, y] = (0, 0, 0, 0)
                removed += 1
    image.save(path, optimize=True)
    return removed, image.width * image.height


def main() -> None:
    total = 0
    files = 0
    for skin_id in IDS:
        folder = ROOT / skin_id
        if not folder.is_dir():
            continue
        for path in sorted(folder.glob("*.png")):
            removed, _ = clean(path)
            total += removed
            files += 1
    print(f"CLEAN_WATER_BALLOON_MATTE files={files} removed_low_alpha_pixels={total}")


if __name__ == "__main__":
    main()
