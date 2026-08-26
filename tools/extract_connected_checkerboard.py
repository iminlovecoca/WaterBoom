"""Remove only a bright neutral checkerboard connected to the image border."""

from collections import deque
from pathlib import Path
import sys

from PIL import Image


def is_background(pixel: tuple[int, int, int, int]) -> bool:
    red, green, blue, _alpha = pixel
    return min(red, green, blue) >= 200 and max(red, green, blue) - min(red, green, blue) <= 18


def extract(source_path: Path, output_path: Path) -> int:
    image = Image.open(source_path).convert("RGBA")
    pixels = image.load()
    width, height = image.size
    queue: deque[tuple[int, int]] = deque()
    visited = bytearray(width * height)

    def enqueue(x: int, y: int) -> None:
        index = y * width + x
        if not visited[index] and is_background(pixels[x, y]):
            visited[index] = 1
            queue.append((x, y))

    for x in range(width):
        enqueue(x, 0)
        enqueue(x, height - 1)
    for y in range(height):
        enqueue(0, y)
        enqueue(width - 1, y)

    removed = 0
    while queue:
        x, y = queue.popleft()
        red, green, blue, _alpha = pixels[x, y]
        pixels[x, y] = (red, green, blue, 0)
        removed += 1
        if x > 0:
            enqueue(x - 1, y)
        if x + 1 < width:
            enqueue(x + 1, y)
        if y > 0:
            enqueue(x, y - 1)
        if y + 1 < height:
            enqueue(x, y + 1)

    output_path.parent.mkdir(parents=True, exist_ok=True)
    image.save(output_path)
    return removed


if __name__ == "__main__":
    if len(sys.argv) != 3:
        raise SystemExit("usage: extract_connected_checkerboard.py SOURCE OUTPUT")
    source = Path(sys.argv[1])
    output = Path(sys.argv[2])
    count = extract(source, output)
    print(f"EXTRACTED_BACKGROUND_PIXELS: {count}")
    print(f"OUTPUT: {output}")
