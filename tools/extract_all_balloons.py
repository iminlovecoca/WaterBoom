import cv2
import numpy as np
import os
import glob
from pathlib import Path

# We might need rembg, try to import
try:
    from rembg import remove
    import onnxruntime
except ImportError:
    remove = None

IMG_PATH = r'C:\Users\khang\.gemini\antigravity\brain\8d5450db-5a47-4a4a-af37-9aad2b7203db\.user_uploaded\media_1787032639590.jpg'
OUT_DIR = r'C:\Users\khang\Documents\Build\Boom\assets\water_balloon\raw_extracted'

def main():
    if not os.path.exists(IMG_PATH):
        print("Image not found:", IMG_PATH)
        return
        
    os.makedirs(OUT_DIR, exist_ok=True)
    img = cv2.imread(IMG_PATH, cv2.IMREAD_UNCHANGED)
    
    h, w = img.shape[:2]
    
    # 9 columns, 8 rows
    cols = 9
    rows = 8
    
    cell_w = w / cols
    cell_h = h / rows
    
    count = 0
    for r in range(rows):
        for c in range(cols):
            x1 = int(c * cell_w)
            y1 = int(r * cell_h)
            x2 = int((c + 1) * cell_w)
            y2 = int((r + 1) * cell_h)
            
            cell = img[y1:y2, x1:x2]
            
            # Check if cell is completely empty/transparent or just background.
            # We can check the standard deviation of edges or colors.
            # A completely flat background cell will have low edge std.
            gray = cv2.cvtColor(cell, cv2.COLOR_BGR2GRAY)
            edges = cv2.Canny(gray, 30, 100)
            
            if np.sum(edges) < 1000:  # arbitrary low threshold for empty cell
                continue
                
            out_path = os.path.join(OUT_DIR, f'balloon_{count:02d}.png')
            
            # Use rembg if available, otherwise save as is.
            if remove is not None:
                # Convert BGR to RGB for rembg (or use bytes)
                cell_rgba = cv2.cvtColor(cell, cv2.COLOR_BGR2BGRA)
                # We can just process bytes
                success, encoded_img = cv2.imencode('.png', cell_rgba)
                if success:
                    output_bytes = remove(encoded_img.tobytes())
                    # Convert bytes back to cv2 image
                    nparr = np.frombuffer(output_bytes, np.uint8)
                    result_img = cv2.imdecode(nparr, cv2.IMREAD_UNCHANGED)
                    cv2.imwrite(out_path, result_img)
                    print(f'Extracted and background removed: {out_path}')
            else:
                cv2.imwrite(out_path, cell)
                print(f'Extracted raw: {out_path}')
                
            count += 1

if __name__ == '__main__':
    main()
