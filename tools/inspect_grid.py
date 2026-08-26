import numpy as np
from PIL import Image

src_path = r'C:\Users\khang\.gemini\antigravity\brain\8d5450db-5a47-4a4a-af37-9aad2b7203db\.user_uploaded\media_1786853100400.png'
img = Image.open(src_path).convert('RGBA')
arr = np.array(img)

# Let's inspect the columns for row 0 (IDLE) from x=60 to x=615
idle_alpha = arr[0:78, 60:615, 3]
col_sums = np.sum(idle_alpha > 10, axis=0)

print("Non-zero column segments in IDLE row:")
zero_indices = np.where(col_sums == 0)[0]
# Print valleys (where col_sums drops to 0 or near 0)
valleys = []
for i in range(1, len(col_sums)-1):
    if col_sums[i] == 0:
        valleys.append(i + 60)
print(f"Valleys count: {len(valleys)}")

# Let's check uniform grid spacing:
# Width of character area = 615 - 60 = 555px
# 7 frames -> each frame is roughly 555 / 7 = ~79.28 pixels!
# Let's verify if each frame is evenly spaced at width ~79px:
for i in range(7):
    x0 = int(60 + i * 79.28)
    x1 = int(60 + (i + 1) * 79.28)
    print(f"Frame {i}: x in [{x0}, {x1}]")
