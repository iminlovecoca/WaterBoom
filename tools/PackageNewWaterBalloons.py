from pathlib import Path
from PIL import Image
import shutil


ROOT = Path(__file__).resolve().parents[1]
PROCESSED = ROOT / "assets" / "water_balloons" / "v14_rebuild_processed"
SKINS = ROOT / "assets" / "water_balloons" / "skins"


def package(skin_id: str) -> None:
    src = PROCESSED / skin_id
    dst = SKINS / skin_id
    dst.mkdir(parents=True, exist_ok=True)
    for index in range(4):
        frame = Image.open(src / f"idle-{index + 1}.png").convert("RGBA")
        frame.save(dst / f"idle_{index}.png", format="PNG", optimize=True)
        if index == 0:
            frame.resize((64, 64), Image.Resampling.LANCZOS).save(
                dst / "icon.png", format="PNG", optimize=True
            )
    shutil.copy2(SKINS / "skin_066" / "pop_burst.png", dst / "pop_burst.png")


if __name__ == "__main__":
    package("skin_080")
    package("skin_081")
    print("PACKAGED skin_080 skin_081")
