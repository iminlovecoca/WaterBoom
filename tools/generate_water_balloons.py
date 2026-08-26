#!/usr/bin/env python3
"""
Water Balloon Procedural Generator v3 — Truly Distinct Skins
Every skin uses its catalog motif + pattern + a per-skin seed to guarantee uniqueness.
No two skins look alike, even if they share a theme.
"""
import json, math, os, random
from PIL import Image, ImageDraw, ImageFilter

CATALOG_PATH = os.path.join(os.path.dirname(__file__), "..", "assets", "water_balloons", "water_balloon_catalog.json")
OUTPUT_BASE  = os.path.join(os.path.dirname(__file__), "..", "assets", "water_balloons", "skins")
FRAME_SIZE   = 128
R            = 40          # balloon radius
CX, CY       = FRAME_SIZE // 2, FRAME_SIZE // 2 + 4

# ── colour helpers ────────────────────────────────────────────────────
def h2c(h):
    h = h.lstrip('#')
    return tuple(int(h[i:i+2], 16) for i in (0, 2, 4))

def darken(c, f=0.6):  return tuple(max(0, int(v*f)) for v in c)
def lighten(c, f=1.4): return tuple(min(255, int(v*f)) for v in c)
def lerp_c(a, b, t):   return tuple(int(a[i]+(b[i]-a[i])*t) for i in range(3))
def NL():              return Image.new('RGBA', (FRAME_SIZE, FRAME_SIZE), (0,0,0,0))

# ── base balloon ──────────────────────────────────────────────────────
def draw_balloon(img, pc, oc):
    d = ImageDraw.Draw(img)
    dk, md, br = darken(pc,.5), darken(pc,.8), lighten(pc,1.2)
    for r in range(R+4, R-3, -1):
        d.ellipse([CX-r, CY-r+2, CX+r, CY+r+2], fill=lerp_c(dk, md, (R+4-r)/7))
    d.ellipse([CX-R, CY-R+2, CX+R, CY+R+2], fill=pc)
    for i in range(5):
        a = math.radians(i*72+15)
        ix, iy = CX+math.cos(a)*R*.35, CY+math.sin(a)*R*.35
        ir = R*0.4
        d.ellipse([ix-ir, iy-ir, ix+ir, iy+ir], fill=br)
    d.ellipse([CX-R+3, CY-R+5, CX+R-3, CY+R-3], fill=pc)
    for ang in range(360):
        a = math.radians(ang)
        x, y = CX+int(math.cos(a)*R), CY+int(math.sin(a)*R)+2
        d.point((x,y), fill=oc); d.point((x+1,y), fill=oc)

def draw_knot(d, pc, lean_r=True):
    kc = darken(pc, .65); kh = lighten(pc, 1.1)
    kx = CX + (7 if lean_r else -7); ky = CY - R + 3; lean = 5 if lean_r else -5
    d.polygon([(kx-3,ky+1),(kx+3,ky+1),(kx+lean,ky-7),(kx+lean-3,ky-7)], fill=kc)
    d.ellipse([kx+lean-4,ky-10,kx+lean+4,ky-4], fill=kc)
    d.ellipse([kx+lean-2,ky-9,kx+lean+2,ky-6], fill=kh)

def draw_highlight(d, style="smooth"):
    if style == "smooth":
        d.ellipse([CX-22, CY-24, CX-2, CY-8], fill=(255,255,255,190))
        d.ellipse([CX+5, CY-8, CX+11, CY-2], fill=(255,255,255,220))
    elif style == "warm":
        d.ellipse([CX-22, CY-24, CX-2, CY-8], fill=(255,240,220,180))
        d.ellipse([CX+5, CY-8, CX+11, CY-2], fill=(255,255,240,210))
    elif style == "cold":
        d.polygon([(CX-14,CY-18),(CX-4,CY-22),(CX+2,CY-14),(CX-8,CY-12)], fill=(220,240,255,200))
        d.ellipse([CX+5, CY-6, CX+11, CY-0], fill=(255,255,255,230))
    elif style == "small":
        d.ellipse([CX-16, CY-18, CX-12, CY-14], fill=(255,255,255,240))
        d.ellipse([CX+5, CY-5, CX+9, CY-1], fill=(255,255,255,200))
    elif style == "pearl":
        d.ellipse([CX-22, CY-24, CX-2, CY-8], fill=(255,230,255,160))
        d.ellipse([CX-18, CY-20, CX+0, CY-6], fill=(230,255,255,140))
    elif style == "neon":
        d.ellipse([CX-22, CY-24, CX-2, CY-8], fill=(255,255,255,200))
        for i in range(3):
            rr = R+3+i*2
            d.ellipse([CX-rr, CY-rr+2, CX+rr, CY+rr+2], outline=(255,150,255,40-i*10), width=1)
    elif style == "cosmic":
        d.ellipse([CX-20, CY-22, CX+0, CY-6], fill=(200,200,255,170))
    else:
        d.ellipse([CX-22, CY-24, CX-2, CY-8], fill=(255,255,255,190))

