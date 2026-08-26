import os
import math
import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageEnhance
from collections import deque
from scipy import ndimage

ROOT = r'c:\Users\khang\Documents\Build\Boom'
DEV_DIR = os.path.join(ROOT, 'development')
BALLOON_BASE = os.path.join(ROOT, 'assets', 'water_balloons')
LEGACY_WB = os.path.join(ROOT, 'assets', 'water_balloon')

img2_p = r'C:\Users\khang\.gemini\antigravity\brain\8d5450db-5a47-4a4a-af37-9aad2b7203db\.user_uploaded\media_1786953518304.png'
img3_p = r'C:\Users\khang\.gemini\antigravity\brain\8d5450db-5a47-4a4a-af37-9aad2b7203db\.user_uploaded\media_1786953526324.png'

im2 = Image.open(img2_p).convert('RGBA')
im3 = Image.open(img3_p).convert('RGBA')

def extract_and_remaster_balloon(src_crop, bg_color, skin_id):
    """
    1. Precise background removal with edge de-fringing (removes cyan halo)
    2. Edge smoothing & antialiasing
    3. HD Super-Sampling (upscale 3x, enhance contrast, colors, and specular highlights)
    4. Clean 128x128 centering with neat ground baseline
    """
    arr = np.array(src_crop).astype(np.float32)
    H, W = arr.shape[:2]
    
    # 1. Color distance to background
    bg_rgb = np.array(bg_color[:3], dtype=np.float32)
    diff = np.sqrt(np.sum((arr[:, :, :3] - bg_rgb)**2, axis=-1))
    
    # Background mask via BFS from borders
    is_bg = diff < 38.0
    visited = np.zeros((H, W), dtype=bool)
    queue = deque()
    for x in range(W):
        if is_bg[0, x]: queue.append((0, x)); visited[0, x] = True
        if is_bg[H - 1, x]: queue.append((H - 1, x)); visited[H - 1, x] = True
    for y in range(H):
        if is_bg[y, 0]: queue.append((y, 0)); visited[y, 0] = True
        if is_bg[y, W - 1]: queue.append((y, W - 1)); visited[y, W - 1] = True
        
    while queue:
        cy, cx = queue.popleft()
        for dy, dx in [(-1, 0), (1, 0), (0, -1), (0, 1)]:
            ny, nx = cy + dy, cx + dx
            if 0 <= ny < H and 0 <= nx < W:
                if not visited[ny, nx] and is_bg[ny, nx]:
                    visited[ny, nx] = True
                    queue.append((ny, nx))
                    
    # Initial alpha
    alpha = np.where(visited, 0.0, 255.0)
    
    # De-fringe: For pixels near the background edge, remove the cyan background bleed
    edge_mask = ndimage.binary_dilation(visited, iterations=2) & (~visited)
    
    # Suppress cyan background tint in RGB
    for y, x in zip(*np.where(edge_mask)):
        # If pixel color is very close to bg, fade alpha
        d = diff[y, x]
        if d < 55.0:
            alpha[y, x] = np.clip((d - 25.0) / 30.0 * 255.0, 0, 255)
            
    # Clean up isolated stray noise pixels
    labeled, num_features = ndimage.label(alpha > 40)
    if num_features > 0:
        sizes = ndimage.sum(alpha > 40, labeled, range(num_features + 1))
        largest_idx = np.argmax(sizes[1:]) + 1
        main_mask = (labeled == largest_idx)
        # Dilate slightly to retain thin sparkles/knots
        main_mask = ndimage.binary_dilation(main_mask, iterations=1)
        alpha[~main_mask] = 0.0
        
    arr[:, :, 3] = alpha
    clean_raw = Image.fromarray(arr.astype(np.uint8))
    
    bbox = clean_raw.getbbox()
    if not bbox:
        return clean_raw
        
    cropped = clean_raw.crop(bbox)
    cw, ch = cropped.size
    
    # 2. HD Super-Sampling & Enhancement (Scale up to 256x256, polish, downsample to 128x128)
    target_h = 200
    scale = target_h / float(ch)
    nw = max(1, int(round(cw * scale)))
    nh = target_h
    
    # Lanczos upscale
    hd_upscaled = cropped.resize((nw, nh), Image.Resampling.LANCZOS)
    
    # Enhance sharpness & vibrant colors
    enhancer = ImageEnhance.Sharpness(hd_upscaled)
    hd_sharp = enhancer.enhance(1.8)
    enh_color = ImageEnhance.Color(hd_sharp)
    hd_vibrant = enh_color.enhance(1.25)
    enh_contrast = ImageEnhance.Contrast(hd_vibrant)
    hd_final = enh_contrast.enhance(1.15)
    
    # 3. Downsample with clean antialiasing to target 128x128 canvas
    canvas_size = 128
    icon_h = 100
    icon_scale = icon_h / float(hd_final.size[1])
    icon_w = int(round(hd_final.size[0] * icon_scale))
    
    icon_img = hd_final.resize((icon_w, icon_h), Image.Resampling.LANCZOS)
    
    canvas = Image.new("RGBA", (canvas_size, canvas_size), (0, 0, 0, 0))
    px = (canvas_size - icon_w) // 2
    py = (canvas_size - icon_h) // 2
    canvas.paste(icon_img, (px, py), icon_img)
    
    return canvas

