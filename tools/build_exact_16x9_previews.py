import os
from PIL import Image

ROOT = r'c:\Users\khang\Documents\Build\Boom'
PREVIEW_DIR = os.path.join(ROOT, 'assets', 'ui', 'map_previews')

THEMES = [
    "training_plaza",
    "aqua_park",
    "pirate_harbor",
    "snow_village",
    "neon_arcade",
    "lego_city",
    "ice_labyrinth",
    "egypt_temple",
]

# Generate exact 16:9 ratio previews (384 x 216)
for theme in THEMES:
    t_dir = os.path.join(ROOT, 'assets', 'tilesets', theme, 'runtime')
    floor = Image.open(os.path.join(t_dir, 'floor.png')).convert('RGBA')
    floor_alt = Image.open(os.path.join(t_dir, 'floor_alt.png')).convert('RGBA')
    hard = Image.open(os.path.join(t_dir, 'hard_block.png')).convert('RGBA')
    soft = Image.open(os.path.join(t_dir, 'soft_block.png')).convert('RGBA')
    
    # 16x16 grid -> 640x640 arena
    arena_img = Image.new('RGBA', (640, 640), (0, 0, 0, 255))
    for y in range(16):
        for x in range(16):
            px, py = x * 40, y * 40
            if x == 0 or x == 15 or y == 0 or y == 15:
                arena_img.paste(hard, (px, py))
            elif x % 2 == 0 and y % 2 == 0:
                arena_img.paste(hard, (px, py))
            elif (x + y) % 3 == 0 and (x not in (1, 2, 13, 14) or y not in (1, 2, 13, 14)):
                arena_img.paste(soft, (px, py))
            else:
                arena_img.paste(floor_alt if (x + y) % 2 == 0 else floor, (px, py))
                
    # Center-crop or fit 640x640 into a 16:9 canvas (384 x 216)
    # Crop central 640x360 window from the 640x640 arena to keep exact 1:1 pixel square aspect
    crop_y0 = (640 - 360) // 2
    cropped_arena = arena_img.crop((0, crop_y0, 640, crop_y0 + 360))
    preview_16_9 = cropped_arena.resize((384, 216), Image.Resampling.LANCZOS)
    
    out_path = os.path.join(PREVIEW_DIR, f'map_{theme}.png')
    preview_16_9.save(out_path)
    print(f"Generated un-stretched 16:9 preview for {theme}")

print("All map previews generated at exact 16:9 aspect ratio!")
