"""
Training Plaza Environment Art Generator — v1
Generates production-quality 40x40 tiles for the Training Plaza theme.

Produces:
  floor variant A–F        (6 seamless grass tiles)
  floor_alt variant A–C    (3 alternate grass tiles)
  wall_center              (independent wall block)
  wall_edge_top/bottom/left/right  (edge pieces)
  wall_corner_tl/tr/bl/br  (corner pieces)
  wall_cap                 (isolated single wall)
  soft_crate_a/b/c         (3 crate variants)
  soft_barrel              (barrel)
  soft_training_box        (training box)
  soft_bush                (bush destructible)
  contact_shadow           (shadow blob beneath blocks)
  hard_block_preview       (wall preview for validation)

All tiles are 40x40 RGBA, pixel-art style, upper-left lighting.
"""

from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter
import random, json, hashlib

ROOT = Path(__file__).resolve().parents[1]
OUT_BASE = ROOT / "assets" / "tilesets" / "training_plaza" / "runtime"
SOURCE_DIR = ROOT / "assets" / "tilesets" / "training_plaza" / "source"
TILE = 40

# ── Palette ──────────────────────────────────────────────────────────
GRASS_BASE     = (100, 185, 90)
GRASS_DARK     = (75, 145, 65)
GRASS_LIGHT    = (130, 210, 115)
GRASS_ACCENT   = (145, 220, 80)
SOIL_COLOR     = (140, 110, 70)
WOOD_BASE      = (160, 120, 65)
WOOD_DARK      = (115, 80, 40)
WOOD_LIGHT     = (195, 155, 95)
WOOD_HIGHLIGHT = (220, 185, 130)
METAL_RIVET    = (180, 180, 185)
BRICK_BASE     = (175, 75, 55)
BRICK_DARK     = (130, 50, 35)
BRICK_LIGHT    = (200, 100, 75)
BRICK_MORTAR   = (155, 145, 130)
STONE_BASE     = (145, 140, 135)
STONE_DARK     = (110, 105, 100)
STONE_LIGHT    = (175, 170, 165)
LEAF_GREEN     = (60, 140, 50)
LEAF_DARK      = (40, 100, 35)
BARREL_BAND    = (90, 80, 70)
SHADOW_COLOR   = (20, 30, 15, 80)

OUT_BASE.mkdir(parents=True, exist_ok=True)


def NL():
    return Image.new("RGBA", (TILE, TILE), (0, 0, 0, 0))


# ═══════════════════════════════════════════════════════════════════════
# FLOOR TILES — seamless grass with subtle variation
# ═══════════════════════════════════════════════════════════════════════

def _grass_base(seed: int) -> Image.Image:
    """Create a seamless 40x40 grass tile — clean arcade pixel-art style."""
    rng = random.Random(seed)
    img = NL()
    d = ImageDraw.Draw(img, "RGBA")

    # solid base
    d.rectangle([0, 0, 39, 39], fill=GRASS_BASE)

    # scattered single-pixel texture (lighter and darker dots)
    for _ in range(rng.randint(20, 30)):
        x, y = rng.randint(0, 39), rng.randint(0, 39)
        col = rng.choice([GRASS_DARK, GRASS_LIGHT, GRASS_ACCENT])
        alpha = rng.randint(25, 55)
        d.point((x, y), fill=(*col, alpha))

    # 2-3 tiny grass blade marks (2px tall lines)
    for _ in range(rng.randint(2, 4)):
        x = rng.randint(4, 35)
        y = rng.randint(10, 35)
        d.line([(x, y), (x, y - 2)], fill=(*GRASS_DARK, 60), width=1)

    # occasional tiny flower (8%)
    if rng.random() < 0.08:
        fx, fy = rng.randint(8, 31), rng.randint(8, 31)
        d.point((fx, fy), fill=(255, 230, 120, 140))

    return img


def build_floor_variants() -> list[Image.Image]:
    """6 seamless grass floor variants."""
    return [_grass_base(100 + i) for i in range(6)]


