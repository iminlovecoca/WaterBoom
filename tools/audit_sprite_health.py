"""Audit sprite folders for alpha-edge garbage and import settings."""
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parent.parent


def audit(folder: Path) -> dict:
    stats = {"png": 0, "dirty_png": 0, "import": 0, "no_mipmap": 0, "no_fixborder": 0}
    for path in sorted(folder.rglob("*")):
        parts = path.relative_to(ROOT).parts
        if "source" in parts:
            continue
        if path.suffix.lower() == ".png":
            stats["png"] += 1
            try:
                rgba = np.array(Image.open(path).convert("RGBA")).astype(np.int32)
            except Exception:  # noqa: BLE001
                continue
            rgb, alpha = rgba[..., :3], rgba[..., 3]
            if ((alpha < 8) & (rgb.max(axis=-1) > 12)).any():
                stats["dirty_png"] += 1
        elif path.suffix == ".import":
            stats["import"] += 1
            text = path.read_text(encoding="utf-8", errors="replace")
            if "mipmaps/generate=true" not in text:
                stats["no_mipmap"] += 1
            if "process/fix_alpha_border=true" not in text:
                stats["no_fixborder"] += 1
    return stats


def main() -> None:
    base = ROOT / "assets"
    print(f"{'folder':34} {'png':>5} {'dirty':>6} {'imp':>5} {'noMip':>6} {'noFixB':>7}")
    for folder in sorted(p for p in base.iterdir() if p.is_dir()):
        s = audit(folder)
        flag = ""
        if s["dirty_png"] or s["no_mipmap"]:
            flag = "  <-- NEEDS FIX"
        print(f"{folder.name:34} {s['png']:>5} {s['dirty_png']:>6} {s['import']:>5} {s['no_mipmap']:>6} {s['no_fixborder']:>7}{flag}")


if __name__ == "__main__":
    main()
