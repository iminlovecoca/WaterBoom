from PIL import Image
import os

IMG_PATH = r'C:\Users\khang\.gemini\antigravity\brain\8d5450db-5a47-4a4a-af37-9aad2b7203db\.user_uploaded\media_1787032369779.png'
OUT_DIR = r'C:\Users\khang\Documents\Build\Boom\assets\water_stream'

if not os.path.exists(IMG_PATH):
    print("Reference image not found.")
    exit(1)

img = Image.open(IMG_PATH).convert('RGBA')
bbox = img.getbbox()
if not bbox:
    print("Image is empty.")
    exit(1)

cropped = img.crop(bbox)
cw, ch = cropped.size

# To find the true vertical bar width, we scan a row near the top (e.g. y=10)
top_row = [cropped.getpixel((x, 10))[3] for x in range(cw)]
v_left = next(x for x, a in enumerate(top_row) if a > 10)
v_right = cw - next(x for x, a in enumerate(reversed(top_row)) if a > 10) - 1

# To find the true horizontal bar height, we scan a col near the left (e.g. x=10)
left_col = [cropped.getpixel((10, y))[3] for y in range(ch)]
h_top = next(y for y, a in enumerate(left_col) if a > 10)
h_bottom = ch - next(y for y, a in enumerate(reversed(left_col)) if a > 10) - 1

print(f"Vertical bar X: {v_left} to {v_right} (width: {v_right - v_left})")
print(f"Horizontal bar Y: {h_top} to {h_bottom} (height: {h_bottom - h_top})")

# The center intersection is exactly:
center_box = (v_left, h_top, v_right, h_bottom)
center = cropped.crop(center_box)

# We want a segment of the horizontal and vertical bars for tiling
# Let's just use the center box's width/height to extract a square segment
seg_w = v_right - v_left
seg_h = h_bottom - h_top

# Horizontal segment (take from the left arm, right before the center)
# Actually, the ripples repeat. We should just crop a segment from the left arm.
horiz_box = (v_left - seg_w, h_top, v_left, h_bottom)
horizontal = cropped.crop(horiz_box)

# Vertical segment (take from the top arm, right above the center)
vert_box = (v_left, h_top - seg_h, v_right, h_top)
vertical = cropped.crop(vert_box)

# For the ends, we take the absolute tips of the cross
end_left_box = (0, h_top, seg_w, h_bottom)
end_right_box = (cw - seg_w, h_top, cw, h_bottom)
end_up_box = (v_left, 0, v_right, seg_h)
end_down_box = (v_left, ch - seg_h, v_right, ch)

def resize(img):
    # Resize to 40x40 to match the game's tile size perfectly
    return img.resize((40, 40), Image.Resampling.LANCZOS)

pieces = {
    'water_center.png': center,
    'water_horizontal.png': horizontal,
    'water_vertical.png': vertical,
    'water_end_left.png': cropped.crop(end_left_box),
    'water_end_right.png': cropped.crop(end_right_box),
    'water_end_up.png': cropped.crop(end_up_box),
    'water_end_down.png': cropped.crop(end_down_box),
}

os.makedirs(OUT_DIR, exist_ok=True)
for name, p_img in pieces.items():
    resized = resize(p_img)
    resized.save(os.path.join(OUT_DIR, name))
    print(f"Saved {name}")

print("Done extracting water burst pieces.")
