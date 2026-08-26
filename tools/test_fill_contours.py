import cv2
import numpy as np
import os
import json

CATALOG_PATH = r'C:\Users\khang\Documents\Build\Boom\assets\water_balloons\water_balloon_catalog.json'
IMG_PATH = r'C:\Users\khang\.gemini\antigravity\brain\8d5450db-5a47-4a4a-af37-9aad2b7203db\.user_uploaded\media_1787032639590.jpg'
OUT_PATH = r'C:\Users\khang\Documents\Build\Boom\tools\test_fill_contours.jpg'

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

def process_cell(cell, bg):
    diff = cv2.absdiff(cell, bg)
    gray_diff = cv2.cvtColor(diff, cv2.COLOR_BGR2GRAY)
    
    # Threshold: higher to avoid JPEG noise
    _, thresh = cv2.threshold(gray_diff, 20, 255, cv2.THRESH_BINARY)
    
    # Morphological operations to clean up
    kernel = cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (3,3))
    thresh = cv2.morphologyEx(thresh, cv2.MORPH_OPEN, kernel) # Remove tiny noise
    
    # Connect slightly disconnected parts (like the knot)
    kernel_close = cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (7,7))
    thresh = cv2.morphologyEx(thresh, cv2.MORPH_CLOSE, kernel_close)
    
    # Find contours
    contours, _ = cv2.findContours(thresh, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
    
    if not contours:
        return np.zeros_like(gray_diff)
        
    # Find the largest contour
    largest_contour = max(contours, key=cv2.contourArea)
    
    # Create new mask and fill it
    mask = np.zeros_like(gray_diff)
    cv2.drawContours(mask, [largest_contour], -1, 255, thickness=cv2.FILLED)
    
    # Smooth the edges
    mask = cv2.GaussianBlur(mask, (5,5), 0)
    
    # Create output cell with pink background to easily see transparency
    out_cell = np.full_like(cell, (200, 100, 255)) # Pink
    
    # Blend
    alpha = mask.astype(float) / 255.0
    for c in range(3):
        out_cell[:,:,c] = cell[:,:,c] * alpha + out_cell[:,:,c] * (1 - alpha)
        
    return out_cell

def main():
    with open(CATALOG_PATH, 'r', encoding='utf-8') as f:
        catalog = json.load(f)
        
    grid_cols = catalog['grid']['columns']
    grid_rows = catalog['grid']['rows']
    
    cv_img = cv2.imread(IMG_PATH, cv2.IMREAD_COLOR)
    h, w = cv_img.shape[:2]
    
    cell_w = w / grid_cols
    cell_h = h / grid_rows
    
    bg = extract_background(cv_img, grid_cols, grid_rows, cell_w, cell_h)
    
    # We will assemble a grid to see all results
    out_img = np.zeros_like(cv_img)
    
    skins = catalog.get('skins', [])
    for skin in skins:
        s_row = skin['source_row']
        s_col = skin['source_col']
        
        x1 = int(s_col * cell_w)
        y1 = int(s_row * cell_h)
        x2 = int((s_col + 1) * cell_w)
        y2 = int((s_row + 1) * cell_h)
        
        cell = cv_img[y1:y2, x1:x2]
        processed = process_cell(cell, bg)
        out_img[y1:y2, x1:x2] = processed
        
    cv2.imwrite(OUT_PATH, out_img)
    print("Saved test grid to", OUT_PATH)

if __name__ == '__main__':
    main()
