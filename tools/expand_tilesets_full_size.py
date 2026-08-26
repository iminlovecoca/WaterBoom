import os, glob
import numpy as np
from PIL import Image

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
        alpha = arr[:, :, 3]
        
        has_r = np.any(alpha > 15, axis=1)
        has_c = np.any(alpha > 15, axis=0)
        
        if not np.any(has_r) or not np.any(has_c):
            continue
            
        ymin = np.where(has_r)[0][0]
        ymax = np.where(has_r)[0][-1] + 1
        xmin = np.where(has_c)[0][0]
        xmax = np.where(has_c)[0][-1] + 1
        
        # Crop tight content
        cropped = im.crop((xmin, ymin, xmax, ymax))
        
        # Resize to full 40x40 square so it fills the grid cell completely with zero gaps
        resized = cropped.resize((40, 40), Image.Resampling.NEAREST)
        resized.save(fpath)
        print(f"Expanded {os.path.basename(tdir)}/{bname} from {xmax-xmin}x{ymax-ymin} to full 40x40.")

# Also check default maps/tile_wall.png and maps/tile_destructible.png
for mname in ['tile_wall.png', 'tile_destructible.png']:
    mpath = os.path.join(r'c:\Users\khang\Documents\Build\Boom\assets\maps', mname)
    if os.path.exists(mpath):
        im = Image.open(mpath).convert('RGBA')
        arr = np.array(im)
        alpha = arr[:, :, 3]
        has_r = np.any(alpha > 15, axis=1)
        has_c = np.any(alpha > 15, axis=0)
        if np.any(has_r) and np.any(has_c):
            ymin, ymax = np.where(has_r)[0][0], np.where(has_r)[0][-1] + 1
            xmin, xmax = np.where(has_c)[0][0], np.where(has_c)[0][-1] + 1
            cropped = im.crop((xmin, ymin, xmax, ymax))
            resized = cropped.resize((40, 40), Image.Resampling.NEAREST)
            resized.save(mpath)
            print(f"Expanded maps/{mname} to 40x40.")

print("All blocks are now full-size (40x40) with 0 gaps!")
