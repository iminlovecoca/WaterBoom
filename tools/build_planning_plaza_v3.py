from collections import deque
from pathlib import Path
import json

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "assets" / "maps" / "planning_plaza_v3" / "source"
OUT = ROOT / "assets" / "maps" / "planning_plaza_v3" / "runtime"
BOUNDS = (0, 314, 627, 941, 1254)


def crop_cell(image: Image.Image, col: int, row: int) -> Image.Image:
    return image.crop((BOUNDS[col], BOUNDS[row], BOUNDS[col + 1], BOUNDS[row + 1]))


def is_checker(pixel) -> bool:
    r, g, b, _ = pixel
    return min(r, g, b) >= 202 and max(r, g, b) - min(r, g, b) <= 20


def remove_edge_checker(image: Image.Image) -> Image.Image:
    image = image.convert("RGBA")
    pixels = image.load()
    width, height = image.size
    queue = deque()
    visited = bytearray(width * height)

    def enqueue(x: int, y: int) -> None:
        idx = y * width + x
        if not visited[idx] and is_checker(pixels[x, y]):
            visited[idx] = 1
            queue.append((x, y))

    for x in range(width):
        enqueue(x, 0)
        enqueue(x, height - 1)
    for y in range(height):
        enqueue(0, y)
        enqueue(width - 1, y)

    while queue:
        x, y = queue.popleft()
        pixels[x, y] = (255, 255, 255, 0)
        if x > 0:
            enqueue(x - 1, y)
        if x + 1 < width:
            enqueue(x + 1, y)
        if y > 0:
            enqueue(x, y - 1)
        if y + 1 < height:
            enqueue(x, y + 1)

    # Remove pale checker remnants along the new transparent edge.
    for _ in range(2):
        clear = []
        for y in range(1, height - 1):
            for x in range(1, width - 1):
                if pixels[x, y][3] == 0 or not is_checker(pixels[x, y]):
                    continue
                if any(
                    pixels[nx, ny][3] == 0
                    for nx, ny in ((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1))
                ):
                    clear.append((x, y))
        for x, y in clear:
            pixels[x, y] = (255, 255, 255, 0)
    return image


def remove_small_components(image: Image.Image) -> Image.Image:
    pixels = image.load()
    width, height = image.size
    seen = bytearray(width * height)
    components = []
    for start_y in range(height):
        for start_x in range(width):
            start_idx = start_y * width + start_x
            if seen[start_idx] or pixels[start_x, start_y][3] == 0:
                continue
            seen[start_idx] = 1
            queue = deque([(start_x, start_y)])
            component = []
            while queue:
                x, y = queue.popleft()
                component.append((x, y))
                for nx, ny in ((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)):
                    if nx < 0 or ny < 0 or nx >= width or ny >= height:
                        continue
                    idx = ny * width + nx
                    if not seen[idx] and pixels[nx, ny][3] > 0:
                        seen[idx] = 1
                        queue.append((nx, ny))
            components.append(component)

    if not components:
        return image
    largest = max(len(component) for component in components)
    for component in components:
        if len(component) >= max(20, largest // 100):
            continue
        for x, y in component:
            pixels[x, y] = (255, 255, 255, 0)
    return image


def trim_and_fit(image: Image.Image, size: tuple[int, int], padding: int = 6) -> Image.Image:
    alpha = image.getchannel("A")
    box = alpha.getbbox()
    if not box:
        return Image.new("RGBA", size)
    image = image.crop(box)
    target_w = size[0] - padding * 2
    target_h = size[1] - padding * 2
    scale = min(target_w / image.width, target_h / image.height)
    resized = image.resize(
        (max(1, round(image.width * scale)), max(1, round(image.height * scale))),
        Image.Resampling.LANCZOS,
    )
    canvas = Image.new("RGBA", size)
    canvas.alpha_composite(resized, ((size[0] - resized.width) // 2, (size[1] - resized.height) // 2))
    return canvas


def save_tile(image: Image.Image, name: str) -> None:
    image.resize((256, 256), Image.Resampling.LANCZOS).save(OUT / f"{name}.png")


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    terrain = Image.open(SOURCE / "planning_plaza_terrain_master_v4_4x4.png").convert("RGBA")
    objects = Image.open(SOURCE / "planning_plaza_objects_master_4x4.png").convert("RGBA")
    fountain = Image.open(SOURCE / "planning_plaza_fountain_full_v2.png").convert("RGBA")

    terrain_rows = ("grass", "path", "wall", "hard")
    for row, prefix in enumerate(terrain_rows):
        for col in range(4):
            save_tile(crop_cell(terrain, col, row), f"{prefix}_{col + 1:02d}")

    object_rows = (
        ("crate_01", "crate_02", "crate_03", "crate_04"),
        ("flowerbed_01", "flowerbed_02", "flowerbed_03", "flowerbed_04"),
        ("prop_lamp", "prop_bench", "prop_signboard", "prop_planter"),
        ("damaged_crate_01", "damaged_crate_02", "damaged_crate_03", "damaged_crate_04"),
    )
    for row, names in enumerate(object_rows):
        for col, name in enumerate(names):
            cleaned = remove_small_components(remove_edge_checker(crop_cell(objects, col, row)))
            # Props fill their logical cell. In particular, crates must completely
            # cover the floor beneath instead of reading as undersized icons.
            trim_and_fit(cleaned, (256, 256), padding=0).save(OUT / f"{name}.png")

    fountain_clean = remove_small_components(remove_edge_checker(fountain))
    # Preserve the complete landmark. Trim only transparent space, then contain
    # and uniformly scale the whole fountain into the exact 3x3 runtime canvas.
    # Never crop into the fountain artwork itself.
    trim_and_fit(fountain_clean, (768, 768), padding=0).save(OUT / "fountain_3x3.png")

    manifest = {
        "tile_size": 40,
        "source_cell_size": 313,
        "runtime_tile_size": 256,
        "center_size_cells": [3, 3],
        "palette": "muted planning plaza",
        "terrain": [f"{kind}_{idx:02d}.png" for kind in terrain_rows for idx in range(1, 5)],
        "objects": [name + ".png" for row in object_rows for name in row],
        "center": "fountain_3x3.png",
    }
    (OUT / "manifest.json").write_text(json.dumps(manifest, ensure_ascii=False, indent=2), encoding="utf-8")


if __name__ == "__main__":
    main()
