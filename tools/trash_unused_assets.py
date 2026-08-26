"""Move unused assets (per audit_unused_assets.py) out of the project into a
trash tree, preserving relative paths. Removes now-empty directories.

Usage: python tools/trash_unused_assets.py [--dry-run]
"""
import shutil
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "tools"))
import audit_unused_assets as audit  # noqa: E402

TRASH = ROOT.parent / "Boom_trash_2026-08-23"


def collect_manifest() -> list:
    skin_ids = audit.catalog_skin_ids()
    exact_refs, pattern_refs = audit.collect_references()

    for ref in list(exact_refs):
        if ref.startswith("assets/decorations") and ref not in audit.DECORATION_KEEP:
            exact_refs.discard(ref)
    pattern_refs = {p for p in pattern_refs if "decorations" not in p}

    manifest: list = []
    for path in (ROOT / "assets").rglob("*"):
        if not path.is_file() or path.suffix in (".uid", ".import"):
            continue
        rel = path.relative_to(ROOT).as_posix()
        if audit.is_referenced(rel, exact_refs, pattern_refs, skin_ids):
            continue
        if rel in audit.KEEP_EXCEPTIONS or rel in audit.DECORATION_KEEP:
            continue
        manifest.append(rel)
    return sorted(manifest)


def main() -> None:
    dry_run = "--dry-run" in sys.argv
    manifest = collect_manifest()

    # Preserve the only copy of harbor_lamp by copying it into decorations_v2.
    lamp_src = ROOT / "assets/decorations/pirate_harbor/runtime/harbor_lamp.png"
    lamp_dst = ROOT / "assets/decorations_v2/pirate_harbor/runtime/harbor_lamp.png"
    if lamp_src.exists() and not dry_run:
        lamp_dst.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(lamp_src, lamp_dst)
    print(f"harbor_lamp copied to v2: {lamp_dst.exists()}")

    moved = skipped = 0
    for rel in manifest:
        src = ROOT / rel
        dst = TRASH / rel
        if not src.exists():
            continue
        if dry_run:
            moved += 1
            continue
        dst.parent.mkdir(parents=True, exist_ok=True)
        try:
            shutil.move(str(src), str(dst))
            moved += 1
        except Exception as exc:  # noqa: BLE001
            print(f"  FAILED {rel}: {exc}")
            skipped += 1

    # Drop .import sidecars whose source png was trashed, and empty dirs.
    orphan_imports = 0
    if not dry_run:
        for imp in (ROOT / "assets").rglob("*.import"):
            asset_name = imp.name[: -len(".import")]
            if not (imp.parent / asset_name).exists():
                dest = TRASH / imp.relative_to(ROOT)
                dest.parent.mkdir(parents=True, exist_ok=True)
                shutil.move(str(imp), str(dest))
                orphan_imports += 1
        for dirpath, dirnames, filenames in list(os_walk_bottomup(ROOT / "assets")):
            if not dirnames and not filenames:
                dirpath.rmdir()

    total_mb = sum((ROOT / f).stat().st_size for f in manifest if (ROOT / f).exists()) / (1024 * 1024)
    action = "WOULD MOVE" if dry_run else "MOVED"
    print(f"{action}: {moved} files ({total_mb:.1f} MB), failed/skipped: {skipped}, orphan imports cleaned: {orphan_imports}")
    print(f"trash root: {TRASH}")


def os_walk_bottomup(base: Path):
    import os
    for dirpath, dirnames, filenames in os.walk(base, topdown=False):
        yield Path(dirpath), dirnames, filenames


if __name__ == "__main__":
    main()
