import os
import numpy as np
from PIL import Image

src_path = r'C:\Users\khang\.gemini\antigravity\brain\8d5450db-5a47-4a4a-af37-9aad2b7203db\.user_uploaded\media_1786853100400.png'
img = Image.open(src_path).convert('RGBA')
arr = np.array(img)

# Let's inspect the layout regions:
# 1. Left side (x < 620): Character animations
# Rows vertically (approximately 9 rows from y=0 to y=682):
# Row 0: IDLE
# Row 1: WALK DOWN
# Row 2: WALK UP
# Row 3: WALK LEFT
# Row 4: WALK RIGHT
# Row 5: PLANT WATER_BALLOON
# Row 6: PICKUP
# Row 7: HURT
# Row 8: DIE

# 2. Right side (x >= 620):
# y ~ 20 to 100: Avatars / Expressions
# y ~ 160 to 220: WATER_BALLOON (5 frames)
# y ~ 270 to 390: WATER_BURST (top & bottom rows)
# y ~ 430 to 480: BUBBLE (6 frames)
# y ~ 530 to 570: SHADOW (4 sizes)
# y ~ 600 to 680: TILESCALE CHECK (1 frame)

# Let's write an auto-crop and segmenter for each row in the left side
# Each row has a blue pill label on the left (x < 70). We ignore x < 70.
# For each row, characters are located at x in [70, 610].

rows = [
    ("idle", 0, 78, 7),
    ("walk_down", 78, 150, 7),
    ("walk_up", 150, 225, 7),
    ("walk_left", 225, 305, 7),
    ("walk_right", 305, 385, 7),
    ("plant", 385, 465, 6),
    ("pickup", 465, 535, 6),
    ("hurt", 535, 605, 6),
    ("die", 605, 680, 5)
]

out_char_dir = r'c:\Users\khang\Documents\Build\Boom\assets\characters\ninja'
os.makedirs(out_char_dir, exist_ok=True)

for anim_name, y_min, y_max, count in rows:
    # Get row sub-image ignoring label
    row_img = img.crop((65, y_min, 615, y_max))
    row_arr = np.array(row_img)
    alpha = row_arr[:, :, 3]
    
    # Find column projections with alpha > 0
    col_has_pixels = np.any(alpha > 10, axis=0)
    
    # Find contiguous intervals
    intervals = []
    in_interval = False
    start_x = 0
    for x, val in enumerate(col_has_pixels):
        if val and not in_interval:
            in_interval = True
            start_x = x
        elif not val and in_interval:
            in_interval = False
            if x - start_x > 15: # minimum width of a character frame
                intervals.append((start_x, x))
    if in_interval and (len(col_has_pixels) - start_x > 15):
        intervals.append((start_x, len(col_has_pixels)))
        
    print(f"Animation {anim_name} (y={y_min}..{y_max}): found {len(intervals)} frames (expected {count})")
    
    # Save frames
    for f_idx, (sx, ex) in enumerate(intervals):
        # Crop tight bounding box vertically
        frame_patch = row_arr[:, sx:ex]
        patch_alpha = frame_patch[:, :, 3]
        rows_has_pixels = np.any(patch_alpha > 10, axis=1)
        if not np.any(rows_has_pixels): continue
        ymin_patch = np.where(rows_has_pixels)[0][0]
        ymax_patch = np.where(rows_has_pixels)[0][-1] + 1
        
        cropped_char = row_img.crop((sx, ymin_patch, ex, ymax_patch))
        
        # Center in standardized 48x48 or 40x40 canvas for game sprite
        target_size = (48, 48)
        canvas = Image.new("RGBA", target_size, (0, 0, 0, 0))
        
        cw, ch = cropped_char.size
        px = (target_size[0] - cw) // 2
        # Align bottom with padding of 4px
        py = target_size[1] - ch - 4
        canvas.paste(cropped_char, (px, py))
        
        frame_filename = f"{anim_name}_{f_idx}.png"
        canvas.save(os.path.join(out_char_dir, frame_filename))

print("Ninja character frames extraction finished.")
