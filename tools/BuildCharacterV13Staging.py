"""Build one V13 character staging bundle from three generated atlases.

Visible art must already exist under the character's v13_staging directory and
must originate from image generation. This tool only crops rows, runs the
generate2dsprite deterministic processor, and assembles the 84 accepted runtime
frames. It never writes production SpriteFrames resources.
"""

from __future__ import annotations

import argparse
from collections import deque
import shutil
import subprocess
import sys
from pathlib import Path

import numpy as np
from PIL import Image


PROJECT_ROOT = Path(__file__).resolve().parents[1]
PROCESSOR = Path.home() / ".codex" / "skills" / "generate2dsprite" / "scripts" / "generate2dsprite.py"

IDLE = ["idle_down", "idle_left", "idle_right", "idle_up"]
WALK = ["walk_down", "walk_left", "walk_right", "walk_up"]
STATUS = ["rescue", "water_hit", "bubble", "rescued", "die", "win", "lose"]
COUNTS = {
    "idle_down": 4, "idle_left": 4, "idle_right": 4, "idle_up": 4,
    "walk_down": 8, "walk_left": 8, "walk_right": 8, "walk_up": 8,
    "rescue": 4, "water_hit": 4, "bubble": 6, "rescued": 4,
    "die": 6, "win": 6, "lose": 6,
}


def normalize_connected_magenta_background(pixels: np.ndarray) -> np.ndarray:
    """Replace only border-connected magenta-family pixels with exact chroma.

    Image generation sometimes paints the requested flat #FF00FF background as
    a compressed or gently varying pink/purple field. A broad colour-only mask
    would also catch Coral Diver's pink hood. Restricting normalization to the
    magenta component connected to an atlas edge preserves outlined character
    colours while cleaning the full background and cell gutters.
    """
    red = pixels[:, :, 0].astype(np.int16)
    green = pixels[:, :, 1].astype(np.int16)
    blue = pixels[:, :, 2].astype(np.int16)
    candidate = (
        (red >= 135)
        & (blue >= 125)
        & (green <= 135)
        & ((red - green) >= 45)
        & ((blue - green) >= 40)
        & (np.abs(red - blue) <= 120)
    )

    height, width = candidate.shape
    visited = np.zeros((height, width), dtype=np.bool_)
    queue: deque[tuple[int, int]] = deque()

    for x in range(width):
        if candidate[0, x]:
            visited[0, x] = True
            queue.append((0, x))
        if candidate[height - 1, x] and not visited[height - 1, x]:
            visited[height - 1, x] = True
            queue.append((height - 1, x))
    for y in range(height):
        if candidate[y, 0] and not visited[y, 0]:
            visited[y, 0] = True
            queue.append((y, 0))
        if candidate[y, width - 1] and not visited[y, width - 1]:
            visited[y, width - 1] = True
            queue.append((y, width - 1))

    while queue:
        y, x = queue.popleft()
        for next_y, next_x in ((y - 1, x), (y + 1, x), (y, x - 1), (y, x + 1)):
            if (
                0 <= next_y < height
                and 0 <= next_x < width
                and candidate[next_y, next_x]
                and not visited[next_y, next_x]
            ):
                visited[next_y, next_x] = True
                queue.append((next_y, next_x))

    pixels[visited] = (255, 0, 255)
    return pixels


