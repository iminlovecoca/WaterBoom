import os
import math
import numpy as np
from PIL import Image, ImageDraw, ImageFilter

ROOT = r'c:\Users\khang\Documents\Build\Boom'
TILESETS_DIR = os.path.join(ROOT, 'assets', 'tilesets')

M_SIZE = 160  # 4x supersampling master size
OUT_SIZE = 40 # Target in-game cell size
SCALE = M_SIZE // OUT_SIZE

THEMES = {
    "egypt_temple": {
        "name": "Desert Temple",
        "floor_base": (218, 172, 98),
        "floor_dark": (200, 150, 78),
        "floor_accent": (230, 188, 115),
        "wall_top": (225, 185, 110),
        "wall_front": (175, 130, 65),
        "wall_outline": (105, 75, 30),
        "wall_trim": (45, 130, 145), # Egyptian turquoise trim
        "crate_top": (195, 140, 75),
        "crate_front": (145, 95, 45),
        "crate_outline": (85, 50, 20),
        "crate_metal": (235, 195, 70), # Brass corner brackets
    },
    "ice_labyrinth": {
        "name": "Ice Labyrinth",
        "floor_base": (36, 75, 125),   # Deep calm blue floor (low contrast for water VFX)
        "floor_dark": (28, 62, 108),
        "floor_accent": (48, 92, 145),
        "wall_top": (65, 130, 185),    # Heavy frozen navy stone with cyan crystal rim
        "wall_front": (35, 75, 120),
        "wall_outline": (18, 40, 70),
        "wall_trim": (140, 235, 255),
        "crate_top": (145, 225, 255),  # Translucent cartoon ice blocks
        "crate_front": (75, 165, 220),
        "crate_outline": (30, 95, 155),
        "crate_metal": (245, 255, 255),
    },
    "lego_city": {
        "name": "Toy Brick City",
        "floor_base": (75, 165, 82),   # Soft lawn green
        "floor_dark": (60, 145, 68),
        "floor_accent": (92, 185, 98),
        "wall_top": (220, 55, 55),     # Warm red toy brick walls
        "wall_front": (175, 35, 35),
        "wall_outline": (105, 18, 18),
        "wall_trim": (255, 110, 110),
        "crate_top": (245, 195, 45),   # Golden yellow toy cargo blocks
        "crate_front": (205, 155, 25),
        "crate_outline": (135, 95, 10),
        "crate_metal": (255, 235, 140),
    },
    "training_plaza": {
        "name": "Training Plaza",
        "floor_base": (120, 168, 72),  # Soft garden green
        "floor_dark": (102, 148, 58),
        "floor_accent": (138, 188, 88),
        "wall_top": (185, 190, 198),   # Arcade granite stone
        "wall_front": (135, 140, 148),
        "wall_outline": (75, 80, 88),
        "wall_trim": (215, 220, 228),
        "crate_top": (198, 142, 82),   # Classic wooden cargo crate
        "crate_front": (150, 98, 48),
        "crate_outline": (90, 52, 22),
        "crate_metal": (225, 185, 85),
    },
    "aqua_park": {
        "name": "Aqua Park",
        "floor_base": (45, 155, 215),  # Pool aqua blue
        "floor_dark": (35, 130, 185),
        "floor_accent": (65, 180, 240),
        "wall_top": (240, 245, 250),   # White poolside tiles with azure trim
        "wall_front": (185, 200, 215),
        "wall_outline": (100, 125, 150),
        "wall_trim": (35, 160, 235),
        "crate_top": (255, 160, 65),   # Beach buoy crate
        "crate_front": (215, 115, 30),
        "crate_outline": (145, 65, 12),
        "crate_metal": (255, 220, 140),
    },
    "pirate_harbor": {
        "name": "Pirate Harbor",
        "floor_base": (168, 125, 82),  # Weathered wooden deck
        "floor_dark": (142, 102, 65),
        "floor_accent": (190, 145, 98),
        "wall_top": (95, 105, 120),    # Iron fortress stone
        "wall_front": (65, 75, 88),
        "wall_outline": (35, 42, 52),
        "wall_trim": (215, 175, 75),   # Gold pirate coin trim
        "crate_top": (175, 115, 60),   # Heavy naval cargo crate
        "crate_front": (125, 75, 32),
        "crate_outline": (72, 38, 14),
        "crate_metal": (85, 95, 110),
    },
    "snow_village": {
        "name": "Snow Village",
        "floor_base": (205, 225, 242), # Soft packed snow
        "floor_dark": (175, 202, 225),
        "floor_accent": (235, 245, 255),
        "wall_top": (140, 110, 85),    # Log cabin wood
        "wall_front": (100, 75, 55),
        "wall_outline": (55, 38, 25),
        "wall_trim": (245, 250, 255),  # Snow roof cap
        "crate_top": (185, 135, 85),
        "crate_front": (135, 90, 48),
        "crate_outline": (78, 48, 22),
        "crate_metal": (245, 250, 255),
    },
    "neon_arcade": {
        "name": "Neon Arcade",
        "floor_base": (32, 28, 55),    # Dark synthwave grid
        "floor_dark": (22, 18, 42),
        "floor_accent": (48, 40, 78),
        "wall_top": (75, 35, 120),     # Cyberpunk purple barrier
        "wall_front": (45, 18, 80),
        "wall_outline": (18, 5, 35),
        "wall_trim": (0, 235, 255),    # Cyan neon glow
        "crate_top": (235, 45, 145),   # Magenta neon crate
        "crate_front": (175, 25, 98),
        "crate_outline": (95, 10, 52),
        "crate_metal": (0, 255, 235),
    },
}

