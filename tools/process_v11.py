import os
import shutil

MAPPING = {
    'bear': 'boom_mascot',
    'bunny': 'cloud_bunny',
    'leaf': 'mint_sprout',
    'diver_blue': 'coral_diver',
    'star': 'star_skater',
    'axolotl_pink': 'cocoa_otter',
    'engineer': 'sunny_mechanic',
    'fox_red': 'red_rider',
    'dino': 'lime_dino',
}

SRC_DIR = r'C:\Users\khang\Documents\Build\Boom\assets\characters\character_frames_ready'
ASSETS_DIR = r'C:\Users\khang\Documents\Build\Boom\assets\characters'
RES_DIR = r'C:\Users\khang\Documents\Build\Boom\resources\characters'

def build_tres(char_id, user_id):
    src_char_dir = os.path.join(SRC_DIR, user_id, 'runtime_112_optional')
    dest_char_dir = os.path.join(ASSETS_DIR, char_id, 'v11')
    
    # Copy files
    if os.path.exists(dest_char_dir):
        shutil.rmtree(dest_char_dir)
    shutil.copytree(src_char_dir, dest_char_dir)

    # We need to build the .tres file
    # We will collect all image paths first to assign them unique IDs
    # The order of animations in the .tres:
    anim_names = [
        'idle_down', 'idle_left', 'idle_right', 'idle_up',
        'walk_down', 'walk_left', 'walk_right', 'walk_up',
        'bubble', 'rescued', 'lose', 'win'
    ]
    
    ext_resources = []
    anim_parts = []
    tex_id = 1
    
    # Helper to get frames for an animation
    def get_frames(anim):
        # Map game animation name to user's folder name
        folder_name = anim
        if anim == 'bubble': folder_name = 'bubbled'
        elif anim == 'rescued': folder_name = 'escape'
        
        d = os.path.join(dest_char_dir, folder_name)
        frames = []
        if os.path.exists(d):
            files = sorted([f for f in os.listdir(d) if f.endswith('.png')])
            for f in files:
                rel_path = f"res://assets/characters/{char_id}/v11/{folder_name}/{f}"
                frames.append(rel_path)
        return frames

    texture_to_id = {}
    
    def add_textures(paths):
        nonlocal tex_id
        ids = []
        for p in paths:
            if p not in texture_to_id:
                texture_to_id[p] = tex_id
                ext_resources.append(f'[ext_resource type="Texture2D" path="{p}" id="{tex_id}_tex"]')
                tex_id += 1
            ids.append(texture_to_id[p])
        return ids

    # Ping pong logic for walk
    def pingpong(paths):
        if len(paths) == 4:
            return [paths[0], paths[1], paths[2], paths[3], paths[2], paths[1], paths[0], paths[1]]
        return paths

    animations = []
    
    # Base animations
    for anim in anim_names:
        paths = get_frames(anim)
        is_walk = anim.startswith('walk_')
        if is_walk:
            paths = pingpong(paths)
            speed = 8.0
            loop = True
        else:
            speed = 4.0 if anim.startswith('idle_') else 6.0
            if anim == 'rescued': speed = 8.0
            loop = anim.startswith('idle_') or anim == 'bubble'
            
        ids = add_textures(paths)
        animations.append((anim, ids, loop, speed))
        
    # Extra aliases to satisfy smoke test
    lose_paths = get_frames('lose')
    if lose_paths:
        ids = add_textures(lose_paths)
        animations.append(('die', ids, False, 6.0))
        animations.append(('water_hit', [texture_to_id[lose_paths[0]]], False, 2.0))

    # Build parts
    for name, ids, loop, speed in animations:
        frames_str = ",\n".join(
            f'{{"duration": 1.0, "texture": ExtResource("{i}_tex")}}' for i in ids
        )
        loop_str = "true" if loop else "false"
        anim_parts.append(
            f'{{\n"frames": [{frames_str}],\n"loop": {loop_str},\n"name": &"{name}",\n"speed": {speed}\n}}'
        )
        
    content = (
        '[gd_resource type="SpriteFrames" format=3]\n\n'
        + "\n".join(ext_resources) + "\n\n"
        + "[resource]\n"
        + "animations = [\n" + ",\n".join(anim_parts) + "\n]\n"
    )
    
    tres_path = os.path.join(RES_DIR, f"{char_id}_frames.tres")
    with open(tres_path, 'w', encoding='utf-8') as f:
        f.write(content)
    print(f"Processed {char_id} (from {user_id})")

if __name__ == '__main__':
    for user_id, char_id in MAPPING.items():
        build_tres(char_id, user_id)
    print("Done generating V11 files!")
