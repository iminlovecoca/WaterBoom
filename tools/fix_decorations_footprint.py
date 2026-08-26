import os, glob
import numpy as np
from PIL import Image

decorations_dir = r'c:\Users\khang\Documents\Build\Boom\assets\decorations'

# All centerpieces (2x2 = 80x80) and corner props (1x1 = 40x40)
center_props = [
    'bubble_fountain.png', 'anchor_rope.png', 'ice_crystal.png',
    'hologram.png', 'toy_house.png', 'ice_monument.png',
    'scarab_monument.png', 'fountain.png', 'desert_tent.png'
]

hedge_props = ['toy_hedge.png'] # 2x2 = 80x80

for ddir in glob.glob(os.path.join(decorations_dir, '*')):
    if not os.path.isdir(ddir):
        continue
    runtime_dir = os.path.join(ddir, 'runtime')
    if not os.path.exists(runtime_dir):
        continue
        
    for f in glob.glob(os.path.join(runtime_dir, '*.png')):
        fname = os.path.basename(f)
        im = Image.open(f).convert('RGBA')
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
        
        cropped = im.crop((xmin, ymin, xmax, ymax))
        
        # Determine target size
        if fname in center_props or fname in hedge_props:
            target_size = (80, 80) # Full 2x2 tiles
        else:
            target_size = (40, 40) # Full 1x1 tile
            
        resized = cropped.resize(target_size, Image.Resampling.NEAREST)
        resized.save(f)
        print(f"Tight-cropped and scaled {os.path.basename(ddir)}/{fname} from {xmax-xmin}x{ymax-ymin} to {target_size} (0 padding).")

print("All decorations now cover 100% of their footprint with 0 false gaps!")
