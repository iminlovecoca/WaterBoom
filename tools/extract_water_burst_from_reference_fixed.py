from PIL import Image
import os

IMG_PATH = r'C:\Users\khang\.gemini\antigravity\brain\8d5450db-5a47-4a4a-af37-9aad2b7203db\.user_uploaded\media_1787032369779.png'
OUT_DIR = r'C:\Users\khang\Documents\Build\Boom\assets\water_stream'

if not os.path.exists(IMG_PATH):
    print("Reference image not found.")
    exit(1)

img = Image.open(IMG_PATH).convert('RGBA')

# Bounds measured:
v_left, v_right = 447, 576
h_top, h_bottom = 426, 549
width = v_right - v_left
height = h_bottom - h_top

# Let's make them a square to avoid distortion
size = max(width, height)
v_left = 512 - size//2
v_right = 512 + size//2
h_top = 499 - size//2
h_bottom = 499 + size//2

center_box = (v_left, h_top, v_right, h_bottom)
center = img.crop(center_box)

# Horizontal segment (left arm)
horiz_box = (v_left - size, h_top, v_left, h_bottom)
horizontal = img.crop(horiz_box)

# Vertical segment (top arm)
vert_box = (v_left, h_top - size, v_right, h_top)
vertical = img.crop(vert_box)

# End caps (measured bounds: x: 16-1007, y: 5-994)
end_left_box = (16, h_top, 16 + size, h_bottom)
end_right_box = (1007 - size, h_top, 1007, h_bottom)
end_up_box = (v_left, 5, v_right, 5 + size)
end_down_box = (v_left, 994 - size, v_right, 994)

def process_piece(img_crop, is_end_cap=False, rot=0):
    # Resize to 40x40
    res = img_crop.resize((40, 40), Image.Resampling.LANCZOS)
    if rot != 0:
        res = res.rotate(rot, expand=False)
    return res

pieces = {
    'water_center.png': process_piece(center),
    'water_horizontal.png': process_piece(horizontal),
    'water_vertical.png': process_piece(vertical),
    'water_end_left.png': process_piece(img.crop(end_left_box)),
    'water_end_right.png': process_piece(img.crop(end_right_box)),
    'water_end_up.png': process_piece(img.crop(end_up_box)),
    'water_end_down.png': process_piece(img.crop(end_down_box)),
}

os.makedirs(OUT_DIR, exist_ok=True)
for name, p_img in pieces.items():
    p_img.save(os.path.join(OUT_DIR, name))
    print(f"Saved {name}")

# Additionally, the game expects a `water_cross.png` (sometimes used interchangeably with center)
pieces['water_center.png'].save(os.path.join(OUT_DIR, 'water_cross.png'))
print("Saved water_cross.png")

print("Done extracting fixed water burst pieces.")
