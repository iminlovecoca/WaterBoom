"""Integrate user-supplied 2x2 water-balloon sheets into the runtime catalog.

The images are treated as art sources, not as runtime assets.  The
generate2dsprite processor performs magenta chroma-key cleanup, component
extraction, shared scaling and strict edge QC.  This script then packages the
validated frames into the game's 128px/64px skin contract and updates the
catalog without touching existing skin IDs.
"""

from __future__ import annotations

import json
import shutil
import subprocess
import sys
from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
PROCESSOR = Path(r"C:\Users\khang\.codex\skills\generate2dsprite\scripts\generate2dsprite.py")
TEMP_ROOT = Path(r"C:\Users\khang\AppData\Local\Temp")
SOURCE_ARCHIVE = ROOT / "assets" / "water_balloons" / "source_user_2026_08_25"
STAGING_ROOT = ROOT / "assets" / "water_balloons" / "v12_staging" / "samples"
SKIN_ROOT = ROOT / "assets" / "water_balloons" / "skins"
CATALOG_PATH = ROOT / "assets" / "water_balloons" / "water_balloon_catalog.json"


SOURCES = [
    {
        "id": "skin_070",
        "slug": "duckling_splash",
        "source": "codex-clipboard-68b6da9b-c708-4d27-990f-3320ab6e28cf.jpg",
        "name": "Duckling Splash",
        "theme": "cute_water",
        "primary_color": "#38bde9",
        "secondary_color": "#9beeff",
        "outline_color": "#2c729c",
        "motif": "yellow_duck",
        "description": "Bóng nước trong veo với chú vịt vàng đang bơi và gợn nước lấp lánh",
        "rarity": "uncommon",
        "price": 100000,
        "vfx_profile": "water_default",
        "burst_accent": "blue_splash",
    },
    {
        "id": "skin_071",
        "slug": "pink_gem",
        "source": "codex-clipboard-6f7384c3-5b43-4d7e-b353-992ad0939f81.jpg",
        "name": "Rose Gem",
        "theme": "crystal",
        "primary_color": "#ef9fce",
        "secondary_color": "#ffe5f7",
        "outline_color": "#a94a87",
        "motif": "rose_crystal",
        "description": "Bóng nước hồng trong suốt với pha lê hồng và cánh hoa bay nhẹ",
        "rarity": "epic",
        "price": 180000,
        "vfx_profile": "water_sparkle",
        "burst_accent": "pink_splash",
    },
    {
        "id": "skin_072",
        "slug": "toxic_skull",
        "source": "codex-clipboard-de189092-3dde-49e2-9bb6-fcdfd13d58ef.jpg",
        "name": "Toxic Skull",
        "theme": "toxic",
        "primary_color": "#8cdf32",
        "secondary_color": "#d9ff72",
        "outline_color": "#4d7020",
        "motif": "purple_skull",
        "description": "Bóng nước độc màu xanh chanh với đầu lâu tím và bong bóng độc",
        "rarity": "epic",
        "price": 175000,
        "vfx_profile": "water_dark",
        "burst_accent": "green_splash",
    },
    {
        "id": "skin_073",
        "slug": "pink_paw",
        "source": "codex-clipboard-0c9d19f8-2ae5-44c9-ab07-944b6504b4fa.jpg",
        "name": "Kitty Paw",
        "theme": "cute",
        "primary_color": "#f4a8cb",
        "secondary_color": "#ffe5f2",
        "outline_color": "#aa5c8c",
        "motif": "cat_paw",
        "description": "Bóng nước mèo hồng với tai mèo, dấu chân và trái tim nhỏ",
        "rarity": "rare",
        "price": 130000,
        "vfx_profile": "water_heart",
        "burst_accent": "pink_splash",
    },
    {
        "id": "skin_074",
        "slug": "galaxy_orbit",
        "source": "codex-clipboard-d9bf1cd0-a052-4f95-b649-b664cb752a3e.jpg",
        "name": "Galaxy Orbit",
        "theme": "cosmic",
        "primary_color": "#3f276d",
        "secondary_color": "#c28cff",
        "outline_color": "#211a54",
        "motif": "ringed_planet",
        "description": "Bóng nước vũ trụ với hành tinh có vành đai giữa dải ngân hà",
        "rarity": "legendary",
        "price": 240000,
        "vfx_profile": "water_galaxy",
        "burst_accent": "galaxy_splash",
    },
    {
        "id": "skin_075",
        "slug": "cyber_cube",
        "source": "codex-clipboard-14a206c8-dad9-492f-8a39-08a4ce2046c2.jpg",
        "name": "Cyber Cube",
        "theme": "cyber",
        "primary_color": "#193b7e",
        "secondary_color": "#4fe9ff",
        "outline_color": "#162b72",
        "motif": "neon_cube",
        "description": "Bóng nước cyber xanh tím với mạch neon và khối lập phương phát sáng",
        "rarity": "legendary",
        "price": 250000,
        "vfx_profile": "water_sparkle",
        "burst_accent": "sparkle_splash",
    },
    {
        "id": "skin_076",
        "slug": "lava_prism",
        "source": "codex-clipboard-afb5d15e-4812-4752-adef-e0c0e58bb6bc.jpg",
        "name": "Lava Prism",
        "theme": "fire",
        "primary_color": "#b63f26",
        "secondary_color": "#ff9f3d",
        "outline_color": "#6e2420",
        "motif": "orange_crystal",
        "description": "Bóng nước dung nham cam đỏ với pha lê nóng rực ở trung tâm",
        "rarity": "legendary",
        "price": 260000,
        "vfx_profile": "water_fire_accent",
        "burst_accent": "fire_splash",
    },
    {
        "id": "skin_077",
        "slug": "honey_gold",
        "source": "codex-clipboard-1450e872-d5e4-40f6-b7c4-2f4cf79dc9c4.jpg",
        "name": "Honey Gold",
        "theme": "sweet",
        "primary_color": "#e6a928",
        "secondary_color": "#ffe17a",
        "outline_color": "#916321",
        "motif": "honeycomb",
        "description": "Bóng nước mật ong vàng óng với cụm lục giác phát sáng",
        "rarity": "rare",
        "price": 145000,
        "vfx_profile": "water_glow",
        "burst_accent": "gold_splash",
    },
    {
        "id": "skin_078",
        "slug": "prism_pearl",
        "source": "codex-clipboard-9b97f8e0-3174-4772-854d-a219d3aad00f.jpg",
        "name": "Prism Pearl",
        "theme": "prism",
        "primary_color": "#326fc2",
        "secondary_color": "#b7e8ff",
        "outline_color": "#20518e",
        "motif": "iridescent_pearl",
        "description": "Bóng nước xanh sâu với viên ngọc cầu vồng lấp lánh ở giữa",
        "rarity": "epic",
        "price": 190000,
        "vfx_profile": "water_sparkle",
        "burst_accent": "sparkle_splash",
    },
    {
        "id": "skin_079",
        "slug": "jellyfish_bubble",
        "source": "codex-clipboard-6f2b6257-fe14-468e-9c93-bd2dae59839f.jpg",
        "name": "Jellyfish Bubble",
        "theme": "ocean",
        "primary_color": "#46c8e7",
        "secondary_color": "#c7f8ff",
        "outline_color": "#3278aa",
        "motif": "jellyfish",
        "description": "Bóng nước biển trong veo với sứa con phát sáng và bong bóng nhỏ",
        "rarity": "rare",
        "price": 150000,
        "vfx_profile": "water_ice",
        "burst_accent": "ice_splash",
    },
]


