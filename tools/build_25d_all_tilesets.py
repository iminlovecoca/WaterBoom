import os
from PIL import Image, ImageDraw

ROOT = r'c:\Users\khang\Documents\Build\Boom'
THEMES = [
    "training_plaza",
    "aqua_park",
    "pirate_harbor",
    "snow_village",
    "neon_arcade",
    "lego_city",
    "ice_labyrinth",
    "egypt_temple",
]

def make_25d_block(top_color, top_highlight, front_color, front_shadow, border_color, emblem_type="none", extra_data=None):
    """
    Creates an authentic 2.5D perspective block (40x40):
    - Top face (y=0..27): Brightly lit, perspective roof.
    - Front face (y=28..39): 12px 3D extrusion facing camera with depth shading.
    - Seamless horizontal tiling across x=0..39.
    """
    img = Image.new('RGBA', (40, 40), (0, 0, 0, 255))
    draw = ImageDraw.Draw(img)
    
    # 1. Top face (y=0..27)
    draw.rectangle([0, 0, 39, 27], fill=top_color)
    # Top rim highlight
    draw.line([(0, 0), (39, 0)], fill=top_highlight, width=2)
    draw.line([(0, 0), (0, 27)], fill=top_highlight, width=1)
    
    # 2. Front face (y=28..39)
    draw.rectangle([0, 28, 39, 39], fill=front_color)
    # Front bottom drop shadow
    draw.line([(0, 38), (39, 38)], fill=front_shadow, width=2)
    # Crease line between top face and front face
    draw.line([(0, 27), (39, 27)], fill=front_shadow, width=2)
    draw.line([(0, 28), (39, 28)], fill=top_highlight, width=1)
    
    # 3. Outer border outline
    draw.rectangle([0, 0, 39, 39], outline=border_color, width=1)
    
    # 4. 2.5D Emblems & Textures
    if emblem_type == "brick_wall":
        # 2.5D Brick pattern on top and front
        draw.line([(0, 9), (39, 9)], fill=front_shadow, width=1)
        draw.line([(0, 18), (39, 18)], fill=front_shadow, width=1)
        draw.line([(20, 0), (20, 9)], fill=front_shadow, width=1)
        draw.line([(10, 9), (10, 18)], fill=front_shadow, width=1)
        draw.line([(30, 9), (30, 18)], fill=front_shadow, width=1)
        draw.line([(20, 18), (20, 27)], fill=front_shadow, width=1)
        # Front brick columns
        draw.line([(10, 28), (10, 39)], fill=front_shadow, width=1)
        draw.line([(30, 28), (30, 39)], fill=front_shadow, width=1)

    elif emblem_type == "wooden_crate":
        # Top face: Wooden cross brace 'X'
        draw.rectangle([3, 3, 36, 24], outline=border_color, width=2)
        draw.line([(3, 3), (36, 24)], fill=front_shadow, width=2)
        draw.line([(36, 3), (3, 24)], fill=front_shadow, width=2)
        draw.line([(3, 3), (36, 24)], fill=top_highlight, width=1)
        draw.line([(36, 3), (3, 24)], fill=top_highlight, width=1)
        # Front face: Vertical wood plank lines & iron studs
        draw.line([(13, 28), (13, 39)], fill=front_shadow, width=1)
        draw.line([(26, 28), (26, 39)], fill=front_shadow, width=1)
        draw.rectangle([4, 30, 7, 33], fill=(255, 230, 120, 255), outline=border_color)
        draw.rectangle([32, 30, 35, 33], fill=(255, 230, 120, 255), outline=border_color)

    elif emblem_type == "lego_studs":
        # 4 Circular 2.5D raised studs on top face
        studs = [(10, 7), (29, 7), (10, 20), (29, 20)]
        for sx, sy in studs:
            # Stud shadow
            draw.ellipse([sx - 6, sy - 4, sx + 6, sy + 6], fill=front_shadow)
            # Stud cylinder side
            draw.ellipse([sx - 6, sy - 4, sx + 6, sy + 4], fill=front_color)
            # Stud top disc
            draw.ellipse([sx - 6, sy - 6, sx + 6, sy + 2], fill=top_highlight, outline=border_color)
            draw.ellipse([sx - 4, sy - 5, sx + 4, sy + 1], fill=top_color)
        # Front lego rim
        draw.line([(0, 33), (39, 33)], fill=front_shadow, width=1)

    elif emblem_type == "lego_crate":
        # Top face yellow crate lid with 'Z' brace
        draw.rectangle([3, 3, 36, 24], outline=border_color, width=2)
        draw.line([(5, 5), (34, 22)], fill=front_shadow, width=3)
        draw.line([(5, 5), (34, 22)], fill=top_highlight, width=1)
        # Front face yellow planks
        draw.line([(13, 28), (13, 39)], fill=front_shadow, width=2)
        draw.line([(26, 28), (26, 39)], fill=front_shadow, width=2)

    elif emblem_type == "ice_glacier":
        # 2.5D Faceted crystal shards on top
        draw.polygon([(20, 3), (34, 13), (20, 24), (6, 13)], fill=top_highlight)
        draw.polygon([(20, 6), (30, 13), (20, 21), (10, 13)], fill=top_color)
        # Crystal fracture lines on front
        draw.line([(8, 28), (14, 38)], fill=top_highlight, width=2)
        draw.line([(24, 28), (32, 38)], fill=top_highlight, width=2)

    elif emblem_type == "ice_cube":
        # Glowing translucent ice cube with frost rim
        draw.rectangle([3, 3, 36, 24], outline=(230, 255, 255, 255), width=2)
        draw.line([(6, 8), (18, 16), (12, 22)], fill=(255, 255, 255, 255), width=2)
        draw.line([(32, 6), (22, 14), (28, 22)], fill=(255, 255, 255, 255), width=2)
        # Front frost drips
        draw.rectangle([4, 28, 12, 34], fill=(220, 250, 255, 255))
        draw.rectangle([20, 28, 28, 36], fill=(220, 250, 255, 255))

    elif emblem_type == "pharaoh_pillar":
        # Royal Egyptian Gold Ankh on top
        draw.polygon([(20, 4), (32, 13), (20, 23), (8, 13)], fill=(255, 215, 60, 255), outline=border_color)
        draw.rectangle([17, 7, 23, 20], fill=(255, 240, 120, 255))
        # Front gold hieroglyph band
        draw.rectangle([0, 30, 39, 36], fill=(215, 170, 40, 255), outline=border_color)
        draw.line([(10, 30), (10, 36)], fill=(50, 30, 10, 255), width=1)
        draw.line([(20, 30), (20, 36)], fill=(50, 30, 10, 255), width=1)
        draw.line([(30, 30), (30, 36)], fill=(50, 30, 10, 255), width=1)

    elif emblem_type == "cyber_matrix":
        # Neon cyber grid on top
        draw.rectangle([4, 4, 35, 23], outline=top_highlight, width=2)
        draw.rectangle([10, 8, 29, 19], fill=front_color, outline=top_highlight)
        # Front server vent glow
        for vy in [30, 33, 36]:
            draw.line([(6, vy), (33, vy)], fill=top_highlight, width=1)

    return img

