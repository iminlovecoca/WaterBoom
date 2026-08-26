import numpy as np
from PIL import Image, ImageDraw

src_path = r'C:\Users\khang\.gemini\antigravity\brain\8d5450db-5a47-4a4a-af37-9aad2b7203db\.user_uploaded\media_1786853100400.png'
img = Image.open(src_path).convert('RGBA')
arr = np.array(img)

# Let's inspect the exact vertical row intervals by calculating horizontal projection (sum across columns)
# For the character section x in [60, 615]
char_section_alpha = arr[:, 60:615, 3]
row_sums = np.sum(char_section_alpha > 10, axis=1)

# Find row valleys where row_sums == 0
row_valleys = []
in_gap = True
for y, s in enumerate(row_sums):
    if s == 0 and not in_gap:
        in_gap = True
        row_valleys.append(y)
    elif s > 0 and in_gap:
        in_gap = False
        row_valleys.append(y)

print("Row transitions (gaps & content starts):", row_valleys)

# Let's also check column intervals for each row
for r_idx in range(len(row_valleys)//2):
    y0 = row_valleys[2*r_idx]
    y1 = row_valleys[2*r_idx + 1] if 2*r_idx + 1 < len(row_valleys) else len(row_sums)
    print(f"Row {r_idx}: y in [{y0}, {y1}] (height = {y1 - y0})")
