# Boom Water Arcade — Tileset & Environment Style Guide
**Version 2.0 — Authentic Cute 2.5D Korean Arcade Map Architecture**

---

## 1. Universal Environment Standards

### 1.1 Logical Grid & Pixel Density
- **Logical Tile Size**: $40 \times 40$ pixels.
- **Rendering Perspective**: Elevated 2.5D near-top-down arcade perspective (showing clear top surface, front face depth, and subtle contact shadow).
- **Master Texture Resolution**: $160 \times 160$ px supersampled down to $40 \times 40$ px with Lanczos anti-aliasing for razor-sharp, clean edges without blurriness.

### 1.2 Universal Lighting & Shadow
- **Key Light**: Upper-Left light source ($\vec{L} = (-0.58, -0.62, 0.53)$).
- **Highlights**: Upper-left and top edge bevels.
- **Ambient Shadows**: Fall lower-right, soft dark navy/ambient tone (never harsh pure black).
- **Continuous Shadow Rule**: Connected walls and blocks share a unified perimeter shadow rather than per-tile rectangular boxes.

### 1.3 Visual Hierarchy & Contrast
1. **Characters & Water Balloons** (Highest contrast, vibrant, sharp silhouette)
2. **Water Blast Waves & Danger Zones** (Bright, thick, saturated cyan/blue)
3. **Items & Pickups** (Crisp, glowing, floating bounce)
4. **Destructible Blocks / Cargo Crates** (Medium-high contrast, obvious breakable material)
5. **Solid Walls & Structures** (Medium contrast, heavy, grounded, connected)
6. **Floor / Terrain** (Lowest contrast, calm, seamless, non-distracting)

---

## 2. Terrain & Flooring System

### 2.1 The "Zero Square Box" Rule
- Floor tiles MUST be 100% seamless across all 4 edges.
- **NEVER** draw borders, dark outlines, or beveled card frames around floor tiles.
- When 10 floor tiles are placed adjacent to each other, they merge seamlessly into **ONE continuous terrain surface**.

### 2.2 Variation System
- **`floor_base`**: Clean, smooth, seamless primary material.
- **`floor_alt1`**: Subtle grain / surface wear.
- **`floor_alt2`**: Small decorative accent (pebble, scratch, sparkle, sand wave).
- **`floor_detail`**: Occasional landmark tile (inscribed stone, flower tuft, frost star).

---

## 3. Connected Wall & Border System (Autotiling)

### 3.1 Adjacency & Interior Contour Elimination
- Connected solid walls merge into single architectural structures.
- **Exterior Silhouette**: Defined 2px dark outline + top bevel highlight + bottom shadow.
- **Interior Seams**: Seamless blend or subtle panel groove (no double borders `|WALL||WALL|`).

### 3.2 16-State Bitmask Adjacency Matrix
- `single`: Isolated pillar/column.
- `h_middle`: Horizontal continuous wall segment.
- `v_middle`: Vertical continuous wall segment.
- `end_left`, `end_right`, `end_top`, `end_bottom`: Terminal wall caps with rounded 2.5D corners.
- `corner_tl`, `corner_tr`, `corner_bl`, `corner_br`: Outer corner blocks.
- `t_up`, `t_down`, `t_left`, `t_right`: T-junction intersections.
- `cross`: 4-way intersection.
- `solid_center`: Fully surrounded interior wall block.

---

## 4. Destructible Blocks (Cargo Crates & Ice Blocks)

### 4.1 Material Language
- **Destructible**: Wooden cargo crates, translucent cyan ice blocks, yellow toy storage boxes.
- **Indestructible**: Heavy granite stone, fortified navy steel, frozen obsidian pillars.

### 4.2 Crate Cluster Cohesion
- Crates maintain individual gameplay cell identities but share identical lighting angle, top-plane brightness, and ground baseline.
- 4 subtle visual variants (`crate_A`, `crate_B`, `crate_C`, `crate_damaged`) distribute pseudo-randomly across large groups to break visual repetition.

---

## 5. Theme Palette & Material Specifications

### 5.1 Desert / Treasure Arena (`egypt_temple` / `pirate_harbor`)
- **Floor**: Warm golden sand / smoothed sandstone (`#d9aa62` / `#c8964e`).
- **Walls**: Golden sandstone temple blocks with teal/navy masonry accents.
- **Destructibles**: Warm oak/teak cargo crates with brass reinforced corners.
- **Props**: Treasure chests, palm fronds, grooved stone pillars.

### 5.2 Ice Labyrinth (`ice_labyrinth` / `snow_village`)
- **Floor**: Cool deep cobalt-blue ice floor (`#244d7e` / `#1c3e66`), low contrast to ensure water blasts remain ultra-visible.
- **Walls**: Heavy frozen navy stone with cyan crystal crystalline rims.
- **Destructibles**: Translucent cyan cartoon ice blocks with white frost glints.
- **Props**: Snow-dusted pine, ice stalagmites, crystal clusters.

### 5.3 Toy Brick City (`lego_city`)
- **Floor**: Soft lawn green (`#4cae52`) and slate gray-blue pavement (`#4e6378`).
- **Walls**: Rounded warm red toy brick structures (`#c83232`).
- **Destructibles**: Golden/yellow toy storage crates (`#e6b828`).
- **Props**: Miniature toy houses, street lamps, clock towers.

---

## 6. Multi-Tile Object Standard
- Objects spanning multiple grid cells (e.g. $2 \times 2, 3 \times 3$) must be rendered at exact multiples of the 40px grid ($80 \times 80, 120 \times 120$) with origin anchored to the ground baseline.
