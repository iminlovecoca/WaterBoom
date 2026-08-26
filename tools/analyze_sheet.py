import cv2
import numpy as np
from PIL import Image

src_path = r'C:\Users\khang\.gemini\antigravity\brain\8d5450db-5a47-4a4a-af37-9aad2b7203db\.user_uploaded\media_1786853100400.png'
img = Image.open(src_path).convert('RGBA')
arr = np.array(img)

print("Image shape:", arr.shape)
# Inspect corners for background color
print("Top-left pixel:", arr[0, 0])
print("Bottom-left pixel:", arr[-1, 0])
print("Top-right pixel:", arr[0, -1])

# Check white background threshold
is_white = (arr[:, :, 0] > 245) & (arr[:, :, 1] > 245) & (arr[:, :, 2] > 245)
print("White background percentage: %.2f%%" % (np.mean(is_white) * 100))
