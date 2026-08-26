import os
import math
import numpy as np
from PIL import Image, ImageDraw, ImageFilter

ROOT = r'c:\Users\khang\Documents\Build\Boom'
WB_DIR = os.path.join(ROOT, 'assets', 'water_balloon')
os.makedirs(WB_DIR, exist_ok=True)

# High-res canvas for supersampled smooth 2.5D rendering (192x192 -> 48x48)
HI_RES = 192
OUT_RES = 44

def create_sphere_normals(size=HI_RES, rx=70, ry=70, cx=96, cy=104):
    """Generates 3D normal vectors (Nx, Ny, Nz) and mask for a 3D sphere."""
    x, y = np.meshgrid(np.arange(size, dtype=np.float32), np.arange(size, dtype=np.float32))
    dx = (x - cx) / float(rx)
    dy = (y - cy) / float(ry)
    dist_sq = dx**2 + dy**2
    mask = dist_sq <= 1.0
    
    nz = np.zeros((size, size), dtype=np.float32)
    nz[mask] = np.sqrt(np.maximum(0.0, 1.0 - dist_sq[mask]))
    
    nx = np.zeros((size, size), dtype=np.float32)
    ny = np.zeros((size, size), dtype=np.float32)
    nx[mask] = dx[mask]
    ny[mask] = dy[mask]
    
    return nx, ny, nz, mask, dist_sq

