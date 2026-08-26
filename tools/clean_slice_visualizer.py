import os
import cv2
import numpy as np
from PIL import Image

src_path = r'C:\Users\khang\.gemini\antigravity\brain\8d5450db-5a47-4a4a-af37-9aad2b7203db\.user_uploaded\media_1786853100400.png'
img = Image.open(src_path).convert('RGBA')
arr = np.array(img)

base_assets = r'c:\Users\khang\Documents\Build\Boom\assets'
char_dir = os.path.join(base_assets, "characters", "ninja")
os.makedirs(char_dir, exist_ok=True)

# Let's inspect each row in the character area x in [60, 600]
# To prevent any bleeding from adjacent rows:
# Row 0 (IDLE): y in [12, 78]
# Row 1 (WALK DOWN): y in [85, 155]
# Row 2 (WALK UP): y in [162, 235]
# Row 3 (WALK LEFT): y in [240, 310]
# Row 4 (WALK RIGHT): y in [318, 388]
# Row 5 (PLANT WATER_BALLOON): y in [395, 465]
# Row 6 (PICKUP): y in [470, 532]
# Row 7 (HURT): y in [538, 600]
# Row 8 (DIE): y in [606, 660]

rows_def = [
    ("idle", 12, 78, 7),
    ("walk_down", 85, 155, 7),
    ("walk_up", 162, 235, 7),
    ("walk_left", 240, 310, 7),
    ("walk_right", 318, 388, 7),
    ("plant", 395, 465, 6),
    ("pickup", 470, 532, 6),
    ("hurt", 538, 600, 6),
    ("die", 606, 660, 5)
]

for anim_name, y0, y1, expected_count in rows_def:
    # 1. Get row alpha
    row_arr = arr[y0:y1, 60:600]
    alpha = (row_arr[:, :, 3] > 20).astype(np.uint8)
    
    # 2. Find connected components in this specific row
    num_labels, labels, stats, centroids = cv2.connectedComponentsWithStats(alpha)
    
    components = []
    for i in range(1, num_labels):
        x, y, w, h, area = stats[i]
        # Ignore tiny specks (< 30 px area)
        if area >= 30:
            components.append((x + 60, y + y0, w, h))
            
    # Sort left to right
    components.sort(key=lambda c: c[0])
    
    # Merge parts belonging to the same character (katana, sweat drops, exclamations)
    merged = []
    for c in components:
        x, y, w, h = c
        did_merge = False
        for m_i, (mx, my, mw, mh) in enumerate(merged):
            # If horizontally overlapping or within 6 pixels
            if max(x, mx) <= min(x + w, mx + mw) + 6:
                nx = min(x, mx)
                ny = min(y, my)
                nw = max(x + w, mx + mw) - nx
                nh = max(y + h, my + mh) - ny
                merged[m_i] = (nx, ny, nw, nh)
                did_merge = True
                break
        if not did_merge:
            merged.append(c)
            
    merged.sort(key=lambda c: c[0])
    print(f"Row {anim_name}: found {len(merged)} characters (expected {expected_count})")
    
    # Save clean centered frames
    for idx, (x, y, w, h) in enumerate(merged):
        # Crop tight with zero bleeding
        cropped = img.crop((x, y, x + w, y + h))
        
        # 48x48 standard canvas
        target_size = (48, 48)
        canvas = Image.new("RGBA", target_size, (0, 0, 0, 0))
        
        cw, ch = cropped.size
        # Fit inside canvas without overflowing
        if cw > 46 or ch > 46:
            scale = min(46.0 / cw, 46.0 / ch)
            new_w = int(cw * scale)
            new_h = int(ch * scale)
            cropped = cropped.resize((new_w, new_h), Image.Resampling.NEAREST)
            cw, ch = new_w, new_h
            
        px = (target_size[0] - cw) // 2
        py = target_size[1] - ch - 2
        canvas.paste(cropped, (px, py))
        
        canvas.save(os.path.join(char_dir, f"{anim_name}_{idx}.png"))

# WATER_BALLOON (y in [120, 195], x in [630, 990])
water_balloon_dir = os.path.join(base_assets, "water_balloons")
os.makedirs(water_balloon_dir, exist_ok=True)
water_balloon_alpha = (arr[120:195, 630:990, 3] > 20).astype(np.uint8)
num_b, labels_b, stats_b, _ = cv2.connectedComponentsWithStats(water_balloon_alpha)
b_comps = []
for i in range(1, num_b):
    x, y, w, h, area = stats_b[i]
    if area >= 30:
        b_comps.append((x + 630, y + 120, w, h))
merged_b = []
for c in sorted(b_comps, key=lambda c: c[0]):
    x, y, w, h = c
    did_merge = False
    for m_i, (mx, my, mw, mh) in enumerate(merged_b):
        if max(x, mx) <= min(x + w, mx + mw) + 6:
            nx = min(x, mx)
            ny = min(y, my)
            nw = max(x + w, mx + mw) - nx
            nh = max(y + h, my + mh) - ny
            merged_b[m_i] = (nx, ny, nw, nh)
            did_merge = True
            break
    if not did_merge:
        merged_b.append(c)
merged_b.sort(key=lambda c: c[0])
print(f"WaterBalloon: found {len(merged_b)} frames")

for idx, (x, y, w, h) in enumerate(merged_b):
    cropped = img.crop((x, y, x + w, y + h))
    canvas = Image.new("RGBA", (36, 36), (0, 0, 0, 0))
    cw, ch = cropped.size
    if cw > 34 or ch > 34:
        scale = min(34.0 / cw, 34.0 / ch)
        cropped = cropped.resize((int(cw*scale), int(ch*scale)), Image.Resampling.NEAREST)
        cw, ch = cropped.size
    px = (36 - cw) // 2
    py = (36 - ch) // 2
    canvas.paste(cropped, (px, py))
    canvas.save(os.path.join(water_balloon_dir, f"water_balloon_{idx}.png"))

print("Clean extraction complete.")
