extends Node

## Regression gate for the ten newly packaged RGBA balloon skins.
## It catches the old magenta-matte failure without changing the art pixels.
const NEW_SKINS := [
	"skin_092", "skin_093", "skin_094", "skin_095", "skin_096",
	"skin_097", "skin_098", "skin_099", "skin_100", "skin_101",
]
const REQUIRED_FILES := ["icon.png", "idle_0.png", "idle_1.png", "idle_2.png", "idle_3.png", "pop_burst.png"]

var failures: Array[String] = []

func _ready() -> void:
	_run.call_deferred()

func _run() -> void:
	var registry := get_tree().root.get_node_or_null("WaterBalloonSkinRegistry")
	if registry == null:
		push_error("TRANSPARENT_BALLOON_SKINS FAIL: registry autoload missing")
		get_tree().quit(1)
		return
	await get_tree().process_frame
	for skin_id in NEW_SKINS:
		_check_skin(registry, skin_id)
	var report := {
		"schema_version": 1,
		"skin_ids": NEW_SKINS,
		"checked_files_per_skin": REQUIRED_FILES.size(),
		"failures": failures,
		"ok": failures.is_empty(),
	}
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://tests/artifacts"))
	var artifact := FileAccess.open("res://tests/artifacts/transparent_balloon_skins.json", FileAccess.WRITE)
	if artifact != null:
		artifact.store_string(JSON.stringify(report, "  "))
		artifact.close()
	if failures.is_empty():
		print("TRANSPARENT_BALLOON_SKINS PASS new=10 alpha=clean canvas=128 icon=64")
		get_tree().quit(0)
	else:
		push_error("TRANSPARENT_BALLOON_SKINS FAIL count=%d" % failures.size())
		get_tree().quit(1)

func _check_skin(registry: Node, skin_id: String) -> void:
	var directory := "res://assets/water_balloons/skins/%s" % skin_id
	for file_name in REQUIRED_FILES:
		var path := "%s/%s" % [directory, file_name]
		if not FileAccess.file_exists(path):
			failures.append("%s missing %s" % [skin_id, file_name])
			continue
		var texture := load(path) as Texture2D
		if texture == null:
			failures.append("%s unloadable %s" % [skin_id, file_name])
			continue
		var expected := Vector2i(64, 64) if file_name == "icon.png" else Vector2i(128, 128)
		if Vector2i(texture.get_size()) != expected:
			failures.append("%s %s size=%s expected=%s" % [skin_id, file_name, texture.get_size(), expected])
		if file_name == "pop_burst.png":
			continue
		var image := texture.get_image()
		var used := image.get_used_rect()
		if used.size.x <= 0 or used.size.y <= 0:
			failures.append("%s %s has no alpha content" % [skin_id, file_name])
		var opaque_magenta := 0
		for y in range(image.get_height()):
			for x in range(image.get_width()):
				var pixel := image.get_pixel(x, y)
				if pixel.a > 0.98 and pixel.r > 0.95 and pixel.b > 0.95 and pixel.g < 0.10:
					opaque_magenta += 1
		if opaque_magenta > 0:
			failures.append("%s %s still contains opaque magenta matte (%d px)" % [skin_id, file_name, opaque_magenta])
	var definition = registry.get_skin(StringName(skin_id))
	if definition == null or str(definition.id) != skin_id:
		failures.append("%s not resolved by registry" % skin_id)
	elif registry.get_textures(StringName(skin_id)).size() != 4:
		failures.append("%s idle animation does not expose four frames" % skin_id)
