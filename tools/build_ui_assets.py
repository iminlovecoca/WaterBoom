from pathlib import Path
from PIL import Image, ImageDraw, ImageFont, ImageFilter
import cv2
import numpy as np


ROOT = Path(__file__).resolve().parents[1]
FONT = ROOT / "assets/fonts/ChakraPetch-SemiBold.ttf"
RESULT_DIR = ROOT / "assets/ui/results"
PREVIEW_DIR = ROOT / "assets/ui/map_previews"
CAPTURE_DIR = ROOT / "tests/artifacts/tileset_validation"
RESULT_SOURCE_DIR = RESULT_DIR / "source"
PORTRAIT_DIR = ROOT / "assets/ui/character_portraits"
CHARACTER_CARD_DIR = ROOT / "assets/ui/character_cards"
CHARACTER_BANNER_DIR = ROOT / "assets/ui/character_banners"
CHARACTER_SELFIE_DIR = ROOT / "assets/ui/character_selfies"
CHARACTER_PREVIEWS = {
    "ninja": ROOT / "assets/characters/ninja/runtime/ninja_turnaround_front.png",
    "red_rider": ROOT / "assets/characters/red_rider/runtime/red_rider_preview.png",
    "sunny_mechanic": ROOT / "assets/characters/sunny_mechanic/runtime/sunny_mechanic_preview.png",
    "mint_sprout": ROOT / "assets/characters/mint_sprout/runtime/mint_sprout_preview.png",
    "boom_mascot": ROOT / "assets/characters/boom_mascot/runtime/boom_mascot_preview.png",
}


def fit_cover(image: Image.Image, size: tuple[int, int]) -> Image.Image:
    ratio = max(size[0] / image.width, size[1] / image.height)
    resized = image.resize((round(image.width * ratio), round(image.height * ratio)), Image.Resampling.LANCZOS)
    left = (resized.width - size[0]) // 2
    top = (resized.height - size[1]) // 2
    return resized.crop((left, top, left + size[0], top + size[1]))


def build_map_previews() -> None:
    PREVIEW_DIR.mkdir(parents=True, exist_ok=True)
    for source in sorted(CAPTURE_DIR.glob("map_*.png")):
        image = Image.open(source).convert("RGB")
        # Visual captures are 4:3. The actual arena occupies the left 69% below the top bar.
        board = image.crop((int(image.width * 0.017), int(image.height * 0.09), int(image.width * 0.684), int(image.height * 0.978)))
        preview = fit_cover(board, (384, 216))
        preview.save(PREVIEW_DIR / source.name, optimize=True)