def build_floor_alt_variants() -> list[Image.Image]:
    """3 alternate grass tiles — subtle pixel-art variation."""
    imgs = []
    for i in range(3):
        rng = random.Random(200 + i)
        img = NL()
        d = ImageDraw.Draw(img, "RGBA")
        # very slightly shifted base color
        shift = rng.randint(-3, 4)
        alt_base = tuple(min(255, max(0, c + shift)) for c in GRASS_BASE)
        d.rectangle([0, 0, 39, 39], fill=alt_base)
        # scattered pixel texture
        for _ in range(rng.randint(18, 28)):
            x, y = rng.randint(0, 39), rng.randint(0, 39)
            col = rng.choice([GRASS_DARK, GRASS_LIGHT])
            d.point((x, y), fill=(*col, rng.randint(20, 45)))
        # sparse blades
        for _ in range(rng.randint(1, 3)):
            x, y = rng.randint(5, 34), rng.randint(10, 34)
            d.line([(x, y), (x, y - 2)], fill=(*GRASS_DARK, 50), width=1)
        imgs.append(img)
    return imgs


# ═══════════════════════════════════════════════════════════════════════
# WALL / INDESTRUCTIBLE BLOCK — brick wall with 2.5D depth
# ═══════════════════════════════════════════════════════════════════════

def _draw_brick_row(d: ImageDraw.ImageDraw, y: int, offset: int, w: int = 40):
    """Draw a single brick row with offset for running bond pattern."""
    brick_w = 10
    mortar = 1
    for x in range(offset % (brick_w + mortar) - brick_w - mortar, w + brick_w, brick_w + mortar):
        bx1 = max(0, x)
        bx2 = min(w - 1, x + brick_w - 1)
        if bx2 > bx1:
            d.rectangle([bx1, y, bx2, y + 5], fill=BRICK_BASE)
            d.line([(bx1, y), (bx2, y)], fill=BRICK_LIGHT, width=1)
            d.line([(bx1, y + 5), (bx2, y + 5)], fill=BRICK_DARK, width=1)
            d.line([(bx1, y), (bx1, y + 5)], fill=BRICK_DARK, width=1)


def build_wall_block() -> Image.Image:
    """40x40 brick wall block with 2.5D depth (front face + top face illusion)."""
    img = NL()
    d = ImageDraw.Draw(img, "RGBA")

    # contact shadow at bottom
    d.rectangle([2, 36, 37, 39], fill=SHADOW_COLOR)

    # front face (lower portion, darker)
    front_y = 8
    for row in range(5):
        y = front_y + row * 6
        _draw_brick_row(d, y, 5 if row % 2 else 0)

    # top face (brighter, compressed vertically)
    d.rectangle([0, 0, 39, 7], fill=(*BRICK_LIGHT, 220))
    for x in range(0, 40, 11):
        d.line([(x, 0), (x, 7)], fill=(*BRICK_MORTAR, 120), width=1)
    d.line([(0, 3), (39, 3)], fill=(*BRICK_MORTAR, 80), width=1)

    # edge highlight on top-left
    d.line([(1, 0), (1, 7)], fill=(*BRICK_LIGHT, 100), width=1)
    d.line([(0, 0), (39, 0)], fill=(255, 255, 255, 40), width=1)

    # right edge shadow
    d.line([(38, 8), (38, 35)], fill=(*BRICK_DARK, 120), width=1)

    return img


# ═══════════════════════════════════════════════════════════════════════
# DESTRUCTIBLE PROPS — wooden crate variants, barrel, training box, bush
# ═══════════════════════════════════════════════════════════════════════

def _draw_wooden_crate(d: ImageDraw.ImageDraw, seed: int, variant: str = "a"):
    """Draw a wooden crate with cross-bracing, nails, and grain."""
    rng = random.Random(seed)
    # front face
    d.rectangle([3, 12, 36, 36], fill=WOOD_BASE)
    # top face
    d.polygon([(3, 12), (36, 12), (33, 3), (6, 3)], fill=WOOD_LIGHT)
    # side face (right)
    d.polygon([(36, 12), (36, 36), (33, 36), (33, 3)], fill=WOOD_DARK)

    # wood grain on front
    for _ in range(rng.randint(3, 5)):
        gy = rng.randint(14, 34)
        d.line([(5, gy), (34, gy + rng.randint(-1, 1))], fill=(*WOOD_DARK, 50), width=1)

    # cross-bracing
    if variant == "a":
        d.line([(5, 14), (34, 34)], fill=(*WOOD_DARK, 120), width=1)
        d.line([(34, 14), (5, 34)], fill=(*WOOD_DARK, 120), width=1)
    elif variant == "b":
        d.line([(20, 14), (20, 34)], fill=(*WOOD_DARK, 100), width=2)
        d.line([(5, 24), (34, 24)], fill=(*WOOD_DARK, 100), width=2)
    else:
        d.line([(5, 14), (34, 34)], fill=(*WOOD_DARK, 120), width=1)

    # nails at corners
    for nx, ny in [(6, 14), (33, 14), (6, 33), (33, 33)]:
        d.ellipse([nx - 1, ny - 1, nx + 1, ny + 1], fill=(*METAL_RIVET, 200))

    # edge highlight
    d.line([(4, 12), (35, 12)], fill=(*WOOD_HIGHLIGHT, 100), width=1)
    d.line([(4, 12), (4, 35)], fill=(*WOOD_HIGHLIGHT, 60), width=1)

    # contact shadow
    d.rectangle([4, 36, 35, 38], fill=SHADOW_COLOR)


