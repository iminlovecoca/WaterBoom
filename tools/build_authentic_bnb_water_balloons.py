import os
import math
from PIL import Image, ImageDraw, ImageFilter

ROOT = r'c:\Users\khang\Documents\Build\Boom'
WB_DIR = os.path.join(ROOT, 'assets', 'water_balloon')
os.makedirs(WB_DIR, exist_ok=True)

# Master rendering resolution (160x160 downscaled with Lanczos to 40x40 for razor-sharp antialiasing)
M_SIZE = 160
OUT_SIZE = 40
SCALE = M_SIZE / OUT_SIZE  # 4.0

def draw_cel_balloon(skin_id, frame_idx):
    """
    Renders an authentic Boom Online (Crazy Arcade / BnB) style water balloon.
    Features:
    - Chubby, plump round balloon body
    - Distinct tied rubber neck/knot at the top with cute bow
    - Multi-layered translucent liquid gradient & inner water volume
    - Iconic curved specular gloss highlights (vệt sáng bóng nước)
    - Clean 2px dark contour outline (cel-shaded)
    - 4-frame breathing/tension pulse animation
    """
    canvas = Image.new("RGBA", (M_SIZE, M_SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(canvas)
    
    # Breathing animation tension curves
    # Frame 0: Base resting (w=128, h=128)
    # Frame 1: Horizontal swell / squash (w=134, h=122)
    # Frame 2: Vertical stretch / pulse (w=122, h=132)
    # Frame 3: Pre-pop tension wobble (w=130, h=126, slight tilt)
    tensions = [
        (128, 126, 0.0),    # Frame 0: Resting plump
        (134, 120, 1.2),    # Frame 1: Breathing squash
        (124, 132, -1.2),   # Frame 2: Tension stretch
        (132, 124, 2.0),    # Frame 3: Pre-pop wobble
    ]
    bw, bh, rot_deg = tensions[frame_idx]
    
    cx = M_SIZE // 2
    # Ground contact at y = 148 (which maps to y = 37 on 40x40 canvas)
    ground_y = 148
    cy = ground_y - (bh // 2)
    
    # -------------------------------------------------------------
    # 1. Soft Ground Contact Shadow (Bóng đổ tiếp đất)
    # -------------------------------------------------------------
    sh_w = int(bw * 0.75)
    sh_h = 16
    draw.ellipse([cx - sh_w//2, ground_y - 8, cx + sh_w//2, ground_y + 8], fill=(10, 25, 55, 90))
    
    # -------------------------------------------------------------
    # 2. Main Balloon Body Shapes & Palettes
    # -------------------------------------------------------------
    rx = bw // 2
    ry = bh // 2
    
    # Palettes for 4 skins
    if skin_id == "classic":
        # Boom Online Signature Azure/Cyan Water
        outline_col = (12, 45, 110, 255)
        base_fill = (25, 140, 245, 255)
        dark_shade = (10, 85, 200, 255)
        mid_water = (60, 185, 255, 255)
        bright_water = (160, 230, 255, 255)
        knot_col = (18, 110, 225, 255)
        knot_hl = (120, 210, 255, 255)
    elif skin_id == "watermelon":
        # Juiced Watermelon Rind
        outline_col = (10, 50, 20, 255)
        base_fill = (35, 175, 75, 255)
        dark_shade = (15, 110, 45, 255)
        mid_water = (70, 215, 95, 255)
        bright_water = (175, 255, 150, 255)
        knot_col = (100, 65, 30, 255)
        knot_hl = (160, 115, 60, 255)
    elif skin_id == "dark":
        # Shadow Cosmic Obsidian
        outline_col = (20, 10, 45, 255)
        base_fill = (65, 35, 125, 255)
        dark_shade = (35, 15, 75, 255)
        mid_water = (110, 65, 190, 255)
        bright_water = (195, 155, 255, 255)
        knot_col = (55, 25, 105, 255)
        knot_hl = (165, 115, 245, 255)
    elif skin_id == "sparkle":
        # Celestial Pearlescent Starlight
        outline_col = (25, 65, 130, 255)
        base_fill = (130, 195, 255, 255)
        dark_shade = (80, 140, 225, 255)
        mid_water = (185, 225, 255, 255)
        bright_water = (245, 250, 255, 255)
        knot_col = (150, 205, 255, 255)
        knot_hl = (255, 255, 255, 255)

    # A. Base outer sphere (Outline)
    draw.ellipse([cx - rx - 3, cy - ry - 3, cx + rx + 3, cy + ry + 3], fill=outline_col)
    
    # B. Base body fill
    draw.ellipse([cx - rx, cy - ry, cx + rx, cy + ry], fill=base_fill)
    
    # C. Bottom depth shade (Mảng bóng khối dưới)
    draw.ellipse([cx - rx + 4, cy - ry + 12, cx + rx - 4, cy + ry - 4], fill=dark_shade)
    
    # D. Inner translucent liquid core (Khối nước sáng tâm bóng)
    draw.ellipse([cx - int(rx * 0.82), cy - int(ry * 0.78), cx + int(rx * 0.82), cy + int(ry * 0.65)], fill=mid_water)
    
    # E. Inner wave shimmer (Lớp nước bề mặt uốn lượn)
    draw.ellipse([cx - int(rx * 0.68), cy - int(ry * 0.65), cx + int(rx * 0.68), cy + int(ry * 0.40)], fill=bright_water)

    # -------------------------------------------------------------
    # 3. Special Skin Patterns
    # -------------------------------------------------------------
    if skin_id == "watermelon":
        # 3D Curved Watermelon Stripes (Vân sọc dưa hấu uốn theo mặt cầu)
        stripe_col = (12, 75, 30, 255)
        for offset_x in [-36, -18, 0, 18, 36]:
            curve_top = (cx + int(offset_x * 0.4), cy - ry + 8)
            curve_mid = (cx + offset_x, cy)
            curve_bot = (cx + int(offset_x * 0.4), cy + ry - 10)
            draw.line([curve_top, curve_mid, curve_bot], fill=stripe_col, width=6)
    elif skin_id == "dark":
        # Cosmic aura ring
        draw.arc([cx - rx + 8, cy - ry + 8, cx + rx - 8, cy + ry - 8], 190, 350, fill=(185, 130, 255, 180), width=5)
    elif skin_id == "sparkle":
        # Floating golden & crystal stars inside (Sao lấp lánh bên trong)
        for star_x, star_y, star_sz in [(cx + 24, cy - 14, 10), (cx - 20, cy + 16, 8), (cx + 22, cy + 20, 7)]:
            draw.polygon([(star_x, star_y - star_sz), (star_x + 3, star_y), (star_x, star_y + star_sz), (star_x - 3, star_y)], fill=(255, 245, 160, 255))
            draw.polygon([(star_x - star_sz, star_y), (star_x, star_y + 3), (star_x + star_sz, star_y), (star_x, star_y - 3)], fill=(255, 245, 160, 255))
            draw.ellipse([star_x - 2, star_y - 2, star_x + 2, star_y + 2], fill=(255, 255, 255, 255))

    # -------------------------------------------------------------
    # 4. Iconic Glossy Specular Highlights (Vệt sáng bóng nước chuẩn Boom Online)
    # -------------------------------------------------------------
    # Primary top-left large curved glare
    hl_x = cx - int(rx * 0.52)
    hl_y = cy - int(ry * 0.55)
    draw.ellipse([hl_x - 14, hl_y - 9, hl_x + 14, hl_y + 9], fill=(255, 255, 255, 240))
    draw.ellipse([hl_x - 10, hl_y - 6, hl_x + 10, hl_y + 6], fill=(255, 255, 255, 255))
    
    # Secondary trailing glare dot
    draw.ellipse([hl_x + 24, hl_y - 4, hl_x + 34, hl_y + 4], fill=(255, 255, 255, 220))
    
    # Bottom-right subtle bounce reflection (Phản xạ sáng viền dưới)
    br_x = cx + int(rx * 0.45)
    br_y = cy + int(ry * 0.48)
    draw.arc([br_x - 20, br_y - 12, br_x + 10, br_y + 8], 10, 110, fill=(255, 255, 255, 160), width=4)

    # -------------------------------------------------------------
    # 5. Tied Rubber Neck & Knot (Nút thắt cao su phía trên chuẩn BnB)
    # -------------------------------------------------------------
    knot_top = cy - ry - 14
    # Knot outline
    draw.polygon([
        (cx - 14, knot_top - 6), (cx + 14, knot_top - 6),
        (cx + 6, cy - ry + 4), (cx - 6, cy - ry + 4)
    ], fill=outline_col)
    draw.ellipse([cx - 15, knot_top - 10, cx + 15, knot_top], fill=outline_col)
    
    # Knot fill
    draw.polygon([
        (cx - 11, knot_top - 4), (cx + 11, knot_top - 4),
        (cx + 4, cy - ry + 2), (cx - 4, cy - ry + 2)
    ], fill=knot_col)
    draw.ellipse([cx - 12, knot_top - 8, cx + 12, knot_top - 1], fill=knot_hl)
    
    # Cute tie string / bow tabs
    draw.polygon([(cx - 14, knot_top - 4), (cx - 24, knot_top - 12), (cx - 10, knot_top - 9)], fill=knot_col)
    draw.polygon([(cx + 14, knot_top - 4), (cx + 24, knot_top - 12), (cx + 10, knot_top - 9)], fill=knot_col)

    # -------------------------------------------------------------
    # 6. Smooth Antialiasing & Downsample to 40×40
    # -------------------------------------------------------------
    if rot_deg != 0.0:
        canvas = canvas.rotate(rot_deg, resample=Image.Resampling.BICUBIC, expand=False, center=(cx, ground_y))
        
    final_img = canvas.resize((OUT_SIZE, OUT_SIZE), Image.Resampling.LANCZOS)
    return final_img

def build_all():
    skins = [
        ("water_balloon", "classic"),
        ("watermelon_balloon", "watermelon"),
        ("dark_balloon", "dark"),
        ("sparkle_balloon", "sparkle"),
    ]
    
    for fname_prefix, skin_id in skins:
        for frame_idx in range(4):
            img = draw_cel_balloon(skin_id, frame_idx)
            out_file = os.path.join(WB_DIR, f"{fname_prefix}_{frame_idx}.png")
            img.save(out_file, optimize=True)
            print(f"Generated Authentic Boom Online Sprite: {fname_prefix}_{frame_idx}.png")

    print("All 4 water balloon sheets synchronized and rendered at Boom Online master quality!")

build_all()
