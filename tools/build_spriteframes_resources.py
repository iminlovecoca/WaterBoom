import os

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

def generate_bazzi_spriteframes_tres():
    tres_path = os.path.join(BASE_DIR, "resources", "characters", "bazzi_frames.tres")
    
    anims = {
        "idle": ["res://assets/characters/bazzi/idle.png"],
        "walk_down": [f"res://assets/characters/bazzi/walk_down_{i}.png" for i in range(4)],
        "walk_up": [f"res://assets/characters/bazzi/walk_up_{i}.png" for i in range(4)],
        "walk_left": [f"res://assets/characters/bazzi/walk_left_{i}.png" for i in range(4)],
        "walk_right": [f"res://assets/characters/bazzi/walk_right_{i}.png" for i in range(4)],
        "plant": [f"res://assets/characters/bazzi/plant_{i}.png" for i in range(2)],
        "hurt": [f"res://assets/characters/bazzi/hurt_{i}.png" for i in range(2)],
        "die": [f"res://assets/characters/bazzi/die_{i}.png" for i in range(4)]
    }
    
    ext_resources = []
    ext_map = {}
    idx = 1
    for anim_name, frames in anims.items():
        for frame_path in frames:
            if frame_path not in ext_map:
                res_id = f"{idx}_tex"
                ext_map[frame_path] = res_id
                ext_resources.append(f'[ext_resource type="Texture2D" uid="uid://char_tex_{idx}" path="{frame_path}" id="{res_id}"]')
                idx += 1
                
    anim_blocks = []
    for anim_name, frames in anims.items():
        frame_entries = []
        for frame_path in frames:
            res_id = ext_map[frame_path]
            frame_entries.append(f'{{\n"duration": 1.0,\n"texture": ExtResource("{res_id}")\n}}')
        frames_joined = ",\n".join(frame_entries)
        speed = 8.0 if anim_name.startswith("walk") else 5.0
        loop = "false" if anim_name in ["plant", "die"] else "true"
        block = f'{{\n"frames": [\n{frames_joined}\n],\n"loop": {loop},\n"name": &"{anim_name}",\n"speed": {speed}\n}}'
        anim_blocks.append(block)
        
    all_anims = ",\n".join(anim_blocks)
    
    content = f"""[gd_resource type="SpriteFrames" load_steps={len(ext_resources) + 1} format=3]

{chr(10).join(ext_resources)}

[resource]
animations = [
{all_anims}
]
"""
    with open(tres_path, "w", encoding="utf-8") as f:
        f.write(content)
    print("Generated bazzi_frames.tres")

def generate_bazzi_character_tres():
    tres_path = os.path.join(BASE_DIR, "resources", "characters", "bazzi.tres")
    content = """[gd_resource type="Resource" script_class="CharacterDefinition" load_steps=4 format=3]

[ext_resource type="Script" path="res://resources/characters/CharacterDefinition.gd" id="1_script"]
[ext_resource type="SpriteFrames" path="res://resources/characters/bazzi_frames.tres" id="2_frames"]
[ext_resource type="Texture2D" path="res://assets/characters/bazzi/idle.png" id="3_preview"]

[resource]
script = ExtResource("1_script")
id = "bazzi"
display_name = "Bazzi"
base_speed = 160.0
base_water_balloon_capacity = 1
base_water_power = 1
max_speed = 280.0
max_water_balloon_capacity = 8
max_water_power = 8
sprite_frames = ExtResource("2_frames")
preview_texture = ExtResource("3_preview")
shadow_offset_y = 12.0
"""
    with open(tres_path, "w", encoding="utf-8") as f:
        f.write(content)
    print("Generated bazzi.tres")

if __name__ == "__main__":
    generate_bazzi_spriteframes_tres()
    generate_bazzi_character_tres()
