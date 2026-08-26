import os, glob
import numpy as np
from PIL import Image
from scipy.ndimage import label

# =========================================================================
# 1. FIX CHARACTER SPRITES: Remove stray floating fragments/islands
# =========================================================================
char_dir = r'c:\Users\khang\Documents\Build\Boom\assets\characters'

for root, dirs, files in os.walk(char_dir):
    for fname in files:
        if not fname.endswith('.png'):
            continue
        fpath = os.path.join(root, fname)
        try:
            im = Image.open(fpath).convert('RGBA')
            arr = np.array(im)
            alpha = arr[:, :, 3]
            
            lbl, num = label(alpha > 15)
            if num > 1:
                # Find the main character body (largest connected component)
                sizes = [np.sum(lbl == i) for i in range(1, num + 1)]
                max_comp_idx = np.argmax(sizes) + 1
                
                # Keep main component + any piece attached or close to it; wipe isolated small bottom noise
                main_mask = (lbl == max_comp_idx)
                main_pts = np.where(main_mask)
                main_max_y = main_pts[0].max()
                
                cleaned_alpha = np.zeros_like(alpha)
                for i in range(1, num + 1):
                    pts = np.where(lbl == i)
                    comp_min_y = pts[0].min()
                    # If this piece is isolated far below the main body, remove it
                    if comp_min_y > main_max_y + 4 and sizes[i - 1] < 300:
                        print(f"Removed floating fragment in {os.path.basename(root)}/{fname} (piece {i}, size {sizes[i-1]})")
                    elif sizes[i - 1] <= 3:
                        # 1-3 px stray single pixels
                        pass
                    else:
                        cleaned_alpha[lbl == i] = alpha[lbl == i]
                        
                arr[:, :, 3] = cleaned_alpha
                Image.fromarray(arr).save(fpath)
        except Exception as e:
            print(f"Error processing {fpath}: {e}")

print("Character sprite cleanup complete.")

# =========================================================================
# 2. FIX MAP BLOCKS: Clean up white bars and make 100% solid block textures
# =========================================================================
tilesets_dir = r'c:\Users\khang\Documents\Build\Boom\assets\tilesets'

for tdir in glob.glob(os.path.join(tilesets_dir, '*')):
    if not os.path.isdir(tdir):
        continue
    runtime_dir = os.path.join(tdir, 'runtime')
    if not os.path.exists(runtime_dir):
        continue
        
    for bname in ['hard_block.png', 'soft_block.png']:
        fpath = os.path.join(runtime_dir, bname)
        if not os.path.exists(fpath):
            continue
            
        im = Image.open(fpath).convert('RGBA')
        arr = np.array(im)
        
        # Check for pure white or semi-transparent stripes in the bottom 4 rows (y=36..39)
        # Any pixel with R>240, G>240, B>240 or alpha<255 in bottom rows should take the block texture color from row 35
        for y in range(36, 40):
            for x in range(40):
                r, g, b, a = arr[y, x]
                # If pixel is bright white or was an injected white border
                if (r > 230 and g > 230 and b > 230) or a < 255:
                    # Sample color from row 34 or 35
                    sample_y = 34
                    while sample_y > 0 and arr[sample_y, x, 0] > 230 and arr[sample_y, x, 1] > 230 and arr[sample_y, x, 2] > 230:
                        sample_y -= 1
                    arr[y, x, :3] = arr[sample_y, x, :3]
                    arr[y, x, 3] = 255
                    
        Image.fromarray(arr).save(fpath)
        print(f"Removed white border on {os.path.basename(tdir)}/{bname}")

# Also check maps/tile_wall.png and maps/tile_destructible.png
for mname in ['tile_wall.png', 'tile_destructible.png']:
    mpath = os.path.join(r'c:\Users\khang\Documents\Build\Boom\assets\maps', mname)
    if os.path.exists(mpath):
        im = Image.open(mpath).convert('RGBA')
        arr = np.array(im)
        for y in range(36, 40):
            for x in range(40):
                if (arr[y, x, 0] > 230 and arr[y, x, 1] > 230 and arr[y, x, 2] > 230) or arr[y, x, 3] < 255:
                    arr[y, x, :3] = arr[34, x, :3]
                    arr[y, x, 3] = 255
        Image.fromarray(arr).save(mpath)
        print(f"Removed white border on {mname}")

# =========================================================================
# 3. FIX DECORATIONS: Scale 3x3 Centerpieces to full 120x120 px
# =========================================================================
decorations_dir = r'c:\Users\khang\Documents\Build\Boom\assets\decorations'

center_props = [
    'bubble_fountain.png', 'anchor_rope.png', 'ice_crystal.png',
    'hologram.png', 'toy_house.png', 'ice_monument.png',
    'scarab_monument.png', 'fountain.png', 'desert_tent.png'
]

for ddir in glob.glob(os.path.join(decorations_dir, '*')):
    if not os.path.isdir(tdir):
        continue
    runtime_dir = os.path.join(ddir, 'runtime')
    if not os.path.exists(runtime_dir):
        continue
        
    for fname in center_props:
        fpath = os.path.join(runtime_dir, fname)
        if not os.path.exists(fpath):
            continue
        im = Image.open(fpath).convert('RGBA')
        arr = np.array(im)
        alpha = arr[:, :, 3]
        has_r = np.any(alpha > 15, axis=1)
        has_c = np.any(alpha > 15, axis=0)
        if np.any(has_r) and np.any(has_c):
            ymin, ymax = np.where(has_r)[0][0], np.where(has_r)[0][-1] + 1
            xmin, xmax = np.where(has_c)[0][0], np.where(has_c)[0][-1] + 1
            cropped = im.crop((xmin, ymin, xmax, ymax))
            # Resize centerpiece to full 120x120 (3x3 tiles)
            resized = cropped.resize((120, 120), Image.Resampling.NEAREST)
            resized.save(fpath)
            print(f"Scaled centerpiece {os.path.basename(ddir)}/{fname} to full 3x3 (120x120 px)")

print("All fixes applied successfully!")
