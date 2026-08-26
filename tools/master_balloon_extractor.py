import os
import json
import cv2
import numpy as np
from PIL import Image

try:
    from rembg import remove
except ImportError:
    remove = None

CATALOG_PATH = r'C:\Users\khang\Documents\Build\Boom\assets\water_balloons\water_balloon_catalog.json'
IMG_PATH = r'C:\Users\khang\.gemini\antigravity\brain\8d5450db-5a47-4a4a-af37-9aad2b7203db\.user_uploaded\media_1787032639590.jpg'
OUT_BASE = r'C:\Users\khang\Documents\Build\Boom\assets\water_balloons\skins'
CANVAS_SIZE = 128

def generate_wobble_frames(img, skin_id):
    # Determine tight bbox to center the balloon
    bbox = img.getbbox()
    if bbox:
        img = img.crop(bbox)
        
    w, h = img.size
    # Scale to ~90px max to leave room for wobble
    scale = 90 / max(w, h)
    new_w = int(w * scale)
    new_h = int(h * scale)
    img = img.resize((new_w, new_h), Image.Resampling.LANCZOS)
    
    frames = [
        {'sx': 1.0,  'sy': 1.0,  'dy': 0},
        {'sx': 1.15, 'sy': 0.85, 'dy': 4},
        {'sx': 0.9,  'sy': 1.1,  'dy': -4},
        {'sx': 1.0,  'sy': 1.0,  'dy': 0},
    ]
    
    skin_dir = os.path.join(OUT_BASE, skin_id)
    os.makedirs(skin_dir, exist_ok=True)
    
    for i, frame in enumerate(frames):
        fw = int(new_w * frame['sx'])
        fh = int(new_h * frame['sy'])
        res = img.resize((fw, fh), Image.Resampling.LANCZOS)
        
        canvas = Image.new('RGBA', (CANVAS_SIZE, CANVAS_SIZE), (0, 0, 0, 0))
        cx = (CANVAS_SIZE - fw) // 2
        cy = (CANVAS_SIZE - fh) // 2 + frame['dy']
        
        canvas.paste(res, (cx, cy), res)
        out_path = os.path.join(skin_dir, f"idle_{i}.png")
        canvas.save(out_path)
        
    # Also save the first frame as icon
    icon_path = os.path.join(skin_dir, "icon.png")
    frames[0] = {'sx': 1.0, 'sy': 1.0, 'dy': 0} # reset just in case
    # For icon, crop it tight and save
    icon_canvas = Image.new('RGBA', (64, 64), (0,0,0,0))
    res_icon = img.resize((56, 56), Image.Resampling.LANCZOS)
    icon_canvas.paste(res_icon, (4, 4), res_icon)
    icon_canvas.save(icon_path)

def main():
    if not os.path.exists(IMG_PATH):
        print("Image not found")
        return
        
    if remove is None:
        print("rembg is not installed. Please install it.")
        return
        
    with open(CATALOG_PATH, 'r', encoding='utf-8') as f:
        catalog = json.load(f)
        
    grid_cols = catalog['grid']['columns']
    grid_rows = catalog['grid']['rows']
    
    # We must read with OpenCV to use rembg efficiently, then convert to PIL
    cv_img = cv2.imread(IMG_PATH, cv2.IMREAD_UNCHANGED)
    h, w = cv_img.shape[:2]
    
    cell_w = w / grid_cols
    cell_h = h / grid_rows
    
    skins = catalog.get('skins', [])
    print(f"Extracting {len(skins)} skins from {grid_cols}x{grid_rows} grid...")
    
    for skin in skins:
        skin_id = skin['id']
        s_row = skin['source_row']
        s_col = skin['source_col']
        
        # Calculate cell bounds
        x1 = int(s_col * cell_w)
        y1 = int(s_row * cell_h)
        x2 = int((s_col + 1) * cell_w)
        y2 = int((s_row + 1) * cell_h)
        
        # Crop cell
        cell = cv_img[y1:y2, x1:x2]
        
        # Remove background using rembg
        cell_rgba = cv2.cvtColor(cell, cv2.COLOR_BGR2BGRA)
        success, encoded_img = cv2.imencode('.png', cell_rgba)
        if not success:
            continue
            
        output_bytes = remove(encoded_img.tobytes())
        nparr = np.frombuffer(output_bytes, np.uint8)
        result_img = cv2.imdecode(nparr, cv2.IMREAD_UNCHANGED)
        
        # Convert back to PIL for VFX generation
        result_rgb = cv2.cvtColor(result_img, cv2.COLOR_BGRA2RGBA)
        pil_img = Image.fromarray(result_rgb)
        
        generate_wobble_frames(pil_img, skin_id)
        print(f"Extracted and generated VFX for {skin_id}")
        
    print("Done!")

if __name__ == '__main__':
    main()
