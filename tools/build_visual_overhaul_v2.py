from __future__ import annotations

from collections import deque
from pathlib import Path
from statistics import median

from PIL import Image, ImageChops, ImageDraw


ROOT = Path(__file__).resolve().parents[1]
ASSET_ROOT = ROOT / "assets/visual_overhaul_v2"
MAP_ROOT = ASSET_ROOT / "maps"
DECOR_ROOT = ASSET_ROOT / "decorations"
SIZE = 256


def _grid_cell(image: Image.Image, column: int, row: int) -> Image.Image:
    """Crop a generated 4x4 atlas while removing its thin separators."""
    x0 = round(column * image.width / 4) + (2 if column else 0)
    x1 = round((column + 1) * image.width / 4) - (2 if column < 3 else 0)
    y0 = round(row * image.height / 4) + (2 if row else 0)
    y1 = round((row + 1) * image.height / 4) - (2 if row < 3 else 0)
    return image.crop((x0, y0, x1, y1))


def _edge_filled(image: Image.Image) -> Image.Image:
    """Fill a complete gameplay cell; the atlas already contains safe gutters."""
    inset_x = round(image.width * 0.045)
    inset_y = round(image.height * 0.04)
    return image.crop((inset_x, inset_y, image.width - inset_x, image.height - inset_y)).resize(
        (SIZE, SIZE), Image.Resampling.LANCZOS
    )


