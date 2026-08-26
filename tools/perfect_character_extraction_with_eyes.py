import os, glob
from PIL import Image
import numpy as np
from collections import deque

ROOT = r'c:\Users\khang\Documents\Build\Boom'
CANVAS = (112, 112)

# Playable characters list (NINJA REMOVED)
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

def border_flood_fill_transparency(img: Image.Image) -> Image.Image:
    """
    Removes ONLY background pixels connected to outer borders.
    Internal white pixels (EYES, TEETH, GLOVES, REFLECTIONS) are 100% PRESERVED!
    """
    img = img.convert("RGBA")
    arr = np.array(img)
    H, W = arr.shape[:2]
    
    # Background color definition: near-white / light grey
    is_white = (arr[:, :, 0] > 215) & (arr[:, :, 1] > 215) & (arr[:, :, 2] > 215)
    
    # BFS queue starting only from outer borders
    visited = np.zeros((H, W), dtype=bool)
    queue = deque()
    
    for x in range(W):
        if is_white[0, x]:
            queue.append((0, x))
            visited[0, x] = True
        if is_white[H - 1, x]:
            queue.append((H - 1, x))
            visited[H - 1, x] = True
            
    for y in range(H):
        if is_white[y, 0]:
            queue.append((y, 0))
            visited[y, 0] = True
        if is_white[y, W - 1]:
            queue.append((y, W - 1))
            visited[y, W - 1] = True
            
    while queue:
        cy, cx = queue.popleft()
        for dy, dx in [(-1, 0), (1, 0), (0, -1), (0, 1)]:
            ny, nx = cy + dy, cx + dx
            if 0 <= ny < H and 0 <= nx < W:
                if not visited[ny, nx] and is_white[ny, nx]:
                    visited[ny, nx] = True
                    queue.append((ny, nx))
                    
    # Only border-connected white pixels get alpha = 0
    arr[visited, 3] = 0
    return Image.fromarray(arr)

def extract_4_poses(image_path):
    raw_img = Image.open(image_path)
    clean_img = border_flood_fill_transparency(raw_img)
    arr = np.array(clean_img)
    alpha = arr[:, :, 3]
    
    # Split into 4 quadrants with 30px buffer to prevent any clipping
    H, W = alpha.shape
    mid_x, mid_y = W // 2, H // 2
    
    # Quadrants:
    # Down: top-left [0..mid_y+60, 0..mid_x+60]
    # Up: top-right [0..mid_y+60, mid_x-60..W]
    # Left: bottom-left [mid_y-60..H, 0..mid_x+60]
    # Right: bottom-right [mid_y-60..H, mid_x-60..W]
    
    quads = {
        "down": (0, 0, mid_x + 60, mid_y + 80),
        "up": (mid_x - 60, 0, W, mid_y + 80),
        "left": (0, mid_y - 60, mid_x + 60, H),
        "right": (mid_x - 60, mid_y - 60, W, H),
    }
    
    poses = {}
    for dname, (x1, y1, x2, y2) in quads.items():
        sub_img = clean_img.crop((x1, y1, x2, y2))
        sub_alpha = np.array(sub_img)[:, :, 3]
        
        # Find exact bounding box of the character inside this quadrant
        has_r = np.any(sub_alpha > 20, axis=1)
        has_c = np.any(sub_alpha > 20, axis=0)
        if not np.any(has_r):
            raise RuntimeError(f"No character found in {dname} quadrant of {image_path}")
            
        ymin, ymax = np.where(has_r)[0][0], np.where(has_r)[0][-1] + 1
        xmin, xmax = np.where(has_c)[0][0], np.where(has_c)[0][-1] + 1
        
        cropped_pose = sub_img.crop((xmin, ymin, xmax, ymax))
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

def build_all_characters():
    for char_id, turnaround_fname in CHARACTERS:
        src_path = os.path.join(ROOT, "assets", "characters", char_id, "source", turnaround_fname)
        if not os.path.exists(src_path):
            print(f"Skipping {char_id}, source not found")
            continue
            
        poses = extract_4_poses(src_path)
        v3_dir = os.path.join(ROOT, "assets", "characters", char_id, "v3")
        os.makedirs(v3_dir, exist_ok=True)
        
        # 1. Fit all poses to synchronized 86px height (100% UNIFIED SCALE!)
        fitted_down = fit_pose(poses["down"], 86)
        fitted_up = fit_pose(poses["up"], 86)
        fitted_left = fit_pose(poses["left"], 86)
        fitted_right = fit_pose(poses["right"], 86)
        
        # 2. Idle frames (4 frames)
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
        print(f"Successfully processed {char_id} with 100% eyes preserved and unified scale!")

build_all_characters()
