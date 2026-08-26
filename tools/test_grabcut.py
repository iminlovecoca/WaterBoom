import cv2
import numpy as np

IMG_PATH = r'C:\Users\khang\.gemini\antigravity\brain\8d5450db-5a47-4a4a-af37-9aad2b7203db\.user_uploaded\media_1787032639590.jpg'
OUT_PATH = r'C:\Users\khang\Documents\Build\Boom\tools\grabcut_test.png'

def main():
    img = cv2.imread(IMG_PATH, cv2.IMREAD_COLOR)
    
    # Cow balloon is skin_024
    # From catalog: source_row: 2, source_col: 7 (Wait, let me check the catalog to be sure)
    # Actually, I'll just crop the cell for skin_024 using the same math:
    h, w = img.shape[:2]
    cell_w = w / 8
    cell_h = h / 8
    
    # Wait, skin_024 is what? Let's just crop row 2, col 7 to see
    r, c = 2, 7
    x1, y1 = int(c * cell_w), int(r * cell_h)
    x2, y2 = int((c + 1) * cell_w), int((r + 1) * cell_h)
    cell = img[y1:y2, x1:x2]
    
    # Apply GrabCut
    mask = np.zeros(cell.shape[:2], np.uint8)
    bgdModel = np.zeros((1,65), np.float64)
    fgdModel = np.zeros((1,65), np.float64)
    
    # The balloon is roughly in the center, so rect is [10, 10, w-20, h-20]
    rect = (10, 10, cell.shape[1]-20, cell.shape[0]-20)
    
    cv2.grabCut(cell, mask, rect, bgdModel, fgdModel, 5, cv2.GC_INIT_WITH_RECT)
    
    # mask2 is where we are sure it's foreground (1) or likely foreground (3)
    mask2 = np.where((mask==2)|(mask==0), 0, 1).astype('uint8')
    cell_rgba = cv2.cvtColor(cell, cv2.COLOR_BGR2BGRA)
    cell_rgba[:, :, 3] = mask2 * 255
    
    cv2.imwrite(OUT_PATH, cell_rgba)
    print("Saved GrabCut test to", OUT_PATH)

if __name__ == '__main__':
    main()
