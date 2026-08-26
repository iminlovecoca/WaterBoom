#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Planning Plaza 15x15 Full Map Generator & Renderer (Refined)
Generates:
  - planning_plaza_map.json (Complete JSON tilemap data)
  - planning_plaza_map.csv (CSV tilemap matrix)
  - planning_plaza_15x15_full.png (HD 1500x1500 composite map)
  - planning_plaza_15x15_labeled.png (With grid coordinates overlay 1..15)
  - map_training_plaza.png & qa_map_plaza.png (In-game UI and QA previews)
"""

import os
import json
import csv
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(r"C:\Users\khang\Documents\Build\Boom")
CLEAN_DIR = ROOT / "assets" / "maps" / "planning_plaza_tileset_CLEAN"
OUT_JSON = CLEAN_DIR / "planning_plaza_map.json"
OUT_CSV = CLEAN_DIR / "planning_plaza_map.csv"
OUT_PNG_FULL = CLEAN_DIR / "planning_plaza_15x15_full.png"
OUT_PNG_LABELED = CLEAN_DIR / "planning_plaza_15x15_labeled.png"
OUT_UI_PREVIEW = ROOT / "assets" / "ui" / "map_previews" / "map_training_plaza.png"
OUT_QA_PREVIEW = ROOT / "development" / "qa_map_plaza.png"
DATA_MAPS_DIR = ROOT / "data" / "maps"

DATA_MAPS_DIR.mkdir(parents=True, exist_ok=True)

GRID_W = 15
GRID_H = 15
CELL_PX = 100

tiles = {}
for root_path, _, files in os.walk(CLEAN_DIR):
    for f in files:
        if f.endswith('.png') and not f.startswith(('tileset_catalog', 'map_crop', 'grid_crop', 'planning_plaza_15x15')):
            rel_path = Path(root_path) / f
            name = f.replace('.png', '')
            tiles[name] = Image.open(rel_path).convert("RGBA")

print(f"Loaded {len(tiles)} tiles from {CLEAN_DIR}")

# Complete Tile Dictionary
TILE_DICT = {
    0: {"name": "empty", "category": "none", "file": ""},
    1: {"name": "grass_01", "category": "ground_grass", "file": "01_ground_grass/grass_01.png"},
    2: {"name": "grass_02", "category": "ground_grass", "file": "01_ground_grass/grass_02.png"},
    3: {"name": "grass_03", "category": "ground_grass", "file": "01_ground_grass/grass_03.png"},
    4: {"name": "grass_04", "category": "ground_grass", "file": "01_ground_grass/grass_04.png"},
    5: {"name": "grass_05", "category": "ground_grass", "file": "01_ground_grass/grass_05.png"},
    6: {"name": "grass_06", "category": "ground_grass", "file": "01_ground_grass/grass_06.png"},
    7: {"name": "grass_07", "category": "ground_grass", "file": "01_ground_grass/grass_07.png"},
    8: {"name": "grass_08", "category": "ground_grass", "file": "01_ground_grass/grass_08.png"},
    9: {"name": "grass_09", "category": "ground_grass", "file": "01_ground_grass/grass_09.png"},
    10: {"name": "grass_10", "category": "ground_grass", "file": "01_ground_grass/grass_10.png"},
    11: {"name": "grass_11", "category": "ground_grass", "file": "01_ground_grass/grass_11.png"},
    12: {"name": "grass_12", "category": "ground_grass", "file": "01_ground_grass/grass_12.png"},
    13: {"name": "grass_13", "category": "ground_grass", "file": "01_ground_grass/grass_13.png"},
    14: {"name": "path_01", "category": "ground_path", "file": "02_ground_path/path_01.png"},
    15: {"name": "path_02", "category": "ground_path", "file": "02_ground_path/path_02.png"},
    16: {"name": "path_03", "category": "ground_path", "file": "02_ground_path/path_03.png"},
    17: {"name": "path_04", "category": "ground_path", "file": "02_ground_path/path_04.png"},
    18: {"name": "path_05", "category": "ground_path", "file": "02_ground_path/path_05.png"},
    19: {"name": "path_06", "category": "ground_path", "file": "02_ground_path/path_06.png"},
    20: {"name": "path_07", "category": "ground_path", "file": "02_ground_path/path_07.png"},
    21: {"name": "path_08", "category": "ground_path", "file": "02_ground_path/path_08.png"},
    22: {"name": "path_09", "category": "ground_path", "file": "02_ground_path/path_09.png"},
    23: {"name": "path_10", "category": "ground_path", "file": "02_ground_path/path_10.png"},
    24: {"name": "path_11", "category": "ground_path", "file": "02_ground_path/path_11.png"},
    25: {"name": "path_12", "category": "ground_path", "file": "02_ground_path/path_12.png"},
    26: {"name": "path_13", "category": "ground_path", "file": "02_ground_path/path_13.png"},
    27: {"name": "wall_01", "category": "walls", "file": "03_walls/wall_01.png"},
    28: {"name": "wall_02", "category": "walls", "file": "03_walls/wall_02.png"},
    29: {"name": "wall_03", "category": "walls", "file": "03_walls/wall_03.png"},
    30: {"name": "wall_04", "category": "walls", "file": "03_walls/wall_04.png"},
    31: {"name": "wall_05", "category": "walls", "file": "03_walls/wall_05.png"},
    32: {"name": "wall_06", "category": "walls", "file": "03_walls/wall_06.png"},
    33: {"name": "wall_07", "category": "walls", "file": "03_walls/wall_07.png"},
    34: {"name": "wall_08", "category": "walls", "file": "03_walls/wall_08.png"},
    35: {"name": "wall_09", "category": "walls", "file": "03_walls/wall_09.png"},
    36: {"name": "wall_10", "category": "walls", "file": "03_walls/wall_10.png"},
    37: {"name": "wall_11", "category": "walls", "file": "03_walls/wall_11.png"},
    38: {"name": "wall_12", "category": "walls", "file": "03_walls/wall_12.png"},
    39: {"name": "wall_13", "category": "walls", "file": "03_walls/wall_13.png"},
    40: {"name": "crate_tall_01", "category": "crates_tall", "file": "04_crates_tall/crate_tall_01.png"},
    41: {"name": "crate_tall_02", "category": "crates_tall", "file": "04_crates_tall/crate_tall_02.png"},
    42: {"name": "crate_tall_03", "category": "crates_tall", "file": "04_crates_tall/crate_tall_03.png"},
    43: {"name": "crate_tall_04", "category": "crates_tall", "file": "04_crates_tall/crate_tall_04.png"},
    44: {"name": "crate_tall_05", "category": "crates_tall", "file": "04_crates_tall/crate_tall_05.png"},
    45: {"name": "crate_tall_06", "category": "crates_tall", "file": "04_crates_tall/crate_tall_06.png"},
    46: {"name": "crate_tall_07", "category": "crates_tall", "file": "04_crates_tall/crate_tall_07.png"},
    47: {"name": "crate_tall_08", "category": "crates_tall", "file": "04_crates_tall/crate_tall_08.png"},
    48: {"name": "crate_tall_09", "category": "crates_tall", "file": "04_crates_tall/crate_tall_09.png"},
    49: {"name": "crate_tall_10", "category": "crates_tall", "file": "04_crates_tall/crate_tall_10.png"},
    50: {"name": "crate_tall_11", "category": "crates_tall", "file": "04_crates_tall/crate_tall_11.png"},
    51: {"name": "crate_tall_12", "category": "crates_tall", "file": "04_crates_tall/crate_tall_12.png"},
    52: {"name": "crate_tall_13", "category": "crates_tall", "file": "04_crates_tall/crate_tall_13.png"},
    53: {"name": "border_01", "category": "stone_borders", "file": "05_stone_borders/border_01.png"},
    54: {"name": "border_02", "category": "stone_borders", "file": "05_stone_borders/border_02.png"},
    55: {"name": "border_03", "category": "stone_borders", "file": "05_stone_borders/border_03.png"},
    56: {"name": "border_04", "category": "stone_borders", "file": "05_stone_borders/border_04.png"},
    57: {"name": "border_05", "category": "stone_borders", "file": "05_stone_borders/border_05.png"},
    58: {"name": "border_06", "category": "stone_borders", "file": "05_stone_borders/border_06.png"},
    59: {"name": "border_07", "category": "stone_borders", "file": "05_stone_borders/border_07.png"},
    60: {"name": "border_08", "category": "stone_borders", "file": "05_stone_borders/border_08.png"},
    61: {"name": "border_09", "category": "stone_borders", "file": "05_stone_borders/border_09.png"},
    62: {"name": "border_10", "category": "stone_borders", "file": "05_stone_borders/border_10.png"},
    63: {"name": "border_11", "category": "stone_borders", "file": "05_stone_borders/border_11.png"},
    64: {"name": "border_12", "category": "stone_borders", "file": "05_stone_borders/border_12.png"},
    65: {"name": "border_13", "category": "stone_borders", "file": "05_stone_borders/border_13.png"},
    66: {"name": "hedge_01", "category": "hedges_flowerbeds", "file": "06_hedges_flowerbeds/hedge_01.png"},
    67: {"name": "hedge_02", "category": "hedges_flowerbeds", "file": "06_hedges_flowerbeds/hedge_02.png"},
    68: {"name": "hedge_03", "category": "hedges_flowerbeds", "file": "06_hedges_flowerbeds/hedge_03.png"},
    69: {"name": "hedge_04", "category": "hedges_flowerbeds", "file": "06_hedges_flowerbeds/hedge_04.png"},
    70: {"name": "hedge_05", "category": "hedges_flowerbeds", "file": "06_hedges_flowerbeds/hedge_05.png"},
    71: {"name": "hedge_06", "category": "hedges_flowerbeds", "file": "06_hedges_flowerbeds/hedge_06.png"},
    72: {"name": "hedge_07", "category": "hedges_flowerbeds", "file": "06_hedges_flowerbeds/hedge_07.png"},
    73: {"name": "hedge_08", "category": "hedges_flowerbeds", "file": "06_hedges_flowerbeds/hedge_08.png"},
    74: {"name": "hedge_09", "category": "hedges_flowerbeds", "file": "06_hedges_flowerbeds/hedge_09.png"},
    75: {"name": "hedge_10", "category": "hedges_flowerbeds", "file": "06_hedges_flowerbeds/hedge_10.png"},
    76: {"name": "hedge_11", "category": "hedges_flowerbeds", "file": "06_hedges_flowerbeds/hedge_11.png"},
    77: {"name": "hedge_12", "category": "hedges_flowerbeds", "file": "06_hedges_flowerbeds/hedge_12.png"},
    78: {"name": "prop_01", "category": "props", "file": "07_props/prop_01.png"},
    79: {"name": "prop_02", "category": "props", "file": "07_props/prop_02.png"},
    80: {"name": "prop_03", "category": "props", "file": "07_props/prop_03.png"},
    81: {"name": "prop_04", "category": "props", "file": "07_props/prop_04.png"},
    82: {"name": "prop_05", "category": "props", "file": "07_props/prop_05.png"},
    83: {"name": "prop_06", "category": "props", "file": "07_props/prop_06.png"},
    84: {"name": "prop_07", "category": "props", "file": "07_props/prop_07.png"},
    85: {"name": "prop_08", "category": "props", "file": "07_props/prop_08.png"},
    86: {"name": "prop_09", "category": "props", "file": "07_props/prop_09.png"},
    87: {"name": "prop_10", "category": "props", "file": "07_props/prop_10.png"},
    88: {"name": "prop_11", "category": "props", "file": "07_props/prop_11.png"},
    89: {"name": "prop_12", "category": "props", "file": "07_props/prop_12.png"},
    90: {"name": "prop_13", "category": "props", "file": "07_props/prop_13.png"},
    91: {"name": "plaza_center_7x2_full", "category": "plaza_center", "file": "08_plaza_center_tiles/plaza_center_7x2_full.png"},
}

NAME_TO_ID = {v["name"]: k for k, v in TILE_DICT.items()}

# Ground Layer
GROUND_MATRIX = [
    ["path_01", "grass_01", "grass_02", "grass_03", "path_02", "grass_01", "grass_02", "grass_03", "grass_01", "grass_02", "grass_03", "grass_01", "grass_02", "grass_03", "path_01"],
    ["grass_01", "grass_02", "grass_03", "grass_01", "grass_02", "grass_03", "grass_01", "grass_02", "grass_03", "grass_01", "grass_02", "grass_03", "grass_01", "grass_02", "grass_01"],
    ["grass_02", "grass_03", "grass_01", "grass_02", "grass_03", "grass_01", "grass_02", "grass_03", "grass_01", "grass_02", "grass_03", "grass_01", "grass_02", "grass_03", "grass_02"],
    ["grass_03", "grass_01", "grass_02", "grass_03", "grass_01", "grass_02", "grass_03", "grass_01", "grass_02", "grass_03", "grass_01", "grass_02", "grass_03", "grass_01", "grass_03"],
    ["grass_01", "grass_02", "grass_03", "grass_01", "grass_02", "grass_03", "grass_01", "grass_02", "grass_03", "grass_01", "grass_02", "grass_03", "grass_01", "grass_02", "grass_01"],
    ["grass_02", "grass_03", "grass_01", "grass_02", "grass_03", "path_01", "path_02", "path_03", "path_04", "path_05", "grass_01", "grass_02", "grass_03", "grass_01", "grass_02"],
    ["grass_03", "grass_01", "grass_02", "grass_03", "grass_01", "path_06", "path_07", "path_08", "path_09", "path_10", "grass_02", "grass_03", "grass_01", "grass_02", "grass_03"],
    ["path_01", "path_02", "path_03", "path_04", "path_05", "path_06", "path_07", "path_08", "path_09", "path_10", "path_11", "path_12", "path_13", "path_01", "path_02"],
    ["grass_01", "grass_02", "grass_03", "grass_01", "grass_02", "path_01", "path_02", "path_03", "path_04", "path_05", "grass_03", "grass_01", "grass_02", "grass_03", "grass_01"],
    ["grass_02", "grass_03", "grass_01", "grass_02", "grass_03", "grass_01", "grass_02", "path_06", "grass_01", "grass_02", "grass_03", "grass_01", "grass_02", "grass_03", "grass_02"],
    ["grass_03", "grass_01", "grass_02", "grass_03", "grass_01", "grass_02", "grass_03", "path_07", "grass_02", "grass_03", "grass_01", "grass_02", "grass_03", "grass_01", "grass_03"],
    ["grass_01", "grass_02", "grass_03", "grass_01", "grass_02", "grass_03", "grass_01", "path_08", "grass_03", "grass_01", "grass_02", "grass_03", "grass_01", "grass_02", "grass_01"],
    ["grass_02", "grass_03", "grass_01", "grass_02", "grass_03", "grass_01", "grass_02", "path_09", "grass_01", "grass_02", "grass_03", "grass_01", "grass_02", "grass_03", "grass_02"],
    ["grass_03", "grass_01", "grass_02", "grass_03", "grass_01", "grass_02", "grass_03", "path_10", "grass_02", "grass_03", "grass_01", "grass_02", "grass_03", "grass_01", "grass_03"],
    ["path_03", "grass_01", "grass_02", "grass_03", "grass_01", "grass_02", "grass_03", "path_11", "grass_01", "grass_02", "grass_03", "grass_01", "grass_02", "grass_03", "path_04"],
]

# Objects Layer: Matched directly to the template image
OBJECTS_MATRIX = [
    # Row 1 (y=0)
    ["wall_11", "wall_01", "wall_02", "wall_03", "wall_08", "wall_04", "wall_05", "wall_06", "wall_01", "wall_02", "prop_04", "wall_03", "wall_04", "wall_05", "wall_12"],
    # Row 2 (y=1)
    ["wall_07", "crate_tall_01", "crate_tall_02", "", "prop_01", "", "crate_tall_03", "", "crate_tall_04", "prop_01", "", "crate_tall_05", "hedge_03", "crate_tall_06", "wall_09"],
    # Row 3 (y=2)
    ["wall_07", "hedge_03", "crate_tall_07", "crate_tall_08", "hedge_01", "", "crate_tall_09", "", "crate_tall_10", "crate_tall_01", "", "crate_tall_02", "hedge_08", "", "wall_09"],
    # Row 4 (y=3)
    ["wall_07", "", "crate_tall_03", "hedge_08", "hedge_02", "crate_tall_04", "crate_tall_05", "", "crate_tall_06", "", "crate_tall_07", "crate_tall_08", "crate_tall_09", "", "wall_09"],
    # Row 5 (y=4)
    ["wall_07", "crate_tall_10", "hedge_06", "hedge_07", "", "crate_tall_01", "prop_01", "", "prop_01", "", "crate_tall_02", "hedge_06", "hedge_07", "crate_tall_03", "wall_09"],
    # Row 6 (y=5)
    ["wall_07", "crate_tall_04", "", "", "", "", "", "", "", "", "", "hedge_01", "", "crate_tall_05", "wall_09"],
    # Row 7 (y=6)
    ["wall_07", "crate_tall_06", "", "", "", "", "FOUNTAIN", "", "", "", "", "hedge_02", "crate_tall_07", "", "wall_09"],
    # Row 8 (y=7)
    ["wall_10", "", "", "", "", "", "", "", "", "", "", "", "", "", "wall_10"],
    # Row 9 (y=8)
    ["wall_07", "crate_tall_08", "", "crate_tall_09", "prop_01", "", "", "", "", "", "prop_01", "", "crate_tall_10", "crate_tall_01", "wall_09"],
    # Row 10 (y=9)
    ["wall_07", "", "hedge_01", "", "crate_tall_02", "", "", "", "", "", "crate_tall_03", "hedge_01", "", "", "wall_09"],
    # Row 11 (y=10)
    ["wall_07", "crate_tall_04", "hedge_02", "prop_06", "crate_tall_05", "crate_tall_06", "prop_01", "", "prop_01", "crate_tall_07", "crate_tall_08", "hedge_03", "crate_tall_09", "crate_tall_10", "wall_09"],
    # Row 12 (y=11)
    ["wall_07", "crate_tall_01", "crate_tall_02", "crate_tall_03", "", "crate_tall_04", "", "", "", "crate_tall_05", "", "crate_tall_06", "hedge_06", "crate_tall_07", "wall_09"],
    # Row 13 (y=12)
    ["wall_07", "crate_tall_08", "hedge_03", "crate_tall_09", "hedge_01", "hedge_08", "crate_tall_10", "", "crate_tall_01", "hedge_03", "hedge_01", "", "hedge_08", "crate_tall_02", "wall_09"],
    # Row 14 (y=13)
    ["wall_07", "", "crate_tall_03", "crate_tall_04", "prop_01", "crate_tall_05", "", "", "prop_01", "", "hedge_02", "crate_tall_06", "crate_tall_07", "crate_tall_08", "wall_09"],
    # Row 15 (y=14)
    ["wall_13", "wall_01", "wall_02", "wall_03", "wall_04", "wall_05", "wall_06", "wall_01", "wall_02", "wall_03", "wall_04", "wall_05", "wall_06", "wall_01", "wall_13"],
]

# Calculate Collision & Statistics
collision_matrix = []
crates_count = 0
walls_count = 0
props_count = 0
walkable_count = 0

for y in range(GRID_H):
    row = []
    for x in range(GRID_W):
        obj = OBJECTS_MATRIX[y][x]
        if (6 <= x <= 8) and (6 <= y <= 8):
            row.append(1)
            walls_count += 1
        elif obj.startswith("wall"):
            row.append(1)
            walls_count += 1
        elif obj.startswith("crate"):
            row.append(2)
            crates_count += 1
        elif obj.startswith("prop") or obj.startswith("hedge"):
            row.append(1)
            props_count += 1
        else:
            row.append(0)
            walkable_count += 1
    collision_matrix.append(row)

playable_cells = GRID_W * GRID_H - 56
crates_pct = round((crates_count / playable_cells) * 100, 1)
walkable_pct = round((walkable_count / playable_cells) * 100, 1)
decor_pct = round(((props_count + 9) / playable_cells) * 100, 1)

print(f"\nMap Statistics:")
print(f"  Total cells: {GRID_W * GRID_H}")
print(f"  Playable cells: {playable_cells}")
print(f"  Destructible Crates: {crates_count} ({crates_pct}% of playable area)")
print(f"  Walkable paths: {walkable_count} ({walkable_pct}%)")
print(f"  Props & Fountain: {props_count + 9} ({decor_pct}%)")

map_json_data = {
    "name": "Planning Plaza",
    "theme": "planning_plaza",
    "width": GRID_W,
    "height": GRID_H,
    "tile_size": 40,
    "stats": {
        "total_cells": GRID_W * GRID_H,
        "border_cells": 56,
        "playable_cells": playable_cells,
        "crates_count": crates_count,
        "crates_percentage": crates_pct,
        "walkable_count": walkable_count,
        "walkable_percentage": walkable_pct,
        "decorations_count": props_count + 9,
        "decorations_percentage": decor_pct
    },
    "spawn_points": [
        {"player": 1, "x": 1, "y": 1, "note": "Top-Left Pocket (Player 1)"},
        {"player": 2, "x": 13, "y": 1, "note": "Top-Right Pocket (Player 2)"},
        {"player": 3, "x": 1, "y": 13, "note": "Bottom-Left Pocket (Player 3)"},
        {"player": 4, "x": 13, "y": 13, "note": "Bottom-Right Pocket (Player 4)"}
    ],
    "tile_dictionary": TILE_DICT,
    "layers": {
        "ground": [[NAME_TO_ID.get(GROUND_MATRIX[y][x], 1) for x in range(GRID_W)] for y in range(GRID_H)],
        "objects": [[NAME_TO_ID.get(OBJECTS_MATRIX[y][x], 0) if OBJECTS_MATRIX[y][x] != "FOUNTAIN" else 91 for x in range(GRID_W)] for y in range(GRID_H)],
        "collision": collision_matrix
    }
}

with open(OUT_JSON, "w", encoding="utf-8") as f:
    json.dump(map_json_data, f, indent=2, ensure_ascii=False)
print(f"Exported JSON: {OUT_JSON}")

with open(DATA_MAPS_DIR / "planning_plaza_map.json", "w", encoding="utf-8") as f:
    json.dump(map_json_data, f, indent=2, ensure_ascii=False)

with open(OUT_CSV, "w", newline="", encoding="utf-8") as f:
    writer = csv.writer(f)
    writer.writerow(["Planning Plaza 15x15 Tilemap Collision Data (0=Walkable, 1=Impassable/Wall/Prop, 2=Destructible Crate)"])
    for row in collision_matrix:
        writer.writerow(row)
print(f"Exported CSV: {OUT_CSV}")

# ── Render HD Composite Map (1500 x 1500 px) ──
map_img = Image.new("RGBA", (GRID_W * CELL_PX, GRID_H * CELL_PX), (34, 52, 34, 255))

# Layer 0: Ground (Grass & Stone Path)
for y in range(GRID_H):
    for x in range(GRID_W):
        g_name = GROUND_MATRIX[y][x]
        if g_name in tiles:
            tile_tex = tiles[g_name].resize((CELL_PX, CELL_PX), Image.Resampling.BICUBIC)
            map_img.paste(tile_tex, (x * CELL_PX, y * CELL_PX), tile_tex)

# Layer 1: Centerpiece Fountain (3x3 footprint at cols 6..8, rows 6..8)
if "plaza_center_7x2_full" in tiles:
    f_w = CELL_PX * 3
    f_h = int(CELL_PX * 2.8)
    fountain_tex = tiles["plaza_center_7x2_full"].resize((f_w, f_h), Image.Resampling.BICUBIC)
    map_img.paste(fountain_tex, (6 * CELL_PX, int(6 * CELL_PX - 20)), fountain_tex)

# Layer 2: Contact Shadows
shadow_color = (15, 28, 15, 95)
for y in range(GRID_H):
    for x in range(GRID_W):
        obj = OBJECTS_MATRIX[y][x]
        if obj.startswith("crate") or obj.startswith("prop") or obj.startswith("hedge"):
            shadow_img = Image.new("RGBA", (CELL_PX, CELL_PX), (0, 0, 0, 0))
            sd = ImageDraw.Draw(shadow_img)
            sd.ellipse([int(CELL_PX * 0.12), int(CELL_PX * 0.72), int(CELL_PX * 0.88), int(CELL_PX * 0.95)], fill=shadow_color)
            map_img.paste(shadow_img, (x * CELL_PX, y * CELL_PX), shadow_img)

# Layer 3: Outer Walls
for y in range(GRID_H):
    for x in range(GRID_W):
        obj = OBJECTS_MATRIX[y][x]
        if obj.startswith("wall"):
            if obj in tiles:
                w_tex = tiles[obj].resize((CELL_PX, CELL_PX), Image.Resampling.BICUBIC)
                map_img.paste(w_tex, (x * CELL_PX, y * CELL_PX), w_tex)

# Layer 4: Destructibles (Tall Crates) & Flowerbeds & Props
for y in range(GRID_H):
    for x in range(GRID_W):
        obj = OBJECTS_MATRIX[y][x]
        if obj == "FOUNTAIN" or obj.startswith("wall") or not obj:
            continue
        if obj in tiles:
            tex = tiles[obj]
            if obj.startswith("crate_tall"):
                crate_h = int(CELL_PX * 1.35)
                crate_tex = tex.resize((CELL_PX, crate_h), Image.Resampling.BICUBIC)
                map_img.paste(crate_tex, (x * CELL_PX, y * CELL_PX - (crate_h - CELL_PX)), crate_tex)
            elif obj.startswith("hedge"):
                h_tex = tex.resize((CELL_PX, CELL_PX), Image.Resampling.BICUBIC)
                map_img.paste(h_tex, (x * CELL_PX, y * CELL_PX), h_tex)
            elif obj.startswith("prop"):
                prop_w = int(CELL_PX * (tex.size[0] / 94.0))
                prop_h = int(CELL_PX * (tex.size[1] / 94.0))
                p_tex = tex.resize((prop_w, prop_h), Image.Resampling.BICUBIC)
                px = x * CELL_PX + (CELL_PX - prop_w) // 2
                py = y * CELL_PX + (CELL_PX - prop_h)
                map_img.paste(p_tex, (px, py), p_tex)

# Save HD Full Map
map_img.save(OUT_PNG_FULL, optimize=True)
print(f"Saved HD Full Map Render: {OUT_PNG_FULL} ({map_img.size})")

# ── Render Labeled Map (with 1..15 coordinate bars) ──
labeled_w = GRID_W * CELL_PX + 120
labeled_h = GRID_H * CELL_PX + 120
labeled_img = Image.new("RGBA", (labeled_w, labeled_h), (18, 22, 32, 255))
labeled_draw = ImageDraw.Draw(labeled_img)
offset_x, offset_y = 60, 60
labeled_img.paste(map_img, (offset_x, offset_y))
font = ImageFont.load_default()

for i in range(15):
    col_num = str(i + 1)
    row_num = str(i + 1)
    # Top coordinate
    labeled_draw.text((offset_x + i * CELL_PX + CELL_PX // 2 - 5, 28), col_num, fill=(245, 225, 95), font=font)
    # Bottom coordinate
    labeled_draw.text((offset_x + i * CELL_PX + CELL_PX // 2 - 5, offset_y + GRID_H * CELL_PX + 18), col_num, fill=(245, 225, 95), font=font)
    # Left coordinate
    labeled_draw.text((25, offset_y + i * CELL_PX + CELL_PX // 2 - 5), row_num, fill=(245, 225, 95), font=font)
    # Right coordinate
    labeled_draw.text((offset_x + GRID_W * CELL_PX + 18, offset_y + i * CELL_PX + CELL_PX // 2 - 5), row_num, fill=(245, 225, 95), font=font)

# Outline border
labeled_draw.rectangle([offset_x - 2, offset_y - 2, offset_x + GRID_W * CELL_PX + 2, offset_y + GRID_H * CELL_PX + 2], outline=(90, 140, 210), width=2)
labeled_img.save(OUT_PNG_LABELED, optimize=True)
print(f"Saved Labeled Grid Map Render: {OUT_PNG_LABELED}")

# ── Update UI Preview and QA Preview ──
preview_img = map_img.resize((600, 600), Image.Resampling.LANCZOS)
preview_img.save(OUT_UI_PREVIEW, optimize=True)
preview_img.save(OUT_QA_PREVIEW, optimize=True)
print(f"Saved UI Preview: {OUT_UI_PREVIEW}")
print(f"Saved QA Preview: {OUT_QA_PREVIEW}")

print("\n>>> All Planning Plaza map assets, data, and renders completed successfully!")
