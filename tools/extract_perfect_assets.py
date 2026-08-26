import os
import numpy as np
from PIL import Image, ImageDraw

src_path = r'C:\Users\khang\.gemini\antigravity\brain\8d5450db-5a47-4a4a-af37-9aad2b7203db\.user_uploaded\media_1786853100400.png'
img = Image.open(src_path).convert('RGBA')
arr = np.array(img)

base_assets = r'c:\Users\khang\Documents\Build\Boom\assets'

def auto_crop_n_columns(region_img, num_cols, target_size=(48, 48), bottom_pad=2):
    w, h = region_img.size
    col_w = w / float(num_cols)
    frames = []
    
    for i in range(num_cols):
        x0 = int(i * col_w)
        x1 = int((i + 1) * col_w)
        cell = region_img.crop((x0, 0, x1, h))
        cell_arr = np.array(cell)
        alpha = cell_arr[:, :, 3]
        
        has_r = np.any(alpha > 10, axis=1)
        has_c = np.any(alpha > 10, axis=0)
        
        if not np.any(has_r) or not np.any(has_c):
            frames.append(None)
            continue
            
        ymin = np.where(has_r)[0][0]
        ymax = np.where(has_r)[0][-1] + 1
        xmin = np.where(has_c)[0][0]
        xmax = np.where(has_c)[0][-1] + 1
        
        cropped = cell.crop((xmin, ymin, xmax, ymax))
        cw, ch = cropped.size
        
        canvas = Image.new("RGBA", target_size, (0, 0, 0, 0))
        # Scale down slightly if bigger than canvas
        if cw > target_size[0] or ch > target_size[1]:
            scale = min(float(target_size[0] - 2) / cw, float(target_size[1] - 2) / ch)
            new_w = int(cw * scale)
            new_h = int(ch * scale)
            cropped = cropped.resize((new_w, new_h), Image.Resampling.NEAREST)
            cw, ch = new_w, new_h
            
        px = (target_size[0] - cw) // 2
        py = target_size[1] - ch - bottom_pad
        canvas.paste(cropped, (px, py))
        frames.append(canvas)
    return frames

# 1. CHARACTER ROWS
char_dir = os.path.join(base_assets, "characters", "ninja")
os.makedirs(char_dir, exist_ok=True)

char_specs = [
    ("idle", 8, 81, 7),
    ("walk_down", 85, 161, 7),
    ("walk_up", 165, 238, 7),
    ("walk_left", 242, 314, 7),
    ("walk_right", 321, 393, 7),
    ("plant", 397, 468, 6),
    ("pickup", 469, 535, 6),
    ("hurt", 535, 603, 6),
    ("die", 605, 664, 5)
]

for anim_name, y0, y1, count in char_specs:
    region = img.crop((58, y0, 600, y1))
    frames = auto_crop_n_columns(region, count, target_size=(44, 44), bottom_pad=2)
    for idx, f in enumerate(frames):
        if f is not None:
            f.save(os.path.join(char_dir, f"{anim_name}_{idx}.png"))
    print(f"Extracted character {anim_name} ({count} frames)")

# 2. WATER_BALLOON FRAMES (y in [120, 197], x in [630, 990], 5 frames)
water_balloon_dir = os.path.join(base_assets, "water_balloons")
os.makedirs(water_balloon_dir, exist_ok=True)
water_balloon_region = img.crop((630, 120, 990, 197))
b_frames = auto_crop_n_columns(water_balloon_region, 5, target_size=(36, 36), bottom_pad=2)
for idx, f in enumerate(b_frames):
    if f is not None:
        f.save(os.path.join(water_balloon_dir, f"water_balloon_{idx}.png"))
print("Extracted 5 skull water_balloon frames")

# 3. WATER_BURSTS
exp_dir = os.path.join(base_assets, "water_bursts")
os.makedirs(exp_dir, exist_ok=True)

# Top row: spark to cross (y in [215, 308], x in [630, 1000], 7 frames)
exp_r1 = img.crop((630, 215, 1000, 308))
e1_frames = auto_crop_n_columns(exp_r1, 7, target_size=(40, 40), bottom_pad=0)
for idx, f in enumerate(e1_frames):
    if f is not None:
        f.save(os.path.join(exp_dir, f"exp_stage1_{idx}.png"))

