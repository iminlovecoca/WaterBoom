import os
import numpy as np
from PIL import Image

SRC_PATH = r"C:\Users\khang\.gemini\antigravity\brain\8d5450db-5a47-4a4a-af37-9aad2b7203db\.user_uploaded\media_1786853100400.png"
OUTPUT_DIR = r"c:\Users\khang\Documents\Build\Boom\assets\characters\ninja"

# Frame column boundaries derived from walk_down reference gaps
FRAME_BOUNDS = [
    (62, 135),   # Frame 0
    (140, 212),  # Frame 1
    (218, 290),  # Frame 2
    (296, 366),  # Frame 3
    (372, 443),  # Frame 4
    (448, 517),  # Frame 5
    (520, 593),  # Frame 6
]

ROW_Y_MIN = 8
ROW_Y_MAX = 81
TARGET_SIZE = (44, 44)
BOTTOM_PAD = 2
ALPHA_THRESHOLD = 20

def extract_idle_frames():
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    img = Image.open(SRC_PATH).convert("RGBA")
    
    print(f"Source image loaded from: {SRC_PATH} (size: {img.size})")
    print(f"Extracting 7 idle frames from y=[{ROW_Y_MIN}, {ROW_Y_MAX}]...")

    for idx, (x0, x1) in enumerate(FRAME_BOUNDS):
        # 1. Slice cell from spritesheet
        cell = img.crop((x0, ROW_Y_MIN, x1, ROW_Y_MAX))
        cell_arr = np.array(cell)
        alpha = cell_arr[:, :, 3]

        # 2. Auto-crop to content bounding box (alpha > 20)
        has_r = np.any(alpha > ALPHA_THRESHOLD, axis=1)
        has_c = np.any(alpha > ALPHA_THRESHOLD, axis=0)

        if not np.any(has_r) or not np.any(has_c):
            print(f"Warning: Frame {idx} is empty!")
            continue

        ymin = int(np.where(has_r)[0][0])
        ymax = int(np.where(has_r)[0][-1] + 1)
        xmin = int(np.where(has_c)[0][0])
        xmax = int(np.where(has_c)[0][-1] + 1)

        cropped = cell.crop((xmin, ymin, xmax, ymax))
        raw_w, raw_h = cropped.size

        # 3. Fit and scale to canvas if larger than available content area
        max_content_w = TARGET_SIZE[0] - 2
        max_content_h = TARGET_SIZE[1] - BOTTOM_PAD
        
        cw, ch = raw_w, raw_h
        if cw > max_content_w or ch > max_content_h:
            scale = min(float(max_content_w) / cw, float(max_content_h) / ch)
            new_w = int(cw * scale)
            new_h = int(ch * scale)
            cropped = cropped.resize((new_w, new_h), Image.Resampling.NEAREST)
            cw, ch = new_w, new_h

        # 4. Center horizontally, align to bottom with 2px padding
        canvas = Image.new("RGBA", TARGET_SIZE, (0, 0, 0, 0))
        px = (TARGET_SIZE[0] - cw) // 2
        py = TARGET_SIZE[1] - ch - BOTTOM_PAD
        canvas.paste(cropped, (px, py))

        # 5. Save frame
        out_filename = f"idle_{idx}.png"
        out_path = os.path.join(OUTPUT_DIR, out_filename)
        canvas.save(out_path)

        print(
            f"Frame {idx}: extracted slice x=[{x0}, {x1}], "
            f"content bbox=({raw_w}x{raw_h}) at x=[{x0+xmin}, {x0+xmax}], y=[{ROW_Y_MIN+ymin}, {ROW_Y_MIN+ymax}] -> "
            f"scaled=({cw}x{ch}) on {TARGET_SIZE[0]}x{TARGET_SIZE[1]} canvas at pos=({px}, {py}) -> "
            f"Saved: {out_filename}"
        )

if __name__ == "__main__":
    extract_idle_frames()
