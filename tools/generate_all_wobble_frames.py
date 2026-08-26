import os
import glob
from PIL import Image

RAW_DIR = r'C:\Users\khang\Documents\Build\Boom\assets\water_balloon\raw_extracted'
OUT_DIR = r'C:\Users\khang\Documents\Build\Boom\assets\water_balloon'
CANVAS_SIZE = 128

def generate_wobble(image_path, skin_name):
    img = Image.open(image_path).convert('RGBA')
    
    # Optional: crop the empty transparent space tightly to get the true balloon dimensions
    bbox = img.getbbox()
    if bbox:
        img = img.crop(bbox)
        
    # Resize the balloon to fit within a ~90x90 box so it has room to wobble
    # The original masters were around 1254x1254, but here they are extracted from a ~113x128 cell
    # So they are already small. We just scale them proportionally so max dimension is 90.
    w, h = img.size
    scale = 90 / max(w, h)
    new_w = int(w * scale)
    new_h = int(h * scale)
    img = img.resize((new_w, new_h), Image.Resampling.LANCZOS)
    
    # 4 frames:
    # 0: idle
    # 1: tension/squish (wider, shorter, moving down)
    # 2: elastic rebound (narrower, taller, moving up)
    # 3: returning to idle
    
    frames = [
        {'sx': 1.0,  'sy': 1.0,  'dy': 0},
        {'sx': 1.15, 'sy': 0.85, 'dy': 4},
        {'sx': 0.9,  'sy': 1.1,  'dy': -4},
        {'sx': 1.0,  'sy': 1.0,  'dy': 0},
    ]
    
    for i, frame in enumerate(frames):
        fw = int(new_w * frame['sx'])
        fh = int(new_h * frame['sy'])
        res = img.resize((fw, fh), Image.Resampling.LANCZOS)
        
        canvas = Image.new('RGBA', (CANVAS_SIZE, CANVAS_SIZE), (0, 0, 0, 0))
        cx = (CANVAS_SIZE - fw) // 2
        cy = (CANVAS_SIZE - fh) // 2 + frame['dy']
        
        canvas.paste(res, (cx, cy), res)
        
        out_path = os.path.join(OUT_DIR, f"{skin_name}_{i}.png")
        canvas.save(out_path)

def main():
    if not os.path.exists(RAW_DIR):
        print(f"Raw directory not found: {RAW_DIR}")
        return
        
    files = glob.glob(os.path.join(RAW_DIR, '*.png'))
    files.sort()
    
    if not files:
        print("No raw extracted balloons found.")
        return
        
    print(f"Generating VFX frames for {len(files)} balloons...")
    
    # Start numbering from 005 since 001-004 are currently used
    start_idx = 5
    for i, file_path in enumerate(files):
        skin_name = f"skin_{start_idx + i:03d}"
        generate_wobble(file_path, skin_name)
        
    print(f"Finished generating VFX frames up to skin_{start_idx + len(files) - 1:03d}.")

if __name__ == '__main__':
    main()
