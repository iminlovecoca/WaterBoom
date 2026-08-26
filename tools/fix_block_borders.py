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
        
        # Ensure 40x40
        if im.size != (40, 40):
            arr = np.array(im.resize((40, 40), Image.Resampling.NEAREST))
            
        # Fix transparent/semi-transparent pixels at bottom/borders
        # For block textures, alpha should be 100% solid (255) across the entire 40x40 tile
        # If any pixel has alpha < 255, fill with neighboring solid color or set alpha to 255
        for y in range(40):
            for x in range(40):
                if arr[y, x, 3] < 255:
                    if arr[y, x, 3] > 0:
                        # Semi-transparent pixel: make it fully opaque
                        arr[y, x, 3] = 255
                    else:
                        # Completely transparent pixel: copy color from nearest solid pixel above
                        sample_y = max(0, y - 1)
                        while sample_y > 0 and arr[sample_y, x, 3] == 0:
                            sample_y -= 1
                        arr[y, x, :3] = arr[sample_y, x, :3]
                        arr[y, x, 3] = 255
                        
        fixed_im = Image.fromarray(arr)
        fixed_im.save(fpath)
        print(f"Fixed opaque borders for {os.path.basename(tdir)}/{bname}")

# Also fix maps/tile_wall.png and maps/tile_destructible.png
for mname in ['tile_wall.png', 'tile_destructible.png']:
    mpath = os.path.join(r'c:\Users\khang\Documents\Build\Boom\assets\maps', mname)
    if os.path.exists(mpath):
        im = Image.open(mpath).convert('RGBA')
        arr = np.array(im)
        arr[:, :, 3] = 255
        Image.fromarray(arr).save(mpath)
        print(f"Fixed {mname} to 100% solid opaque.")

print("All block textures across all maps are now 100% solid with 0 border leakage!")