def render_seamless_floor(cfg, is_alt=False):
    """
    Renders 100% seamless floor tile with ZERO borders.
    Continuous material with subtle texture and organic variations.
    """
    img = Image.new("RGBA", (M_SIZE, M_SIZE), cfg["floor_base"] + (255,))
    draw = ImageDraw.Draw(img)
    
    # Generate seamless noise/grain
    np.random.seed(42 if not is_alt else 84)
    noise = np.random.normal(0, 4.0, (M_SIZE, M_SIZE))
    
    base_arr = np.array(img).astype(np.float32)
    for c in range(3):
        base_arr[:, :, c] = np.clip(base_arr[:, :, c] + noise, 0, 255)
        
    img = Image.fromarray(base_arr.astype(np.uint8))
    draw = ImageDraw.Draw(img)
    
    if is_alt:
        # Subtle material detail in center (pebble / grain patch)
        draw.ellipse([54, 54, 76, 76], fill=cfg["floor_accent"] + (90,))
        draw.ellipse([98, 92, 114, 108], fill=cfg["floor_dark"] + (70,))
    else:
        # Soft cross-hatch or ambient wave
        draw.line([(0, 40), (40, 0)], fill=cfg["floor_accent"] + (40,), width=4)
        draw.line([(120, 160), (160, 120)], fill=cfg["floor_accent"] + (40,), width=4)
        
    return img.resize((OUT_SIZE, OUT_SIZE), Image.Resampling.LANCZOS)


