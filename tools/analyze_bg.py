from PIL import Image
import numpy as np

img = Image.open('C:/Users/khang/Documents/Build/Boom/assets/water_balloons/reference_sheet.png')
arr = np.array(img).astype(float)

# Gap area = pure background
gap = arr[111:158, 0:36]
print('Gap area mean:', gap.mean(axis=(0,1)))
print('Gap area std:', gap.std(axis=(0,1)))

# Sample balloon edge pixels
bal0 = arr[37:111, 37:111]
# Corners of balloon cell
print()
print('Balloon 0 cell corners:')
print('  TL(0,0):', bal0[0,0])
print('  TR(0,73):', bal0[0,73])
print('  BL(73,0):', bal0[73,0])
print('  BR(73,73):', bal0[73,73])
print('  Center(37,37):', bal0[37,37])

# Check: is the background actually 222 or something else?
# Look at all corner pixels across multiple cells
all_corners = []
ROW_BANDS = [(37,110), (159,231), (280,353), (400,473), (521,596), (643,716), (763,837), (885,958)]
COL_BANDS = [(37,110), (163,235), (289,360), (415,486), (539,609), (665,736), (789,861), (917,986)]

for r1, r2 in ROW_BANDS:
    for c1, c2 in COL_BANDS:
        cell = arr[r1:r2+1, c1:c2+1]
        # Check the 4 corner pixels
        all_corners.append(cell[0, 0])
        all_corners.append(cell[0, -1])
        all_corners.append(cell[-1, 0])
        all_corners.append(cell[-1, -1])

all_corners = np.array(all_corners)
print()
print('All cell corners:')
print('  Mean RGB:', all_corners.mean(axis=0))
print('  Std:', all_corners.std(axis=0))
print('  Min:', all_corners.min(axis=0))
print('  Max:', all_corners.max(axis=0))

# The background color
bg = all_corners.mean(axis=0)
print()
print('Detected background color:', bg)
