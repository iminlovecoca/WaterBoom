import os
import cv2
import numpy as np
from PIL import Image

src_path = r'C:\Users\khang\.gemini\antigravity\brain\8d5450db-5a47-4a4a-af37-9aad2b7203db\.user_uploaded\media_1786853100400.png'
img = Image.open(src_path).convert('RGBA')
arr = np.array(img)

base_assets_dir = r'c:\Users\khang\Documents\Build\Boom\assets'

def extract_connected_components(sub_arr, min_area=80):
    alpha = sub_arr[:, :, 3]
    _, thresh = cv2.threshold(alpha, 10, 255, cv2.THRESH_BINARY)
    num_labels, labels, stats, centroids = cv2.connectedComponentsWithStats(thresh)
    
    components = []
    for i in range(1, num_labels):
        x, y, w, h, area = stats[i]
        if area >= min_area:
            components.append((x, y, w, h))
            
    # Sort left to right
    components.sort(key=lambda c: c[0])
    return components

# 1. CHARACTER ANIMATIONS
char_dir = os.path.join(base_assets_dir, "characters", "ninja")
os.makedirs(char_dir, exist_ok=True)

rows_config = [
    ("idle", 0, 78),
    ("walk_down", 78, 150),
    ("walk_up", 150, 225),
    ("walk_left", 225, 305),
    ("walk_right", 305, 385),
    ("plant", 385, 465),
    ("pickup", 465, 535),
    ("hurt", 535, 605),
    ("die", 605, 680)
]

for anim_name, y_min, y_max in rows_config:
    # Crop row region (ignoring left label at x < 60 and right area at x > 615)
    row_arr = arr[y_min:y_max, 60:615]
    row_img = img.crop((60, y_min, 615, y_max))
    
    comps = extract_connected_components(row_arr, min_area=120)
    
    # Merge sub-components of the same character (e.g. detached katana, sweat drops, exclamation)
    # Group components whose horizontal center distance is < 30px
    merged_comps = []
    for c in comps:
        x, y, w, h = c
        merged = False
        for i, mc in enumerate(merged_comps):
            mx, my, mw, mh = mc
            # Check overlap or close proximity
            if max(x, mx) <= min(x + w, mx + mw) + 12:
                # Merge
                nx = min(x, mx)
                ny = min(y, my)
                nw = max(x + w, mx + mw) - nx
                nh = max(y + h, my + mh) - ny
                merged_comps[i] = (nx, ny, nw, nh)
                merged = True
                break
        if not merged:
            merged_comps.append(c)
            
    merged_comps.sort(key=lambda c: c[0])
    print(f"Character {anim_name}: extracted {len(merged_comps)} frames")
    
    for idx, (x, y, w, h) in enumerate(merged_comps):
        # Crop tight frame
        char_patch = row_img.crop((x, y, x + w, y + h))
        
        # Center on 48x48
        target_size = (48, 48)
        canvas = Image.new("RGBA", target_size, (0, 0, 0, 0))
        px = (target_size[0] - w) // 2
        py = target_size[1] - h - 3
        canvas.paste(char_patch, (px, py))
        
        canvas.save(os.path.join(char_dir, f"{anim_name}_{idx}.png"))

# 2. WATER_BALLOON (y ~ 170..250, x ~ 620..1020)
water_balloon_dir = os.path.join(base_assets_dir, "water_balloons")
os.makedirs(water_balloon_dir, exist_ok=True)
water_balloon_row = arr[170:255, 630:1010]
water_balloon_img = img.crop((630, 170, 1010, 255))
b_comps = extract_connected_components(water_balloon_row, min_area=80)
# Merge close components (sparks with water_balloon)
merged_b = []
for c in b_comps:
    x, y, w, h = c
    merged = False
    for i, mc in enumerate(merged_b):
        mx, my, mw, mh = mc
        if max(x, mx) <= min(x + w, mx + mw) + 15:
            nx = min(x, mx)
            ny = min(y, my)
            nw = max(x + w, mx + mw) - nx
            nh = max(y + h, my + mh) - ny
            merged_b[i] = (nx, ny, nw, nh)
            merged = True
            break
    if not merged:
        merged_b.append(c)
merged_b.sort(key=lambda c: c[0])
print(f"WaterBalloon frames: {len(merged_b)}")

for idx, (x, y, w, h) in enumerate(merged_b):
    b_patch = water_balloon_img.crop((x, y, x + w, y + h))
    target_size = (40, 40)
    canvas = Image.new("RGBA", target_size, (0, 0, 0, 0))
    px = (target_size[0] - w) // 2
    py = (target_size[1] - h) // 2
    canvas.paste(b_patch, (px, py))
    canvas.save(os.path.join(water_balloon_dir, f"water_balloon_{idx}.png"))

# 3. WATER_BURST (y ~ 260..410, x ~ 630..1020)
exp_dir = os.path.join(base_assets_dir, "water_bursts")
os.makedirs(exp_dir, exist_ok=True)

# Top water_burst row: spark to full cross
top_exp_row = arr[265:335, 630:1010]
top_exp_img = img.crop((630, 265, 1010, 335))
te_comps = extract_connected_components(top_exp_row, min_area=30)
te_comps.sort(key=lambda c: c[0])
print(f"Top WaterBurst frames: {len(te_comps)}")

