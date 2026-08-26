import os
from PIL import Image, ImageDraw

ROOT = r'c:\Users\khang\Documents\Build\Boom'
DEV_DIR = os.path.join(ROOT, 'development')
TILESETS_DIR = os.path.join(ROOT, 'assets', 'tilesets')

# 15x13 standard arena
GRID_W = 15
GRID_H = 13
CELL_SIZE = 40

def render_map_preview(theme_id, output_name):
    theme_dir = os.path.join(TILESETS_DIR, theme_id, "runtime")
    f_base = Image.open(os.path.join(theme_dir, "floor.png")).convert("RGBA")
    f_alt = Image.open(os.path.join(theme_dir, "floor_alt.png")).convert("RGBA")
    wall_img = Image.open(os.path.join(theme_dir, "hard_block.png")).convert("RGBA")
    crate_img = Image.open(os.path.join(theme_dir, "soft_block.png")).convert("RGBA")
    
    map_img = Image.new("RGBA", (GRID_W * CELL_SIZE, GRID_H * CELL_SIZE), (20, 20, 30, 255))
    
    # Standard classic layout:
    # Outer border = Wall
    # Pillars on odd (x, y) = Wall
    # Inner spaces = Floor with soft blocks (crates)
    for y in range(GRID_H):
        for x in range(GRID_W):
            px, py = x * CELL_SIZE, y * CELL_SIZE
            is_border = (x == 0 or y == 0 or x == GRID_W - 1 or y == GRID_H - 1)
            is_pillar = (x % 2 == 0 and y % 2 == 0 and not is_border)
            
            # Floor everywhere inside
            if not is_border:
                is_alt = ((x * 37 + y * 61) % 100) < 22
                floor_tex = f_alt if is_alt else f_base
                map_img.paste(floor_tex, (px, py), floor_tex)
                
            # Walls
            if is_border or is_pillar:
                map_img.paste(wall_img, (px, py), wall_img)
            else:
                # Crates in some non-spawn lanes
                is_spawn = (x in [1, 2] and y in [1, 2]) or (x in [12, 13] and y in [1, 2]) or (x in [1, 2] and y in [10, 11]) or (x in [12, 13] and y in [10, 11])
                if not is_spawn and ((x + y * 3) % 4 != 0):
                    map_img.paste(crate_img, (px, py), crate_img)
                    
    out_path = os.path.join(DEV_DIR, output_name)
    map_img.save(out_path, optimize=True)
    print(f"Rendered Map QA Preview: {out_path}")

render_map_preview("egypt_temple", "qa_map_desert.png")
render_map_preview("ice_labyrinth", "qa_map_ice.png")
render_map_preview("lego_city", "qa_map_toy_city.png")
render_map_preview("training_plaza", "qa_map_plaza.png")
render_map_preview("aqua_park", "qa_map_aqua_park.png")
render_map_preview("pirate_harbor", "qa_map_pirate_harbor.png")
print("All QA map previews rendered successfully!")
