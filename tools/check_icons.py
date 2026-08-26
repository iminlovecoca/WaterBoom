import os
from PIL import Image

BASE_DIR = r'C:\Users\khang\Documents\Build\Boom\assets\water_balloons\skins'
OUT_PATH = r'C:\Users\khang\.gemini\antigravity\brain\8d5450db-5a47-4a4a-af37-9aad2b7203db\test_all_icons.jpg'

def main():
    icons = []
    for i in range(1, 63):
        skin_id = f"skin_{i:03d}"
        path = os.path.join(BASE_DIR, skin_id, "icon.png")
        if os.path.exists(path):
            icons.append(Image.open(path).convert("RGBA"))
        else:
            icons.append(Image.new("RGBA", (64, 64), (0,0,0,0)))
            
    # Create 8x8 grid
    grid = Image.new("RGBA", (64*8, 64*8), (255, 0, 0, 255)) # Red background to easily spot checkerboard
    for i, icon in enumerate(icons):
        row = i // 8
        col = i % 8
        grid.paste(icon, (col*64, row*64), icon)
        
    grid.convert("RGB").save(OUT_PATH)
    print(f"Saved {OUT_PATH}")

if __name__ == '__main__':
    main()
