from __future__ import annotations

from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
COMMON_SOURCE = ROOT / "assets/visual_overhaul_v1/common/source/common_atlas.png"
COMMON_OUT = ROOT / "assets/visual_overhaul_v1/common/runtime"
STREAM_SOURCE = ROOT / "assets/visual_overhaul_v1/water_stream/source/water_stream_master.png"
STREAM_OUT = ROOT / "assets/visual_overhaul_v1/water_stream/runtime"
MAPS_ROOT = ROOT / "assets/visual_overhaul_v1/maps"
DECOR_ROOT = ROOT / "assets/visual_overhaul_v1/decorations"
SIZE = 256


def _grid_cell(image: Image.Image, column: int, row: int) -> Image.Image:
    """Crop an AI atlas by proportional coordinates, excluding divider pixels."""
    x0 = round(column * image.width / 4) + (2 if column else 0)
    x1 = round((column + 1) * image.width / 4) - (2 if column < 3 else 0)
    y0 = round(row * image.height / 4) + (2 if row else 0)
    y1 = round((row + 1) * image.height / 4) - (2 if row < 3 else 0)
    return image.crop((x0, y0, x1, y1))


def _remove_grass_backdrop(image: Image.Image) -> Image.Image:
    """Chroma-key only the generated green ground; keep brown/stone props intact."""
    rgba = image.convert("RGBA")
    pixels = rgba.load()
    for y in range(rgba.height):
        for x in range(rgba.width):
            r, g, b, _ = pixels[x, y]
            green_dominance = g - max(r, b)
            alpha = 0 if g > 62 and green_dominance > 13 else 255
            pixels[x, y] = (r, g, b, alpha)
    return rgba


def build_common() -> None:
    COMMON_OUT.mkdir(parents=True, exist_ok=True)
    atlas = Image.open(COMMON_SOURCE).convert("RGB")
    for column in range(4):
        tile = _grid_cell(atlas, column, 0).resize((SIZE, SIZE), Image.Resampling.LANCZOS)
        tile.save(COMMON_OUT / f"ground_{column + 1:02d}.png")

    object_cells = {
        "hard_stone": (0, 1),
        "hard_stack": (1, 1),
        "hard_stump": (3, 1),
        "soft_crate": (0, 2),
        "soft_reinforced": (1, 2),
        "soft_pot": (2, 2),
    }
    for name, (column, row) in object_cells.items():
        prop = _grid_cell(atlas, column, row).resize((SIZE, SIZE), Image.Resampling.LANCZOS)
        _remove_grass_backdrop(prop).save(COMMON_OUT / f"{name}.png")


def _edge_filled_module(image: Image.Image) -> Image.Image:
    """Remove atlas dividers/margins so adjacent gameplay blocks cannot reveal floor."""
    inset_x = round(image.width * 0.085)
    inset_y = round(image.height * 0.075)
    return image.crop((inset_x, inset_y, image.width - inset_x, image.height - inset_y)).resize(
        (SIZE, SIZE), Image.Resampling.LANCZOS
    )


def build_maps() -> None:
    for theme_dir in sorted(path for path in MAPS_ROOT.iterdir() if path.is_dir()):
        source = theme_dir / "source/atlas.png"
        if not source.exists():
            continue
        output = theme_dir / "runtime"
        output.mkdir(parents=True, exist_ok=True)
        atlas = Image.open(source).convert("RGB")
        floor_names = ["floor_A", "floor_B", "floor_alt_A", "floor_alt_B"]
        hard_names = ["hard_block_A", "hard_block_B", "hard_block_C", "hard_block_D"]
        soft_names = ["soft_crate_a", "soft_crate_b", "soft_crate_c", "soft_crate_d"]
        for column, name in enumerate(floor_names):
            _grid_cell(atlas, column, 0).resize((SIZE, SIZE), Image.Resampling.LANCZOS).save(output / f"{name}.png")
        for column, name in enumerate(hard_names):
            _edge_filled_module(_grid_cell(atlas, column, 1)).save(output / f"{name}.png")
        for column, name in enumerate(soft_names):
            _edge_filled_module(_grid_cell(atlas, column, 2)).save(output / f"{name}.png")
        # Compatibility aliases used by older scenes and previews.
        Image.open(output / "hard_block_A.png").save(output / "hard_block.png")
        Image.open(output / "soft_crate_a.png").save(output / "soft_block.png")


def _nonblack_column_runs(image: Image.Image) -> list[tuple[int, int]]:
    rgb = image.convert("RGB")
    runs: list[tuple[int, int]] = []
    start: int | None = None
    for x in range(rgb.width):
        active = any(max(rgb.getpixel((x, y))) > 24 for y in range(rgb.height))
        if active and start is None:
            start = x
        elif not active and start is not None:
            if x - start > 24:
                runs.append((start, x))
            start = None
    if start is not None:
        runs.append((start, rgb.width))
    return runs


def _black_to_alpha(image: Image.Image) -> Image.Image:
    rgb = image.convert("RGB")
    alpha = Image.new("L", rgb.size)
    alpha.putdata([max(pixel) if max(pixel) > 18 else 0 for pixel in rgb.getdata()])
    rgba = rgb.convert("RGBA")
    rgba.putalpha(alpha)
    return rgba


