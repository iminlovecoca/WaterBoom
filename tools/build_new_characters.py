"""Build the two generated character turnarounds through the shared animation pipeline."""

from pathlib import Path
import build_red_rider_character as builder


ROOT = Path(__file__).resolve().parents[1]
CHARACTERS = (
    ("sunny_mechanic", "sunny_mechanic_turnaround_v2.png"),
    ("mint_sprout", "mint_sprout_turnaround_v2.png"),
    ("boom_mascot", "boom_mascot_turnaround_v1.png"),
)


for character_id, source_name in CHARACTERS:
    builder.SOURCE = ROOT / "assets" / "characters" / character_id / "source" / source_name
    builder.RUNTIME = ROOT / "assets" / "characters" / character_id / "runtime"
    builder.FRAME_RESOURCE = ROOT / "resources" / "characters" / f"{character_id}_frames.tres"
    builder.FILE_PREFIX = character_id
    builder.main()
