import os
from PIL import Image, ImageDraw, ImageFilter
import math

ROOT = r'c:\Users\khang\Documents\Build\Boom'
BG_DIR = os.path.join(ROOT, 'assets', 'maps', 'backgrounds')
os.makedirs(BG_DIR, exist_ok=True)

W, H = 960, 640

# 1. Training Plaza (Sunny Park & Blue Sky)
def build_training_plaza():
    img = Image.new('RGB', (W, H))
    draw = ImageDraw.Draw(img)
    for y in range(H):
        # Sky gradient from azure to soft cyan
        r = int(70 + 90 * (y / H))
        g = int(145 + 75 * (y / H))
        b = int(230 + 25 * (y / H))
        draw.line([(0, y), (W, y)], fill=(r, g, b))
    # Distant green hills
    draw.polygon([(0, 420), (280, 360), (600, 400), (960, 350), (960, H), (0, H)], fill=(45, 140, 65))
    draw.polygon([(0, 480), (380, 430), (740, 470), (960, 420), (960, H), (0, H)], fill=(32, 115, 50))
    # Soft clouds
    for cx, cy in [(160, 140), (520, 110), (820, 160)]:
        draw.ellipse([cx - 90, cy - 35, cx + 90, cy + 35], fill=(255, 255, 255, 200))
        draw.ellipse([cx - 45, cy - 55, cx + 45, cy + 20], fill=(255, 255, 255, 220))
    img.save(os.path.join(BG_DIR, 'bg_training_plaza.png'))

# 2. Aqua Park (Tropical Beach & Water Waves)
def build_aqua_park():
    img = Image.new('RGB', (W, H))
    draw = ImageDraw.Draw(img)
    for y in range(H):
        r = int(25 + 20 * (y / H))
        g = int(120 + 70 * (y / H))
        b = int(210 + 40 * (y / H))
        draw.line([(0, y), (W, y)], fill=(r, g, b))
    # Ocean water layers
    draw.polygon([(0, 380), (320, 360), (680, 390), (960, 370), (960, H), (0, H)], fill=(12, 105, 175))
    draw.polygon([(0, 460), (420, 440), (820, 470), (960, 450), (960, H), (0, H)], fill=(8, 75, 140))
    # Sun glare
    draw.ellipse([720, 60, 840, 180], fill=(255, 245, 170))
    # Distant palm island silhouette
    draw.polygon([(80, 420), (220, 390), (340, 430), (0, 450)], fill=(20, 85, 95))
    img.save(os.path.join(BG_DIR, 'bg_aqua_park.png'))

# 3. Pirate Harbor (Sunset Pirate Bay)
def build_pirate_harbor():
    img = Image.new('RGB', (W, H))
    draw = ImageDraw.Draw(img)
    for y in range(H):
        # Fiery sunset
        r = int(235 - 120 * (y / H))
        g = int(95 - 40 * (y / H))
        b = int(45 + 40 * (y / H))
        draw.line([(0, y), (W, y)], fill=(r, g, b))
    # Dark ocean water
    draw.rectangle([0, 420, W, H], fill=(25, 22, 42))
    # Distant pirate galleon silhouette
    draw.polygon([(650, 430), (690, 400), (790, 400), (830, 430)], fill=(15, 12, 28))
    draw.line([(740, 400), (740, 290)], fill=(15, 12, 28), width=4)
    draw.polygon([(740, 310), (800, 330), (740, 360)], fill=(35, 28, 48))
    # Dock pilings
    for x in range(60, W, 140):
        draw.rectangle([x, 480, x + 20, H], fill=(45, 30, 22))
    img.save(os.path.join(BG_DIR, 'bg_pirate_harbor.png'))

# 4. Snow Village (Winter Forest & Peaks)
def build_snow_village():
    img = Image.new('RGB', (W, H))
    draw = ImageDraw.Draw(img)
    for y in range(H):
        r = int(140 + 60 * (y / H))
        g = int(175 + 50 * (y / H))
        b = int(215 + 35 * (y / H))
        draw.line([(0, y), (W, y)], fill=(r, g, b))
    # Snowy mountain peaks
    draw.polygon([(0, 340), (240, 180), (480, 350)], fill=(240, 250, 255))
    draw.polygon([(360, 350), (620, 150), (880, 360)], fill=(225, 240, 252))
    draw.polygon([(650, 360), (840, 210), (960, 330), (960, H), (0, H)], fill=(205, 225, 245))
    # Pine tree forest silhouettes
    for px in range(20, W, 45):
        h_tree = 70 + (px % 40)
        draw.polygon([(px, 480), (px + 18, 480 - h_tree), (px + 36, 480)], fill=(35, 75, 95))
    img.save(os.path.join(BG_DIR, 'bg_snow_village.png'))

