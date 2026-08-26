from pathlib import Path
from PIL import Image, ImageChops, ImageEnhance, ImageFilter, ImageOps


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "assets/boss/source"
OUTPUT = ROOT / "assets/boss"


def normalize(source_name: str, output_name: str, size: int, inset: int) -> None:
    image = Image.open(SOURCE / source_name).convert("RGBA")
    bbox = image.getchannel("A").getbbox()
    figure = image.crop(bbox)
    figure.thumbnail((size - inset * 2, size - inset * 2), Image.Resampling.LANCZOS)
    canvas = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    canvas.alpha_composite(figure, ((size - figure.width) // 2, size - inset - figure.height))
    canvas.save(OUTPUT / output_name, optimize=True)


def _extract_turnaround_pose(sheet: Image.Image, index: int, is_boss: bool) -> Image.Image:
    half_w, half_h = sheet.width // 2, sheet.height // 2
    x = (index % 2) * half_w
    y = (index // 2) * half_h
    pose = sheet.crop((x, y, x + half_w, y + half_h)).convert("RGBA")
    pixels = pose.load()
    mask = Image.new("L", pose.size, 0)
    out = mask.load()
    for py in range(pose.height):
        for px in range(pose.width):
            red, green, blue, _ = pixels[px, py]
            if is_boss:
                foreground = not (green > 130 and green > red * 1.18 and green > blue * 1.18)
            else:
                # The minion turnaround came on a dark presentation backdrop.
                # Seed from its coral body and navy bandana, then dilate to retain
                # the clean dark outline without carrying the backdrop.
                foreground = (red > 90 and red > green * 1.18) or (blue > 65 and blue > red * 1.15)
            out[px, py] = 255 if foreground else 0
    if not is_boss:
        mask = mask.filter(ImageFilter.MaxFilter(15)).filter(ImageFilter.GaussianBlur(1.2))
    else:
        mask = mask.filter(ImageFilter.MaxFilter(5)).filter(ImageFilter.GaussianBlur(0.6))
    pose.putalpha(mask)
    bbox = pose.getchannel("A").getbbox()
    return pose.crop(bbox) if bbox else pose


def build_walk_sheet(source_name: str, output_name: str, frame_size: int, inset: int) -> None:
    """Build an explicit 4-direction × 6-frame cute locomotion sheet."""
    is_boss = "boss" in source_name
    turnaround_name = "pirate_octopus_boss_turnaround.png" if is_boss else "pirate_octopus_minion_turnaround.png"
    turnaround = Image.open(SOURCE / turnaround_name).convert("RGBA")
    sheet = Image.new("RGBA", (frame_size * 6, frame_size * 4), (0, 0, 0, 0))
    directions = ("down", "left", "right", "up")
    for row, direction in enumerate(directions):
        figure = _extract_turnaround_pose(turnaround, row, is_boss)
        figure.thumbnail((frame_size - inset * 2, frame_size - inset * 2), Image.Resampling.LANCZOS)
        for frame in range(6):
            phase = (frame % 3) - 1
            width_scale = 1.0 + (0.025 if frame % 2 == 0 else -0.015)
            height_scale = 1.0 - (0.018 if frame % 2 == 0 else -0.025)
            posed = figure.resize((round(figure.width * width_scale), round(figure.height * height_scale)), Image.Resampling.LANCZOS)
            posed = posed.rotate(phase * (0.45 if is_boss else 0.9), Image.Resampling.BICUBIC, expand=True)
            frame_canvas = Image.new("RGBA", (frame_size, frame_size), (0, 0, 0, 0))
            stride_x = phase * (2 if direction in {"left", "right"} else 1)
            bob_y = -3 if frame in {1, 4} else (1 if frame in {0, 3} else 0)
            frame_canvas.alpha_composite(posed, ((frame_size - posed.width) // 2 + stride_x, frame_size - inset - posed.height + bob_y))
            sheet.alpha_composite(frame_canvas, (frame * frame_size, row * frame_size))
    sheet.save(OUTPUT / output_name, optimize=True)


if __name__ == "__main__":
    OUTPUT.mkdir(parents=True, exist_ok=True)
    normalize("pirate_octopus_boss_master.png", "pirate_octopus_boss.png", 192, 6)
    normalize("pirate_octopus_minion_master.png", "pirate_octopus_minion.png", 80, 4)
    build_walk_sheet("pirate_octopus_boss_master.png", "pirate_octopus_boss_walk_sheet.png", 160, 6)
    build_walk_sheet("pirate_octopus_minion_master.png", "pirate_octopus_minion_walk_sheet.png", 64, 3)
    print("Built boss/minion runtime sprites and explicit 4-direction six-frame walk sheets")