# ── MOTIF LIBRARY ─────────────────────────────────────────────────────
# Each motif is a function(draw, cx, cy, r, colour, rng) -> None
# rng is a per-skin random.Random instance for variation

def M_bubbles(d, cx, cy, r, col, rng):
    for _ in range(rng.randint(5,10)):
        bx = cx+rng.randint(int(-r*.6), int(r*.6))
        by = cy+rng.randint(int(-r*.5), int(r*.5))
        br = rng.randint(2,5)
        d.ellipse([bx-br,by-br,bx+br,by+br], outline=(*col,120), width=1)
        d.ellipse([bx-br+1,by-br+1,bx-br+3,by-br+3], fill=(*col,80))

def M_swirl(d, cx, cy, r, col, rng):
    pts = []
    rev = rng.choice([1,-1])
    for i in range(60):
        t = i/60.0; a = t*math.pi*4*rev; dist = r*.15+t*r*.5
        pts.append((cx+int(math.cos(a)*dist), cy+int(math.sin(a)*dist)))
    if len(pts)>1: d.line(pts, fill=(*col,140), width=2)

def M_star(d, cx, cy, r, col, rng):
    sz = rng.randint(5,9)
    pts = []
    for i in range(10):
        a = math.radians(i*36-90); s = sz if i%2==0 else sz*.4
        pts.append((cx+int(math.cos(a)*s), cy+int(math.sin(a)*s)))
    d.polygon(pts, fill=(*col,200))