def write_frames_tres(skin_id: str, target: Path) -> None:
    target.write_text(
        f'''[gd_resource type="SpriteFrames" load_steps=6 format=3]\n\n'''
        f'''[ext_resource type="Texture2D" path="res://assets/water_balloons/skins/{skin_id}/idle_0.png" id="1_idle0"]\n'''
        f'''[ext_resource type="Texture2D" path="res://assets/water_balloons/skins/{skin_id}/idle_1.png" id="2_idle1"]\n'''
        f'''[ext_resource type="Texture2D" path="res://assets/water_balloons/skins/{skin_id}/idle_2.png" id="3_idle2"]\n'''
        f'''[ext_resource type="Texture2D" path="res://assets/water_balloons/skins/{skin_id}/idle_3.png" id="4_idle3"]\n\n'''
        '''[resource]\nanimations = [{\n"frames": [{"duration": 1.0, "texture": ExtResource("1_idle0")}, {"duration": 1.0, "texture": ExtResource("2_idle1")}, {"duration": 1.0, "texture": ExtResource("3_idle2")}, {"duration": 1.0, "texture": ExtResource("4_idle3")}],\n"loop": true,\n"name": &"idle",\n"speed": 5.0\n}]\n''',
        encoding="utf-8",
    )


def write_definition(meta: dict, target: Path) -> None:
    skin_id = meta["id"]
    target.write_text(
        f'''[gd_resource type="Resource" script_class="WaterBalloonSkinDefinition" load_steps=4 format=3]\n\n'''
        '''[ext_resource type="Script" path="res://scripts/water_balloon/WaterBalloonSkinDefinition.gd" id="1_script"]\n'''
        f'''[ext_resource type="Texture2D" path="res://assets/water_balloons/skins/{skin_id}/icon.png" id="2_icon"]\n'''
        f'''[ext_resource type="SpriteFrames" path="res://assets/water_balloons/skins/{skin_id}/{skin_id}_frames.tres" id="3_frames"]\n\n'''
        f'''[resource]\nscript = ExtResource("1_script")\nid = &"{skin_id}"\ndisplay_name = "{meta["name"]}"\ntheme = "{meta["theme"]}"\nmotif = "{meta["motif"]}"\ndescription = "{meta["description"]}"\nrarity = "{meta["rarity"]}"\nprice = {meta["price"]}\nvfx_profile = "{meta["vfx_profile"]}"\nburst_accent = "{meta["burst_accent"]}"\nicon = ExtResource("2_icon")\nsprite_frames = ExtResource("3_frames")\n''',
        encoding="utf-8",
    )


