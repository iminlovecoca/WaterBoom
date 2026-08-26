import os
from PIL import Image
import numpy as np
from collections import deque
from scipy import ndimage

ROOT = r'c:\Users\khang\Documents\Build\Boom'
img2_p = r'C:\Users\khang\.gemini\antigravity\brain\8d5450db-5a47-4a4a-af37-9aad2b7203db\.user_uploaded\media_1786953518304.png'
img3_p = r'C:\Users\khang\.gemini\antigravity\brain\8d5450db-5a47-4a4a-af37-9aad2b7203db\.user_uploaded\media_1786953526324.png'

im2 = Image.open(img2_p).convert('RGBA')
im3 = Image.open(img3_p).convert('RGBA')

def remove_background_bfs(crop_img, bg_color, tol=25):
    """Flood-fills from outer borders to remove the solid cyan background."""
    arr = np.array(crop_img)
    H, W = arr.shape[:2]
    
    # Calculate color distance to background
    diff = np.sqrt(np.sum((arr[:, :, :3].astype(np.float32) - np.array(bg_color[:3], dtype=np.float32))**2, axis=-1))
    is_bg = diff < tol
    
    visited = np.zeros((H, W), dtype=bool)
    queue = deque()
    
    for x in range(W):
        if is_bg[0, x]: queue.append((0, x)); visited[0, x] = True
        if is_bg[H - 1, x]: queue.append((H - 1, x)); visited[H - 1, x] = True
    for y in range(H):
        if is_bg[y, 0]: queue.append((y, 0)); visited[y, 0] = True
        if is_bg[y, W - 1]: queue.append((y, W - 1)); visited[y, W - 1] = True
        
    while queue:
        cy, cx = queue.popleft()
        for dy, dx in [(-1, 0), (1, 0), (0, -1), (0, 1)]:
            ny, nx = cy + dy, cx + dx
            if 0 <= ny < H and 0 <= nx < W:
                if not visited[ny, nx] and is_bg[ny, nx]:
                    visited[ny, nx] = True
                    queue.append((ny, nx))
                    
    arr[visited, 3] = 0
    return Image.fromarray(arr)

def auto_isolate_balloon(clean_img, target_size=128):
    """Finds the main balloon component, centers it on target canvas."""
    arr = np.array(clean_img)
    alpha = arr[:, :, 3]
    labeled, num_features = ndimage.label(alpha > 20)
    if num_features == 0:
        return clean_img
        
    sizes = ndimage.sum(alpha > 20, labeled, range(num_features + 1))
    largest_idx = np.argmax(sizes[1:]) + 1
    
    mask = (labeled == largest_idx)
    arr[~mask] = [0, 0, 0, 0]
    isolated = Image.fromarray(arr)
    
    bbox = isolated.getbbox()
    if not bbox:
        return clean_img
        
    cropped = isolated.crop(bbox)
    cw, ch = cropped.size
    
    # Scale to ~80% of target_size (e.g. 102px on 128x128 canvas)
    target_dim = 100
    scale = target_dim / float(max(cw, ch))
    nw = max(1, int(round(cw * scale)))
    nh = max(1, int(round(ch * scale)))
    
    resized = cropped.resize((nw, nh), Image.Resampling.LANCZOS)
    canvas = Image.new("RGBA", (target_size, target_size), (0, 0, 0, 0))
    px = (target_size - nw) // 2
    py = (target_size - nh) // 2
    canvas.paste(resized, (px, py), resized)
    return canvas

# Let's extract all balloons from Image 2 (1024x576)
bg2 = im2.getpixel((0, 0))
for r in range(3):
    for c in range(8):
        box = (c * 128, r * 192, (c + 1) * 128, (r + 1) * 192)
        crop = im2.crop(box)
        clean = remove_background_bfs(crop, bg2, tol=30)
        balloon = auto_isolate_balloon(clean)
        balloon.save(f'development/extracted_im2_r{r}_c{c}.png')

# Let's extract all balloons from Image 3 (596x335)
bg3 = im3.getpixel((0, 0))
col_w = 596 / 7.0
row_h = 335 / 3.0
for r in range(3):
    for c in range(7):
        box = (int(c * col_w), int(r * row_h), int((c + 1) * col_w), int((r + 1) * row_h))
        crop = im3.crop(box)
        clean = remove_background_bfs(crop, bg3, tol=30)
        balloon = auto_isolate_balloon(clean)
        balloon.save(f'development/extracted_im3_r{r}_c{c}.png')

print('All reference balloons extracted and isolated with clean transparency!')
