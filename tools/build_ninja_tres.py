import os

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

def generate_ninja_resources():
    tres_path = os.path.join(BASE_DIR, "resources", "characters", "ninja_frames.tres")
    
    anims = {
        "idle": [f"res://assets/characters/ninja/idle_{i}.png" for i in range(7)],
        "walk_down": [f"res://assets/characters/ninja/walk_down_{i}.png" for i in range(7)],
        "walk_up": [f"res://assets/characters/ninja/walk_up_{i}.png" for i in range(7)],
        "walk_left": [f"res://assets/characters/ninja/walk_left_{i}.png" for i in range(7)],
        "walk_right": [f"res://assets/characters/ninja/walk_right_{i}.png" for i in range(7)],
        "plant": [f"res://assets/characters/ninja/plant_{i}.png" for i in range(6)],
        "pickup": [f"res://assets/characters/ninja/pickup_{i}.png" for i in range(6)],
        "hurt": [f"res://assets/characters/ninja/hurt_{i}.png" for i in range(6)],
        "die": [f"res://assets/characters/ninja/die_{i}.png" for i in range(5)]
    }
    
    ext_resources = []
    ext_map = {}
    idx = 1
    for anim_name, frames in anims.items():
        for frame_path in frames:
            if frame_path not in ext_map:
                res_id = f"{idx}_tex"
                ext_map[frame_path] = res_id
                ext_resources.append(f'[ext_resource type="Texture2D" uid="uid://ninja_tex_{idx}" path="{frame_path}" id="{res_id}"]')
                idx += 1
                
    anim_blocks = []
    for anim_name, frames in anims.items():
        frame_entries = []
        for frame_path in frames:
            res_id = ext_map[frame_path]
            frame_entries.append(f'{{\n"duration": 1.0,\n"texture": ExtResource("{res_id}")\n}}')
        frames_joined = ",\n".join(frame_entries)
        speed = 10.0 if anim_name.startswith("walk") else (6.0 if anim_name == "idle" else 8.0)
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
        
    # Also write to bazzi_frames.tres for backward-compatibility
    bazzi_frames_path = os.path.join(BASE_DIR, "resources", "characters", "bazzi_frames.tres")
    with open(bazzi_frames_path, "w", encoding="utf-8") as f:
        f.write(content)
        
    print("Generated ninja_frames.tres & bazzi_frames.tres")

    # Write Character Definition Resource
    char_tres = """[gd_resource type="Resource" script_class="CharacterDefinition" load_steps=4 format=3]

[ext_resource type="Script" path="res://resources/characters/CharacterDefinition.gd" id="1_script"]
[ext_resource type="SpriteFrames" path="res://resources/characters/ninja_frames.tres" id="2_frames"]
[ext_resource type="Texture2D" path="res://assets/ui/avatar_ninja_0.png" id="3_preview"]

[resource]
script = ExtResource("1_script")
id = "ninja"
display_name = "Shadow Ninja"
base_speed = 160.0
base_water_balloon_capacity = 1
base_water_power = 1
max_speed = 280.0
max_water_balloon_capacity = 8
max_water_power = 8
sprite_frames = ExtResource("2_frames")
preview_texture = ExtResource("3_preview")
shadow_offset_y = 10.0
"""
    ninja_res_path = os.path.join(BASE_DIR, "resources", "characters", "ninja.tres")
    with open(ninja_res_path, "w", encoding="utf-8") as f:
        f.write(char_tres)
        
    bazzi_res_path = os.path.join(BASE_DIR, "resources", "characters", "bazzi.tres")
    with open(bazzi_res_path, "w", encoding="utf-8") as f:
        f.write(char_tres)
    print("Generated ninja.tres & bazzi.tres")

if __name__ == "__main__":
    generate_ninja_resources()
