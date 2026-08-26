"""
V10 — Definitive Character Sprite Pipeline
===========================================
Source: assets/characters/FrameGrid/*.png  (9 AI-generated 6×8 grid sheets)
Output: assets/characters/<char_id>/v10/frame_NNN.png  (48 transparent PNGs, 96×96)
        resources/characters/<char_id>_frames.tres  (SpriteFrames with 14 animations)

Grid layout (6 rows × 8 cols):
  Row 0: idle_down(4) | walk_down(4)
  Row 1: idle_left(4) | walk_left(4)
  Row 2: idle_right(4)| walk_right(4)
  Row 3: idle_up(4)   | walk_up(4)
  Row 4: bubble(4)    | rescued(4)
  Row 5: lose(4)      | win(4)

Background removal: FloodFill from 4 corners (tolerance 20) — preserves internal white pixels.
Canvas: 96×96, baseline at y=88, centered at x=48.
Walk clips: 8-frame ping-pong [0,1,2,3,2,1,0,1] for smooth stepping.
"""

import cv2
import numpy as np
import os
import sys

# ── Character mapping ──────────────────────────────────────────────────
MAPPING = {
    'ChatGPT Image 10_18_24 20 thg 8, 2026 (9).png': 'cloud_bunny',
    'ChatGPT Image 10_18_24 20 thg 8, 2026 (1).png': 'cocoa_otter',
    'ChatGPT Image 10_18_25 20 thg 8, 2026 (2).png': 'sunny_mechanic',
    'ChatGPT Image 10_18_25 20 thg 8, 2026 (3).png': 'lime_dino',
    'ChatGPT Image 10_18_25 20 thg 8, 2026 (4).png': 'red_rider',
    'ChatGPT Image 10_18_26 20 thg 8, 2026 (5).png': 'boom_mascot',
    'ChatGPT Image 10_18_26 20 thg 8, 2026 (6).png': 'coral_diver',
    'ChatGPT Image 10_18_26 20 thg 8, 2026 (7).png': 'star_skater',
    'ChatGPT Image 10_18_27 20 thg 8, 2026 (8).png': 'mint_sprout',
}

IN_DIR  = r'C:\Users\khang\Documents\Build\Boom\assets\characters\FrameGrid'
OUT_BASE = r'C:\Users\khang\Documents\Build\Boom\assets\characters'
RES_DIR  = r'C:\Users\khang\Documents\Build\Boom\resources\characters'

CANVAS   = 96          # output canvas size
BASELINE = 88          # y-coordinate where feet touch
CENTER_X = 48          # x-coordinate for horizontal center
ROWS, COLS = 6, 8
TOLERANCE = 20         # floodfill colour tolerance

ROW_ANIMS = [
    ('idle_down',  'walk_down'),
    ('idle_left',  'walk_left'),
    ('idle_right', 'walk_right'),
    ('idle_up',    'walk_up'),
    ('bubble',     'rescued'),
    ('lose',       'win'),
]


def floodfill_remove_bg(cell_bgr):
    """Remove background using floodFill from 4 corners. Returns BGRA with alpha."""
    h, w = cell_bgr.shape[:2]
    # Pad by 2px so floodfill seed is guaranteed inside padded image
    padded = cv2.copyMakeBorder(cell_bgr, 2, 2, 2, 2, cv2.BORDER_REPLICATE)
    ff_mask = np.zeros((h + 6, w + 6), dtype=np.uint8)

    lo = (TOLERANCE, TOLERANCE, TOLERANCE)
    hi = (TOLERANCE, TOLERANCE, TOLERANCE)
    flags = 4 | (255 << 8) | cv2.FLOODFILL_FIXED_RANGE
    fill_color = (255, 0, 255)  # magenta marker

    # Seed from 4 corners of padded image
    cv2.floodFill(padded, ff_mask, (0, 0),       fill_color, lo, hi, flags)
    cv2.floodFill(padded, ff_mask, (w + 3, 0),   fill_color, lo, hi, flags)
    cv2.floodFill(padded, ff_mask, (0, h + 3),   fill_color, lo, hi, flags)
    cv2.floodFill(padded, ff_mask, (w + 3, h + 3), fill_color, lo, hi, flags)

    # Extract the mask region that corresponds to the original cell
    bg_mask = ff_mask[3:3 + h, 3:3 + w]
    fg_mask = (bg_mask != 255).astype(np.uint8) * 255

    # Convert to BGRA
    if cell_bgr.shape[2] == 3:
        cell_rgba = cv2.cvtColor(cell_bgr, cv2.COLOR_BGR2BGRA)
    else:
        cell_rgba = cell_bgr.copy()
    cell_rgba[:, :, 3] = fg_mask
    return cell_rgba


