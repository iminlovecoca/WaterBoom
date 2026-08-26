import os
import math
import numpy as np
from PIL import Image, ImageDraw, ImageFilter

ROOT = r'c:\Users\khang\Documents\Build\Boom'
BALLOON_BASE = os.path.join(ROOT, 'assets', 'water_balloons')
VFX_BASE = os.path.join(ROOT, 'assets', 'vfx', 'water')
DEV_BASE = os.path.join(ROOT, 'development')
LEGACY_WB = os.path.join(ROOT, 'assets', 'water_balloon')
LEGACY_WS = os.path.join(ROOT, 'assets', 'water_stream')

os.makedirs(BALLOON_BASE, exist_ok=True)
os.makedirs(VFX_BASE, exist_ok=True)
os.makedirs(DEV_BASE, exist_ok=True)
os.makedirs(LEGACY_WB, exist_ok=True)
os.makedirs(LEGACY_WS, exist_ok=True)

# Master rendering resolution (256x256) downscaled to 128x128 for razor-sharp antialiasing
M_SIZE = 256
OUT_SIZE = 128

SKIN_CONFIGS = {
    "default": {
        "id": "default",
        "name": "Bóng Mặc Định",
        "outline": (16, 42, 98, 255),
        "rim": (22, 118, 238, 255),
        "base": (38, 172, 255, 255),
        "water_core": (130, 225, 255, 255),
        "water_wave": (185, 242, 255, 255),
        "knot_base": (25, 125, 240, 255),
        "knot_hl": (145, 220, 255, 255),
        "highlight": (255, 255, 255, 245),
        "highlight_soft": (200, 240, 255, 180),
        "burst_col": (40, 180, 255, 255),
    },
    "watermelon": {
        "id": "watermelon",
        "name": "Bóng Dưa Hấu",
        "outline": (10, 48, 20, 255),
        "rim": (25, 140, 55, 255),
        "base": (48, 210, 85, 255),
        "water_core": (95, 235, 125, 255),
        "water_wave": (160, 255, 180, 255),
        "knot_base": (35, 160, 65, 255),
        "knot_hl": (140, 245, 165, 255),
        "highlight": (255, 255, 255, 245),
        "highlight_soft": (210, 255, 220, 180),
        "burst_col": (45, 215, 90, 255),
        "stripe_col": (12, 78, 30, 255),
    },
    "dark": {
        "id": "dark",
        "name": "Bóng Tối",
        "outline": (24, 12, 48, 255),
        "rim": (65, 25, 120, 255),
        "base": (95, 38, 160, 255),
        "water_core": (155, 75, 230, 255),
        "water_wave": (205, 145, 255, 255),
        "knot_base": (80, 30, 140, 255),
        "knot_hl": (185, 125, 255, 255),
        "highlight": (255, 255, 255, 245),
        "highlight_soft": (230, 195, 255, 180),
        "burst_col": (145, 60, 225, 255),
    },
    "sparkling": {
        "id": "sparkling",
        "name": "Bóng Lấp Lánh",
        "outline": (18, 75, 118, 255),
        "rim": (75, 185, 245, 255),
        "base": (155, 228, 255, 255),
        "water_core": (215, 248, 255, 255),
        "water_wave": (245, 252, 255, 255),
        "knot_base": (135, 215, 255, 255),
        "knot_hl": (255, 255, 255, 255),
        "highlight": (255, 255, 255, 255),
        "highlight_soft": (220, 245, 255, 200),
        "burst_col": (120, 225, 255, 255),
    },
}

