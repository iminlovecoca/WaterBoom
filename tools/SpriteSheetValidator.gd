extends SceneTree

const DEFAULT_DIR := "res://assets/characters/ninja/runtime"
const EXPECTED_SIZE := Vector2i(112, 112)
const EXPECTED_BASELINE := 107
const BASELINE_TOLERANCE := 4
const ALPHA_THRESHOLD := 8.0 / 255.0

var failures: Array[String] = []
var last_hash_by_sequence: Dictionary = {}
var report: Dictionary = {"character": "All", "frames": {}}

var characters := [
	"coral_diver", "red_rider", "sunny_mechanic", "mint_sprout",
	"boom_mascot", "cloud_bunny", "lime_dino", "star_skater", "cocoa_otter"
]

func _init() -> void:
	var total_frames := 0
	for char_id in characters:
		var directory := "res://assets/characters/%s/v11" % char_id
		var files: Array[String] = []
		_collect_png_files(directory, files)
		files.sort()
		total_frames += files.size()
		for path in files:
			_validate_frame(path)
	report["status"] = "PASS" if failures.is_empty() else "FAIL"
	report["failures"] = failures
	var output_path := "res://tests/artifacts/character_validation/ninja_validation.json"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output_path.get_base_dir()))
	var output := FileAccess.open(output_path, FileAccess.WRITE)
	output.store_string(JSON.stringify(report, "  "))
	print("SPRITE_VALIDATION_RESULT: ", report["status"], " | ", report["frames"].size(), " frames | ", failures.size(), " failures")
	for failure in failures:
		printerr("  ", failure)
	quit(0 if failures.is_empty() else 1)

func _validate_frame(path: String) -> void:
	var image := Image.new()
	var load_error := image.load_png_from_buffer(FileAccess.get_file_as_bytes(path))
	var name := path # Use full path so keys don't collide
	var frame_report := {
		"dimensions": [image.get_width(), image.get_height()],
		"has_alpha": image.get_format() in [Image.FORMAT_LA8, Image.FORMAT_RGBA8, Image.FORMAT_RGBAF, Image.FORMAT_RGBAH],
		"opaque_border_pixels": 0,
		"feet_baseline": -1,
		"duplicate_of": "",
		"status": "PASS"
	}
	if load_error != OK or image.is_empty() or image.get_size() != EXPECTED_SIZE:
		_fail(name, "inconsistent canvas; expected %s" % EXPECTED_SIZE)
		frame_report["status"] = "FAIL"
		report["frames"][name] = frame_report
		return

	var bottom := -1
	var opaque_border := 0
	for y in image.get_height():
		for x in image.get_width():
			if image.get_pixel(x, y).a >= ALPHA_THRESHOLD:
				bottom = maxi(bottom, y)
				if x == 0 or y == 0 or x == image.get_width() - 1 or y == image.get_height() - 1:
					opaque_border += 1
	frame_report["opaque_border_pixels"] = opaque_border
	frame_report["feet_baseline"] = bottom + 1
	if opaque_border > 0:
		_fail(name, "unexpected opaque pixels touch canvas border")
		frame_report["status"] = "FAIL"
	var animation := path.get_base_dir().get_file() # e.g. "idle_down"
	var requires_locked_baseline := animation not in ["die", "win", "lose"]
	if requires_locked_baseline and absi((bottom + 1) - EXPECTED_BASELINE) > BASELINE_TOLERANCE:
		_fail(name, "pivot/baseline mismatch: %d" % (bottom + 1))
		frame_report["status"] = "FAIL"

	var hash_context := HashingContext.new()
	hash_context.start(HashingContext.HASH_SHA256)
	hash_context.update(image.get_data())
	var digest := hash_context.finish().hex_encode()
	var sequence := animation # Group duplicates by animation sequence
	if last_hash_by_sequence.get(sequence, "") == digest:
		frame_report["duplicate_of"] = "previous frame"
		_fail(name, "duplicates the immediately previous animation frame")
		frame_report["status"] = "FAIL"
	last_hash_by_sequence[sequence] = digest
	report["frames"][name] = frame_report

func _fail(frame: String, reason: String) -> void:
	failures.append("%s — %s" % [frame, reason])

func _animation_from_filename(file_name: String) -> String:
	var parts := file_name.get_basename().split("_")
	return parts[1] if parts.size() > 2 else "turnaround"

func _collect_png_files(directory: String, output: Array[String]) -> void:
	var access := DirAccess.open(directory)
	if access == null:
		return
	access.list_dir_begin()
	var entry := access.get_next()
	while not entry.is_empty():
		var path := "%s/%s" % [directory, entry]
		if access.current_is_dir():
			_collect_png_files(path, output)
		elif entry.get_extension().to_lower() == "png":
			output.append(path)
		entry = access.get_next()
	access.list_dir_end()
