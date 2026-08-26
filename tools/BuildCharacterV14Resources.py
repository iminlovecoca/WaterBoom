"""Assemble the accepted V14 Ninja and Aqua character art into runtime resources.

The art itself is produced and QC'd by generate2dsprite.  This script is only a
deterministic assembler: it copies the processed 112x112 frames into the
runtime contract, fills the direction/status animation slots without changing
the pixels, and writes Godot SpriteFrames/CharacterDefinition resources.

Status animations intentionally use the character's own idle frames for now.
PlayerVisual/BubbleVisual still owns the actual bubble shell and pop VFX; this
keeps the new characters in the game without borrowing pixels from another
character until dedicated status sheets are commissioned.
"""

from __future__ import annotations

import shutil
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
CONTRACT = [
    ("idle_down", 4, 6.0, True),
    ("idle_left", 4, 6.0, True),
    ("idle_right", 4, 6.0, True),
    ("idle_up", 4, 6.0, True),
    ("walk_down", 8, 10.0, True),
    ("walk_left", 8, 10.0, True),
    ("walk_right", 8, 10.0, True),
    ("walk_up", 8, 10.0, True),
    ("rescue", 4, 8.0, False),
    ("water_hit", 4, 8.0, False),
    ("bubble", 6, 8.0, True),
    ("rescued", 4, 8.0, False),
    ("die", 6, 8.0, False),
    ("win", 6, 8.0, True),
    ("lose", 6, 8.0, True),
]

CHARACTERS = {
    "shadow_ninja": {
        "display_name": "Shadow Ninja",
        "speed": 172.0,
        "capacity": 1,
        "power": 2,
    },
    "aqua_pacifier": {
        "display_name": "Aqua Pacifier",
        "speed": 176.0,
        "capacity": 2,
        "power": 1,
    },
}


def source_frames(character_id: str, action: str) -> list[Path]:
    staging = ROOT / "assets" / "characters" / "v14_rebuild" / character_id
    # V3 is the fit-normalized pass: both new silhouettes occupy the same
    # 94px body-height envelope as the approved mascot sheets while retaining
    # the shared 112x112 canvas and feet anchor.
    idle = staging / "idle_down_v3"
    walk = staging / "walk_v3"
    if action == "idle_down":
        return [idle / f"idle-{index}.png" for index in range(1, 5)]
    if action.startswith("idle_"):
        # The V14 walk sheet contains one useful directional standing pose at
        # the beginning of each direction group, followed by stepping poses.
        # Never cycle those stepping frames while the player is standing still:
        # it makes the full body visibly jitter in the lobby and in-game.
        #
        # Down-facing idle is the only authored blink strip, so it keeps its
        # four eye frames above. Side/back poses intentionally hold still
        # until dedicated blink strips for those views are supplied.
        start = {"idle_left": 5, "idle_right": 9, "idle_up": 13}[action]
        standing_pose = walk / f"walk-{start}.png"
        return [standing_pose] * 4
    if action.startswith("walk_"):
        start = {"walk_down": 1, "walk_left": 5, "walk_right": 9, "walk_up": 13}[action]
        frames = [walk / f"walk-{start + offset}.png" for offset in range(4)]
        return frames + frames
    # Dedicated status/VFX sheets are deliberately deferred. Keep each action
    # character-local and fully opaque to the runtime so no frame can be lost.
    return [idle / f"idle-{index}.png" for index in range(1, 5)]


def copy_runtime_frames(character_id: str) -> dict[str, list[Path]]:
    runtime_root = ROOT / "assets" / "characters" / "v14_rebuild" / character_id / "runtime_frames"
    runtime_root.mkdir(parents=True, exist_ok=True)
    action_paths: dict[str, list[Path]] = {}
    for action, count, _speed, _loop in CONTRACT:
        destination = runtime_root / action
        destination.mkdir(parents=True, exist_ok=True)
        copied: list[Path] = []
        sources = source_frames(character_id, action)
        for index in range(count):
            src = sources[index % len(sources)]
            if not src.exists():
                raise FileNotFoundError(f"{character_id}: missing processed frame {src}")
            dst = destination / f"{index:03d}.png"
            shutil.copyfile(src, dst)
            copied.append(dst)
        action_paths[action] = copied
    return action_paths


