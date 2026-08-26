import cv2
import numpy as np
import os

IMG_DIR = r'C:\Users\khang\Documents\Build\Boom\assets\image'
files = sorted([f for f in os.listdir(IMG_DIR) if f.endswith('.png')])

stds = []
for f in files:
    img = cv2.imread(os.path.join(IMG_DIR, f))
    if img is not None:
        stds.append((f, np.std(img)))

stds.sort(key=lambda x: x[1])
print("Lowest standard deviations:")
for f, std in stds[:5]:
    print(f, std)
