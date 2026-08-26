import os
import math
import numpy as np
from PIL import Image, ImageDraw, ImageFilter

ROOT = r'c:\Users\khang\Documents\Build\Boom'
WB_DIR = os.path.join(ROOT, 'assets', 'water_balloon')
os.makedirs(WB_DIR, exist_ok=True)

# We will render crisp, high-resolution 128x128 sprites!
# With cx=64, cy=74, radius=42.
# Top knot reaches y=16 (leaving 16px of top padding so it NEVER gets cut off!)
# Bottom shadow reaches y=118 (leaving 10px of bottom padding).
CANVAS_SIZE = 128

def create_high_res_balloon(skin_id, frame_idx):
    # 4-frame breathing & tension squish/stretch
    # Frame 0: Resting plump round
    # Frame 1: Breath in (horizontal squash)
    # Frame 2: Tension pulse (vertical stretch & shine)
    # Frame 3: Pre-pop wobble (slight tilt)
    t = frame_idx * (math.pi / 2.0)
    squash_x = 1.0 + math.sin(t) * 0.05
    stretch_y = 1.0 - math.sin(t) * 0.05
    tilt_deg = math.sin(t * 2.0) * 1.5 if frame_idx == 3 else 0.0
    
    # 2x supersampling for razor sharp details (render at 256x256, downsample to 128x128)
    W = 256
    H = 256
    cx = W // 2
    cy = 148  # Center of balloon sphere
    
    rx = int(84 * squash_x)
    ry = int(84 * stretch_y)
    
    canvas = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    draw = ImageDraw.Draw(canvas)
    
    # -------------------------------------------------------------
    # 1. Soft Ground Contact Shadow (Bóng đổ tiếp đất)
    # -------------------------------------------------------------
    sh_w = int(rx * 1.6)
    sh_h = 24
    sh_y = cy + ry - 6
    draw.ellipse([cx - sh_w//2, sh_y, cx + sh_w//2, sh_y + sh_h], fill=(8, 20, 48, 110))
    
    # -------------------------------------------------------------
    # 2. 3D Volumetric Sphere Shading (NumPy Meshgrid)
    # -------------------------------------------------------------
    x_grid, y_grid = np.meshgrid(np.arange(W, dtype=np.float32), np.arange(H, dtype=np.float32))
    dx = (x_grid - cx) / float(rx)
    dy = (y_grid - cy) / float(ry)
    dist_sq = dx**2 + dy**2
    mask = dist_sq <= 1.0
    
    nz = np.zeros((H, W), dtype=np.float32)
    nz[mask] = np.sqrt(np.maximum(0.0, 1.0 - dist_sq[mask]))
    nx = np.zeros((H, W), dtype=np.float32)
    ny = np.zeros((H, W), dtype=np.float32)
    nx[mask] = dx[mask]
    ny[mask] = dy[mask]
    
    # Key light from top-left
    lx, ly, lz = -0.55, -0.65, 0.52
    length = math.sqrt(lx*lx + ly*ly + lz*lz)
    lx, ly, lz = lx/length, ly/length, lz/length
    dot = np.maximum(0.0, -(nx*lx + ny*ly + nz*lz))
    fresnel = np.power(np.maximum(0.0, 1.0 - nz), 2.4)
    ambient = 0.35 + 0.65 * (1.0 - dist_sq * 0.4)
    
    r = np.zeros((H, W), dtype=np.float32)
    g = np.zeros((H, W), dtype=np.float32)
    b = np.zeros((H, W), dtype=np.float32)
    a = np.zeros((H, W), dtype=np.float32)
    
    if skin_id == "classic":
        # Deep Crystal Azure Water Balloon
        # Inner rich ocean core + bright cyan liquid
        r[mask] = (0.05 + 0.15 * dot[mask]) + 0.65 * fresnel[mask]
        g[mask] = (0.45 + 0.45 * dot[mask]) + 0.90 * fresnel[mask]
        b[mask] = (0.92 + 0.08 * dot[mask]) + 1.00 * fresnel[mask]
        a[mask] = 0.94
        
    elif skin_id == "watermelon":
        # Authentic 3D Watermelon: Vivid Lime Green with Wavy Dark Emerald Stripes
        angle = np.arctan2(dy, dx)
        # Organic wavy watermelon stripes
        wave = np.sin(angle * 6.0 + nx * 3.0 + np.sin(ny * 5.0) * 0.4)
        is_stripe = wave > 0.05
        
        base_r = np.where(is_stripe, 0.04, 0.22)
        base_g = np.where(is_stripe, 0.38, 0.86)
        base_b = np.where(is_stripe, 0.10, 0.26)
        
        r[mask] = base_r[mask] * (dot[mask] * 0.7 + ambient[mask] * 0.4) + 0.45 * fresnel[mask]
        g[mask] = base_g[mask] * (dot[mask] * 0.7 + ambient[mask] * 0.4) + 0.85 * fresnel[mask]
        b[mask] = base_b[mask] * (dot[mask] * 0.7 + ambient[mask] * 0.4) + 0.40 * fresnel[mask]
        a[mask] = 0.98
        
    elif skin_id == "dark":
        # Deep Cosmic Obsidian / Purple Amethyst
        r[mask] = (0.18 + 0.20 * dot[mask]) + 0.70 * fresnel[mask]
        g[mask] = (0.08 + 0.12 * dot[mask]) + 0.40 * fresnel[mask]
        b[mask] = (0.38 + 0.40 * dot[mask]) + 0.95 * fresnel[mask]
        a[mask] = 0.96
        
    elif skin_id == "sparkle":
        # Pearlescent Celestial Starlight
        r[mask] = (0.55 + 0.35 * dot[mask]) + 0.95 * fresnel[mask]
        g[mask] = (0.75 + 0.25 * dot[mask]) + 0.95 * fresnel[mask]
        b[mask] = (0.96 + 0.04 * dot[mask]) + 1.00 * fresnel[mask]
        a[mask] = 0.92

    # Blinn-Phong Specular Gloss
    hx, hy, hz = lx, ly, lz + 1.0
    hlen = np.sqrt(hx*hx + hy*hy + hz*hz)
    hx, hy, hz = hx/hlen, hy/hlen, hz/hlen
    spec_dot = np.maximum(0.0, -(nx*hx + ny*hy + nz*hz))
    specular = np.power(spec_dot, 24.0) * mask
    
    r = np.clip(r + specular * 0.9, 0.0, 1.0)
    g = np.clip(g + specular * 0.9, 0.0, 1.0)
    b = np.clip(b + specular * 0.9, 0.0, 1.0)
    
    sphere_arr = np.zeros((H, W, 4), dtype=np.uint8)
    sphere_arr[:, :, 0] = (r * 255).astype(np.uint8)
    sphere_arr[:, :, 1] = (g * 255).astype(np.uint8)
    sphere_arr[:, :, 2] = (b * 255).astype(np.uint8)
    sphere_arr[:, :, 3] = (a * 255).astype(np.uint8)
    
    sphere_img = Image.fromarray(sphere_arr, mode="RGBA")
    canvas.paste(sphere_img, (0, 0), sphere_img)
    
    # -------------------------------------------------------------
    # 3. Clean Dark Outer Contour (Cel-shaded Edge)
    # -------------------------------------------------------------
    outline_col = {
        "classic": (10, 45, 115, 240),
        "watermelon": (8, 48, 16, 250),
        "dark": (18, 8, 42, 250),
        "sparkle": (28, 75, 145, 230)
    }[skin_id]
    draw.ellipse([cx - rx - 1, cy - ry - 1, cx + rx + 1, cy + ry + 1], outline=outline_col, width=3)
    
    # -------------------------------------------------------------
    # 4. Specular Curved Glare & Stars
    # -------------------------------------------------------------
    # Main curved gloss glare (top-left)
    glare_cx = cx - int(rx * 0.46)
    glare_cy = cy - int(ry * 0.48)
    draw.ellipse([glare_cx - 20, glare_cy - 12, glare_cx + 20, glare_cy + 12], fill=(255, 255, 255, 235))
    draw.ellipse([glare_cx - 14, glare_cy - 8, glare_cx + 14, glare_cy + 8], fill=(255, 255, 255, 255))
    draw.ellipse([glare_cx + 32, glare_cy - 4, glare_cx + 44, glare_cy + 8], fill=(255, 255, 255, 210))
    
    if skin_id == "sparkle":
        # Golden twinkling 4-point stars floating inside
        for sx, sy, ssz in [(cx + 28, cy - 18, 14), (cx - 22, cy + 24, 11), (cx + 26, cy + 26, 10)]:
            draw.polygon([(sx, sy - ssz), (sx + 4, sy), (sx, sy + ssz), (sx - 4, sy)], fill=(255, 250, 160, 255))
            draw.polygon([(sx - ssz, sy), (sx, sy + 4), (sx + ssz, sy), (sx, sy - 4)], fill=(255, 250, 160, 255))
            draw.ellipse([sx - 3, sy - 3, sx + 3, sy + 3], fill=(255, 255, 255, 255))
            
    # -------------------------------------------------------------
    # 5. Fully Intact Tied Rubber Neck / Stem at Top (Never Cut Off!)
    # -------------------------------------------------------------
    # The knot is drawn at cy - ry - 22 to cy - ry + 4, well inside the 256 canvas (top at y ~ 42)
    knot_base_y = cy - ry
    
    if skin_id == "watermelon":
        # Realistic Curled Watermelon Stem (Cuống dưa hấu màu nâu cong tự nhiên + lá nhỏ)
        stem_col = (115, 75, 30, 255)
        stem_hl = (165, 115, 55, 255)
        stem_out = (45, 25, 8, 255)
        
        # Stem base button
        draw.ellipse([cx - 16, knot_base_y - 8, cx + 16, knot_base_y + 8], fill=stem_out)
        draw.ellipse([cx - 13, knot_base_y - 6, cx + 13, knot_base_y + 6], fill=stem_col)
        
        # Curled stem stalk
        stalk_pts = [
            (cx - 5, knot_base_y),
            (cx - 3, knot_base_y - 18),
            (cx + 8, knot_base_y - 32),
            (cx + 22, knot_base_y - 36),
            (cx + 26, knot_base_y - 32),
            (cx + 14, knot_base_y - 24),
            (cx + 4, knot_base_y - 14),
            (cx + 4, knot_base_y)
        ]
        draw.polygon(stalk_pts, fill=stem_col, outline=stem_out)
        draw.line([(cx - 1, knot_base_y - 4), (cx + 6, knot_base_y - 24), (cx + 18, knot_base_y - 30)], fill=stem_hl, width=3)
        
        # Cute little leaf attached to stem
        leaf_pts = [
            (cx - 4, knot_base_y - 12),
            (cx - 24, knot_base_y - 20),
            (cx - 32, knot_base_y - 14),
            (cx - 20, knot_base_y - 6),
            (cx - 4, knot_base_y - 8)
        ]
        draw.polygon(leaf_pts, fill=(45, 180, 70, 255), outline=(15, 65, 25, 255))
        draw.line([(cx - 6, knot_base_y - 10), (cx - 26, knot_base_y - 16)], fill=(120, 240, 140, 255), width=2)
        
    else:
        # Authentic Boom Online Tied Rubber Balloon Knot (with flared opening & cute tied ribbon tabs)
        knot_col, knot_hl, knot_out = {
            "classic": ((25, 130, 245, 255), (140, 215, 255, 255), (10, 45, 115, 255)),
            "dark": ((65, 30, 125, 255), (165, 110, 245, 255), (18, 8, 42, 255)),
            "sparkle": ((130, 195, 255, 255), (230, 245, 255, 255), (28, 75, 145, 255))
        }[skin_id]
        
        # Knot throat (thân cổ bóng)
        draw.polygon([
            (cx - 14, knot_base_y - 24), (cx + 14, knot_base_y - 24),
            (cx + 8, knot_base_y + 4), (cx - 8, knot_base_y + 4)
        ], fill=knot_out)
        draw.polygon([
            (cx - 11, knot_base_y - 22), (cx + 11, knot_base_y - 22),
            (cx + 6, knot_base_y + 2), (cx - 6, knot_base_y + 2)
        ], fill=knot_col)
        
        # Flared rolled rubber lip (Vành miệng bóng cao su cuộn tròn)
        draw.ellipse([cx - 18, knot_base_y - 32, cx + 18, knot_base_y - 18], fill=knot_out)
        draw.ellipse([cx - 15, knot_base_y - 30, cx + 15, knot_base_y - 20], fill=knot_hl)
        draw.ellipse([cx - 8, knot_base_y - 28, cx + 8, knot_base_y - 22], fill=knot_col)
        
        # Tied ribbon tabs (2 tai nơ cao su xòe 2 bên)
        draw.polygon([(cx - 12, knot_base_y - 20), (cx - 28, knot_base_y - 32), (cx - 14, knot_base_y - 28)], fill=knot_col, outline=knot_out)
        draw.polygon([(cx + 12, knot_base_y - 20), (cx + 28, knot_base_y - 32), (cx + 14, knot_base_y - 28)], fill=knot_col, outline=knot_out)

    # -------------------------------------------------------------
    # 6. Apply Rotation & Downsample to Crisp 128x128
    # -------------------------------------------------------------
    if tilt_deg != 0.0:
        canvas = canvas.rotate(tilt_deg, resample=Image.Resampling.BICUBIC, expand=False, center=(cx, cy + ry))
        
    final_128 = canvas.resize((CANVAS_SIZE, CANVAS_SIZE), Image.Resampling.LANCZOS)
    return final_128

def build_all():
    skins = [
        ("water_balloon", "classic"),
        ("watermelon_balloon", "watermelon"),
        ("dark_balloon", "dark"),
        ("sparkle_balloon", "sparkle"),
    ]
    
    for fname_prefix, skin_id in skins:
        for frame_idx in range(4):
            img = create_high_res_balloon(skin_id, frame_idx)
            out_file = os.path.join(WB_DIR, f"{fname_prefix}_{frame_idx}.png")
            img.save(out_file, optimize=True)
            print(f"Generated High-Res Crisp 128x128 Balloon: {fname_prefix}_{frame_idx}.png")

    print("All water balloons rebuilt with high resolution, 100% complete top knot, and rich 3D watermelon/balloon details!")

build_all()
