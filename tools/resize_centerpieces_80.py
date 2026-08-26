import os, glob
from PIL import Image
import numpy as np

ROOT = r'c:\Users\khang\Documents\Build\Boom'
decorations_dir = os.path.join(ROOT, 'assets', 'decorations')

center_props = [
    'bubble_fountain.png', 'anchor_rope.png', 'ice_crystal.png',
    'hologram.png', 'toy_house.png', 'ice_monument.png',
    'scarab_monument.png', 'fountain.png', 'desert_tent.png'
]

for ddir in glob.glob(os.path.join(decorations_dir, '*')):
    if not os.path.isdir(ddir):
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
            resized = cropped.resize((80, 80), Image.Resampling.NEAREST)
            resized.save(fpath)
            print(f"Resized centerpiece {os.path.basename(ddir)}/{fname} to 80x80 (2x2)")

print("Centerpiece resizing complete!")
