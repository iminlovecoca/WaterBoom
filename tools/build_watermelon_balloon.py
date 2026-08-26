from pathlib import Path
from PIL import Image, ImageDraw
import math


ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "assets/water_balloon"
SKINS = {
    "watermelon": ROOT / "assets/water_balloon/source/watermelon_water_balloon_master.png",
    "dark": ROOT / "assets/water_balloon/source/dark_water_balloon_master.png",
    "sparkle": ROOT / "assets/water_balloon/source/sparkle_water_balloon_master.png",
}


def round_balloon_master(skin_id: str) -> Image.Image:
    """Author a genuinely circular balloon body; the tied neck is separate."""
    size = 160
    canvas = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    px = canvas.load()
    cx, cy, radius = 80, 91, 61
    dark = skin_id == "dark"
    for y in range(size):
        for x in range(size):
            dx, dy = x - cx, y - cy
            distance = math.sqrt(dx * dx + dy * dy)
            if distance > radius:
                continue
            nx, ny = dx / radius, dy / radius
            light = max(0.0, 1.0 - math.sqrt((nx + 0.36) ** 2 + (ny + 0.42) ** 2))
            edge = max(0.0, min(1.0, (radius - distance) / 10.0))
            if dark:
                r = int(28 + light * 54 + edge * 5)
                g = int(34 + light * 48 + edge * 7)
                b = int(112 + light * 92 + edge * 20)
            else:
                r = int(92 + light * 118 + max(nx, 0) * 28)
                g = int(188 + light * 58)
                b = int(226 + light * 29)
            px[x, y] = (min(r, 255), min(g, 255), min(b, 255), 255)
    draw = ImageDraw.Draw(canvas)
    outline = (27, 20, 94, 255) if dark else (35, 93, 190, 255)
    draw.ellipse((cx - radius, cy - radius, cx + radius, cy + radius), outline=outline, width=7)
    # Separate tied pouch neck so the main silhouette remains a perfect circle.
    tie_fill = (61, 52, 177, 255) if dark else (166, 226, 255, 255)
    draw.polygon([(70, 31), (80, 12), (90, 31), (87, 42), (73, 42)], fill=tie_fill, outline=outline)
    draw.polygon([(72, 20), (59, 8), (75, 6), (80, 16), (87, 5), (103, 10), (89, 23)], fill=tie_fill, outline=outline)
    draw.ellipse((43, 43, 70, 67), fill=(235, 249, 255, 205))
    draw.ellipse((51, 49, 62, 59), fill=(255, 255, 255, 245))
    if dark:
        draw.arc((50, 74, 113, 128), 205, 350, fill=(124, 83, 255, 210), width=7)
        draw.ellipse((104, 53, 116, 65), fill=(107, 87, 244, 180))
    else:
        for sx, sy in [(115, 54), (126, 76), (105, 122), (42, 101)]:
            draw.line((sx - 7, sy, sx + 7, sy), fill=(255, 250, 210, 235), width=3)
            draw.line((sx, sy - 7, sx, sy + 7), fill=(255, 250, 210, 235), width=3)
        draw.arc((48, 82, 125, 142), 8, 155, fill=(242, 181, 255, 195), width=7)
    return canvas


def main() -> None:
    default_frames = [(35, 37, -1.5), (37, 35, 1.5), (34, 38, -2.2), (38, 34, 2.2)]
    # Dark and sparkle masters originally had a long pouch silhouette. Keep the
    # cute tied top, but normalize the complete alpha figure into a near-square
    # envelope so their playable silhouette reads as a round water balloon.
    round_frames = [(36, 36, 0.0), (37, 35, 0.8), (35, 37, -0.8), (36, 36, 0.0)]
    for skin_id, source in SKINS.items():
        image = round_balloon_master(skin_id) if skin_id in {"dark", "sparkle"} else Image.open(source).convert("RGBA")
        figure = image.crop(image.getchannel("A").getbbox())
        frames = round_frames if skin_id in {"dark", "sparkle"} else default_frames
        for index, (width, height, angle) in enumerate(frames):
            if skin_id in {"dark", "sparkle"}:
                sprite = figure.copy()
                sprite.thumbnail((width, height), Image.Resampling.LANCZOS)
                width, height = sprite.size
            else:
                sprite = figure.resize((width, height), Image.Resampling.LANCZOS)
            sprite = sprite.rotate(angle, Image.Resampling.BICUBIC, expand=False)
            canvas = Image.new("RGBA", (40, 40), (0, 0, 0, 0))
            canvas.alpha_composite(sprite, ((40 - width) // 2, 39 - height))
            canvas.save(OUTPUT / f"{skin_id}_balloon_{index}.png", optimize=True)
    print(f"Built four 40x40 tension frames for {len(SKINS)} water-balloon skins")


if __name__ == "__main__":
    main()
