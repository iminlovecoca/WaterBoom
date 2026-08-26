import os
import math
from PIL import Image, ImageDraw, ImageFilter
import numpy as np

ROOT = r'c:\Users\khang\Documents\Build\Boom'
DEV_DIR = os.path.join(ROOT, 'development')
BALLOON_BASE = os.path.join(ROOT, 'assets', 'water_balloons')
LEGACY_WB = os.path.join(ROOT, 'assets', 'water_balloon')

# Mapping of the 4 iconic official Crazy Arcade balloon models
OFFICIAL_MODELS = {
    "default": os.path.join(DEV_DIR, "extracted_im2_r0_c0.png"),     # Official Classic Blue Water Balloon
    "watermelon": os.path.join(DEV_DIR, "extracted_im3_r0_c3.png"),  # Official Watermelon Balloon
    "dark": os.path.join(DEV_DIR, "extracted_im2_r2_c0.png"),        # Official Dark Cosmic Balloon
    "sparkling": os.path.join(DEV_DIR, "extracted_im2_r1_c7.png"),   # Official Sparkling Star Crystal Balloon
}

def generate_breathing_frames(base_img, skin_id):
    """
    Generates 4 authentic breathing frames (idle) and tension/wobble for the official sprite:
    - Frame 0: Base resting
    - Frame 1: Squash horizontally (w=103%, h=97%)
    - Frame 2: Stretch vertically (w=97%, h=103%)
    - Frame 3: Pre-pop wobble (slight tilt)
    """
    frames = []
    bbox = base_img.getbbox()
    cropped = base_img.crop(bbox)
    cw, ch = cropped.size
    
    tensions = [
        (1.00, 1.00, 0.0),
        (1.03, 0.97, 0.0),
        (0.97, 1.03, 0.0),
        (1.01, 0.99, 1.8),
    ]
    
    for sx, sy, rot in tensions:
        nw = max(1, int(round(cw * sx)))
        nh = max(1, int(round(ch * sy)))
        res = cropped.resize((nw, nh), Image.Resampling.LANCZOS)
        if rot != 0.0:
            res = res.rotate(rot, resample=Image.Resampling.BICUBIC, expand=True)
            
        canvas = Image.new("RGBA", (128, 128), (0, 0, 0, 0))
        px = (128 - res.size[0]) // 2
        py = 118 - res.size[1]  # Align bottom to ground line at y=118
        canvas.paste(res, (px, py), res)
        frames.append(canvas)
        
    return frames

def build_all():
    for skin_id, src_path in OFFICIAL_MODELS.items():
        if not os.path.exists(src_path):
            print(f"Error: {src_path} not found")
            continue
            
        base_balloon = Image.open(src_path).convert("RGBA")
        skin_dir = os.path.join(BALLOON_BASE, skin_id)
        os.makedirs(skin_dir, exist_ok=True)
        
        # 1. Save High-Res Menu Card Icon (icon.png - 128x128, centered)
        icon_canvas = Image.new("RGBA", (128, 128), (0, 0, 0, 0))
        bbox = base_balloon.getbbox()
        cropped = base_balloon.crop(bbox)
        # Fit to 102px
        scale = 100.0 / float(max(cropped.size))
        nw = int(round(cropped.size[0] * scale))
        nh = int(round(cropped.size[1] * scale))
        icon_res = cropped.resize((nw, nh), Image.Resampling.LANCZOS)
        icon_canvas.paste(icon_res, ((128 - nw) // 2, (128 - nh) // 2), icon_res)
        
        icon_path = os.path.join(skin_dir, "icon.png")
        icon_canvas.save(icon_path, optimize=True)
        print(f"Saved Official Icon -> {icon_path}")
        
        # 2. Generate 4 Idle Frames
        idle_frames = generate_breathing_frames(icon_canvas, skin_id)
        legacy_prefix = {
            "default": "water_balloon",
            "watermelon": "watermelon_balloon",
            "dark": "dark_balloon",
            "sparkling": "sparkle_balloon"
        }[skin_id]
        
        for idx, fimg in enumerate(idle_frames):
            fpath = os.path.join(skin_dir, f"idle_{idx}.png")
            fimg.save(fpath, optimize=True)
            # Also save to legacy folder
            leg_path = os.path.join(LEGACY_WB, f"{legacy_prefix}_{idx}.png")
            fimg.save(leg_path, optimize=True)
            
        # 3. Save Sprite Sheet (128x128 grid)
        sheet_img = Image.new("RGBA", (8 * 128, 5 * 128), (0, 0, 0, 0))
        for i, f in enumerate(idle_frames):
            sheet_img.paste(f, (i * 128, 0), f)
            sheet_img.paste(f, (i * 128, 128), f)  # place
            sheet_img.paste(f, (i * 128, 256), f)  # warning
        sheet_path = os.path.join(skin_dir, "sheet.png")
        sheet_img.save(sheet_path, optimize=True)
        print(f"Saved Sprite Sheet -> {sheet_path}")
        
    print("All 4 official Boom Online water balloons built and integrated successfully!")

build_all()
