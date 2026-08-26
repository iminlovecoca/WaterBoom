import os
from PIL import Image, ImageDraw, ImageFont, ImageFilter
import numpy as np

ROOT = r'c:\Users\khang\Documents\Build\Boom'
UPLOAD_PATH = r'C:\Users\khang\.gemini\antigravity\brain\8d5450db-5a47-4a4a-af37-9aad2b7203db\.user_uploaded\media_1786947625973.png'
SPLASH_DIR = os.path.join(ROOT, 'assets', 'ui', 'splash')
os.makedirs(SPLASH_DIR, exist_ok=True)

# 1. Load cat image
cat_img = Image.open(UPLOAD_PATH).convert('RGBA')

# Auto-crop to content
arr = np.array(cat_img)
alpha = arr[:, :, 3]
has_r = np.any(alpha > 15, axis=1)
has_c = np.any(alpha > 15, axis=0)
if np.any(has_r) and np.any(has_c):
    ymin, ymax = np.where(has_r)[0][0], np.where(has_r)[0][-1] + 1
    xmin, xmax = np.where(has_c)[0][0], np.where(has_c)[0][-1] + 1
    cat_img = cat_img.crop((xmin, ymin, xmax, ymax))

cat_logo_path = os.path.join(SPLASH_DIR, 'coke_cat_logo.png')
cat_img.save(cat_logo_path)
print("Saved cat logo to", cat_logo_path)

# 2. Build 960x720 cinematic Publisher Splash Background
W, H = 960, 720
splash = Image.new('RGBA', (W, H), (10, 18, 38, 255))
draw = ImageDraw.Draw(splash)

# Radial gradient background
center_x, center_y = W // 2, H // 2 - 40
for r in range(450, 0, -5):
    alpha_factor = 1.0 - (r / 450.0)
    # Deep blue / cyan center glow
    col = (
        int(10 + 20 * alpha_factor),
        int(25 + 65 * alpha_factor),
        int(60 + 130 * alpha_factor),
        255
    )
    draw.ellipse([center_x - r, center_y - r, center_x + r, center_y + r], fill=col)

# Circular badge for the cat
badge_size = 280
badge_x = (W - badge_size) // 2
badge_y = 110

# Glow behind badge
for g in range(30, 0, -3):
    glow_col = (100, 220, 255, int(15 * (1.0 - g / 30.0)))
    draw.ellipse([badge_x - g, badge_y - g, badge_x + badge_size + g, badge_y + badge_size + g], fill=glow_col)

# Outer golden-cyan ring
draw.ellipse([badge_x - 6, badge_y - 6, badge_x + badge_size + 6, badge_y + badge_size + 6], fill=(255, 215, 80, 255))
draw.ellipse([badge_x - 2, badge_y - 2, badge_x + badge_size + 2, badge_y + badge_size + 2], fill=(12, 45, 90, 255))
draw.ellipse([badge_x, badge_y, badge_x + badge_size, badge_y + badge_size], fill=(245, 248, 255, 255))

# Fit cat inside circular mask
cat_resized = cat_img.resize((badge_size - 16, badge_size - 16), Image.Resampling.LANCZOS)
cat_mask = Image.new('L', (badge_size - 16, badge_size - 16), 0)
mask_draw = ImageDraw.Draw(cat_mask)
mask_draw.ellipse([0, 0, badge_size - 16, badge_size - 16], fill=255)

splash.paste(cat_resized, (badge_x + 8, badge_y + 8), cat_mask)

# Save splash background
splash_bg_path = os.path.join(SPLASH_DIR, 'publisher_splash_bg.png')
splash.save(splash_bg_path)
print("Saved publisher splash image to", splash_bg_path)
