import cv2
import numpy as np
import os
import json
from PIL import Image

IMG_PATH = r'C:\Users\khang\.gemini\antigravity\brain\8d5450db-5a47-4a4a-af37-9aad2b7203db\.user_uploaded\media_1787049589938.png'
OUT_BASE = r'C:\Users\khang\Documents\Build\Boom\assets\water_balloons\skins'
CANVAS_SIZE = 128
TARGET_BALLOON_SIZE = 96
SKIN_ID = 'skin_063'

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
    if not os.path.exists(IMG_PATH):
        print(f"Image not found at {IMG_PATH}")
        return
        
    pil_img = Image.open(IMG_PATH).convert('RGBA')
    
    # Auto-crop the balloon
    bbox = pil_img.getbbox()
    if bbox:
        pil_img = pil_img.crop(bbox)
        
    generate_wobble_frames(pil_img, SKIN_ID)
    print(f"Successfully generated {SKIN_ID} frames!")

if __name__ == '__main__':
    main()
