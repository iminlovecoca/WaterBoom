#!/usr/bin/env python3
"""
Generate per-skin VFX textures:
1. pop_burst.png — water splash on balloon pop (colored to match skin)
2. idle_glow.png — subtle glow behind balloon in idle
"""
from PIL import Image, ImageDraw, ImageFilter
import numpy as np
import os

BALLOON_DIR = 'C:/Users/khang/Documents/Build/Boom/assets/water_balloons/balloon_sprites'
OUT_DIR = 'C:/Users/khang/Documents/Build/Boom/assets/water_balloons/skins'
VFX_SIZE = 128

def get_dominant_color(img_arr):
    """Get dominant non-transparent color from balloon sprite."""
    mask = img_arr[:,:,3] > 100
    if mask.sum() == 0:
        return (100, 180, 255)
    pixels = img_arr[:,:,:3][mask]
    # Get average of brightest 30% of pixels
    brightness = pixels.sum(axis=1)
    threshold = np.percentile(brightness, 70)
    bright_pixels = pixels[brightness >= threshold]
    if len(bright_pixels) == 0:
        bright_pixels = pixels
    r = int(np.mean(bright_pixels[:,0]))
    g = int(np.mean(bright_pixels[:,1]))
    b = int(np.mean(bright_pixels[:,2]))
    return (r, g, b)

def create_pop_burst(color, size=128):
    """Create water splash pop burst texture."""
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img, 'RGBA')
    cx, cy = size // 2, size // 2

    r, g, b = color

    # Central splash droplets
    for angle_deg in range(0, 360, 30):
        angle = np.radians(angle_deg + np.random.uniform(-10, 10))
        dist = np.random.uniform(20, 45)
        droplet_x = cx + np.cos(angle) * dist
        droplet_y = cy + np.sin(angle) * dist
        droplet_r = np.random.uniform(4, 10)
        
        # Gradient droplet
        for i in range(int(droplet_r), 0, -1):
            alpha = int(200 * (1 - i / droplet_r))
            draw.ellipse([droplet_x - i, droplet_y - i, droplet_x + i, droplet_y + i],
                        fill=(r, g, b, alpha))

    # Water splash ring
    for i in range(3):
        ring_r = 30 + i * 12
        alpha = int(150 - i * 40)
        draw.ellipse([cx - ring_r, cy - ring_r, cx + ring_r, cy + ring_r],
                     outline=(r, g, b, alpha), width=3)

    # Sparkle highlights
    for _ in range(6):
        sx = np.random.randint(15, size - 15)
        sy = np.random.randint(15, size - 15)
        sr = np.random.uniform(2, 4)
        draw.ellipse([sx - sr, sy - sr, sx + sr, sy + sr],
                     fill=(255, 255, 255, 200))

    # Apply slight blur for glow
    img = img.filter(ImageFilter.GaussianBlur(radius=1.5))
    return img

def create_idle_glow(color, size=128):
    """Create subtle glow texture behind balloon."""
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img, 'RGBA')
    cx, cy = size // 2, size // 2
    r, g, b = color

    # Soft radial glow
    for radius in range(55, 10, -1):
        alpha = int(30 * (1 - radius / 55))
        draw.ellipse([cx - radius, cy - radius, cx + radius, cy + radius],
                     fill=(r, g, b, alpha))

    img = img.filter(ImageFilter.GaussianBlur(radius=4))
    return img

# Process each balloon
count = 0
for i in range(64):
    balloon_path = os.path.join(BALLOON_DIR, f'balloon_{i:03d}.png')
    if not os.path.exists(balloon_path):
        continue
    
    skin_id = f'skin_{i+1:03d}'
    skin_dir = os.path.join(OUT_DIR, skin_id)
    if not os.path.isdir(skin_dir):
        continue

    balloon = Image.open(balloon_path)
    color = get_dominant_color(np.array(balloon))

    # Pop burst
    pop = create_pop_burst(color)
    pop.save(os.path.join(skin_dir, 'pop_burst.png'))

    # Idle glow
    glow = create_idle_glow(color)
    glow.save(os.path.join(skin_dir, 'idle_glow.png'))

    count += 1

print(f'Generated VFX for {count} skins')
