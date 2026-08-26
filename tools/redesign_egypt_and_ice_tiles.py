import os
from PIL import Image, ImageDraw

ROOT = r'c:\Users\khang\Documents\Build\Boom'

# =========================================================================
# 1. EGYPT TEMPLE (DESERT MAP) - HIGH CONTRAST & CRYSTAL CLEAR TILES
# =========================================================================
egypt_dir = os.path.join(ROOT, 'assets', 'tilesets', 'egypt_temple', 'runtime')
os.makedirs(egypt_dir, exist_ok=True)

# Floor: Warm Golden Desert Sand Tiles (40x40)
eg_floor = Image.new('RGBA', (40, 40), (228, 192, 92, 255))
d = ImageDraw.Draw(eg_floor)
# Subtle sandstone paver pattern
d.rectangle([0, 0, 39, 39], outline=(212, 172, 72, 255), width=1)
d.rectangle([2, 2, 37, 37], fill=(232, 198, 98, 255))
d.point([(8, 8), (14, 25), (28, 12), (32, 28), (20, 32)], fill=(245, 215, 120, 255))
eg_floor.save(os.path.join(egypt_dir, 'floor.png'))

# Floor Alt: Sandstone Tile with Egyptian diamond
eg_floor_alt = eg_floor.copy()
d_alt = ImageDraw.Draw(eg_floor_alt)
d_alt.polygon([(20, 10), (30, 20), (20, 30), (10, 20)], outline=(205, 160, 60, 255), fill=(225, 185, 85, 255))
eg_floor_alt.save(os.path.join(egypt_dir, 'floor_alt.png'))

# Hard Block: Dark Obsidian / Royal Blue & Gold Pharaoh Pillar (Indestructible Solid Wall)
eg_hard = Image.new('RGBA', (40, 40), (24, 38, 68, 255))
d_h = ImageDraw.Draw(eg_hard)
# Heavy gold border
d_h.rectangle([0, 0, 39, 39], outline=(255, 210, 50, 255), width=3)
d_h.rectangle([3, 3, 36, 36], outline=(15, 25, 48, 255), width=2)
# Inner royal obsidian stone
d_h.rectangle([5, 5, 34, 34], fill=(28, 48, 85, 255))
# Gold Pharaoh Eye / Ankh Emblem
d_h.polygon([(20, 8), (32, 20), (20, 32), (8, 20)], fill=(255, 200, 40, 255))
d_h.rectangle([17, 12, 23, 28], fill=(255, 230, 90, 255))
d_h.rectangle([14, 18, 26, 22], fill=(255, 230, 90, 255))
eg_hard.save(os.path.join(egypt_dir, 'hard_block.png'))

# Soft Block: Warm Terracotta & Golden Wooden Egyptian Crate (Breakable Block)
eg_soft = Image.new('RGBA', (40, 40), (185, 95, 35, 255))
d_s = ImageDraw.Draw(eg_soft)
# Crate outer frame
d_s.rectangle([0, 0, 39, 39], outline=(110, 45, 12, 255), width=2)
d_s.rectangle([2, 2, 37, 37], outline=(240, 160, 60, 255), width=2)
d_s.rectangle([4, 4, 35, 35], fill=(215, 120, 45, 255))
# Diagonal wooden cross braces ('X')
d_s.line([(4, 4), (35, 35)], fill=(120, 50, 15, 255), width=3)
d_s.line([(35, 4), (4, 35)], fill=(120, 50, 15, 255), width=3)
d_s.line([(4, 4), (35, 35)], fill=(250, 185, 80, 255), width=1)
d_s.line([(35, 4), (4, 35)], fill=(250, 185, 80, 255), width=1)
# Center bolt
d_s.ellipse([17, 17, 23, 23], fill=(255, 220, 60, 255), outline=(100, 40, 10, 255))
eg_soft.save(os.path.join(egypt_dir, 'soft_block.png'))


# =========================================================================
# 2. ICE LABYRINTH (ICE MAP) - CRYSTAL CLEAR ARCTIC BLUE CONTRAST
# =========================================================================
ice_dir = os.path.join(ROOT, 'assets', 'tilesets', 'ice_labyrinth', 'runtime')
os.makedirs(ice_dir, exist_ok=True)

# Floor: Frosted Arctic Ocean Blue Tiles (Clean Walkable Surface)
ice_floor = Image.new('RGBA', (40, 40), (45, 95, 148, 255))
d_if = ImageDraw.Draw(ice_floor)
d_if.rectangle([0, 0, 39, 39], outline=(35, 75, 120, 255), width=1)
d_if.rectangle([2, 2, 37, 37], fill=(52, 108, 165, 255))
d_if.point([(10, 10), (28, 14), (16, 28), (30, 30)], fill=(95, 165, 225, 255))
ice_floor.save(os.path.join(ice_dir, 'floor.png'))

# Floor Alt: Ice Tile with Snowflake diamond
ice_floor_alt = ice_floor.copy()
d_ifa = ImageDraw.Draw(ice_floor_alt)
d_ifa.polygon([(20, 8), (32, 20), (20, 32), (8, 20)], outline=(35, 75, 120, 255), fill=(40, 85, 135, 255))
d_ifa.point([(20, 20)], fill=(200, 245, 255, 255))
ice_floor_alt.save(os.path.join(ice_dir, 'floor_alt.png'))

# Hard Block: Solid Deep Dark Glacier Steel Fortress Wall (Indestructible Solid Wall)
ice_hard = Image.new('RGBA', (40, 40), (14, 38, 72, 255))
d_ih = ImageDraw.Draw(ice_hard)
d_ih.rectangle([0, 0, 39, 39], outline=(100, 225, 255, 255), width=3)
d_ih.rectangle([3, 3, 36, 36], outline=(10, 24, 48, 255), width=2)
d_ih.rectangle([5, 5, 34, 34], fill=(18, 48, 92, 255))
# Dark Glacier Core with Ice Shard
d_ih.polygon([(20, 8), (30, 20), (20, 32), (10, 20)], fill=(60, 180, 240, 255))
d_ih.polygon([(20, 12), (26, 20), (20, 28), (14, 20)], fill=(180, 245, 255, 255))
ice_hard.save(os.path.join(ice_dir, 'hard_block.png'))

# Soft Block: Glowing Translucent Ice Cube with Frost Crust (Breakable Block)
ice_soft = Image.new('RGBA', (40, 40), (130, 230, 255, 255))
d_is = ImageDraw.Draw(ice_soft)
d_is.rectangle([0, 0, 39, 39], outline=(30, 120, 180, 255), width=2)
d_is.rectangle([2, 2, 37, 37], outline=(220, 250, 255, 255), width=2)
d_is.rectangle([4, 4, 35, 35], fill=(100, 215, 255, 255))
# Ice fracture cracks
d_is.line([(6, 12), (18, 20), (14, 34)], fill=(240, 255, 255, 255), width=2)
d_is.line([(34, 8), (24, 18), (30, 30)], fill=(240, 255, 255, 255), width=2)
d_is.line([(18, 20), (24, 18)], fill=(255, 255, 255, 255), width=2)
# Top frost highlight
d_is.rectangle([4, 4, 35, 8], fill=(255, 255, 255, 230))
ice_soft.save(os.path.join(ice_dir, 'soft_block.png'))

print("Egypt and Ice tilesets successfully redesigned for maximum visual clarity and contrast!")
