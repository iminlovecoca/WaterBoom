import numpy as np
from PIL import Image

src_path = r'C:\Users\khang\.gemini\antigravity\brain\8d5450db-5a47-4a4a-af37-9aad2b7203db\.user_uploaded\media_1786853100400.png'
img = Image.open(src_path).convert('RGBA')
arr = np.array(img)

# Width of character sheet section:
# Column 0: x in [65, 140]
# Column 1: x in [140, 216]
# Column 2: x in [216, 292]
# Column 3: x in [292, 368]
# Column 4: x in [368, 444]
# Column 5: x in [444, 520]
# Column 6: x in [520, 596]
# Notice that each column is EXACTLY 76.0 pixels wide (65 + i * 76.0)!

cols = [
    (65, 140),
    (141, 216),
    (217, 292),
    (293, 368),
    (369, 444),
    (445, 520),
    (521, 596)
]

for idx, (x0, x1) in enumerate(cols):
    cell = arr[12:78, x0:x1, 3]
    print(f"Col {idx}: x in [{x0}, {x1}] -> non-zero pixels: {np.sum(cell > 10)}")