def build_crate_a() -> Image.Image:
    img = NL(); d = ImageDraw.Draw(img, "RGBA")
    _draw_wooden_crate(d, 300, "a")
    return img

def build_crate_b() -> Image.Image:
    img = NL(); d = ImageDraw.Draw(img, "RGBA")
    _draw_wooden_crate(d, 301, "b")
    return img

def build_crate_c() -> Image.Image:
    img = NL(); d = ImageDraw.Draw(img, "RGBA")
    _draw_wooden_crate(d, 302, "c")
    return img


def build_barrel() -> Image.Image:
    """Wooden barrel with metal bands."""
    img = NL(); d = ImageDraw.Draw(img, "RGBA")

    # contact shadow
    d.rectangle([8, 36, 31, 38], fill=SHADOW_COLOR)

    # barrel body (slightly wider in middle)
    body = [(10, 10), (30, 10), (32, 23), (30, 36), (10, 36), (8, 23)]
    d.polygon(body, fill=WOOD_BASE)

    # top ellipse
    d.ellipse([10, 5, 30, 15], fill=WOOD_LIGHT, outline=WOOD_DARK, width=1)

    # metal bands
    d.arc([(9, 10), (31, 30)], 0, 180, fill=(*BARREL_BAND, 200), width=2)
    d.arc([(8, 22), (32, 38)], 0, 180, fill=(*BARREL_BAND, 200), width=2)

    # vertical stave lines
    for x in [14, 20, 26]:
        d.line([(x, 12), (x, 35)], fill=(*WOOD_DARK, 60), width=1)

    # highlight
    d.arc([(10, 10), (25, 30)], 250, 290, fill=(*WOOD_HIGHLIGHT, 80), width=2)

    return img


def build_training_box() -> Image.Image:
    """Training supply box with star marking."""
    img = NL(); d = ImageDraw.Draw(img, "RGBA")

    # shadow
    d.rectangle([4, 36, 35, 38], fill=SHADOW_COLOR)

    # box body
    d.rectangle([4, 12, 35, 36], fill=(180, 140, 80))
    # top face
    d.polygon([(4, 12), (35, 12), (32, 3), (7, 3)], fill=(210, 175, 110))

    # strap / tape
    d.rectangle([18, 12, 22, 36], fill=(200, 60, 50))
    d.rectangle([4, 22, 35, 26], fill=(200, 60, 50))

    # star emblem in center
    cx, cy = 20, 24
    star_pts = []
    for i in range(10):
        import math
        a = math.radians(i * 36 - 90)
        r = 5 if i % 2 == 0 else 2.5
        star_pts.append((cx + int(math.cos(a) * r), cy + int(math.sin(a) * r)))
    d.polygon(star_pts, fill=(255, 220, 80))

    # nails
    for nx, ny in [(6, 14), (33, 14), (6, 34), (33, 34)]:
        d.ellipse([nx - 1, ny - 1, nx + 1, ny + 1], fill=(*METAL_RIVET, 180))

    # highlight
    d.line([(5, 12), (34, 12)], fill=(255, 255, 255, 60), width=1)

    return img


