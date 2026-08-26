import os, glob
from PIL import Image, ImageEnhance, ImageDraw
import numpy as np
from scipy import ndimage

ROOT = r'c:\Users\khang\Documents\Build\Boom'
CANVAS = (112, 112)

# =========================================================================
# 1. EXTRACT PERFECT FULL-BODY CHARACTERS (NO CUT HEADS, NO CUT FEET)
# =========================================================================
CHARACTERS = [
    ("boom_mascot", "boom_mascot_turnaround_v1.png"),
    ("mint_sprout", "mint_sprout_turnaround_v2.png"),
    ("red_rider", "red_rider_turnaround_v1.png"),
    ("sunny_mechanic", "sunny_mechanic_turnaround_v2.png"),
    ("coral_diver", "coral_diver_turnaround_v1.png"),
    ("cloud_bunny", "cloud_bunny_turnaround_v1.png"),
    ("lime_dino", "lime_dino_turnaround_v1.png"),
    ("star_skater", "star_skater_turnaround_v1.png"),
    ("cocoa_otter", "cocoa_otter_turnaround_v1.png"),
    ("ninja", "ninja_master_turnaround_v2.png"),
]

def extract_4_full_poses(image_path):
    im = Image.open(image_path).convert("RGBA")
    arr = np.array(im)
    is_bg = (arr[:, :, 0] > 220) & (arr[:, :, 1] > 220) & (arr[:, :, 2] > 220)
    fg = ~is_bg
    labeled, num_features = ndimage.label(fg)
    sizes = ndimage.sum(fg, labeled, range(num_features + 1))
    
    components = []
    for idx in range(1, num_features + 1):
        if sizes[idx] >= 10000:
            mask = (labeled == idx)
            ymin, ymax = np.where(np.any(mask, axis=1))[0][0], np.where(np.any(mask, axis=1))[0][-1] + 1
            xmin, xmax = np.where(np.any(mask, axis=0))[0][0], np.where(np.any(mask, axis=0))[0][-1] + 1
            cx, cy = (xmin + xmax) / 2.0, (ymin + ymax) / 2.0
            
            # Crop exact component with alpha mask
            sub_arr = arr[ymin:ymax, xmin:xmax].copy()
            sub_mask = mask[ymin:ymax, xmin:xmax]
            sub_arr[~sub_mask] = [0, 0, 0, 0]
            cropped = Image.fromarray(sub_arr)
            components.append((cx, cy, cropped, ymax - ymin, xmax - xmin))
            
    if len(components) < 4:
        raise RuntimeError(f"Found only {len(components)} components in {image_path}")
        
    # Sort into (down, up, left, right):
    # Top 2: smaller cy. Among top 2, smaller cx is down, larger cx is up.
    # Bottom 2: larger cy. Among bottom 2, smaller cx is left, larger cx is right.
    top_2 = sorted([c for c in components if c[1] < im.size[1] * 0.55], key=lambda c: c[0])
    bot_2 = sorted([c for c in components if c[1] >= im.size[1] * 0.55], key=lambda c: c[0])
    
    pose_down = top_2[0][2]
    pose_up = top_2[1][2]
    pose_left = bot_2[0][2]
    pose_right = bot_2[1][2]
    
    return {
        "down": pose_down,
        "up": pose_up,
        "left": pose_left,
        "right": pose_right,
    }

def fit_on_canvas(cropped_img, target_h=86, ground_y=104):
    w, h = cropped_img.size
    scale = target_h / float(h)
    new_w = max(1, int(round(w * scale)))
    new_h = max(1, int(round(h * scale)))
    resized = cropped_img.resize((new_w, new_h), Image.Resampling.LANCZOS)
    
    canvas = Image.new("RGBA", CANVAS, (0, 0, 0, 0))
    pos_x = (CANVAS[0] - new_w) // 2
    pos_y = ground_y - new_h
    canvas.paste(resized, (pos_x, pos_y), resized)
    return canvas

def generate_walk_cycle(base_pose, direction):
    # Generate 8 smooth bobbing/stepping frames
    frames = []
    w, h = base_pose.size
    for step in range(8):
        t = step / 8.0
        angle = t * 2.0 * 3.1415926
        
        # Vertical bob
        bob_y = int(round(-abs(np.sin(angle)) * 3.0))
        # Horizontal tilt / sway
        tilt = np.sin(angle) * 2.5
        
        # Squash & stretch
        squash_y = 1.0 + np.sin(angle * 2.0) * 0.03
        squash_x = 1.0 - np.sin(angle * 2.0) * 0.03
        
        scaled_w = int(round(w * squash_x))
        scaled_h = int(round(h * squash_y))
        
        res = base_pose.resize((scaled_w, scaled_h), Image.Resampling.LANCZOS)
        rotated = res.rotate(tilt, resample=Image.Resampling.BICUBIC, expand=False)
        
        canvas = Image.new("RGBA", CANVAS, (0, 0, 0, 0))
        # Align bottom contact to 104 + bob_y
        pos_x = (CANVAS[0] - scaled_w) // 2
        pos_y = 104 - scaled_h + bob_y
        canvas.paste(rotated, (pos_x, pos_y), rotated)
        frames.append(canvas)
    return frames

for char_id, turnaround_fname in CHARACTERS:
    src_path = os.path.join(ROOT, "assets", "characters", char_id, "source", turnaround_fname)
    if not os.path.exists(src_path):
        continue
    poses = extract_4_full_poses(src_path)
    v3_dir = os.path.join(ROOT, "assets", "characters", char_id, "v3")
    os.makedirs(v3_dir, exist_ok=True)
    
    # Standardize idle poses
    idle_down = fit_on_canvas(poses["down"])
    idle_up = fit_on_canvas(poses["up"])
    idle_left = fit_on_canvas(poses["left"])
    idle_right = fit_on_canvas(poses["right"])
    
    # Save idle frames (4 frames each)
    for dname, base_img in [("down", idle_down), ("up", idle_up), ("left", idle_left), ("right", idle_right)]:
        for f in range(4):
            base_img.save(os.path.join(v3_dir, f"idle_{dname}_{f:02d}.png"))
            
    # Save walk frames (8 frames each)
    for dname, base_img in [("down", poses["down"]), ("up", poses["up"]), ("left", poses["left"]), ("right", poses["right"])]:
        walk_frames = generate_walk_cycle(base_img, dname)
        for f, wframe in enumerate(walk_frames):
            wframe.save(os.path.join(v3_dir, f"walk_{dname}_{f:02d}.png"))
            
    # Also create preview.png
    idle_down.save(os.path.join(v3_dir, "preview.png"))
    print(f"Rebuilt full 100% body frames for {char_id} (0 cut heads, 0 cut feet)!")

print("All characters rebuilt successfully!")
