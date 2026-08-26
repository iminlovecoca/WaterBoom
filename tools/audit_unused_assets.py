"""Project-wide unused asset auditor.

Static scan: every res:// path literal found in .gd/.tscn/.tres/.cfg/.godot/.json.
Dynamic rules: folders the engine walks or builds paths for at runtime.

Usage: python tools/audit_unused_assets.py [--verbose]
"""
import fnmatch
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SCAN_TEXT_EXT = {".gd", ".tscn", ".tres", ".cfg", ".godot", ".json", ".md", ".txt"}
SCAN_ROOTS = ["scripts", "scenes", "resources", "tests", "assets", "."]
SKIP_DIRS = {".godot", "addons", "tools", "__pycache__"}

# Folder prefixes whose entire subtree is treated as reachable at runtime.
DYNAMIC_PREFIXES = [
    "assets/visual_overhaul_v2/maps/",
    "assets/visual_overhaul_v3/water_stream/runtime/",
]

# Water balloon skin folders listed in the runtime catalog.
def catalog_skin_ids() -> set:
    import json
    catalog = ROOT / "assets/water_balloons/water_balloon_catalog.json"
    try:
        data = json.loads(catalog.read_text(encoding="utf-8"))
        return {s["id"] for s in data.get("skins", [])}
    except Exception as exc:  # noqa: BLE001
        print(f"WARN catalog parse failed: {exc}")
        return set()


def collect_references() -> tuple[set, set]:
    exact_refs: set = set()
    pattern_refs: set = set()
    scan_files: list = []
    for root in SCAN_ROOTS:
        base = ROOT if root == "." else ROOT / root
        if not base.exists():
            continue
        for path in base.rglob("*"):
            if not path.is_file():
                continue
            rel_parts = path.relative_to(ROOT).parts
            if SKIP_DIRS & set(rel_parts):
                continue
            if path.suffix.lower() in SCAN_TEXT_EXT:
                scan_files.append(path)
    for path in scan_files:
        try:
            text = path.read_text(encoding="utf-8", errors="ignore")
        except Exception:  # noqa: BLE001
            continue
        for token in text.split('"'):
            token = token.strip().strip(",")
            if not token.startswith("res://"):
                continue
            clean = token.split(" ")[0].rstrip(".,)")
            if not clean.startswith("res://"):
                continue
            if "%s" in clean or "*" in clean:
                pattern_refs.add(clean)
            else:
                exact_refs.add(clean[len("res://"):].lstrip("/"))
    return exact_refs, pattern_refs


def is_referenced(rel_posix: str, exact_refs: set, pattern_refs: set, skin_ids: set) -> str | None:
    """Return reason string when the file counts as referenced."""
    if rel_posix in exact_refs:
        return "static"
    for pref in DYNAMIC_PREFIXES:
        if rel_posix.startswith(pref):
            return "dynamic-dir"
    if rel_posix.startswith("assets/water_balloons/skins/") :
        parts = rel_posix.split("/")
        if len(parts) > 3 and parts[3] in skin_ids:
            return "catalog-skin"
    for pat in pattern_refs:
        # res://assets/x/%s/y -> match any single segment in place of %s
        bare = pat[len("res://"):] if pat.startswith("res://") else pat
        if fnmatch.fnmatch(rel_posix, bare.replace("%s", "*")):
            return f"pattern:{pat}"
    return None


# Decoration catalog only ever requests these concrete names (specs_for_map
# returns [] for standard maps; boss_pirate_ship needs the lamp + mast).
DECORATION_KEEP = {
    "assets/decorations_v2/pirate_harbor/runtime/harbor_lamp.png",
    "assets/decorations_v2/pirate_harbor/runtime/harbor_lamp.png.import",
    "assets/decorations/pirate_harbor/runtime/harbor_lamp.png",
    "assets/decorations/pirate_harbor/runtime/harbor_lamp.png.import",
    "assets/boss_arena/runtime/pirate_mast.png",
}

# Scanner false-positives / intentional keeps that must never be trashed.
KEEP_EXCEPTIONS = {
    "assets/water_balloons/balloon_sprites/balloon_062.png",
    "assets/water_balloons/balloon_sprites/balloon_063.png",
    "assets/water_balloons/catalog/water_balloon_catalog.png",
    "assets/fonts/OFL-ChakraPetch.txt",
}


def main() -> None:
    verbose = "--verbose" in sys.argv
    skin_ids = catalog_skin_ids()
    exact_refs, pattern_refs = collect_references()

    # Decoration folders: pattern refs over-approximate (catalog builds paths
    # for names that no longer appear in any spec). Restrict to known keeps.
    for ref in list(exact_refs):
        if ref.startswith("assets/decorations") and ref not in DECORATION_KEEP:
            exact_refs.discard(ref)
    pattern_refs = {p for p in pattern_refs if "decorations" not in p}

    groups: dict = {}
    for path in (ROOT / "assets").rglob("*"):
        if not path.is_file():
            continue
        rel = path.relative_to(ROOT).as_posix()
        if "/source/" in f"/{rel}" :
            group = "__source_sheets"
        elif ".import" in path.suffixes[-1:]:
            continue
        else:
            group = "/".join(rel.split("/")[:2])
        stat = groups.setdefault(group, {"n": 0, "mb": 0.0, "unused": [], "umb": 0.0})
        size_mb = path.stat().st_size / (1024 * 1024)
        stat["n"] += 1
        stat["mb"] += size_mb
        reason = is_referenced(rel, exact_refs, pattern_refs, skin_ids)
        if reason is None and rel not in KEEP_EXCEPTIONS and path.suffix != ".uid":
            stat["unused"].append(rel)
            stat["umb"] += size_mb

    rows = sorted(groups.items(), key=lambda kv: kv[1]["umb"], reverse=True)
    print(f"{'group':44} {'files':>6} {'MB':>8} {'unused':>7} {'unusedMB':>9}")
    for name, s in rows:
        mark = " <-- ALL UNUSED" if abs(s["umb"] - s["mb"]) < 0.01 and s["mb"] > 0 else ""
        print(f"{name:44} {s['n']:>6} {s['mb']:>8.1f} {len(s['unused']):>7} {s['umb']:>9.1f}{mark}")
        if verbose:
            for u in s["unused"][:12]:
                print(f"    - {u}")
            if len(s["unused"]) > 12:
                print(f"    ... +{len(s['unused']) - 12} more")

    total_unused = sum(len(s['unused']) for _, s in rows)
    total_umb = sum(s['umb'] for _, s in rows)
    print(f"\nTOTAL unreferenced: {total_unused} files, {total_umb:.1f} MB")


if __name__ == "__main__":
    main()