def find_opaque_bbox(rgba):
    """Return (x, y, w, h) bounding box of opaque pixels, or None."""
    alpha = rgba[:, :, 3]
    coords = np.where(alpha > 10)
    if len(coords[0]) == 0:
        return None
    y_min, y_max = coords[0].min(), coords[0].max()
    x_min, x_max = coords[1].min(), coords[1].max()
    return (x_min, y_min, x_max - x_min + 1, y_max - y_min + 1)


def process_sheet(filename, char_id):
    """Process one sprite sheet into 48 individual 96×96 frames."""
    img_path = os.path.join(IN_DIR, filename)
    out_dir = os.path.join(OUT_BASE, char_id, 'v10')
    os.makedirs(out_dir, exist_ok=True)

    img = cv2.imread(img_path, cv2.IMREAD_UNCHANGED)
    if img is None:
        print(f"  ERROR: Cannot read {filename}", file=sys.stderr)
        return None

    h, w = img.shape[:2]

    # ── Step 1: Slice grid into cells ────────────────────────────────
    cells = []   # cells[row][col] = BGRA with alpha
    margin = 3   # trim grid-line pixels from edges

    for r in range(ROWS):
        row_cells = []
        for c in range(COLS):
            y1 = int(r * h / ROWS) + margin
            y2 = int((r + 1) * h / ROWS) - margin
            x1 = int(c * w / COLS) + margin
            x2 = int((c + 1) * w / COLS) - margin
            cell = img[y1:y2, x1:x2].copy()
            cell_rgba = floodfill_remove_bg(cell)
            row_cells.append(cell_rgba)
        cells.append(row_cells)

    # ── Step 2: Compute uniform scale & baseline ─────────────────────
    # Use the tallest character across all cells to determine scale
    max_char_h = 0
    bboxes = []
    for r in range(ROWS):
        row_bboxes = []
        for c in range(COLS):
            bb = find_opaque_bbox(cells[r][c])
            row_bboxes.append(bb)
            if bb is not None:
                max_char_h = max(max_char_h, bb[3])
        bboxes.append(row_bboxes)

    # Target character height: ~72px (75% of 96) so there's padding
    target_h = 72
    scale = target_h / max(max_char_h, 1)

    # Use idle_down (row=0, col=0) as the anchor for baseline calculation
    anchor_bb = bboxes[0][0]
    if anchor_bb is None:
        print(f"  WARNING: idle_down has no opaque pixels for {char_id}")
        anchor_bb = (0, 0, cells[0][0].shape[1], cells[0][0].shape[0])

    # ── Step 3: Scale + place each cell onto 96×96 canvas ────────────
    anim_frames = {}  # anim_name -> list of frame images
    frame_idx = 0

    for r in range(ROWS):
        anim1, anim2 = ROW_ANIMS[r]
        if anim1 not in anim_frames: anim_frames[anim1] = []
        if anim2 not in anim_frames: anim_frames[anim2] = []

        for c in range(COLS):
            cell = cells[r][c]
            bb = bboxes[r][c]
            if bb is None:
                bb = (0, 0, cell.shape[1], cell.shape[0])

            # Scale the entire cell
            new_w = max(int(cell.shape[1] * scale), 1)
            new_h = max(int(cell.shape[0] * scale), 1)
            scaled = cv2.resize(cell, (new_w, new_h), interpolation=cv2.INTER_AREA)

            # Compute placement on 96×96 canvas
            # Feet position in scaled coordinates
            feet_y_scaled = int((bb[1] + bb[3]) * scale)
            center_x_scaled = int((bb[0] + bb[2] / 2) * scale)

            # Place so feet land at BASELINE, center at CENTER_X
            paste_y = BASELINE - feet_y_scaled
            paste_x = CENTER_X - center_x_scaled

            # Create canvas
            canvas = np.zeros((CANVAS, CANVAS, 4), dtype=np.uint8)

            # Compute overlap region
            src_y1 = max(0, -paste_y)
            src_y2 = min(new_h, CANVAS - paste_y)
            src_x1 = max(0, -paste_x)
            src_x2 = min(new_w, CANVAS - paste_x)

            dst_y1 = paste_y + src_y1
            dst_y2 = paste_y + src_y2
            dst_x1 = paste_x + src_x1
            dst_x2 = paste_x + src_x2

            if dst_y2 > dst_y1 and dst_x2 > dst_x1:
                canvas[dst_y1:dst_y2, dst_x1:dst_x2] = scaled[src_y1:src_y2, src_x1:src_x2]

            # Assign to animation
            if c < 4:
                anim_frames[anim1].append(canvas)
            else:
                anim_frames[anim2].append(canvas)

    # ── Step 4: Save frames ──────────────────────────────────────────
    anim_map = {}
    idx = 0
    for anim_name in ['idle_down', 'walk_down', 'idle_left', 'walk_left',
                       'idle_right', 'walk_right', 'idle_up', 'walk_up',
                       'bubble', 'rescued', 'lose', 'win']:
        frames = anim_frames[anim_name]
        indices = []
        for f in frames:
            out_path = os.path.join(out_dir, f"frame_{idx:03d}.png")
            cv2.imwrite(out_path, f)
            indices.append(idx)
            idx += 1
        anim_map[anim_name] = indices

    print(f"  ✅ {char_id}: {idx} frames saved to v10/")
    return anim_map


