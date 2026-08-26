import cv2
import numpy as np

IMG_PATH = r'C:\Users\khang\.gemini\antigravity\brain\8d5450db-5a47-4a4a-af37-9aad2b7203db\.user_uploaded\media_1787032639590.jpg'

def main():
    img = cv2.imread(IMG_PATH, cv2.IMREAD_COLOR)
    gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
    
    # The balloons are colorful, the background is a grey/white checkerboard.
    # The checkerboard is light (val > 200). 
    # Let's threshold to find the balloons.
    # We can also use edge detection, as balloons have strong edges.
    edges = cv2.Canny(gray, 50, 150)
    
    # Morphological close to connect balloon edges
    kernel = cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (15, 15))
    closed = cv2.morphologyEx(edges, cv2.MORPH_CLOSE, kernel)
    
    # Find contours
    contours, _ = cv2.findContours(closed, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
    
    valid_balloons = []
    for cnt in contours:
        x, y, w, h = cv2.boundingRect(cnt)
        # Balloons should be roughly 70x70 to 110x110
        if 50 < w < 120 and 50 < h < 120:
            valid_balloons.append((x, y, w, h))
            
    print(f"Found {len(valid_balloons)} potential balloons")
    
if __name__ == '__main__':
    main()