def _remove_connected_atlas_background(image: Image.Image) -> Image.Image:
    """Remove only the pale presentation board connected to a cell edge.

    Generated atlas objects have a warm paper background around their
    silhouette. Keeping that paper inside each runtime sprite caused bright
    gutters wherever crates touched. A connected-edge flood preserves pale
    stone inside a hard block because its darker outline isolates it from the
    presentation board.
    """
    rgba = image.convert("RGBA")
    pixels = rgba.load()
    width, height = rgba.size
    sample_points: list[tuple[int, int]] = []
    band = max(2, min(width, height) // 32)
    for y in range(band):
        for x in range(band):
            sample_points.extend(((x, y), (width - 1 - x, y), (x, height - 1 - y), (width - 1 - x, height - 1 - y)))
    bg = tuple(int(median([pixels[x, y][channel] for x, y in sample_points])) for channel in range(3))
    # Lego atlas cells are already full-bleed colored modules, not objects on
    # pale paper, so no background removal is needed for those cells.
    if min(bg) < 165 or max(bg) - min(bg) > 105:
        return rgba

    def is_board(x: int, y: int) -> bool:
        red, green, blue, _alpha = pixels[x, y]
        distance = (red - bg[0]) ** 2 + (green - bg[1]) ** 2 + (blue - bg[2]) ** 2
        return distance <= 88 ** 2 and max(red, green, blue) >= 155

    queue: deque[tuple[int, int]] = deque()
    for x in range(width):
        queue.append((x, 0))
        queue.append((x, height - 1))
    for y in range(height):
        queue.append((0, y))
        queue.append((width - 1, y))
    visited: set[tuple[int, int]] = set()
    while queue:
        x, y = queue.popleft()
        if (x, y) in visited or not is_board(x, y):
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
    return rgba


def _object_filled(image: Image.Image) -> Image.Image:
    """Cut a block from its atlas board and fill one complete gameplay cell."""
    inset_x = round(image.width * 0.045)
    inset_y = round(image.height * 0.04)
    cropped = image.crop((inset_x, inset_y, image.width - inset_x, image.height - inset_y))
    cutout = _remove_connected_atlas_background(cropped)
    bbox = cutout.getchannel("A").getbbox()
    if bbox is not None:
        cutout = cutout.crop(bbox)
    return cutout.resize((SIZE, SIZE), Image.Resampling.LANCZOS)


def _save_rotations(base: Image.Image, output: Path, names: tuple[str, str, str, str]) -> None:
    base.save(output / f"{names[0]}.png")
    base.rotate(-90, expand=False).save(output / f"{names[1]}.png")
    base.rotate(90, expand=False).save(output / f"{names[2]}.png")
    base.rotate(180, expand=False).save(output / f"{names[3]}.png")


def _build_seamless_frame(
    horizontal: Image.Image,
    output: Path,
    material_crop: tuple[int, int],
    cap_crop: tuple[int, int],
    cap_thickness: int,
) -> None:
    """Build four full-cell edges plus four correctly oriented L corners.

    The old generated modules contained floor-colored gutters. Rotating them
    also rotated those gutters, which made the corner appear detached. Here the
    wall material fills the complete cell and the directional cap is added on
    the outside edge. Corner caps are explicit TL/TR/BL/BR L shapes.
    """
    source = horizontal.convert("RGB")

    def tangent_seamless(image: Image.Image, height: int) -> Image.Image:
        """Mirror one half so both tangent edges have identical pixels.

        The runtime scales 256px art down to a 40px cell. Even a one-pixel
        mismatch at the authored edge became a visible bright/dark seam after
        filtering. A mirrored half guarantees exact continuity without hiding
        it under an overlapping sprite.
        """
        half = image.resize((SIZE // 2, height), Image.Resampling.LANCZOS)
        result = Image.new("RGB", (SIZE, height))
        result.paste(half, (0, 0))
        result.paste(half.transpose(Image.Transpose.FLIP_LEFT_RIGHT), (SIZE // 2, 0))
        return result

    material_source = source.crop((0, material_crop[0], SIZE, material_crop[1]))
    material = tangent_seamless(material_source, SIZE)
    cap_source = source.crop((0, cap_crop[0], SIZE, cap_crop[1]))
    cap = tangent_seamless(cap_source, cap_thickness)
    cap_vertical = cap.rotate(90, expand=True)

    # Edges own only their outside cap. The previous build also carried a
    # rotated floor-coloured inner gutter, which produced the white strip below
    # Pirate Harbor and made neighbouring corner modules look disconnected.
    top = material.copy()
    top.paste(cap, (0, 0))
    bottom = material.copy()
    bottom.paste(cap.transpose(Image.Transpose.FLIP_TOP_BOTTOM), (0, SIZE - cap_thickness))
    left = material.copy()
    left.paste(cap_vertical, (0, 0))
    right = material.copy()
    right.paste(cap_vertical.transpose(Image.Transpose.FLIP_LEFT_RIGHT), (SIZE - cap_thickness, 0))

    top.save(output / "wall_edge_top.png")
    bottom.save(output / "wall_edge_bottom.png")
    left.save(output / "wall_edge_left.png")
    right.save(output / "wall_edge_right.png")

    # Explicit square L corners. Every module starts from the same seamless
    # material and receives exactly the two outward-facing caps. This keeps all
    # four rotations honest and makes the frame one continuous rectangular ring.
    corner_specs = {
        "wall_corner_tl": ("top", "left"),
        "wall_corner_tr": ("top", "right"),
        "wall_corner_bl": ("bottom", "left"),
        "wall_corner_br": ("bottom", "right"),
    }
    for name, directions in corner_specs.items():
        corner = material.copy()
        if "top" in directions:
            corner.paste(cap, (0, 0))
        if "bottom" in directions:
            corner.paste(cap.transpose(Image.Transpose.FLIP_TOP_BOTTOM), (0, SIZE - cap_thickness))
        if "left" in directions:
            corner.paste(cap_vertical, (0, 0))
        if "right" in directions:
            corner.paste(cap_vertical.transpose(Image.Transpose.FLIP_LEFT_RIGHT), (SIZE - cap_thickness, 0))
        corner.save(output / f"{name}.png")


def build_maps() -> None:
    # Every selectable map now goes through one V2 slicing/frame pipeline.  The
    # generated atlases keep their own material identity, while runtime scale,
    # alpha cutout, apparent block mass and directional border construction stay
    # identical across all six arenas.
    for map_id in (
        "training_plaza",
        "lego_city",
        "egypt_temple",
        "aqua_park",
        "pirate_harbor",
        "snow_village",
    ):
        source = MAP_ROOT / map_id / "source/atlas.png"
        if map_id == "lego_city" and (MAP_ROOT / map_id / "source/atlas_v3.png").exists():
            source = MAP_ROOT / map_id / "source/atlas_v3.png"
        output = MAP_ROOT / map_id / "runtime"
        output.mkdir(parents=True, exist_ok=True)
        atlas = Image.open(source).convert("RGB")

        cells = [[_grid_cell(atlas, column, row) for column in range(4)] for row in range(4)]
        if map_id == "training_plaza":
            floor_cells = [cells[0][0], cells[0][0], cells[0][1], cells[0][3]]
        else:
            floor_cells = cells[0]
        for name, cell in zip(("floor_A", "floor_B", "floor_alt_A", "floor_alt_B"), floor_cells):
            cell.resize((SIZE, SIZE), Image.Resampling.LANCZOS).save(output / f"{name}.png")

        hard_cell_columns = [0, 1, 2, 3]
        if map_id == "aqua_park":
            # The generated pool-wall module is intentionally U-shaped.  It is
            # useful as decoration but its open middle would misrepresent a
            # fully solid gameplay collision cell, so runtime hard blocks use
            # only the three honest full-footprint Aqua modules.
            hard_cell_columns = [1, 2, 3, 1]
        for column, name in zip(hard_cell_columns, ("hard_block_A", "hard_block_B", "hard_block_C", "hard_block_D")):
            _object_filled(cells[1][column]).save(output / f"{name}.png")
        for column, name in enumerate(("soft_crate_a", "soft_crate_b", "soft_crate_c", "soft_crate_d")):
            _object_filled(cells[2][column]).save(output / f"{name}.png")

        horizontal = _edge_filled(cells[3][0])
        frame_profiles = {
            "training_plaza": ((105, 225), (56, 116), 54),
            "lego_city": ((0, 255), (0, 82), 58),
            "egypt_temple": ((88, 226), (47, 108), 54),
            "aqua_park": ((72, 232), (34, 105), 56),
            "pirate_harbor": ((76, 225), (43, 106), 54),
            "snow_village": ((82, 226), (48, 116), 58),
        }
        material_crop, cap_crop, cap_thickness = frame_profiles[map_id]
        _build_seamless_frame(horizontal, output, material_crop, cap_crop, cap_thickness)
        Image.open(output / "hard_block_A.png").save(output / "wall_center.png")
        Image.open(output / "hard_block_A.png").save(output / "wall_cap.png")
        Image.open(output / "hard_block_A.png").save(output / "hard_block.png")
        Image.open(output / "soft_crate_a.png").save(output / "soft_block.png")


def _fit_alpha_sprite(image: Image.Image, canvas_size: int, padding: int = 0) -> Image.Image:
    rgba = image.convert("RGBA")
    bbox = rgba.getchannel("A").getbbox()
    if bbox is None:
        raise RuntimeError("Empty alpha sprite")
    crop = rgba.crop(bbox)
    target = canvas_size - padding * 2
    scale = min(target / crop.width, target / crop.height)
    resized = crop.resize((round(crop.width * scale), round(crop.height * scale)), Image.Resampling.LANCZOS)
    canvas = Image.new("RGBA", (canvas_size, canvas_size), (0, 0, 0, 0))
    canvas.alpha_composite(resized, ((canvas_size - resized.width) // 2, (canvas_size - resized.height) // 2))
    return canvas


def _fit_alpha_canvas(
    image: Image.Image,
    canvas_width: int,
    canvas_height: int,
    padding: int = 0,
) -> Image.Image:
    rgba = image.convert("RGBA")
    bbox = rgba.getchannel("A").getbbox()
    if bbox is None:
        raise RuntimeError("Empty alpha sprite")
    crop = rgba.crop(bbox)
    target_width = canvas_width - padding * 2
    target_height = canvas_height - padding * 2
    scale = min(target_width / crop.width, target_height / crop.height)
    resized = crop.resize(
        (round(crop.width * scale), round(crop.height * scale)),
        Image.Resampling.LANCZOS,
    )
    canvas = Image.new("RGBA", (canvas_width, canvas_height), (0, 0, 0, 0))
    x = (canvas_width - resized.width) // 2
    y = canvas_height - padding - resized.height
    canvas.alpha_composite(resized, (x, y))
    return canvas


def _build_landmark_foundation(
    map_id: str,
    landmark_source: Path,
    output_name: str,
) -> None:
    """Compose a landmark over an opaque, exact 4x4 gameplay foundation.

    A transparent circular/triangular landmark over sixteen collision cells
    made its top row and corners look walkable. The foundation covers all 4x4
    cells, while the landmark remains the dominant authored object.
    """
    output = DECOR_ROOT / map_id / "runtime"
    output.mkdir(parents=True, exist_ok=True)
    canvas_size = 768
    cell_size = canvas_size // 4
    floor = Image.open(MAP_ROOT / map_id / "runtime/floor_A.png").convert("RGB")
    floor = floor.resize((cell_size, cell_size), Image.Resampling.LANCZOS)
    foundation = Image.new("RGBA", (canvas_size, canvas_size), (0, 0, 0, 255))
    for y in range(4):
        for x in range(4):
            foundation.paste(floor, (x * cell_size, y * cell_size))

    landmark = Image.open(landmark_source).convert("RGBA")
    bbox = landmark.getchannel("A").getbbox()
    if bbox is None:
        raise RuntimeError(f"Empty landmark: {landmark_source}")
    landmark = landmark.crop(bbox)
    # Fill the 4x4 canvas as aggressively as possible without clipping any
    # authored part. The neutral map floor remains visible only in genuine
    # silhouette corners; there is no foreign coloured frame around it.
    target = canvas_size - 8
    scale = min(target / landmark.width, target / landmark.height)
    landmark = landmark.resize(
        (round(landmark.width * scale), round(landmark.height * scale)),
        Image.Resampling.LANCZOS,
    )
    foundation.alpha_composite(
        landmark,
        ((canvas_size - landmark.width) // 2, canvas_size - 4 - landmark.height),
    )
    foundation.save(output / output_name)


def build_decorations() -> None:
    specifications = {
        "training_plaza": ("fountain.png", "fountain_4x4.png", 0),
        "lego_city": ("toy_city_hall.png", "toy_city_hall_4x4.png", 4),
        "egypt_temple": ("temple_center.png", "temple_center_4x4.png", 4),
    }
    for map_id, (source_name, output_name, padding) in specifications.items():
        source = DECOR_ROOT / map_id / "source" / source_name
        output = DECOR_ROOT / map_id / "runtime"
        output.mkdir(parents=True, exist_ok=True)
        _fit_alpha_sprite(Image.open(source), 768, padding).save(output / output_name)

    cactus_source = DECOR_ROOT / "egypt_temple/source/flowering_cactus.png"
    cactus_output = DECOR_ROOT / "egypt_temple/runtime/flowering_cactus_1x1.png"
    generated_cactus = DECOR_ROOT / "egypt_temple/source/flowering_cactus_v3_raw.png"
    cactus = Image.open(generated_cactus if generated_cactus.exists() else cactus_source)
    if generated_cactus.exists():
        cactus = _remove_connected_atlas_background(cactus)
    _fit_alpha_canvas(cactus, 48, 48, 1).save(cactus_output)

    snowman_source = DECOR_ROOT / "snow_village/source/snowman_v3_raw.png"
    if snowman_source.exists():
        snowman = _remove_connected_atlas_background(Image.open(snowman_source))
        snowman_output = DECOR_ROOT / "snow_village/runtime/snowman_1x1.png"
        snowman_output.parent.mkdir(parents=True, exist_ok=True)
        _fit_alpha_canvas(snowman, 48, 52, 1).save(snowman_output)

    _build_landmark_foundation(
        "aqua_park",
        ROOT / "assets/decorations_v2/aqua_park/runtime/aqua_fountain.png",
        "aqua_fountain_4x4.png",
    )
    _build_landmark_foundation(
        "pirate_harbor",
        ROOT / "assets/decorations_v2/pirate_harbor/runtime/anchor_fountain.png",
        "anchor_fountain_4x4.png",
    )
    _build_landmark_foundation(
        "lego_city",
        DECOR_ROOT / "lego_city/runtime/toy_city_hall_4x4.png",
        "toy_city_hall_full_4x4.png",
    )
    _build_landmark_foundation(
        "egypt_temple",
        DECOR_ROOT / "egypt_temple/runtime/temple_center_4x4.png",
        "temple_center_full_4x4.png",
    )


def _direction_region(direction: str) -> Image.Image:
    mask = Image.new("L", (SIZE, SIZE), 0)
    draw = ImageDraw.Draw(mask)
    center = SIZE // 2
    if direction == "left":
        draw.rectangle((0, 0, center, SIZE), fill=255)
    elif direction == "right":
        draw.rectangle((center, 0, SIZE, SIZE), fill=255)
    elif direction == "up":
        draw.rectangle((0, 0, SIZE, center), fill=255)
    elif direction == "down":
        draw.rectangle((0, center, SIZE, SIZE), fill=255)
    return mask


def build_water_stream() -> None:
    source = ASSET_ROOT / "water_stream/source/water_center_square_v4.png"
    if not source.exists():
        return

    old_runtime = ROOT / "assets/visual_overhaul_v1/water_stream/runtime"
    output = ASSET_ROOT / "water_stream/runtime"
    output.mkdir(parents=True, exist_ok=True)

    horizontal = Image.open(old_runtime / "water_horizontal.png").convert("RGBA").resize(
        (SIZE, SIZE), Image.Resampling.LANCZOS
    )
    vertical = Image.open(old_runtime / "water_vertical.png").convert("RGBA").resize(
        (SIZE, SIZE), Image.Resampling.LANCZOS
    )
    horizontal_alpha = horizontal.getchannel("A")
    vertical_alpha = vertical.getchannel("A")

    # This source is authored as a full-bleed square junction rather than a
    # radial splash. Keeping the complete image makes all four water currents
    # reach the exact tile boundary and removes the circular visual gap that
    # appeared between the old center and its neighbouring stream cells.
    generated_core = Image.open(source).convert("RGB").resize(
        (SIZE, SIZE), Image.Resampling.LANCZOS
    )
    core_sprite = generated_core.convert("RGBA")
    core_sprite.putalpha(Image.new("L", (SIZE, SIZE), 255))

    arm_masks = {
        "left": ImageChops.multiply(horizontal_alpha, _direction_region("left")),
        "right": ImageChops.multiply(horizontal_alpha, _direction_region("right")),
        "up": ImageChops.multiply(vertical_alpha, _direction_region("up")),
        "down": ImageChops.multiply(vertical_alpha, _direction_region("down")),
    }

    variants = {
        "center": ("left", "right", "up", "down"),
        "cross": ("left", "right", "up", "down"),
        "center_t_down": ("left", "right", "down"),
        "center_t_up": ("left", "right", "up"),
        "center_t_left": ("left", "up", "down"),
        "center_t_right": ("right", "up", "down"),
        "center_corner_rd": ("right", "down"),
        "center_corner_ld": ("left", "down"),
        "center_corner_ru": ("right", "up"),
        "center_corner_lu": ("left", "up"),
    }
    for name, directions in variants.items():
        tile = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
        for direction in directions:
            arm = horizontal.copy() if direction in ("left", "right") else vertical.copy()
            arm.putalpha(arm_masks[direction])
            tile.alpha_composite(arm)
        tile.alpha_composite(core_sprite)
        tile.save(output / f"water_{name}.png")

    for name in (
        "horizontal", "vertical", "end_left", "end_right", "end_up", "end_down", "impact"
    ):
        old_path = old_runtime / f"water_{name}.png"
        if old_path.exists():
            Image.open(old_path).save(output / f"water_{name}.png")


if __name__ == "__main__":
    build_maps()
    build_decorations()
    build_water_stream()
    print(f"Built strict Aqua-height visual overhaul in {ASSET_ROOT}")
