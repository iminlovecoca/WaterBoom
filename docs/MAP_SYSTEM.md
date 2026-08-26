# Map System

`MapDefinition` contains ID, display name, dimensions, tile size, spawn points, player limit, deterministic layout seed/density, drop rate, theme, colors, and optional preview.

`MapCatalog` creates eight original 16×16 development maps: Training Plaza, Aqua Park, Pirate Harbor, Snow Village, Neon Arcade, Toy Brick City, Ice Labyrinth, and Egypt Temple. `MapLayoutBuilder` gives each one a separate terrain signature instead of recoloring one shared grid. The authored quadrant is mirrored horizontally and vertically, so permanent walls, destructible density, terrain details, and routes stay equally weighted in all four corners while each theme keeps its own recognizable layout. Every layout provides eight safe spawn slots and remains permanently connected when destructible blocks are cleared.

Each map theme is resolved by `MapThemeCatalog` and has four dedicated 40x40 runtime textures: base floor, alternate floor, indestructible hard block, and destructible soft block. The alternate floor is distributed deterministically from the map seed, so clients render the same decoration pattern without network data. Runtime art lives under `assets/tilesets/<map>/runtime`; generated masters and QA previews are retained in ignored `source` and `processed` folders and are not imported into game builds.

`MapDecorationCatalog` gives every map one exact 3×3 centerpiece and four grid-locked landmarks. Small props occupy one honest cell and render at 54×54 so they remain readable without stealing a movement lane; Toy Brick City's deliberately large shrubs retain their symmetric 2×2 footprints. Odd-sized centerpieces receive a half-tile visual correction on the even 16×16 board, placing them on the true arena center. The outer hard-wall ring has no floor texture beneath it. Every occupied decoration cell remains a real hard-wall cell, so visuals and gameplay collision agree.

Run `python tools/build_map_tilesets.py` after replacing a generated master sheet. The builder extracts the strict 2x2 sheet, creates seamless mirrored floors, removes the presentation background from block art, scales every tile to 40x40, and updates the validation contact sheet and hash manifest.

Run `python tools/build_map_decorations.py` after replacing a decoration master. It extracts four quadrants, removes the neutral extraction background, fits transparent 128x128 sprites, and refreshes the decoration QA sheet.

`MatchFrameUI` draws the full-screen blue arcade cabinet frame behind gameplay. On the 960×720 baseline, the arena starts at the left frame and fills every pixel up to a two-pixel divider; the 292-pixel player sidebar is anchored directly to the right frame and never stretches. It uses one full-size column for up to four solo players or eight compact rows for team mode, showing animated portraits, nicknames, and live state without power/speed/range stat lines. The local player's capacity appears at the upper-left as a balloon icon and `BOOM ×N`. `MatchHUD` aligns its countdown, result modal, and pause modal to the left playfield; the old bottom stat strip is hidden.

`MapValidator` rejects invalid dimensions, layout height, out-of-bounds/duplicate/blocked spawns, excessive spawn count, and spawns with fewer than two exits. `MatchManager` refuses invalid maps before simulation.

The room lobby exports a 384×216 preview for each map. The current preview is a real `TextureButton`; clicking it opens the complete 4×2 selection panel inside the existing arcade frame. Every map is a separate interactive card with a 16:9 thumbnail, footer, badge, selected border, hover lift, pressed state, and shadow—none of these controls are baked button pictures.
