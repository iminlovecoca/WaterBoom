#!/usr/bin/env python3
"""Package ten already-generated RGBA balloon assets into the runtime catalog.

This is deterministic integration only: it never generates art.  The source
assets were previously accepted by the sprite pipeline and are padded to the
project's 128px frame / 64px icon contract without a chroma-key pass, so the
interior water, highlights, and knots remain intact.
"""

from __future__ import annotations

import json
import shutil
from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
SOURCE_DIR = ROOT / "assets" / "water_balloons" / "v14_new16_transparent_final"
SKINS_DIR = ROOT / "assets" / "water_balloons" / "skins"
CATALOG_PATH = ROOT / "assets" / "water_balloons" / "water_balloon_catalog.json"
POP_SOURCE = SKINS_DIR / "skin_066" / "pop_burst.png"

SKINS = [
    ("skin_092", 1, "Boba Pearl", "festival", "#43c5e8", "#d8fbff", "#126a9a", "boba_pearl", "rare", 135000, "water_sparkle", "blue_splash"),
    ("skin_093", 2, "Citrus Splash", "citrus", "#f5c84b", "#fff0a2", "#b86b1d", "citrus_slice", "rare", 125000, "water_glow", "gold_splash"),
    ("skin_094", 3, "Moonlit Tide", "moonlight", "#315ecb", "#91d8ff", "#17235f", "moon_tide", "epic", 165000, "water_dark", "blue_splash"),
    ("skin_095", 4, "Cloud Drift", "sky", "#71c9ef", "#eefbff", "#3c83bd", "cloud_drift", "rare", 145000, "water_ice", "blue_splash"),
    ("skin_096", 5, "Petal Jelly", "garden", "#f08bbf", "#ffe6f5", "#a44486", "petal_jelly", "epic", 180000, "water_heart", "pink_splash"),
    ("skin_097", 6, "Candy Orbit", "candy", "#f16eac", "#ffd6fb", "#9b3fbc", "candy_orbit", "epic", 175000, "water_sparkle", "pink_splash"),
    ("skin_098", 7, "Cherry Pop", "cherry", "#db3c55", "#ffc1c7", "#861b34", "cherry_pop", "rare", 140000, "water_fire_accent", "red_splash"),
    ("skin_099", 8, "Snow Globe", "winter", "#82d9ff", "#f5fdff", "#3f8cc2", "snow_globe", "epic", 190000, "water_ice", "ice_splash"),
    ("skin_100", 9, "Prism Rainbow", "prism", "#83d9ff", "#fff0ff", "#4777d5", "prism_rainbow", "legendary", 220000, "water_sparkle", "rainbow_splash"),
    ("skin_101", 10, "Firefly Grove", "grove", "#55d89d", "#d9ff9b", "#1f8f74", "firefly_grove", "epic", 185000, "water_glow", "green_splash"),
]


def rgba_frame(source: Path) -> Image.Image:
    image = Image.open(source).convert("RGBA")
    # The accepted source is 112x112.  Keep every pixel and only place it on
    # the canonical 128x128 transparent runtime canvas.
    canvas = Image.new("RGBA", (128, 128), (0, 0, 0, 0))
    x = (128 - image.width) // 2
    y = (128 - image.height) // 2
    canvas.alpha_composite(image, (x, y))
    return canvas


def write_frames_tres(skin_id: str) -> None:
    out = SKINS_DIR / skin_id / f"{skin_id}_frames.tres"
    out.write_text(
        "\n".join(
            [
                "[gd_resource type=\"SpriteFrames\" format=3]",
                "",
                f"[ext_resource type=\"Texture2D\" path=\"res://assets/water_balloons/skins/{skin_id}/idle_0.png\" id=\"1\"]",
                f"[ext_resource type=\"Texture2D\" path=\"res://assets/water_balloons/skins/{skin_id}/idle_1.png\" id=\"2\"]",
                f"[ext_resource type=\"Texture2D\" path=\"res://assets/water_balloons/skins/{skin_id}/idle_2.png\" id=\"3\"]",
                f"[ext_resource type=\"Texture2D\" path=\"res://assets/water_balloons/skins/{skin_id}/idle_3.png\" id=\"4\"]",
                "",
                "[resource]",
                "animations = [{",
                "\"frames\": [{\"duration\": 1.0, \"texture\": ExtResource(\"1\")}, {\"duration\": 1.0, \"texture\": ExtResource(\"2\")}, {\"duration\": 1.0, \"texture\": ExtResource(\"3\")}, {\"duration\": 1.0, \"texture\": ExtResource(\"4\")}],",
                "\"loop\": true,",
                "&\"idle\": true,",
                "\"name\": &\"idle\",",
                "\"speed\": 5.0",
                "}]",
            ]
        ),
        encoding="utf-8",
    )


