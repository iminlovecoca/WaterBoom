import os
from PIL import Image, ImageDraw

ROOT = r'c:\Users\khang\Documents\Build\Boom'

def make_3d_cube(top_color, top_highlight, front_color, front_shadow, border_color, emblem_type="none"):
    """
    Creates a true 3D Cube (Khối Lập Phương 40x40):
    - Top face (y=0..19): 20px top surface with isometric highlight.
    - Front face (y=20..39): 20px tall front face with vertical depth shading and bevels.
    - Ratio 1:1 gives the authentic look of a solid 3D cube!
    """
    img = Image.new('RGBA', (40, 40), (0, 0, 0, 255))
    draw = ImageDraw.Draw(img)
    
    # 1. Top face (y=0..19)
    draw.rectangle([0, 0, 39, 19], fill=top_color)
    draw.line([(0, 0), (39, 0)], fill=top_highlight, width=2)
    draw.line([(0, 0), (0, 19)], fill=top_highlight, width=1)
    
    # 2. Front face (y=20..39) - 20px tall solid face
    draw.rectangle([0, 20, 39, 39], fill=front_color)
    
    # Left & Right 3D corner vertical bevels
    draw.rectangle([0, 20, 3, 39], fill=top_highlight)
    draw.rectangle([36, 20, 39, 39], fill=front_shadow)
    
    # Top-to-front edge crease
    draw.line([(0, 19), (39, 19)], fill=front_shadow, width=2)
    draw.line([(0, 20), (39, 20)], fill=top_highlight, width=1)
    
    # Bottom ground contact drop shadow
    draw.line([(0, 38), (39, 38)], fill=front_shadow, width=2)
    
    # Outer border
    draw.rectangle([0, 0, 39, 39], outline=border_color, width=1)
    
    # 3. Cube Emblems & Textures
    if emblem_type == "brick_wall":
        # Top brick row
        draw.line([(0, 9), (39, 9)], fill=front_shadow, width=1)
        draw.line([(20, 0), (20, 9)], fill=front_shadow, width=1)
        draw.line([(10, 9), (10, 19)], fill=front_shadow, width=1)
        draw.line([(30, 9), (30, 19)], fill=front_shadow, width=1)
        # Front 3D brick rows (2 rows of bricks on front face)
        draw.line([(0, 29), (39, 29)], fill=front_shadow, width=1)
        draw.line([(20, 20), (20, 29)], fill=front_shadow, width=1)
        draw.line([(10, 29), (10, 39)], fill=front_shadow, width=1)
        draw.line([(30, 29), (30, 39)], fill=front_shadow, width=1)

    elif emblem_type == "wooden_crate":
        # Top face wooden cross brace
        draw.rectangle([3, 2, 36, 17], outline=border_color, width=1)
        draw.line([(3, 2), (36, 17)], fill=front_shadow, width=2)
        draw.line([(36, 2), (3, 17)], fill=front_shadow, width=2)
        draw.line([(3, 2), (36, 17)], fill=top_highlight, width=1)
        draw.line([(36, 2), (3, 17)], fill=top_highlight, width=1)
        # Front face vertical planks and iron studs
        draw.rectangle([3, 22, 36, 37], outline=border_color, width=1)
        draw.line([(13, 20), (13, 39)], fill=front_shadow, width=2)
        draw.line([(26, 20), (26, 39)], fill=front_shadow, width=2)
        # Metal corner studs
        draw.rectangle([4, 22, 7, 25], fill=(255, 230, 120, 255), outline=border_color)
        draw.rectangle([32, 22, 35, 25], fill=(255, 230, 120, 255), outline=border_color)
        draw.rectangle([4, 34, 7, 37], fill=(255, 230, 120, 255), outline=border_color)
        draw.rectangle([32, 34, 35, 37], fill=(255, 230, 120, 255), outline=border_color)

    elif emblem_type == "lego_studs":
        # 4 3D Raised Lego studs on top face
        studs = [(10, 6), (29, 6), (10, 14), (29, 14)]
        for sx, sy in studs:
            draw.ellipse([sx - 5, sy - 3, sx + 5, sy + 5], fill=front_shadow)
            draw.ellipse([sx - 5, sy - 4, sx + 5, sy + 3], fill=front_color)
            draw.ellipse([sx - 5, sy - 5, sx + 5, sy + 1], fill=top_highlight, outline=border_color)
        # Front face lego block seam
        draw.line([(0, 29), (39, 29)], fill=front_shadow, width=1)
        draw.line([(20, 20), (20, 39)], fill=front_shadow, width=1)

    elif emblem_type == "lego_crate":
        # Top yellow lid
        draw.rectangle([3, 2, 36, 17], outline=border_color, width=1)
        draw.line([(4, 3), (35, 16)], fill=front_shadow, width=2)
        draw.line([(4, 3), (35, 16)], fill=top_highlight, width=1)
        # Front face yellow planks
        draw.rectangle([3, 22, 36, 37], outline=border_color, width=1)
        draw.line([(13, 20), (13, 39)], fill=front_shadow, width=2)
        draw.line([(26, 20), (26, 39)], fill=front_shadow, width=2)

    elif emblem_type == "ice_glacier":
        # Faceted 3D crystal cube
        draw.polygon([(20, 2), (35, 10), (20, 18), (5, 10)], fill=top_highlight)
        draw.polygon([(20, 5), (31, 10), (20, 15), (9, 10)], fill=top_color)
        # Front crystal facets
        draw.polygon([(5, 20), (20, 28), (5, 38)], fill=top_highlight)
        draw.polygon([(35, 20), (20, 28), (35, 38)], fill=front_shadow)
        draw.line([(20, 20), (20, 39)], fill=(230, 255, 255, 255), width=2)

    elif emblem_type == "ice_cube":
        # Translucent ice cube with frost border
        draw.rectangle([3, 2, 36, 17], outline=(230, 255, 255, 255), width=2)
        draw.line([(6, 5), (18, 12)], fill=(255, 255, 255, 255), width=2)
        draw.line([(33, 4), (22, 12)], fill=(255, 255, 255, 255), width=2)
        # Front ice cracks
        draw.rectangle([3, 22, 36, 37], outline=(230, 255, 255, 255), width=2)
        draw.line([(8, 22), (18, 30), (12, 38)], fill=(255, 255, 255, 255), width=2)
        draw.line([(32, 22), (24, 30), (28, 38)], fill=(255, 255, 255, 255), width=2)

    elif emblem_type == "pharaoh_pillar":
        # Top Ankh diamond
        draw.polygon([(20, 3), (32, 10), (20, 17), (8, 10)], fill=(255, 215, 60, 255), outline=border_color)
        draw.rectangle([18, 5, 22, 15], fill=(255, 240, 120, 255))
        # Front Gold Hieroglyph Plaque
        draw.rectangle([4, 23, 35, 36], fill=(215, 170, 40, 255), outline=border_color)
        draw.line([(12, 23), (12, 36)], fill=(50, 30, 10, 255), width=1)
        draw.line([(20, 23), (20, 36)], fill=(50, 30, 10, 255), width=1)
        draw.line([(28, 23), (28, 36)], fill=(50, 30, 10, 255), width=1)

    elif emblem_type == "cyber_matrix":
        # Neon cyber grid on top
        draw.rectangle([4, 3, 35, 16], outline=top_highlight, width=1)
        draw.rectangle([10, 6, 29, 13], fill=front_color, outline=top_highlight)
        # Front server racks & LEDs
        draw.rectangle([4, 23, 35, 36], outline=top_highlight, width=1)
        for vy in [26, 30, 34]:
            draw.line([(6, vy), (33, vy)], fill=top_highlight, width=1)
            draw.point([(8, vy), (31, vy)], fill=(255, 255, 255, 255))

    return img

