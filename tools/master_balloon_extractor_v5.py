import cv2
import numpy as np
import os
import json
from PIL import Image, ImageDraw
import rembg

CATALOG_PATH = r'C:\Users\khang\Documents\Build\Boom\assets\water_balloons\water_balloon_catalog.json'
IMG_PATH = r'C:\Users\khang\.gemini\antigravity\brain\8d5450db-5a47-4a4a-af37-9aad2b7203db\.user_uploaded\media_1787032639590.jpg'
OUT_BASE = r'C:\Users\khang\Documents\Build\Boom\assets\water_balloons\skins'
CANVAS_SIZE = 128

def create_circular_mask(h, w, center=None, radius=None):
    if center is None: # use the middle of the image
        center = (int(w/2), int(h/2))
    if radius is None: # use the smallest distance between the center and image walls
        radius = min(center[0], center[1], w-center[0], h-center[1])
        
    Y, X = np.ogrid[:h, :w]
    dist_from_center = np.sqrt((X - center[0])**2 + (Y-center[1])**2)
    
    mask = np.zeros((h, w), dtype=np.uint8)
    # Give it a soft edge
    mask[dist_from_center <= radius] = 255
    # Smooth the mask
    mask = cv2.GaussianBlur(mask, (5,5), 0)
    return mask

def generate_wobble_frames(img, skin_id):
    # NO getbbox()! We trust the original grid layout and AI mask.
    # The balloons are naturally about 110x110 in the 128x128 cell.
    # We will just scale them slightly to fit our standard size.
    # Let's scale down by 0.85 to give breathing room for wobble
    w, h = img.size
    new_w = int(w * 0.85)
    new_h = int(h * 0.85)
    img = img.resize((new_w, new_h), Image.Resampling.LANCZOS)
    
    frames = [
        {'sx': 1.0,  'sy': 1.0,  'dy': 0},
        {'sx': 1.1, 'sy': 0.9, 'dy': 4},
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
        
    # Generate icon
    icon_path = os.path.join(skin_dir, "icon.png")
    icon_canvas = Image.new('RGBA', (64, 64), (0,0,0,0))
    # Icon should be centered
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
    
    # Create circular mask of radius 58 to clip corners
    circ_mask = create_circular_mask(cell_h, cell_w, radius=56)
    
    skins = catalog.get('skins', [])
    
    print("Extracting using rembg + circular masking...")
    # Initialize rembg session to reuse it
    session = rembg.new_session()
    
    for skin in skins:
        skin_id = skin['id']
        s_row = skin['source_row']
        s_col = skin['source_col']
        
        x1 = s_col * cell_w
        y1 = s_row * cell_h
        x2 = (s_col + 1) * cell_w
        y2 = (s_row + 1) * cell_h
        
        cell = cv_img[y1:y2, x1:x2]
        
        # Convert to RGB for rembg
        cell_rgb = cv2.cvtColor(cell, cv2.COLOR_BGR2RGB)
        
        # Run rembg
        out_rgba = rembg.remove(cell_rgb, session=session)
        
        # Convert to BGRA for opencv processing
        out_bgra = cv2.cvtColor(out_rgba, cv2.COLOR_RGBA2BGRA)
        
        # Apply circular mask to alpha channel to force corners to be transparent!
        # This completely solves the "checkerboard in corners" issue for Cow/Frost Byte!
        out_bgra[:, :, 3] = cv2.bitwise_and(out_bgra[:, :, 3], circ_mask)
        
        # Convert back to PIL
        result_rgb = cv2.cvtColor(out_bgra, cv2.COLOR_BGRA2RGBA)
        pil_img = Image.fromarray(result_rgb)
        
        generate_wobble_frames(pil_img, skin_id)
        
    print("Done re-extracting with rembg + circular masking!")

if __name__ == '__main__':
    main()
