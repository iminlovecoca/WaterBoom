from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageChops


ROOT = Path(__file__).resolve().parents[1]
MAP_ROOT = ROOT / "assets/visual_overhaul_v2/maps"
DECOR_ROOT = ROOT / "assets/visual_overhaul_v2/decorations"
MAP_IDS = (
    "training_plaza",
    "lego_city",
    "egypt_temple",
    "aqua_park",
    "pirate_harbor",
    "snow_village",
)


CHECKS_RUN = 0


def require(condition: bool, label: str, failures: list[str]) -> None:
    global CHECKS_RUN
    CHECKS_RUN += 1
    if condition:
        print(f"[VISUAL ASSET PASS] {label}")
    else:
        print(f"[VISUAL ASSET FAIL] {label}")
        failures.append(label)


def edge_equal(image: Image.Image, first_box: tuple[int, int, int, int], second_box: tuple[int, int, int, int]) -> bool:
    first = image.crop(first_box)
    second = image.crop(second_box)
    return ImageChops.difference(first, second).getbbox() is None


def main() -> int:
    failures: list[str] = []
    for map_id in MAP_IDS:
        runtime = MAP_ROOT / map_id / "runtime"
        for name in ("wall_edge_top", "wall_edge_bottom"):
            image = Image.open(runtime / f"{name}.png").convert("RGBA")
            require(image.size == (256, 256), f"{map_id} {name} is one exact source cell", failures)
            require(image.getchannel("A").getextrema() == (255, 255), f"{map_id} {name} is fully opaque", failures)
            require(
                edge_equal(image, (0, 0, 1, 256), (255, 0, 256, 256)),
                f"{map_id} {name} joins horizontally without a seam",
                failures,
            )
        for name in ("wall_edge_left", "wall_edge_right"):
            image = Image.open(runtime / f"{name}.png").convert("RGBA")
            require(
                edge_equal(image, (0, 0, 256, 1), (0, 255, 256, 256)),
                f"{map_id} {name} joins vertically without a seam",
                failures,
            )
        for name in ("wall_corner_tl", "wall_corner_tr", "wall_corner_bl", "wall_corner_br"):
            image = Image.open(runtime / f"{name}.png").convert("RGBA")
            require(image.size == (256, 256), f"{map_id} {name} is square", failures)
            require(image.getchannel("A").getextrema() == (255, 255), f"{map_id} {name} has no transparent gap", failures)

    landmarks = {
        "aqua_park": "aqua_fountain_4x4.png",
        "pirate_harbor": "anchor_fountain_4x4.png",
        "lego_city": "toy_city_hall_full_4x4.png",
        "egypt_temple": "temple_center_full_4x4.png",
    }
    for map_id, filename in landmarks.items():
        image = Image.open(DECOR_ROOT / map_id / "runtime" / filename).convert("RGBA")
        require(image.size == (768, 768), f"{map_id} landmark master is exact square 4x4 art", failures)
        require(image.getchannel("A").getextrema() == (255, 255), f"{map_id} landmark covers all sixteen center cells", failures)

    cactus = Image.open(DECOR_ROOT / "egypt_temple/runtime/flowering_cactus_1x1.png").convert("RGBA")
    snowman = Image.open(DECOR_ROOT / "snow_village/runtime/snowman_1x1.png").convert("RGBA")
    require(cactus.size == (48, 48), "cactus is authored at its final crisp runtime size", failures)
    require(cactus.getchannel("A").getextrema()[0] == 0, "cactus has a real transparent cutout", failures)
    require(snowman.size == (48, 52), "snowman is authored at its final map-scale size", failures)
    require(snowman.getchannel("A").getextrema()[0] == 0, "snowman has a real transparent cutout", failures)

    print(f"VISUAL_ASSET_RESULT: {CHECKS_RUN - len(failures)} passed | {len(failures)} failed")
    return 0 if not failures else 1


if __name__ == "__main__":
    raise SystemExit(main())