def build_normalized_character_portraits() -> None:
    PORTRAIT_DIR.mkdir(parents=True, exist_ok=True)
    for character_id, source_path in CHARACTER_PREVIEWS.items():
        image = Image.open(source_path).convert("RGBA")
        bbox = image.getchannel("A").getbbox()
        figure = image.crop(bbox)
        figure.thumbnail((72, 78), Image.Resampling.LANCZOS)
        canvas = Image.new("RGBA", (96, 96), (0, 0, 0, 0))
        canvas.alpha_composite(figure, ((96 - figure.width) // 2, 88 - figure.height))
        canvas.save(PORTRAIT_DIR / f"{character_id}.png", optimize=True)


def build_character_cards() -> None:
    """Create exact square runtime cards from the authored full-background masters."""
    source_dir = CHARACTER_CARD_DIR / "source"
    CHARACTER_CARD_DIR.mkdir(parents=True, exist_ok=True)
    for source_path in sorted(source_dir.glob("*_card_master.png")):
        character_id = source_path.stem.removesuffix("_card_master")
        image = Image.open(source_path).convert("RGB")
        fit_cover(image, (256, 256)).save(CHARACTER_CARD_DIR / f"{character_id}.png", optimize=True)


def build_character_banners() -> None:
    source_dir = CHARACTER_BANNER_DIR / "source"
    CHARACTER_BANNER_DIR.mkdir(parents=True, exist_ok=True)
    for source_path in sorted(source_dir.glob("*_background_master.png")):
        character_id = source_path.stem.removesuffix("_background_master")
        image = Image.open(source_path).convert("RGB")
        fit_cover(image, (512, 128)).save(CHARACTER_BANNER_DIR / f"{character_id}.png", optimize=True)


def build_character_selfies() -> None:
    """Normalize transparent ImageGen selfie cutouts without baking in a background."""
    source_dir = CHARACTER_SELFIE_DIR / "source"
    CHARACTER_SELFIE_DIR.mkdir(parents=True, exist_ok=True)
    for source_path in sorted(source_dir.glob("*_selfie_master.png")):
        character_id = source_path.stem.removesuffix("_selfie_master")
        image = Image.open(source_path).convert("RGBA")
        bbox = image.getchannel("A").getbbox()
        if bbox is None:
            continue
        figure = image.crop(bbox)
        figure.thumbnail((244, 244), Image.Resampling.LANCZOS)
        canvas = Image.new("RGBA", (256, 256), (0, 0, 0, 0))
        canvas.alpha_composite(figure, ((256 - figure.width) // 2, 250 - figure.height))
        canvas.save(CHARACTER_SELFIE_DIR / f"{character_id}.png", optimize=True)


def tracked_text_masks(text: str, font: ImageFont.FreeTypeFont, tracking: int) -> tuple[Image.Image, Image.Image, Image.Image]:
    advances = [round(font.getlength(char)) for char in text]
    canvas_size = (sum(advances) + tracking * (len(text) - 1) + 80, font.size * 2)
    masks = [Image.new("L", canvas_size, 0) for _ in range(3)]
    draws = [ImageDraw.Draw(mask) for mask in masks]
    x = 40
    for char, advance in zip(text, advances):
        draws[0].text((x, 12), char, font=font, fill=255, stroke_width=18, stroke_fill=255)
        draws[1].text((x, 12), char, font=font, fill=255, stroke_width=9, stroke_fill=255)
        draws[2].text((x, 12), char, font=font, fill=255)
        x += advance + tracking
    bbox = masks[0].getbbox()
    return tuple(mask.crop(bbox) for mask in masks)


def build_result_title(text: str, filename: str, top: tuple[int, int, int], bottom: tuple[int, int, int]) -> None:
    RESULT_DIR.mkdir(parents=True, exist_ok=True)
    font = ImageFont.truetype(str(FONT), 156)
    outer, inner, fill = tracked_text_masks(text, font, 7)
    size = outer.size
    pad = 32
    canvas = Image.new("RGBA", (size[0] + pad * 2, size[1] + pad * 2), (0, 0, 0, 0))
    shadow = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    shadow_mask = Image.new("L", canvas.size, 0)
    shadow_mask.paste(outer, (pad + 7, pad + 11))
    blurred = shadow_mask.filter(ImageFilter.GaussianBlur(6))
    shadow.paste((0, 12, 30, 150), (0, 0), blurred)
    canvas.alpha_composite(shadow)
    outer_layer = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    outer_layer.paste((12, 28, 52, 255), (pad, pad), outer)
    canvas.alpha_composite(outer_layer)
    rim_layer = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    rim_layer.paste((244, 250, 255, 255), (pad, pad), inner)
    canvas.alpha_composite(rim_layer)
    gradient = Image.new("RGBA", fill.size)
    pixels = gradient.load()
    for y in range(fill.height):
        t = y / max(fill.height - 1, 1)
        color = tuple(round(top[i] * (1.0 - t) + bottom[i] * t) for i in range(3)) + (255,)
        for x in range(fill.width):
            pixels[x, y] = color
    fill_layer = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    fill_layer.paste(gradient, (pad, pad), fill)
    canvas.alpha_composite(fill_layer)
    canvas.crop(canvas.getbbox()).save(RESULT_DIR / filename, optimize=True)


def extract_imagegen_title(source_name: str, output_name: str) -> None:
    """Remove only the baked light checkerboard while preserving generated lettering."""
    source = np.array(Image.open(RESULT_SOURCE_DIR / source_name).convert("RGB"))
    minimum = source.min(axis=2)
    maximum = source.max(axis=2)
    candidate = ((minimum > 180) & ((maximum - minimum) < 20)).astype(np.uint8)
    count, labels, stats, _ = cv2.connectedComponentsWithStats(candidate, 8)
    remove = np.zeros(candidate.shape, dtype=np.uint8)
    height, width = candidate.shape
    for label in range(1, count):
        x, y, w, h, area = stats[label]
        touches_edge = x == 0 or y == 0 or x + w == width or y + h == height
        fill_ratio = area / max(w * h, 1)
        component_brightness = float(minimum[labels == label].mean())
        enclosed_checker = area > 200 and fill_ratio > 0.58 and component_brightness > 225
        if touches_edge or enclosed_checker:
            remove[labels == label] = 255
    alpha = 255 - remove
    rgba = np.dstack((source, alpha))
    ys, xs = np.where(alpha > 0)
    cropped = rgba[ys.min():ys.max() + 1, xs.min():xs.max() + 1]
    Image.fromarray(cropped, "RGBA").save(RESULT_DIR / output_name, optimize=True)


if __name__ == "__main__":
    build_map_previews()
    build_normalized_character_portraits()
    build_character_cards()
    build_character_banners()
    build_character_selfies()
    extract_imagegen_title("victory_imagegen_v1.png", "victory_vi.png")
    extract_imagegen_title("defeat_imagegen_v1.png", "defeat_vi.png")
    print("Built map previews, character cards, banners, separate selfies, portraits, and result titles")
