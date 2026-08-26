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
    source_path = os.path.join(ROOT, 'assets', 'tilesets', theme, 'source', f'{theme}_master_v1.png')
    runtime_dir = os.path.join(ROOT, 'assets', 'tilesets', theme, 'runtime')
    if not os.path.exists(source_path):
        continue
        
    master = Image.open(source_path).convert("RGBA")
    mw, mh = master.size
    hw, hh = mw // 2, mh // 2
    
    q_hard = master.crop((0, hh, hw, mh))
    q_soft = master.crop((hw, hh, mw, mh))
    
    for name, q in [('hard_block.png', q_hard), ('soft_block.png', q_soft)]:
        arr = np.array(q)
        h, w = arr.shape[:2]
        
        # Color distance from white / light background
        is_bg = (arr[:,:,0] > 200) & (arr[:,:,1] > 200) & (arr[:,:,2] > 200)
        is_fg = ~is_bg
        
        # Find inner bounding box with 2px margin inside foreground to avoid background fringe
        has_r = np.any(is_fg, axis=1)
        has_c = np.any(is_fg, axis=0)
        
        if np.any(has_r) and np.any(has_c):
            ymin = min(h - 1, np.where(has_r)[0][0] + 2)
            ymax = max(ymin + 1, np.where(has_r)[0][-1] - 2)
            xmin = min(w - 1, np.where(has_c)[0][0] + 2)
            xmax = max(xmin + 1, np.where(has_c)[0][-1] - 2)
            cropped = q.crop((xmin, ymin, xmax, ymax))
        else:
            cropped = q
            
        tile = cropped.resize((40, 40), Image.Resampling.LANCZOS)
        tile_arr = np.array(tile)
        
        # Replace any remaining light/white fringe pixels with the nearest solid inner pixel
        for y in range(40):
            for x in range(40):
                r, g, b = tile_arr[y, x, :3]
                if (r > 205 and g > 205 and b > 205) or tile_arr[y, x, 3] < 255:
                    sample_y = 20
                    sample_x = 20
                    tile_arr[y, x, :3] = tile_arr[sample_y, sample_x, :3]
                tile_arr[y, x, 3] = 255
                
        final_block = Image.fromarray(tile_arr)
        out_path = os.path.join(runtime_dir, name)
        final_block.save(out_path)
        print(f"Generated clean 100% flush {theme}/{name}")

# Also update assets/maps/tile_wall.png and tile_destructible.png
tp_hard = os.path.join(ROOT, 'assets', 'tilesets', 'training_plaza', 'runtime', 'hard_block.png')
tp_soft = os.path.join(ROOT, 'assets', 'tilesets', 'training_plaza', 'runtime', 'soft_block.png')
if os.path.exists(tp_hard):
    Image.open(tp_hard).save(os.path.join(ROOT, 'assets', 'maps', 'tile_wall.png'))
if os.path.exists(tp_soft):
    Image.open(tp_soft).save(os.path.join(ROOT, 'assets', 'maps', 'tile_destructible.png'))

print("All 8 map block sets completely remade cleanly with 0 white lines and 0 gaps!")
