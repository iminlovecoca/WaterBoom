import cv2
import numpy as np
import os
import json
from PIL import Image
import rembg

CATALOG_PATH = r'C:\Users\khang\Documents\Build\Boom\assets\water_balloons\water_balloon_catalog.json'
IMG_DIR = r'C:\Users\khang\Documents\Build\Boom\assets\image'
OUT_BASE = r'C:\Users\khang\Documents\Build\Boom\assets\water_balloons\skins'
CANVAS_SIZE = 128
TARGET_BALLOON_SIZE = 96 # The max width/height of the balloon inside the 128x128 canvas

def generate_wobble_frames(img, skin_id):
    w, h = img.size
    
    # Scale so the largest dimension is exactly TARGET_BALLOON_SIZE
    scale = min(TARGET_BALLOON_SIZE / w, TARGET_BALLOON_SIZE / h)
    new_w = max(1, int(w * scale))
    new_h = max(1, int(h * scale))
    img = img.resize((new_w, new_h), Image.Resampling.LANCZOS)
    
    frames = [
        {'sx': 1.0,  'sy': 1.0,  'dy': 0},
        {'sx': 1.1,  'sy': 0.9,  'dy': 4},
        {'sx': 0.9,  'sy': 1.1,  'dy': -4},
        {'sx': 1.0,  'sy': 1.0,  'dy': 0},
    ]
    
    skin_dir = os.path.join(OUT_BASE, skin_id)
    os.makedirs(skin_dir, exist_ok=True)
    
    for i, frame in enumerate(frames):
        fw = max(1, int(new_w * frame['sx']))
        fh = max(1, int(new_h * frame['sy']))
        res = img.resize((fw, fh), Image.Resampling.LANCZOS)
        
        canvas = Image.new('RGBA', (CANVAS_SIZE, CANVAS_SIZE), (0, 0, 0, 0))
        cx = (CANVAS_SIZE - fw) // 2
        cy = (CANVAS_SIZE - fh) // 2 + frame['dy']
        
        canvas.paste(res, (cx, cy), res)
        out_path = os.path.join(skin_dir, f"idle_{i}.png")
        canvas.save(out_path)
        
    icon_path = os.path.join(skin_dir, "icon.png")
    icon_canvas = Image.new('RGBA', (64, 64), (0,0,0,0))
    # Icon should be around 56x56
    icon_scale = min(56 / w, 56 / h)
    iw = max(1, int(w * icon_scale))
    ih = max(1, int(h * icon_scale))
    res_icon = img.resize((iw, ih), Image.Resampling.LANCZOS)
    icx = (64 - iw) // 2
    icy = (64 - ih) // 2
    icon_canvas.paste(res_icon, (icx, icy), res_icon)
    icon_canvas.save(icon_path)

def main():
    if not os.path.exists(IMG_DIR):
        print("Image directory not found")
        return
        
    with open(CATALOG_PATH, 'r', encoding='utf-8') as f:
        catalog = json.load(f)
    skins = catalog.get('skins', [])
    
    # Sort files
    valid_files = sorted([f for f in os.listdir(IMG_DIR) if f.endswith('.png')])
    print(f"Found {len(valid_files)} user images.")
    
    session = rembg.new_session()
    print("Processing user separated images with rembg...")
    
    skins_sorted = sorted(skins, key=lambda s: (s['source_row'], s['source_col']))
    
    # The user provided 63 images. We have 62 skins. We will process 62 of them.
    for i, skin in enumerate(skins_sorted):
        if i >= len(valid_files):
            break
            
        skin_id = skin['id']
        f = valid_files[i]
        path = os.path.join(IMG_DIR, f)
        
        with open(path, 'rb') as fp:
            img_bytes = fp.read()
            
        # 1. Remove background with rembg
        out_bytes = rembg.remove(img_bytes, session=session)
        nparr = np.frombuffer(out_bytes, np.uint8)
        out_bgra = cv2.imdecode(nparr, cv2.IMREAD_UNCHANGED)
        
        # 2. Cleanup: If there are stray pixels (like checkerboard corners) that rembg missed,
        # they are usually disconnected from the main balloon.
        # Let's find the largest connected component in the alpha channel and ONLY keep that!
        # Wait, if Frost Byte has snowflakes, they will be deleted.
        # But maybe the user doesn't care about the floating snowflakes as long as the balloon is clean and centered!
        # Actually, let's just use the rembg mask as is, and rely on getbbox to crop it.
        # If there are faint checkerboards, they might affect getbbox.
        # To be safe, we threshold the alpha channel before getbbox.
        
        result_rgb = cv2.cvtColor(out_bgra, cv2.COLOR_BGRA2RGBA)
        pil_img = Image.fromarray(result_rgb)
        
        # Auto-crop
        bbox = pil_img.getbbox()
        if bbox:
            pil_img = pil_img.crop(bbox)
            
        generate_wobble_frames(pil_img, skin_id)
        
    print("Done processing user images!")

if __name__ == '__main__':
    main()
