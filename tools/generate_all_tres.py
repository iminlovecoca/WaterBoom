import os
import glob

BASE_DIR = r'C:\Users\khang\Documents\Build\Boom\assets\water_balloons\skins'

def generate_tres(skin_id):
    tres_path = os.path.join(BASE_DIR, skin_id, f"{skin_id}_frames.tres")
    
    tres_content = f"""[gd_resource type="SpriteFrames" load_steps=6 format=3]

[ext_resource type="Texture2D" path="res://assets/water_balloons/skins/{skin_id}/idle_0.png" id="1_idle0"]
[ext_resource type="Texture2D" path="res://assets/water_balloons/skins/{skin_id}/idle_1.png" id="2_idle1"]
[ext_resource type="Texture2D" path="res://assets/water_balloons/skins/{skin_id}/idle_2.png" id="3_idle2"]
[ext_resource type="Texture2D" path="res://assets/water_balloons/skins/{skin_id}/idle_3.png" id="4_idle3"]

[resource]
animations = [{{
"frames": [{{
"duration": 1.0,
"texture": ExtResource("1_idle0")
}}, {{
"duration": 1.0,
"texture": ExtResource("2_idle1")
}}, {{
"duration": 1.0,
"texture": ExtResource("3_idle2")
}}, {{
"duration": 1.0,
"texture": ExtResource("4_idle3")
}}],
"loop": true,
"name": &"idle",
"speed": 5.0
}}]
"""
    with open(tres_path, "w", encoding="utf-8") as f:
        f.write(tres_content)

def main():
    if not os.path.exists(BASE_DIR):
        print(f"Base dir not found: {BASE_DIR}")
        return
        
    skin_dirs = [d for d in os.listdir(BASE_DIR) if d.startswith("skin_")]
    print(f"Generating .tres files for {len(skin_dirs)} skins...")
    
    for skin_id in skin_dirs:
        generate_tres(skin_id)
        
    print("Done generating SpriteFrames .tres files!")

if __name__ == "__main__":
    main()
