"""Build Red Comet directional animation frames from the approved turnaround."""

from __future__ import annotations

from collections import deque
from pathlib import Path
import math

from PIL import Image, ImageEnhance, ImageOps


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "assets" / "characters" / "red_rider" / "source" / "red_rider_turnaround_v1.png"
RUNTIME = ROOT / "assets" / "characters" / "red_rider" / "runtime"
FRAME_RESOURCE = ROOT / "resources" / "characters" / "red_rider_frames.tres"
FILE_PREFIX = "red_rider"
CANVAS = (96, 112)
DIRECTIONS = ("down", "up", "left", "right")
ACTIONS = {
    "idle": (4, 3.5, True),
    "walk": (6, 10.5, True),
    "place": (4, 9.0, False),
    "pickup": (4, 9.0, False),
    "hurt": (3, 10.0, False),
    "bubbled": (4, 6.0, True),
    "die": (5, 7.0, False),
    "win": (6, 8.0, True),
    "lose": (4, 5.0, True),
}


def split_quadrants(source: Image.Image) -> list[Image.Image]:
    w, h = source.size
    hw, hh = w // 2, h // 2
    return [source.crop((0, 0, hw, hh)), source.crop((hw, 0, w, hh)), source.crop((0, hh, hw, h)), source.crop((hw, hh, w, h))]


def is_background(pixel: tuple[int, int, int, int]) -> bool:
    r, g, b, _a = pixel
    return min(r, g, b) >= 205 and max(r, g, b) - min(r, g, b) <= 38


def isolate(quadrant: Image.Image) -> Image.Image:
    image = quadrant.convert("RGBA")
    px = image.load()
    w, h = image.size
    queue: deque[tuple[int, int]] = deque()
    seen: set[tuple[int, int]] = set()
    for x in range(w):
        queue.extend(((x, 0), (x, h - 1)))
    for y in range(h):
        queue.extend(((0, y), (w - 1, y)))
    while queue:
        x, y = queue.popleft()
        if (x, y) in seen or not is_background(px[x, y]):
            continue
        seen.add((x, y))
        r, g, b, _a = px[x, y]
        px[x, y] = (r, g, b, 0)
        if x > 0: queue.append((x - 1, y))
        if x + 1 < w: queue.append((x + 1, y))
        if y > 0: queue.append((x, y - 1))
        if y + 1 < h: queue.append((x, y + 1))
    bbox = image.getchannel("A").getbbox()
    if bbox is None:
        raise RuntimeError("Character extraction produced an empty quadrant")
    return image.crop(bbox)


def transform_frame(base: Image.Image, action: str, index: int, count: int) -> Image.Image:
    phase = index / max(count, 1) * math.tau
    scale_x, scale_y = 1.0, 1.0
    offset_x, offset_y, angle = 0, 0, 0.0
    image = base.copy()
    if action == "idle":
        breath = (math.sin(phase) + 1.0) * 0.5
        offset_y = -round(breath * 1.5)
        scale_x = 1.0 + breath * 0.018
        scale_y = 1.0 - breath * 0.012
    elif action == "walk":
        image = animate_walk_legs(image, index, count)
        offset_x = round(math.sin(phase) * 1.5)
        offset_y = -abs(round(math.sin(phase) * 2.5))
        angle = math.sin(phase) * 1.7
        scale_x = 1.0 + abs(math.sin(phase)) * 0.025
        scale_y = 1.0 - abs(math.sin(phase)) * 0.018
    elif action == "place":
        anticipation = math.sin(index / max(count - 1, 1) * math.pi)
        offset_y = round(anticipation * 3.0)
        scale_x, scale_y = 1.0 + anticipation * 0.075, 1.0 - anticipation * 0.065
    elif action == "pickup":
        offset_y = -round(math.sin(index / max(count - 1, 1) * math.pi) * 7.0)
    elif action == "hurt":
        offset_x = (-3, 3, 0)[index]
        angle = (-5.0, 5.0, 0.0)[index]
        image = ImageEnhance.Color(image).enhance(0.65)
    elif action == "bubbled":
        offset_x = round(math.sin(phase) * 2.0)
        offset_y = -round(abs(math.sin(phase)) * 2.0)
        scale_x = scale_y = 0.94
    elif action == "die":
        progress = index / max(count - 1, 1)
        angle = progress * 72.0
        offset_y = round(progress * 16.0)
        scale_x = scale_y = 1.0 - progress * 0.18
        image.putalpha(image.getchannel("A").point(lambda alpha: round(alpha * (1.0 - progress * 0.35))))
    elif action == "win":
        offset_y = -round(abs(math.sin(phase)) * 9.0)
        angle = math.sin(phase) * 4.0
    elif action == "lose":
        offset_y = round(abs(math.sin(phase * 0.5)) * 5.0)
        scale_y = 0.96
        image = ImageEnhance.Color(image).enhance(0.72)

    target = (max(1, round(image.width * scale_x)), max(1, round(image.height * scale_y)))
    image = image.resize(target, Image.Resampling.LANCZOS)
    if abs(angle) > 0.01:
        image = image.rotate(angle, Image.Resampling.BICUBIC, expand=True)
    canvas = Image.new("RGBA", CANVAS, (0, 0, 0, 0))
    x = (CANVAS[0] - image.width) // 2 + offset_x
    y = CANVAS[1] - image.height - 4 + offset_y
    canvas.alpha_composite(image, (x, y))
    return canvas


