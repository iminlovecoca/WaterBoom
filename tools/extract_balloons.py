#!/usr/bin/env python3
"""
Extract balloon sprites v10 — clean crop from reference sheet.
The reference sheet has transparent (checkerboard) backgrounds.
Simple approach: auto-detect grid, crop each cell, trim transparent edges, paste onto 128x128 canvas.
"""
from PIL import Image
import numpy as np
import os

SRC = 'C:/Users/khang/Documents/Build/Boom/assets/water_balloons/reference_sheet.png'
OUT = 'C:/Users/khang/Documents/Build/Boom/assets/water_balloons/balloon_sprites'

os.makedirs(OUT, exist_ok=True)
img = Image.open(SRC).convert('RGBA')
arr = np.array(img)
h_img, w_img = arr.shape[:2]

print(f"Reference sheet: {w_img}x{h_img}")

# Detect grid lines by finding columns/rows that are mostly transparent
alpha = arr[:, :, 3]

# A column is a "gap" if most pixels are transparent
col_transparency = (alpha < 128).mean(axis=0)
row_transparency = (alpha < 128).mean(axis=1)

# Find grid boundaries: transitions from content to gap
def find_bands(transparency, min_content=0.3, min_gap=0.7):
    """Find bands of content separated by gaps."""
    is_content = transparency < (1.0 - min_content)
    is_gap = transparency > min_gap

    bands = []
    in_band = False
    start = 0

    for i in range(len(transparency)):
        if not in_band and is_content[i]:
            in_band = True
            start = i
        elif in_band and is_gap[i]:
            in_band = False
            if i - start > 10:  # minimum band width
                bands.append((start, i - 1))
    if in_band and len(transparency) - start > 10:
        bands.append((start, len(transparency) - 1))

    return bands

col_bands = find_bands(col_transparency)
row_bands = find_bands(row_transparency)

print(f"Detected {len(col_bands)} columns, {len(row_bands)} rows")
print(f"Col bands: {col_bands}")
print(f"Row bands: {row_bands}")

# If auto-detection fails, use manual grid
if len(col_bands) < 7 or len(row_bands) < 7:
    print("Auto-detection failed, using manual grid for 1024x1024 sheet")
    # For a 1024x1024 sheet with 8x8 grid, each cell ~128x128
    # Estimate from visual: balloons start around y=20, cells ~125px
    cell_w = w_img // 8
    cell_h = h_img // 8
    col_bands = [(i * cell_w, (i + 1) * cell_w - 1) for i in range(8)]
    row_bands = [(i * cell_h, (i + 1) * cell_h - 1) for i in range(8)]

skin_idx = 0
TARGET = 128

for row_i, (r1, r2) in enumerate(row_bands):
    for col_i, (c1, c2) in enumerate(col_bands):
        # Crop cell
        cell = img.crop((c1, r1, c2 + 1, r2 + 1))
        cell_arr = np.array(cell)

        # Skip empty cells (all transparent)
        if cell_arr[:, :, 3].max() == 0:
            continue

        # Skip mostly-transparent cells
        non_transparent = (cell_arr[:, :, 3] > 128).sum()
        if non_transparent < 100:
            continue

        # Trim transparent edges
        bbox = cell.getbbox()
        if not bbox:
            continue

        # Add small padding (4px)
        pad = 4
        bbox_padded = (
            max(0, bbox[0] - pad),
            max(0, bbox[1] - pad),
            min(cell.width, bbox[2] + pad),
            min(cell.height, bbox[3] + pad)
        )
        trimmed = cell.crop(bbox_padded)

        # Scale to fit within TARGET x TARGET, preserving aspect ratio
        scale = min(TARGET / trimmed.width, TARGET / trimmed.height)
        new_w = int(trimmed.width * scale)
        new_h = int(trimmed.height * scale)
        resized = trimmed.resize((new_w, new_h), Image.Resampling.LANCZOS)

        # Center on transparent canvas
        canvas = Image.new('RGBA', (TARGET, TARGET), (0, 0, 0, 0))
        ox = (TARGET - new_w) // 2
        oy = (TARGET - new_h) // 2
        canvas.paste(resized, (ox, oy), resized)

        canvas.save(os.path.join(OUT, f'balloon_{skin_idx:03d}.png'))
        skin_idx += 1

print(f'Extracted {skin_idx} balloons (v10)')
