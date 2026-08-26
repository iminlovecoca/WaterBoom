#!/usr/bin/env python3
"""
Generates a visual catalog sheet PNG showing all 61 balloon skins.
8 columns x 8 rows grid, each cell 128x128 with 8px padding.
"""
import json
import os
from PIL import Image, ImageDraw, ImageFont

CATALOG_PATH = os.path.join(os.path.dirname(__file__), "..", "assets", "water_balloons", "water_balloon_catalog.json")
SKINS_BASE = os.path.join(os.path.dirname(__file__), "..", "assets", "water_balloons", "skins")
OUTPUT_PATH = os.path.join(os.path.dirname(__file__), "..", "assets", "water_balloons", "catalog", "water_balloon_catalog.png")

CELL_SIZE = 128
PADDING = 8
COLS = 8
ROWS = 8
BG_COLOR = (40, 50, 70)

def generate_catalog_sheet():
    with open(CATALOG_PATH) as f:
        catalog = json.load(f)
    
    grid_w = COLS * (CELL_SIZE + PADDING) + PADDING
    grid_h = ROWS * (CELL_SIZE + PADDING) + PADDING
    header_h = 60
    total_h = grid_h + header_h
    
    sheet = Image.new('RGB', (grid_w, total_h), BG_COLOR)
    draw = ImageDraw.Draw(sheet)
    
    try:
        font = ImageFont.truetype("arial.ttf", 16)
        title_font = ImageFont.truetype("arial.ttf", 24)
    except Exception:
        font = ImageFont.load_default()
        title_font = font
    
    draw.text((grid_w // 2 - 200, 15), "WATER BALLOON COLLECTION - 61 SKINS", fill=(200, 230, 255), font=title_font)
    
    skin_map = {}
    for skin in catalog["skins"]:
        key = (skin["source_row"], skin["source_col"])
        skin_map[key] = skin
    
    empty_cells = set(tuple(c) for c in catalog["grid"]["empty_cells"])
    
    for row in range(ROWS):
        for col in range(COLS):
            x = PADDING + col * (CELL_SIZE + PADDING)
            y = header_h + PADDING + row * (CELL_SIZE + PADDING)
            
            if (row, col) in empty_cells:
                draw.rectangle([x, y, x + CELL_SIZE, y + CELL_SIZE], fill=(30, 35, 50))
                continue
            
            key = (row, col)
            if key not in skin_map:
                draw.rectangle([x, y, x + CELL_SIZE, y + CELL_SIZE], fill=(50, 50, 60))
                continue
            
            skin = skin_map[key]
            icon_path = os.path.join(SKINS_BASE, skin["id"], "icon.png")
            
            if os.path.exists(icon_path):
                icon = Image.open(icon_path).convert('RGBA')
                icon = icon.resize((CELL_SIZE, CELL_SIZE), Image.Resampling.LANCZOS)
                sheet.paste(icon, (x, y), icon)
            else:
                draw.rectangle([x, y, x + CELL_SIZE, y + CELL_SIZE], fill=(60, 60, 80))
                draw.text((x + 4, y + 4), skin["id"], fill=(150, 150, 180), font=font)
    
    os.makedirs(os.path.dirname(OUTPUT_PATH), exist_ok=True)
    sheet.save(OUTPUT_PATH)
    print("Catalog sheet saved to: " + OUTPUT_PATH)

if __name__ == "__main__":
    generate_catalog_sheet()
