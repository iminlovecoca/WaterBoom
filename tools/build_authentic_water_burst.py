from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter
import math

OUT = Path(r"c:\Users\khang\Documents\Build\Boom\assets\water_stream")
SIZE = 40

# Colors based on the user's reference image
OUTLINE_COLOR = (0, 150, 240, 255)    # Outer border color
CORE_COLOR = (0, 210, 255, 255)       # Main cyan body
RIPPLE_COLOR = (180, 240, 255, 255)   # Light cyan / white ripples
HIGHLIGHT = (255, 255, 255, 255)      # Pure white
GLOW = (0, 180, 255, 120)

def _new() -> Image.Image:
    return Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))

def draw_scalloped_border(draw, x0, y0, x1, y1, axis='h'):
    # Draw small circles along the edge to create the bumpy/scalloped look
    # spacing must evenly divide SIZE (40) so it tiles seamlessly.
    # 40 / 5 = 8 px spacing
    spacing = 8
    radius = 3
    if axis == 'h':
        for x in range(x0, x1 + 1, spacing):
            # Top edge
            draw.ellipse((x - radius, y0 - radius, x + radius, y0 + radius), fill=OUTLINE_COLOR)
            # Bottom edge
            draw.ellipse((x - radius, y1 - radius, x + radius, y1 + radius), fill=OUTLINE_COLOR)
    else:
        for y in range(y0, y1 + 1, spacing):
            # Left edge
            draw.ellipse((x0 - radius, y - radius, x0 + radius, y + radius), fill=OUTLINE_COLOR)
            # Right edge
            draw.ellipse((x1 - radius, y - radius, x1 + radius, y + radius), fill=OUTLINE_COLOR)

def draw_scallop_highlights(draw, x0, y0, x1, y1, axis='h'):
    spacing = 8
    radius = 1.5
    if axis == 'h':
        for x in range(x0, x1 + 1, spacing):
            draw.ellipse((x - radius, y0 - radius, x + radius, y0 + radius), fill=HIGHLIGHT)
            draw.ellipse((x - radius, y1 - radius, x + radius, y1 + radius), fill=HIGHLIGHT)
    else:
        for y in range(y0, y1 + 1, spacing):
            draw.ellipse((x0 - radius, y - radius, x0 + radius, y + radius), fill=HIGHLIGHT)
            draw.ellipse((x1 - radius, y - radius, x1 + radius, y + radius), fill=HIGHLIGHT)

def draw_ripples(draw, x0, y0, x1, y1, axis='h'):
    # Draw the crescent ripples.
    spacing = 10
    if axis == 'h':
        for x in range(x0, x1 + 1, spacing):
            # Draw an arc / crescent
            # We can use a thick arc or an ellipse with another ellipse subtracted
            rect = (x - 6, y0 + 2, x + 6, y1 - 2)
            draw.arc(rect, start=-90, end=90, fill=RIPPLE_COLOR, width=3)
    else:
        for y in range(y0, y1 + 1, spacing):
            rect = (x0 + 2, y - 6, x1 - 2, y + 6)
            draw.arc(rect, start=0, end=180, fill=RIPPLE_COLOR, width=3)

def build_horizontal() -> Image.Image:
    img = _new()
    draw = ImageDraw.Draw(img, "RGBA")
    
    y0, y1 = 8, 31
    # 1. Scalloped border bubbles
    draw_scalloped_border(draw, 0, y0, 39, y1, 'h')
    
    # 2. Main outline rectangle
    draw.rectangle((0, y0, 39, y1), fill=OUTLINE_COLOR)
    
    # 3. Inner core
    draw.rectangle((0, y0+2, 39, y1-2), fill=CORE_COLOR)
    
    # 4. Ripples
    draw_ripples(draw, 0, y0, 39, y1, 'h')
    
    # 5. Highlights on the scallops
    draw_scallop_highlights(draw, 0, y0, 39, y1, 'h')
    
    # Add a central bright white glow line
    draw.line((0, 19, 39, 19), fill=(255,255,255,180), width=2)
    return img

def build_vertical() -> Image.Image:
    img = _new()
    draw = ImageDraw.Draw(img, "RGBA")
    
    x0, x1 = 8, 31
    draw_scalloped_border(draw, x0, 0, x1, 39, 'v')
    draw.rectangle((x0, 0, x1, 39), fill=OUTLINE_COLOR)
    draw.rectangle((x0+2, 0, x1-2, 39), fill=CORE_COLOR)
    draw_ripples(draw, x0, 0, x1, 39, 'v')
    draw_scallop_highlights(draw, x0, 0, x1, 39, 'v')
    draw.line((19, 0, 19, 39), fill=(255,255,255,180), width=2)
    return img