def generate_animation_frames(base_icon):
    """Generates 4 smooth, polished breathing frames from the HD remastered icon."""
    bbox = base_icon.getbbox()
    cropped = base_icon.crop(bbox)
    cw, ch = cropped.size
    
    frames = []
    tensions = [
        (1.00, 1.00, 0.0),
        (1.025, 0.975, 0.0),
        (0.975, 1.025, 0.0),
        (1.01, 0.99, 1.5),
    ]
    
    for sx, sy, rot in tensions:
        nw = max(1, int(round(cw * sx)))
        nh = max(1, int(round(ch * sy)))
        res = cropped.resize((nw, nh), Image.Resampling.LANCZOS)
        if rot != 0.0:
            res = res.rotate(rot, resample=Image.Resampling.BICUBIC, expand=True)
            
        c = Image.new("RGBA", (128, 128), (0, 0, 0, 0))
        px = (128 - res.size[0]) // 2
        py = 114 - res.size[1]
        c.paste(res, (px, py), res)
        frames.append(c)
        
    return frames

def build_all_remastered():
    print("==================================================")
    print("REMASTERING OFFICIAL WATER BALLOONS TO CRISP HD")
    print("==================================================")
    
    # 1. Classic Blue Water Balloon (Image 2: Row 0, Col 0)
    bg2 = im2.getpixel((0, 0))
    crop_def = im2.crop((0, 0, 128, 192))
    hd_default = extract_and_remaster_balloon(crop_def, bg2, "default")
    
    # 2. Watermelon Balloon (Image 3: Row 0, Col 3)
    bg3 = im3.getpixel((0, 0))
    col_w = 596 / 7.0
    row_h = 335 / 3.0
    crop_wm = im3.crop((int(3 * col_w), 0, int(4 * col_w), int(row_h)))
    hd_watermelon = extract_and_remaster_balloon(crop_wm, bg3, "watermelon")
    
    # 3. Dark Shadow Balloon (Image 2: Row 2, Col 0)
    crop_dark = im2.crop((0, 2 * 192, 128, 3 * 192))
    hd_dark = extract_and_remaster_balloon(crop_dark, bg2, "dark")
    
    # 4. Sparkling Star Balloon (Image 2: Row 1, Col 7)
    crop_spark = im2.crop((7 * 128, 1 * 192, 8 * 128, 2 * 192))
    hd_sparkle = extract_and_remaster_balloon(crop_spark, bg2, "sparkling")
    
    skins = [
        ("default", hd_default, "water_balloon"),
        ("watermelon", hd_watermelon, "watermelon_balloon"),
        ("dark", hd_dark, "dark_balloon"),
        ("sparkling", hd_sparkle, "sparkle_balloon"),
    ]
    
    for skin_id, icon_img, leg_prefix in skins:
        skin_dir = os.path.join(BALLOON_BASE, skin_id)
        os.makedirs(skin_dir, exist_ok=True)
        
        # Save Remastered HD Icon (128x128)
        icon_path = os.path.join(skin_dir, "icon.png")
        icon_img.save(icon_path, optimize=True)
        print(f"Saved HD Remastered Icon -> {icon_path}")
        
        # Generate and save 4 breathing animation frames
        anim_frames = generate_animation_frames(icon_img)
        for idx, f in enumerate(anim_frames):
            f.save(os.path.join(skin_dir, f"idle_{idx}.png"), optimize=True)
            f.save(os.path.join(LEGACY_WB, f"{leg_prefix}_{idx}.png"), optimize=True)
            
        # Save Sprite Sheet (128x128 grid)
        sheet_img = Image.new("RGBA", (8 * 128, 5 * 128), (0, 0, 0, 0))
        for i, f in enumerate(anim_frames):
            sheet_img.paste(f, (i * 128, 0), f)
            sheet_img.paste(f, (i * 128, 128), f)
            sheet_img.paste(f, (i * 128, 256), f)
        sheet_img.save(os.path.join(skin_dir, "sheet.png"), optimize=True)
        
    # Update item icon
    it_path = os.path.join(ROOT, "assets", "items", "item_water_balloon_up.png")
    c_it = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
    res_it = hd_default.resize((28, 28), Image.Resampling.LANCZOS)
    c_it.paste(res_it, (2, 2), res_it)
    c_it.save(it_path, optimize=True)
    print(f"Updated item_water_balloon_up.png -> {it_path}")
    
    print("==================================================")
    print("HD REMASTER & DE-FRINGING COMPLETED 100%!")
    print("==================================================")

build_all_remastered()