def build_all():
    # 1. Training Plaza
    tp_dir = os.path.join(ROOT, 'assets', 'tilesets', 'training_plaza', 'runtime')
    os.makedirs(tp_dir, exist_ok=True)
    tp_hard = make_25d_block((215, 80, 55), (255, 140, 110), (145, 45, 30), (85, 20, 12), (70, 15, 10), "brick_wall")
    tp_soft = make_25d_block((235, 175, 75), (255, 225, 140), (175, 115, 40), (105, 65, 18), (80, 45, 10), "wooden_crate")
    tp_hard.save(os.path.join(tp_dir, 'hard_block.png'))
    tp_soft.save(os.path.join(tp_dir, 'soft_block.png'))
    tp_hard.save(os.path.join(ROOT, 'assets', 'maps', 'tile_wall.png'))
    tp_soft.save(os.path.join(ROOT, 'assets', 'maps', 'tile_destructible.png'))

    # 2. Aqua Park
    aq_dir = os.path.join(ROOT, 'assets', 'tilesets', 'aqua_park', 'runtime')
    os.makedirs(aq_dir, exist_ok=True)
    aq_hard = make_25d_block((35, 160, 230), (120, 220, 255), (18, 100, 165), (10, 55, 100), (8, 40, 75), "brick_wall")
    aq_soft = make_25d_block((255, 195, 60), (255, 235, 130), (200, 135, 30), (130, 75, 15), (95, 50, 10), "wooden_crate")
    aq_hard.save(os.path.join(aq_dir, 'hard_block.png'))
    aq_soft.save(os.path.join(aq_dir, 'soft_block.png'))

    # 3. Pirate Harbor
    pi_dir = os.path.join(ROOT, 'assets', 'tilesets', 'pirate_harbor', 'runtime')
    os.makedirs(pi_dir, exist_ok=True)
    pi_hard = make_25d_block((110, 85, 70), (165, 135, 115), (70, 50, 40), (35, 22, 16), (25, 15, 10), "brick_wall")
    pi_soft = make_25d_block((195, 125, 60), (245, 185, 110), (135, 80, 32), (75, 40, 14), (55, 25, 10), "wooden_crate")
    pi_hard.save(os.path.join(pi_dir, 'hard_block.png'))
    pi_soft.save(os.path.join(pi_dir, 'soft_block.png'))

    # 4. Snow Village
    sn_dir = os.path.join(ROOT, 'assets', 'tilesets', 'snow_village', 'runtime')
    os.makedirs(sn_dir, exist_ok=True)
    sn_hard = make_25d_block((210, 235, 250), (255, 255, 255), (130, 170, 205), (75, 105, 140), (50, 75, 105), "brick_wall")
    sn_soft = make_25d_block((205, 155, 95), (250, 210, 155), (145, 100, 52), (85, 52, 22), (60, 35, 15), "wooden_crate")
    sn_hard.save(os.path.join(sn_dir, 'hard_block.png'))
    sn_soft.save(os.path.join(sn_dir, 'soft_block.png'))

    # 5. Neon Arcade
    ne_dir = os.path.join(ROOT, 'assets', 'tilesets', 'neon_arcade', 'runtime')
    os.makedirs(ne_dir, exist_ok=True)
    ne_hard = make_25d_block((45, 30, 85), (160, 100, 255), (25, 15, 55), (12, 6, 30), (180, 70, 255), "cyber_matrix")
    ne_soft = make_25d_block((20, 150, 190), (100, 240, 255), (10, 95, 130), (5, 50, 75), (50, 220, 255), "cyber_matrix")
    ne_hard.save(os.path.join(ne_dir, 'hard_block.png'))
    ne_soft.save(os.path.join(ne_dir, 'soft_block.png'))

    # 6. Lego City
    le_dir = os.path.join(ROOT, 'assets', 'tilesets', 'lego_city', 'runtime')
    os.makedirs(le_dir, exist_ok=True)
    le_hard = make_25d_block((235, 55, 45), (255, 130, 115), (170, 28, 22), (100, 12, 10), (75, 8, 6), "lego_studs")
    le_soft = make_25d_block((255, 205, 45), (255, 240, 125), (200, 145, 20), (130, 85, 8), (95, 60, 5), "lego_crate")
    le_hard.save(os.path.join(le_dir, 'hard_block.png'))
    le_soft.save(os.path.join(le_dir, 'soft_block.png'))

    # 7. Ice Labyrinth
    ic_dir = os.path.join(ROOT, 'assets', 'tilesets', 'ice_labyrinth', 'runtime')
    os.makedirs(ic_dir, exist_ok=True)
    ic_hard = make_25d_block((35, 95, 175), (125, 215, 255), (18, 55, 115), (8, 28, 68), (6, 20, 50), "ice_glacier")
    ic_soft = make_25d_block((120, 225, 255), (230, 255, 255), (60, 165, 215), (28, 95, 140), (18, 65, 100), "ice_cube")
    ic_hard.save(os.path.join(ic_dir, 'hard_block.png'))
    ic_soft.save(os.path.join(ic_dir, 'soft_block.png'))

    # 8. Egypt Temple
    eg_dir = os.path.join(ROOT, 'assets', 'tilesets', 'egypt_temple', 'runtime')
    os.makedirs(eg_dir, exist_ok=True)
    eg_hard = make_25d_block((38, 48, 75), (110, 135, 185), (20, 28, 48), (10, 14, 28), (255, 210, 50), "pharaoh_pillar")
    eg_soft = make_25d_block((210, 125, 50), (255, 190, 110), (145, 75, 25), (85, 38, 10), (60, 25, 6), "wooden_crate")
    eg_hard.save(os.path.join(eg_dir, 'hard_block.png'))
    eg_soft.save(os.path.join(eg_dir, 'soft_block.png'))

    print("Successfully built all 8 tilesets in authentic 2.5D perspective!")

build_all()