def repack_row_to_equal_cells(row_image: Image.Image, columns: int) -> Image.Image:
    """Center visually separated subjects into a mathematically exact grid.

    Image generation often draws the requested number of frames with even
    visual spacing but oversized outer gutters, so dividing the full canvas by
    N can cut a subject. Detect each foreground x-cluster on the normalized
    magenta row and repack it into N equal cells without changing its pixels or
    scale. This is deterministic layout correction, not visible-art creation.
    """
    pixels = np.asarray(row_image.convert("RGB"))
    foreground = np.any(pixels != np.array((255, 0, 255), dtype=np.uint8), axis=2)
    projection = foreground.sum(axis=0) >= 2

    # Bridge small internal/anti-alias gaps, but never the wide gutter between
    # adjacent characters.
    true_x = np.flatnonzero(projection)
    if true_x.size == 0:
        raise RuntimeError("Generated row contains no foreground subjects")
    bridged = projection.copy()
    for left, right in zip(true_x[:-1], true_x[1:]):
        if 1 < right - left <= 12:
            bridged[left:right + 1] = True

    transitions = np.diff(np.pad(bridged.astype(np.int8), (1, 1)))
    starts = np.flatnonzero(transitions == 1)
    ends = np.flatnonzero(transitions == -1)
    groups = [
        (int(start), int(end))
        for start, end in zip(starts, ends)
        if end - start >= 8 and int(foreground[:, start:end].sum()) >= 96
    ]
    if len(groups) != columns:
        raise RuntimeError(
            f"Expected {columns} separated subjects in generated row, detected {len(groups)}: {groups}"
        )

    cell_width = row_image.width // columns
    output = Image.new("RGB", (cell_width * columns, row_image.height), (255, 0, 255))
    for index, (left, right) in enumerate(groups):
        subject = row_image.crop((left, 0, right, row_image.height))
        if subject.width > cell_width:
            raise RuntimeError(
                f"Subject {index} width {subject.width}px cannot fit {cell_width}px cell without scaling"
            )
        target_x = index * cell_width + (cell_width - subject.width) // 2
        output.paste(subject, (target_x, 0))
    return output


def crop_rows(source: Path, actions: list[str], columns: int, output_root: Path) -> dict[str, Path]:
    image = Image.open(source).convert("RGB")
    pixels = np.asarray(image).copy()
    pixels = normalize_connected_magenta_background(pixels)
    image = Image.fromarray(pixels, mode="RGB")
    cell_w = image.width // columns
    cell_h = image.height // len(actions)
    cropped_width = cell_w * columns
    result: dict[str, Path] = {}
    output_root.mkdir(parents=True, exist_ok=True)
    for row, action in enumerate(actions):
        row_image = image.crop((0, row * cell_h, cropped_width, (row + 1) * cell_h))
        row_image = repack_row_to_equal_cells(row_image, columns)
        path = output_root / f"{action}.png"
        row_image.save(path)
        result[action] = path
    return result


def crop_walk_rows_4x8(source: Path, output_root: Path) -> dict[str, Path]:
    """Convert a generated 4-column x 8-row walk atlas into four 8-frame rows.

    Some image models preserve full-body silhouettes more reliably when an
    eight-frame direction is requested as two rows of four. Each consecutive
    pair belongs to one direction in WALK order. The conversion only reorders
    and centers generated pixels; it never redraws or scales visible art.
    """
    image = Image.open(source).convert("RGB")
    pixels = normalize_connected_magenta_background(np.asarray(image).copy())
    image = Image.fromarray(pixels, mode="RGB")
    source_columns = 4
    source_rows = 8
    cell_w = image.width // source_columns
    cell_h = image.height // source_rows
    output_root.mkdir(parents=True, exist_ok=True)
    result: dict[str, Path] = {}

    for direction_index, action in enumerate(WALK):
        output = Image.new("RGB", (cell_w * 8, cell_h), (255, 0, 255))
        for pair_index in range(2):
            source_row = direction_index * 2 + pair_index
            row_image = image.crop(
                (0, source_row * cell_h, cell_w * source_columns, (source_row + 1) * cell_h)
            )
            row_image = repack_row_to_equal_cells(row_image, source_columns)
            for source_column in range(source_columns):
                frame = row_image.crop(
                    (source_column * cell_w, 0, (source_column + 1) * cell_w, cell_h)
                )
                destination_column = pair_index * source_columns + source_column
                output.paste(frame, (destination_column * cell_w, 0))
        path = output_root / f"{action}.png"
        output.save(path)
        result[action] = path
    return result


