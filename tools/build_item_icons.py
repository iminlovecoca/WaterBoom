"""Extract the generated three-panel item master into clean 40×40 runtime icons."""

from pathlib import Path
from PIL import Image, ImageOps


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "assets" / "items" / "source" / "item_upgrade_master_v2.png"
OUTPUT = ROOT / "assets" / "items"
NAMES = ("item_water_balloon_up", "item_water_power_up", "item_speed_up")
SMILING_BOMB = ROOT / "assets" / "items" / "source" / "item_smiling_bomb_v1.png"


source = Image.open(SOURCE).convert("RGBA")
panel_width = source.width // 3
for index, name in enumerate(NAMES):
    left = index * panel_width
    right = source.width if index == 2 else (index + 1) * panel_width
    panel = source.crop((left, 0, right, source.height))
    alpha = panel.getchannel("A")
    bbox = alpha.getbbox()
    if bbox is None:
        raise RuntimeError(f"Empty generated item panel: {name}")
    panel = panel.crop(bbox)
    fitted = ImageOps.contain(panel, (36, 36), Image.Resampling.LANCZOS)
    canvas = Image.new("RGBA", (40, 40), (0, 0, 0, 0))
    canvas.alpha_composite(fitted, ((40 - fitted.width) // 2, (40 - fitted.height) // 2))
    canvas.save(OUTPUT / f"{name}.png", optimize=True)
    print(f"Built {name}.png")

# The capacity icon is authored separately so it can read as the requested
# friendly blue bomb instead of the earlier utility belt.
bomb = Image.open(SMILING_BOMB).convert("RGBA")
bbox = bomb.getchannel("A").getbbox()
if bbox is None:
    raise RuntimeError("Empty smiling bomb source")
bomb = ImageOps.contain(bomb.crop(bbox), (36, 36), Image.Resampling.LANCZOS)
canvas = Image.new("RGBA", (40, 40), (0, 0, 0, 0))
canvas.alpha_composite(bomb, ((40 - bomb.width) // 2, (40 - bomb.height) // 2))
canvas.save(OUTPUT / "item_water_balloon_up.png", optimize=True)
print("Replaced item_water_balloon_up.png with smiling bomb")