def animate_walk_legs(image: Image.Image, index: int, count: int) -> Image.Image:
    """Alternate the actual lower-left/right pixels so feet visibly step."""
    width, height = image.size
    cut = int(height * 0.70)
    middle = width // 2
    phase = math.sin(index / max(count, 1) * math.tau)
    lift_left = 0 if phase >= 0.0 else 3
    lift_right = 3 if phase >= 0.0 else 0
    result = Image.new("RGBA", (width, height + 3), (0, 0, 0, 0))
    # Torso overlaps the split slightly so no seam opens at the hips.
    result.alpha_composite(image.crop((0, 0, width, cut + 4)), (0, 0))
    left_leg = image.crop((0, cut, middle + 2, height))
    right_leg = image.crop((middle - 2, cut, width, height))
    result.alpha_composite(left_leg, (-2 if phase >= 0.0 else 1, cut + lift_left))
    result.alpha_composite(right_leg, (middle - 2 + (2 if phase >= 0.0 else -1), cut + lift_right))
    return result


def build_frames() -> list[tuple[str, float, bool, list[Path]]]:
    RUNTIME.mkdir(parents=True, exist_ok=True)
    source = Image.open(SOURCE).convert("RGBA")
    bases: dict[str, Image.Image] = {}
    for direction, quadrant in zip(DIRECTIONS, split_quadrants(source)):
        extracted = isolate(quadrant)
        # Round mascot anatomy: a slightly wider, shorter body gives all cast
        # members the stubby-limb silhouette requested for cute locomotion.
        fitted = ImageOps.contain(extracted, (86, 90), Image.Resampling.LANCZOS)
        bases[direction] = fitted
    animations = []
    for action, (count, fps, loop) in ACTIONS.items():
        for direction in DIRECTIONS:
            paths = []
            for index in range(count):
                frame = transform_frame(bases[direction], action, index, count)
                path = RUNTIME / f"{FILE_PREFIX}_{action}_{direction}_{index:02}.png"
                frame.save(path, optimize=True)
                paths.append(path)
            animations.append((f"{action}_{direction}", fps, loop, paths))
    Image.open(RUNTIME / f"{FILE_PREFIX}_idle_down_00.png").save(RUNTIME / f"{FILE_PREFIX}_preview.png")
    return animations


def write_spriteframes(animations: list[tuple[str, float, bool, list[Path]]]) -> None:
    ext_lines = []
    ids: dict[Path, str] = {}
    next_id = 1
    for _name, _fps, _loop, paths in animations:
        for path in paths:
            resource_id = f"{next_id}_tex"
            ids[path] = resource_id
            relative = path.relative_to(ROOT).as_posix()
            ext_lines.append(f'[ext_resource type="Texture2D" path="res://{relative}" id="{resource_id}"]')
            next_id += 1
    animation_blocks = []
    for name, fps, loop, paths in animations:
        frames = ", ".join(f'{{\n"duration": 1.0,\n"texture": ExtResource("{ids[path]}")\n}}' for path in paths)
        animation_blocks.append(f'{{\n"frames": [{frames}],\n"loop": {1 if loop else 0},\n"name": &"{name}",\n"speed": {fps:.1f}\n}}')
    content = "[gd_resource type=\"SpriteFrames\" format=3]\n\n" + "\n".join(ext_lines)
    content += "\n\n[resource]\nanimations = [" + ", ".join(animation_blocks) + "]\n"
    FRAME_RESOURCE.write_text(content, encoding="utf-8")


def main() -> None:
    animations = build_frames()
    write_spriteframes(animations)
    print(f"Built {sum(len(paths) for _name, _fps, _loop, paths in animations)} {FILE_PREFIX} frames in {len(animations)} clips")


if __name__ == "__main__":
    main()
