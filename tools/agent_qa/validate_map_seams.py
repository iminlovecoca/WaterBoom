#!/usr/bin/env python3
"""Validate edge/corner seam contracts for the map selected by an agent task."""

from __future__ import annotations

import argparse
import json
from pathlib import Path

from PIL import Image, ImageChops


ROOT = Path(__file__).resolve().parents[2]


def edge_equal(image: Image.Image, first_box: tuple[int, int, int, int], second_box: tuple[int, int, int, int]) -> bool:
    return ImageChops.difference(image.crop(first_box), image.crop(second_box)).getbbox() is None


def check(condition: bool, code: str, message: str, failures: list[str]) -> None:
    if condition:
        print(f"[AGENT MAP SEAM PASS] {code}: {message}")
    else:
        print(f"[AGENT MAP SEAM FAIL] {code}: {message}")
        failures.append(f"{code}: {message}")


def task_map_id(task_path: Path) -> str:
    task = json.loads(task_path.read_text(encoding="utf-8"))
    for criterion in task.get("acceptance_criteria", []):
        if criterion.get("type") == "map_contract":
            return str(criterion.get("map_id", ""))
    return ""


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--task", required=True, type=Path)
    args = parser.parse_args()
    map_id = task_map_id(args.task.resolve())
    failures: list[str] = []
    check(bool(map_id), "map_id", "task contains a map_contract map_id", failures)
    runtime = ROOT / "assets" / "visual_overhaul_v2" / "maps" / map_id / "runtime"
    check(runtime.is_dir(), "runtime", f"runtime directory exists for {map_id}", failures)
    if not runtime.is_dir():
        print("AGENT_MAP_SEAM_RESULT: 0 passed | %d failed" % len(failures))
        return 1

    total = 2
    for name in ("wall_edge_top", "wall_edge_bottom"):
        path = runtime / f"{name}.png"
        exists = path.is_file()
        check(exists, f"{name}_exists", f"{path.name} exists", failures)
        total += 1
        if not exists:
            continue
        image = Image.open(path).convert("RGBA")
        check(image.size == (256, 256), f"{name}_size", "asset is exactly 256x256", failures)
        check(image.getchannel("A").getextrema() == (255, 255), f"{name}_alpha", "asset is fully opaque", failures)
        check(edge_equal(image, (0, 0, 1, 256), (255, 0, 256, 256)), f"{name}_horizontal", "left/right edges join exactly", failures)
        total += 3
    for name in ("wall_edge_left", "wall_edge_right"):
        path = runtime / f"{name}.png"
        exists = path.is_file()
        check(exists, f"{name}_exists", f"{path.name} exists", failures)
        total += 1
        if not exists:
            continue
        image = Image.open(path).convert("RGBA")
        check(image.size == (256, 256), f"{name}_size", "asset is exactly 256x256", failures)
        check(image.getchannel("A").getextrema() == (255, 255), f"{name}_alpha", "asset is fully opaque", failures)
        check(edge_equal(image, (0, 0, 256, 1), (0, 255, 256, 256)), f"{name}_vertical", "top/bottom edges join exactly", failures)
        total += 3
    for name in ("wall_corner_tl", "wall_corner_tr", "wall_corner_bl", "wall_corner_br"):
        path = runtime / f"{name}.png"
        exists = path.is_file()
        check(exists, f"{name}_exists", f"{path.name} exists", failures)
        total += 1
        if not exists:
            continue
        image = Image.open(path).convert("RGBA")
        check(image.size == (256, 256), f"{name}_size", "corner is square", failures)
        check(image.getchannel("A").getextrema() == (255, 255), f"{name}_alpha", "corner has no transparent gap", failures)
        total += 2
    print(f"AGENT_MAP_SEAM_RESULT: {total - len(failures)} passed | {len(failures)} failed")
    if failures:
        print("AGENT_QA_JSON:" + json.dumps({"ok": False, "failures": failures}, ensure_ascii=False))
    return 0 if not failures else 1


if __name__ == "__main__":
    raise SystemExit(main())
