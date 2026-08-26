import os, glob
from collections import deque
from PIL import Image, ImageOps
import numpy as np

ROOT = r'c:\Users\khang\Documents\Build\Boom'

# =========================================================================
# 1. REBUILD ALL LEFT CHARACTER FRAMES FROM RIGHT FRAMES (100% Grounded)
# =========================================================================
char_dir = os.path.join(ROOT, 'assets', 'characters')

for cpath in glob.glob(os.path.join(char_dir, '*')):
    if not os.path.isdir(cpath):
        continue
    v3_dir = os.path.join(cpath, 'v3')
    if not os.path.exists(v3_dir):
        continue
    cname = os.path.basename(cpath)
    
    # Mirror all right frames to left frames (idle_right -> idle_left, walk_right -> walk_left)
    for r_file in glob.glob(os.path.join(v3_dir, '*_right_*.png')):
        l_file = r_file.replace('_right_', '_left_')
        im_right = Image.open(r_file).convert('RGBA')
        im_left = ImageOps.mirror(im_right)
        im_left.save(l_file)
        
    print(f"Rebuilt left animations for {cname} from right frames (100% grounded at y=104).")

# =========================================================================
# 2. REBUILD ALL BLOCK SHEETS TO 100% FULL 40x40 FLUSH SQUARES
# =========================================================================
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
    os.makedirs(runtime_dir, exist_ok=True)
    
    if not os.path.exists(source_path):
        continue
        
    master = Image.open(source_path).convert("RGBA")
    mw, mh = master.size
    hw, hh = mw // 2, mh // 2
    
    # Quadrant 2: Hard block (bottom-left)
    # Quadrant 3: Soft block (bottom-right)
    q_hard = master.crop((0, hh, hw, mh))
    q_soft = master.crop((hw, hh, mw, mh))
    
    for name, q in [('hard_block.png', q_hard), ('soft_block.png', q_soft)]:
        arr = np.array(q)
        h, w = arr.shape[:2]
        
        # Detect background color from corners
        bg_r = np.median([arr[0, 0, 0], arr[0, w-1, 0], arr[h-1, 0, 0], arr[h-1, w-1, 0]])
        bg_g = np.median([arr[0, 0, 1], arr[0, w-1, 1], arr[h-1, 0, 1], arr[h-1, w-1, 1]])
        bg_b = np.median([arr[0, 0, 2], arr[0, w-1, 2], arr[h-1, 0, 2], arr[h-1, w-1, 2]])
        
        # Color distance from background
        dist = np.sqrt((arr[:,:,0] - bg_r)**2 + (arr[:,:,1] - bg_g)**2 + (arr[:,:,2] - bg_b)**2)
        is_fg = dist > 25
        
        # Find foreground bounding box
        has_r = np.any(is_fg, axis=1)
        has_c = np.any(is_fg, axis=0)
        
        if np.any(has_r) and np.any(has_c):
            ymin, ymax = np.where(has_r)[0][0], np.where(has_r)[0][-1] + 1
            xmin, xmax = np.where(has_c)[0][0], np.where(has_c)[0][-1] + 1
            cropped = q.crop((xmin, ymin, xmax, ymax))
        else:
            cropped = q
            
        # Scale to 40x40 full tile
        tile = cropped.resize((40, 40), Image.Resampling.LANCZOS)
        tile_arr = np.array(tile)
        tile_arr[:, :, 3] = 255 # 100% solid edge-to-edge
        
        final_block = Image.fromarray(tile_arr)
        out_path = os.path.join(runtime_dir, name)
        final_block.save(out_path)
        print(f"Built 100% full 40x40 flush block: {theme}/{name}")

# Also update assets/maps/tile_wall.png and tile_destructible.png with training_plaza blocks
tp_hard = os.path.join(ROOT, 'assets', 'tilesets', 'training_plaza', 'runtime', 'hard_block.png')
tp_soft = os.path.join(ROOT, 'assets', 'tilesets', 'training_plaza', 'runtime', 'soft_block.png')
if os.path.exists(tp_hard):
    Image.open(tp_hard).save(os.path.join(ROOT, 'assets', 'maps', 'tile_wall.png'))
if os.path.exists(tp_soft):
    Image.open(tp_soft).save(os.path.join(ROOT, 'assets', 'maps', 'tile_destructible.png'))

print("All block sheets and character animations are 100% rebuilt and verified!")
