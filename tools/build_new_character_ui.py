"""Compose deterministic UI portraits from the generated gameplay sprites."""

from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parents[1]
THEMES = {
    "coral_diver": ("#063f78", "#22c8e8"),
    "cloud_bunny": ("#7350b8", "#ffc1ea"),
    "lime_dino": ("#286b30", "#b9eb49"),
    "star_skater": ("#34216f", "#bd68ff"),
    "cocoa_otter": ("#754322", "#35c3bd"),
}


def gradient(size: tuple[int, int], top: str, bottom: str) -> Image.Image:
    start, end = Image.new("RGB", (1, 1), top).getpixel((0, 0)), Image.new("RGB", (1, 1), bottom).getpixel((0, 0))
    image = Image.new("RGBA", size)
    draw = ImageDraw.Draw(image)
    for y in range(size[1]):
        t = y / max(size[1] - 1, 1)
        color = tuple(round(start[i] * (1 - t) + end[i] * t) for i in range(3)) + (255,)
        draw.line((0, y, size[0], y), fill=color)
    return image


def fit_subject(subject: Image.Image, bounds: tuple[int, int]) -> Image.Image:
    bbox = subject.getchannel("A").getbbox()
    subject = subject.crop(bbox) if bbox else subject
    scale = min(bounds[0] / max(subject.width, 1), bounds[1] / max(subject.height, 1))
    return subject.resize((max(1, round(subject.width * scale)), max(1, round(subject.height * scale))), Image.Resampling.LANCZOS)


for character_id, colors in THEMES.items():
    subject = Image.open(ROOT / "assets/characters" / character_id / "v3/preview.png").convert("RGBA")
    subject = fit_subject(subject, (216, 224))
    selfie = Image.new("RGBA", (256, 256), (0, 0, 0, 0))
    selfie.alpha_composite(subject, ((256 - subject.width) // 2, 250 - subject.height))

    card = gradient((256, 256), *colors)
    bubbles = Image.new("RGBA", card.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(bubbles)
    for x, y, r in ((28, 32, 14), (215, 45, 24), (45, 205, 20), (224, 192, 12)):
        draw.ellipse((x-r, y-r, x+r, y+r), outline=(220, 250, 255, 110), width=4)
    card = Image.alpha_composite(card, bubbles.filter(ImageFilter.GaussianBlur(1)))

    banner = gradient((512, 128), *colors)
    banner_subject = fit_subject(subject.copy(), (148, 124))
    banner.alpha_composite(banner_subject, (18, 126 - banner_subject.height))
    overlay = Image.new("RGBA", banner.size, (0, 0, 0, 0))
    od = ImageDraw.Draw(overlay)
    od.ellipse((350, -30, 510, 130), outline=(220, 250, 255, 70), width=10)
    od.ellipse((420, 18, 475, 73), outline=(255, 255, 255, 65), width=5)
    banner = Image.alpha_composite(banner, overlay)

    for folder, image in (("character_selfies", selfie), ("character_portraits", selfie), ("character_cards", card), ("character_banners", banner)):
        target = ROOT / "assets/ui" / folder / f"{character_id}.png"
        target.parent.mkdir(parents=True, exist_ok=True)
        image.save(target, optimize=True)
    print(character_id)
