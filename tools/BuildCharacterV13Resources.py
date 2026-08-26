"""Build production SpriteFrames resources from accepted V13 staging frames.

This is a deterministic resource assembler: it does not create or alter art.
V12 resources remain in place for rollback; CharacterDefinition resources are
switched to V13 only after all 84 input frames exist on the shared 112px canvas.
"""

from __future__ import annotations

from pathlib import Path


PROJECT_ROOT = Path(__file__).resolve().parents[1]
CHARACTERS = [
    "boom_mascot",
    "cloud_bunny",
    "cocoa_otter",
    "coral_diver",
    "lime_dino",
    "mint_sprout",
    "red_rider",
    "star_skater",
    "sunny_mechanic",
]
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


def build_resource(character_id: str) -> None:
    frame_root = PROJECT_ROOT / "assets" / "characters" / character_id / "v13_staging" / "runtime_frames"
    textures: list[tuple[int, str, Path]] = []
    animation_texture_ids: dict[str, list[int]] = {}
    texture_id = 1
    for action, count, _speed, _loop in CONTRACT:
        action_ids: list[int] = []
        for index in range(count):
            path = frame_root / action / f"{index:03d}.png"
            if not path.exists():
                raise FileNotFoundError(f"{character_id}: missing {path}")
            textures.append((texture_id, action, path))
            action_ids.append(texture_id)
            texture_id += 1
        animation_texture_ids[action] = action_ids

    lines = [f'[gd_resource type="SpriteFrames" load_steps={len(textures) + 1} format=3]', ""]
    for current_id, _action, path in textures:
        resource_path = "res://" + path.relative_to(PROJECT_ROOT).as_posix()
        lines.append(
            f'[ext_resource type="Texture2D" path="{resource_path}" id="{current_id}_tex"]'
        )
    lines.extend(["", "[resource]", "animations = ["])
    for animation_index, (action, _count, speed, loop) in enumerate(CONTRACT):
        frame_entries = ",".join(
            f'{{"duration": 1.0, "texture": ExtResource("{current_id}_tex")}}'
            for current_id in animation_texture_ids[action]
        )
        lines.extend(
            [
                "{",
                f'"frames": [{frame_entries}],',
                f'"loop": {str(loop).lower()},',
                f'"name": &"{action}",',
                f'"speed": {speed:.1f}',
                "}" + ("," if animation_index < len(CONTRACT) - 1 else ""),
            ]
        )
    lines.extend(["]", ""])

    output = PROJECT_ROOT / "resources" / "characters" / f"{character_id}_frames_v13.tres"
    output.write_text("\n".join(lines), encoding="utf-8")

    definition = PROJECT_ROOT / "resources" / "characters" / f"{character_id}.tres"
    definition_text = definition.read_text(encoding="utf-8")
    old_path = f"res://resources/characters/{character_id}_frames_v12.tres"
    new_path = f"res://resources/characters/{character_id}_frames_v13.tres"
    if old_path in definition_text:
        definition_text = definition_text.replace(old_path, new_path)
    elif new_path not in definition_text:
        raise RuntimeError(f"{character_id}: CharacterDefinition does not reference V12 or V13 frames")
    definition.write_text(definition_text, encoding="utf-8")
    print(f"CHARACTER_V13_RESOURCE PASS id={character_id} actions=15 frames=84")


def main() -> int:
    for character_id in CHARACTERS:
        build_resource(character_id)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
