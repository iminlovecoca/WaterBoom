import cv2
import numpy as np
import os
import json
from PIL import Image
import rembg

CATALOG_PATH = r'C:\Users\khang\Documents\Build\Boom\assets\water_balloons\water_balloon_catalog.json'
IMG_PATH = r'C:\Users\khang\.gemini\antigravity\brain\8d5450db-5a47-4a4a-af37-9aad2b7203db\.user_uploaded\media_1787032639590.jpg'
OUT_BASE = r'C:\Users\khang\Documents\Build\Boom\assets\water_balloons\skins'
CANVAS_SIZE = 128

def extract_background(cv_img, grid_cols, grid_rows, cell_w, cell_h):
    cells = []
    for r in range(grid_rows):
        for c in range(grid_cols):
            x1 = int(c * cell_w)
            y1 = int(r * cell_h)
            x2 = int((c + 1) * cell_w)
            y2 = int((r + 1) * cell_h)
            cell = cv_img[y1:y2, x1:x2]
            cells.append(cell)
    stack = np.stack(cells, axis=0)
    bg = np.median(stack, axis=0).astype(np.uint8)
    return bg

def generate_wobble_frames(img, skin_id):
    w, h = img.size
    new_w = int(w * 0.85)
    new_h = int(h * 0.85)
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
        fw = int(new_w * frame['sx'])
        fh = int(new_h * frame['sy'])
        res = img.resize((fw, fh), Image.Resampling.LANCZOS)
        
        canvas = Image.new('RGBA', (CANVAS_SIZE, CANVAS_SIZE), (0, 0, 0, 0))
        cx = (CANVAS_SIZE - fw) // 2
        cy = (CANVAS_SIZE - fh) // 2 + frame['dy']
        
        canvas.paste(res, (cx, cy), res)
        out_path = os.path.join(skin_dir, f"idle_{i}.png")
        canvas.save(out_path)
        
    icon_path = os.path.join(skin_dir, "icon.png")
    icon_canvas = Image.new('RGBA', (64, 64), (0,0,0,0))
    res_icon = img.resize((56, 56), Image.Resampling.LANCZOS)
    icon_canvas.paste(res_icon, (4, 4), res_icon)
    icon_canvas.save(icon_path)

def main():
    if not os.path.exists(IMG_PATH):
        print("Image not found")
        return
        
    with open(CATALOG_PATH, 'r', encoding='utf-8') as f:
        catalog = json.load(f)
        
    grid_cols = catalog['grid']['columns']
    grid_rows = catalog['grid']['rows']
    
    cv_img = cv2.imread(IMG_PATH, cv2.IMREAD_COLOR)
    h, w = cv_img.shape[:2]
    
    cell_w = int(w / grid_cols)
    cell_h = int(h / grid_rows)
    
    bg = extract_background(cv_img, grid_cols, grid_rows, cell_w, cell_h)
    
    Y, X = np.ogrid[:cell_h, :cell_w]
    dist_from_center = np.sqrt((X - cell_w/2)**2 + (Y - cell_h/2)**2)
    
    print("Processing entire 1024x1024 image with rembg...")
    with open(IMG_PATH, 'rb') as f:
        img_bytes = f.read()
    
    out_bytes = rembg.remove(img_bytes)
    nparr = np.frombuffer(out_bytes, np.uint8)
    out_bgra = cv2.imdecode(nparr, cv2.IMREAD_UNCHANGED)
    
    skins = catalog.get('skins', [])
    print("Slicing and cleaning 62 skins...")
    
    for skin in skins:
        skin_id = skin['id']
        s_row = skin['source_row']
        s_col = skin['source_col']
        
        x1 = s_col * cell_w
        y1 = s_row * cell_h
        x2 = (s_col + 1) * cell_w
        y2 = (s_row + 1) * cell_h
        
        cell = cv_img[y1:y2, x1:x2]
        cell_bgra = out_bgra[y1:y2, x1:x2].copy()
        alpha = cell_bgra[:, :, 3]
        
        diff = cv2.absdiff(cell, bg)
        gray_diff = cv2.cvtColor(diff, cv2.COLOR_BGR2GRAY)
        gray_diff = cv2.GaussianBlur(gray_diff, (3,3), 0)
        
        # Pixels that match the checkerboard background
        bg_matches = gray_diff < 20
        
        # Delete pixels that match background AND are far from center (to preserve highlights)
        # Distance > 45 protects the core 90x90 area of the balloon and knot
        to_delete = bg_matches & (dist_from_center > 45)
        
        alpha[to_delete] = 0
        
        result_rgb = cv2.cvtColor(cell_bgra, cv2.COLOR_BGRA2RGBA)
        pil_img = Image.fromarray(result_rgb)
        
        generate_wobble_frames(pil_img, skin_id)
        
    print("Done generating perfect balloons!")

if __name__ == '__main__':
    main()
