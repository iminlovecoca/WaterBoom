"""Remove magenta matte spill from water-balloon glass without cutting details.

The source sheets were generated over #ff00ff.  A normal chroma key removes
the outside, but semi-transparent glass can keep a pink hue inside the
silhouette.  This pass is deliberately conservative: it only hue-corrects
smooth, magenta-dominant pixels in the upper glass band of the affected blue
skins.  Alpha, geometry, highlights, motifs, and all intentional pink skins
are left intact.
"""

from __future__ import annotations

import colorsys
import json
import math
from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
SKIN_ROOT = ROOT / "assets" / "water_balloons" / "skins"
REPORT = ROOT / "tests" / "artifacts" / "water_balloon_despill_report.json"

# These are the blue/cyan glass skins where pink from the staging matte is
# visibly wrong. Pink, red, purple, green, and gold designs are protected.
TARGET_HUES = {
    "skin_078": 0.56,  # prism pearl: clear blue glass
    "skin_079": 0.53,  # jellyfish bubble: aqua glass
    "skin_080": 0.54,  # bubble star: aqua glass
    "skin_081": 0.57,  # cloud pearl: cool blue glass
}


def lerp_hue(a: float, b: float, amount: float) -> float:
    delta = (b - a + 0.5) % 1.0 - 0.5
    return (a + delta * amount) % 1.0


def local_smoothness(image: Image.Image, x: int, y: int) -> float:
    """Return 0..1; flat glass gets 1, detailed motifs get 0."""
    px = image.load()
    samples: list[tuple[float, float, float]] = []
    for yy in range(max(0, y - 1), min(image.height, y + 2)):
        for xx in range(max(0, x - 1), min(image.width, x + 2)):
            r, g, b, a = px[xx, yy]
            if a >= 180:
                samples.append((float(r), float(g), float(b)))
    if len(samples) < 4:
        return 0.0
    means = [sum(item[i] for item in samples) / len(samples) for i in range(3)]
    variance = sum(
        sum((item[i] - means[i]) ** 2 for i in range(3)) for item in samples
    ) / (len(samples) * 3)
    deviation = math.sqrt(variance)
    return max(0.0, min(1.0, 1.0 - deviation / 55.0))


def despill_image(image: Image.Image, target_hue: float) -> tuple[Image.Image, int, float]:
    image = image.convert("RGBA")
    pixels = image.load()
    alpha_values = [pixels[x, y][3] for y in range(image.height) for x in range(image.width)]
    bbox = image.getchannel("A").point(lambda a: 255 if a >= 32 else 0).getbbox()
    if not bbox:
        return image, 0, 0.0
    left, top, right, bottom = bbox
    height = max(1, bottom - top)
    changed = 0
    total_weight = 0.0

    for y in range(top, bottom):
        rel_y = (y - top) / height
        # Matte contamination is most visible in the clear upper membrane.
        band_weight = max(0.0, min(1.0, (0.56 - rel_y) / 0.30))
        if band_weight <= 0:
            continue
        for x in range(left, right):
            r, g, b, a = pixels[x, y]
            if a < 180:
                continue
            magenta_score = min(1.0, max(0.0, (r - g) / 145.0)) * min(
                1.0, max(0.0, (b - g) / 145.0)
            )
            hue, saturation, value = colorsys.rgb_to_hsv(r / 255.0, g / 255.0, b / 255.0)
            # Keep true blue/cyan pixels and any low-saturation white highlight.
            if saturation < 0.16 or hue < 0.72 or hue > 0.98:
                continue
            hue_spill = max(0.0, min(1.0, (hue - 0.68) / 0.24))
            spill_score = max(magenta_score, hue_spill)
            if spill_score < 0.08:
                continue
            smooth = local_smoothness(image, x, y)
            weight = max(0.0, min(1.0, spill_score * band_weight * (0.30 + smooth * 0.70)))
            if weight < 0.10:
                continue
            # Correct hue only; preserve value and most saturation so the glass
            # keeps its highlight, bubbles, and material response.
            # Strong spill is fully moved to the cool water hue; weak spill is
            # only nudged. This prevents the upper glass from retaining a pink
            # cast while leaving the actual motif pixels untouched.
            corrected_hue = lerp_hue(hue, target_hue, min(1.0, weight * 2.6))
            corrected_sat = saturation * (1.0 - 0.10 * weight)
            nr, ng, nb = colorsys.hsv_to_rgb(corrected_hue, corrected_sat, value)
            pixels[x, y] = (round(nr * 255), round(ng * 255), round(nb * 255), a)
            changed += 1
            total_weight += weight

    return image, changed, total_weight


def main() -> None:
    report: dict[str, object] = {"method": "upper_glass_hue_despill", "skins": {}}
    for skin_id, target_hue in TARGET_HUES.items():
        skin_dir = SKIN_ROOT / skin_id
        skin_info: dict[str, object] = {"target_hue": target_hue, "files": {}}
        for name in ["icon.png", "idle_0.png", "idle_1.png", "idle_2.png", "idle_3.png"]:
            path = skin_dir / name
            image, changed, weight = despill_image(Image.open(path), target_hue)
            image.save(path, format="PNG", optimize=True)
            skin_info["files"][name] = {"pixels_changed": changed, "weight": round(weight, 3)}
        report["skins"][skin_id] = skin_info

    REPORT.parent.mkdir(parents=True, exist_ok=True)
    REPORT.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(f"DESPILL complete report={REPORT}")


if __name__ == "__main__":
    main()
