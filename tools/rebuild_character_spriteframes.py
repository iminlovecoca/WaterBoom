"""Rebuild SpriteFrames resources after importing the 8-frame walk sheets.

The source sheets are already cut/normalized by import_character_sheets.py. This
small deterministic writer only restores the Godot SpriteFrames manifest so all
four directions reference the complete eight-frame walk cycle.
"""

from pathlib import Path


PROJECT_ROOT = Path(__file__).resolve().parents[1]
CHARACTERS_ROOT = PROJECT_ROOT / "assets" / "characters"
RESOURCES_ROOT = PROJECT_ROOT / "resources" / "characters"


def ext_resources(character: str) -> list[str]:
    groups = [
        ("idle_down", range(4)),
        ("idle_left", range(4)),
        ("idle_right", range(4)),
        ("idle_up", range(4)),
        ("walk_down", range(4)),
        ("walk_left", range(4)),
        ("walk_right", range(4)),
        ("walk_up", range(4)),
        ("bubbled", range(4)),
        ("escape", range(4)),
        ("lose", range(4)),
        ("win", range(4)),
        ("walk_down", range(4, 8)),
        ("walk_left", range(4, 8)),
        ("walk_right", range(4, 8)),
        ("walk_up", range(4, 8)),
    ]
    lines: list[str] = []
    resource_id = 1
    for directory, frames in groups:
        for frame in frames:
            path = f"res://assets/characters/{character}/v11/{directory}/{frame:02d}.png"
            lines.append(
                f'[ext_resource type="Texture2D" path="{path}" id="{resource_id}_tex"]'
            )
            resource_id += 1
    return lines


def frame_entry(resource_id: int) -> str:
    return f'{{"duration": 1.0, "texture": ExtResource("{resource_id}_tex")}}'


def clip(name: str, resource_ids: list[int], loop: bool, speed: float) -> str:
    frames = ",\n".join(frame_entry(resource_id) for resource_id in resource_ids)
    return (
        "{\n"
        f'"frames": [{frames}],\n'
        f'"loop": {str(loop).lower()},\n'
        f'"name": &"{name}",\n'
        f'"speed": {speed:.1f}\n'
        "}"
    )


def build_resource(character: str) -> str:
    # The first 48 resources are the four-frame authored states. IDs 49..64
    # are the appended walk frames emitted by the importer.
    clips = [
        clip("idle_down", [1, 2, 3, 4], True, 4.0),
        clip("idle_left", [5, 6, 7, 8], True, 4.0),
        clip("idle_right", [9, 10, 11, 12], True, 4.0),
        clip("idle_up", [13, 14, 15, 16], True, 4.0),
        clip("walk_down", [17, 18, 19, 20, 49, 50, 51, 52], True, 8.0),
        clip("walk_left", [21, 22, 23, 24, 53, 54, 55, 56], True, 8.0),
        clip("walk_right", [25, 26, 27, 28, 57, 58, 59, 60], True, 8.0),
        clip("walk_up", [29, 30, 31, 32, 61, 62, 63, 64], True, 8.0),
        clip("bubble", [33, 34, 35, 36], True, 6.0),
        clip("rescued", [37, 38, 39, 40], False, 8.0),
        clip("lose", [41, 42, 43, 44], False, 6.0),
        clip("win", [45, 46, 47, 48], False, 6.0),
        clip("die", [41, 42, 43, 44], False, 6.0),
        clip("water_hit", [41], False, 2.0),
    ]
    return (
        "[gd_resource type=\"SpriteFrames\" format=3]\n\n"
        + "\n".join(ext_resources(character))
        + "\n\n[resource]\nanimations = [\n"
        + ",\n".join(clips)
        + "\n]\n"
    )


def main() -> None:
    character_ids = sorted(
        path.name for path in CHARACTERS_ROOT.iterdir() if path.is_dir()
    )
    for character in character_ids:
        target = RESOURCES_ROOT / f"{character}_frames.tres"
        if not target.exists():
            raise FileNotFoundError(target)
        target.write_text(build_resource(character), encoding="utf-8", newline="\n")
        print(target)


if __name__ == "__main__":
    main()