# 5. Neon Arcade (Cyberpunk Synthwave Grid)
def build_neon_arcade():
    img = Image.new('RGB', (W, H))
    draw = ImageDraw.Draw(img)
    for y in range(H):
        r = int(25 + 55 * (y / H))
        g = int(10 + 20 * (y / H))
        b = int(55 + 75 * (y / H))
        draw.line([(0, y), (W, y)], fill=(r, g, b))
    # Neon city skyline
    buildings = [(40, 240, 80), (140, 190, 70), (230, 280, 90), (340, 160, 80), (440, 220, 100),
                 (560, 170, 75), (650, 250, 85), (760, 200, 90), (870, 230, 80)]
    for bx, by, bw in buildings:
        draw.rectangle([bx, by, bx + bw, 460], fill=(18, 8, 38), outline=(160, 40, 255), width=2)
        for wy in range(by + 20, 440, 25):
            draw.line([(bx + 8, wy), (bx + bw - 8, wy)], fill=(50, 220, 255), width=2)
    # Perspective Grid Floor
    draw.rectangle([0, 460, W, H], fill=(12, 4, 25))
    for gy in range(470, H, 25):
        draw.line([(0, gy), (W, gy)], fill=(255, 45, 180), width=1)
    for gx in range(0, W, 60):
        draw.line([(W // 2, 460), (gx, H)], fill=(45, 200, 255), width=1)
    img.save(os.path.join(BG_DIR, 'bg_neon_arcade.png'))

# 6. Lego City (Playful Toy Block Realm)
def build_lego_city():
    img = Image.new('RGB', (W, H))
    draw = ImageDraw.Draw(img)
    for y in range(H):
        r = int(55 + 40 * (y / H))
        g = int(120 + 50 * (y / H))
        b = int(205 + 30 * (y / H))
        draw.line([(0, y), (W, y)], fill=(r, g, b))
    # Huge Lego buildings in background
    lego_cols = [(220, 40, 40), (250, 200, 30), (35, 140, 230), (45, 180, 60), (220, 40, 40)]
    for idx, lx in enumerate(range(30, W - 100, 180)):
        col = lego_cols[idx % len(lego_cols)]
        draw.rectangle([lx, 260, lx + 150, H], fill=col, outline=(30, 30, 30), width=3)
        # Studs on top
        for sx in range(lx + 15, lx + 140, 35):
            draw.rectangle([sx, 245, sx + 22, 260], fill=col, outline=(30, 30, 30), width=2)
    img.save(os.path.join(BG_DIR, 'bg_lego_city.png'))

# 7. Ice Labyrinth (Arctic Aurora Cavern)
def build_ice_labyrinth():
    img = Image.new('RGB', (W, H))
    draw = ImageDraw.Draw(img)
    for y in range(H):
        r = int(8 + 15 * (y / H))
        g = int(25 + 45 * (y / H))
        b = int(65 + 85 * (y / H))
        draw.line([(0, y), (W, y)], fill=(r, g, b))
    # Aurora wave
    for ax in range(0, W, 4):
        ay = 160 + int(math.sin(ax * 0.015) * 45 + math.cos(ax * 0.03) * 20)
        draw.line([(ax, ay - 40), (ax, ay + 60)], fill=(80, 255, 200, 160), width=3)
    # Giant ice crystals
    crystals = [(120, 300, 60, 220), (340, 260, 80, 260), (620, 280, 70, 240), (840, 250, 90, 280)]
    for cx, cy, cw, ch in crystals:
        draw.polygon([(cx, cy + ch), (cx + cw // 2, cy), (cx + cw, cy + ch)], fill=(75, 185, 245), outline=(220, 250, 255), width=2)
        draw.polygon([(cx, cy + ch), (cx + cw // 2, cy), (cx + cw // 2, cy + ch)], fill=(120, 220, 255))
    img.save(os.path.join(BG_DIR, 'bg_ice_labyrinth.png'))

# 8. Egypt Temple (Pyramid Sunset Sands)
def build_egypt_temple():
    img = Image.new('RGB', (W, H))
    draw = ImageDraw.Draw(img)
    for y in range(H):
        r = int(245 - 35 * (y / H))
        g = int(140 + 20 * (y / H))
        b = int(60 + 30 * (y / H))
        draw.line([(0, y), (W, y)], fill=(r, g, b))
    # Golden Sun
    draw.ellipse([640, 80, 800, 240], fill=(255, 225, 90))
    # Distant Pyramids
    draw.polygon([(80, 440), (280, 220), (480, 440)], fill=(195, 130, 45))
    draw.polygon([(280, 220), (360, 270), (480, 440)], fill=(155, 95, 30))
    draw.polygon([(420, 450), (580, 280), (740, 450)], fill=(210, 145, 55))
    # Sand dunes
    draw.polygon([(0, 460), (360, 410), (720, 460), (960, 430), (960, H), (0, H)], fill=(215, 160, 65))
    draw.polygon([(0, 520), (450, 480), (960, 510), (960, H), (0, H)], fill=(185, 130, 45))
    img.save(os.path.join(BG_DIR, 'bg_egypt_temple.png'))

build_training_plaza()
build_aqua_park()
build_pirate_harbor()
build_snow_village()
build_neon_arcade()
build_lego_city()
build_ice_labyrinth()
build_egypt_temple()

print("All 8 custom map backgrounds successfully generated!")
