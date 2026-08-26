#!/usr/bin/env python3
"""
SpriteFrames .tres Generator for Water Balloon Skins
Creates Godot SpriteFrames resources from generated balloon PNGs.
"""
import json
import os

CATALOG_PATH = os.path.join(os.path.dirname(__file__), "..", "assets", "water_balloons", "water_balloon_catalog.json")
SKINS_BASE = os.path.join(os.path.dirname(__file__), "..", "assets", "water_balloons", "skins")

def tex_ext(id_val, path):
    return '[ext_resource type="Texture2D" path="' + path + '" id="' + id_val + '"]'

def tex_ref(id_val):
    return 'ExtResource("' + id_val + '")'

def frame_entry(tex_id, duration=1.0):
    return '{"duration": ' + str(duration) + ', "texture": ' + tex_ref(tex_id) + '}'

def anim_block(name, tex_ids, loop=True, speed=6.0):
    frames = ", ".join([frame_entry(tid) for tid in tex_ids])
    return '{' + '"frames": [' + frames + '], "loop": ' + ("true" if loop else "false") + ', "name": &' + repr(name) + ', "speed": ' + str(speed) + '}'

def generate_frames_tres(skin_id):
    skin_dir = os.path.join(SKINS_BASE, skin_id)
    tres_path = os.path.join(skin_dir, skin_id + "_frames.tres")
    
    idle_texs = []
    for i in range(4):
        idle_texs.append("res://assets/water_balloons/skins/" + skin_id + "/idle_" + str(i) + ".png")
    
    lines = []
    lines.append('[gd_resource type="SpriteFrames" format=3]')
    lines.append('')
    for i in range(4):
        lines.append(tex_ext("idle_" + str(i), idle_texs[i]))
    lines.append('')
    lines.append('[resource]')
    
    anims = []
    anims.append(anim_block("idle", ["idle_0", "idle_1", "idle_2", "idle_3"], True, 6.0))
    anims.append(anim_block("place", ["idle_0", "idle_1"], False, 10.0))
    anims.append(anim_block("squash", ["idle_0", "idle_1", "idle_2"], False, 12.0))
    anims.append(anim_block("rebound", ["idle_2", "idle_1", "idle_0"], False, 12.0))
    anims.append(anim_block("wobble_slow", ["idle_0", "idle_1", "idle_2", "idle_3"], True, 3.0))
    anims.append(anim_block("wobble_medium", ["idle_0", "idle_1", "idle_2", "idle_3"], True, 8.0))
    anims.append(anim_block("wobble_fast", ["idle_0", "idle_1", "idle_2", "idle_3"], True, 14.0))
    anims.append(anim_block("warning", ["idle_1", "idle_2"], True, 16.0))
    anims.append(anim_block("pre_pop", ["idle_2", "idle_3"], False, 20.0))
    anims.append(anim_block("burst_start", ["idle_3"], False, 1.0))
    anims.append(anim_block("burst_peak", ["idle_3"], False, 1.0))
    anims.append(anim_block("burst_end", ["idle_0"], False, 1.0))
    
    lines.append('animations = [' + ', '.join(anims) + ']')
    
    with open(tres_path, 'w') as f:
        f.write('\n'.join(lines) + '\n')
    
    return tres_path

def hex_to_float_r(hex_str):
    hex_str = hex_str.lstrip('#')
    return round(int(hex_str[0:2], 16) / 255.0, 4)

def hex_to_float_g(hex_str):
    hex_str = hex_str.lstrip('#')
    return round(int(hex_str[2:4], 16) / 255.0, 4)

def hex_to_float_b(hex_str):
    hex_str = hex_str.lstrip('#')
    return round(int(hex_str[4:6], 16) / 255.0, 4)

def generate_definition_tres(skin_id, skin_data):
    skin_dir = os.path.join(SKINS_BASE, skin_id)
    tres_path = os.path.join(skin_dir, skin_id + "_definition.tres")
    
    icon_path = "res://assets/water_balloons/skins/" + skin_id + "/icon.png"
    frames_path = "res://assets/water_balloons/skins/" + skin_id + "/" + skin_id + "_frames.tres"
    
    pc = skin_data.get("primary_color", "#ffffff")
    sc = skin_data.get("secondary_color", "#ffffff")
    oc = skin_data.get("outline_color", "#000000")
    
    lines = [
        '[gd_resource type="Resource" script_class="WaterBalloonSkinDefinition" format=3]',
        '',
        '[ext_resource type="Texture2D" path="' + icon_path + '" id="icon"]',
        '[ext_resource type="SpriteFrames" path="' + frames_path + '" id="frames"]',
        '',
        '[resource]',
        'script = ExtResource("icon")',
        'id = &' + repr(skin_id),
        'display_name = "' + skin_data["name"].upper() + '"',
        'theme = "' + skin_data.get("theme", "basic") + '"',
        'primary_color = Color(' + str(hex_to_float_r(pc)) + ', ' + str(hex_to_float_g(pc)) + ', ' + str(hex_to_float_b(pc)) + ', 1)',
        'secondary_color = Color(' + str(hex_to_float_r(sc)) + ', ' + str(hex_to_float_g(sc)) + ', ' + str(hex_to_float_b(sc)) + ', 1)',
        'outline_color = Color(' + str(hex_to_float_r(oc)) + ', ' + str(hex_to_float_g(oc)) + ', ' + str(hex_to_float_b(oc)) + ', 1)',
        'motif = "' + skin_data.get("motif", "basic") + '"',
        'description = "' + skin_data.get("description", "") + '"',
        'rarity = "' + skin_data.get("rarity", "common") + '"',
        'price = ' + str(skin_data.get("price", 0)),
        'vfx_profile = "' + skin_data.get("vfx_profile", "water_default") + '"',
        'burst_accent = "' + skin_data.get("burst_accent", "blue_splash") + '"',
        'icon = ExtResource("icon")',
        'sprite_frames = ExtResource("frames")',
        'unlocked = false',
    ]
    
    with open(tres_path, 'w') as f:
        f.write('\n'.join(lines) + '\n')
    
    return tres_path

def generate_all():
    with open(CATALOG_PATH) as f:
        catalog = json.load(f)
    
    for skin in catalog["skins"]:
        skin_id = skin["id"]
        print("Generating .tres for " + skin_id + "...")
        frames_path = generate_frames_tres(skin_id)
        def_path = generate_definition_tres(skin_id, skin)
        print("  -> " + frames_path)
        print("  -> " + def_path)
    
    print("\nDone! Generated .tres files for " + str(len(catalog["skins"])) + " skins.")

if __name__ == "__main__":
    generate_all()
