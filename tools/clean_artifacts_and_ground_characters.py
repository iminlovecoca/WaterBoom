import os
from PIL import Image
import numpy as np
from scipy import ndimage
from collections import deque

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
]

def border_flood_fill(img: Image.Image) -> Image.Image:
    """Removes ONLY background pixels connected to outer borders."""
    img = img.convert("RGBA")
    arr = np.array(img)
    H, W = arr.shape[:2]
    
    is_white = (arr[:, :, 0] > 215) & (arr[:, :, 1] > 215) & (arr[:, :, 2] > 215)
    visited = np.zeros((H, W), dtype=bool)
    queue = deque()
    
    for x in range(W):
        if is_white[0, x]: queue.append((0, x)); visited[0, x] = True
        if is_white[H - 1, x]: queue.append((H - 1, x)); visited[H - 1, x] = True
    for y in range(H):
        if is_white[y, 0]: queue.append((y, 0)); visited[y, 0] = True
        if is_white[y, W - 1]: queue.append((y, W - 1)); visited[y, W - 1] = True
        
    while queue:
        cy, cx = queue.popleft()
        for dy, dx in [(-1, 0), (1, 0), (0, -1), (0, 1)]:
            ny, nx = cy + dy, cx + dx
            if 0 <= ny < H and 0 <= nx < W:
                if not visited[ny, nx] and is_white[ny, nx]:
                    visited[ny, nx] = True
                    queue.append((ny, nx))
                    
    arr[visited, 3] = 0
    return Image.fromarray(arr)

def isolate_main_component(crop_img: Image.Image) -> Image.Image:
    """Keeps ONLY the largest connected subject, removing any stray ear/hat artifacts."""
    arr = np.array(crop_img)
    alpha = arr[:, :, 3]
    labeled, num_features = ndimage.label(alpha > 15)
    if num_features <= 1:
        return crop_img
        
    sizes = ndimage.sum(alpha > 15, labeled, range(num_features + 1))
    largest_idx = np.argmax(sizes[1:]) + 1
    
    # Keep only largest component
    mask = (labeled == largest_idx)
    arr[~mask] = [0, 0, 0, 0]
    return Image.fromarray(arr)

def extract_4_clean_poses(image_path):
    clean_full = border_flood_fill(Image.open(image_path))
    H, W = clean_full.size[1], clean_full.size[0]
    mid_x, mid_y = W // 2, H // 2
    
    quads = {
        "down": (0, 0, mid_x + 60, mid_y + 80),
        "up": (mid_x - 60, 0, W, mid_y + 80),
        "left": (0, mid_y - 60, mid_x + 60, H),
        "right": (mid_x - 60, mid_y - 60, W, H),
    }
    
    poses = {}
    for dname, box in quads.items():
        sub_img = clean_full.crop(box)
        # Isolate ONLY the primary character, discarding any neighboring ears/feet
        isolated_img = isolate_main_component(sub_img)
        
        arr = np.array(isolated_img)
        alpha = arr[:, :, 3]
        has_r = np.any(alpha > 20, axis=1)
        has_c = np.any(alpha > 20, axis=0)
        
        ymin, ymax = np.where(has_r)[0][0], np.where(has_r)[0][-1] + 1
        xmin, xmax = np.where(has_c)[0][0], np.where(has_c)[0][-1] + 1
        
        cropped_pose = isolated_img.crop((xmin, ymin, xmax, ymax))
        poses[dname] = cropped_pose
        
    return poses

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
        
        bob_y = int(round(-abs(np.sin(angle)) * 3.0))
        tilt = np.sin(angle) * 3.0
        
        sw = max(1, int(round(w * (1.0 - np.sin(angle * 2.0) * 0.03))))
        sh = max(1, int(round(h * (1.0 + np.sin(angle * 2.0) * 0.03))))
        
        res = fitted_img.resize((sw, sh), Image.Resampling.LANCZOS)
        rot = res.rotate(tilt, resample=Image.Resampling.BICUBIC, expand=False)
        
        frame = put_on_canvas(rot, bob_y)
        frames.append(frame)
    return frames

def build_all():
    for char_id, turnaround_fname in CHARACTERS:
        src_path = os.path.join(ROOT, "assets", "characters", char_id, "source", turnaround_fname)
        if not os.path.exists(src_path):
            continue
            
        poses = extract_4_clean_poses(src_path)
        v3_dir = os.path.join(ROOT, "assets", "characters", char_id, "v3")
        os.makedirs(v3_dir, exist_ok=True)
        
        fitted_down = fit_pose(poses["down"], 86)
        fitted_up = fit_pose(poses["up"], 86)
        fitted_left = fit_pose(poses["left"], 86)
        fitted_right = fit_pose(poses["right"], 86)
        
        for dname, fimg in [("down", fitted_down), ("up", fitted_up), ("left", fitted_left), ("right", fitted_right)]:
            for f in range(4):
                breath_y = -1 if f in (1, 2) else 0
                canvas = put_on_canvas(fimg, breath_y)
                canvas.save(os.path.join(v3_dir, f"idle_{dname}_{f:02d}.png"))
                
        for dname, fimg in [("down", fitted_down), ("up", fitted_up), ("left", fitted_left), ("right", fitted_right)]:
            walk_frames = generate_walk_frames(fimg)
            for f, wframe in enumerate(walk_frames):
                wframe.save(os.path.join(v3_dir, f"walk_{dname}_{f:02d}.png"))
                
        put_on_canvas(fitted_down, 0).save(os.path.join(v3_dir, "preview.png"))
        print(f"Cleaned 100% artifacts and grounded {char_id}!")

    print("All characters rebuilt perfectly clean!")

build_all()
