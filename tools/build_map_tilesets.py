"""Build compact Godot runtime tiles from the five generated master sheets."""

from __future__ import annotations

from collections import deque
from pathlib import Path
import hashlib
import json

from PIL import Image, ImageDraw, ImageEnhance, ImageFilter, ImageFont, ImageOps


ROOT = Path(__file__).resolve().parents[1]
THEMES = (
    "training_plaza",
    "aqua_park",
    "pirate_harbor",
    "snow_village",
    "neon_arcade",
    "lego_city",
    "ice_labyrinth",
    "egypt_temple",
)
TILE_NAMES = ("floor", "floor_alt", "hard_block", "soft_block")
TILE_SIZE = 40


def split_quadrants(source: Image.Image) -> list[Image.Image]:
    width, height = source.size
    half_w, half_h = width // 2, height // 2
    return [
        source.crop((0, 0, half_w, half_h)),
        source.crop((half_w, 0, width, half_h)),
        source.crop((0, half_h, half_w, height)),
        source.crop((half_w, half_h, width, height)),
    ]


def build_seamless_floor(quadrant: Image.Image) -> Image.Image:
    # Ignore the presentation border and form a mirrored repeat. Mirrored edges
    # guarantee that neighbouring tiles join without visible seams.
    width, height = quadrant.size
    margin_x, margin_y = int(width * 0.27), int(height * 0.27)
    core = quadrant.crop((margin_x, margin_y, width - margin_x, height - margin_y))
    core = ImageOps.fit(core.convert("RGB"), (TILE_SIZE // 2, TILE_SIZE // 2), Image.Resampling.LANCZOS)
    tile = Image.new("RGBA", (TILE_SIZE, TILE_SIZE), (0, 0, 0, 255))
    tile.paste(core, (0, 0))
    tile.paste(ImageOps.mirror(core), (TILE_SIZE // 2, 0))
    tile.paste(ImageOps.flip(core), (0, TILE_SIZE // 2))
    tile.paste(ImageOps.flip(ImageOps.mirror(core)), (TILE_SIZE // 2, TILE_SIZE // 2))
    # A restrained inset bevel gives every 40x40 floor slab a readable top
    # plane without creating seams or changing the logical grid footprint.
    draw = ImageDraw.Draw(tile, "RGBA")
    # Keep ground seamless. Depth belongs to blocks/props, not to every floor
    # cell; outlining each tile made grass, snow and timber read as a grid.
    return tile


def is_background(pixel: tuple[int, int, int, int]) -> bool:
    red, green, blue, _alpha = pixel
    return min(red, green, blue) >= 215 and max(red, green, blue) - min(red, green, blue) <= 28


def remove_connected_background(quadrant: Image.Image) -> Image.Image:
    image = quadrant.convert("RGBA")
    pixels = image.load()
    width, height = image.size
    seen: set[tuple[int, int]] = set()
    queue: deque[tuple[int, int]] = deque()
    for x in range(width):
        queue.append((x, 0))
        queue.append((x, height - 1))
    for y in range(height):
        queue.append((0, y))
        queue.append((width - 1, y))
    while queue:
        x, y = queue.popleft()
        if (x, y) in seen or not is_background(pixels[x, y]):
            continue
        seen.add((x, y))
        red, green, blue, _alpha = pixels[x, y]
        pixels[x, y] = (red, green, blue, 0)
        if x > 0:
            queue.append((x - 1, y))
        if x + 1 < width:
            queue.append((x + 1, y))
        if y > 0:
            queue.append((x, y - 1))
        if y + 1 < height:
            queue.append((x, y + 1))
    return image


def build_block(quadrant: Image.Image) -> Image.Image:
    isolated = remove_connected_background(quadrant)
    alpha = isolated.getchannel("A")
    bbox = alpha.getbbox()
    if bbox is None:
        raise RuntimeError("No foreground object remained after background removal")
    cropped = isolated.crop(bbox)
    # Reserve space for a visible front face. The original illustration becomes
    # the raised top plane while the extrusion and contact shadow create 2.5D
    # depth. Everything remains inside one exact 40x40 gameplay cell.
    fitted = ImageOps.contain(cropped, (34, 29), Image.Resampling.LANCZOS)
    canvas = Image.new("RGBA", (TILE_SIZE, TILE_SIZE), (0, 0, 0, 0))
    x = (TILE_SIZE - fitted.width) // 2
    y = 3

    shadow_mask = fitted.getchannel("A").resize((fitted.width + 4, fitted.height + 4), Image.Resampling.BILINEAR)
    shadow = Image.new("RGBA", shadow_mask.size, (3, 8, 18, 0))
    shadow.putalpha(shadow_mask.filter(ImageFilter.GaussianBlur(2)))
    canvas.alpha_composite(shadow, (x - 1, y + 7))

    front = ImageEnhance.Brightness(fitted).enhance(0.58)
    for depth in range(7, 0, -1):
        canvas.alpha_composite(front, (x, y + depth))
    canvas.alpha_composite(fitted, (x, y))
    draw = ImageDraw.Draw(canvas, "RGBA")
    draw.line([(x + 2, y + fitted.height - 1), (x + fitted.width - 3, y + fitted.height - 1)], fill=(255, 255, 255, 55), width=1)
    draw.line([(x + 2, y + fitted.height + 6), (x + fitted.width - 3, y + fitted.height + 6)], fill=(0, 0, 0, 90), width=1)
    return canvas


def save_theme(theme: str) -> dict[str, str]:
    theme_dir = ROOT / "assets" / "tilesets" / theme
    source_path = theme_dir / "source" / f"{theme}_master_v1.png"
    runtime_dir = theme_dir / "runtime"
    processed_dir = theme_dir / "processed"
    runtime_dir.mkdir(parents=True, exist_ok=True)
    processed_dir.mkdir(parents=True, exist_ok=True)
    source = Image.open(source_path).convert("RGBA")
    quadrants = split_quadrants(source)
    tiles = [
        build_seamless_floor(quadrants[0]),
        build_seamless_floor(quadrants[1]),
        build_block(quadrants[2]),
        build_block(quadrants[3]),
    ]
    hashes: dict[str, str] = {}
    for name, tile in zip(TILE_NAMES, tiles):
        output_path = runtime_dir / f"{name}.png"
        tile.save(output_path, optimize=True)
        hashes[name] = hashlib.sha256(output_path.read_bytes()).hexdigest()

    preview = Image.new("RGBA", (4 * 160, 205), (26, 32, 48, 255))
    draw = ImageDraw.Draw(preview)
    draw.text((10, 8), theme.replace("_", " ").title(), fill=(255, 255, 255, 255), font=ImageFont.load_default())
    for index, (name, tile) in enumerate(zip(TILE_NAMES, tiles)):
        scaled = tile.resize((140, 140), Image.Resampling.NEAREST)
        preview.alpha_composite(scaled, (index * 160 + 10, 35))
        draw.text((index * 160 + 10, 182), name, fill=(210, 220, 240, 255), font=ImageFont.load_default())
    preview.save(processed_dir / f"{theme}_validation.png")
    return hashes


def build_combined_preview() -> None:
    row_height = 205
    combined = Image.new("RGBA", (640, row_height * len(THEMES)), (18, 24, 38, 255))
    for row, theme in enumerate(THEMES):
        preview_path = ROOT / "assets" / "tilesets" / theme / "processed" / f"{theme}_validation.png"
        combined.alpha_composite(Image.open(preview_path).convert("RGBA"), (0, row * row_height))
    output_dir = ROOT / "tests" / "artifacts" / "tileset_validation"
    output_dir.mkdir(parents=True, exist_ok=True)
    combined.save(output_dir / "TILESETS_FULL_VALIDATION.png")


def main() -> None:
    manifest = {theme: save_theme(theme) for theme in THEMES}
    build_combined_preview()
    manifest_path = ROOT / "tests" / "artifacts" / "tileset_validation" / "tileset_manifest.json"
    manifest_path.write_text(json.dumps(manifest, indent=2), encoding="utf-8")
    print(f"Built {len(THEMES) * len(TILE_NAMES)} runtime tiles across {len(THEMES)} themes")


if __name__ == "__main__":
    main()
