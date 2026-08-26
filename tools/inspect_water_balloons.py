import cv2
import numpy as np
from PIL import Image

src_path = r'C:\Users\khang\.gemini\antigravity\brain\8d5450db-5a47-4a4a-af37-9aad2b7203db\.user_uploaded\media_1786853100400.png'
img = Image.open(src_path).convert('RGBA')
arr = np.array(img)

# Crop the water_balloon row precisely:
# WaterBalloon row is located below WATER_BALLOON label (y in [120, 205], x in [640, 1005])
water_balloon_patch = arr[120:205, 640:1005]
alpha = (water_balloon_patch[:, :, 3] > 15).astype(np.uint8)

# Find connected components with bounding boxes
num_labels, labels, stats, centroids = cv2.connectedComponentsWithStats(alpha)

raw_comps = []
for i in range(1, num_labels):
    x, y, w, h, area = stats[i]
    if area >= 25:
        raw_comps.append((x + 640, y + 120, w, h, area))

print("Raw water_balloon components found:", len(raw_comps))

# Merge parts belonging to the same water_balloon (timer sparks + water_balloon body)
# Group components that overlap or are within 8px of each other
merged = []
for c in sorted(raw_comps, key=lambda x: x[0]):
    x, y, w, h, area = c
    did_merge = False
    for m_i, (mx, my, mw, mh, m_area) in enumerate(merged):
        # If horizontally close (within 8px)
        if max(x, mx) <= min(x + w, mx + mw) + 8:
            nx = min(x, mx)
            ny = min(y, my)
            nw = max(x + w, mx + mw) - nx
            nh = max(y + h, my + mh) - ny
            merged[m_i] = (nx, ny, nw, nh, m_area + area)
            did_merge = True
            break
    if not did_merge:
        merged.append(c)

merged.sort(key=lambda x: x[0])
print(f"Merged exact water_balloon frames count: {len(merged)}")
for idx, (x, y, w, h, area) in enumerate(merged):
    print(f"WaterBalloon Frame {idx}: x in [{x}, {x+w}], y in [{y}, {y+h}], size = {w}x{h}")