def _light_neutral_to_alpha(image: Image.Image) -> Image.Image:
    """Remove a baked white/light-gray transparency checker without eating gold."""
    rgba = image.convert("RGBA")
    pixels = rgba.load()
    for y in range(rgba.height):
        for x in range(rgba.width):
            r, g, b, _ = pixels[x, y]
            neutral = max(r, g, b) - min(r, g, b) < 11
            pixels[x, y] = (r, g, b, 0 if neutral and min(r, g, b) > 224 else 255)
    return rgba


def _fit_alpha_sprite(image: Image.Image, size: int, padding: int) -> Image.Image:
    bbox = image.getchannel("A").getbbox()
    if bbox is None:
        raise RuntimeError("Empty alpha sprite")
    crop = image.crop(bbox)
    target = size - padding * 2
    scale = min(target / crop.width, target / crop.height)
    resized = crop.resize((round(crop.width * scale), round(crop.height * scale)), Image.Resampling.LANCZOS)
    canvas = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    canvas.alpha_composite(resized, ((size - resized.width) // 2, (size - resized.height) // 2))
    return canvas


def build_decorations() -> None:
    egypt = DECOR_ROOT / "egypt_temple"
    output = egypt / "runtime"
    output.mkdir(parents=True, exist_ok=True)
    center = _light_neutral_to_alpha(Image.open(egypt / "source/temple_center.png"))
    _fit_alpha_sprite(center, 768, 24).save(output / "temple_center_4x4.png")
    cactus = _black_to_alpha(Image.open(egypt / "source/flowering_cactus.png"))
    _fit_alpha_sprite(cactus, 512, 28).save(output / "flowering_cactus_1x1.png")

    lego = DECOR_ROOT / "lego_city"
    output = lego / "runtime"
    output.mkdir(parents=True, exist_ok=True)
    city_hall = _light_neutral_to_alpha(Image.open(lego / "source/toy_city_hall.png"))
    # Preserve the full silhouette and a small transparent safety gutter. The
    # gameplay sprite then fits this exactly into its authored 3x3 footprint.
    _fit_alpha_sprite(city_hall, 768, 10).save(output / "toy_city_hall_3x3.png")


def _fit(image: Image.Image, target_width: int, target_height: int) -> Image.Image:
    resized = image.resize((target_width, target_height), Image.Resampling.LANCZOS)
    canvas = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    canvas.alpha_composite(resized, ((SIZE - target_width) // 2, (SIZE - target_height) // 2))
    return canvas


def _mask_cross(cross: Image.Image, arms: set[str]) -> Image.Image:
    result = cross.copy()
    alpha = result.getchannel("A")
    clear = Image.new("L", alpha.size, 0)
    # Preserve a generous 88x88 junction and remove only the far unused arm.
    boxes = {
        "up": (84, 0, 172, 84),
        "down": (84, 172, 172, 256),
        "left": (0, 84, 84, 172),
        "right": (172, 84, 256, 172),
    }
    for direction, box in boxes.items():
        if direction not in arms:
            alpha.paste(clear.crop(box), box)
    result.putalpha(alpha)
    return result


def build_stream() -> None:
    STREAM_OUT.mkdir(parents=True, exist_ok=True)
    source = Image.open(STREAM_SOURCE).convert("RGB")
    runs = _nonblack_column_runs(source)
    if len(runs) != 4:
        raise RuntimeError(f"Expected four water components, found {runs}")

    components: list[Image.Image] = []
    for x0, x1 in runs:
        crop = source.crop((x0, 0, x1, source.height))
        keyed = _black_to_alpha(crop)
        bbox = keyed.getchannel("A").getbbox()
        if bbox is None:
            raise RuntimeError("Empty water component")
        components.append(keyed.crop(bbox))

    raw_cross = _fit(components[0], SIZE, SIZE)
    horizontal = _fit(components[1], SIZE, SIZE)
    end_right = _fit(components[2], SIZE, SIZE)
    splash = _fit(components[3], SIZE, SIZE)
    # Center uses edge-reaching arms plus a full-cell impact, so the origin is
    # covered without sacrificing seamless joins to neighboring cells.
    cross = raw_cross.copy()
    cross.alpha_composite(splash)

    pieces = {
        "center": cross,
        "cross": cross,
        "horizontal": horizontal,
        "vertical": horizontal.rotate(90, expand=False),
        "end_right": end_right,
        "end_left": end_right.transpose(Image.Transpose.FLIP_LEFT_RIGHT),
        "end_up": end_right.rotate(90, expand=False),
        "end_down": end_right.rotate(-90, expand=False),
        "impact": splash,
        "center_t_down": _mask_cross(cross, {"down", "left", "right"}),
        "center_t_up": _mask_cross(cross, {"up", "left", "right"}),
        "center_t_left": _mask_cross(cross, {"up", "down", "left"}),
        "center_t_right": _mask_cross(cross, {"up", "down", "right"}),
        "center_corner_rd": _mask_cross(cross, {"right", "down"}),
        "center_corner_ld": _mask_cross(cross, {"left", "down"}),
        "center_corner_ru": _mask_cross(cross, {"right", "up"}),
        "center_corner_lu": _mask_cross(cross, {"left", "up"}),
    }
    for name, piece in pieces.items():
        piece.save(STREAM_OUT / f"water_{name}.png")


if __name__ == "__main__":
    build_common()
    build_maps()
    build_decorations()
    build_stream()
    print(f"Built visual overhaul assets in {COMMON_OUT.parent} and {STREAM_OUT.parent}")