def qc_limits(action: str) -> tuple[str, str]:
    # Expressive status poses deliberately change silhouette area (reaching,
    # recoiling, crouching, collapsing) while shared-scale keeps the rendered
    # body calibration fixed. Their body-area CV therefore needs a wider,
    # pose-aware gate than locomotion.
    if action == "die":
        # Standing-to-prone defeats intentionally move the source contact point;
        # feet/bottom alignment normalizes the accepted runtime output.
        return "0.25", "0.28"
    if action in STATUS:
        return "0.18", "0.15"
    # Hood leaves, tails and short stepping feet legitimately alter the source
    # silhouette a little; shared-scale and the 112px feet anchor still enforce
    # the actual in-game calibration.
    return "0.13", "0.07"


def process_action(action: str, source: Path, columns: int, output_dir: Path) -> None:
    body_cv, anchor_std = qc_limits(action)
    command = [
        sys.executable, str(PROCESSOR), "process",
        "--input", str(source),
        "--target", "player",
        "--role", "player",
        "--mode", action,
        "--output-dir", str(output_dir),
        "--rows", "1",
        "--cols", str(columns),
        "--label-prefix", action,
        "--cell-size", "112",
        "--fit-scale", "0.84",
        "--trim-border", "0",
        "--edge-clean-depth", "3",
        "--align", "feet",
        "--shared-scale",
        "--scale-strategy", "fit",
        "--component-mode", "largest",
        "--component-padding", "2",
        "--min-component-area", "32",
        "--edge-touch-margin", "1",
        # Generated atlases are reviewed before this deterministic step. This
        # permits source-cell chroma noise at a split while output-edge contact
        # and clamping remain strict failures under strict QC.
        "--allow-source-edge-touch",
        "--strict-qc",
        "--max-body-scale-cv", body_cv,
        "--max-anchor-y-std", anchor_std,
    ]
    subprocess.run(command, cwd=PROJECT_ROOT, check=True)


def assemble_runtime(character_root: Path, processed_root: Path) -> int:
    runtime_root = character_root / "runtime_frames"
    copied = 0
    for action, count in COUNTS.items():
        destination = runtime_root / action
        destination.mkdir(parents=True, exist_ok=True)
        frames = sorted(processed_root.joinpath(action).glob(f"{action}-*.png"))
        if len(frames) < count:
            raise RuntimeError(f"{action}: expected at least {count} processed frames, got {len(frames)}")
        for index, source in enumerate(frames[:count]):
            shutil.copy2(source, destination / f"{index:03d}.png")
            copied += 1
    return copied


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("character_id")
    args = parser.parse_args()

    root = PROJECT_ROOT / "assets" / "characters" / args.character_id / "v13_staging"
    inputs = {
        "idle": root / "idle_directional" / "raw_sheet.png",
        "walk": root / "walk_directional" / "raw_sheet.png",
        "status": root / "status_atlas" / "raw_sheet.png",
    }
    missing = [str(path) for path in inputs.values() if not path.exists()]
    if missing:
        raise FileNotFoundError("Missing V13 generated atlases: " + ", ".join(missing))

    row_root = root / "row_sources"
    rows: dict[str, Path] = {}
    rows.update(crop_rows(inputs["idle"], IDLE, 4, row_root))
    walk_layout_marker = root / "walk_directional" / "layout_4x8.txt"
    if walk_layout_marker.exists():
        rows.update(crop_walk_rows_4x8(inputs["walk"], row_root))
    else:
        rows.update(crop_rows(inputs["walk"], WALK, 8, row_root))
    rows.update(crop_rows(inputs["status"], STATUS, 6, row_root))

    processed_root = root / "processed_actions"
    for action, source in rows.items():
        process_action(action, source, 4 if action in IDLE else 8 if action in WALK else 6, processed_root / action)

    copied = assemble_runtime(root, processed_root)
    if copied != 84:
        raise RuntimeError(f"Expected 84 runtime frames, copied {copied}")
    print(f"CHARACTER_V13_BUILD PASS id={args.character_id} actions=15 frames={copied}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
