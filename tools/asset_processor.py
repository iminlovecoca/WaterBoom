import os
from PIL import Image, ImageDraw

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ASSETS_DIR = os.path.join(BASE_DIR, "assets")

def ensure_dir(path):
    os.makedirs(path, exist_ok=True)

def create_pixel_character():
    char_dir = os.path.join(ASSETS_DIR, "characters", "bazzi")
    ensure_dir(char_dir)
    
    # 32x32 pixel art character frames
    # Palette: Blue suit (#2563eb, #1d4ed8), Skin (#fed7aa), Eyes (#1e293b), Cap/Cheeks (#ef4444)
    def draw_base_body(d, offset_x=0, offset_y=0, dir_face="down"):
        ox, oy = offset_x + 16, offset_y + 16
        # Head (circle-like pixel cluster)
        for dx in range(-8, 9):
            for dy in range(-8, 7):
                if dx*dx + dy*dy <= 64:
                    # Blue helmet
                    d.point((ox + dx, oy + dy - 2), fill=(37, 99, 235, 255))
        # Face skin
        if dir_face == "down":
            for dx in range(-5, 6):
                for dy in range(-3, 4):
                    d.point((ox + dx, oy + dy - 1), fill=(254, 215, 170, 255))
            # Eyes
            d.point((ox - 3, oy - 1), fill=(30, 41, 59, 255))
            d.point((ox - 3, oy), fill=(30, 41, 59, 255))
            d.point((ox + 3, oy - 1), fill=(30, 41, 59, 255))
            d.point((ox + 3, oy), fill=(30, 41, 59, 255))
            # Cheeks
            d.point((ox - 4, oy + 2), fill=(248, 113, 113, 255))
            d.point((ox + 4, oy + 2), fill=(248, 113, 113, 255))
        elif dir_face == "left":
            for dx in range(-7, 2):
                for dy in range(-3, 4):
                    d.point((ox + dx, oy + dy - 1), fill=(254, 215, 170, 255))
            d.point((ox - 4, oy - 1), fill=(30, 41, 59, 255))
            d.point((ox - 4, oy), fill=(30, 41, 59, 255))
            d.point((ox - 6, oy + 2), fill=(248, 113, 113, 255))
        elif dir_face == "right":
            for dx in range(-2, 8):
                for dy in range(-3, 4):
                    d.point((ox + dx, oy + dy - 1), fill=(254, 215, 170, 255))
            d.point((ox + 4, oy - 1), fill=(30, 41, 59, 255))
            d.point((ox + 4, oy), fill=(30, 41, 59, 255))
            d.point((ox + 6, oy + 2), fill=(248, 113, 113, 255))
        elif dir_face == "up":
            # Back of blue helmet, small antenna/top knot
            for dx in range(-2, 3):
                d.point((ox + dx, oy - 10), fill=(29, 78, 216, 255))

    # Animations & Frames
    animations = {
        "idle": 1,
        "walk_down": 4,
        "walk_up": 4,
        "walk_left": 4,
        "walk_right": 4,
        "plant": 2,
        "hurt": 2,
        "die": 4
    }

    for anim_name, frame_count in animations.items():
        for frame in range(frame_count):
            img = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
            d = ImageDraw.Draw(img)
            
            bounce = 1 if (frame % 2 == 1) else 0
            dir_name = "down"
            if "up" in anim_name: dir_name = "up"
            elif "left" in anim_name: dir_name = "left"
            elif "right" in anim_name: dir_name = "right"
            
            if anim_name == "die":
                # Spinning / fading
                angle = frame * 90
                draw_base_body(d, 0, 0, "down")
                img = img.rotate(angle)
            else:
                draw_base_body(d, 0, -bounce, dir_name)
                # Feet
                if anim_name.startswith("walk"):
                    leg_shift = 2 if (frame == 1) else (-2 if frame == 3 else 0)
                    d.rectangle([10 + leg_shift, 26 - bounce, 14 + leg_shift, 29 - bounce], fill=(30, 64, 175, 255))
                    d.rectangle([18 - leg_shift, 26 - bounce, 22 - leg_shift, 29 - bounce], fill=(30, 64, 175, 255))
                else:
                    d.rectangle([11, 26, 14, 29], fill=(30, 64, 175, 255))
                    d.rectangle([18, 26, 21, 29], fill=(30, 64, 175, 255))

            filename = f"{anim_name}_{frame}.png" if frame_count > 1 else f"{anim_name}.png"
            img.save(os.path.join(char_dir, filename))
    print("Character frames generated.")