def render_25d_balloon(skin_id, frame_idx):
    # Pulse squash and stretch
    t = frame_idx * (math.pi / 2.0)
    squash = 1.0 + math.sin(t) * 0.06
    stretch = 1.0 - math.sin(t) * 0.06
    
    rx = int(72 * squash)
    ry = int(72 * stretch)
    cx = HI_RES // 2
    cy = 108 + int((72 - ry) * 0.5)
    
    nx, ny, nz, mask, dist_sq = create_sphere_normals(HI_RES, rx, ry, cx, cy)
    
    # Lighting vectors (Key light from top-left, fill light from bottom-right)
    lx, ly, lz = -0.55, -0.65, 0.52
    length = math.sqrt(lx*lx + ly*ly + lz*lz)
    lx, ly, lz = lx/length, ly/length, lz/length
    
    # Diffuse shading
    dot = np.maximum(0.0, -(nx*lx + ny*ly + nz*lz))
    # Ambient
    ambient = 0.35 + 0.65 * (1.0 - dist_sq * 0.5)
    # Fresnel rim glow (strong at edges)
    fresnel = np.power(np.maximum(0.0, 1.0 - nz), 2.2)
    
    # Specular highlight (top-left)
    # Blinn-Phong half vector
    hx, hy, hz = lx, ly, lz + 1.0
    hlen = np.sqrt(hx*hx + hy*hy + hz*hz)
    hx, hy, hz = hx/hlen, hy/hlen, hz/hlen
    spec_dot = np.maximum(0.0, -(nx*hx + ny*hy + nz*hz))
    specular = np.power(spec_dot, 28.0) * mask
    specular_soft = np.power(spec_dot, 8.0) * mask * 0.4
    
    # Bottom secondary reflection (bounce light from ground)
    bounce_dot = np.maximum(0.0, ny * 0.8 - nz * 0.2)
    bounce = bounce_dot * 0.45 * mask
    
    # Create RGB buffer
    r = np.zeros((HI_RES, HI_RES), dtype=np.float32)
    g = np.zeros((HI_RES, HI_RES), dtype=np.float32)
    b = np.zeros((HI_RES, HI_RES), dtype=np.float32)
    a = np.zeros((HI_RES, HI_RES), dtype=np.float32)
    
    if skin_id == "classic":
        # Pure 3D Liquid Crystal Water Sphere
        base_r, base_g, base_b = 0.05, 0.60, 0.98
        core_r, core_g, core_b = 0.02, 0.35, 0.85
        rim_r, rim_g, rim_b = 0.65, 0.95, 1.00
        
        # Color gradient based on depth and normal
        r[mask] = (core_r * (1.0 - nz[mask]) + base_r * nz[mask]) * (dot[mask] * 0.6 + ambient[mask] * 0.4) + rim_r * fresnel[mask] * 0.7 + bounce[mask] * 0.2
        g[mask] = (core_g * (1.0 - nz[mask]) + base_g * nz[mask]) * (dot[mask] * 0.6 + ambient[mask] * 0.4) + rim_g * fresnel[mask] * 0.7 + bounce[mask] * 0.4
        b[mask] = (core_b * (1.0 - nz[mask]) + base_b * nz[mask]) * (dot[mask] * 0.6 + ambient[mask] * 0.4) + rim_b * fresnel[mask] * 0.7 + bounce[mask] * 0.5
        a[mask] = 0.92 + 0.08 * fresnel[mask]
        
    elif skin_id == "watermelon":
        # 3D Glossy Watermelon Sphere with emerald stripes and ruby depth
        x_idx, y_idx = np.meshgrid(np.arange(HI_RES, dtype=np.float32), np.arange(HI_RES, dtype=np.float32))
        angle = np.arctan2(y_idx - cy, (x_idx - cx) * (1.0 / squash))
        stripes = np.sin(angle * 7.0 + nx * 2.0)
        is_dark_stripe = stripes > 0.1
        
        base_r = np.where(is_dark_stripe, 0.05, 0.18)
        base_g = np.where(is_dark_stripe, 0.38, 0.82)
        base_b = np.where(is_dark_stripe, 0.12, 0.28)
        
        r[mask] = base_r[mask] * (dot[mask] * 0.7 + ambient[mask] * 0.4) + 0.6 * fresnel[mask]
        g[mask] = base_g[mask] * (dot[mask] * 0.7 + ambient[mask] * 0.4) + 0.9 * fresnel[mask]
        b[mask] = base_b[mask] * (dot[mask] * 0.7 + ambient[mask] * 0.4) + 0.5 * fresnel[mask]
        a[mask] = 0.98
        
    elif skin_id == "dark":
        # 3D Shadow Obsidian Sphere with purple aura
        core_r, core_g, core_b = 0.10, 0.05, 0.22
        base_r, base_g, base_b = 0.22, 0.10, 0.45
        rim_r, rim_g, rim_b = 0.65, 0.35, 0.95
        
        r[mask] = (core_r * (1.0 - nz[mask]) + base_r * nz[mask]) * (dot[mask] * 0.5 + ambient[mask] * 0.4) + rim_r * fresnel[mask] * 0.9
        g[mask] = (core_g * (1.0 - nz[mask]) + base_g * nz[mask]) * (dot[mask] * 0.5 + ambient[mask] * 0.4) + rim_g * fresnel[mask] * 0.9
        b[mask] = (core_b * (1.0 - nz[mask]) + base_b * nz[mask]) * (dot[mask] * 0.5 + ambient[mask] * 0.4) + rim_b * fresnel[mask] * 0.9
        a[mask] = 0.96
        
    elif skin_id == "sparkle":
        # 3D Celestial Crystal Bubble
        core_r, core_g, core_b = 0.35, 0.65, 0.98
        base_r, base_g, base_b = 0.70, 0.85, 1.00
        rim_r, rim_g, rim_b = 1.00, 0.90, 0.98
        
        r[mask] = (core_r * (1.0 - nz[mask]) + base_r * nz[mask]) * (dot[mask] * 0.6 + ambient[mask] * 0.4) + rim_r * fresnel[mask] * 0.8
        g[mask] = (core_g * (1.0 - nz[mask]) + base_g * nz[mask]) * (dot[mask] * 0.6 + ambient[mask] * 0.4) + rim_g * fresnel[mask] * 0.8
        b[mask] = (core_b * (1.0 - nz[mask]) + base_b * nz[mask]) * (dot[mask] * 0.6 + ambient[mask] * 0.4) + rim_b * fresnel[mask] * 0.8
        a[mask] = 0.90 + 0.10 * fresnel[mask]
        
    elif skin_id == "fire_plasma":
        # 3D Glowing Solar Plasma Orb
        x_idx, y_idx = np.meshgrid(np.arange(HI_RES, dtype=np.float32), np.arange(HI_RES, dtype=np.float32))
        d_center = np.sqrt(((x_idx - cx)/float(rx))**2 + ((y_idx - cy)/float(ry))**2)
        heat = np.clip(1.0 - d_center * 0.8 + dot * 0.3, 0.0, 1.0)
        
        r[mask] = 1.00 * heat[mask] + 0.90 * (1.0 - heat[mask]) + 1.0 * fresnel[mask] * 0.4
        g[mask] = 0.85 * (heat[mask]**2.5) + 0.25 * heat[mask] + 0.6 * fresnel[mask] * 0.4
        b[mask] = 0.30 * (heat[mask]**4.0) + 0.05
        a[mask] = 0.98
        
    elif skin_id == "cyber_neon":
        # 3D Holographic Cyber Glass Orb
        x_idx, y_idx = np.meshgrid(np.arange(HI_RES, dtype=np.float32), np.arange(HI_RES, dtype=np.float32))
        grid_x = np.abs(np.sin((x_idx - cx) * 0.12 + nx * 1.5)) > 0.88
        grid_y = np.abs(np.sin((y_idx - cy) * 0.12 + ny * 1.5)) > 0.88
        is_grid = grid_x | grid_y
        
        base_r = np.where(is_grid, 0.0, 0.08)
        base_g = np.where(is_grid, 0.95, 0.12)
        base_b = np.where(is_grid, 1.0, 0.32)
        
        r[mask] = base_r[mask] + 0.9 * fresnel[mask] * 0.4
        g[mask] = base_g[mask] + 0.2 * fresnel[mask] * 0.3
        b[mask] = base_b[mask] + 1.0 * fresnel[mask] * 0.8
        a[mask] = 0.95
        
    elif skin_id == "golden_dragon":
        # 3D Royal 24K Gold Pearl Orb with Ruby Dragon Core
        gold_r, gold_g, gold_b = 1.00, 0.82, 0.22
        deep_r, deep_g, deep_b = 0.72, 0.48, 0.08
        
        r[mask] = (deep_r * (1.0 - nz[mask]) + gold_r * nz[mask]) * (dot[mask] * 0.7 + ambient[mask] * 0.4) + 1.0 * fresnel[mask] * 0.6
        g[mask] = (deep_g * (1.0 - nz[mask]) + gold_g * nz[mask]) * (dot[mask] * 0.7 + ambient[mask] * 0.4) + 0.9 * fresnel[mask] * 0.6
        b[mask] = (deep_b * (1.0 - nz[mask]) + gold_b * nz[mask]) * (dot[mask] * 0.7 + ambient[mask] * 0.4) + 0.4 * fresnel[mask] * 0.6
        a[mask] = 0.99
        
    elif skin_id == "rainbow_prism":
        # 3D Prismatic Crystal Rainbow Sphere
        x_idx, y_idx = np.meshgrid(np.arange(HI_RES, dtype=np.float32), np.arange(HI_RES, dtype=np.float32))
        angle = np.arctan2(y_idx - cy, x_idx - cx) + math.pi
        hue = (angle / (2.0 * math.pi) * 6.0) % 6.0
        
        # Spectral colors
        rf = np.clip(np.abs(hue - 3.0) - 1.0, 0.0, 1.0)
        gf = np.clip(2.0 - np.abs(hue - 2.0), 0.0, 1.0)
        bf = np.clip(2.0 - np.abs(hue - 4.0), 0.0, 1.0)
        
        r[mask] = (0.3 + 0.7 * rf[mask]) * (dot[mask] * 0.6 + ambient[mask] * 0.4) + 0.9 * fresnel[mask] * 0.7
        g[mask] = (0.3 + 0.7 * gf[mask]) * (dot[mask] * 0.6 + ambient[mask] * 0.4) + 0.9 * fresnel[mask] * 0.7
        b[mask] = (0.3 + 0.7 * bf[mask]) * (dot[mask] * 0.6 + ambient[mask] * 0.4) + 0.9 * fresnel[mask] * 0.7
        a[mask] = 0.92 + 0.08 * fresnel[mask]

    # Add 3D Glossy Specular Highlights
    r = np.clip(r + specular * 0.95 + specular_soft * 0.6, 0.0, 1.0)
    g = np.clip(g + specular * 0.95 + specular_soft * 0.6, 0.0, 1.0)
    b = np.clip(b + specular * 0.95 + specular_soft * 0.6, 0.0, 1.0)
    
    # Pack to RGBA PIL Image
    rgba_arr = np.zeros((HI_RES, HI_RES, 4), dtype=np.uint8)
    rgba_arr[:, :, 0] = (r * 255.0).astype(np.uint8)
    rgba_arr[:, :, 1] = (g * 255.0).astype(np.uint8)
    rgba_arr[:, :, 2] = (b * 255.0).astype(np.uint8)
    rgba_arr[:, :, 3] = (a * 255.0).astype(np.uint8)
    
    img = Image.fromarray(rgba_arr, mode="RGBA")
    draw = ImageDraw.Draw(img)
    
    # 3D Translucent Balloon Tie Knot at top
    knot_y = cy - ry - 6
    knot_col = (
        int(r[cy - ry + 4, cx] * 255),
        int(g[cy - ry + 4, cx] * 255),
        int(b[cy - ry + 4, cx] * 255),
        250
    )
    knot_rim = (255, 255, 255, 220)
    
    draw.polygon([(cx - 10, knot_y - 8), (cx + 10, knot_y - 8), (cx + 4, knot_y + 8), (cx - 4, knot_y + 8)], fill=knot_col)
    draw.ellipse([cx - 10, knot_y - 12, cx + 10, knot_y - 4], fill=knot_col, outline=knot_rim, width=2)
    # Knot specular shine
    draw.ellipse([cx - 4, knot_y - 10, cx + 2, knot_y - 6], fill=(255, 255, 255, 240))
    
    # Add special skin embellishments
    if skin_id == "golden_dragon":
        # Embedded 3D glowing ruby gemstone
        draw.polygon([(cx, cy - 14), (cx + 14, cy), (cx, cy + 14), (cx - 14, cy)], fill=(235, 30, 70, 245), outline=(255, 240, 140, 255), width=2)
        draw.polygon([(cx - 3, cy - 8), (cx + 5, cy - 2), (cx - 1, cy + 2)], fill=(255, 255, 255, 220))
    elif skin_id == "sparkle":
        # Twinkling starlight
        for sx, sy in [(cx + 25, cy - 18), (cx - 22, cy + 22), (cx + 28, cy + 20)]:
            draw.polygon([(sx, sy - 8), (sx + 3, sy), (sx, sy + 8), (sx - 3, sy)], fill=(255, 255, 255, 240))
            draw.polygon([(sx - 8, sy), (sx, sy + 3), (sx + 8, sy), (sx, sy - 3)], fill=(255, 255, 255, 240))
            draw.ellipse([sx - 2, sy - 2, sx + 2, sy + 2], fill=(255, 240, 150, 255))
    elif skin_id == "dark":
        # Shadow mist eyes / mysterious smile
        draw.arc([cx - 24, cy - 8, cx - 8, cy + 4], 200, 340, fill=(180, 120, 255, 240), width=3)
        draw.arc([cx + 8, cy - 8, cx + 24, cy + 4], 200, 340, fill=(180, 120, 255, 240), width=3)
        draw.arc([cx - 16, cy + 10, cx + 16, cy + 30], 20, 160, fill=(180, 120, 255, 240), width=3)

    # Soft Contact Shadow at bottom
    shadow = Image.new("RGBA", (HI_RES, HI_RES), (0, 0, 0, 0))
    d_sh = ImageDraw.Draw(shadow)
    d_sh.ellipse([cx - rx + 10, cy + ry - 8, cx + rx - 10, cy + ry + 16], fill=(5, 12, 28, 120))
    shadow = shadow.filter(ImageFilter.GaussianBlur(radius=6))
    
    # Composite shadow + balloon
    final_hi = Image.new("RGBA", (HI_RES, HI_RES), (0, 0, 0, 0))
    final_hi.paste(shadow, (0, 0), shadow)
    final_hi.paste(img, (0, 0), img)
    
    # Downsample with high quality Lanczos to 44x44
    final_44 = final_hi.resize((OUT_RES, OUT_RES), Image.Resampling.LANCZOS)
    return final_44

def build_all_skins():
    skins = [
        ("water_balloon", "classic"),
        ("watermelon_balloon", "watermelon"),
        ("dark_balloon", "dark"),
        ("sparkle_balloon", "sparkle"),
        ("fire_plasma_balloon", "fire_plasma"),
        ("cyber_neon_balloon", "cyber_neon"),
        ("golden_dragon_balloon", "golden_dragon"),
        ("rainbow_prism_balloon", "rainbow_prism"),
    ]
    
    for fname_prefix, skin_id in skins:
        for frame_idx in range(4):
            frame_img = render_25d_balloon(skin_id, frame_idx)
            out_path = os.path.join(WB_DIR, f"{fname_prefix}_{frame_idx}.png")
            frame_img.save(out_path)
            print("Rendered True 2.5D:", out_path)
            
    print("All 8 balloon skins rendered in True 2.5D Volumetric Sphere aesthetics!")

build_all_skins()