def build_bush() -> Image.Image:
    """Leafy bush — organic destructible."""
    img = NL(); d = ImageDraw.Draw(img, "RGBA")

    # shadow
    d.ellipse([6, 30, 34, 38], fill=SHADOW_COLOR)

    # bush mass — overlapping circles
    circles = [(20, 22, 14), (13, 25, 10), (27, 25, 10), (20, 18, 11),
               (15, 19, 8), (25, 19, 8), (20, 28, 9)]
    for cx, cy, r in circles:
        d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=LEAF_GREEN)

    # darker inner patches
    for cx, cy, r in [(16, 24, 5), (24, 22, 5), (20, 20, 4)]:
        d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=LEAF_DARK)

    # highlight leaves on top
    for cx, cy, r in [(18, 16, 3), (24, 17, 2), (20, 14, 3)]:
        d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=(*GRASS_LIGHT, 160))

    # tiny berries / flowers
    for bx, by in [(14, 20), (26, 21), (20, 26)]:
        d.ellipse([bx - 1, by - 1, bx + 1, by + 1], fill=(255, 100, 100, 180))

    return img


# ═══════════════════════════════════════════════════════════════════════
# CONTACT SHADOW
# ═══════════════════════════════════════════════════════════════════════

def build_contact_shadow() -> Image.Image:
    """Soft elliptical shadow blob placed beneath blocks."""
    img = NL()
    shadow = NL()
    sd = ImageDraw.Draw(shadow, "RGBA")
    sd.ellipse([4, 28, 36, 38], fill=(0, 0, 0, 100))
    blurred = shadow.filter(ImageFilter.GaussianBlur(2))
    return blurred


# ═══════════════════════════════════════════════════════════════════════
# WALL AUTOTILE PIECES — connected wall rendering
# ═══════════════════════════════════════════════════════════════════════

def _wall_top_face(d: ImageDraw.ImageDraw, brightness: float = 1.0):
    """Draw the top face of a wall block."""
    col = tuple(min(255, int(c * brightness)) for c in BRICK_LIGHT)
    d.rectangle([0, 0, 39, 7], fill=(*col, 220))
    for x in range(0, 40, 11):
        d.line([(x, 0), (x, 7)], fill=(*BRICK_MORTAR, 100), width=1)
    d.line([(0, 3), (39, 3)], fill=(*BRICK_MORTAR, 60), width=1)


def _wall_front_face(d: ImageDraw.ImageDraw, y_start: int = 8, brightness: float = 1.0):
    """Draw the front brick face."""
    for row in range(5):
        y = y_start + row * 6
        _draw_brick_row(d, y, 5 if row % 2 else 0)


def build_wall_center() -> Image.Image:
    """Independent wall block — all edges visible."""
    img = NL(); d = ImageDraw.Draw(img, "RGBA")
    d.rectangle([2, 36, 37, 39], fill=SHADOW_COLOR)
    _wall_front_face(d)
    _wall_top_face(d)
    d.line([(1, 0), (1, 7)], fill=(*BRICK_LIGHT, 80), width=1)
    d.line([(38, 8), (38, 35)], fill=(*BRICK_DARK, 100), width=1)
    return img


def build_wall_edge_top() -> Image.Image:
    """Wall with top edge visible (no wall above)."""
    img = NL(); d = ImageDraw.Draw(img, "RGBA")
    d.rectangle([2, 36, 37, 39], fill=SHADOW_COLOR)
    _wall_front_face(d)
    _wall_top_face(d, 1.05)
    d.line([(1, 0), (1, 7)], fill=(*BRICK_LIGHT, 80), width=1)
    d.line([(38, 8), (38, 35)], fill=(*BRICK_DARK, 100), width=1)
    return img


def build_wall_edge_bottom() -> Image.Image:
    """Wall with bottom edge (wall continues above)."""
    img = NL(); d = ImageDraw.Draw(img, "RGBA")
    _wall_front_face(d)
    d.line([(38, 0), (38, 35)], fill=(*BRICK_DARK, 100), width=1)
    return img


def build_wall_edge_left() -> Image.Image:
    """Wall with left edge visible."""
    img = NL(); d = ImageDraw.Draw(img, "RGBA")
    d.rectangle([2, 36, 37, 39], fill=SHADOW_COLOR)
    _wall_front_face(d)
    _wall_top_face(d)
    d.line([(1, 0), (1, 35)], fill=(*BRICK_LIGHT, 80), width=2)
    return img


def build_wall_edge_right() -> Image.Image:
    """Wall with right edge visible."""
    img = NL(); d = ImageDraw.Draw(img, "RGBA")
    d.rectangle([2, 36, 37, 39], fill=SHADOW_COLOR)
    _wall_front_face(d)
    _wall_top_face(d)
    d.line([(38, 0), (38, 35)], fill=(*BRICK_DARK, 120), width=2)
    return img