def build_tres(char_id, anim_map):
    """Generate the SpriteFrames .tres file with exactly 14 animations."""
    path = os.path.join(RES_DIR, f"{char_id}_frames.tres")
    total = sum(len(v) for v in anim_map.values())

    # ext_resource declarations
    ext_lines = []
    for i in range(total):
        tex_path = f"res://assets/characters/{char_id}/v10/frame_{i:03d}.png"
        ext_lines.append(f'[ext_resource type="Texture2D" path="{tex_path}" id="{i+1}_tex"]')

    # Walk uses ping-pong: [0,1,2,3,2,1,0,1]
    def pingpong(indices):
        return [indices[0], indices[1], indices[2], indices[3],
                indices[2], indices[1], indices[0], indices[1]]

    # Build the 14 animation definitions
    animations = {
        'idle_down':  (anim_map['idle_down'],  True,  4.0),
        'idle_left':  (anim_map['idle_left'],  True,  4.0),
        'idle_right': (anim_map['idle_right'], True,  4.0),
        'idle_up':    (anim_map['idle_up'],    True,  4.0),
        'walk_down':  (pingpong(anim_map['walk_down']),  True,  8.0),
        'walk_left':  (pingpong(anim_map['walk_left']),  True,  8.0),
        'walk_right': (pingpong(anim_map['walk_right']), True,  8.0),
        'walk_up':    (pingpong(anim_map['walk_up']),    True,  8.0),
        'bubble':     (anim_map['bubble'],     True,  6.0),
        'rescued':    (anim_map['rescued'],    False, 8.0),
        'lose':       (anim_map['lose'],       False, 6.0),
        'win':        (anim_map['win'],        False, 6.0),
        'die':        (anim_map['lose'],       False, 6.0),
        'water_hit':  ([anim_map['lose'][0]],  False, 2.0),
    }

    anim_parts = []
    for name, (indices, loop, speed) in animations.items():
        frames_str = ", ".join(
            f'{{\n"duration": 1.0,\n"texture": ExtResource("{idx+1}_tex")\n}}'
            for idx in indices
        )
        loop_str = "true" if loop else "false"
        anim_parts.append(
            f'{{\n"frames": [{frames_str}],\n"loop": {loop_str},\n"name": &"{name}",\n"speed": {speed}\n}}'
        )

    content = (
        '[gd_resource type="SpriteFrames" format=3]\n\n'
        + "\n".join(ext_lines) + "\n\n"
        + "[resource]\n"
        + "animations = [" + ", ".join(anim_parts) + "]\n"
    )

    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)
    print(f"  ✅ {char_id}_frames.tres written ({len(animations)} animations)")


# ── Main ─────────────────────────────────────────────────────────────
if __name__ == '__main__':
    print("═══ V10 Character Sprite Pipeline ═══")
    print(f"Canvas: {CANVAS}×{CANVAS}, Baseline: {BASELINE}, Center: {CENTER_X}")
    print()

    all_ok = True
    for filename, char_id in MAPPING.items():
        print(f"Processing {char_id}...")
        anim_map = process_sheet(filename, char_id)
        if anim_map is None:
            all_ok = False
            continue
        build_tres(char_id, anim_map)
        print()

    if all_ok:
        print("═══ All 9 characters processed successfully ═══")
    else:
        print("═══ SOME CHARACTERS FAILED ═══", file=sys.stderr)
        sys.exit(1)