def render_25d_wall(cfg):
    """
    Renders an authentic cute 2.5D solid wall block:
    - Top face (elevated plane, bright upper-left bevel, decorative trim)
    - Front face (depth plane with vertical shadow gradient)
    - Soft bottom contact shadow
    """
    img = Image.new("RGBA", (M_SIZE, M_SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    # Dimensions (elevated 2.5D box)
    # Top plane: y in [12, 108]
    # Front plane: y in [108, 148]
    # Contact shadow: y in [142, 156]
    
    # 1. Soft contact shadow
    draw.ellipse([10, 138, 150, 158], fill=(10, 22, 45, 95))
    
    # 2. Outer outline box
    draw.rounded_rectangle([12, 12, 148, 148], radius=10, fill=cfg["wall_outline"] + (255,))
    
    # 3. Front depth plane
    draw.rectangle([16, 104, 144, 144], fill=cfg["wall_front"] + (255,))
    # Front panel shading lines
    draw.line([(16, 144), (144, 144)], fill=cfg["wall_outline"] + (200,), width=4)
    draw.line([(80, 104), (80, 144)], fill=cfg["wall_outline"] + (140,), width=3)
    
    # 4. Top elevated plane
    draw.rectangle([16, 16, 144, 104], fill=cfg["wall_top"] + (255,))
    
    # 5. Top face inner bevel & decorative trim
    # Upper-left light bevel
    draw.line([(16, 16), (144, 16)], fill=(255, 255, 255, 190), width=5)
    draw.line([(16, 16), (16, 104)], fill=(255, 255, 255, 190), width=5)
    # Lower-right shadow bevel
    draw.line([(16, 104), (144, 104)], fill=(0, 0, 0, 110), width=4)
    draw.line([(144, 16), (144, 104)], fill=(0, 0, 0, 110), width=4)
    
    # Decorative center emblem / trim
    draw.rounded_rectangle([38, 34, 122, 86], radius=6, fill=cfg["wall_trim"] + (240,), outline=cfg["wall_outline"] + (180,), width=3)
    draw.line([(42, 38), (118, 38)], fill=(255, 255, 255, 170), width=3)
    
    return img.resize((OUT_SIZE, OUT_SIZE), Image.Resampling.LANCZOS)


def render_25d_crate(cfg, variant=0):
    """
    Renders authentic cute arcade cargo crates:
    - 2.5D perspective (light top plane, medium front face, brass corner metal)
    - Wood plank lines & X-bracing on front face
    - Distinctive material personality for every theme
    """
    img = Image.new("RGBA", (M_SIZE, M_SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    # 1. Soft contact shadow
    draw.ellipse([12, 138, 148, 156], fill=(10, 22, 45, 90))
    
    # 2. Outer crate box
    draw.rounded_rectangle([14, 14, 146, 146], radius=8, fill=cfg["crate_outline"] + (255,))
    
    # 3. Front face (wood planks)
    draw.rectangle([18, 96, 142, 142], fill=cfg["crate_front"] + (255,))
    # Plank separation lines
    draw.line([(18, 118), (142, 118)], fill=cfg["crate_outline"] + (220,), width=3)
    
    # 4. Top face (light plane)
    draw.rectangle([18, 18, 142, 96], fill=cfg["crate_top"] + (255,))
    # Top plank slats
    draw.line([(18, 56), (142, 56)], fill=cfg["crate_outline"] + (160,), width=3)
    
    # Top face highlight
    draw.line([(18, 18), (142, 18)], fill=(255, 255, 255, 180), width=4)
    draw.line([(18, 18), (18, 96)], fill=(255, 255, 255, 180), width=4)
    
    # 5. Front face cross-bracing (X-brace or panels depending on variant)
    if variant == 0:
        # Diagonal X-brace
        draw.line([(24, 102), (136, 138)], fill=cfg["crate_metal"] + (220,), width=4)
        draw.line([(24, 138), (136, 102)], fill=cfg["crate_metal"] + (220,), width=4)
    elif variant == 1:
        # Metal reinforced border
        draw.rectangle([28, 102, 132, 136], outline=cfg["crate_metal"] + (220,), width=4)
        
    # 6. Brass corner reinforcements (4 corners on top plane)
    cr_sz = 14
    for cx_c, cy_c in [(18, 18), (142 - cr_sz, 18), (18, 96 - cr_sz), (142 - cr_sz, 96 - cr_sz)]:
        draw.rectangle([cx_c, cy_c, cx_c + cr_sz, cy_c + cr_sz], fill=cfg["crate_metal"] + (255,), outline=cfg["crate_outline"] + (200,), width=2)
        draw.ellipse([cx_c + 4, cy_c + 4, cx_c + cr_sz - 4, cy_c + cr_sz - 4], fill=(255, 255, 255, 230))
        
    return img.resize((OUT_SIZE, OUT_SIZE), Image.Resampling.LANCZOS)


def build_all_tilesets():
    print("==================================================")
    print("BUILDING SEAMLESS MASTER TILESETS ACROSS ALL THEMES")
    print("==================================================")
    
    for theme_id, cfg in THEMES.items():
        theme_dir = os.path.join(TILESETS_DIR, theme_id, "runtime")
        os.makedirs(theme_dir, exist_ok=True)
        
        # 1. Floor Base
        floor_img = render_seamless_floor(cfg, is_alt=False)
        floor_path = os.path.join(theme_dir, "floor.png")
        floor_img.save(floor_path, optimize=True)
        
        # 2. Floor Alternate
        floor_alt_img = render_seamless_floor(cfg, is_alt=True)
        floor_alt_path = os.path.join(theme_dir, "floor_alt.png")
        floor_alt_img.save(floor_alt_path, optimize=True)
        
        # 3. Solid Hard Block (Wall)
        wall_img = render_25d_wall(cfg)
        wall_path = os.path.join(theme_dir, "hard_block.png")
        wall_img.save(wall_path, optimize=True)
        
        # 4. Destructible Soft Block (Crate)
        crate_img = render_25d_crate(cfg, variant=0)
        crate_path = os.path.join(theme_dir, "soft_block.png")
        crate_img.save(crate_path, optimize=True)
        
        print(f"Built Master Tileset for [{cfg['name']}] -> {theme_dir}")
        
    print("==================================================")
    print("ALL 8 THEMES BUILT WITH SEAMLESS FLOORS & 2.5D TILES!")
    print("==================================================")

build_all_tilesets()
