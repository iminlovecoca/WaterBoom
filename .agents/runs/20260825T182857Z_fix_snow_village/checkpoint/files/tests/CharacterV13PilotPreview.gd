extends Control

## V13 pilot comparison. Reads staging only and never changes production resources.

const OUTPUT := "res://tests/artifacts/character_v13_cloud_bunny_pilot.png"
const ACTIONS := [
	"idle_down", "idle_up", "idle_left", "idle_right",
	"walk_down", "walk_up", "walk_left", "walk_right",
	"rescue", "water_hit", "bubble", "rescued", "die", "win", "lose"
]
const ROOTS := {
	"GẤU NÂU": "res://assets/characters/boom_mascot/v12_staging/runtime_frames",
	"CLOUD BUNNY": "res://assets/characters/cloud_bunny/v13_staging/runtime_frames",
}

var _sprites: Array[AnimatedSprite2D] = []
var _action_index := 0
var _elapsed := 0.0
var _action_label: Label


func _ready() -> void:
	_build_surface()
	for character_name in ROOTS:
		var sprite := AnimatedSprite2D.new()
		sprite.sprite_frames = _build_frames(str(ROOTS[character_name]))
		sprite.position = Vector2(260 if _sprites.is_empty() else 700, 410)
		sprite.scale = Vector2(3.0, 3.0)
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		add_child(sprite)
		_sprites.append(sprite)
		var name_label := _label(str(character_name), sprite.position + Vector2(-180, 190), Vector2(360, 30), 21, Color("eafcff"))
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		add_child(name_label)
	_play_action(ACTIONS[0])
	_capture_after_settle.call_deferred()


func _process(delta: float) -> void:
	_elapsed += delta
	if _elapsed >= 1.0:
		_elapsed = 0.0
		_action_index = (_action_index + 1) % ACTIONS.size()
		_play_action(ACTIONS[_action_index])


func _play_action(action: String) -> void:
	for sprite in _sprites:
		if sprite.sprite_frames.has_animation(action):
			sprite.play(action)
	_action_label.text = "%02d / %02d   •   %s" % [_action_index + 1, ACTIONS.size(), action.to_upper()]


func _build_frames(root_path: String) -> SpriteFrames:
	var frames := SpriteFrames.new()
	if frames.has_animation("default"):
		frames.remove_animation("default")
	for action in ACTIONS:
		frames.add_animation(action)
		frames.set_animation_speed(action, 8.0 if action.begins_with("walk") else 6.0)
		frames.set_animation_loop(action, action.begins_with("idle") or action.begins_with("walk") or action == "bubble")
		for frame_path in _sorted_frame_paths("%s/%s" % [root_path, action]):
			var texture := load(frame_path) as Texture2D
			if texture != null:
				frames.add_frame(action, texture)
	return frames


func _sorted_frame_paths(directory: String) -> Array[String]:
	var paths: Array[String] = []
	var dir := DirAccess.open(directory)
	if dir == null:
		return paths
	dir.list_dir_begin()
	var entry := dir.get_next()
	while entry != "":
		if not dir.current_is_dir() and entry.ends_with(".png"):
			paths.append("%s/%s" % [directory, entry])
		entry = dir.get_next()
	dir.list_dir_end()
	paths.sort()
	return paths


func _build_surface() -> void:
	var bg := ColorRect.new()
	bg.color = Color("06172c")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var header := ColorRect.new()
	header.color = Color("0c4779")
	header.position = Vector2.ZERO
	header.size = Vector2(960, 104)
	add_child(header)

	var title := _label("CHARACTER V13  •  CLOUD BUNNY PILOT", Vector2(30, 20), Vector2(900, 36), 28, Color("f4fcff"))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(title)
	var subtitle := _label("CÙNG 15 HOẠT ẢNH  •  CÙNG 84 FRAME  •  CÙNG NHỊP VFX", Vector2(30, 60), Vector2(900, 26), 15, Color("67ddff"))
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(subtitle)

	for x in [40.0, 480.0]:
		var stage := Panel.new()
		stage.position = Vector2(x, 146)
		stage.size = Vector2(440, 470)
		var style := StyleBoxFlat.new()
		style.bg_color = Color("092b4e")
		style.border_color = Color("27c8ff")
		style.set_border_width_all(3)
		style.set_corner_radius_all(18)
		stage.add_theme_stylebox_override("panel", style)
		add_child(stage)

	_action_label = _label("", Vector2(230, 122), Vector2(500, 34), 20, Color("ffd665"))
	_action_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_action_label)

	var contract := _label("112 × 112 px   •   chân neo (56, 103)   •   tay/chân ngắn một mẩu   •   bubble/water VFX dùng chung", Vector2(40, 650), Vector2(880, 30), 14, Color("a9eaff"))
	contract.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(contract)


func _label(text_value: String, pos: Vector2, label_size: Vector2, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text_value
	label.position = pos
	label.size = label_size
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label


func _capture_after_settle() -> void:
	await get_tree().create_timer(0.85).timeout
	RenderingServer.force_draw()
	await get_tree().process_frame
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://tests/artifacts"))
	var image := get_viewport().get_texture().get_image()
	var error := image.save_png(OUTPUT) if image != null and not image.is_empty() else ERR_CANT_CREATE
	print("CHARACTER_V13_PILOT_CAPTURE error=", error, " path=", ProjectSettings.globalize_path(OUTPUT))
