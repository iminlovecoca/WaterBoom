import cv2
import numpy as np
import os
import json
from PIL import Image
import rembg

CATALOG_PATH = r'C:\Users\khang\Documents\Build\Boom\assets\water_balloons\water_balloon_catalog.json'
IMG_PATH = r'C:\Users\khang\.gemini\antigravity\brain\8d5450db-5a47-4a4a-af37-9aad2b7203db\.user_uploaded\media_1787032639590.jpg'
OUT_PATH = r'C:\Users\khang\Documents\Build\Boom\tools\test_rembg_diff.png'

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

def main():
    with open(CATALOG_PATH, 'r', encoding='utf-8') as f:
        catalog = json.load(f)
        
    cv_img = cv2.imread(IMG_PATH, cv2.IMREAD_COLOR)
    h, w = cv_img.shape[:2]
    
    grid_cols = catalog['grid']['columns']
    grid_rows = catalog['grid']['rows']
    cell_w = int(w / grid_cols)
    cell_h = int(h / grid_rows)
    
    bg = extract_background(cv_img, grid_cols, grid_rows, cell_w, cell_h)
    
    session = rembg.new_session()
    
    Y, X = np.ogrid[:cell_h, :cell_w]
    dist_from_center = np.sqrt((X - cell_w/2)**2 + (Y - cell_h/2)**2)
    
    # Test on Frost Byte (skin_040, source_row: 4, source_col: 6)
    # Test on Cow (skin_024, source_row: 2, source_col: 7)
    test_skins = [(4, 6), (2, 7), (0, 0)]
    
    out_cells = []
    
    for r, c in test_skins:
        x1 = c * cell_w
        y1 = r * cell_h
        x2 = (c + 1) * cell_w
        y2 = (r + 1) * cell_h
        
        cell = cv_img[y1:y2, x1:x2]
        
        # 1. Get rembg mask
        cell_rgb = cv2.cvtColor(cell, cv2.COLOR_BGR2RGB)
        out_rgba = rembg.remove(cell_rgb, session=session)
        alpha = out_rgba[:, :, 3].copy()
        
        # 2. Get difference mask
        diff = cv2.absdiff(cell, bg)
        gray_diff = cv2.cvtColor(diff, cv2.COLOR_BGR2GRAY)
        
        # Smooth difference to avoid noise
        gray_diff = cv2.GaussianBlur(gray_diff, (3,3), 0)
        
        # Pixels that match background (diff < 20)
        bg_matches = gray_diff < 20
        
        # Pixels to delete: matches bg AND is far from center
        to_delete = bg_matches & (dist_from_center > 40)
        
        # Apply deletion
        alpha[to_delete] = 0
        
        # Optionally, keep only the largest connected component to remove completely detached noise
        # But for Frost Byte, snowflakes might be detached. Let's see without CC first.
        
        out_cell = cv2.cvtColor(cell, cv2.COLOR_BGR2BGRA)
        out_cell[:, :, 3] = alpha
        out_cells.append(out_cell)
        
    res = np.hstack(out_cells)
    cv2.imwrite(OUT_PATH, res)
    print("Saved test image to", OUT_PATH)

if __name__ == '__main__':
    main()
