from pathlib import Path

from PIL import Image, ImageDraw, ImageOps


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "assets/visual_overhaul_v3/water_stream/source/water_cross_reference.png"
OUTPUT = ROOT / "assets/visual_overhaul_v3/water_stream/runtime"
SIZE = 64
EDGE_SEAL = 2


def _is_cyan(pixel: tuple[int, int, int]) -> bool:
    red, green, blue = pixel
    return blue - red > 24 and green - red > 8


def _find_water_bands(image: Image.Image) -> tuple[int, int, int, int]:
    width, height = image.size
    pixels = image.load()
    row_counts = [
        sum(1 for x in range(width) if _is_cyan(pixels[x, y])) for y in range(height)
    ]
    column_counts = [
        sum(1 for y in range(height) if _is_cyan(pixels[x, y])) for x in range(width)
    ]
    horizontal_rows = [index for index, count in enumerate(row_counts) if count > width * 0.45]
    vertical_columns = [index for index, count in enumerate(column_counts) if count > height * 0.45]
    if not horizontal_rows or not vertical_columns:
        raise RuntimeError("Could not locate the water cross inside the supplied reference")
    return (
        min(horizontal_rows),
        max(horizontal_rows) + 1,
        min(vertical_columns),
        max(vertical_columns) + 1,
    )


def _best_repeating_body(image: Image.Image, top: int, bottom: int) -> Image.Image:
    width = image.width
    band = image.crop((0, top, width, bottom)).convert("RGB")
    pixels = band.load()
    target = round(width / 5.0)
    best_score: int | None = None
    best_start = target
    best_width = target

    # Choose two naturally similar columns from the supplied effect so the
    # repeated body tile closes on itself without inventing a new pattern.
    for candidate_width in range(target - 28, target + 29):
        for start in range(target - 30, width - target - candidate_width + 30, 2):
            if start < 0 or start + candidate_width >= width:
                continue
            score = 0
            for y in range(0, band.height, 4):
                first = pixels[start, y]
                last = pixels[start + candidate_width, y]
                score += sum(abs(first[channel] - last[channel]) for channel in range(3))
            if best_score is None or score < best_score:
                best_score = score
                best_start = start
                best_width = candidate_width

    body = band.crop((best_start, 0, best_start + best_width, band.height)).resize(
        (SIZE, SIZE), Image.Resampling.NEAREST
    ).convert("RGBA")
    body.putalpha(Image.new("L", (SIZE, SIZE), 255))
    body.paste(body.crop((0, 0, 1, SIZE)), (SIZE - 1, 0))
    return body


def _reference_center(
    image: Image.Image,
    top: int,
    bottom: int,
    left: int,
    right: int,
    horizontal: Image.Image,
    vertical: Image.Image,
) -> Image.Image:
    center_x = (left + right) // 2
    center_y = (top + bottom) // 2
    span = max(bottom - top, right - left)
    x0 = center_x - span // 2
    y0 = center_y - span // 2
    center = image.crop((x0, y0, x0 + span, y0 + span)).resize(
        (SIZE, SIZE), Image.Resampling.NEAREST
    ).convert("RGBA")
    center.putalpha(Image.new("L", (SIZE, SIZE), 255))

    # Only copy the connector boundaries from the matching reference-derived
    # body; the center artwork itself stays untouched.
    center.alpha_composite(horizontal.crop((0, 0, EDGE_SEAL, SIZE)), (0, 0))
    center.alpha_composite(
        horizontal.crop((SIZE - EDGE_SEAL, 0, SIZE, SIZE)), (SIZE - EDGE_SEAL, 0)
    )
    center.alpha_composite(
        vertical.crop((EDGE_SEAL, 0, SIZE - EDGE_SEAL, EDGE_SEAL)), (EDGE_SEAL, 0)
    )
    center.alpha_composite(
        vertical.crop((EDGE_SEAL, SIZE - EDGE_SEAL, SIZE - EDGE_SEAL, SIZE)),
        (EDGE_SEAL, SIZE - EDGE_SEAL),
    )
    return center


def _reference_right_end(
    image: Image.Image,
    top: int,
    bottom: int,
    horizontal: Image.Image,
) -> Image.Image:
    cell_width = round(image.width / 5.0)
    cap = image.crop((image.width - cell_width, top, image.width, bottom)).resize(
        (SIZE, SIZE), Image.Resampling.NEAREST
    ).convert("RGBA")

    # Preserve every original pale foam pixel. Color-keying the background
    # also removed these low-saturation highlights and produced a black,
    # jagged terminal edge. The geometric cap removes only the four corners.
    capsule = Image.new("L", (SIZE, SIZE), 0)
    draw = ImageDraw.Draw(capsule)
    draw.rectangle((0, 0, SIZE // 2, SIZE - 1), fill=255)
    draw.ellipse((0, 0, SIZE - 1, SIZE - 1), fill=255)
    cap.putalpha(capsule)
    cap.alpha_composite(horizontal.crop((0, 0, EDGE_SEAL, SIZE)), (0, 0))
    return cap


def main() -> None:
    if not SOURCE.exists():
        raise FileNotFoundError(SOURCE)
    OUTPUT.mkdir(parents=True, exist_ok=True)

    reference = Image.open(SOURCE).convert("RGB")
    top, bottom, left, right = _find_water_bands(reference)
    horizontal = _best_repeating_body(reference, top, bottom)
    vertical = horizontal.transpose(Image.Transpose.ROTATE_90)
    center = _reference_center(reference, top, bottom, left, right, horizontal, vertical)
    end_right = _reference_right_end(reference, top, bottom, horizontal)

    horizontal.save(OUTPUT / "water_horizontal.png")
    vertical.save(OUTPUT / "water_vertical.png")
    center.save(OUTPUT / "water_center.png")
    center.save(OUTPUT / "water_cross.png")
    center.save(OUTPUT / "water_impact.png")
    for name in (
        "center_t_down",
        "center_t_up",
        "center_t_left",
        "center_t_right",
        "center_corner_rd",
        "center_corner_ld",
        "center_corner_ru",
        "center_corner_lu",
    ):
        center.save(OUTPUT / f"water_{name}.png")

    end_right.save(OUTPUT / "water_end_right.png")
    ImageOps.mirror(end_right).save(OUTPUT / "water_end_left.png")
    end_right.transpose(Image.Transpose.ROTATE_90).save(OUTPUT / "water_end_up.png")
    end_right.transpose(Image.Transpose.ROTATE_270).save(OUTPUT / "water_end_down.png")
    print(f"Built exact reference-sliced water burst set in {OUTPUT}")


if __name__ == "__main__":
    main()