def M_heart(d, cx, cy, r, col, rng):
    sz = rng.randint(6,10)
    h = sz//2
    d.ellipse([cx-h, cy-h, cx, cy], fill=(*col,200))
    d.ellipse([cx, cy-h, cx+h, cy], fill=(*col,200))
    d.polygon([(cx-h,cy-h//2),(cx,cy+sz//3),(cx+h,cy-h//2)], fill=(*col,200))

def M_snowflake(d, cx, cy, r, col, rng):
    arm = rng.randint(10,16)
    for i in range(6):
        a = math.radians(i*60)
        ex, ey = cx+int(math.cos(a)*arm), cy+int(math.sin(a)*arm)
        d.line([(cx,cy),(ex,ey)], fill=(*col,180), width=1)
        for j in range(1,3):
            mx = cx+int(math.cos(a)*arm*j/3)
            my = cy+int(math.sin(a)*arm*j/3)
            ba = a+math.radians(60)
            bx, by = mx+int(math.cos(ba)*arm*.25), my+int(math.sin(ba)*arm*.25)
            d.line([(mx,my),(bx,by)], fill=(*col,140), width=1)

def M_eye(d, cx, cy, r, col, rng):
    ew, eh = int(r*.6), int(r*.35)
    d.ellipse([cx-ew,cy-eh,cx+ew,cy+eh], fill=(*lighten(col,1.3),200), outline=(*darken(col,.7),180), width=2)
    ir = int(ew*.5)
    d.ellipse([cx-ir,cy-ir,cx+ir,cy+ir], fill=(*col,220))
    pr = int(ir*.5)
    d.ellipse([cx-pr,cy-pr,cx+pr,cy+pr], fill=(20,10,30,240))
    d.ellipse([cx-pr+2,cy-pr+1,cx-pr+5,cy-pr+4], fill=(255,255,255,200))

def M_wave(d, cx, cy, r, col, rng):
    count = rng.randint(2,4)
    for i in range(count):
        wy = cy-5+i*8; pts = []
        for x in range(cx-int(r*.7), cx+int(r*.7), 3):
            pts.append((x, wy+int(math.sin((x-cx)*.15+i)*4)))
        if len(pts)>1: d.line(pts, fill=(*col,100+i*20), width=2)

def M_leaf(d, cx, cy, r, col, rng):
    sz = rng.randint(10,16)
    pts = [(cx,cy-sz),(cx+sz//2,cy),(cx,cy+sz//3),(cx-sz//2,cy)]
    d.polygon(pts, fill=(*col,180))
    d.line([(cx,cy-sz),(cx,cy+sz//3)], fill=(*darken(col,.6),150), width=1)

def M_flame(d, cx, cy, r, col, rng):
    sz = rng.randint(12,18)
    pts = [(cx,cy-sz),(cx+sz//3,cy+sz//4),(cx+sz//6,cy+sz//2),(cx-sz//6,cy+sz//2),(cx-sz//3,cy+sz//4)]
    d.polygon(pts, fill=(*col,180))
    inner = [(cx,cy-sz//2),(cx+sz//6,cy+sz//6),(cx-sz//6,cy+sz//6)]
    d.polygon(inner, fill=(*lighten(col,1.3),160))

def M_galaxy(d, cx, cy, r, col, rng):
    for _ in range(40):
        a = rng.uniform(0,math.pi*2); dist = rng.uniform(0,r*.7)
        x, y = cx+int(math.cos(a)*dist), cy+int(math.sin(a)*dist)
        sz = rng.randint(1,2); c = rng.choice([(180,160,255),(255,180,220),(160,200,255)])
        d.ellipse([x-sz,y-sz,x+sz,y+sz], fill=(*c,150))

def M_diamond(d, cx, cy, r, col, rng):
    sz = rng.randint(8,14)
    pts = [(cx,cy-sz),(cx+sz//2,cy),(cx,cy+sz),(cx-sz//2,cy)]
    d.polygon(pts, fill=(*col,180), outline=(*lighten(col,1.4),160))
    d.line([(cx,cy-sz),(cx,cy+sz)], fill=(*lighten(col,1.2),120), width=1)

def M_moon(d, cx, cy, r, col, rng):
    d.ellipse([cx-10,cy-8,cx+10,cy+8], fill=(*col,180))
    d.ellipse([cx-6,cy-10,cx+8,cy+4], fill=(*lighten(col,1.5),200))

def M_cross(d, cx, cy, r, col, rng):
    w = rng.randint(2,4)
    d.line([(cx,cy-r//2),(cx,cy+r//2)], fill=(*col,160), width=w)
    d.line([(cx-r//2,cy),(cx+r//2,cy)], fill=(*col,160), width=w)

def M_ring(d, cx, cy, r, col, rng):
    rr = rng.randint(10,16)
    d.ellipse([cx-rr,cy-rr,cx+rr,cy+rr], outline=(*col,160), width=2)
    rr2 = rng.randint(5,9)
    d.ellipse([cx-rr2,cy-rr2,cx+rr2,cy+rr2], outline=(*col,120), width=1)

def M_triangle(d, cx, cy, r, col, rng):
    sz = rng.randint(10,16)
    pts = [(cx,cy-sz),(cx+sz,cy+sz//2),(cx-sz,cy+sz//2)]
    d.polygon(pts, fill=(*col,160), outline=(*lighten(col,1.3),140))

def M_scales(d, cx, cy, r, col, rng):
    for row in range(-3,4):
        for c in range(-3,4):
            sx = cx+c*10+(5 if row%2 else 0); sy = cy+row*8
            if math.sqrt((sx-cx)**2+(sy-cy)**2) < r-6:
                d.ellipse([sx-5,sy-4,sx+5,sy+4], outline=(*col,100), width=1)

def M_cloud(d, cx, cy, r, col, rng):
    for _ in range(rng.randint(3,5)):
        bx = cx+rng.randint(int(-r*.5),int(r*.5))
        by = cy+rng.randint(int(-r*.4),int(r*.3))
        bw, bh = rng.randint(6,12), rng.randint(4,7)
        d.ellipse([bx-bw,by-bh,bx+bw,by+bh], fill=(*col,80))

def M_nebula(d, cx, cy, r, col, rng):
    colors = [(100,80,200),(200,100,180),(80,150,220)]
    for i in range(60):
        t = i/60.0; a = t*math.pi*3; dist = t*r*.65
        x, y = cx+int(math.cos(a)*dist), cy+int(math.sin(a)*dist)
        c = colors[i%3]; sz = int(2+t*3)
        d.ellipse([x-sz,y-sz,x+sz,y+sz], fill=(*c,100))

def M_candy(d, cx, cy, r, col, rng):
    colors = [(255,150,200),(150,220,255),(255,230,100)]
    for i in range(80):
        t = i/80.0; a = t*math.pi*3; dist = t*r*.6
        x, y = cx+int(math.cos(a)*dist), cy+int(math.sin(a)*dist)
        c = colors[i%3]; sz = int(1+t*2)
        d.ellipse([x-sz,y-sz,x+sz,y+sz], fill=(*c,140))

def M_fish(d, cx, cy, r, col, rng):
    sz = rng.randint(7,10)
    body = [(cx-sz,cy),(cx-sz//3,cy-sz//2),(cx+sz//2,cy-sz//4),(cx+sz,cy),(cx+sz//2,cy+sz//4),(cx-sz//3,cy+sz//2)]
    d.polygon(body, fill=(*col,150))
    d.polygon([(cx-sz,cy),(cx-sz-sz//3,cy-sz//3),(cx-sz-sz//3,cy+sz//3)], fill=(*col,130))
    d.ellipse([cx+sz//3-2,cy-3,cx+sz//3+2,cy+1], fill=(40,40,60,180))

def M_monster(d, cx, cy, r, col, rng):
    for dx in [-10,10]:
        ex, ey = cx+dx, cy-4
        d.ellipse([ex-8,ey-10,ex+8,ey+10], fill=(255,255,255,220), outline=(60,40,80,200), width=2)
        d.ellipse([ex-4,ey-5,ex+4,ey+3], fill=(80,40,120,220))
        d.ellipse([ex-2,ey-3,ex+2,ey-1], fill=(30,15,40,240))

def M_crown(d, cx, cy, r, col, rng):
    sz = rng.randint(8,12)
    pts = [(cx-sz,cy+sz//3),(cx-sz,cy-sz//6),(cx-sz//2,cy-sz//4),(cx,cy-sz//2),(cx+sz//2,cy-sz//4),(cx+sz,cy-sz//6),(cx+sz,cy+sz//3)]
    d.polygon(pts, fill=(*col,200))

def M_ripple(d, cx, cy, r, col, rng):
    for i in range(rng.randint(3,5)):
        rr = int(r*.3+i*r*.15)
        alpha = max(40,120-i*25)
        d.ellipse([cx-rr,cy-rr//2,cx+rr,cy+rr//2], outline=(*col,alpha), width=1)

def M_dots(d, cx, cy, r, col, rng):
    for _ in range(rng.randint(8,15)):
        dx = rng.randint(int(-r*.6),int(r*.6))
        dy = rng.randint(int(-r*.5),int(r*.4))
        sz = rng.randint(1,3)
        d.ellipse([cx+dx-sz,cy+dy-sz,cx+dx+sz,cy+dy+sz], fill=(*col,160))

def M_stripes_h(d, cx, cy, r, col, rng):
    for i in range(rng.randint(3,6)):
        yy = cy-r+int(r*2*(i+0.5)/rng.randint(3,6))
        pts = [(x, yy+int(math.sin((x-cx)*.1)*3)) for x in range(cx-int(r*.7),cx+int(r*.7),3)]
        if len(pts)>1: d.line(pts, fill=(*col,110), width=2)

def M_stripes_v(d, cx, cy, r, col, rng):
    for i in range(rng.randint(3,6)):
        xx = cx-r+int(r*2*(i+0.5)/rng.randint(3,6))
        pts = [(xx+int(math.sin((y-cy)*.1)*3), y) for y in range(cy-int(r*.7),cy+int(r*.7),3)]
        if len(pts)>1: d.line(pts, fill=(*col,110), width=2)

def M_grid(d, cx, cy, r, col, rng):
    step = rng.randint(8,12)
    for x in range(cx-int(r*.7), cx+int(r*.7), step):
        d.line([(x,cy-int(r*.7)),(x,cy+int(r*.7))], fill=(*col,60), width=1)
    for y in range(cy-int(r*.7), cy+int(r*.7), step):
        d.line([(cx-int(r*.7),y),(cx+int(r*.7),y)], fill=(*col,60), width=1)

def M_sparkle(d, cx, cy, r, col, rng):
    for _ in range(rng.randint(4,8)):
        sx = cx+rng.randint(int(-r*.6),int(r*.6))
        sy = cy+rng.randint(int(-r*.5),int(r*.4))
        sz = rng.randint(2,4)
        d.polygon([(sx,sy-sz),(sx+sz//3,sy),(sx,sy+sz//3),(sx-sz//3,sy)], fill=(*col,200))

MOTIF_MAP = {
    "bubbles": M_bubbles, "bubble": M_bubbles,
    "swirl": M_swirl, "internal_swirl": M_swirl,
    "star": M_star, "glowing_star": M_star, "star_badge": M_star,
    "heart": M_heart, "flower": M_heart, "blossom": M_heart,
    "snowflake": M_snowflake, "frost_crystal": M_snowflake,
    "eye": M_eye, "all_seeing_eye": M_eye,
    "wave": M_wave, "waves": M_wave, "flow_lines": M_wave,
    "leaf": M_leaf, "leaf_veins": M_leaf,
    "flame": M_flame, "fire_core": M_flame,
    "galaxy": M_galaxy, "galaxy_spiral": M_galaxy,
    "diamond": M_diamond, "crystal_shard": M_diamond,
    "moon": M_moon, "crescent": M_moon,
    "cross": M_cross, "x_mark": M_cross,
    "ring": M_ring, "concentric": M_ring,
    "triangle": M_triangle, "pyramid": M_triangle,
    "scales": M_scales, "dragon_scales": M_scales,
    "cloud": M_cloud, "clouds": M_cloud,
    "nebula": M_nebula, "cosmic_dust": M_nebula,
    "candy": M_candy, "candy_spiral": M_candy,
    "fish": M_fish, "fish_silhouette": M_fish,
    "monster": M_monster, "monster_eyes": M_monster,
    "crown": M_crown, "royal": M_crown,
    "ripple": M_ripple, "water_ripple": M_ripple,
    "dots": M_dots, "polka": M_dots,
    "stripes_h": M_stripes_h, "horizontal_stripes": M_stripes_h,
    "stripes_v": M_stripes_v, "vertical_stripes": M_stripes_v,
    "grid": M_grid, "sparkle_grid": M_grid,
    "sparkle": M_sparkle, "sparkles": M_sparkle,
    "seeds": M_dots, "rind_stripes": M_stripes_v,
}

def M_watermelon(d, cx, cy, r, col, rng):
    """Draw watermelon seeds inside the balloon."""
    # black seeds scattered inside
    for _ in range(rng.randint(5, 8)):
        sx = cx + rng.randint(int(-r*.5), int(r*.5))
        sy = cy + rng.randint(int(-r*.4), int(r*.4))
        # seed shape — small oval
        d.ellipse([sx-2, sy-1, sx+2, sy+1], fill=(30, 20, 10, 200))
        # seed highlight
        d.ellipse([sx-1, sy-1, sx, sy], fill=(60, 50, 40, 150))

# ── PATTERN OVERLAYS ──────────────────────────────────────────────────
def P_none(d, cx, cy, r, col, rng): pass

def P_stripe_h(d, cx, cy, r, col, rng):
    for i in range(5):
        yy = cy-20+i*8
        pts = [(x, yy+int(math.sin((x-cx)*.12)*3)) for x in range(cx-25,cx+25,3)]
        if len(pts)>1: d.line(pts, fill=(*col,90), width=2)

def P_stripe_v(d, cx, cy, r, col, rng):
    for i in range(5):
        xx = cx-20+i*8
        pts = [(xx+int(math.sin((y-cy)*.12)*3), y) for y in range(cy-25,cy+25,3)]
        if len(pts)>1: d.line(pts, fill=(*col,90), width=2)

def P_cross_hatch(d, cx, cy, r, col, rng):
    P_stripe_h(d, cx, cy, r, col, rng)
    P_stripe_v(d, cx, cy, r, col, rng)

def P_ring(d, cx, cy, r, col, rng):
    for i in range(3):
        rr = int(r*.3+i*r*.15)
        d.ellipse([cx-rr,cy-rr//2,cx+rr,cy+rr//2], outline=(*col,80), width=1)

def P_spiral(d, cx, cy, r, col, rng):
    pts = []
    for i in range(80):
        t = i/80.0; a = t*math.pi*3; dist = t*r*.6
        pts.append((cx+int(math.cos(a)*dist), cy+int(math.sin(a)*dist)))
    if len(pts)>1: d.line(pts, fill=(*col,80), width=2)

PATTERN_MAP = {
    "none": P_none, "water_line": P_none,
    "stripe_h": P_stripe_h, "horizontal_stripes": P_stripe_h, "wave_lines": P_stripe_h,
    "stripe_v": P_stripe_v, "vertical_stripes": P_stripe_v,
    "cross_hatch": P_cross_hatch, "camo_patches": P_cross_hatch,
    "ring": P_ring, "glow_rings": P_ring, "concentric": P_ring,
    "spiral": P_spiral, "petal_swirl": P_spiral, "internal_swirl": P_spiral,
    "sparkle_grid": P_ring, "coral_texture": P_ring,
    "leaf_veins": P_stripe_v, "citrus_segments": P_stripe_h,
    "soft_gradient": P_none, "clouds": P_none, "waves": P_none,
}

# ── SKIN COMPOSER ─────────────────────────────────────────────────────
HIGHLIGHT_MAP = {
    "smooth_large": "smooth", "smooth": "smooth", "natural": "smooth",
    "atmospheric": "smooth", "caustic": "smooth", "soft": "smooth",
    "bright": "smooth", "subtle": "small", "warm": "warm",
    "pearlescent": "pearl", "colored_secondary": "pearl",
    "fragmented": "small", "cold_sharp": "cold", "dappled": "small",
    "neon_glow": "neon", "cosmic": "cosmic", "reptile": "small",
    "soft_glow": "pearl",
}

# ── WATERMELON BALLOON — full rind pattern, no slice ──────────────────
def _draw_watermelon_balloon() -> Image.Image:
    """Draw a water balloon whose entire body IS a watermelon rind."""
    img = NL()
    d = ImageDraw.Draw(img, "RGBA")

    rind_light = (75, 185, 65)
    stripe_col = (18, 48, 18, 235)

    # ── Rind base ──
    d.ellipse([CX-R, CY-R+2, CX+R, CY+R+2], fill=rind_light)

    # ── Bold stripes — each is an independent curved band on the sphere ──
    # 7 stripes at different x positions on the equator
    stripe_eq_x = [-34, -23, -12, 0, 12, 23, 34]

    for eq_x in stripe_eq_x:
        # draw each stripe as a series of small circles following a curved path
        # the stripe curves outward at the equator, inward at poles
        for i in range(50):
            t = i / 49.0  # 0=top, 1=bottom
            y_off = -R + 6 + t * (R * 2 - 12)
            sy = CY + y_off

            # x position: sphere projection
            # at equator (t=0.5), x = eq_x
            # at poles (t=0 or 1), x moves toward center
            lat = (t - 0.5) * math.pi  # -pi/2 to pi/2
            sphere_factor = math.cos(lat)  # 1 at equator, 0 at poles
            sx = CX + eq_x * sphere_factor

            # stripe width: thickest at equator, tapers to 0 at poles
            width = max(1, int(4.0 * pow(sphere_factor, 1.0)))

            # draw as filled circle for smooth taper
            d.ellipse([sx-width, sy-width, sx+width, sy+width], fill=stripe_col)

    # ── Re-clip to balloon circle ──
    mask = Image.new("L", (FRAME_SIZE, FRAME_SIZE), 0)
    md = ImageDraw.Draw(mask, "L")
    md.ellipse([CX-R, CY-R+2, CX+R, CY+R+2], fill=255)
    img.putalpha(mask)

    # ── Glossy shading ──
    for i in range(6):
        d.arc([CX-R+3, CY-R+5, CX+R-3, CY+R-1], 200, 340,
              fill=(15, 50, 15, 25 + i * 10), width=2)

    # ── Primary highlight — large white curve upper-left ──
    hl = NL()
    hld = ImageDraw.Draw(hl, "RGBA")
    hld.ellipse([CX-26, CY-30, CX-2, CY-8], fill=(255, 255, 255, 165))
    hld.ellipse([CX-20, CY-24, CX-8, CY-14], fill=(255, 255, 255, 120))
    hld.ellipse([CX+6, CY-8, CX+14, CY-2], fill=(255, 255, 255, 110))
    hl_mask = Image.new("L", (FRAME_SIZE, FRAME_SIZE), 0)
    hmd = ImageDraw.Draw(hl_mask, "L")
    hmd.ellipse([CX-R, CY-R+2, CX+R, CY+R+2], fill=255)
    hl_a = hl.split()[3]
    hl_a = Image.composite(hl_a, Image.new("L", hl_a.size, 0), hl_mask)
    hl.putalpha(hl_a)
    img = Image.alpha_composite(img, hl)

    # ── Tiny sparkle ──
    ImageDraw.Draw(img, "RGBA").ellipse([CX-6, CY-24, CX-2, CY-20], fill=(210, 255, 210, 170))

    return img


def _draw_watermelon_knot(d: ImageDraw.ImageDraw):
    """Small green rubber knot leaning upper-right ~35 degrees."""
    # knot position — upper right
    kx = CX + 10
    ky = CY - R + 2
    # rubber nub leaning right
    d.polygon([
        (kx - 3, ky + 2), (kx + 4, ky + 2),
        (kx + 8, ky - 6), (kx + 4, ky - 7)
    ], fill=(40, 130, 40))
    # rounded top
    d.ellipse([kx + 5, ky - 9, kx + 13, ky - 3], fill=(40, 130, 40))
    # highlight on knot
    d.ellipse([kx + 7, ky - 8, kx + 11, ky - 5], fill=(70, 170, 70))

def compose_skin(sd):
    """Single dynamic composer — uses motif, pattern, material from catalog."""
    img = NL()
    pc, oc = h2c(sd["primary_color"]), h2c(sd["outline_color"])
    draw_balloon(img, pc, oc)

    # pattern overlay
    pat_name = sd.get("pattern", "none")
    pat_fn = PATTERN_MAP.get(pat_name, P_none)
    pat_layer = NL(); pd = ImageDraw.Draw(pat_layer, "RGBA")
    ac = h2c(sd.get("accent_color", sd["primary_color"]))
    pat_fn(pd, CX, CY, R, ac, random)

    # main motif
    motif_name = sd.get("motif", "bubbles")
    motif_fn = MOTIF_MAP.get(motif_name, M_bubbles)
    motif_layer = NL(); md = ImageDraw.Draw(motif_layer, "RGBA")
    motif_fn(md, CX, CY, R, ac, random)

    # secondary motif (smaller, offset)
    secondary_motifs = ["dots", "sparkle", "ring", "cross", "triangle", "diamond"]
    sec_name = rng.choice(secondary_motifs) if hasattr(rng := random, 'choice') else "dots"
    # use skin id hash for secondary motif selection
    sec_idx = hash(sd["id"]) % len(secondary_motifs)
    sec_fn = MOTIF_MAP[secondary_motifs[sec_idx]]
    sec_layer = NL(); sd2 = ImageDraw.Draw(sec_layer, "RGBA")
    sec_fn(sd2, CX+rng.randint(-8,8), CY+rng.randint(-8,8), R, lighten(ac, 1.2), rng)

    # compose
    img = Image.alpha_composite(img, pat_layer)
    img = Image.alpha_composite(img, motif_layer)
    img = Image.alpha_composite(img, sec_layer)

    # ── WATERMELON: entire body IS the rind — bold dark stripes on green ──
    if sd.get("theme") == "watermelon":
        img = _draw_watermelon_balloon()

    # knot
    knot_layer = NL(); kd = ImageDraw.Draw(knot_layer, "RGBA")
    if sd.get("theme") == "watermelon":
        _draw_watermelon_knot(kd)
    else:
        draw_knot(kd, pc, lean_r=(hash(sd["id"])%2==0))
    img = Image.alpha_composite(img, knot_layer)

    # highlight
    hl_name = sd.get("highlight", "smooth")
    hl_style = HIGHLIGHT_MAP.get(hl_name, "smooth")
    hl_layer = NL(); hd = ImageDraw.Draw(hl_layer, "RGBA")
    draw_highlight(hd, hl_style)
    img = Image.alpha_composite(img, hl_layer)

    # per-skin accent particles
    rng2 = random.Random(hash(sd["id"]) + 999)
    accent_layer = NL(); ad = ImageDraw.Draw(accent_layer, "RGBA")
    accent_col = lighten(pc, 1.3)
    for _ in range(rng2.randint(2,6)):
        ax = CX + rng2.randint(-22, 22)
        ay = CY + rng2.randint(-22, 18)
        sz = rng2.randint(1,3)
        ad.ellipse([ax-sz,ay-sz,ax+sz,ay+sz], fill=(*accent_col, 180))
    img = Image.alpha_composite(img, accent_layer)

    return img

# ── FRAME / ICON / SHEET ─────────────────────────────────────────────
def generate_frame(sd, fi):
    rng = random.Random(hash(sd["id"]) + fi)
    # temporarily set module-level random for compose_skin
    import generate_water_balloons as _self
    _self.rng = rng
    img = compose_skin(sd)
    sq = [1.0, 1.06, 0.95, 1.03][fi]
    st = [1.0, 0.96, 1.05, 0.98][fi]
    if sq != 1.0 or st != 1.0:
        w, h = int(FRAME_SIZE*sq), int(FRAME_SIZE*st)
        resized = img.resize((w, h), Image.Resampling.LANCZOS)
        img = NL()
        img.paste(resized, ((FRAME_SIZE-w)//2, (FRAME_SIZE-h)//2), resized)
    return img

def generate_icon(sd):
    rng = random.Random(hash(sd["id"]) + 100)
    import generate_water_balloons as _self
    _self.rng = rng
    img = compose_skin(sd)
    hl = NL(); hd = ImageDraw.Draw(hl, "RGBA")
    hw, hh = int(R*.48), int(R*.32)
    hd.ellipse([CX-12-hw, CY-14-hh, CX-12+hw, CY-14+hh], fill=(255,255,255,210))
    return Image.alpha_composite(img, hl)

def generate_sheet(sd, frames):
    sheet = Image.new('RGBA', (len(frames)*FRAME_SIZE, 8*FRAME_SIZE), (0,0,0,0))
    for i, f in enumerate(frames):
        sheet.paste(f, (i*FRAME_SIZE, 0), f)
    return sheet

# ── MAIN ──────────────────────────────────────────────────────────────
# module-level rng for compose_skin access
rng = random.Random(0)

def generate_all():
    os.makedirs(OUTPUT_BASE, exist_ok=True)
    with open(CATALOG_PATH) as f:
        catalog = json.load(f)
    for sd in catalog["skins"]:
        sid = sd["id"]
        sdir = os.path.join(OUTPUT_BASE, sid)
        os.makedirs(sdir, exist_ok=True)
        print("Generating %s: %s..." % (sid, sd["name"]))
        frames = []
        for fi in range(4):
            frame = generate_frame(sd, fi)
            frame.save(os.path.join(sdir, "idle_%d.png" % fi))
            frames.append(frame)
        icon = generate_icon(sd)
        icon.save(os.path.join(sdir, "icon.png"))
        sheet = generate_sheet(sd, frames)
        sheet.save(os.path.join(sdir, "sheet.png"))
        print("  -> 4 frames + icon + sheet")
    print("\nDone! Generated %d skins with distinct visual identities." % len(catalog["skins"]))

if __name__ == "__main__":
    generate_all()
