import cv2
import numpy as np
import os
import json
from PIL import Image

CATALOG_PATH = r'C:\Users\khang\Documents\Build\Boom\assets\water_balloons\water_balloon_catalog.json'
IMG_PATH = r'C:\Users\khang\.gemini\antigravity\brain\8d5450db-5a47-4a4a-af37-9aad2b7203db\.user_uploaded\media_1787032639590.jpg'
OUT_BASE = r'C:\Users\khang\Documents\Build\Boom\assets\water_balloons\skins'
CANVAS_SIZE = 128

def generate_wobble_frames(img, skin_id):
    bbox = img.getbbox()
    if bbox:
        img = img.crop(bbox)
        
    w, h = img.size
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
        
    icon_path = os.path.join(skin_dir, "icon.png")
    icon_canvas = Image.new('RGBA', (64, 64), (0,0,0,0))
    res_icon = img.resize((56, 56), Image.Resampling.LANCZOS)
    icon_canvas.paste(res_icon, (4, 4), res_icon)
    icon_canvas.save(icon_path)

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
    # Stack all cells and calculate median across the stack
    stack = np.stack(cells, axis=0)
    bg = np.median(stack, axis=0).astype(np.uint8)
    return bg

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
    
    cell_w = w / grid_cols
    cell_h = h / grid_rows
    
    print("Extracting universal background...")
    bg = extract_background(cv_img, grid_cols, grid_rows, cell_w, cell_h)
    
    skins = catalog.get('skins', [])
    print(f"Re-extracting {len(skins)} skins using exact background subtraction...")
    
    for skin in skins:
        skin_id = skin['id']
        s_row = skin['source_row']
        s_col = skin['source_col']
        
        x1 = int(s_col * cell_w)
        y1 = int(s_row * cell_h)
        x2 = int((s_col + 1) * cell_w)
        y2 = int((s_row + 1) * cell_h)
        
        cell = cv_img[y1:y2, x1:x2]
        
        # Calculate color difference to background
        diff = cv2.absdiff(cell, bg)
        # Convert difference to grayscale to measure magnitude
        gray_diff = cv2.cvtColor(diff, cv2.COLOR_BGR2GRAY)
        
        # Threshold: if difference > 15, it's foreground
        # Smooth the mask to reduce noise
        mask = cv2.GaussianBlur(gray_diff, (3,3), 0)
        _, alpha = cv2.threshold(mask, 15, 255, cv2.THRESH_BINARY)
        
        # Apply morphological operations to clean up small noise and fill holes inside the balloon
        kernel = cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (5,5))
        alpha = cv2.morphologyEx(alpha, cv2.MORPH_CLOSE, kernel)
        alpha = cv2.morphologyEx(alpha, cv2.MORPH_OPEN, kernel)
        
        # Use GrabCut to refine the mask, initialized with our difference mask
        # 0 = bg, 1 = fg, 2 = pr_bg, 3 = pr_fg
        gc_mask = np.where(alpha > 128, 3, 2).astype('uint8')
        
        # Ensure borders are absolute background (since the balloon doesn't touch the edge)
        gc_mask[0:10, :] = 0
        gc_mask[-10:, :] = 0
        gc_mask[:, 0:10] = 0
        gc_mask[:, -10:] = 0
        
        bgdModel = np.zeros((1,65), np.float64)
        fgdModel = np.zeros((1,65), np.float64)
        
        # Run GrabCut using mask
        cv2.grabCut(cell, gc_mask, None, bgdModel, fgdModel, 5, cv2.GC_INIT_WITH_MASK)
        
        # Final mask is where gc_mask is 1 or 3
        final_alpha = np.where((gc_mask==1)|(gc_mask==3), 255, 0).astype('uint8')
        
        # Soften the edges of the mask slightly
        final_alpha = cv2.GaussianBlur(final_alpha, (3,3), 0)
        
        cell_rgba = cv2.cvtColor(cell, cv2.COLOR_BGR2BGRA)
        cell_rgba[:, :, 3] = final_alpha
        
        # Convert to PIL
        result_rgb = cv2.cvtColor(cell_rgba, cv2.COLOR_BGRA2RGBA)
        pil_img = Image.fromarray(result_rgb)
        
        generate_wobble_frames(pil_img, skin_id)
        
    print("Done re-extracting with background subtraction!")

if __name__ == '__main__':
    main()