def build_wall_corner_tl() -> Image.Image:
    """Top-left outer corner."""
    img = NL(); d = ImageDraw.Draw(img, "RGBA")
    d.rectangle([2, 36, 37, 39], fill=SHADOW_COLOR)
    _wall_front_face(d)
    _wall_top_face(d)
    d.line([(1, 0), (1, 35)], fill=(*BRICK_LIGHT, 100), width=2)
    return img


def build_wall_corner_tr() -> Image.Image:
    """Top-right outer corner."""
    img = NL(); d = ImageDraw.Draw(img, "RGBA")
    d.rectangle([2, 36, 37, 39], fill=SHADOW_COLOR)
    _wall_front_face(d)
    _wall_top_face(d)
    d.line([(38, 0), (38, 35)], fill=(*BRICK_DARK, 120), width=2)
    return img


def build_wall_corner_bl() -> Image.Image:
    """Bottom-left inner corner."""
    img = NL(); d = ImageDraw.Draw(img, "RGBA")
    _wall_front_face(d)
    d.line([(1, 0), (1, 35)], fill=(*BRICK_LIGHT, 80), width=2)
    return img


def build_wall_corner_br() -> Image.Image:
    """Bottom-right inner corner."""
    img = NL(); d = ImageDraw.Draw(img, "RGBA")
    _wall_front_face(d)
    d.line([(38, 0), (38, 35)], fill=(*BRICK_DARK, 100), width=2)
    return img


def build_wall_cap() -> Image.Image:
    """Isolated single wall — all edges visible, prominent."""
    img = NL(); d = ImageDraw.Draw(img, "RGBA")
    d.rectangle([2, 36, 37, 39], fill=SHADOW_COLOR)
    _wall_front_face(d, brightness=1.02)
    _wall_top_face(d, 1.08)
    # all edges
    d.line([(1, 0), (1, 35)], fill=(*BRICK_LIGHT, 100), width=2)
    d.line([(38, 0), (38, 35)], fill=(*BRICK_DARK, 120), width=2)
    return img


# ═══════════════════════════════════════════════════════════════════════
# SAVE ALL
# ═══════════════════════════════════════════════════════════════════════

def save_tiles():
    """Generate and save all Training Plaza tiles."""
    manifest = {}

    # Floor variants
    for i, tile in enumerate(build_floor_variants()):
        name = f"floor_{chr(65 + i)}"  # floor_A through floor_F
        tile.save(OUT_BASE / f"{name}.png", optimize=True)
        manifest[name] = hashlib.sha256((OUT_BASE / f"{name}.png").read_bytes()).hexdigest()

    # Alternate floor variants
    for i, tile in enumerate(build_floor_alt_variants()):
        name = f"floor_alt_{chr(65 + i)}"
        tile.save(OUT_BASE / f"{name}.png", optimize=True)
        manifest[name] = hashlib.sha256((OUT_BASE / f"{name}.png").read_bytes()).hexdigest()

    # Wall pieces
    wall_pieces = {
        "wall_center": build_wall_center,
        "wall_edge_top": build_wall_edge_top,
        "wall_edge_bottom": build_wall_edge_bottom,
        "wall_edge_left": build_wall_edge_left,
        "wall_edge_right": build_wall_edge_right,
        "wall_corner_tl": build_wall_corner_tl,
        "wall_corner_tr": build_wall_corner_tr,
        "wall_corner_bl": build_wall_corner_bl,
        "wall_corner_br": build_wall_corner_br,
        "wall_cap": build_wall_cap,
    }
    for name, fn in wall_pieces.items():
        tile = fn()
        tile.save(OUT_BASE / f"{name}.png", optimize=True)
        manifest[name] = hashlib.sha256((OUT_BASE / f"{name}.png").read_bytes()).hexdigest()

    # Keep legacy hard_block as wall_center for backward compat
    build_wall_center().save(OUT_BASE / "hard_block.png", optimize=True)
    manifest["hard_block"] = hashlib.sha256((OUT_BASE / "hard_block.png").read_bytes()).hexdigest()

    # Destructible variants
    dest_variants = {
        "soft_crate_a": build_crate_a,
        "soft_crate_b": build_crate_b,
        "soft_crate_c": build_crate_c,
        "soft_barrel": build_barrel,
        "soft_training_box": build_training_box,
        "soft_bush": build_bush,
    }
    for name, fn in dest_variants.items():
        tile = fn()
        tile.save(OUT_BASE / f"{name}.png", optimize=True)
        manifest[name] = hashlib.sha256((OUT_BASE / f"{name}.png").read_bytes()).hexdigest()

    # Legacy soft_block = crate_a
    build_crate_a().save(OUT_BASE / "soft_block.png", optimize=True)
    manifest["soft_block"] = hashlib.sha256((OUT_BASE / "soft_block.png").read_bytes()).hexdigest()

    # Legacy floor/floor_alt = first variant
    build_floor_variants()[0].save(OUT_BASE / "floor.png", optimize=True)
    build_floor_alt_variants()[0].save(OUT_BASE / "floor_alt.png", optimize=True)
    manifest["floor"] = hashlib.sha256((OUT_BASE / "floor.png").read_bytes()).hexdigest()
    manifest["floor_alt"] = hashlib.sha256((OUT_BASE / "floor_alt.png").read_bytes()).hexdigest()

    # Contact shadow
    shadow = build_contact_shadow()
    shadow.save(OUT_BASE / "contact_shadow.png", optimize=True)
    manifest["contact_shadow"] = hashlib.sha256((OUT_BASE / "contact_shadow.png").read_bytes()).hexdigest()

    # Save manifest
    manifest_path = ROOT / "tests" / "artifacts" / "tileset_validation" / "training_plaza_manifest.json"
    manifest_path.parent.mkdir(parents=True, exist_ok=True)
    manifest_path.write_text(json.dumps(manifest, indent=2), encoding="utf-8")

    # Build validation preview
    _build_validation_preview()

    total = len(manifest)
    print(f"\nGenerated {total} tiles for Training Plaza")
    print(f"  Floor variants: 6 + 3 alt")
    print(f"  Wall pieces: {len(wall_pieces)} + legacy")
    print(f"  Destructible variants: {len(dest_variants)} + legacy")
    print(f"  Contact shadow: 1")
    print(f"Output: {OUT_BASE}")


