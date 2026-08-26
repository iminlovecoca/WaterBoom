#!/usr/bin/env python3
"""
Shared VFX Assets Generator
Creates water burst VFX, particles, and shadow assets.
"""
import math
import os
from PIL import Image, ImageDraw

OUTPUT_VFX = os.path.join(os.path.dirname(__file__), "..", "assets", "water_balloons", "vfx")
OUTPUT_PARTICLES = os.path.join(os.path.dirname(__file__), "..", "assets", "water_balloons", "particles")
OUTPUT_COMMON = os.path.join(os.path.dirname(__file__), "..", "assets", "water_balloons", "common")
SIZE = 64

def create_dirs():
    for d in [OUTPUT_VFX, OUTPUT_PARTICLES, OUTPUT_COMMON]:
        os.makedirs(d, exist_ok=True)

def generate_droplet(size, color=(100, 200, 255)):
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    cx, cy = size // 2, size // 2
    r = size // 3
    draw.ellipse([cx - r, cy - r * 2, cx + r, cy], fill=(*color, 200))
    draw.ellipse([cx - r + 1, cy - r * 2 + 1, cx + r - 1, cy - 1], fill=(*color, 180))
    draw.ellipse([cx - r // 2, cy - r, cx, cy - r // 2], fill=(255, 255, 255, 150))
    return img

def generate_bubble(size, color=(180, 230, 255)):
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    cx, cy = size // 2, size // 2
    r = size // 3
    draw.ellipse([cx - r, cy - r, cx + r, cy + r], outline=(*color, 180), width=2)
    draw.ellipse([cx - r // 2, cy - r, cx, cy - r // 2], fill=(255, 255, 255, 120))
    return img

def generate_foam(size):
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    for _ in range(5):
        bx = size // 2 + (size // 4)
        by = size // 2
        br = size // 8
        draw.ellipse([bx - br, by - br, bx + br, by + br], fill=(255, 255, 255, 100))
    return img

def generate_ripple(size, color=(100, 200, 255)):
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    cx, cy = size // 2, size // 2
    for r in range(5, size // 2, 4):
        alpha = max(0, 180 - r * 4)
        draw.ellipse([cx - r, cy - r // 2, cx + r, cy + r // 2], outline=(*color, alpha), width=1)
    return img

def generate_sparkle(size, color=(255, 255, 255)):
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    cx, cy = size // 2, size // 2
    arm = size // 3
    draw.line([(cx - arm, cy), (cx + arm, cy)], fill=(*color, 220), width=2)
    draw.line([(cx, cy - arm), (cx, cy + arm)], fill=(*color, 220), width=2)
    draw.line([(cx - arm // 2, cy - arm // 2), (cx + arm // 2, cy + arm // 2)], fill=(*color, 160), width=1)
    draw.line([(cx - arm // 2, cy + arm // 2), (cx + arm // 2, cy - arm // 2)], fill=(*color, 160), width=1)
    return img

def generate_heart_particle(size, color=(255, 120, 180)):
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    cx, cy = size // 2, size // 2
    r = size // 4
    draw.ellipse([cx - r, cy - r, cx, cy], fill=(*color, 200))
    draw.ellipse([cx, cy - r, cx + r, cy], fill=(*color, 200))
    draw.polygon([(cx - r, cy - r // 2), (cx, cy + r), (cx + r, cy - r // 2)], fill=(*color, 200))
    return img

def generate_snowflake(size, color=(200, 230, 255)):
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    cx, cy = size // 2, size // 2
    arm = size // 3
    for angle_deg in range(0, 360, 60):
        angle = math.radians(angle_deg)
        ex = cx + int(math.cos(angle) * arm)
        ey = cy + int(math.sin(angle) * arm)
        draw.line([(cx, cy), (ex, ey)], fill=(*color, 200), width=1)
    return img

def generate_shadow(size, shadow_type="normal"):
    img = Image.new('RGBA', (size, int(size * 0.4)), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    cx = size // 2
    cy = int(size * 0.35)
    
    if shadow_type == "small":
        rw, rh = size // 4, size // 8
    elif shadow_type == "squash":
        rw, rh = size // 3, size // 10
    else:
        rw, rh = size // 3, size // 7
    
    for i in range(3):
        alpha = max(0, 80 - i * 20)
        draw.ellipse(
            [cx - rw - i, cy - rh - i, cx + rw + i, cy + rh + i],
            fill=(20, 30, 80, alpha)
        )
    draw.ellipse([cx - rw, cy - rh, cx + rw, cy + rh], fill=(20, 30, 80, 60))
    return img

def generate_all():
    create_dirs()
    
    for size_name, size in [("small", 16), ("medium", 24), ("large", 32)]:
        droplet = generate_droplet(size)
        droplet.save(os.path.join(OUTPUT_PARTICLES, f"droplet_{size_name}.png"))
        
        bubble = generate_bubble(size)
        bubble.save(os.path.join(OUTPUT_PARTICLES, f"bubble_{size_name}.png"))
        
        foam = generate_foam(size)
        foam.save(os.path.join(OUTPUT_PARTICLES, f"foam_{size_name}.png"))
    
    for size_name, size in [("small", 24), ("medium", 32), ("large", 48)]:
        ripple = generate_ripple(size)
        ripple.save(os.path.join(OUTPUT_PARTICLES, f"ripple_{size_name}.png"))
    
    for color_name, color in [("white", (255, 255, 255)), ("blue", (100, 180, 255)), ("gold", (255, 220, 80))]:
        sparkle = generate_sparkle(24, color)
        sparkle.save(os.path.join(OUTPUT_PARTICLES, f"sparkle_{color_name}.png"))
    
    rainbow_sparkle = generate_sparkle(24, (255, 180, 255))
    rainbow_sparkle.save(os.path.join(OUTPUT_PARTICLES, "sparkle_rainbow.png"))
    
    heart = generate_heart_particle(20)
    heart.save(os.path.join(OUTPUT_PARTICLES, "heart_particle.png"))
    
    snowflake = generate_snowflake(20)
    snowflake.save(os.path.join(OUTPUT_PARTICLES, "snowflake_particle.png"))
    
    dark = generate_sparkle(20, (80, 60, 120))
    dark.save(os.path.join(OUTPUT_PARTICLES, "dark_particle.png"))
    
    star = generate_sparkle(20, (255, 230, 100))
    star.save(os.path.join(OUTPUT_PARTICLES, "star_particle.png"))
    
    for shadow_type in ["small", "normal", "squash"]:
        shadow = generate_shadow(64, shadow_type)
        shadow.save(os.path.join(OUTPUT_COMMON, f"shadow_{shadow_type}.png"))
    
    print("Generated VFX, particles, and shadows.")

if __name__ == "__main__":
    generate_all()
