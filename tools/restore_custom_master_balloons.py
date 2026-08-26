import os
from PIL import Image, ImageEnhance

ROOT = r'c:\Users\khang\Documents\Build\Boom'
WB_DIR = os.path.join(ROOT, 'assets', 'water_balloon')
SRC_DIR = os.path.join(WB_DIR, 'source')
os.makedirs(WB_DIR, exist_ok=True)

# 1. Process 1254x1254 high-res masters for watermelon, dark, and sparkle
MASTERS = {
    "watermelon_balloon": os.path.join(SRC_DIR, "watermelon_water_balloon_master.png"),
    "dark_balloon": os.path.join(SRC_DIR, "dark_water_balloon_master.png"),
    "sparkle_balloon": os.path.join(SRC_DIR, "sparkle_water_balloon_master.png"),
}

def make_4_tension_frames_from_image(img, target_size=128, target_h=96):
    bbox = img.getbbox()
    cropped = img.crop(bbox)
    cw, ch = cropped.size
    
    scale = target_h / float(ch)
    base_w = int(round(cw * scale))
    base_h = target_h
    
    frames = []
    tensions = [
        (1.00, 1.00, 0.0),
        (1.025, 0.975, 0.0),
        (0.975, 1.025, 0.0),
        (1.01, 0.99, 1.0),
    ]
    
    for sx, sy, rot in tensions:
        nw = max(1, int(round(base_w * sx)))
        nh = max(1, int(round(base_h * sy)))
        res = cropped.resize((nw, nh), Image.Resampling.LANCZOS)
        if rot != 0.0:
            res = res.rotate(rot, resample=Image.Resampling.BICUBIC, expand=True)
            
        canvas = Image.new("RGBA", (target_size, target_size), (0, 0, 0, 0))
        px = (target_size - res.size[0]) // 2
        py = 114 - res.size[1]
        canvas.paste(res, (px, py), res)
        frames.append(canvas)
        
    return frames

def build_all():
    print("Restoring original master balloon skins for watermelon, dark, and sparkle...")
    for prefix, src_path in MASTERS.items():
        if os.path.exists(src_path):
            src_img = Image.open(src_path).convert("RGBA")
            frames = make_4_tension_frames_from_image(src_img)
            for idx, f in enumerate(frames):
                out_p = os.path.join(WB_DIR, f"{prefix}_{idx}.png")
                f.save(out_p, optimize=True)
                print(f"Restored: {out_p}")
                
    print("All 3 custom balloon skins (Watermelon, Dark, Sparkle) restored to original masters!")

build_all()
