"""Build identity-safe Ninja 01 animation frames from the approved turnaround."""

from pathlib import Path
from PIL import Image, ImageDraw, ImageEnhance

ROOT = Path("assets/characters/ninja/runtime")
OUTPUT = ROOT / "animations_v1"
PIVOT = (48, 88)
DIRECTIONS = ("down", "up", "left", "right")
BASE_FILES = {
    "down": ROOT / "ninja_turnaround_front.png",
    "up": ROOT / "ninja_turnaround_back.png",
    "left": ROOT / "ninja_turnaround_left.png",
    "right": ROOT / "ninja_turnaround_right.png",
}

SEQUENCES = {
    "idle": [(0, 0, 0.0), (0, -1, -0.5), (0, -2, 0.0), (0, -1, 0.5)],
    "walk": [(-2, 0, -1.2), (-1, -2, -0.4), (1, -1, 1.2), (2, 0, 1.2), (1, -2, 0.4), (-1, -1, -1.2)],
    "place": [(0, 0, 0.0), (0, 0, 1.0), (0, 1, 1.5), (0, 0, 0.5), (0, 0, 0.0)],
    "pickup": [(0, 0, 0.0), (0, -1, -1.0), (0, -2, 0.0), (0, -1, 1.0), (0, 0, 0.0)],
    "hurt": [(-3, -1, -3.0), (3, 0, 3.0), (-2, -1, -2.0), (2, 0, 2.0), (-1, 0, -1.0), (0, 0, 0.0)],
    "bubbled": [(0, 0, -1.0), (0, -1, 0.0), (0, -2, 1.0), (0, -1, 0.0)],
    "die": [(0, 0, 0.0), (0, 1, 18.0), (0, 2, 38.0), (0, 4, 62.0), (0, 6, 82.0), (0, 8, 90.0)],
    "win": [(0, 0, 0.0), (0, -4, -3.0), (0, -9, 0.0), (0, -5, 3.0), (0, -2, 0.0), (0, 0, 0.0)],
    "lose": [(0, 0, 0.0), (0, 1, -1.0), (0, 2, 1.0), (0, 3, 0.0)],
}


def translate(image: Image.Image, dx: int, dy: int) -> Image.Image:
    canvas = Image.new("RGBA", image.size, (0, 0, 0, 0))
    canvas.alpha_composite(image, (dx, dy))
    return canvas


def rotate_about_pivot(image: Image.Image, degrees: float, pivot: tuple[int, int] = PIVOT) -> Image.Image:
    if degrees == 0.0:
        return image
    return image.rotate(
        degrees,
        resample=Image.Resampling.BICUBIC,
        center=pivot,
        expand=False,
    )


def tint_for_state(image: Image.Image, animation: str, frame: int) -> Image.Image:
    if animation == "hurt":
        cyan = Image.new("RGBA", image.size, (80, 225, 255, 0))
        cyan.putalpha(image.getchannel("A").point(lambda alpha: int(alpha * (0.25 if frame < 4 else 0.08))))
        return Image.alpha_composite(image, cyan)
    if animation == "lose":
        return ImageEnhance.Color(image).enhance(max(0.35, 1.0 - frame * 0.2))
    if animation == "die":
        alpha_factor = [1.0, 1.0, 0.9, 0.75, 0.5, 0.2][frame]
        result = image.copy()
        result.putalpha(result.getchannel("A").point(lambda alpha: int(alpha * alpha_factor)))
        return result
    return image


def animate_walk_legs(image: Image.Image, frame: int) -> Image.Image:
    """Move the two authored feet independently instead of only bobbing the body."""
    result = image.copy()
    # Clear only the boot area, preserving the coat and torso.
    clear = Image.new("RGBA", (42, 28), (0, 0, 0, 0))
    result.paste(clear, (27, 66))
    left = image.crop((27, 66, 49, 94))
    right = image.crop((47, 66, 69, 94))
    left_lift = 0 if frame % 4 < 2 else 3
    right_lift = 3 if frame % 4 < 2 else 0
    result.alpha_composite(left, (25 if left_lift == 0 else 27, 66 + left_lift))
    result.alpha_composite(right, (49 if right_lift == 0 else 47, 66 + right_lift))
    return result


def build() -> None:
    OUTPUT.mkdir(parents=True, exist_ok=True)
    frame_count = 0
    for direction in DIRECTIONS:
        base = Image.open(BASE_FILES[direction]).convert("RGBA")
        if base.size != (96, 96):
            raise RuntimeError(f"Unexpected base canvas for {direction}: {base.size}")
        for animation, poses in SEQUENCES.items():
            for index, (dx, dy, angle) in enumerate(poses):
                # Profile motion leans in travel direction; front/back retain the authored pose.
                adjusted_angle = angle
                if direction == "right":
                    adjusted_angle = -angle
                rotation_pivot = (48, 53) if animation == "die" else PIVOT
                pose_base = animate_walk_legs(base, index) if animation == "walk" else base
                frame = rotate_about_pivot(pose_base, adjusted_angle, rotation_pivot)
                frame = translate(frame, dx, dy)
                frame = tint_for_state(frame, animation, index)
                path = OUTPUT / f"ninja_{animation}_{direction}_{index:02d}.png"
                frame.save(path)
                frame_count += 1
    print(f"NINJA_ANIMATION_FRAMES: {frame_count}")
    print(f"OUTPUT: {OUTPUT}")
    build_contact_sheets()


def build_contact_sheets() -> None:
    artifact_dir = Path("tests/artifacts/character_validation")
    artifact_dir.mkdir(parents=True, exist_ok=True)
    cell = 96
    label_width = 110
    row_height = 106
    max_frames = max(len(poses) for poses in SEQUENCES.values())
    sheet = Image.new("RGBA", (label_width + max_frames * cell, len(SEQUENCES) * row_height), (31, 40, 55, 255))
    draw = ImageDraw.Draw(sheet)
    for row, (animation, poses) in enumerate(SEQUENCES.items()):
        y = row * row_height
        draw.text((8, y + 40), f"{animation}_down", fill=(230, 240, 255, 255))
        for frame_index in range(len(poses)):
            frame = Image.open(OUTPUT / f"ninja_{animation}_down_{frame_index:02d}.png").convert("RGBA")
            background = Image.new("RGBA", (cell, cell), (220, 225, 232, 255) if frame_index % 2 == 0 else (55, 66, 82, 255))
            background.alpha_composite(frame)
            sheet.alpha_composite(background, (label_width + frame_index * cell, y))
            draw.text((label_width + frame_index * cell + 4, y + 2), str(frame_index), fill=(255, 220, 90, 255))
    sheet.save(artifact_dir / "NINJA_FULL_VALIDATION.png")

    alpha_sheet = Image.new("RGBA", (384, 96), (0, 0, 0, 0))
    front = Image.open(ROOT / "ninja_turnaround_front.png").convert("RGBA")
    backgrounds = [(255, 255, 255, 255), (0, 0, 0, 255), (24, 104, 210, 255), (28, 145, 62, 255)]
    for index, color in enumerate(backgrounds):
        panel = Image.new("RGBA", (96, 96), color)
        panel.alpha_composite(front)
        alpha_sheet.alpha_composite(panel, (index * 96, 0))
    alpha_sheet.save(artifact_dir / "NINJA_ALPHA_BACKGROUNDS.png")


if __name__ == "__main__":
    build()
