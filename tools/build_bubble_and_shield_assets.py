import os
from PIL import Image, ImageDraw, ImageFilter
import math

ROOT = r'c:\Users\khang\Documents\Build\Boom'
ITEMS_DIR = os.path.join(ROOT, 'assets', 'items')
VFX_DIR = os.path.join(ROOT, 'assets', 'vfx')
os.makedirs(ITEMS_DIR, exist_ok=True)
os.makedirs(VFX_DIR, exist_ok=True)

# 1. Generate item_shield.png (40x40)
shield_img = Image.new('RGBA', (40, 40), (0, 0, 0, 0))
draw = ImageDraw.Draw(shield_img)

# Outer golden-cyan shield polygon
shield_poly = [
    (20, 3), (35, 8), (35, 24), (20, 37), (5, 24), (5, 8)
]
draw.polygon(shield_poly, fill=(255, 215, 60, 255), outline=(10, 40, 90, 255))

# Inner metallic cyan shield plate
inner_poly = [
    (20, 7), (31, 11), (31, 22), (20, 33), (9, 22), (9, 11)
]
draw.polygon(inner_poly, fill=(35, 180, 255, 255), outline=(20, 80, 160, 255))

# Bright crest / star in center
draw.polygon([(20, 13), (23, 19), (29, 20), (24, 24), (26, 30), (20, 26), (14, 30), (16, 24), (11, 20), (17, 19)], fill=(255, 255, 255, 255))

shield_path = os.path.join(ITEMS_DIR, 'item_shield.png')
shield_img.save(shield_path)
print("Created", shield_path)

# 2. Generate Bubble Pop Burst Sheet (8 frames of 64x64)
pop_frames = []
for i in range(8):
    prog = i / 7.0
    f = Image.new('RGBA', (64, 64), (0, 0, 0, 0))
    d = ImageDraw.Draw(f)
    cx, cy = 32, 32
    if i == 0:
        # Initial bubble swell
        d.ellipse([cx - 24, cy - 24, cx + 24, cy + 24], fill=(80, 200, 255, 120), outline=(220, 250, 255, 230), width=3)
    elif i == 1:
        # Crack / tension rupture
        d.ellipse([cx - 26, cy - 25, cx + 26, cy + 25], fill=(120, 220, 255, 180), outline=(255, 255, 255, 255), width=4)
    else:
        # Water droplets bursting outward
        num_drops = 10
        burst_rad = 18.0 + prog * 26.0
        drop_size = max(1, int(5.0 * (1.0 - prog * 0.8)))
        alpha = int(255 * (1.0 - prog * 0.85))
        for n in range(num_drops):
            angle = (n / float(num_drops)) * 2.0 * math.pi + (i * 0.3)
            dx = cx + math.cos(angle) * burst_rad
            dy = cy + math.sin(angle) * burst_rad
            d.ellipse([dx - drop_size, dy - drop_size, dx + drop_size, dy + drop_size], fill=(140, 230, 255, alpha), outline=(255, 255, 255, alpha))
            
        # Central splash ring
        ring_rad = 8.0 + prog * 16.0
        d.ellipse([cx - ring_rad, cy - ring_rad, cx + ring_rad, cy + ring_rad], outline=(200, 245, 255, int(alpha * 0.7)), width=2)
    pop_frames.append(f)

# Combine into horizontal sheet
pop_sheet = Image.new('RGBA', (64 * 8, 64), (0, 0, 0, 0))
for i, fr in enumerate(pop_frames):
    pop_sheet.paste(fr, (i * 64, 0))
pop_sheet_path = os.path.join(VFX_DIR, 'bubble_pop_burst.png')
pop_sheet.save(pop_sheet_path)
print("Created", pop_sheet_path)

# 3. Generate Giant Boss Water Bubble Sheet (160x160)
boss_bubble = Image.new('RGBA', (160, 160), (0, 0, 0, 0))
d_boss = ImageDraw.Draw(boss_bubble)
cx, cy = 80, 80
r = 74

# Soft outer water aura
for g in range(12, 0, -2):
    d_boss.ellipse([cx - r - g, cy - r - g, cx + r + g, cy + r + g], fill=(60, 180, 255, int(20 * (1.0 - g / 12.0))))

# Main water sphere
d_boss.ellipse([cx - r, cy - r, cx + r, cy + r], fill=(40, 160, 255, 110), outline=(200, 245, 255, 240), width=5)
# Inner refraction ring
d_boss.ellipse([cx - r + 8, cy - r + 8, cx + r - 8, cy + r - 8], outline=(100, 220, 255, 90), width=4)
# Glass highlight
d_boss.ellipse([cx - 45, cy - 50, cx - 15, cy - 25], fill=(255, 255, 255, 210))
d_boss.ellipse([cx - 52, cy - 58, cx - 42, cy - 48], fill=(255, 255, 255, 240))
# Lower specular arc
d_boss.arc([cx - r + 15, cy - r + 15, cx + r - 15, cy + r - 15], 30, 130, fill=(255, 255, 255, 160), width=4)

boss_bubble_path = os.path.join(VFX_DIR, 'giant_boss_bubble.png')
boss_bubble.save(boss_bubble_path)
print("Created", boss_bubble_path)

# 4. Generate Shield Aura VFX (64x64)
shield_aura = Image.new('RGBA', (64, 64), (0, 0, 0, 0))
d_sa = ImageDraw.Draw(shield_aura)
# Shimmering golden hex barrier
hex_poly = [
    (32, 4), (56, 18), (56, 46), (32, 60), (8, 46), (8, 18)
]
d_sa.polygon(hex_poly, fill=(255, 220, 50, 45), outline=(255, 240, 120, 220), width=3)
d_sa.polygon([(32, 10), (50, 21), (50, 43), (32, 54), (14, 43), (14, 21)], outline=(120, 240, 255, 180), width=2)
shield_aura_path = os.path.join(VFX_DIR, 'shield_aura.png')
shield_aura.save(shield_aura_path)
print("Created", shield_aura_path)
