"""Fix blurry/fringed sprites imported into Godot.

Layer 1 (source PNGs): bleed true edge colors outward into fully transparent
pixels (4px dilation) and unpremultiply semi-transparent pixels so bilinear
filtering no longer mixes garbage RGB into character silhouettes.

Layer 2 (.import files): enable mipmaps + fix_alpha_border so heavy minification
stays crisp instead of mushy.

Run:  python tools/fix_sprite_edges.py [--dry-run]
"""
import sys
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
SPRITE_DIRS = [
    "assets/characters",
    "assets/water_balloons",
    "assets/cosmetics",
    "assets/boss",
    "assets/effects",
    "assets/vfx",
    "assets/water_stream",
    "assets/items",
    "assets/decorations_v2",
    "assets/maps",
    "assets/tilesets",
    "assets/tilesets_v2",
    "assets/boss_arena",
    "assets/decorations",
    "assets/visual_overhaul_v1",
    "assets/visual_overhaul_v2",
    "assets/visual_overhaul_v3",
    "assets/ui",
    "assets/branding",
]
BLEED_RADIUS = 4


def dilate_edges(rgba: np.ndarray) -> np.ndarray:
    alpha = rgba[..., 3].astype(np.int32)
    rgb = rgba[..., :3].astype(np.float64)

    # Unpremultiply semi-transparent pixels: recover true surface color so the
    # filtered blend at edges uses object color, not darkened variants.
    semi = (alpha > 0) & (alpha < 255)
    if semi.any():
        a = np.maximum(alpha[semi], 1).astype(np.float64)[..., None] / 255.0
        rgb[semi] = np.clip(rgb[semi] / a, 0.0, 255.0)

    # BFS-style outward color fill: transparent pixels adopt the average color
    # of already-filled neighbours, expanding BLEED_RADIUS pixels.
    filled = alpha > 0
    colors = rgb.copy()
    for _ in range(BLEED_RADIUS):
        frontier = (~filled) & (
            np.roll(filled, 1, 0) | np.roll(filled, -1, 0)
            | np.roll(filled, 1, 1) | np.roll(filled, -1, 1)
        )
        if not frontier.any():
            break
        acc = np.zeros_like(colors)
        cnt = np.zeros(filled.shape, dtype=np.int32)
        for shift, axis in ((1, 0), (-1, 0), (1, 1), (-1, 1)):
            src_fill = np.roll(filled, shift, axis)
            src_col = np.roll(colors, shift, axis)
            take = src_fill & frontier
            acc[take] += src_col[take]
            cnt[take] += 1
        newly = frontier & (cnt > 0)
        colors[newly] = acc[newly] / cnt[newly][..., None]
        filled |= newly

    rgba[..., :3] = np.where((alpha == 0)[..., None], np.rint(colors), rgb).astype(np.uint8)
    return rgba


def process_png(path: Path, dry_run: bool) -> bool:
    try:
        img = Image.open(path).convert("RGBA")
    except Exception as exc:  # noqa: BLE001
        print(f"  SKIP {path.relative_to(ROOT)}: {exc}")
        return False
    rgba = np.array(img)
    before = rgba.copy()
    fixed = dilate_edges(rgba)
    if not np.array_equal(before, fixed):
        if not dry_run:
            Image.fromarray(fixed, "RGBA").save(path, optimize=True)
        return True
    return False


def patch_import(path: Path, dry_run: bool) -> bool:
    text = path.read_text(encoding="utf-8", errors="replace")
    original = text
    for key, value in (("mipmaps/generate=", "true"), ("process/fix_alpha_border=", "true")):
        idx = text.find(key)
        if idx < 0:
            continue
        line_end = text.find("\n", idx)
        line = text[idx:line_end]
        if not line.endswith(value):
            text = text[:idx] + key + value + text[line_end:]
    if text != original:
        if not dry_run:
            path.write_text(text, encoding="utf-8")
        return True
    return False


def main() -> None:
    dry_run = "--dry-run" in sys.argv
    png_fixed = imports_patched = png_total = import_total = 0
    for folder in SPRITE_DIRS:
        base = ROOT / folder
        if not base.is_dir():
            print(f"missing folder: {folder}")
            continue
        for path in sorted(base.rglob("*")):
            rel = path.relative_to(ROOT).as_posix()
            if "source" in Path(rel).parts:
                continue
            if path.suffix.lower() == ".png":
                png_total += 1
                if process_png(path, dry_run):
                    png_fixed += 1
                    print(f"bledges: {rel}")
            elif path.suffix == ".import":
                import_total += 1
                if patch_import(path, dry_run):
                    imports_patched += 1
    print(f"\npngs changed: {png_fixed}/{png_total} | imports patched: {imports_patched}/{import_total}")


if __name__ == "__main__":
    main()
