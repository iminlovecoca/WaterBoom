import os
import math
import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageEnhance

ROOT = r'c:\Users\khang\Documents\Build\Boom'
WB_DIR = os.path.join(ROOT, 'assets', 'water_balloon')
os.makedirs(WB_DIR, exist_ok=True)

img2_p = r'C:\Users\khang\.gemini\antigravity\brain\8d5450db-5a47-4a4a-af37-9aad2b7203db\.user_uploaded\media_1786953518304.png'
img3_p = r'C:\Users\khang\.gemini\antigravity\brain\8d5450db-5a47-4a4a-af37-9aad2b7203db\.user_uploaded\media_1786953526324.png'

im2 = Image.open(img2_p).convert('RGBA')
im3 = Image.open(img3_p).convert('RGBA')

def clean_and_upscale_balloon(crop_img, bg_color, target_size=128):
    arr = np.array(crop_img).astype(np.float32)
    H, W = arr.shape[:2]
    
    bg_rgb = np.array(bg_color[:3], dtype=np.float32)
    diff = np.sqrt(np.sum((arr[:, :, :3] - bg_rgb)**2, axis=-1))
    
    # 1. Background mask
    from collections import deque
    from scipy import ndimage
    
    is_bg = diff < 36.0
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
                    
    alpha = np.where(visited, 0.0, 255.0)
    
    # Edge de-fringing
    edge_mask = ndimage.binary_dilation(visited, iterations=2) & (~visited)
    for y, x in zip(*np.where(edge_mask)):
        d = diff[y, x]
        if d < 55.0:
            alpha[y, x] = np.clip((d - 25.0) / 30.0 * 255.0, 0, 255)
            
    # Largest connected component
    labeled, num_features = ndimage.label(alpha > 30)
    if num_features > 0:
        sizes = ndimage.sum(alpha > 30, labeled, range(num_features + 1))
        largest_idx = np.argmax(sizes[1:]) + 1
        main_mask = ndimage.binary_dilation(labeled == largest_idx, iterations=1)
        alpha[~main_mask] = 0.0
        
    arr[:, :, 3] = alpha
    raw_clean = Image.fromarray(arr.astype(np.uint8))
    
    bbox = raw_clean.getbbox()
    if not bbox:
        return raw_clean
        
    cropped = raw_clean.crop(bbox)
    cw, ch = cropped.size
    
    # High-quality supersampling: scale to 256px height, apply smooth contour & color polish
    high_h = 240
    high_w = int(round(cw * (high_h / float(ch))))
    hd = cropped.resize((high_w, high_h), Image.Resampling.LANCZOS)
    
    # Polish & sharpen
    hd = ImageEnhance.Sharpness(hd).enhance(1.6)
    hd = ImageEnhance.Color(hd).enhance(1.2)
    hd = ImageEnhance.Contrast(hd).enhance(1.1)
    
    # Smooth downsample to target 128x128
    icon_h = 96
    icon_w = int(round(hd.size[0] * (icon_h / float(hd.size[1]))))
    icon_res = hd.resize((icon_w, icon_h), Image.Resampling.LANCZOS)
    
    canvas = Image.new("RGBA", (target_size, target_size), (0, 0, 0, 0))
    px = (target_size - icon_w) // 2
    py = (target_size - icon_h) // 2
    canvas.paste(icon_res, (px, py), icon_res)
    return canvas

def make_4_tension_frames(base_img):
    bbox = base_img.getbbox()
    cropped = base_img.crop(bbox)
    cw, ch = cropped.size
    
    frames = []
    tensions = [
        (1.00, 1.00, 0.0),
        (1.025, 0.975, 0.0),
        (0.975, 1.025, 0.0),
        (1.01, 0.99, 1.2),
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

def build_all():
    print("Building high-resolution, crystal-clear official Boom Online water balloons...")
    
    bg2 = im2.getpixel((0, 0))
    bg3 = im3.getpixel((0, 0))
    
    # 1. Classic Blue Water Balloon (Image 2: row 0, col 0)
    crop_def = im2.crop((0, 0, 128, 192))
    hd_default = clean_and_upscale_balloon(crop_def, bg2)
    
    # 2. Watermelon Balloon (Image 3: row 0, col 3)
    col_w = 596 / 7.0
    row_h = 335 / 3.0
    crop_wm = im3.crop((int(3 * col_w), 0, int(4 * col_w), int(row_h)))
    hd_watermelon = clean_and_upscale_balloon(crop_wm, bg3)
    
    # 3. Dark Shadow Balloon (Image 2: row 2, col 0)
    crop_dark = im2.crop((0, 2 * 192, 128, 3 * 192))
    hd_dark = clean_and_upscale_balloon(crop_dark, bg2)
    
    # 4. Sparkling Star Balloon (Image 2: row 1, col 7)
    crop_spark = im2.crop((7 * 128, 1 * 192, 8 * 128, 2 * 192))
    hd_sparkle = clean_and_upscale_balloon(crop_spark, bg2)
    
    skins = [
        ("water_balloon", hd_default),
        ("watermelon_balloon", hd_watermelon),
        ("dark_balloon", hd_dark),
        ("sparkle_balloon", hd_sparkle),
    ]
    
    for prefix, hd_img in skins:
        frames = make_4_tension_frames(hd_img)
        for idx, f in enumerate(frames):
            out_p = os.path.join(WB_DIR, f"{prefix}_{idx}.png")
            f.save(out_p, optimize=True)
            print(f"Saved: {out_p}")
            
    # Update item icon
    it_path = os.path.join(ROOT, "assets", "items", "item_water_balloon_up.png")
    c_it = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
    res_it = hd_default.resize((28, 28), Image.Resampling.LANCZOS)
    c_it.paste(res_it, (2, 2), res_it)
    c_it.save(it_path, optimize=True)
    print(f"Updated item_water_balloon_up.png -> {it_path}")
    print("Done building crisp balloons!")

build_all()
