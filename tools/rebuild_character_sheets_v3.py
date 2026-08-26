"""Rebuild every playable character into one consistent 14-clip animation set."""

from __future__ import annotations

from collections import deque
from pathlib import Path
import math

from PIL import Image, ImageEnhance, ImageOps


ROOT = Path(__file__).resolve().parents[1]
CANVAS = (112, 112)
DIRECTIONS = ("down", "up", "left", "right")
CHARACTERS = (
    ("boom_mascot", "assets/characters/boom_mascot/source/boom_mascot_turnaround_v1.png", "assets/characters/boom_mascot/source/boom_mascot_idle_sheet_v1.png", "assets/characters/action_sheets_v4/boom_mascot.png", 4, "boom_mascot_frames.tres"),
    ("mint_sprout", "assets/characters/mint_sprout/source/mint_sprout_turnaround_v2.png", "assets/characters/mint_sprout/source/mint_sprout_idle_sheet_v1.png", "assets/characters/action_sheets_v4/mint_sprout.png", 4, "mint_sprout_frames.tres"),
    ("red_rider", "assets/characters/red_rider/source/red_rider_turnaround_v1.png", "assets/characters/red_rider/source/red_rider_idle_sheet_v1.png", "assets/characters/action_sheets_v4/red_rider.png", 4, "red_rider_frames.tres"),
    ("sunny_mechanic", "assets/characters/sunny_mechanic/source/sunny_mechanic_turnaround_v2.png", "assets/characters/sunny_mechanic/source/sunny_mechanic_idle_sheet_v1.png", "assets/characters/action_sheets_v4/sunny_mechanic.png", 4, "sunny_mechanic_frames.tres"),
    ("coral_diver", "assets/characters/coral_diver/source/coral_diver_turnaround_v1.png", "assets/characters/coral_diver/source/coral_diver_idle_sheet_v1.png", "assets/characters/coral_diver/source/coral_diver_actions_v1.png", 3, "coral_diver_frames.tres"),
    ("cloud_bunny", "assets/characters/cloud_bunny/source/cloud_bunny_turnaround_v1.png", "assets/characters/cloud_bunny/source/cloud_bunny_idle_sheet_v1.png", "assets/characters/cloud_bunny/source/cloud_bunny_actions_v1.png", 3, "cloud_bunny_frames.tres"),
    ("lime_dino", "assets/characters/lime_dino/source/lime_dino_turnaround_v1.png", "assets/characters/lime_dino/source/lime_dino_idle_sheet_v1.png", "assets/characters/lime_dino/source/lime_dino_actions_v1.png", 3, "lime_dino_frames.tres"),
    ("star_skater", "assets/characters/star_skater/source/star_skater_turnaround_v1.png", "assets/characters/star_skater/source/star_skater_idle_sheet_v1.png", "assets/characters/star_skater/source/star_skater_actions_v1.png", 3, "star_skater_frames.tres"),
    ("cocoa_otter", "assets/characters/cocoa_otter/source/cocoa_otter_turnaround_v1.png", "assets/characters/cocoa_otter/source/cocoa_otter_idle_sheet_v1.png", "assets/characters/cocoa_otter/source/cocoa_otter_actions_v1.png", 3, "cocoa_otter_frames.tres"),
)
ACTION_META = {
    "water_hit": (5, 12.0, False), "bubble": (6, 7.0, True),
    "rescued": (5, 10.0, False), "die": (7, 8.0, False),
    "win": (8, 9.0, True), "lose": (6, 6.0, True),
}


def is_background(pixel: tuple[int, int, int, int]) -> bool:
    r, g, b, a = pixel
    return a < 10 or (min(r, g, b) >= 195 and max(r, g, b) - min(r, g, b) <= 38)


