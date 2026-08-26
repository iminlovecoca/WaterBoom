"""Validate the final runtime water-balloon package.

This deliberately checks alpha and framing without rejecting legitimate glass
colors (lavender, purple, red, etc.) inside the balloon.
"""

import json
from pathlib import Path
from PIL import Image


ROOT = Path(__file__).resolve().parents[1] / "assets" / "water_balloons" / "skins"
OUT = Path(__file__).resolve().parents[1] / "tests" / "artifacts" / "water_balloon_alpha_validation.json"
IDS = [f"skin_{index:03d}" for index in range(66, 82)]


def inspect(path: Path) -> dict:
    image = Image.open(path).convert("RGBA")
    alpha = image.getchannel("A")
    bbox = alpha.getbbox()
    corners = [image.getpixel(p)[3] for p in ((0, 0), (image.width - 1, 0), (0, image.height - 1), (image.width - 1, image.height - 1))]
    matte_visible = 0
    for r, g, b, a in image.getdata():
        if a > 32 and r >= 220 and b >= 220 and g <= 35:
            matte_visible += 1
    return {
        "size": list(image.size),
        "mode": "RGBA",
        "bbox": list(bbox) if bbox else None,
        "corner_alpha": corners,
        "visible_matte_like_pixels": matte_visible,
        "ok": bool(bbox) and max(corners) == 0 and matte_visible == 0,
    }


def main() -> None:
    report = {"catalog_range": [IDS[0], IDS[-1]], "skins": {}, "ok": True}
    for skin_id in IDS:
        folder = ROOT / skin_id
        files = [folder / "icon.png"] + [folder / f"idle_{frame}.png" for frame in range(4)]
        report["skins"][skin_id] = {str(path.name): inspect(path) for path in files if path.exists()}
        if len(report["skins"][skin_id]) != 5 or not all(item["ok"] for item in report["skins"][skin_id].values()):
            report["ok"] = False
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(json.dumps(report, indent=2), encoding="utf-8")
    print(f"WATER_BALLOON_ALPHA_VALIDATION ok={report['ok']} skins={len(report['skins'])} report={OUT}")
    if not report["ok"]:
        raise SystemExit(1)


if __name__ == "__main__":
    main()