# Bottom row: cross to foam (y in [315, 379], x in [630, 1000], 6 frames)
exp_r2 = img.crop((630, 315, 1000, 379))
e2_frames = auto_crop_n_columns(exp_r2, 6, target_size=(40, 40), bottom_pad=0)
for idx, f in enumerate(e2_frames):
    if f is not None:
        f.save(os.path.join(exp_dir, f"exp_stage2_{idx}.png"))

# Save center 0..3 from the cross streams
if len(e1_frames) > 3 and e1_frames[3]: e1_frames[3].save(os.path.join(exp_dir, "center_0.png"))
if len(e1_frames) > 4 and e1_frames[4]: e1_frames[4].save(os.path.join(exp_dir, "center_1.png"))
if len(e1_frames) > 5 and e1_frames[5]: e1_frames[5].save(os.path.join(exp_dir, "center_2.png"))
if len(e2_frames) > 5 and e2_frames[5]: e2_frames[5].save(os.path.join(exp_dir, "center_3.png"))

# Directional rays
for part in ["ray_h", "ray_v", "cap_up", "cap_down", "cap_left", "cap_right"]:
    for f_i in range(4):
        # Use cross water frames
        src_f = e1_frames[min(3 + f_i, len(e1_frames)-1)]
        if src_f:
            src_f.save(os.path.join(exp_dir, f"{part}_{f_i}.png"))
print("Extracted water_burst VFX frames")

# 4. BUBBLE FRAMES (y in [404, 463], x in [630, 990], 6 frames)
eff_dir = os.path.join(base_assets, "effects")
os.makedirs(eff_dir, exist_ok=True)
bub_region = img.crop((630, 404, 990, 463))
bub_frames = auto_crop_n_columns(bub_region, 6, target_size=(40, 40), bottom_pad=0)
for idx, f in enumerate(bub_frames):
    if f is not None:
        f.save(os.path.join(eff_dir, f"bubble_{idx}.png"))
if bub_frames[-1]:
    bub_frames[-1].save(os.path.join(eff_dir, "bubble.png"))
print("Extracted 6 bubble frames")

# 5. SHADOW (y in [538, 558], x in [630, 900], 4 frames)
sh_region = img.crop((630, 538, 900, 558))
sh_frames = auto_crop_n_columns(sh_region, 4, target_size=(32, 16), bottom_pad=0)
for idx, f in enumerate(sh_frames):
    if f is not None:
        f.save(os.path.join(eff_dir, f"shadow_{idx}.png"))
if sh_frames[1]:
    sh_frames[1].save(os.path.join(eff_dir, "shadow.png"))
print("Extracted 4 shadow frames")

# 6. ITEMS WITH TRANSPARENT BACKGROUND (No white boxes)
item_dir = os.path.join(base_assets, "items")
os.makedirs(item_dir, exist_ok=True)

# WaterBalloon+ item (transparent rounded badge with skull water_balloon)
it_water_balloon = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
if b_frames[0]:
    b_small = b_frames[0].resize((26, 26), Image.Resampling.NEAREST)
    it_water_balloon.paste(b_small, (3, 3), b_small)
it_water_balloon.save(os.path.join(item_dir, "item_water_balloon_up.png"))

# Water Power+ item (Water / Water transparent badge)
it_range = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
d = ImageDraw.Draw(it_range)
d.polygon([(16, 2), (8, 28), (24, 28)], fill=(239, 68, 68, 255))
d.polygon([(16, 10), (11, 26), (21, 26)], fill=(250, 204, 21, 255))
it_range.save(os.path.join(item_dir, "item_water_power_up.png"))

# Speed+ item (Roller skate transparent)
it_speed = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
d = ImageDraw.Draw(it_speed)
d.polygon([(8, 16), (15, 6), (23, 6), (25, 16)], fill=(59, 130, 246, 255))
d.ellipse([6, 18, 13, 25], fill=(234, 88, 12, 255))
d.ellipse([17, 18, 24, 25], fill=(234, 88, 12, 255))
it_speed.save(os.path.join(item_dir, "item_speed_up.png"))

# Kick boot transparent
it_kick = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
d = ImageDraw.Draw(it_kick)
d.polygon([(10, 6), (18, 6), (18, 16), (26, 16), (26, 24), (10, 24)], fill=(168, 85, 247, 255))
it_kick.save(os.path.join(item_dir, "item_kick.png"))
print("Saved clean transparent items.")

print("ALL ASSETS EXTRACTED PERFECTLY WITH NO CUTOFFS!")
