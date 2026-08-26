"""Deterministically cut the 8x8 character sheets used by Boom Water.

The supplied sheets are already transparent PNGs.  This importer does not
generate or redraw artwork: it only crops each grid cell, preserves the alpha
channel, and places the same 64 source frames into the project's 112px
SpriteFrames contract (64 runtime PNGs / character).

The source row contract is:
  0 idle_down, 1 walk_down, 2 up, 3 right, 4 left,
  5 bubbled + escape, 6 lose, 7 win.

Rows 2-4 contain both the four idle poses and the eight walk poses.  The
runtime importer uses the first four frames for idle and all eight for walk.
"""

from __future__ import annotations

import argparse
import json
import math
from pathlib import Path
from typing import Iterable

from PIL import Image


GRID = 8
RUNTIME_SIZE = 112
FIT_SCALE = 0.86
GROUND_PAD = 4

# The source file names are intentionally explicit so a renamed sheet cannot
# silently be assigned to another character.
SOURCES = {
    "boom_mascot": "Codex Image Aug 24, 2026, 08_52_20 AM.png",
    "cloud_bunny": "Codex Image Aug 24, 2026, 08_51_28 AM.png",
    "mint_sprout": "Codex Image Aug 24, 2026, 08_51_53 AM.png",
    "coral_diver": "Codex Image Aug 24, 2026, 08_51_58 AM.png",
    "star_skater": "Codex Image Aug 24, 2026, 08_52_02 AM.png",
    "cocoa_otter": "Codex Image Aug 24, 2026, 08_52_07 AM.png",
    "sunny_mechanic": "Codex Image Aug 24, 2026, 08_52_10 AM.png",
    "red_rider": "Codex Image Aug 24, 2026, 08_52_13 AM.png",
    "lime_dino": "Codex Image Aug 24, 2026, 08_52_16 AM.png",
}

# The bunny export is the only supplied sheet with seven columns.  It is
# retained as-is for source crops; the runtime contract expands the walking
# rows to eight frames with a non-jarring return frame.
SOURCE_COLS = {"cloud_bunny": 7}


def grid_edges(size: int, index: int, count: int) -> tuple[int, int]:
    """Use rounded proportional edges so a 1254px sheet loses no remainder."""

    return round(index * size / count), round((index + 1) * size / count)


def alpha_bbox(image: Image.Image) -> tuple[int, int, int, int] | None:
    alpha = image.getchannel("A")
    return alpha.getbbox()


def keep_largest_component(image: Image.Image) -> Image.Image:
    """Drop alpha fragments leaking in from the neighbouring grid cell."""

    alpha = image.getchannel("A")
    pixels = alpha.load()
    width, height = image.size
    visited: set[tuple[int, int]] = set()
    best: list[tuple[int, int]] = []
    for y in range(height):
        for x in range(width):
            if pixels[x, y] == 0 or (x, y) in visited:
                continue
            queue = [(x, y)]
            visited.add((x, y))
            component: list[tuple[int, int]] = []
            while queue:
                cx, cy = queue.pop()
                component.append((cx, cy))
                for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    nx, ny = cx + dx, cy + dy
                    if (
                        0 <= nx < width
                        and 0 <= ny < height
                        and pixels[nx, ny] > 0
                        and (nx, ny) not in visited
                    ):
                        visited.add((nx, ny))
                        queue.append((nx, ny))
            if len(component) > len(best):
                best = component
    if not best:
        return Image.new("RGBA", image.size, (0, 0, 0, 0))
    selected = Image.new("L", image.size, 0)
    selected_pixels = selected.load()
    for x, y in best:
        selected_pixels[x, y] = pixels[x, y]
    result = image.copy()
    result.putalpha(selected)
    return result


def trim_alpha(image: Image.Image, padding: int = 4) -> Image.Image:
    image = keep_largest_component(image)
    bbox = alpha_bbox(image)
    if not bbox:
        return Image.new("RGBA", (1, 1), (0, 0, 0, 0))
    x0, y0, x1, y1 = bbox
    return image.crop(
        (max(0, x0 - padding), max(0, y0 - padding),
         min(image.width, x1 + padding), min(image.height, y1 + padding))
    )


def source_frames(source: Path, cols: int) -> list[Image.Image]:
    image = Image.open(source).convert("RGBA")
    frames: list[Image.Image] = []
    for row in range(GRID):
        y0, y1 = grid_edges(image.height, row, GRID)
        for col in range(cols):
            x0, x1 = grid_edges(image.width, col, cols)
            cell = image.crop((x0, y0, x1, y1))
            # Very faint transparent pixels are usually anti-aliased edge
            # noise. Removing only alpha<3 keeps the colored outline intact.
            alpha = cell.getchannel("A").point(lambda value: 0 if value < 3 else value)
            cell.putalpha(alpha)
            # Rows 1-4 sit directly below another animation row in the
            # supplied exports. Clear the thin bleed at the top and sides
            # before selecting the character component.
            if row in (1, 2, 3, 4):
                cleaned_alpha = cell.getchannel("A")
                pixels = cleaned_alpha.load()
                # The preceding row's feet overlap up to ~27px into these
                # cells in the supplied exports. The actual head starts
                # below that line for both front/back rows.
                top_clear = 28 if row in (1, 2) else 0
                for y in range(min(top_clear, cell.height)):
                    for x in range(cell.width):
                        pixels[x, y] = 0
                for y in range(cell.height):
                    for x in list(range(min(2, cell.width))) + list(range(max(0, cell.width - 2), cell.width)):
                        pixels[x, y] = 0
                cell.putalpha(cleaned_alpha)
            frames.append(trim_alpha(cell))
    return frames


