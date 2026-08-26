import os
from PIL import Image

ROOT = r'c:\Users\khang\Documents\Build\Boom'
PREVIEW_DIR = os.path.join(ROOT, 'assets', 'ui', 'map_previews')

def generate_preview(theme_name):
    t_dir = os.path.join(ROOT, 'assets', 'tilesets', theme_name, 'runtime')
    floor = Image.open(os.path.join(t_dir, 'floor.png')).convert('RGBA')
    floor_alt = Image.open(os.path.join(t_dir, 'floor_alt.png')).convert('RGBA')
    hard = Image.open(os.path.join(t_dir, 'hard_block.png')).convert('RGBA')
    soft = Image.open(os.path.join(t_dir, 'soft_block.png')).convert('RGBA')
    
    # 16x16 grid -> 640x640 image
    img = Image.new('RGBA', (640, 640), (0, 0, 0, 255))
    for y in range(16):
        for x in range(16):
            px, py = x * 40, y * 40
            # Border
            if x == 0 or x == 15 or y == 0 or y == 15:
                img.paste(hard, (px, py))
            elif x % 2 == 0 and y % 2 == 0:
                img.paste(hard, (px, py))
            elif (x + y) % 3 == 0 and (x not in (1, 2, 13, 14) or y not in (1, 2, 13, 14)):
                img.paste(soft, (px, py))
            else:
                img.paste(floor_alt if (x + y) % 2 == 0 else floor, (px, py))
                
    preview_img = img.resize((368, 207), Image.Resampling.LANCZOS)
    out_path = os.path.join(PREVIEW_DIR, f'map_{theme_name}.png')
    preview_img.save(out_path)
    print(f"Generated preview for {theme_name} at {out_path}")

generate_preview('egypt_temple')
generate_preview('ice_labyrinth')
