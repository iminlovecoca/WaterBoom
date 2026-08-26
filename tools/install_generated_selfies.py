"""Normalize generated transparent selfie cutouts to the lobby's 256px contract."""

from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
SOURCE = Path(r"C:\Users\khang\.codex\generated_images\01a008e1-1d38-7ac1-8026-462b54989736")
FILES = {
    "coral_diver": "exec-17f0418e-e575-4e2c-b65e-1eacff50cb60.png",
    "cloud_bunny": "exec-f7fb03a0-bce1-4abe-90d4-28c6de1aab86.png",
    "lime_dino": "exec-b14e43a5-8949-459d-8a4f-98117cbb8be7.png",
    "star_skater": "exec-217e8b9e-b71c-4c11-b703-d99c9333aeff.png",
    "cocoa_otter": "exec-5d97a8eb-5df0-40cd-b435-7db86fec5ec9.png",
}

for character_id, filename in FILES.items():
    source = Image.open(SOURCE / filename).convert("RGBA")
    bbox = source.getchannel("A").getbbox()
    cutout = source.crop(bbox) if bbox else source
    cutout.thumbnail((246, 246), Image.Resampling.LANCZOS)
    canvas = Image.new("RGBA", (256, 256), (0, 0, 0, 0))
    canvas.alpha_composite(cutout, ((256 - cutout.width) // 2, 254 - cutout.height))
    for folder in ("character_selfies", "character_portraits"):
        canvas.save(ROOT / "assets/ui" / folder / f"{character_id}.png", optimize=True)
    print(character_id, canvas.getchannel("A").getbbox())