def body_scale(frames: list[Image.Image], cols: int) -> float:
    body = [frames[index] for index in range(5 * cols)]
    max_dimension = max(max(frame.width, frame.height) for frame in body)
    return (RUNTIME_SIZE / max_dimension) * FIT_SCALE


def normalize(frame: Image.Image, scale: float) -> Image.Image:
    width = max(1, round(frame.width * scale))
    height = max(1, round(frame.height * scale))
    scaled = frame.resize((width, height), Image.Resampling.LANCZOS)
    canvas = Image.new("RGBA", (RUNTIME_SIZE, RUNTIME_SIZE), (0, 0, 0, 0))
    # All character states share the same x center and ground line.  This is
    # what prevents one character's feet from floating or sinking in-game.
    x = (RUNTIME_SIZE - width) // 2
    y = max(0, RUNTIME_SIZE - height - GROUND_PAD)
    canvas.alpha_composite(scaled, (x, y))
    return canvas


def write_source_crops(frames: list[Image.Image], source: Path, output: Path) -> list[str]:
    prefix = source.stem.replace(" ", "-")
    # Remove stale frames if a source sheet changed its column count (the
    # bunny export is 7 columns while the other supplied sheets are 8).
    for old in output.glob(f"{prefix}_*.png"):
        old.unlink()
    names: list[str] = []
    for index, frame in enumerate(frames, start=1):
        path = output / f"{prefix}_{index:02d}.png"
        frame.save(path, optimize=True)
        names.append(path.name)
    return names


def runtime_map(frames: list[Image.Image], cols: int) -> dict[str, list[Image.Image]]:
    row = lambda number: frames[number * cols : (number + 1) * cols]

    def walk(number: int) -> list[Image.Image]:
        values = row(number)
        if len(values) >= 8:
            return values[:8]
        # The bunny source has seven authored walk frames. Returning through
        # the penultimate frame avoids a visible freeze at the loop seam.
        return values + ([values[-2]] if len(values) > 1 else values)

    def four(values: list[Image.Image]) -> list[Image.Image]:
        values = values[:4]
        while values and len(values) < 4:
            values.append(values[-1])
        return values

    return {
        "idle_down": four(row(0)),
        "walk_down": walk(1),
        "idle_up": four(row(2)),
        "walk_up": walk(2),
        "idle_right": four(row(3)),
        "walk_right": walk(3),
        "idle_left": four(row(4)),
        "walk_left": walk(4),
        "bubbled": four(row(5)),
        "escape": four(row(5)[4:]),
        "lose": four(row(6)),
        "win": four(row(7)),
    }


def write_runtime(frames: list[Image.Image], character: str, project_root: Path, scale: float, cols: int) -> dict[str, int]:
    animation_frames = runtime_map(frames, cols)
    output_root = project_root / "assets" / "characters" / character / "v11"
    counts: dict[str, int] = {}
    for animation, source_list in animation_frames.items():
        output = output_root / animation
        output.mkdir(parents=True, exist_ok=True)
        for old in output.glob("*.png"):
            old.unlink()
        for index, frame in enumerate(source_list):
            normalize(frame, scale).save(output / f"{index:02d}.png", optimize=True)
        counts[animation] = len(source_list)
    return counts


def import_sheets(source_root: Path, project_root: Path, selected: Iterable[str] | None = None) -> dict:
    image_output = source_root / "Assets" / "images"
    image_output.mkdir(parents=True, exist_ok=True)
    chosen = list(selected) if selected else list(SOURCES)
    manifest = {
        "contract": "boom-water-character-sheet-v11",
        "grid_default": [GRID, 8],
        "runtime_frame_size": [RUNTIME_SIZE, RUNTIME_SIZE],
        "fit_scale": FIT_SCALE,
        "ground_pad": GROUND_PAD,
        "source_crops": [],
        "characters": [],
    }
    for character in chosen:
        if character not in SOURCES:
            raise ValueError(f"Unknown character: {character}")
        source = source_root / SOURCES[character]
        if not source.exists():
            raise FileNotFoundError(source)
        cols = SOURCE_COLS.get(character, 8)
        frames = source_frames(source, cols)
        scale = body_scale(frames, cols)
        crop_names = write_source_crops(frames, source, image_output)
        counts = write_runtime(frames, character, project_root, scale, cols)
        manifest["source_crops"].append({
            "character": character,
            "source": str(source),
            "grid": [GRID, cols],
            "frames": crop_names,
            "frame_count": len(crop_names),
        })
        manifest["characters"].append({
            "character": character,
            "source": str(source),
            "grid": [GRID, cols],
            "scale": scale,
            "animations": counts,
        })
    manifest_path = image_output / "character_sheet_import_manifest.json"
    manifest_path.write_text(json.dumps(manifest, ensure_ascii=False, indent=2), encoding="utf-8")
    return manifest


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source-root", type=Path, required=True)
    parser.add_argument("--project-root", type=Path, required=True)
    parser.add_argument("--character", action="append", dest="characters")
    args = parser.parse_args()
    result = import_sheets(args.source_root, args.project_root, args.characters)
    source_counts = [item["frame_count"] for item in result["source_crops"]]
    print(json.dumps({
        "characters": [item["character"] for item in result["characters"]],
        "source_frames_per_character": source_counts,
        "runtime_frames_per_character": 64,
        "manifest": str(args.source_root / "Assets" / "images" / "character_sheet_import_manifest.json"),
    }, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
