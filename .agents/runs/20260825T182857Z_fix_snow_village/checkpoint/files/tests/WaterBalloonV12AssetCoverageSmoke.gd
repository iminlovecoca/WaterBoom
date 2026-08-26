extends SceneTree

const Normalizer = preload("res://scripts/water_balloon/WaterBalloonCatalogV3Normalizer.gd")

const REQUIRED_FILES := [
	"icon.png", "idle_0.png", "idle_1.png", "idle_2.png", "idle_3.png", "pop_burst.png"
]

func _init() -> void:
	_run.call_deferred()

func _run() -> void:
	var source := Normalizer.load_source()
	var preview := Normalizer.normalize(source)
	var entries: Array[Dictionary] = []
	var missing: Array[String] = []
	for raw in preview.get("skins", []):
		if not raw is Dictionary or str((raw as Dictionary).get("status", "")) != "active":
			continue
		var id := str((raw as Dictionary).get("id", ""))
		var directory := "res://assets/water_balloons/skins/%s" % id
		var entry := {"id": id, "canvas": "128x128", "icon": "64x64", "files": REQUIRED_FILES.duplicate()}
		for file_name in REQUIRED_FILES:
			var path := "%s/%s" % [directory, file_name]
			if not FileAccess.file_exists(path):
				missing.append("%s/%s" % [id, file_name])
				continue
			var texture := load(path) as Texture2D
			if texture == null:
				missing.append("%s/%s (unloadable)" % [id, file_name])
				continue
			var expected := Vector2i(64, 64) if file_name == "icon.png" else Vector2i(128, 128)
			if Vector2i(texture.get_size()) != expected:
				missing.append("%s/%s (%sx%s)" % [id, file_name, texture.get_width(), texture.get_height()])
		entries.append(entry)
	var report := {
		"schema_version": 1,
		"active_skin_count": entries.size(),
		"expected_active_skin_count": 78,
		"checked_files_per_skin": REQUIRED_FILES.size(),
		"missing": missing,
		"ok": entries.size() == 78 and missing.is_empty(),
		"skins": entries
	}
	var artifact := FileAccess.open("res://tests/artifacts/water_balloon_v12_coverage.json", FileAccess.WRITE)
	if artifact != null:
		artifact.store_string(JSON.stringify(report, "  "))
		artifact.close()
	if not bool(report["ok"]):
		push_error("BALLOON_V12_ASSET_COVERAGE FAIL active=%d missing=%d" % [entries.size(), missing.size()])
		quit(1)
		return
	print("BALLOON_V12_ASSET_COVERAGE PASS active=78 files_per_skin=6")
	quit(0)
