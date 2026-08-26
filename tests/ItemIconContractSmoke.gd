extends SceneTree

const EXPECTED := {
	"res://assets/items/item_bubble_pin.png": "kim châm",
	"res://assets/items/item_water_balloon_up.png": "thêm bóng",
	"res://assets/items/item_shield.png": "khiên",
	"res://assets/items/item_speed_up.png": "giày",
	"res://assets/items/item_water_power_up.png": "bình tăng độ dài",
}

func _init() -> void:
	var failures: Array[String] = []
	for path in EXPECTED:
		if not ResourceLoader.exists(path):
			failures.append("missing %s" % path)
			continue
		var texture := load(path) as Texture2D
		if texture == null:
			failures.append("not a texture %s" % path)
			continue
		if texture.get_width() != 96 or texture.get_height() != 96:
			failures.append("%s must be 96x96, got %dx%d" % [path, texture.get_width(), texture.get_height()])
	if failures.is_empty():
		print("ITEM_ICON_CONTRACT PASS count=%d size=96x96" % EXPECTED.size())
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)