def build_center() -> Image.Image:
    img = _new()
    draw = ImageDraw.Draw(img, "RGBA")
    
    c0, c1 = 8, 31
    
    # We want a seamless intersection.
    # Scalloped corners
    spacing = 8
    radius = 3
    
    # Draw a cross shape outline
    # Horizontal part
    draw.rectangle((0, c0, 39, c1), fill=OUTLINE_COLOR)
    # Vertical part
    draw.rectangle((c0, 0, c1, 39), fill=OUTLINE_COLOR)
    
    # Inner core
    draw.rectangle((0, c0+2, 39, c1-2), fill=CORE_COLOR)
    draw.rectangle((c0+2, 0, c1-2, 39), fill=CORE_COLOR)
    
    # The center intersection usually has some white splash or just a bright core
    draw.ellipse((c0+2, c0+2, c1-2, c1-2), fill=HIGHLIGHT)
    draw.ellipse((c0+6, c0+6, c1-6, c1-6), fill=CORE_COLOR)
    
    # Central bright lines
    draw.line((0, 19, 39, 19), fill=(255,255,255,180), width=2)
    draw.line((19, 0, 19, 39), fill=(255,255,255,180), width=2)
    
    # Draw scallops only on the non-intersecting edges
    # Horizontal arms
    for x in range(0, c0, spacing):
        draw.ellipse((x - radius, c0 - radius, x + radius, c0 + radius), fill=OUTLINE_COLOR)
        draw.ellipse((x - radius, c1 - radius, x + radius, c1 + radius), fill=OUTLINE_COLOR)
    for x in range(c1+1, 40, spacing):
        draw.ellipse((x - radius, c0 - radius, x + radius, c0 + radius), fill=OUTLINE_COLOR)
        draw.ellipse((x - radius, c1 - radius, x + radius, c1 + radius), fill=OUTLINE_COLOR)
        
    # Vertical arms
    for y in range(0, c0, spacing):
        draw.ellipse((c0 - radius, y - radius, c0 + radius, y + radius), fill=OUTLINE_COLOR)
        draw.ellipse((c1 - radius, y - radius, c1 + radius, y + radius), fill=OUTLINE_COLOR)
    for y in range(c1+1, 40, spacing):
        draw.ellipse((c0 - radius, y - radius, c0 + radius, y + radius), fill=OUTLINE_COLOR)
        draw.ellipse((c1 - radius, y - radius, c1 + radius, y + radius), fill=OUTLINE_COLOR)

    # Scallop highlights
    hradius = 1.5
    for x in range(0, c0, spacing):
        draw.ellipse((x - hradius, c0 - hradius, x + hradius, c0 + hradius), fill=HIGHLIGHT)
        draw.ellipse((x - hradius, c1 - hradius, x + hradius, c1 + hradius), fill=HIGHLIGHT)
    for x in range(c1+1, 40, spacing):
        draw.ellipse((x - hradius, c0 - hradius, x + hradius, c0 + hradius), fill=HIGHLIGHT)
        draw.ellipse((x - hradius, c1 - hradius, x + hradius, c1 + hradius), fill=HIGHLIGHT)
    for y in range(0, c0, spacing):
        draw.ellipse((c0 - hradius, y - hradius, c0 + hradius, y + hradius), fill=HIGHLIGHT)
        draw.ellipse((c1 - hradius, y - hradius, c1 + hradius, y + hradius), fill=HIGHLIGHT)
    for y in range(c1+1, 40, spacing):
        draw.ellipse((c0 - hradius, y - hradius, c0 + hradius, y + hradius), fill=HIGHLIGHT)
        draw.ellipse((c1 - hradius, y - hradius, c1 + hradius, y + hradius), fill=HIGHLIGHT)

    return img