def process_source(meta: dict) -> Path:
    source = TEMP_ROOT / meta["source"]
    if not source.exists():
        raise FileNotFoundError(source)
    archive_path = SOURCE_ARCHIVE / meta["source"]
    archive_path.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(source, archive_path)

    sample_root = STAGING_ROOT / meta["slug"]
    raw_path = sample_root / "raw_sheet.jpg"
    raw_path.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(source, raw_path)
    processed = sample_root / "processed"
    processed.mkdir(parents=True, exist_ok=True)

    command = [
        sys.executable,
        str(PROCESSOR),
        "process",
        "--input",
        str(raw_path),
        "--target",
        "asset",
        "--mode",
        "idle",
        "--rows",
        "2",
        "--cols",
        "2",
        "--output-dir",
        str(processed),
        "--cell-size",
        "128",
        "--fit-scale",
        "0.84",
        "--align",
        "center",
        "--shared-scale",
        "--scale-strategy",
        "fit",
        "--component-mode",
        "largest",
        "--component-padding",
        "2",
        "--min-component-area",
        "64",
        "--edge-touch-margin",
        "1",
        "--reject-edge-touch",
        "--strict-qc",
        "--duration",
        "200",
    ]
    subprocess.run(command, cwd=ROOT, check=True)
    qc = json.loads((processed / "pipeline-meta.json").read_text(encoding="utf-8"))
    summary = qc.get("qc_summary", {})
    if qc.get("edge_touch_frames") or qc.get("paste_clamped_frames") or qc.get("empty_frames"):
        raise RuntimeError(f"QC failed for {meta['id']}: {qc}")
    if float(summary.get("body_scale_cv", 1.0)) > 0.08:
        raise RuntimeError(f"Scale consistency failed for {meta['id']}: {summary}")
    return processed


def package_skin(meta: dict, processed: Path) -> None:
    target = SKIN_ROOT / meta["id"]
    target.mkdir(parents=True, exist_ok=True)
    for index in range(4):
        source = processed / f"idle-{index + 1}.png"
        image = Image.open(source).convert("RGBA")
        image.save(target / f"idle_{index}.png")
    icon = Image.open(processed / "idle-1.png").convert("RGBA").resize((64, 64), Image.Resampling.LANCZOS)
    icon.save(target / "icon.png")
    shutil.copy2(SKIN_ROOT / "skin_001" / "pop_burst.png", target / "pop_burst.png")
    write_frames_tres(meta["id"], target / f"{meta['id']}_frames.tres")
    write_definition(meta, target / f"{meta['id']}_definition.tres")


def update_catalog() -> None:
    catalog = json.loads(CATALOG_PATH.read_text(encoding="utf-8"))
    existing = {str(item.get("id")) for item in catalog.get("skins", [])}
    for meta in SOURCES:
        if meta["id"] in existing:
            continue
        catalog["skins"].append(
            {
                "id": meta["id"],
                "name": meta["name"],
                "theme": meta["theme"],
                "primary_color": meta["primary_color"],
                "secondary_color": meta["secondary_color"],
                "outline_color": meta["outline_color"],
                "motif": meta["motif"],
                "description": meta["description"],
                "rarity": meta["rarity"],
                "price": meta["price"],
                "vfx_profile": meta["vfx_profile"],
                "burst_accent": meta["burst_accent"],
                "source_asset": f"source_user_2026_08_25/{meta['source']}",
            }
        )
    catalog["total_skins"] = len(catalog["skins"])
    catalog["grid"]["rows"] = max(int(catalog["grid"].get("rows", 0)), 10)
    catalog["grid"]["empty_cells"] = []
    CATALOG_PATH.write_text(json.dumps(catalog, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def main() -> None:
    SOURCE_ARCHIVE.mkdir(parents=True, exist_ok=True)
    for meta in SOURCES:
        processed = process_source(meta)
        package_skin(meta, processed)
    update_catalog()
    manifest = {
        "date": "2026-08-25",
        "source_count": len(SOURCES),
        "ids": [meta["id"] for meta in SOURCES],
        "source_archive": str(SOURCE_ARCHIVE.relative_to(ROOT)).replace("\\", "/"),
        "processor": str(PROCESSOR),
        "contract": {"frames": "4 x 128x128", "icon": "64x64", "pop": "shared skin_001"},
    }
    (SOURCE_ARCHIVE / "manifest.json").write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"Integrated {len(SOURCES)} user water-balloon skins: {', '.join(manifest['ids'])}")


if __name__ == "__main__":
    main()
