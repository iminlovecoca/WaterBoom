"""Extract five generated decoration masters into compact Godot sprites."""

from __future__ import annotations

from collections import deque
from pathlib import Path
import json

from PIL import Image, ImageDraw, ImageFont, ImageOps


ROOT = Path(__file__).resolve().parents[1]
THEME_PROPS = {
    "training_plaza": ("fountain", "topiary", "flower_bed", "plaza_lamp"),
    "aqua_park": ("parasol", "lifebuoy", "bubble_fountain", "tropical_plant"),
    "pirate_harbor": ("anchor_rope", "barrel_stack", "harbor_lamp", "fishing_gear"),
    "snow_village": ("snowy_pine", "snowman", "ice_crystal", "village_lamp"),
    "neon_arcade": ("arcade_cabinet", "hologram", "speaker_stack", "circuit_pylon"),
    "lego_city": ("toy_tree", "toy_hedge", "toy_house", "crosswalk_sign"),
    "ice_labyrinth": ("snowy_pine", "snowman", "ice_monument", "heater_lamp"),
    "egypt_temple": ("date_palm", "flowering_cactus", "scarab_monument", "desert_tent"),
}
SPRITE_SIZE = 128


def split_quadrants(source: Image.Image) -> list[Image.Image]:
    width, height = source.size
    half_w, half_h = width // 2, height // 2
    return [
        source.crop((0, 0, half_w, half_h)),
        source.crop((half_w, 0, width, half_h)),
        source.crop((0, half_h, half_w, height)),
        source.crop((half_w, half_h, width, height)),
    ]


def is_background(pixel: tuple[int, int, int, int]) -> bool:
    red, green, blue, _alpha = pixel
    return min(red, green, blue) >= 210 and max(red, green, blue) - min(red, green, blue) <= 34


def isolate(quadrant: Image.Image) -> Image.Image:
    image = quadrant.convert("RGBA")
    pixels = image.load()
    width, height = image.size
    queue: deque[tuple[int, int]] = deque()
    visited: set[tuple[int, int]] = set()
    for x in range(width):
        queue.extend(((x, 0), (x, height - 1)))
    for y in range(height):
        queue.extend(((0, y), (width - 1, y)))
    while queue:
        x, y = queue.popleft()
        if (x, y) in visited or not is_background(pixels[x, y]):
            continue
        visited.add((x, y))
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
    bbox = image.getchannel("A").getbbox()
    if bbox is None:
        raise RuntimeError("Decoration extraction removed the complete quadrant")
    return image.crop(bbox)


def fit_sprite(extracted: Image.Image) -> Image.Image:
    fitted = ImageOps.contain(extracted, (SPRITE_SIZE - 2, SPRITE_SIZE - 2), Image.Resampling.LANCZOS)
    canvas = Image.new("RGBA", (SPRITE_SIZE, SPRITE_SIZE), (0, 0, 0, 0))
    x = (SPRITE_SIZE - fitted.width) // 2
    y = SPRITE_SIZE - fitted.height - 1
    canvas.alpha_composite(fitted, (x, y))
    return canvas


def build_theme(theme: str, prop_names: tuple[str, ...]) -> list[Image.Image]:
    theme_dir = ROOT / "assets" / "decorations" / theme
    source_path = theme_dir / "source" / f"{theme}_decor_master_v1.png"
    runtime_dir = theme_dir / "runtime"
    runtime_dir.mkdir(parents=True, exist_ok=True)
    source = Image.open(source_path).convert("RGBA")
    sprites = [fit_sprite(isolate(quadrant)) for quadrant in split_quadrants(source)]
    for prop_name, sprite in zip(prop_names, sprites):
        sprite.save(runtime_dir / f"{prop_name}.png", optimize=True)
    return sprites


def build_validation_sheet(all_sprites: dict[str, list[Image.Image]]) -> None:
    sheet = Image.new("RGBA", (640, 185 * len(THEME_PROPS)), (18, 24, 38, 255))
    draw = ImageDraw.Draw(sheet)
    font = ImageFont.load_default()
    for row, (theme, names) in enumerate(THEME_PROPS.items()):
        y = row * 185
        draw.text((10, y + 8), theme.replace("_", " ").title(), fill=(255, 255, 255, 255), font=font)
        for index, (name, sprite) in enumerate(zip(names, all_sprites[theme])):
            scaled = sprite.resize((128, 128), Image.Resampling.NEAREST)
            sheet.alpha_composite(scaled, (index * 160 + 16, y + 30))
            draw.text((index * 160 + 10, y + 162), name, fill=(210, 220, 240, 255), font=font)
    output_dir = ROOT / "tests" / "artifacts" / "map_layout_validation"
    output_dir.mkdir(parents=True, exist_ok=True)
    sheet.save(output_dir / "DECORATIONS_FULL_VALIDATION.png")


def main() -> None:
    all_sprites = {theme: build_theme(theme, names) for theme, names in THEME_PROPS.items()}
    build_validation_sheet(all_sprites)
    manifest = {theme: list(names) for theme, names in THEME_PROPS.items()}
    output_path = ROOT / "tests" / "artifacts" / "map_layout_validation" / "decoration_manifest.json"
    output_path.write_text(json.dumps(manifest, indent=2), encoding="utf-8")
    print(f"Built {sum(len(names) for names in THEME_PROPS.values())} decoration sprites")


if __name__ == "__main__":
    main()