# ==============================================================================
# 1. CORE BALLOON DRAWING FUNCTION
# ==============================================================================
def draw_master_balloon(skin_id, sx=1.0, sy=1.0, tilt=0.0, wave_phase=0.0, pressure=0.0, opacity=1.0):
    """
    Renders a master 256x256 Crazy Arcade style water balloon with:
    - Pure round/weighted rubber silhouette
    - Fully intact flared tied rubber neck at top (never clipped)
    - 3D Volumetric liquid shading & internal reflections
    - Curved specular glossy highlight following sphere curvature
    - Distinctive skin features (watermelon curved 3D stripes, sparkle stars, dark glow)
    """
    cfg = SKIN_CONFIGS[skin_id]
    img = Image.new("RGBA", (M_SIZE, M_SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    cx = M_SIZE // 2
    cy = 144
    rx = int(76 * sx)
    ry = int(74 * sy)
    
    # -------------------------------------------------------------
    # A. 3D Volumetric Sphere Shading (NumPy)
    # -------------------------------------------------------------
    x_grid, y_grid = np.meshgrid(np.arange(M_SIZE, dtype=np.float32), np.arange(M_SIZE, dtype=np.float32))
    dx = (x_grid - cx) / float(rx)
    dy = (y_grid - cy) / float(ry)
    dist_sq = dx**2 + dy**2
    mask = dist_sq <= 1.0
    
    nz = np.zeros((M_SIZE, M_SIZE), dtype=np.float32)
    nz[mask] = np.sqrt(np.maximum(0.0, 1.0 - dist_sq[mask]))
    nx = np.zeros((M_SIZE, M_SIZE), dtype=np.float32)
    ny = np.zeros((M_SIZE, M_SIZE), dtype=np.float32)
    nx[mask] = dx[mask]
    ny[mask] = dy[mask]
    
    # Key light from upper-left (-0.55, -0.65, 0.52)
    lx, ly, lz = -0.55, -0.65, 0.52
    length = math.sqrt(lx*lx + ly*ly + lz*lz)
    lx, ly, lz = lx/length, ly/length, lz/length
    dot = np.maximum(0.0, -(nx*lx + ny*ly + nz*lz))
    fresnel = np.power(np.maximum(0.0, 1.0 - nz), 2.2)
    ambient = 0.35 + 0.65 * (1.0 - dist_sq * 0.45)
    
    r_arr = np.zeros((M_SIZE, M_SIZE), dtype=np.float32)
    g_arr = np.zeros((M_SIZE, M_SIZE), dtype=np.float32)
    b_arr = np.zeros((M_SIZE, M_SIZE), dtype=np.float32)
    a_arr = np.zeros((M_SIZE, M_SIZE), dtype=np.float32)
    
    base_r, base_g, base_b = [c/255.0 for c in cfg["base"][:3]]
    rim_r, rim_g, rim_b = [c/255.0 for c in cfg["rim"][:3]]
    core_r, core_g, core_b = [c/255.0 for c in cfg["water_core"][:3]]
    
    if skin_id == "watermelon":
        # Watermelon: Vivid green body with 7 vertical dark emerald stripes
        # mathematically projected across the 3D spherical surface
        angle = np.arctan2(dy, dx)
        # Curved 3D stripes following spherical coordinates
        stripe_val = np.sin(angle * 7.0 + nx * 2.5 + np.sin(ny * 4.0) * 0.3)
        is_stripe = stripe_val > 0.0
        
        st_r, st_g, st_b = [c/255.0 for c in cfg["stripe_col"][:3]]
        
        r_col = np.where(is_stripe, st_r, base_r)
        g_col = np.where(is_stripe, st_g, base_g)
        b_col = np.where(is_stripe, st_b, base_b)
        
        r_arr[mask] = r_col[mask] * (dot[mask] * 0.7 + ambient[mask] * 0.4) + rim_r * fresnel[mask] * 0.5
        g_arr[mask] = g_col[mask] * (dot[mask] * 0.7 + ambient[mask] * 0.4) + rim_g * fresnel[mask] * 0.5
        b_arr[mask] = b_col[mask] * (dot[mask] * 0.7 + ambient[mask] * 0.4) + rim_b * fresnel[mask] * 0.5
        a_arr[mask] = 0.98
        
    else:
        # Standard, Dark, and Sparkling volumetric liquid layers
        r_arr[mask] = (core_r * (1.0 - nz[mask]) + base_r * nz[mask]) * (dot[mask] * 0.65 + ambient[mask] * 0.4) + rim_r * fresnel[mask] * 0.8
        g_arr[mask] = (core_g * (1.0 - nz[mask]) + base_g * nz[mask]) * (dot[mask] * 0.65 + ambient[mask] * 0.4) + rim_g * fresnel[mask] * 0.8
        b_arr[mask] = (core_b * (1.0 - nz[mask]) + base_b * nz[mask]) * (dot[mask] * 0.65 + ambient[mask] * 0.4) + rim_b * fresnel[mask] * 0.8
        a_arr[mask] = 0.95
        
    # Pressure expansion glow
    if pressure > 0.0:
        r_arr[mask] = np.clip(r_arr[mask] + pressure * 0.25, 0.0, 1.0)
        g_arr[mask] = np.clip(g_arr[mask] + pressure * 0.25, 0.0, 1.0)
        b_arr[mask] = np.clip(b_arr[mask] + pressure * 0.25, 0.0, 1.0)

    # Blinn-Phong Specular Gloss
    hx, hy, hz = lx, ly, lz + 1.0
    hlen = np.sqrt(hx*hx + hy*hy + hz*hz)
    hx, hy, hz = hx/hlen, hy/hlen, hz/hlen
    spec_dot = np.maximum(0.0, -(nx*hx + ny*hy + nz*hz))
    specular = np.power(spec_dot, 22.0) * mask
    
    r_arr = np.clip(r_arr + specular * 0.92, 0.0, 1.0)
    g_arr = np.clip(g_arr + specular * 0.92, 0.0, 1.0)
    b_arr = np.clip(b_arr + specular * 0.92, 0.0, 1.0)
    
    sp_img = Image.fromarray(np.stack([
        (r_arr * 255).astype(np.uint8),
        (g_arr * 255).astype(np.uint8),
        (b_arr * 255).astype(np.uint8),
        (a_arr * 255 * opacity).astype(np.uint8)
    ], axis=-1), mode="RGBA")
    img.paste(sp_img, (0, 0), sp_img)
    
    # -------------------------------------------------------------
    # B. Inner Wave & Liquid Slosh (Lớp nước uốn lượn bên trong)
    # -------------------------------------------------------------
    wave_y = cy + int(math.sin(wave_phase) * 4.0)
    wave_box = [cx - int(rx * 0.75), wave_y - int(ry * 0.55), cx + int(rx * 0.75), cy + int(ry * 0.65)]
    draw.ellipse(wave_box, fill=cfg["water_wave"][:3] + (int(70 * opacity),))
    
    # -------------------------------------------------------------
    # C. Strong Arcade Outer Contour Outline
    # -------------------------------------------------------------
    draw.ellipse([cx - rx - 1, cy - ry - 1, cx + rx + 1, cy + ry + 1], outline=cfg["outline"][:3] + (int(255 * opacity),), width=4)
    
    # -------------------------------------------------------------
    # D. Iconic Glossy Specular Crescent Highlights (Vệt sáng bóng nước)
    # -------------------------------------------------------------
    hl_cx = cx - int(rx * 0.46)
    hl_cy = cy - int(ry * 0.48)
    # Primary curved crescent gloss
    draw.ellipse([hl_cx - 18, hl_cy - 11, hl_cx + 18, hl_cy + 11], fill=cfg["highlight"][:3] + (int(240 * opacity),))
    draw.ellipse([hl_cx - 12, hl_cy - 7, hl_cx + 12, hl_cy + 7], fill=(255, 255, 255, int(255 * opacity)))
    # Secondary trailing reflection glint
    draw.ellipse([hl_cx + 28, hl_cy - 4, hl_cx + 40, hl_cy + 8], fill=cfg["highlight"][:3] + (int(210 * opacity),))
    
    # Bottom bounce light
    bb_x = cx + int(rx * 0.42)
    bb_y = cy + int(ry * 0.44)
    draw.arc([bb_x - 22, bb_y - 12, bb_x + 12, bb_y + 10], 10, 120, fill=cfg["highlight_soft"][:3] + (int(180 * opacity),), width=4)
    
    # -------------------------------------------------------------
    # E. Skin Embellishments (Sparkles / Bubbles)
    # -------------------------------------------------------------
    if skin_id == "sparkling":
        # 3 Golden & crystal 4-pointed stars
        for sx_i, sy_i, ssz in [(cx + 26, cy - 16, 14), (cx - 20, cy + 22, 11), (cx + 24, cy + 24, 9)]:
            draw.polygon([(sx_i, sy_i - ssz), (sx_i + 4, sy_i), (sx_i, sy_i + ssz), (sx_i - 4, sy_i)], fill=(255, 250, 160, int(255 * opacity)))
            draw.polygon([(sx_i - ssz, sy_i), (sx_i, sy_i + 4), (sx_i + ssz, sy_i), (sx_i, sy_i - 4)], fill=(255, 250, 160, int(255 * opacity)))
            draw.ellipse([sx_i - 3, sy_i - 3, sx_i + 3, sy_i + 3], fill=(255, 255, 255, int(255 * opacity)))
    elif skin_id == "dark":
        # Faint internal purple bubbles
        draw.ellipse([cx + 18, cy + 8, cx + 32, cy + 22], outline=(215, 160, 255, int(180 * opacity)), width=2)
        draw.ellipse([cx - 24, cy + 12, cx - 14, cy + 22], outline=(215, 160, 255, int(150 * opacity)), width=2)
        
    # -------------------------------------------------------------
    # F. Flared Tied Rubber Balloon Neck at Top (100% Complete, No Cutoff!)
    # -------------------------------------------------------------
    knot_y = cy - ry
    # Neck throat
    draw.polygon([
        (cx - 13, knot_y - 20), (cx + 13, knot_y - 20),
        (cx + 7, knot_y + 4), (cx - 7, knot_y + 4)
    ], fill=cfg["outline"][:3] + (int(255 * opacity),))
    draw.polygon([
        (cx - 10, knot_y - 18), (cx + 10, knot_y - 18),
        (cx + 5, knot_y + 2), (cx - 5, knot_y + 2)
    ], fill=cfg["knot_base"][:3] + (int(255 * opacity),))
    
    # Flared rolled rubber lip (Vành miệng bóng cuộn tròn)
    draw.ellipse([cx - 17, knot_y - 28, cx + 17, knot_y - 16], fill=cfg["outline"][:3] + (int(255 * opacity),))
    draw.ellipse([cx - 14, knot_y - 26, cx + 14, knot_y - 18], fill=cfg["knot_hl"][:3] + (int(255 * opacity),))
    draw.ellipse([cx - 8, knot_y - 24, cx + 8, knot_y - 20], fill=cfg["knot_base"][:3] + (int(255 * opacity),))
    
    # Cute ribbon tie tabs (2 tai nơ cao su xòe 2 bên)
    draw.polygon([(cx - 10, knot_y - 16), (cx - 24, knot_y - 26), (cx - 12, knot_y - 24)], fill=cfg["knot_base"][:3] + (int(255 * opacity),), outline=cfg["outline"][:3] + (int(255 * opacity),))
    draw.polygon([(cx + 10, knot_y - 16), (cx + 24, knot_y - 26), (cx + 12, knot_y - 24)], fill=cfg["knot_base"][:3] + (int(255 * opacity),), outline=cfg["outline"][:3] + (int(255 * opacity),))

    # Apply rotation tilt if specified
    if tilt != 0.0:
        img = img.rotate(tilt, resample=Image.Resampling.BICUBIC, expand=False, center=(cx, cy + ry))
        
    # Downsample with Lanczos to target 128x128
    return img.resize((OUT_SIZE, OUT_SIZE), Image.Resampling.LANCZOS)


# ==============================================================================
# 2. BURST WATER SPLASH FRAMES (NO FIRE, NO SMOKE)
# ==============================================================================
def draw_burst_frame(skin_id, frame_idx):
    """
    Renders an authentic 8-frame aquatic water balloon pop:
    0: Rubber stretch & snap
    1: Initial water sphere rupture & high-speed radial droplets
    2: Expanding radial pressurized water splash
    3: Turbulent peak aquatic bloom with foam ring
    4: Droplet dispersal & fragmentation
    5: Dissipating water ring
    6: Gentle water ripples
    7: Final droplets fading
    """
    cfg = SKIN_CONFIGS[skin_id]
    img = Image.new("RGBA", (OUT_SIZE, OUT_SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    cx, cy = OUT_SIZE // 2, OUT_SIZE // 2 + 6
    
    t = frame_idx / 7.0
    burst_col = cfg["burst_col"]
    foam_col = (245, 252, 255, 255)
    
    if frame_idx == 0:
        # Rubber deform & snap
        draw.ellipse([cx - 36, cy - 28, cx + 36, cy + 28], fill=cfg["base"][:3] + (220,), outline=cfg["outline"][:3] + (255,), width=2)
        draw.ellipse([cx - 20, cy - 14, cx + 20, cy + 14], fill=foam_col)
    elif frame_idx in [1, 2, 3]:
        # Expanding radial water burst
        radius = int(14 + t * 44)
        alpha = int(255 * (1.0 - t * 0.4))
        # Outer water splash lobes
        num_lobes = 8
        for i in range(num_lobes):
            ang = (i / float(num_lobes)) * 2.0 * math.pi + t
            dist = radius * (0.85 + (i % 2) * 0.3)
            lx = cx + int(math.cos(ang) * dist)
            ly = cy + int(math.sin(ang) * dist)
            draw.ellipse([lx - 9, ly - 9, lx + 9, ly + 9], fill=burst_col[:3] + (alpha,))
            draw.ellipse([lx - 5, ly - 5, lx + 5, ly + 5], fill=foam_col[:3] + (alpha,))
        # Core water burst
        draw.ellipse([cx - radius, cy - radius, cx + radius, cy + radius], fill=burst_col[:3] + (int(alpha * 0.7),), outline=cfg["outline"][:3] + (alpha,), width=2)
        draw.ellipse([cx - int(radius * 0.6), cy - int(radius * 0.6), cx + int(radius * 0.6), cy + int(radius * 0.6)], fill=foam_col[:3] + (alpha,))
    elif frame_idx in [4, 5, 6, 7]:
        # Dispersal droplets & fade
        radius = int(32 + t * 24)
        alpha = int(255 * (1.0 - t))
        if alpha > 0:
            for i in range(10):
                ang = (i / 10.0) * 2.0 * math.pi + (i * 0.4)
                dist = radius + (i % 3) * 6
                dx = cx + int(math.cos(ang) * dist)
                dy = cy + int(math.sin(ang) * dist)
                sz = max(1, int(4 * (1.0 - t)))
                draw.ellipse([dx - sz, dy - sz, dx + sz, dy + sz], fill=burst_col[:3] + (alpha,))
                draw.ellipse([dx - 1, dy - 1, dx + 1, dy + 1], fill=foam_col[:3] + (alpha,))
            # Faint ground ripple
            draw.ellipse([cx - radius, cy + 18 - int(radius*0.25), cx + radius, cy + 18 + int(radius*0.25)], outline=burst_col[:3] + (int(alpha * 0.6),), width=2)
            
    return img


# ==============================================================================
# 3. WATER STREAM & VFX GENERATOR (SEAMLESS CONNECTING TILESET)
# ==============================================================================
def draw_water_stream_piece(piece_type, frame_idx=0):
    """
    Renders thick, pressurized, glossy, rounded Boom Online water blast tiles (40x40):
    - Thick aquatic core with bright white foam center
    - Seamless boundary connections across adjacent cells
    - Crisp rounded splash end caps with droplets
    """
    T_SIZE = 40
    img = Image.new("RGBA", (T_SIZE, T_SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    # Colors
    c_out = (15, 65, 140, 255)
    c_base = (35, 175, 255, 255)
    c_core = (130, 230, 255, 255)
    c_foam = (255, 255, 255, 255)
    
    thick = 15
    pad = (T_SIZE - thick * 2) // 2  # 5px from border
    
    if piece_type == "center":
        # Cross center connecting in all 4 directions
        draw.rectangle([pad, 0, T_SIZE - pad, T_SIZE], fill=c_base, outline=c_out)
        draw.rectangle([0, pad, T_SIZE, T_SIZE - pad], fill=c_base, outline=c_out)
        # Foam core
        draw.ellipse([pad + 3, pad + 3, T_SIZE - pad - 3, T_SIZE - pad - 3], fill=c_foam)
        
    elif piece_type == "horizontal":
        # Full width seamless tube
        draw.rectangle([0, pad, T_SIZE, T_SIZE - pad], fill=c_base)
        draw.line([(0, pad), (T_SIZE, pad)], fill=c_out, width=2)
        draw.line([(0, T_SIZE - pad), (T_SIZE, T_SIZE - pad)], fill=c_out, width=2)
        # Center foam line
        draw.line([(0, T_SIZE // 2), (T_SIZE, T_SIZE // 2)], fill=c_foam, width=4)
        draw.line([(0, T_SIZE // 2 - 3), (T_SIZE, T_SIZE // 2 - 3)], fill=c_core, width=2)
        
    elif piece_type == "vertical":
        # Full height seamless tube
        draw.rectangle([pad, 0, T_SIZE - pad, T_SIZE], fill=c_base)
        draw.line([(pad, 0), (pad, T_SIZE)], fill=c_out, width=2)
        draw.line([(T_SIZE - pad, 0), (T_SIZE - pad, T_SIZE)], fill=c_out, width=2)
        # Center foam line
        draw.line([(T_SIZE // 2, 0), (T_SIZE // 2, T_SIZE)], fill=c_foam, width=4)
        draw.line([(T_SIZE // 2 - 3, 0), (T_SIZE // 2 - 3, T_SIZE)], fill=c_core, width=2)
        
    elif piece_type == "end_left":
        # Rounded bubble bulb on left, connects seamlessly on right
        draw.rectangle([10, pad, T_SIZE, T_SIZE - pad], fill=c_base)
        draw.ellipse([2, pad - 2, 22, T_SIZE - pad + 2], fill=c_base, outline=c_out, width=2)
        draw.line([(10, pad), (T_SIZE, pad)], fill=c_out, width=2)
        draw.line([(10, T_SIZE - pad), (T_SIZE, T_SIZE - pad)], fill=c_out, width=2)
        # Foam bulb & splash droplets
        draw.ellipse([6, pad + 3, 16, T_SIZE - pad - 3], fill=c_foam)
        draw.line([(12, T_SIZE // 2), (T_SIZE, T_SIZE // 2)], fill=c_foam, width=4)
        draw.ellipse([0, T_SIZE // 2 - 2, 3, T_SIZE // 2 + 2], fill=c_core)
        
    elif piece_type == "end_right":
        # Rounded bubble bulb on right, connects seamlessly on left
        draw.rectangle([0, pad, T_SIZE - 10, T_SIZE - pad], fill=c_base)
        draw.ellipse([T_SIZE - 22, pad - 2, T_SIZE - 2, T_SIZE - pad + 2], fill=c_base, outline=c_out, width=2)
        draw.line([(0, pad), (T_SIZE - 10, pad)], fill=c_out, width=2)
        draw.line([(0, T_SIZE - pad), (T_SIZE - 10, T_SIZE - pad)], fill=c_out, width=2)
        draw.ellipse([T_SIZE - 16, pad + 3, T_SIZE - 6, T_SIZE - pad - 3], fill=c_foam)
        draw.line([(0, T_SIZE // 2), (T_SIZE - 12, T_SIZE // 2)], fill=c_foam, width=4)
        draw.ellipse([T_SIZE - 3, T_SIZE // 2 - 2, T_SIZE, T_SIZE // 2 + 2], fill=c_core)
        
    elif piece_type == "end_up":
        # Rounded bubble bulb on top, connects seamlessly on bottom
        draw.rectangle([pad, 10, T_SIZE - pad, T_SIZE], fill=c_base)
        draw.ellipse([pad - 2, 2, T_SIZE - pad + 2, 22], fill=c_base, outline=c_out, width=2)
        draw.line([(pad, 10), (pad, T_SIZE)], fill=c_out, width=2)
        draw.line([(T_SIZE - pad, 10), (T_SIZE - pad, T_SIZE)], fill=c_out, width=2)
        draw.ellipse([pad + 3, 6, T_SIZE - pad - 3, 16], fill=c_foam)
        draw.line([(T_SIZE // 2, 12), (T_SIZE // 2, T_SIZE)], fill=c_foam, width=4)
        draw.ellipse([T_SIZE // 2 - 2, 0, T_SIZE // 2 + 2, 3], fill=c_core)
        
    elif piece_type == "end_down":
        # Rounded bubble bulb on bottom, connects seamlessly on top
        draw.rectangle([pad, 0, T_SIZE - pad, T_SIZE - 10], fill=c_base)
        draw.ellipse([pad - 2, T_SIZE - 22, T_SIZE - pad + 2, T_SIZE - 2], fill=c_base, outline=c_out, width=2)
        draw.line([(pad, 0), (pad, T_SIZE - 10)], fill=c_out, width=2)
        draw.line([(T_SIZE - pad, 0), (T_SIZE - pad, T_SIZE - 10)], fill=c_out, width=2)
        draw.ellipse([pad + 3, T_SIZE - 16, T_SIZE - pad - 3, T_SIZE - 6], fill=c_foam)
        draw.line([(T_SIZE // 2, 0), (T_SIZE // 2, T_SIZE - 12)], fill=c_foam, width=4)
        draw.ellipse([T_SIZE // 2 - 2, T_SIZE - 3, T_SIZE // 2 + 2, T_SIZE], fill=c_core)
        
    elif piece_type == "cross":
        # Symmetrical 4-way intersection
        draw.rectangle([pad, 0, T_SIZE - pad, T_SIZE], fill=c_base)
        draw.rectangle([0, pad, T_SIZE, T_SIZE - pad], fill=c_base)
        draw.ellipse([pad - 1, pad - 1, T_SIZE - pad + 1, T_SIZE - pad + 1], fill=c_base, outline=c_out, width=2)
        draw.ellipse([pad + 2, pad + 2, T_SIZE - pad - 2, T_SIZE - pad - 2], fill=c_foam)
        
    return img


# ==============================================================================
# 4. BUILD MASTER ASSET PACKAGE
# ==============================================================================
def build_all_assets():
    print("==================================================")
    print("BUILDING MASTER WATER BALLOON ART SYSTEM")
    print("==================================================")
    
    # -------------------------------------------------------------
    # 1. Build Per-Skin Asset Folders & Fixed-Grid Sheets
    # -------------------------------------------------------------
    for skin_id in ["default", "watermelon", "dark", "sparkling"]:
        skin_dir = os.path.join(BALLOON_BASE, skin_id)
        os.makedirs(skin_dir, exist_ok=True)
        
        # A. Menu Card Icon (128x128, high contrast, ~80% canvas)
        icon_img = draw_master_balloon(skin_id, sx=1.0, sy=1.0, tilt=0.0, wave_phase=0.0)
        icon_path = os.path.join(skin_dir, "icon.png")
        icon_img.save(icon_path, optimize=True)
        print(f"Saved Menu Icon -> {icon_path}")
        
        # B. Animation Sets
        # IDLE (4 frames): subtle liquid breathing
        idle_frames = [
            draw_master_balloon(skin_id, sx=1.00, sy=1.00, wave_phase=0.0),
            draw_master_balloon(skin_id, sx=1.02, sy=0.98, wave_phase=math.pi*0.5),
            draw_master_balloon(skin_id, sx=1.00, sy=1.00, wave_phase=math.pi),
            draw_master_balloon(skin_id, sx=0.98, sy=1.02, wave_phase=math.pi*1.5),
        ]
        
        # PLACE (4 frames): drop squash & rebound
        place_frames = [
            draw_master_balloon(skin_id, sx=0.94, sy=1.08),  # Drop stretch
            draw_master_balloon(skin_id, sx=1.12, sy=0.88),  # Ground hit squash
            draw_master_balloon(skin_id, sx=0.98, sy=1.03),  # Rebound
            draw_master_balloon(skin_id, sx=1.00, sy=1.00),  # Settled
        ]
        
        # WARNING (4 frames): wobble tension pulse
        warning_frames = [
            draw_master_balloon(skin_id, sx=1.04, sy=0.96, tilt=-2.2, pressure=0.15),
            draw_master_balloon(skin_id, sx=0.96, sy=1.04, tilt=0.0, pressure=0.25),
            draw_master_balloon(skin_id, sx=1.05, sy=0.95, tilt=2.2, pressure=0.35),
            draw_master_balloon(skin_id, sx=0.98, sy=1.03, tilt=0.0, pressure=0.45),
        ]
        
        # PRE_POP (3 frames): maximum swelling & high rim glow
        pre_pop_frames = [
            draw_master_balloon(skin_id, sx=1.08, sy=1.08, pressure=0.6),
            draw_master_balloon(skin_id, sx=1.14, sy=1.14, tilt=-1.5, pressure=0.85),
            draw_master_balloon(skin_id, sx=1.18, sy=1.18, tilt=1.5, pressure=1.0),
        ]
        
        # BURST (8 frames): clean water splash pop
        burst_frames = [draw_burst_frame(skin_id, i) for i in range(8)]
        
        # Save individual frames for backward compatibility & direct loading
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
            
        # C. Production Grid Sprite Sheet (128x128 per cell, 8 columns x 5 rows)
        # Row 0: IDLE (4 frames)
        # Row 1: PLACE (4 frames)
        # Row 2: WARNING (4 frames)
        # Row 3: PRE_POP (3 frames)
        # Row 4: BURST (8 frames)
        sheet_w = 8 * OUT_SIZE
        sheet_h = 5 * OUT_SIZE
        sheet_img = Image.new("RGBA", (sheet_w, sheet_h), (0, 0, 0, 0))
        
        for i, f in enumerate(idle_frames): sheet_img.paste(f, (i * OUT_SIZE, 0 * OUT_SIZE), f)
        for i, f in enumerate(place_frames): sheet_img.paste(f, (i * OUT_SIZE, 1 * OUT_SIZE), f)
        for i, f in enumerate(warning_frames): sheet_img.paste(f, (i * OUT_SIZE, 2 * OUT_SIZE), f)
        for i, f in enumerate(pre_pop_frames): sheet_img.paste(f, (i * OUT_SIZE, 3 * OUT_SIZE), f)
        for i, f in enumerate(burst_frames): sheet_img.paste(f, (i * OUT_SIZE, 4 * OUT_SIZE), f)
        
        sheet_path = os.path.join(skin_dir, "sheet.png")
        sheet_img.save(sheet_path, optimize=True)
        print(f"Saved Sprite Sheet -> {sheet_path}")
        
        # D. Generate Godot SpriteFrames .tres Resource
        # Let's write the SpriteFrames resource file
        frames_tres_content = f"""[gd_resource type="SpriteFrames" load_steps=24 format=3]

[ext_resource type="Texture2D" path="res://assets/water_balloons/{skin_id}/sheet.png" id="1_sheet"]

"""
        # Sub-resources for AtlasTexture
        sub_resources = []
        anim_entries = {
            "idle": [],
            "place": [],
            "warning": [],
            "pre_pop": [],
            "burst": []
        }
        step_id = 2
        
        # IDLE
        for i in range(4):
            frames_tres_content += f"""[sub_resource type="AtlasTexture" id="AtlasTexture_{step_id}"]
atlas = ExtResource("1_sheet")
region = Rect2({i * 128}, 0, 128, 128)

"""
            anim_entries["idle"].append(f'{{"duration": 1.0, "texture": SubResource("AtlasTexture_{step_id}")}}')
            step_id += 1
            
        # PLACE
        for i in range(4):
            frames_tres_content += f"""[sub_resource type="AtlasTexture" id="AtlasTexture_{step_id}"]
atlas = ExtResource("1_sheet")
region = Rect2({i * 128}, 128, 128, 128)

"""
            anim_entries["place"].append(f'{{"duration": 1.0, "texture": SubResource("AtlasTexture_{step_id}")}}')
            step_id += 1
            
        # WARNING
        for i in range(4):
            frames_tres_content += f"""[sub_resource type="AtlasTexture" id="AtlasTexture_{step_id}"]
atlas = ExtResource("1_sheet")
region = Rect2({i * 128}, 256, 128, 128)

"""
            anim_entries["warning"].append(f'{{"duration": 1.0, "texture": SubResource("AtlasTexture_{step_id}")}}')
            step_id += 1
            
        # PRE_POP
        for i in range(3):
            frames_tres_content += f"""[sub_resource type="AtlasTexture" id="AtlasTexture_{step_id}"]
atlas = ExtResource("1_sheet")
region = Rect2({i * 128}, 384, 128, 128)

"""
            anim_entries["pre_pop"].append(f'{{"duration": 1.0, "texture": SubResource("AtlasTexture_{step_id}")}}')
            step_id += 1
            
        # BURST
        for i in range(8):
            frames_tres_content += f"""[sub_resource type="AtlasTexture" id="AtlasTexture_{step_id}"]
atlas = ExtResource("1_sheet")
region = Rect2({i * 128}, 512, 128, 128)

"""
            anim_entries["burst"].append(f'{{"duration": 1.0, "texture": SubResource("AtlasTexture_{step_id}")}}')
            step_id += 1
            
        frames_tres_content += f"""[resource]
animations = [{{
"frames": [{", ".join(anim_entries["idle"])}],
"loop": true,
"name": &"idle",
"speed": 6.0
}}, {{
"frames": [{", ".join(anim_entries["place"])}],
"loop": false,
"name": &"place",
"speed": 12.0
}}, {{
"frames": [{", ".join(anim_entries["warning"])}],
"loop": true,
"name": &"warning",
"speed": 10.0
}}, {{
"frames": [{", ".join(anim_entries["pre_pop"])}],
"loop": true,
"name": &"pre_pop",
"speed": 14.0
}}, {{
"frames": [{", ".join(anim_entries["burst"])}],
"loop": false,
"name": &"burst",
"speed": 16.0
}}]
"""
        tres_path = os.path.join(skin_dir, "frames.tres")
        with open(tres_path, "w", encoding="utf-8") as f:
            f.write(frames_tres_content)
        print(f"Saved SpriteFrames -> {tres_path}")

    # -------------------------------------------------------------
    # 2. Build Water Stream Tileset & VFX Sheet
    # -------------------------------------------------------------
    pieces = ["center", "horizontal", "vertical", "end_left", "end_right", "end_up", "end_down", "cross"]
    for p in pieces:
        p_img = draw_water_stream_piece(p)
        p_path = os.path.join(LEGACY_WS, f"water_{p}.png")
        p_img.save(p_path, optimize=True)
        print(f"Saved Water Stream Piece -> {p_path}")
        
    # Water VFX Sheet (128x128 frames)
    vfx_sheet = Image.new("RGBA", (8 * 128, 4 * 128), (0, 0, 0, 0))
    # Row 0: Stream pieces upscaled for reference
    for idx, p in enumerate(pieces):
        p_up = draw_water_stream_piece(p).resize((128, 128), Image.Resampling.NEAREST)
        vfx_sheet.paste(p_up, (idx * 128, 0), p_up)
    # Row 1: Burst sequence
    for idx in range(8):
        b_frame = draw_burst_frame("default", idx)
        vfx_sheet.paste(b_frame, (idx * 128, 128), b_frame)
    vfx_sheet_path = os.path.join(VFX_BASE, "water_vfx_sheet.png")
    vfx_sheet.save(vfx_sheet_path, optimize=True)
    print(f"Saved Water VFX Sheet -> {vfx_sheet_path}")
    
    # -------------------------------------------------------------
    # 3. Build Development QA Contact Sheet
    # -------------------------------------------------------------
    contact_w = 4 * 140 + 40
    contact_h = 5 * 140 + 80
    contact_sheet = Image.new("RGBA", (contact_w, contact_h), (12, 28, 56, 255))
    d_contact = ImageDraw.Draw(contact_sheet)
    
    d_contact.text((20, 20), "BOOM ONLINE — MASTER WATER BALLOON QA CONTACT SHEET", fill=(255, 220, 80, 255))
    
    skins_list = ["default", "watermelon", "dark", "sparkling"]
    for col_idx, skin_id in enumerate(skins_list):
        x_pos = 20 + col_idx * 140
        d_contact.text((x_pos + 10, 50), SKIN_CONFIGS[skin_id]["name"].upper(), fill=(140, 220, 255, 255))
        
        # Idle frame 0
        icon_f = draw_master_balloon(skin_id, sx=1.0, sy=1.0)
        contact_sheet.paste(icon_f, (x_pos, 80), icon_f)
        
        # Place frame
        place_f = draw_master_balloon(skin_id, sx=1.12, sy=0.88)
        contact_sheet.paste(place_f, (x_pos, 220), place_f)
        
        # Warning frame
        warn_f = draw_master_balloon(skin_id, sx=1.05, sy=0.95, tilt=2.2, pressure=0.35)
        contact_sheet.paste(warn_f, (x_pos, 360), warn_f)
        
        # Burst peak
        burst_f = draw_burst_frame(skin_id, 3)
        contact_sheet.paste(burst_f, (x_pos, 500), burst_f)
        
    dev_contact_path = os.path.join(DEV_BASE, "water_balloon_contact_sheet.png")
    contact_sheet.save(dev_contact_path, optimize=True)
    print(f"Saved QA Contact Sheet -> {dev_contact_path}")
    
    # -------------------------------------------------------------
    # 4. Update In-Game Balloon Item Pickup
    # -------------------------------------------------------------
    it_path = os.path.join(ROOT, "assets", "items", "item_water_balloon_up.png")
    def_icon = draw_master_balloon("default", 1.0, 1.0)
    it_img = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
    resized_it = def_icon.resize((28, 28), Image.Resampling.LANCZOS)
    it_img.paste(resized_it, (2, 2), resized_it)
    it_img.save(it_path, optimize=True)
    print(f"Updated item_water_balloon_up.png -> {it_path}")
    
    print("==================================================")
    print("MASTER WATER BALLOON ART SYSTEM COMPLETED 100%!")
    print("==================================================")

build_all_assets()