def isolate(image: Image.Image, keep_all_components: bool = False) -> Image.Image:
    image = image.convert("RGBA")
    px = image.load()
    width, height = image.size
    queue: deque[tuple[int, int]] = deque()
    seen: set[tuple[int, int]] = set()
    for x in range(width):
        queue.extend(((x, 0), (x, height - 1)))
    for y in range(height):
        queue.extend(((0, y), (width - 1, y)))
    while queue:
        x, y = queue.popleft()
        if (x, y) in seen or not is_background(px[x, y]):
            continue
        seen.add((x, y))
        px[x, y] = (0, 0, 0, 0)
        if x: queue.append((x - 1, y))
        if x + 1 < width: queue.append((x + 1, y))
        if y: queue.append((x, y - 1))
        if y + 1 < height: queue.append((x, y + 1))
    # Keep only the main connected subject. This is the critical production
    # cut: neighbouring hats/feet can enter a rectangular atlas cell even when
    # its gutter is trimmed, but they are never connected to this pose.
    alpha = image.getchannel("A")
    alpha_px = alpha.load()
    components: list[list[tuple[int, int]]] = []
    visited: set[tuple[int, int]] = set()
    for sy in range(height):
        for sx in range(width):
            if (sx, sy) in visited or alpha_px[sx, sy] < 24:
                continue
            component: list[tuple[int, int]] = []
            pending = deque([(sx, sy)])
            visited.add((sx, sy))
            while pending:
                cx, cy = pending.popleft()
                component.append((cx, cy))
                for nx, ny in ((cx - 1, cy), (cx + 1, cy), (cx, cy - 1), (cx, cy + 1)):
                    if 0 <= nx < width and 0 <= ny < height and (nx, ny) not in visited and alpha_px[nx, ny] >= 24:
                        visited.add((nx, ny))
                        pending.append((nx, ny))
            components.append(component)
    if components and not keep_all_components:
        keep = set(max(components, key=len))
        pixels = image.load()
        for py in range(height):
            for px_x in range(width):
                if (px_x, py) not in keep:
                    r, g, b, _a = pixels[px_x, py]
                    pixels[px_x, py] = (r, g, b, 0)
    bbox = image.getchannel("A").getbbox()
    if bbox is None:
        raise RuntimeError("Empty character extraction")
    return image.crop(bbox)


