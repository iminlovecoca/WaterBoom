extends SceneTree

const SOURCE := "res://assets/characters/ninja/source/ninja_master_turnaround_v2.png"
const PROCESSED_DIR := "res://assets/characters/ninja/processed"
const RUNTIME_DIR := "res://assets/characters/ninja/runtime"
const FRAME_SIZE := Vector2i(96, 96)
const FEET_BASELINE := 88
const ALPHA_THRESHOLD := 8.0 / 255.0
const VISUAL_HEIGHT := 70

func _init() -> void:
	var source := Image.load_from_file(SOURCE)
	if source.is_empty() or source.get_width() % 2 != 0 or source.get_height() % 2 != 0:
		printerr("Invalid turnaround source: ", SOURCE)
		quit(1)
		return

	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(PROCESSED_DIR))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(RUNTIME_DIR))
	var quadrant := Vector2i(source.get_width() / 2, source.get_height() / 2)
	var names := ["front", "back", "left", "right"]
	var origins := [Vector2i.ZERO, Vector2i(quadrant.x, 0), Vector2i(0, quadrant.y), quadrant]
	var bounds: Array[Rect2i] = []
	var quadrants: Array[Image] = []

	for i in names.size():
		var frame := source.get_region(Rect2i(origins[i], quadrant))
		_clean_low_alpha(frame)
		var opaque_bounds := _opaque_bounds(frame)
		if opaque_bounds.size == Vector2i.ZERO:
			printerr("No visible pixels in ", names[i])
			quit(1)
			return
		quadrants.append(frame)
		bounds.append(opaque_bounds)
		frame.save_png("%s/ninja_turnaround_%s_source.png" % [PROCESSED_DIR, names[i]])

	var max_height := 0
	var max_width := 0
	for bound in bounds:
		max_height = maxi(max_height, bound.size.y)
		max_width = maxi(max_width, bound.size.x)
	var scale := minf(float(VISUAL_HEIGHT) / max_height, 88.0 / max_width)
	var contact := Image.create(FRAME_SIZE.x * 2, FRAME_SIZE.y * 2, false, Image.FORMAT_RGBA8)
	contact.fill(Color.TRANSPARENT)

	for i in names.size():
		var bound := bounds[i]
		var character := quadrants[i].get_region(bound)
		var scaled_size := Vector2i(roundi(character.get_width() * scale), roundi(character.get_height() * scale))
		character.resize(scaled_size.x, scaled_size.y, Image.INTERPOLATE_LANCZOS)
		_clean_low_alpha(character)
		var runtime := Image.create(FRAME_SIZE.x, FRAME_SIZE.y, false, Image.FORMAT_RGBA8)
		runtime.fill(Color.TRANSPARENT)
		var destination := Vector2i((FRAME_SIZE.x - scaled_size.x) / 2, FEET_BASELINE - scaled_size.y)
		runtime.blend_rect(character, Rect2i(Vector2i.ZERO, scaled_size), destination)
		var runtime_path := "%s/ninja_turnaround_%s.png" % [RUNTIME_DIR, names[i]]
		runtime.save_png(runtime_path)
		var contact_position := Vector2i((i % 2) * FRAME_SIZE.x, (i / 2) * FRAME_SIZE.y)
		contact.blend_rect(runtime, Rect2i(Vector2i.ZERO, FRAME_SIZE), contact_position)
		print("PREPARED ", names[i], " canvas=", FRAME_SIZE, " baseline=", FEET_BASELINE, " source_bounds=", bound)

	contact.save_png("%s/NINJA_TURNAROUND_VALIDATION.png" % PROCESSED_DIR)
	quit(0)

func _clean_low_alpha(image: Image) -> void:
	for y in image.get_height():
		for x in image.get_width():
			var color := image.get_pixel(x, y)
			if color.a < ALPHA_THRESHOLD:
				image.set_pixel(x, y, Color.TRANSPARENT)

func _opaque_bounds(image: Image) -> Rect2i:
	var minimum := Vector2i(image.get_width(), image.get_height())
	var maximum := Vector2i(-1, -1)
	for y in image.get_height():
		for x in image.get_width():
			if image.get_pixel(x, y).a >= ALPHA_THRESHOLD:
				minimum = Vector2i(mini(minimum.x, x), mini(minimum.y, y))
				maximum = Vector2i(maxi(maximum.x, x), maxi(maximum.y, y))
	if maximum.x < 0:
		return Rect2i()
	return Rect2i(minimum, maximum - minimum + Vector2i.ONE)