def build_all_cubes():
    # 1. Training Plaza
    tp_dir = os.path.join(ROOT, 'assets', 'tilesets', 'training_plaza', 'runtime')
    os.makedirs(tp_dir, exist_ok=True)
    tp_hard = make_3d_cube((215, 80, 55), (255, 140, 110), (145, 45, 30), (85, 20, 12), (70, 15, 10), "brick_wall")
    tp_soft = make_3d_cube((235, 175, 75), (255, 225, 140), (175, 115, 40), (105, 65, 18), (80, 45, 10), "wooden_crate")
    tp_hard.save(os.path.join(tp_dir, 'hard_block.png'))
    tp_soft.save(os.path.join(tp_dir, 'soft_block.png'))
    tp_hard.save(os.path.join(ROOT, 'assets', 'maps', 'tile_wall.png'))
    tp_soft.save(os.path.join(ROOT, 'assets', 'maps', 'tile_destructible.png'))

    # 2. Aqua Park
    aq_dir = os.path.join(ROOT, 'assets', 'tilesets', 'aqua_park', 'runtime')
    os.makedirs(aq_dir, exist_ok=True)
    aq_hard = make_3d_cube((35, 160, 230), (120, 220, 255), (18, 100, 165), (10, 55, 100), (8, 40, 75), "brick_wall")
    aq_soft = make_3d_cube((255, 195, 60), (255, 235, 130), (200, 135, 30), (130, 75, 15), (95, 50, 10), "wooden_crate")
    aq_hard.save(os.path.join(aq_dir, 'hard_block.png'))
    aq_soft.save(os.path.join(aq_dir, 'soft_block.png'))

    # 3. Pirate Harbor
    pi_dir = os.path.join(ROOT, 'assets', 'tilesets', 'pirate_harbor', 'runtime')
    os.makedirs(pi_dir, exist_ok=True)
    pi_hard = make_3d_cube((110, 85, 70), (165, 135, 115), (70, 50, 40), (35, 22, 16), (25, 15, 10), "brick_wall")
    pi_soft = make_3d_cube((195, 125, 60), (245, 185, 110), (135, 80, 32), (75, 40, 14), (55, 25, 10), "wooden_crate")
    pi_hard.save(os.path.join(pi_dir, 'hard_block.png'))
    pi_soft.save(os.path.join(pi_dir, 'soft_block.png'))

    # 4. Snow Village
    sn_dir = os.path.join(ROOT, 'assets', 'tilesets', 'snow_village', 'runtime')
    os.makedirs(sn_dir, exist_ok=True)
    sn_hard = make_3d_cube((210, 235, 250), (255, 255, 255), (130, 170, 205), (75, 105, 140), (50, 75, 105), "brick_wall")
    sn_soft = make_3d_cube((205, 155, 95), (250, 210, 155), (145, 100, 52), (85, 52, 22), (60, 35, 15), "wooden_crate")
    sn_hard.save(os.path.join(sn_dir, 'hard_block.png'))
    sn_soft.save(os.path.join(sn_dir, 'soft_block.png'))

    # 5. Neon Arcade
    ne_dir = os.path.join(ROOT, 'assets', 'tilesets', 'neon_arcade', 'runtime')
    os.makedirs(ne_dir, exist_ok=True)
    ne_hard = make_3d_cube((45, 30, 85), (160, 100, 255), (25, 15, 55), (12, 6, 30), (180, 70, 255), "cyber_matrix")
    ne_soft = make_3d_cube((20, 150, 190), (100, 240, 255), (10, 95, 130), (5, 50, 75), (50, 220, 255), "cyber_matrix")
    ne_hard.save(os.path.join(ne_dir, 'hard_block.png'))
    ne_soft.save(os.path.join(ne_dir, 'soft_block.png'))

    # 6. Lego City
    le_dir = os.path.join(ROOT, 'assets', 'tilesets', 'lego_city', 'runtime')
    os.makedirs(le_dir, exist_ok=True)
    le_hard = make_3d_cube((235, 55, 45), (255, 130, 115), (170, 28, 22), (100, 12, 10), (75, 8, 6), "lego_studs")
    le_soft = make_3d_cube((255, 205, 45), (255, 240, 125), (200, 145, 20), (130, 85, 8), (95, 60, 5), "lego_crate")
    le_hard.save(os.path.join(le_dir, 'hard_block.png'))
    le_soft.save(os.path.join(le_dir, 'soft_block.png'))

    # 7. Ice Labyrinth
    ic_dir = os.path.join(ROOT, 'assets', 'tilesets', 'ice_labyrinth', 'runtime')
    os.makedirs(ic_dir, exist_ok=True)
    ic_hard = make_3d_cube((35, 95, 175), (125, 215, 255), (18, 55, 115), (8, 28, 68), (6, 20, 50), "ice_glacier")
    ic_soft = make_3d_cube((120, 225, 255), (230, 255, 255), (60, 165, 215), (28, 95, 140), (18, 65, 100), "ice_cube")
    ic_hard.save(os.path.join(ic_dir, 'hard_block.png'))
    ic_soft.save(os.path.join(ic_dir, 'soft_block.png'))

    # 8. Egypt Temple
    eg_dir = os.path.join(ROOT, 'assets', 'tilesets', 'egypt_temple', 'runtime')
    os.makedirs(eg_dir, exist_ok=True)
    eg_hard = make_3d_cube((38, 48, 75), (110, 135, 185), (20, 28, 48), (10, 14, 28), (255, 210, 50), "pharaoh_pillar")
    eg_soft = make_3d_cube((210, 125, 50), (255, 190, 110), (145, 75, 25), (85, 38, 10), (60, 25, 6), "wooden_crate")
    eg_hard.save(os.path.join(eg_dir, 'hard_block.png'))
    eg_soft.save(os.path.join(eg_dir, 'soft_block.png'))

    print("All tilesets rebuilt as authentic 3D Cubes!")

build_all_cubes()
