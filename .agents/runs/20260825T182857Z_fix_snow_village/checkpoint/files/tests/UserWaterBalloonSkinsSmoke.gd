extends Node

const NEW_SKINS := [
	"skin_070", "skin_071", "skin_072", "skin_073", "skin_074",
	"skin_075", "skin_076", "skin_077", "skin_078", "skin_079",
]
const REQUIRED_FILES := ["icon.png", "idle_0.png", "idle_1.png", "idle_2.png", "idle_3.png", "pop_burst.png"]

func _ready() -> void:
	_run.call_deferred()

func _run() -> void:
	var registry := get_tree().root.get_node_or_null("WaterBalloonSkinRegistry")
	if registry == null:
		push_error("USER_BALLOON_SKINS FAIL: WaterBalloonSkinRegistry autoload is missing")
		get_tree().quit(1)
		return
	await get_tree().process_frame
	var missing: Array[String] = []
	var unresolved: Array[String] = []
	for skin_id in NEW_SKINS:
		var directory := "res://assets/water_balloons/skins/%s" % skin_id
		for file_name in REQUIRED_FILES:
			var path := "%s/%s" % [directory, file_name]
			if not FileAccess.file_exists(path):
				missing.append("%s/%s" % [skin_id, file_name])
		var definition = registry.get_skin(StringName(skin_id))
		if definition == null or str(definition.id) != skin_id:
			unresolved.append("%s definition" % skin_id)
			continue
		if registry.get_icon(StringName(skin_id)) == null:
			unresolved.append("%s icon" % skin_id)
		if registry.get_textures(StringName(skin_id)).size() != 4:
			unresolved.append("%s idle frames" % skin_id)
	var report := {
		"schema_version": 1,
		"new_skin_count": NEW_SKINS.size(),
		"new_skin_ids": NEW_SKINS,
		"missing": missing,
		"unresolved": unresolved,
		"ok": missing.is_empty() and unresolved.is_empty(),
	}
	var artifact := FileAccess.open("res://tests/artifacts/user_water_balloon_skins.json", FileAccess.WRITE)
	if artifact != null:
		artifact.store_string(JSON.stringify(report, "  "))
		artifact.close()
	if not bool(report["ok"]):
		push_error("USER_BALLOON_SKINS FAIL missing=%d unresolved=%d" % [missing.size(), unresolved.size()])
		get_tree().quit(1)
		return
	print("USER_BALLOON_SKINS PASS new=10 frames=4 icon=64")
	get_tree().quit(0)