def create_water_balloons_and_water_bursts():
    water_balloon_dir = os.path.join(ASSETS_DIR, "water_balloons")
    exp_dir = os.path.join(ASSETS_DIR, "water_bursts")
    ensure_dir(water_balloon_dir)
    ensure_dir(exp_dir)
    
    # 1. WaterBalloon frames (pulsing sphere with shiny highlight + timer wick)
    for i in range(4):
        img = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
        d = ImageDraw.Draw(img)
        radius = 10 + (1 if i % 2 == 1 else 0)
        # WaterBalloon body (Dark metallic slate / black with cyan gloss)
        d.ellipse([16 - radius, 18 - radius, 16 + radius, 18 + radius], fill=(30, 41, 59, 255), outline=(15, 23, 42, 255))
        # Cyan shine
        d.ellipse([12 - radius//2, 14 - radius//2, 16, 18], fill=(56, 189, 248, 255))
        # Wick & Spark
        d.rectangle([15, 5, 17, 9], fill=(180, 83, 9, 255))
        spark_color = (239, 68, 68, 255) if (i % 2 == 0) else (251, 191, 36, 255)
        d.ellipse([14, 2, 18, 6], fill=spark_color)
        img.save(os.path.join(water_balloon_dir, f"water_balloon_{i}.png"))
    
    # 2. WaterBurst VFX parts (Center, Ray H, Ray V, Cap Up, Cap Down, Cap Left, Cap Right)
    parts = ["center", "ray_h", "ray_v", "cap_up", "cap_down", "cap_left", "cap_right"]
    for part in parts:
        for frame in range(4):
            img = Image.new("RGBA", (40, 40), (0, 0, 0, 0))
            d = ImageDraw.Draw(img)
            core_color = (254, 240, 138, 255) if frame < 2 else (253, 224, 71, 255)
            outer_color = (239, 68, 68, 220) if frame < 2 else (249, 115, 22, 180)
            
            if part == "center":
                d.ellipse([4, 4, 35, 35], fill=outer_color)
                d.ellipse([10, 10, 29, 29], fill=core_color)
            elif part == "ray_h":
                d.rectangle([0, 8, 39, 31], fill=outer_color)
                d.rectangle([0, 14, 39, 25], fill=core_color)
            elif part == "ray_v":
                d.rectangle([8, 0, 31, 39], fill=outer_color)
                d.rectangle([14, 0, 25, 39], fill=core_color)
            elif part == "cap_up":
                d.rectangle([8, 12, 31, 39], fill=outer_color)
                d.ellipse([8, 2, 31, 25], fill=outer_color)
                d.ellipse([14, 8, 25, 20], fill=core_color)
            elif part == "cap_down":
                d.rectangle([8, 0, 31, 27], fill=outer_color)
                d.ellipse([8, 14, 31, 37], fill=outer_color)
                d.ellipse([14, 19, 25, 31], fill=core_color)
            elif part == "cap_left":
                d.rectangle([12, 8, 39, 31], fill=outer_color)
                d.ellipse([2, 8, 25, 31], fill=outer_color)
                d.ellipse([8, 14, 20, 25], fill=core_color)
            elif part == "cap_right":
                d.rectangle([0, 8, 27, 31], fill=outer_color)
                d.ellipse([14, 8, 37, 31], fill=outer_color)
                d.ellipse([19, 14, 31, 25], fill=core_color)
            
            img.save(os.path.join(exp_dir, f"{part}_{frame}.png"))
    print("WaterBalloons & WaterBursts generated.")

def create_items_and_environment():
    item_dir = os.path.join(ASSETS_DIR, "items")
    map_dir = os.path.join(ASSETS_DIR, "maps")
    eff_dir = os.path.join(ASSETS_DIR, "effects")
    ensure_dir(item_dir)
    ensure_dir(map_dir)
    ensure_dir(eff_dir)
    
    # 1. Items (32x32)
    # WaterBalloon+
    img = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.rectangle([4, 4, 27, 27], fill=(241, 245, 249, 255), outline=(148, 163, 184, 255))
    d.ellipse([10, 12, 22, 24], fill=(30, 41, 59, 255))
    d.point((13, 15), fill=(56, 189, 248, 255))
    d.rectangle([15, 8, 17, 12], fill=(239, 68, 68, 255))
    img.save(os.path.join(item_dir, "item_water_balloon_up.png"))
    
    # Water Power+ (Potion / Water)
    img = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.rectangle([4, 4, 27, 27], fill=(241, 245, 249, 255), outline=(148, 163, 184, 255))
    d.polygon([(16, 7), (10, 24), (22, 24)], fill=(239, 68, 68, 255))
    d.polygon([(16, 13), (12, 23), (20, 23)], fill=(250, 204, 21, 255))
    img.save(os.path.join(item_dir, "item_water_power_up.png"))
    
    # Speed+ (Roller Skate)
    img = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.rectangle([4, 4, 27, 27], fill=(241, 245, 249, 255), outline=(148, 163, 184, 255))
    d.polygon([(8, 18), (14, 10), (22, 10), (24, 18)], fill=(59, 130, 246, 255))
    d.ellipse([8, 20, 13, 25], fill=(234, 88, 12, 255))
    d.ellipse([18, 20, 23, 25], fill=(234, 88, 12, 255))
    img.save(os.path.join(item_dir, "item_speed_up.png"))
    
    # Kick (Boot)
    img = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.rectangle([4, 4, 27, 27], fill=(241, 245, 249, 255), outline=(148, 163, 184, 255))
    d.polygon([(10, 8), (17, 8), (17, 18), (25, 18), (25, 24), (10, 24)], fill=(168, 85, 247, 255))
    img.save(os.path.join(item_dir, "item_kick.png"))

    # 2. Map Tiles (40x40)
    # Floor tile
    floor = Image.new("RGBA", (40, 40), (45, 150, 85, 255))
    d = ImageDraw.Draw(floor)
    d.rectangle([0, 0, 39, 39], outline=(38, 130, 72, 255))
    d.rectangle([2, 2, 37, 37], outline=(55, 170, 95, 255))
    floor.save(os.path.join(map_dir, "tile_floor.png"))
    
    # Solid Wall Block
    wall = Image.new("RGBA", (40, 40), (100, 116, 139, 255))
    d = ImageDraw.Draw(wall)
    d.rectangle([0, 0, 39, 39], fill=(71, 85, 105, 255), outline=(30, 41, 59, 255))
    d.rectangle([3, 3, 36, 18], fill=(148, 163, 184, 255))
    d.rectangle([3, 21, 36, 36], fill=(100, 116, 139, 255))
    wall.save(os.path.join(map_dir, "tile_wall.png"))
    
    # Destructible Crate / Block
    crate = Image.new("RGBA", (40, 40), (180, 83, 9, 255))
    d = ImageDraw.Draw(crate)
    d.rectangle([0, 0, 39, 39], fill=(217, 119, 6, 255), outline=(120, 53, 15, 255))
    d.rectangle([4, 4, 35, 35], outline=(251, 191, 36, 255))
    d.line([(4, 4), (35, 35)], fill=(120, 53, 15, 255), width=2)
    d.line([(4, 35), (35, 4)], fill=(120, 53, 15, 255), width=2)
    crate.save(os.path.join(map_dir, "tile_destructible.png"))

    # 3. Effects: Shadow & Bubble
    # Shadow (32x16 oval)
    shadow = Image.new("RGBA", (32, 16), (0, 0, 0, 0))
    d = ImageDraw.Draw(shadow)
    d.ellipse([2, 2, 29, 13], fill=(0, 0, 0, 110))
    shadow.save(os.path.join(eff_dir, "shadow.png"))
    
    # Bubble (40x40 glossy sphere)
    bubble = Image.new("RGBA", (40, 40), (0, 0, 0, 0))
    d = ImageDraw.Draw(bubble)
    d.ellipse([2, 2, 37, 37], fill=(56, 189, 248, 140), outline=(14, 165, 233, 220), width=2)
    d.ellipse([8, 8, 18, 16], fill=(255, 255, 255, 200))
    bubble.save(os.path.join(eff_dir, "bubble.png"))
    print("Items, tiles, and effects generated.")

if __name__ == "__main__":
    create_pixel_character()
    create_water_balloons_and_water_bursts()
    create_items_and_environment()
    print("All assets successfully processed and saved to res://assets/")
