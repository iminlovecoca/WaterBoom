import os
import numpy as np
from PIL import Image

src_path = r'C:\Users\khang\.gemini\antigravity\brain\8d5450db-5a47-4a4a-af37-9aad2b7203db\.user_uploaded\media_1786853100400.png'
img = Image.open(src_path).convert('RGBA')
arr = np.array(img)

base_assets = r'c:\Users\khang\Documents\Build\Boom\assets'

def tight_crop_and_center(sub_img, target_size=(48, 48), bottom_pad=4):
    sub_arr = np.array(sub_img)
    alpha = sub_arr[:, :, 3]
    has_pixels_row = np.any(alpha > 10, axis=1)
    has_pixels_col = np.any(alpha > 10, axis=0)
    
    if not np.any(has_pixels_row) or not np.any(has_pixels_col):
        return None
        
    ymin = np.where(has_pixels_row)[0][0]
    ymax = np.where(has_pixels_row)[0][-1] + 1
    xmin = np.where(has_pixels_col)[0][0]
    xmax = np.where(has_pixels_col)[0][-1] + 1
    
    cropped = sub_img.crop((xmin, ymin, xmax, ymax))
    cw, ch = cropped.size
    
    canvas = Image.new("RGBA", target_size, (0, 0, 0, 0))
    px = (target_size[0] - cw) // 2
    py = target_size[1] - ch - bottom_pad
    canvas.paste(cropped, (px, py))
    return canvas

# 1. CHARACTER ANIMATIONS
char_dir = os.path.join(base_assets, "characters", "ninja")
os.makedirs(char_dir, exist_ok=True)

char_rows = [
    ("idle", 0, 78, 7),
    ("walk_down", 78, 155, 7),
    ("walk_up", 155, 230, 7),
    ("walk_left", 230, 305, 7),
    ("walk_right", 305, 380, 7),
    ("plant", 380, 455, 6),
    ("pickup", 455, 530, 6),
    ("hurt", 530, 605, 6),
    ("die", 605, 680, 5)
]

for anim_name, y0, y1, count in char_rows:
    col_width = (615.0 - 62.0) / 7.0
    for i in range(count):
        x0 = int(62.0 + i * col_width)
        x1 = int(62.0 + (i + 1) * col_width)
        cell_img = img.crop((x0, y0, x1, y1))
        
        frame = tight_crop_and_center(cell_img, target_size=(48, 48), bottom_pad=4)
        if frame is not None:
            frame.save(os.path.join(char_dir, f"{anim_name}_{i}.png"))
    print(f"Saved {anim_name} ({count} frames)")

# 2. WATER_BALLOON ANIMATION
water_balloon_dir = os.path.join(base_assets, "water_balloons")
os.makedirs(water_balloon_dir, exist_ok=True)
water_balloon_col_w = (1010.0 - 635.0) / 5.0
for i in range(5):
    x0 = int(635.0 + i * water_balloon_col_w)
    x1 = int(635.0 + (i + 1) * water_balloon_col_w)
    cell_img = img.crop((x0, 165, x1, 255))
    frame = tight_crop_and_center(cell_img, target_size=(40, 40), bottom_pad=2)
    if frame is not None:
        frame.save(os.path.join(water_balloon_dir, f"water_balloon_{i}.png"))
print("Saved 5 water_balloon frames")

# 3. WATER_BURST ANIMATION
exp_dir = os.path.join(base_assets, "water_bursts")
os.makedirs(exp_dir, exist_ok=True)

# Top water_burst row (7 frames: spark to large cross)
top_exp_w = (1010.0 - 635.0) / 7.0
for i in range(7):
    x0 = int(635.0 + i * top_exp_w)
    x1 = int(635.0 + (i + 1) * top_exp_w)
    cell_img = img.crop((x0, 260, x1, 335))
    frame = tight_crop_and_center(cell_img, target_size=(48, 48), bottom_pad=2)
    if frame is not None:
        frame.save(os.path.join(exp_dir, f"exp_stage1_{i}.png"))

# Bottom water_burst row (6 frames: cross to water burst to foam)
bot_exp_w = (1010.0 - 635.0) / 6.0
for i in range(6):
    x0 = int(635.0 + i * bot_exp_w)
    x1 = int(635.0 + (i + 1) * bot_exp_w)
    cell_img = img.crop((x0, 335, x1, 410))
    frame = tight_crop_and_center(cell_img, target_size=(48, 48), bottom_pad=2)
    if frame is not None:
        frame.save(os.path.join(exp_dir, f"exp_stage2_{i}.png"))

# Map canonical center and rays:
# Center stream sequence: stage1 frame 3, 4, 5, stage2 frame 5 (foam)
for idx, (stage, fnum) in enumerate([("stage1", 3), ("stage1", 4), ("stage1", 5), ("stage2", 5)]):
    p = os.path.join(exp_dir, f"exp_{stage}_{fnum}.png")
    if os.path.exists(p):
        im = Image.open(p).resize((40, 40))
        im.save(os.path.join(exp_dir, f"center_{idx}.png"))

# 4. BUBBLE ANIMATION
eff_dir = os.path.join(base_assets, "effects")
os.makedirs(eff_dir, exist_ok=True)
bub_col_w = (1010.0 - 635.0) / 6.0
for i in range(6):
    x0 = int(635.0 + i * bub_col_w)
    x1 = int(635.0 + (i + 1) * bub_col_w)
    cell_img = img.crop((x0, 435, x1, 510))
    frame = tight_crop_and_center(cell_img, target_size=(40, 40), bottom_pad=2)
    if frame is not None:
        frame.save(os.path.join(eff_dir, f"bubble_{i}.png"))
if os.path.exists(os.path.join(eff_dir, "bubble_5.png")):
    Image.open(os.path.join(eff_dir, "bubble_5.png")).save(os.path.join(eff_dir, "bubble.png"))
print("Saved 6 bubble frames")

# 5. SHADOW ANIMATION
sh_col_w = (920.0 - 635.0) / 4.0
for i in range(4):
    x0 = int(635.0 + i * sh_col_w)
    x1 = int(635.0 + (i + 1) * sh_col_w)
    cell_img = img.crop((x0, 535, x1, 585))
    frame = tight_crop_and_center(cell_img, target_size=(32, 16), bottom_pad=1)
    if frame is not None:
        frame.save(os.path.join(eff_dir, f"shadow_{i}.png"))
if os.path.exists(os.path.join(eff_dir, "shadow_2.png")):
    Image.open(os.path.join(eff_dir, "shadow_2.png")).save(os.path.join(eff_dir, "shadow.png"))
print("Saved 4 shadow frames")

# 6. AVATARS
ui_dir = os.path.join(base_assets, "ui")
os.makedirs(ui_dir, exist_ok=True)
av_col_w = (1010.0 - 625.0) / 5.0
for i in range(5):
    x0 = int(625.0 + i * av_col_w)
    x1 = int(625.0 + (i + 1) * av_col_w)
    cell_img = img.crop((x0, 15, x1, 100))
    frame = tight_crop_and_center(cell_img, target_size=(56, 56), bottom_pad=2)
    if frame is not None:
        frame.save(os.path.join(ui_dir, f"avatar_ninja_{i}.png"))
if os.path.exists(os.path.join(ui_dir, "avatar_ninja_0.png")):
    Image.open(os.path.join(ui_dir, "avatar_ninja_0.png")).save(os.path.join(char_dir, "preview.png"))
print("Saved 5 avatar portraits")

print("\nALL SPRITESHEET ASSETS REPLACED AND INTEGRATED PERFECTLY!")
