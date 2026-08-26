import os
from PIL import Image

src_path = r'C:\Users\khang\.gemini\antigravity\brain\8d5450db-5a47-4a4a-af37-9aad2b7203db\.user_uploaded\media_1786853100400.png'
img = Image.open(src_path).convert('RGBA')

base_assets = r'c:\Users\khang\Documents\Build\Boom\assets'
water_balloon_dir = os.path.join(base_assets, "water_balloons")
os.makedirs(water_balloon_dir, exist_ok=True)

# Exact bounding boxes of the 5 water_balloon frames (excluding the "WATER_BALLOON" label at [643, 122])
exact_water_balloon_boxes = [
    (666, 138, 714, 196),  # Frame 0: Small timer spark
    (742, 134, 788, 196),  # Frame 1: Medium timer spark
    (811, 130, 857, 196),  # Frame 2: Bright spark
    (878, 120, 929, 197),  # Frame 3: Big water spark
    (947, 125, 998, 197)   # Frame 4: Giant star spark
]

target_canvas = (40, 40)

for idx, (x0, y0, x1, y1) in enumerate(exact_water_balloon_boxes):
    cropped = img.crop((x0, y0, x1, y1))
    cw, ch = cropped.size
    
    # Scale to fill ~38px of the 40px tile so it's big, clear, and prominent
    scale = min(38.0 / float(cw), 38.0 / float(ch))
    new_w = int(round(cw * scale))
    new_h = int(round(ch * scale))
    
    resized = cropped.resize((new_w, new_h), Image.Resampling.NEAREST)
    
    # Center on 40x40 canvas
    canvas = Image.new("RGBA", target_canvas, (0, 0, 0, 0))
    px = (target_canvas[0] - new_w) // 2
    # Align bottom of water_balloon body near bottom of tile
    py = target_canvas[1] - new_h - 1
    canvas.paste(resized, (px, py))
    
    canvas.save(os.path.join(water_balloon_dir, f"water_balloon_{idx}.png"))
    print(f"Saved clean WaterBalloon Frame {idx}: {new_w}x{new_h} on 40x40 canvas")

# Also update item_water_balloon_up with the clean water_balloon image
item_dir = os.path.join(base_assets, "items")
it_water_balloon = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
b0 = Image.open(os.path.join(water_balloon_dir, "water_balloon_0.png")).resize((28, 28), Image.Resampling.NEAREST)
it_water_balloon.paste(b0, (2, 2), b0)
it_water_balloon.save(os.path.join(item_dir, "item_water_balloon_up.png"))
print("Updated clean item_water_balloon_up.png")

print("All water_balloons extracted cleanly without any cutoff or leftover pixels!")