def write_definition_tres(entry: dict) -> None:
    skin_id = entry["id"]
    out = SKINS_DIR / skin_id / f"{skin_id}_definition.tres"
    def color(value: str) -> str:
        rgb = tuple(int(value[i : i + 2], 16) / 255.0 for i in (1, 3, 5))
        return ", ".join(f"{part:.4f}" for part in rgb)

    out.write_text(
        "\n".join(
            [
                "[gd_resource type=\"Resource\" script_class=\"WaterBalloonSkinDefinition\" format=3]",
                "",
                "[ext_resource type=\"Script\" path=\"res://scripts/water_balloon/WaterBalloonSkinDefinition.gd\" id=\"1_script\"]",
                f"[ext_resource type=\"Texture2D\" path=\"res://assets/water_balloons/skins/{skin_id}/icon.png\" id=\"2_icon\"]",
                f"[ext_resource type=\"SpriteFrames\" path=\"res://assets/water_balloons/skins/{skin_id}/{skin_id}_frames.tres\" id=\"3_frames\"]",
                "",
                "[resource]",
                "script = ExtResource(\"1_script\")",
                f"id = &\"{skin_id}\"",
                f"display_name = \"{entry['name']}\"",
                f"theme = \"{entry['theme']}\"",
                f"primary_color = Color({color(entry['primary_color'])}, 1)",
                f"secondary_color = Color({color(entry['secondary_color'])}, 1)",
                f"outline_color = Color({color(entry['outline_color'])}, 1)",
                f"motif = \"{entry['motif']}\"",
                f"description = \"{entry['description']}\"",
                f"rarity = \"{entry['rarity']}\"",
                f"price = {entry['price']}",
                f"vfx_profile = \"{entry['vfx_profile']}\"",
                f"burst_accent = \"{entry['burst_accent']}\"",
                "icon = ExtResource(\"2_icon\")",
                "sprite_frames = ExtResource(\"3_frames\")",
            ]
        ),
        encoding="utf-8",
    )


def main() -> None:
    catalog = json.loads(CATALOG_PATH.read_text(encoding="utf-8"))
    existing = {str(item["id"]): item for item in catalog.get("skins", [])}
    for values in SKINS:
        skin_id, source_index, name, theme, primary, secondary, outline, motif, rarity, price, vfx, burst = values
        source = SOURCE_DIR / f"single_asset-{source_index}.png"
        if not source.exists():
            raise FileNotFoundError(source)
        entry = {
            "id": skin_id,
            "name": name,
            "theme": theme,
            "primary_color": primary,
            "secondary_color": secondary,
            "outline_color": outline,
            "motif": motif,
            "description": f"Bóng nước {name} với chất liệu trong suốt, highlight mềm và nút thắt nguyên vẹn",
            "rarity": rarity,
            "price": price,
            "vfx_profile": vfx,
            "burst_accent": burst,
        }
        out_dir = SKINS_DIR / skin_id
        out_dir.mkdir(parents=True, exist_ok=True)
        frame = rgba_frame(source)
        for index in range(4):
            frame.save(out_dir / f"idle_{index}.png", optimize=True)
        frame.resize((64, 64), Image.Resampling.LANCZOS).save(out_dir / "icon.png", optimize=True)
        shutil.copy2(POP_SOURCE, out_dir / "pop_burst.png")
        write_frames_tres(skin_id)
        write_definition_tres(entry)
        existing[skin_id] = entry

    catalog["skins"] = [existing[str(item["id"])] for item in catalog.get("skins", [])]
    catalog["skins"].extend(existing[entry[0]] for entry in SKINS if entry[0] not in {str(item["id"]) for item in catalog.get("skins", [])})
    catalog["total_skins"] = len(catalog["skins"])
    CATALOG_PATH.write_text(json.dumps(catalog, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"PACKAGED_TRANSPARENT_BALLOONS PASS added={len(SKINS)} total={len(catalog['skins'])}")


if __name__ == "__main__":
    main()
