extends SceneTree

const EXPECTED := {
	"idle_down": 4, "idle_up": 4, "idle_left": 4, "idle_right": 4,
	"walk_down": 8, "walk_up": 8, "walk_left": 8, "walk_right": 8,
	"rescue": 4, "water_hit": 4, "bubble": 6, "rescued": 4,
	"die": 6, "win": 6, "lose": 6,
}


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var arguments := OS.get_cmdline_user_args()
	var character_id := arguments[0] if not arguments.is_empty() else "cloud_bunny"
	var root_path := "res://assets/characters/%s/v13_staging/runtime_frames" % character_id
	var errors: Array[String] = []
	var total := 0
	for action in EXPECTED:
		var files := _sorted_pngs("%s/%s" % [root_path, action])
		total += files.size()
		if files.size() != int(EXPECTED[action]):
			errors.append("%s: expected %d, got %d" % [action, EXPECTED[action], files.size()])
		var hashes: Dictionary = {}
		for path in files:
			var texture := load(path) as Texture2D
			if texture == null:
				errors.append("%s: unreadable %s" % [action, path])
				continue
			if texture.get_width() != 112 or texture.get_height() != 112:
				errors.append("%s: %s is %dx%d" % [action, path, texture.get_width(), texture.get_height()])
			hashes[hash(FileAccess.get_file_as_bytes(path))] = true
		if files.size() > 1 and hashes.size() < 2:
			errors.append("%s: all frames are identical" % action)
	if total != 84:
		errors.append("expected 84 total frames, got %d" % total)
	if errors.is_empty():
		print("CHARACTER_V13_BUNDLE_SMOKE PASS id=%s actions=15 frames=84 canvas=112x112" % character_id)
		quit(0)
	else:
		for message in errors:
			push_error("%s: %s" % [character_id, message])
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
