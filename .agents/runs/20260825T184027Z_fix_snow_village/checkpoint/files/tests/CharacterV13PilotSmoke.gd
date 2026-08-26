extends SceneTree

const ROOT := "res://assets/characters/cloud_bunny/v13_staging/runtime_frames"
const EXPECTED := {
	"idle_down": 4, "idle_up": 4, "idle_left": 4, "idle_right": 4,
	"walk_down": 8, "walk_up": 8, "walk_left": 8, "walk_right": 8,
	"rescue": 4, "water_hit": 4, "bubble": 6, "rescued": 4,
	"die": 6, "win": 6, "lose": 6,
}


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var errors: Array[String] = []
	var total := 0
	for action in EXPECTED:
		var files := _sorted_pngs("%s/%s" % [ROOT, action])
		total += files.size()
		if files.size() != int(EXPECTED[action]):
			errors.append("%s: expected %d, got %d" % [action, EXPECTED[action], files.size()])
		var hashes: Dictionary = {}
		for path in files:
			var image := Image.load_from_file(path)
			if image == null or image.is_empty():
				errors.append("%s: unreadable %s" % [action, path])
				continue
			if image.get_width() != 112 or image.get_height() != 112:
				errors.append("%s: %s is %dx%d" % [action, path, image.get_width(), image.get_height()])
			var bytes := FileAccess.get_file_as_bytes(path)
			hashes[hash(bytes)] = true
		if files.size() > 1 and hashes.size() < 2:
			errors.append("%s: all frames are identical" % action)
	if total != 84:
		errors.append("expected 84 total frames, got %d" % total)
	if errors.is_empty():
		print("CHARACTER_V13_PILOT_SMOKE PASS actions=15 frames=84 canvas=112x112")
		quit(0)
	else:
		for message in errors:
			push_error(message)
		quit(1)


func _sorted_pngs(directory: String) -> Array[String]:
	var result: Array[String] = []
	var dir := DirAccess.open(directory)
	if dir == null:
		return result
	for entry in dir.get_files():
		if entry.ends_with(".png"):
			result.append("%s/%s" % [directory, entry])
	result.sort()
	return result
