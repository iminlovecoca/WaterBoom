extends SceneTree

const Normalizer = preload("res://scripts/water_balloon/WaterBalloonCatalogV3Normalizer.gd")

func _init() -> void:
	_run.call_deferred()

func _run() -> void:
	var source: Dictionary = Normalizer.load_source()
	if source.is_empty():
		push_error("CATALOG_V3_SMOKE FAIL: source catalog could not be read")
		quit(1)
		return
	var preview: Dictionary = Normalizer.normalize(source)
	var report: Dictionary = Normalizer.validate(preview, false)
	if not bool(report.get("ok", false)):
		push_error("CATALOG_V3_SMOKE FAIL: %s" % "; ".join(report.get("errors", [])))
		quit(1)
		return
	print("CATALOG_V3_SMOKE PASS active=", report.get("active_count"), " ids=", report.get("id_count"), " warnings=", report.get("warnings").size())
	quit(0)
