from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
CAPTURE_DIR = ROOT / "tests" / "artifacts" / "tileset_validation"
PREVIEW_DIR = ROOT / "assets" / "ui" / "map_previews"

MAP_IDS = (
    "training_plaza",
    "aqua_park",
    "pirate_harbor",
    "snow_village",
    "lego_city",
    "egypt_temple",
)


def main() -> None:
    PREVIEW_DIR.mkdir(parents=True, exist_ok=True)
    for map_id in MAP_IDS:
        source = CAPTURE_DIR / f"map_{map_id}.png"
        if not source.exists():
            raise FileNotFoundError(
                f"Missing runtime capture {source}; run TilesetVisualCapture.tscn first"
            )

        capture = Image.open(source).convert("RGB")
        # The fixture places the complete 16x16 arena at (18, 0), 45px/cell.
        # Use the actual runtime result so lobby previews can never show a stale
        # frame or landmark that no longer exists in gameplay.
        arena = capture.crop((18, 0, 18 + 720, 720))
        preview = arena.resize((368, 207), Image.Resampling.LANCZOS)
        output = PREVIEW_DIR / f"map_{map_id}.png"
        preview.save(output, optimize=True)
        print(f"Updated runtime-accurate 16:9 preview: {output}")


if __name__ == "__main__":
    main()
