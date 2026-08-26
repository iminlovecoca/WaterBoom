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
TARGET_BALLOON_SIZE = 96
SLOT_SIZE = 150

def generate_wobble_frames(img, skin_id):
    w, h = img.size
    
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
    
    valid_files = sorted([f for f in os.listdir(IMG_DIR) if f.endswith('.png')])
    print(f"Found {len(valid_files)} user images.")
    
    images = []
    for f in valid_files:
        path = os.path.join(IMG_DIR, f)
        img = cv2.imread(path, cv2.IMREAD_COLOR)
        images.append(img)
        
    cols = 8
    rows = (len(valid_files) + cols - 1) // cols
    
    # We create a large white canvas to tile the images
    # because rembg might use the white background better
    grid_img = np.full((rows * SLOT_SIZE, cols * SLOT_SIZE, 3), 255, dtype=np.uint8)
    
    for i, img in enumerate(images):
        r = i // cols
        c = i % cols
        h, w = img.shape[:2]
        # center in the slot
        dy = (SLOT_SIZE - h) // 2
        dx = (SLOT_SIZE - w) // 2
        grid_img[r*SLOT_SIZE+dy:r*SLOT_SIZE+dy+h, c*SLOT_SIZE+dx:c*SLOT_SIZE+dx+w] = img
        
    print("Sending large grid to rembg...")
    _, encoded = cv2.imencode('.png', grid_img)
    img_bytes = encoded.tobytes()
    
    out_bytes = rembg.remove(img_bytes)
    nparr = np.frombuffer(out_bytes, np.uint8)
    out_bgra = cv2.imdecode(nparr, cv2.IMREAD_UNCHANGED)
    
    print("Slicing and cleaning up...")
    skins_sorted = sorted(skins, key=lambda s: (s['source_row'], s['source_col']))
    
    for i, skin in enumerate(skins_sorted):
        if i >= len(valid_files):
            break
            
        skin_id = skin['id']
        f = valid_files[i]
        
        r = i // cols
        c = i % cols
        
        h, w = images[i].shape[:2]
        dy = (SLOT_SIZE - h) // 2
        dx = (SLOT_SIZE - w) // 2
        
        # Extract the exact crop we pasted
        cell_bgra = out_bgra[r*SLOT_SIZE+dy:r*SLOT_SIZE+dy+h, c*SLOT_SIZE+dx:c*SLOT_SIZE+dx+w].copy()
        
        result_rgb = cv2.cvtColor(cell_bgra, cv2.COLOR_BGRA2RGBA)
        pil_img = Image.fromarray(result_rgb)
        
        # Auto-crop the balloon
        bbox = pil_img.getbbox()
        if bbox:
            pil_img = pil_img.crop(bbox)
            
        generate_wobble_frames(pil_img, skin_id)
        
    print("Done processing fast!")

if __name__ == '__main__':
    main()
