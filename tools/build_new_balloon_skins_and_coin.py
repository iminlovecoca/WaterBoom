import os
from PIL import Image, ImageDraw
import math

ROOT = r'c:\Users\khang\Documents\Build\Boom'
WB_DIR = os.path.join(ROOT, 'assets', 'water_balloon')
UI_DIR = os.path.join(ROOT, 'assets', 'ui')
os.makedirs(WB_DIR, exist_ok=True)
os.makedirs(UI_DIR, exist_ok=True)

# ---------------------------------------------------------
# 1. GENERATE GOLDEN COKE COIN ICON (40x40)
# ---------------------------------------------------------
coin = Image.new('RGBA', (40, 40), (0, 0, 0, 0))
d_coin = ImageDraw.Draw(coin)

# Outer coin edge shadow
d_coin.ellipse([2, 4, 38, 38], fill=(160, 110, 20, 255))
# Outer golden rim
d_coin.ellipse([2, 2, 38, 36], fill=(255, 215, 50, 255), outline=(180, 125, 25, 255), width=2)
# Inner golden face
d_coin.ellipse([6, 6, 34, 32], fill=(255, 235, 90, 255), outline=(220, 165, 30, 255), width=2)

# Bold "C" (Coke) emblem in center
d_coin.arc([11, 10, 29, 28], 45, 315, fill=(160, 95, 10, 255), width=5)
d_coin.arc([11, 10, 29, 28], 45, 315, fill=(255, 140, 20, 255), width=3)
# Specular glint on top-left
d_coin.ellipse([8, 7, 14, 13], fill=(255, 255, 255, 230))
d_coin.ellipse([26, 25, 30, 29], fill=(255, 255, 255, 180))

coin_path = os.path.join(UI_DIR, 'coke_coin.png')
coin.save(coin_path)
print("Saved Coke Coin to", coin_path)


# ---------------------------------------------------------
# 2. GENERATE 4 NEW WATER BALLOON SKINS (4 FRAMES EACH)
# ---------------------------------------------------------
def create_balloon_frames(skin_name, base_col, rim_col, inner_col, knot_col, style):
    for f in range(4):
        img = Image.new('RGBA', (40, 40), (0, 0, 0, 0))
        draw = ImageDraw.Draw(img)
        
        # Pulse squash & stretch
        squash = 1.0 + math.sin(f * (math.pi / 2.0)) * 0.08
        stretch = 1.0 - math.sin(f * (math.pi / 2.0)) * 0.08
        
        cx, cy = 20, 22
        rx = int(round(15 * squash))
        ry = int(round(15 * stretch))
        
        # Tie knot at top
        knot_top = cy - ry - 3
        draw.polygon([(cx - 3, knot_top), (cx + 3, knot_top), (cx, cy - ry + 1)], fill=knot_col)
        draw.ellipse([cx - 4, knot_top - 2, cx + 4, knot_top + 2], fill=rim_col)
        
        # Balloon shadow
        draw.ellipse([cx - rx + 1, cy - ry + 3, cx + rx + 1, cy + ry + 3], fill=(10, 20, 40, 100))
        
        # Main balloon body
        draw.ellipse([cx - rx, cy - ry, cx + rx, cy + ry], fill=base_col, outline=rim_col, width=2)
        
        # Style details
        if style == "fire":
            # Swirling magma flames
            draw.ellipse([cx - rx + 4, cy - ry + 4, cx + rx - 4, cy + ry - 4], fill=inner_col)
            draw.polygon([(cx, cy - ry + 4), (cx + 6, cy + 2), (cx, cy - 2), (cx - 6, cy + 2)], fill=(255, 255, 120, 230))
            # Glowing heat rim
            draw.arc([cx - rx + 2, cy - ry + 2, cx + rx - 2, cy + ry - 2], 30, 150, fill=(255, 240, 100, 240), width=2)
        elif style == "cyber":
            # Circuit bands
            draw.ellipse([cx - rx + 4, cy - ry + 4, cx + rx - 4, cy + ry - 4], fill=inner_col)
            draw.line([(cx - rx + 3, cy), (cx + rx - 3, cy)], fill=(0, 255, 255, 230), width=2)
            draw.line([(cx, cy - ry + 3), (cx, cy + ry - 3)], fill=(255, 0, 220, 230), width=2)
            draw.rectangle([cx - 3, cy - 3, cx + 3, cy + 3], fill=(255, 255, 255, 255))
        elif style == "gold":
            # Imperial dragon gold plate
            draw.ellipse([cx - rx + 3, cy - ry + 3, cx + rx - 3, cy + ry - 3], fill=inner_col, outline=(255, 245, 140, 255), width=1)
            draw.polygon([(cx, cy - 6), (cx + 6, cy), (cx, cy + 6), (cx - 6, cy)], fill=(255, 50, 80, 255), outline=(255, 230, 90, 255))
            draw.arc([cx - rx + 2, cy - ry + 2, cx + rx - 2, cy + ry - 2], 180, 320, fill=(255, 255, 255, 220), width=2)
        elif style == "rainbow":
            # Rainbow bands
            draw.ellipse([cx - rx + 3, cy - ry + 3, cx + rx - 3, cy + ry - 3], fill=inner_col)
            colors = [(255, 60, 60), (255, 180, 40), (255, 240, 60), (50, 220, 100), (50, 180, 255), (180, 80, 255)]
            for i, c in enumerate(colors):
                draw.arc([cx - rx + 2 + i, cy - ry + 2 + i, cx + rx - 2 - i, cy + ry - 2 - i], 100 + i * 20, 240 + i * 20, fill=c + (200,), width=2)

        # Specular shine
        sh_x = cx - int(rx * 0.45)
        sh_y = cy - int(ry * 0.45)
        draw.ellipse([sh_x - 3, sh_y - 3, sh_x + 3, sh_y + 3], fill=(255, 255, 255, 240))
        draw.ellipse([sh_x + 3, sh_y + 3, sh_x + 5, sh_y + 5], fill=(255, 255, 255, 190))
        
        out_f = os.path.join(WB_DIR, f"{skin_name}_{f}.png")
        img.save(out_f)
        print("Generated", out_f)

# 1. Fire Plasma
create_balloon_frames("fire_plasma_balloon", (230, 60, 20, 245), (255, 170, 40, 255), (255, 110, 30, 255), (180, 40, 10, 255), "fire")
# 2. Cyber Neon
create_balloon_frames("cyber_neon_balloon", (20, 30, 70, 245), (0, 240, 255, 255), (60, 20, 100, 255), (0, 180, 220, 255), "cyber")
# 3. Golden Dragon
create_balloon_frames("golden_dragon_balloon", (245, 190, 35, 245), (255, 235, 120, 255), (255, 215, 60, 255), (200, 140, 20, 255), "gold")
# 4. Rainbow Prism
create_balloon_frames("rainbow_prism_balloon", (240, 245, 255, 200), (255, 255, 255, 255), (220, 240, 255, 180), (200, 220, 255, 255), "rainbow")

print("All new water balloon assets and coin created successfully!")
