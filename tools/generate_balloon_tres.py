#!/usr/bin/env python3
"""
Generate Godot SpriteFrames .tres and definition .tres for each extracted balloon skin.
Replaces procedural generator with real Crazy Arcade balloon art.
"""
import json, os

CATALOG_PATH = os.path.join(os.path.dirname(__file__), "..", "assets", "water_balloons", "water_balloon_catalog.json")
SPRITE_DIR = os.path.join(os.path.dirname(__file__), "..", "assets", "water_balloons", "balloon_sprites")
SKINS_DIR = os.path.join(os.path.dirname(__file__), "..", "assets", "water_balloons", "skins")

def gen_frames_tres(skin_id, balloon_index=0):
    out_dir = os.path.join(SKINS_DIR, skin_id)
    os.makedirs(out_dir, exist_ok=True)
    tres_path = os.path.join(out_dir, f"{skin_id}_frames.tres")

    lines = [
        "[gd_resource type=\"SpriteFrames\" format=3]",
        "",
        f"[ext_resource type=\"Texture2D\" path=\"res://assets/water_balloons/balloon_sprites/balloon_{balloon_index:03d}.png\" id=\"f0\"]",
        "",
        "[resource]",
        "animations = [{",
        "\"frames\": [{",
        "\"duration\": 1.0,",
        "\"texture\": ExtResource(\"f0\")",
        "}],",
        "\"loop\": true,",
        "&\"idle\": true,",
        "\"name\": &\"idle\",",
        "\"speed\": 8.0",
        "}]",
    ]

    with open(tres_path, "w") as f:
        f.write("\n".join(lines))
    return tres_path


def gen_def_tres(skin_id, skin_data, balloon_index):
    out_dir = os.path.join(SKINS_DIR, skin_id)
    os.makedirs(out_dir, exist_ok=True)
    tres_path = os.path.join(out_dir, f"{skin_id}_definition.tres")

    display_name = skin_data.get("name", skin_id)
    rarity = skin_data.get("rarity", "common")
    price = skin_data.get("price", 0)
    description = skin_data.get("description", "")
    theme = skin_data.get("theme", "basic")
    vfx_profile = skin_data.get("vfx_profile", "water_default")
    burst_accent = skin_data.get("burst_accent", "blue_splash")
    motif = skin_data.get("motif", "basic")
    primary_color = _hex_to_godot_color(skin_data.get("primary_color", "#ffffff"))
    secondary_color = _hex_to_godot_color(skin_data.get("secondary_color", "#ffffff"))
    outline_color = _hex_to_godot_color(skin_data.get("outline_color", "#000000"))
    balloon_path = f"res://assets/water_balloons/balloon_sprites/balloon_{balloon_index:03d}.png"

    lines = [
        "[gd_resource type=\"Resource\" script_class=\"WaterBalloonSkinDefinition\" format=3]",
        "",
        f"[ext_resource type=\"Script\" path=\"res://scripts/water_balloon/WaterBalloonSkinDefinition.gd\" id=\"1\"]",
        f"[ext_resource type=\"Texture2D\" path=\"{balloon_path}\" id=\"tex1\"]",
        f"[ext_resource type=\"SpriteFrames\" path=\"res://assets/water_balloons/skins/{skin_id}/{skin_id}_frames.tres\" id=\"frames1\"]",
        "",
        "[resource]",
        "script = ExtResource(\"1\")",
        f"id = &\"{skin_id}\"",
        f"display_name = \"{display_name}\"",
        f"theme = \"{theme}\"",
        f"primary_color = Color({primary_color})",
        f"secondary_color = Color({secondary_color})",
        f"outline_color = Color({outline_color})",
        f"motif = \"{motif}\"",
        f"description = \"{description}\"",
        f"rarity = \"{rarity}\"",
        f"price = {price}",
        f"vfx_profile = \"{vfx_profile}\"",
        f"burst_accent = \"{burst_accent}\"",
        "icon = ExtResource(\"tex1\")",
        "sprite_frames = ExtResource(\"frames1\")",
    ]

    with open(tres_path, "w") as f:
        f.write("\n".join(lines))
    return tres_path


def _hex_to_godot_color(hex_color):
    hex_color = hex_color.lstrip('#')
    if len(hex_color) == 3:
        hex_color = ''.join(c * 2 for c in hex_color)
    r = int(hex_color[0:2], 16)
    g = int(hex_color[2:4], 16)
    b = int(hex_color[4:6], 16)
    return f"{r/255:.4f}, {g/255:.4f}, {b/255:.4f}"


def main():
    data = json.load(open(CATALOG_PATH))

    # Map extracted balloons to skins
    # We have 63 balloons (0-62) and 62 skins (skin_001 to skin_062)
    # skin_001 = classic = balloon_000
    # skin_062 = watermelon = balloon_062 (last one)

    import shutil
    results = []
    for i, skin in enumerate(data["skins"]):
        skin_id = skin["id"]
        balloon_idx = i  # Direct 1:1 mapping
        if balloon_idx > 62:
            balloon_idx = 62  # Clamp to last balloon

        frame_path = gen_frames_tres(skin_id, balloon_idx)
        def_path = gen_def_tres(skin_id, skin, balloon_idx)

        # Copy extracted balloon as icon.png for this skin
        skin_dir = os.path.join(SKINS_DIR, skin_id)
        icon_src = os.path.join(SPRITE_DIR, f"balloon_{balloon_idx:03d}.png")
        icon_dst = os.path.join(skin_dir, "icon.png")
        if os.path.exists(icon_src):
            shutil.copy2(icon_src, icon_dst)

        results.append(f"  {skin_id} -> balloon_{balloon_idx:03d}.png")

    # Also copy balloon_000.png as the default water_balloon_0.png
    src = os.path.join(SPRITE_DIR, "balloon_000.png")
    dst = os.path.join(os.path.dirname(SPRITE_DIR), "water_balloon_0.png")
    if os.path.exists(src):
        shutil.copy2(src, dst)
        results.append(f"  water_balloon_0.png <- balloon_000.png")

    print(f"Generated {len(data['skins'])} skin definitions:")
    for r in results:
        print(r)


if __name__ == "__main__":
    main()