def split_turnaround(source: Image.Image) -> dict[str, Image.Image]:
    width, height = source.size
    boxes = ((0, 0, width // 2, height // 2), (width // 2, 0, width, height // 2),
             (0, height // 2, width // 2, height), (width // 2, height // 2, width, height))
    return {direction: isolate(source.crop(box)) for direction, box in zip(DIRECTIONS, boxes)}


def guide_pose(guide: Image.Image, column: int, row: int, columns: int) -> Image.Image:
    x0 = round(column * guide.width / columns)
    x1 = round((column + 1) * guide.width / columns)
    y0 = round(row * guide.height / 2)
    y1 = round((row + 1) * guide.height / 2)
    inset_x = round((x1 - x0) * .025)
    inset_y = round((y1 - y0) * .025)
    x0 += inset_x; x1 -= inset_x; y0 += inset_y; y1 -= inset_y
    return isolate(guide.crop((x0, y0, x1, y1)))


def idle_pose(sheet: Image.Image, column: int, row: int) -> Image.Image:
    """Extract one exact authored pose from the strict 4x4 idle atlas."""
    x0 = round(column * sheet.width / 4)
    x1 = round((column + 1) * sheet.width / 4)
    y0 = round(row * sheet.height / 4)
    y1 = round((row + 1) * sheet.height / 4)
    inset_x = round((x1 - x0) * .025)
    inset_y = round((y1 - y0) * .025)
    return isolate(
        sheet.crop((x0 + inset_x, y0 + inset_y, x1 - inset_x, y1 - inset_y)),
        keep_all_components=True,
    )


def fit(image: Image.Image, bounds: tuple[int, int] = (92, 98)) -> Image.Image:
    return ImageOps.contain(image, bounds, Image.Resampling.LANCZOS)


def make_stubby(image: Image.Image) -> Image.Image:
    """Turn the lower body into one short foot-piece instead of long legs."""
    width, height = image.size
    hip = int(height * .66)
    upper = image.crop((0, 0, width, min(height, hip + 3)))
    lower = image.crop((0, hip, width, height))
    lower = lower.resize((max(1, round(width * .94)), max(1, round(lower.height * .62))), Image.Resampling.LANCZOS)
    result = Image.new("RGBA", (width, hip + lower.height), (0, 0, 0, 0))
    result.alpha_composite(upper, (0, 0))
    result.alpha_composite(lower, ((width - lower.width) // 2, hip - 1))
    return result


def animate_walk_legs(image: Image.Image, index: int) -> Image.Image:
    width, height = image.size
    cut = int(height * 0.70)
    middle = width // 2
    phase = 1 if index % 4 < 2 else -1
    result = Image.new("RGBA", (width + 4, height + 4), (0, 0, 0, 0))
    result.alpha_composite(image.crop((0, 0, width, min(height, cut + 5))), (2, 0))
    result.alpha_composite(image.crop((0, cut, middle + 2, height)), (0 if phase > 0 else 3, cut + (0 if phase > 0 else 3)))
    result.alpha_composite(image.crop((middle - 2, cut, width, height)), (middle + (3 if phase > 0 else 0), cut + (3 if phase > 0 else 0)))
    return result


def render_frame(base: Image.Image, action: str, index: int, count: int) -> Image.Image:
    phase = index / max(count, 1) * math.tau
    image = base.copy()
    sx = sy = 1.0
    ox = oy = 0
    angle = 0.0
    if action == "walk":
        image = animate_walk_legs(image, index)
        step = math.sin(phase)
        ox, oy, angle = round(step * 1.8), -round(abs(step) * 3.0), step * 2.4
        sx, sy = 1.0 + abs(step) * .025, 1.0 - abs(step) * .02
    elif action == "water_hit":
        ox = (-4, 4, -3, 2, 0)[index]
        angle = (-5, 5, -3, 2, 0)[index]
    elif action == "bubble":
        ox, oy = round(math.sin(phase) * 1.5), -round(abs(math.sin(phase)) * 2)
        sx, sy = 1.0 + math.sin(phase) * .02, 1.0 - math.sin(phase) * .02
    elif action == "rescued":
        progress = index / max(count - 1, 1)
        oy = -round(math.sin(progress * math.pi) * 10)
        angle = math.sin(progress * math.pi * 2) * 4
    elif action == "die":
        progress = index / max(count - 1, 1)
        angle, oy = progress * 22, round(progress * 8)
        image.putalpha(image.getchannel("A").point(lambda a: round(a * (1.0 - progress * .3))))
    elif action == "win":
        oy, angle = -round(abs(math.sin(phase)) * 8), math.sin(phase) * 4
    elif action == "lose":
        oy = round(abs(math.sin(phase * .5)) * 3)
        sy = .98
        image = ImageEnhance.Color(image).enhance(.84)
    image = image.resize((max(1, round(image.width * sx)), max(1, round(image.height * sy))), Image.Resampling.LANCZOS)
    if abs(angle) > .01:
        image = image.rotate(angle, Image.Resampling.BICUBIC, expand=True)
    canvas = Image.new("RGBA", CANVAS, (0, 0, 0, 0))
    canvas.alpha_composite(image, ((CANVAS[0] - image.width) // 2 + ox, CANVAS[1] - image.height - 3 + oy))
    # Production safety pass: no frame may touch the canvas edge. This also
    # normalizes the five characters to the same on-map height range.
    bbox = canvas.getchannel("A").getbbox()
    if bbox is None:
        raise RuntimeError(f"Empty rendered frame: {action} {index}")
    subject = canvas.crop(bbox)
    subject = ImageOps.contain(subject, (98, 98), Image.Resampling.LANCZOS)
    safe = Image.new("RGBA", CANVAS, (0, 0, 0, 0))
    safe.alpha_composite(subject, ((CANVAS[0] - subject.width) // 2, CANVAS[1] - subject.height - 7))
    return safe


def build_character(character_id: str, source_path: str, idle_path: str, action_path: str, action_columns: int, resource_name: str) -> None:
    output = ROOT / "assets/characters" / character_id / "v3"
    output.mkdir(parents=True, exist_ok=True)
    for stale in output.glob("*.png"):
        stale.unlink()
    bases = {direction: fit(make_stubby(image)) for direction, image in split_turnaround(Image.open(ROOT / source_path)).items()}
    animations: list[tuple[str, float, bool, list[Path]]] = []
    idle_sheet = Image.open(ROOT / idle_path).convert("RGBA")
    for row, direction in enumerate(DIRECTIONS):
        paths = []
        for index in range(4):
            path = output / f"idle_{direction}_{index:02}.png"
            authored_pose = fit(idle_pose(idle_sheet, index, row), (96, 96))
            # Deliberately use no affine/bob/squash animation here: visible
            # motion must come from the separately drawn source pose itself.
            render_frame(authored_pose, "authored_idle", index, 4).save(path, optimize=True)
            paths.append(path)
        animations.append((f"idle_{direction}", 4.5, True, paths))
    for direction in DIRECTIONS:
        paths = []
        for index in range(8):
            path = output / f"walk_{direction}_{index:02}.png"
            render_frame(bases[direction], "walk", index, 8).save(path, optimize=True)
            paths.append(path)
        animations.append((f"walk_{direction}", 12.0, True, paths))
    action_sheet = Image.open(ROOT / action_path).convert("RGBA")
    positions = ({"water_hit": (2, 0), "bubble": (3, 0), "rescued": (0, 1), "die": (1, 1), "win": (2, 1), "lose": (3, 1)}
                 if action_columns == 4 else
                 {"water_hit": (0, 0), "bubble": (1, 0), "rescued": (2, 0), "die": (0, 1), "win": (1, 1), "lose": (2, 1)})
    for action, (count, fps, loop) in ACTION_META.items():
        column, row = positions[action]
        pose = fit(guide_pose(action_sheet, column, row, action_columns), (100, 100))
        paths = []
        for index in range(count):
            path = output / f"{action}_{index:02}.png"
            render_frame(pose, action, index, count).save(path, optimize=True)
            paths.append(path)
        animations.append((action, fps, loop, paths))
    write_resource(ROOT / "resources/characters" / resource_name, animations)
    (output / "preview.png").write_bytes((output / "idle_down_00.png").read_bytes())
    print(f"{character_id}: {sum(len(paths) for _, _, _, paths in animations)} frames / {len(animations)} clips")


def write_resource(path: Path, animations: list[tuple[str, float, bool, list[Path]]]) -> None:
    ext, ids, next_id = [], {}, 1
    for _, _, _, paths in animations:
        for frame in paths:
            ids[frame] = f"{next_id}_tex"
            ext.append(f'[ext_resource type="Texture2D" path="res://{frame.relative_to(ROOT).as_posix()}" id="{next_id}_tex"]')
            next_id += 1
    blocks = []
    for name, fps, loop, paths in animations:
        frames = ", ".join(f'{{\n"duration": 1.0,\n"texture": ExtResource("{ids[p]}")\n}}' for p in paths)
        blocks.append(f'{{\n"frames": [{frames}],\n"loop": {str(loop).lower()},\n"name": &"{name}",\n"speed": {fps:.1f}\n}}')
    path.write_text('[gd_resource type="SpriteFrames" format=3]\n\n' + '\n'.join(ext) + '\n\n[resource]\nanimations = [' + ', '.join(blocks) + ']\n', encoding="utf-8")


def main() -> None:
    for spec in CHARACTERS:
        build_character(*spec)


if __name__ == "__main__":
    main()
