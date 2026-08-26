import numpy as np
from PIL import Image

src_path = r'C:\Users\khang\.gemini\antigravity\brain\8d5450db-5a47-4a4a-af37-9aad2b7203db\.user_uploaded\media_1786853100400.png'
img = Image.open(src_path).convert('RGBA')
arr = np.array(img)

# Let's inspect the vertical regions on the left label side (x in [0..60]) to see where each label text is!
label_alpha = arr[:, 0:60, 3]
label_row_sums = np.sum(label_alpha > 10, axis=1)

in_label = False
labels = []
for y, s in enumerate(label_row_sums):
    if s > 0 and not in_label:
        in_label = True
        labels.append(y)
    elif s == 0 and in_label:
        in_label = False
        labels.append(y)

print("Label y-intervals:")
for i in range(len(labels)//2):
    y0 = labels[2*i]
    y1 = labels[2*i + 1]
    # Crop label to print
    print(f"Label {i}: y in [{y0}, {y1}]")

# Let's inspect the water_balloon area on right side (x >= 620):
water_balloon_alpha = arr[:, 620:, 3]
water_balloon_row_sums = np.sum(water_balloon_alpha > 10, axis=1)

in_r = False
r_intervals = []
for y, s in enumerate(water_balloon_row_sums):
    if s > 0 and not in_r:
        in_r = True
        r_intervals.append(y)
    elif s == 0 and in_r:
        in_r = False
        r_intervals.append(y)

print("\nRight side content intervals:")
for i in range(len(r_intervals)//2):
    y0 = r_intervals[2*i]
    y1 = r_intervals[2*i + 1]
    print(f"Section {i}: y in [{y0}, {y1}]")