for idx, (x, y, w, h) in enumerate(te_comps):
    e_patch = top_exp_img.crop((x, y, x + w, y + h))
    target_size = (48, 48)
    canvas = Image.new("RGBA", target_size, (0, 0, 0, 0))
    px = (target_size[0] - w) // 2
    py = (target_size[1] - h) // 2
    canvas.paste(e_patch, (px, py))
    canvas.save(os.path.join(exp_dir, f"exp_stage1_{idx}.png"))

# Bottom water_burst row: cross to foam
bot_exp_row = arr[335:405, 630:1010]
bot_exp_img = img.crop((630, 335, 1010, 405))
be_comps = extract_connected_components(bot_exp_row, min_area=30)
be_comps.sort(key=lambda c: c[0])
print(f"Bottom WaterBurst frames: {len(be_comps)}")

for idx, (x, y, w, h) in enumerate(be_comps):
    e_patch = bot_exp_img.crop((x, y, x + w, y + h))
    target_size = (48, 48)
    canvas = Image.new("RGBA", target_size, (0, 0, 0, 0))
    px = (target_size[0] - w) // 2
    py = (target_size[1] - h) // 2
    canvas.paste(e_patch, (px, py))
    canvas.save(os.path.join(exp_dir, f"exp_stage2_{idx}.png"))

# Also save canonical water_burst center and rays from the sheet's cross and bursts
# Frame 3 in top water_burst is the perfect cross center, Frame 4 is large cross
if len(te_comps) >= 4:
    x, y, w, h = te_comps[3]
    top_exp_img.crop((x, y, x + w, y + h)).resize((40, 40)).save(os.path.join(exp_dir, "center_0.png"))
if len(te_comps) >= 5:
    x, y, w, h = te_comps[4]
    top_exp_img.crop((x, y, x + w, y + h)).resize((40, 40)).save(os.path.join(exp_dir, "center_1.png"))
if len(te_comps) >= 6:
    x, y, w, h = te_comps[5]
    top_exp_img.crop((x, y, x + w, y + h)).resize((40, 40)).save(os.path.join(exp_dir, "center_2.png"))
if len(bot_exp_comps := be_comps):
    x, y, w, h = bot_exp_comps[-1] # Foam cloud
    bot_exp_img.crop((x, y, x + w, y + h)).resize((40, 40)).save(os.path.join(exp_dir, "center_3.png"))

# 4. BUBBLE (y ~ 440..510, x ~ 630..1010)
eff_dir = os.path.join(base_assets_dir, "effects")
os.makedirs(eff_dir, exist_ok=True)
bubble_row = arr[440:510, 630:1010]
bubble_img = img.crop((630, 440, 1010, 510))
bub_comps = extract_connected_components(bubble_row, min_area=80)
bub_comps.sort(key=lambda c: c[0])
print(f"Bubble frames: {len(bub_comps)}")

for idx, (x, y, w, h) in enumerate(bub_comps):
    bub_patch = bubble_img.crop((x, y, x + w, y + h))
    target_size = (40, 40)
    canvas = Image.new("RGBA", target_size, (0, 0, 0, 0))
    px = (target_size[0] - w) // 2
    py = (target_size[1] - h) // 2
    canvas.paste(bub_patch, (px, py))
    canvas.save(os.path.join(eff_dir, f"bubble_{idx}.png"))
# Save canonical bubble.png
if len(bub_comps) > 0:
    x, y, w, h = bub_comps[-1] # largest bubble
    bubble_img.crop((x, y, x + w, y + h)).resize((40, 40)).save(os.path.join(eff_dir, "bubble.png"))

# 5. SHADOW (y ~ 540..585, x ~ 630..950)
shadow_row = arr[540:585, 630:950]
shadow_img = img.crop((630, 540, 950, 585))
sh_comps = extract_connected_components(shadow_row, min_area=20)
sh_comps.sort(key=lambda c: c[0])
print(f"Shadow frames: {len(sh_comps)}")
for idx, (x, y, w, h) in enumerate(sh_comps):
    sh_patch = shadow_img.crop((x, y, x + w, y + h))
    sh_patch.save(os.path.join(eff_dir, f"shadow_{idx}.png"))
if len(sh_comps) > 0:
    x, y, w, h = sh_comps[1] if len(sh_comps) > 1 else sh_comps[0]
    shadow_img.crop((x, y, x + w, y + h)).resize((32, 16)).save(os.path.join(eff_dir, "shadow.png"))

# 6. AVATARS (y ~ 20..100, x ~ 630..1010)
ui_dir = os.path.join(base_assets_dir, "ui")
os.makedirs(ui_dir, exist_ok=True)
avatar_row = arr[20:100, 630:1010]
avatar_img = img.crop((630, 20, 1010, 100))
av_comps = extract_connected_components(avatar_row, min_area=150)
av_comps.sort(key=lambda c: c[0])
print(f"Avatar portraits: {len(av_comps)}")

for idx, (x, y, w, h) in enumerate(av_comps):
    av_patch = avatar_img.crop((x, y, x + w, y + h))
    av_patch.save(os.path.join(ui_dir, f"avatar_ninja_{idx}.png"))
if len(av_comps) > 0:
    avatar_img.crop(av_comps[0]).save(os.path.join(char_dir, "preview.png"))

print("ALL ASSETS FROM SPRITESHEET SUCCESSFULLY EXTRACTED!")
