from PIL import Image
import numpy as np

img = Image.open('C:/Users/khang/Documents/Build/Boom/assets/water_balloons/reference_sheet.png')
arr = np.array(img)

ROW_BANDS = [(37,110), (159,231), (280,353), (400,473), (521,596), (643,716), (763,837), (885,958)]
COL_BANDS = [(37,110), (163,235), (289,360), (415,486), (539,609), (665,736), (789,861), (917,986)]

# Check balloon 0 (first one) - what's the actual balloon radius?
cell = arr[37:111, 37:111]
print(f"Cell shape: {cell.shape}")  # Should be 74x74

# Find balloon boundary by looking for non-gray pixels
r, g, b = cell[:,:,0].astype(float), cell[:,:,1].astype(float), cell[:,:,2].astype(float)
sat = np.max(cell[:,:,:3], axis=2).astype(float) - np.min(cell[:,:,:3], axis=2).astype(float)
bright = (r + g + b) / 3.0

# Balloon = high saturation OR very dark OR very bright (but not gray)
balloon = (sat > 20) | (bright < 150) | ((bright > 240) & (sat > 10))

# Find bounding box of balloon content
rows = np.where(balloon.any(axis=1))[0]
cols = np.where(balloon.any(axis=0))[0]
print(f"Balloon content: rows {rows[0]}-{rows[-1]}, cols {cols[0]}-{cols[-1]}")
print(f"Content size: {rows[-1]-rows[0]+1}x{cols[-1]-cols[0]+1}")
print(f"Cell size: {cell.shape[0]}x{cell.shape[1]}")
print(f"Padding top: {rows[0]}, bottom: {cell.shape[0]-rows[-1]-1}, left: {cols[0]}, right: {cell.shape[1]-cols[-1]-1}")

# Check a few more balloons
for idx, (r1,r2), (c1,c2) in [(5, ROW_BANDS[0], COL_BANDS[1]), (20, ROW_BANDS[2], COL_BANDS[4]), (40, ROW_BANDS[5], COL_BANDS[0])]:
    cell2 = arr[r1:r2+1, c1:c2+1]
    r2_, g2_, b2_ = cell2[:,:,0].astype(float), cell2[:,:,1].astype(float), cell2[:,:,2].astype(float)
    sat2 = np.max(cell2[:,:,:3], axis=2).astype(float) - np.min(cell2[:,:,:3], axis=2).astype(float)
    bright2 = (r2_ + g2_ + b2_) / 3.0
    balloon2 = (sat2 > 20) | (bright2 < 150) | ((bright2 > 240) & (sat2 > 10))
    rows2 = np.where(balloon2.any(axis=1))[0]
    cols2 = np.where(balloon2.any(axis=0))[0]
    print(f"\nBalloon {idx}: rows {rows2[0]}-{rows2[-1]}, cols {cols2[0]}-{cols2[-1]}")
    print(f"  Size: {rows2[-1]-rows2[0]+1}x{cols2[-1]-cols2[0]+1}, padding T/B/L/R: {rows2[0]}/{cell2.shape[0]-rows2[-1]-1}/{cols2[0]}/{cell2.shape[1]-cols2[-1]-1}")
