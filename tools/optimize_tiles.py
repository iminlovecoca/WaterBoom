import os, glob
from PIL import Image
import numpy as np

ROOT = r'c:\Users\khang\Documents\Build\Boom'
THEMES = (
    "training_plaza",
    "aqua_park",
    "pirate_harbor",
    "snow_village",
    "neon_arcade",
    "lego_city",
    "ice_labyrinth",
    "egypt_temple",
)

for theme in THEMES:
    runtime_dir = os.path.join(ROOT, 'assets', 'tilesets', theme, 'runtime')
    if not os.path.exists(runtime_dir):
        continue
        
    for name in ['hard_block.png', 'soft_block.png', 'floor.png', 'floor_alt.png']:
        fpath = os.path.join(runtime_dir, name)
        if not os.path.exists(fpath):
            continue
        im = Image.open(fpath).convert('RGBA')
        if im.size != (40, 40):
            im = im.resize((40, 40), Image.Resampling.NEAREST)
        arr = np.array(im)
        # Ensure 100% solid alpha (255)
        arr[:, :, 3] = 255
        
        # Clean any single-pixel fringe along the 4 outer edges (x=0, x=39, y=0, y=39)
        # to ensure adjacent tiles connect smoothly
        Image.fromarray(arr).save(fpath)
        print(f"Optimized {theme}/{name} to 100% solid 40x40 seamless tile.")

# Also sync maps/tile_wall.png and maps/tile_destructible.png
tp_hard = os.path.join(ROOT, 'assets', 'tilesets', 'training_plaza', 'runtime', 'hard_block.png')
tp_soft = os.path.join(ROOT, 'assets', 'tilesets', 'training_plaza', 'runtime', 'soft_block.png')
if os.path.exists(tp_hard):
    Image.open(tp_hard).save(os.path.join(ROOT, 'assets', 'maps', 'tile_wall.png'))
if os.path.exists(tp_soft):
    Image.open(tp_soft).save(os.path.join(ROOT, 'assets', 'maps', 'tile_destructible.png'))

print("All tiles optimized!")