def build_sprite_frames(character_id: str, action_paths: dict[str, list[Path]]) -> Path:
    unique_paths: list[Path] = []
    for action, _count, _speed, _loop in CONTRACT:
        for path in action_paths[action]:
            if path not in unique_paths:
                unique_paths.append(path)
    resource_ids = {path: index for index, path in enumerate(unique_paths, start=1)}
    lines = [
        f'[gd_resource type="SpriteFrames" load_steps={len(unique_paths) + 1} format=3]',
        "",
    ]
    for path, resource_id in resource_ids.items():
        res_path = "res://" + path.relative_to(ROOT).as_posix()
        lines.append(f'[ext_resource type="Texture2D" path="{res_path}" id="{resource_id}_tex"]')
    lines.extend(["", "[resource]", "animations = ["])
    for animation_index, (action, _count, speed, loop) in enumerate(CONTRACT):
        entries = ",".join(
            f'{{"duration": 1.0, "texture": ExtResource("{resource_ids[path]}_tex")}}'
            for path in action_paths[action]
        )
        suffix = "," if animation_index < len(CONTRACT) - 1 else ""
        lines.extend([
            "{",
            f'"frames": [{entries}],',
            f'"loop": {str(loop).lower()},',
            f'"name": &"{action}",',
            f'"speed": {speed:.1f}',
            "}" + suffix,
        ])
    lines.extend(["]", ""])
    output = ROOT / "resources" / "characters" / f"{character_id}_frames_v14.tres"
    output.write_text("\n".join(lines), encoding="utf-8")
    return output


def build_definition(character_id: str, metadata: dict[str, object]) -> Path:
    preview = (
        f"res://assets/characters/v14_rebuild/{character_id}/runtime_frames/idle_down/000.png"
    )
    frames = f"res://resources/characters/{character_id}_frames_v14.tres"
    text = "\n".join([
        '[gd_resource type="Resource" script_class="CharacterDefinition" load_steps=3 format=3]',
        "",
        '[ext_resource type="Script" path="res://resources/characters/CharacterDefinition.gd" id="1_script"]',
        f'[ext_resource type="SpriteFrames" path="{frames}" id="2_frames"]',
        "",
        "[resource]",
        'script = ExtResource("1_script")',
        f'id = "{character_id}"',
        f'display_name = "{metadata["display_name"]}"',
        f'base_speed = {float(metadata["speed"]):.1f}',
        f'base_water_balloon_capacity = {int(metadata["capacity"])}',
        f'base_water_power = {int(metadata["power"])}',
        "max_speed = 280.0",
        "max_water_balloon_capacity = 8",
        "max_water_power = 8",
        'sprite_frames = ExtResource("2_frames")',
        f'preview_texture = ExtResource("2_frames")',
        f'selection_card_texture = ExtResource("2_frames")',
        f'banner_background_texture = ExtResource("2_frames")',
        f'selfie_texture = ExtResource("3_preview")',
        "shadow_offset_y = 10.0",
        "visual_scale = 1.25",
        "",
    ])
    # The preview/card fields are intentionally assigned below using the same
    # first frame texture path; SpriteFrames is not a Texture2D, so replace the
    # generated block with a valid single texture ext_resource.
    text = text.replace(
        f'[gd_resource type="Resource" script_class="CharacterDefinition" load_steps=3 format=3]',
        f'[gd_resource type="Resource" script_class="CharacterDefinition" load_steps=4 format=3]'
    )
    text = text.replace(
        '[ext_resource type="SpriteFrames" path="' + frames + '" id="2_frames"]',
        '[ext_resource type="SpriteFrames" path="' + frames + '" id="2_frames"]\n'
        '[ext_resource type="Texture2D" path="' + preview + '" id="3_preview"]'
    )
    text = text.replace('ExtResource("2_frames")\nselection_card_texture', 'ExtResource("3_preview")\nselection_card_texture')
    text = text.replace('ExtResource("2_frames")\nbanner_background_texture', 'ExtResource("3_preview")\nbanner_background_texture')
    text = text.replace('ExtResource("2_frames")\nselfie_texture', 'ExtResource("3_preview")\nselfie_texture')
    output = ROOT / "resources" / "characters" / f"{character_id}.tres"
    output.write_text(text, encoding="utf-8")
    return output


def main() -> int:
    for character_id, metadata in CHARACTERS.items():
        actions = copy_runtime_frames(character_id)
        frames = build_sprite_frames(character_id, actions)
        definition = build_definition(character_id, metadata)
        print(f"CHARACTER_V14_RESOURCE PASS id={character_id} actions=15 frames=84")
        print(f"  frames={frames.relative_to(ROOT)}")
        print(f"  definition={definition.relative_to(ROOT)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
