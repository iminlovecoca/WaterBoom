"""Finalize the production water-balloon catalog without deleting rollback assets."""

from pathlib import Path
import json


ROOT = Path(__file__).resolve().parents[1]
CATALOG = ROOT / "assets" / "water_balloons" / "water_balloon_catalog.json"
KEEP = [f"skin_{index:03d}" for index in range(66, 82)]


def main() -> None:
    data = json.loads(CATALOG.read_text(encoding="utf-8"))
    by_id = {entry["id"]: entry for entry in data.get("skins", [])}
    by_id["skin_080"] = {
        "id": "skin_080",
        "name": "Bubble Star",
        "theme": "cute_water",
        "primary_color": "#35cbed",
        "secondary_color": "#b7f5ff",
        "outline_color": "#1770ae",
        "material": "clear_water",
        "pattern": "soft_bubbles",
        "motif": "golden_starfish",
        "highlight": "soft_caustic",
        "description": "Bóng nước xanh trong với sao biển vàng và ánh sáng lấp lánh",
        "rarity": "rare",
        "price": 135000,
        "vfx_profile": "water_star",
        "burst_accent": "blue_splash",
        "source_asset": "v14_rebuild_new12_raw/bubble_star_raw.png",
    }
    by_id["skin_081"] = {
        "id": "skin_081",
        "name": "Cloud Pearl",
        "theme": "sky",
        "primary_color": "#83d9ef",
        "secondary_color": "#e5ddff",
        "outline_color": "#477cc6",
        "material": "pearl_water",
        "pattern": "cloud_glow",
        "motif": "pearl_cloud",
        "highlight": "soft_caustic",
        "description": "Bóng nước xanh tím dịu với ngọc mây và ánh sáng ngọc trai",
        "rarity": "epic",
        "price": 175000,
        "vfx_profile": "water_sparkle",
        "burst_accent": "blue_splash",
        "source_asset": "v14_rebuild_new12_raw/cloud_pearl_raw.png",
    }
    missing = [skin_id for skin_id in KEEP if skin_id not in by_id]
    if missing:
        raise RuntimeError(f"Cannot finalize catalog; missing entries: {missing}")
    data["version"] = 3
    data["total_skins"] = len(KEEP)
    data["grid"] = {"columns": 8, "rows": 2, "empty_cells": []}
    data["skins"] = [by_id[skin_id] for skin_id in KEEP]
    CATALOG.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"FINAL_WATER_CATALOG skins={len(KEEP)} ids={KEEP[0]}..{KEEP[-1]}")


if __name__ == "__main__":
    main()