def _build_validation_preview():
    """Create a visual QA sheet showing all tiles at 3x scale."""
    preview = Image.new("RGBA", (600, 800), (26, 32, 48, 255))
    d = ImageDraw.Draw(preview)

    tiles = [
        ("Floor A", "floor_A"), ("Floor B", "floor_B"), ("Floor C", "floor_C"),
        ("Floor D", "floor_D"), ("Floor E", "floor_E"), ("Floor F", "floor_F"),
        ("Alt A", "floor_alt_A"), ("Alt B", "floor_alt_B"), ("Alt C", "floor_alt_C"),
        ("Wall Center", "wall_center"), ("Wall Edge Top", "wall_edge_top"),
        ("Wall Edge Bottom", "wall_edge_bottom"), ("Wall Edge Left", "wall_edge_left"),
        ("Wall Edge Right", "wall_edge_right"),
        ("Wall TL", "wall_corner_tl"), ("Wall TR", "wall_corner_tr"),
        ("Wall BL", "wall_corner_bl"), ("Wall BR", "wall_corner_br"),
        ("Wall Cap", "wall_cap"),
        ("Crate A", "soft_crate_a"), ("Crate B", "soft_crate_b"), ("Crate C", "soft_crate_c"),
        ("Barrel", "soft_barrel"), ("Training Box", "soft_training_box"), ("Bush", "soft_bush"),
        ("Shadow", "contact_shadow"),
    ]

    cols = 4
    cell_w = 140
    cell_h = 120
    for i, (label, name) in enumerate(tiles):
        col = i % cols
        row = i // cols
        x = col * cell_w + 10
        y = row * cell_h + 10

        tile_path = OUT_BASE / f"{name}.png"
        if tile_path.exists():
            tile = Image.open(tile_path).convert("RGBA")
            scaled = tile.resize((80, 80), Image.Resampling.NEAREST)
            preview.alpha_composite(scaled, (x + 30, y + 5))
        d.text((x, y + 90), label, fill=(210, 220, 240), font=ImageFont.load_default())

    out_path = ROOT / "assets" / "tilesets" / "training_plaza" / "processed" / "training_plaza_validation.png"
    out_path.parent.mkdir(parents=True, exist_ok=True)
    preview.save(out_path)
    print(f"Validation preview: {out_path}")


import math
from PIL import ImageFont

if __name__ == "__main__":
    save_tiles()
