import os, glob
from PIL import Image, ImageEnhance
import numpy as np
from scipy import ndimage

ROOT = r'c:\Users\khang\Documents\Build\Boom'
CANVAS = (112, 112)

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
            
            sub_arr = arr[ymin:ymax, xmin:xmax].copy()
            sub_mask = mask[ymin:ymax, xmin:xmax]
            sub_arr[~sub_mask] = [0, 0, 0, 0]
            cropped = Image.fromarray(sub_arr)
            components.append((cx, cy, cropped))
            
    if len(components) < 4:
        raise RuntimeError(f"Found only {len(components)} components in {image_path}")
        
    top_2 = sorted([c for c in components if c[1] < im.size[1] * 0.55], key=lambda c: c[0])
    bot_2 = sorted([c for c in components if c[1] >= im.size[1] * 0.55], key=lambda c: c[0])
    
    return {
        "down": top_2[0][2],
        "up": top_2[1][2],
        "left": bot_2[0][2],
        "right": bot_2[1][2],
    }

def fit_pose(raw_cropped, target_h=86):
    w, h = raw_cropped.size
    scale = target_h / float(h)
    new_w = max(1, int(round(w * scale)))
    new_h = max(1, int(round(h * scale)))
    return raw_cropped.resize((new_w, new_h), Image.Resampling.LANCZOS)

def put_on_canvas(fitted_img, offset_y=0, ground_y=104):
    canvas = Image.new("RGBA", CANVAS, (0, 0, 0, 0))
    pos_x = (CANVAS[0] - fitted_img.size[0]) // 2
    pos_y = ground_y - fitted_img.size[1] + offset_y
    canvas.paste(fitted_img, (pos_x, pos_y), fitted_img)
    return canvas

def generate_walk_frames(fitted_img):
    frames = []
    w, h = fitted_img.size
    for step in range(8):
        t = step / 8.0
        angle = t * 2.0 * 3.1415926
        
        # Step bounce
        bob_y = int(round(-abs(np.sin(angle)) * 3.0))
        tilt = np.sin(angle) * 3.0
        
        # Subtle squash
        sw = max(1, int(round(w * (1.0 - np.sin(angle * 2.0) * 0.03))))
        sh = max(1, int(round(h * (1.0 + np.sin(angle * 2.0) * 0.03))))
        
        res = fitted_img.resize((sw, sh), Image.Resampling.LANCZOS)
        rot = res.rotate(tilt, resample=Image.Resampling.BICUBIC, expand=False)
        
        frame = put_on_canvas(rot, bob_y)
        frames.append(frame)
    return frames

for char_id, turnaround_fname in CHARACTERS:
    src_path = os.path.join(ROOT, "assets", "characters", char_id, "source", turnaround_fname)
    if not os.path.exists(src_path):
        continue
    poses = extract_4_full_poses(src_path)
    v3_dir = os.path.join(ROOT, "assets", "characters", char_id, "v3")
    os.makedirs(v3_dir, exist_ok=True)
    
    # 1. Fit raw cropped poses to 86px height
    fitted_down = fit_pose(poses["down"])
    fitted_up = fit_pose(poses["up"])
    fitted_left = fit_pose(poses["left"])
    fitted_right = fit_pose(poses["right"])
    
    # 2. Idle frames (4 frames with subtle idle breathing)
    for dname, fimg in [("down", fitted_down), ("up", fitted_up), ("left", fitted_left), ("right", fitted_right)]:
        for f in range(4):
            breath_y = -1 if f in (1, 2) else 0
            canvas = put_on_canvas(fimg, breath_y)
            canvas.save(os.path.join(v3_dir, f"idle_{dname}_{f:02d}.png"))
            
    # 3. Walk frames (8 frames)
    for dname, fimg in [("down", fitted_down), ("up", fitted_up), ("left", fitted_left), ("right", fitted_right)]:
        walk_frames = generate_walk_frames(fimg)
        for f, wframe in enumerate(walk_frames):
            wframe.save(os.path.join(v3_dir, f"walk_{dname}_{f:02d}.png"))
            
    # 4. Preview
    put_on_canvas(fitted_down, 0).save(os.path.join(v3_dir, "preview.png"))
    print(f"Rebuilt 100% full-body animations for {char_id}!")

print("Character animation rebuild complete!")