def build_end(direction: str) -> Image.Image:
    img = _new()
    draw = ImageDraw.Draw(img, "RGBA")
    
    c0, c1 = 8, 31
    spacing = 8
    radius = 3
    hradius = 1.5
    
    if direction == "left":
        draw.rectangle((20, c0, 39, c1), fill=OUTLINE_COLOR)
        # Rounded tip
        draw.ellipse((4, c0, 20 + (c1-c0)//2, c1), fill=OUTLINE_COLOR)
        draw.rectangle((20, c0+2, 39, c1-2), fill=CORE_COLOR)
        draw.ellipse((6, c0+2, 20 + (c1-c0)//2 - 2, c1-2), fill=CORE_COLOR)
        draw_ripples(draw, 20, c0, 39, c1, 'h')
        draw.line((8, 19, 39, 19), fill=(255,255,255,180), width=2)
        
        # Scallops
        for x in range(20, 40, spacing):
            draw.ellipse((x - radius, c0 - radius, x + radius, c0 + radius), fill=OUTLINE_COLOR)
            draw.ellipse((x - radius, c1 - radius, x + radius, c1 + radius), fill=OUTLINE_COLOR)
            draw.ellipse((x - hradius, c0 - hradius, x + hradius, c0 + hradius), fill=HIGHLIGHT)
            draw.ellipse((x - hradius, c1 - hradius, x + hradius, c1 + hradius), fill=HIGHLIGHT)
            
        # Tip scallops
        draw.ellipse((4 - radius, 19 - radius, 4 + radius, 19 + radius), fill=OUTLINE_COLOR)
        draw.ellipse((4 - hradius, 19 - hradius, 4 + hradius, 19 + hradius), fill=HIGHLIGHT)
            
    elif direction == "right":
        draw.rectangle((0, c0, 20, c1), fill=OUTLINE_COLOR)
        draw.ellipse((20 - (c1-c0)//2, c0, 35, c1), fill=OUTLINE_COLOR)
        draw.rectangle((0, c0+2, 20, c1-2), fill=CORE_COLOR)
        draw.ellipse((20 - (c1-c0)//2 + 2, c0+2, 33, c1-2), fill=CORE_COLOR)
        draw_ripples(draw, 0, c0, 20, c1, 'h')
        draw.line((0, 19, 31, 19), fill=(255,255,255,180), width=2)
        
        for x in range(0, 20, spacing):
            draw.ellipse((x - radius, c0 - radius, x + radius, c0 + radius), fill=OUTLINE_COLOR)
            draw.ellipse((x - radius, c1 - radius, x + radius, c1 + radius), fill=OUTLINE_COLOR)
            draw.ellipse((x - hradius, c0 - hradius, x + hradius, c0 + hradius), fill=HIGHLIGHT)
            draw.ellipse((x - hradius, c1 - hradius, x + hradius, c1 + hradius), fill=HIGHLIGHT)
            
        draw.ellipse((35 - radius, 19 - radius, 35 + radius, 19 + radius), fill=OUTLINE_COLOR)
        draw.ellipse((35 - hradius, 19 - hradius, 35 + hradius, 19 + hradius), fill=HIGHLIGHT)

    elif direction == "up":
        draw.rectangle((c0, 20, c1, 39), fill=OUTLINE_COLOR)
        draw.ellipse((c0, 4, c1, 20 + (c1-c0)//2), fill=OUTLINE_COLOR)
        draw.rectangle((c0+2, 20, c1-2, 39), fill=CORE_COLOR)
        draw.ellipse((c0+2, 6, c1-2, 20 + (c1-c0)//2 - 2), fill=CORE_COLOR)
        draw_ripples(draw, c0, 20, c1, 39, 'v')
        draw.line((19, 8, 19, 39), fill=(255,255,255,180), width=2)
        
        for y in range(20, 40, spacing):
            draw.ellipse((c0 - radius, y - radius, c0 + radius, y + radius), fill=OUTLINE_COLOR)
            draw.ellipse((c1 - radius, y - radius, c1 + radius, y + radius), fill=OUTLINE_COLOR)
            draw.ellipse((c0 - hradius, y - hradius, c0 + hradius, y + hradius), fill=HIGHLIGHT)
            draw.ellipse((c1 - hradius, y - hradius, c1 + hradius, y + hradius), fill=HIGHLIGHT)
            
        draw.ellipse((19 - radius, 4 - radius, 19 + radius, 4 + radius), fill=OUTLINE_COLOR)
        draw.ellipse((19 - hradius, 4 - hradius, 19 + hradius, 4 + hradius), fill=HIGHLIGHT)

    elif direction == "down":
        draw.rectangle((c0, 0, c1, 20), fill=OUTLINE_COLOR)
        draw.ellipse((c0, 20 - (c1-c0)//2, c1, 35), fill=OUTLINE_COLOR)
        draw.rectangle((c0+2, 0, c1-2, 20), fill=CORE_COLOR)
        draw.ellipse((c0+2, 20 - (c1-c0)//2 + 2, c1-2, 33), fill=CORE_COLOR)
        draw_ripples(draw, c0, 0, c1, 20, 'v')
        draw.line((19, 0, 19, 31), fill=(255,255,255,180), width=2)
        
        for y in range(0, 20, spacing):
            draw.ellipse((c0 - radius, y - radius, c0 + radius, y + radius), fill=OUTLINE_COLOR)
            draw.ellipse((c1 - radius, y - radius, c1 + radius, y + radius), fill=OUTLINE_COLOR)
            draw.ellipse((c0 - hradius, y - hradius, c0 + hradius, y + hradius), fill=HIGHLIGHT)
            draw.ellipse((c1 - hradius, y - hradius, c1 + hradius, y + hradius), fill=HIGHLIGHT)
            
        draw.ellipse((19 - radius, 35 - radius, 19 + radius, 35 + radius), fill=OUTLINE_COLOR)
        draw.ellipse((19 - hradius, 35 - hradius, 19 + hradius, 35 + hradius), fill=HIGHLIGHT)

    return img

def build_all():
    import os
    os.makedirs(OUT, exist_ok=True)
    
    build_center().save(OUT / "water_center.png")
    build_center().save(OUT / "water_cross.png")
    build_horizontal().save(OUT / "water_horizontal.png")
    build_vertical().save(OUT / "water_vertical.png")
    
    build_end("left").save(OUT / "water_end_left.png")
    build_end("right").save(OUT / "water_end_right.png")
    build_end("up").save(OUT / "water_end_up.png")
    build_end("down").save(OUT / "water_end_down.png")
    print("Done building procedural authentic water burst!")

if __name__ == "__main__":
    build_all()
