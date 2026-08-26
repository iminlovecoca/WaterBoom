extends Node

## Verifies one normalized footprint is available to gameplay and every UI
## surface, including the deliberately tall cloud balloon.
var failures: Array[String] = []
var checks := 0

func _ready() -> void:
	_run.call_deferred()

func _check(condition: bool, label: String) -> void:
	checks += 1
	if condition:
		print("[BALLOON SCALE PASS] ", label)
	else:
		failures.append(label)
		print("[BALLOON SCALE FAIL] ", label)

func _run() -> void:
	var ids := WaterBalloonSkinRegistry.get_all_skin_ids()
	_check(not ids.is_empty(), "catalog exposes balloon skins")
	for skin_id in ids:
		var runtime_scale := WaterBalloonSkinRegistry.get_runtime_scale(skin_id)
		var icon_scale := WaterBalloonSkinRegistry.get_icon_scale(skin_id)
		_check(is_finite(runtime_scale) and runtime_scale > 0.0, "%s runtime scale is valid" % skin_id)
		_check(is_finite(icon_scale) and icon_scale > 0.0, "%s icon scale is valid" % skin_id)
	_check(WaterBalloonSkinRegistry.get_runtime_scale(&"skin_091") > 1.05, "tall cloud balloon receives area normalization")
	print("WATER_BALLOON_SCALE_RESULT: %d passed | %d failed" % [checks - failures.size(), failures.size()])
	get_tree().quit(0 if failures.is_empty() else 1)
