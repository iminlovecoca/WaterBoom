extends Control

const IDS := [
	"boom_mascot", "cloud_bunny", "cocoa_otter",
	"coral_diver", "lime_dino", "mint_sprout",
	"red_rider", "star_skater", "sunny_mechanic"
]
const DISPLAY_NAMES := [
	"GẤU NÂU", "CLOUD BUNNY", "COCOA OTTER",
	"CORAL DIVER", "LIME DINO", "MINT SPROUT",
	"RED RIDER", "STAR SKATER", "SUNNY MECHANIC"
]
const IDLE_OUTPUT := "res://tests/artifacts/character_v13_cast_idle.png"
const BUBBLE_OUTPUT := "res://tests/artifacts/character_v13_cast_bubble.png"
const SHOWCASE_ACTIONS := [
	"idle_down", "idle_up", "idle_left", "idle_right",
	"walk_down", "walk_up", "walk_left", "walk_right",
	"rescue", "water_hit", "bubble", "rescued", "die", "win", "lose"
]

var _visuals: Array[PlayerVisual] = []
var _status_label: Label


func _ready() -> void:
	_build_surface()
	for index in IDS.size():
		var player := preload("res://scenes/characters/Player.tscn").instantiate() as PlayerController
		player.is_local_control = false
		player.character_def = load("res://resources/characters/%s.tres" % IDS[index]) as CharacterDefinition
		player.position = Vector2(165.0 + float(index % 3) * 315.0, 205.0 + float(index / 3) * 180.0)
		add_child(player)
		await get_tree().process_frame
		var visual := player.visual as PlayerVisual
		visual.setup(player.character_def)
		visual.set_player_name("")
		visual.scale = Vector2(1.25, 1.25)
		_visuals.append(visual)
		var name_label := _label(DISPLAY_NAMES[index], player.position + Vector2(-145, 50), Vector2(290, 26), 15, Color("eafcff"))
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		add_child(name_label)
	_capture_sequence.call_deferred()


func _build_surface() -> void:
	var bg := ColorRect.new()
	bg.color = Color("06172c")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var header := ColorRect.new()
	header.color = Color("0c4779")
	header.position = Vector2.ZERO
	header.size = Vector2(960, 100)
	add_child(header)
	var title := _label("CHARACTER V13  •  FULL CAST", Vector2(30, 16), Vector2(900, 38), 29, Color("f4fcff"))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(title)
	var subtitle := _label("9 NHÂN VẬT  •  15 HOẠT ẢNH  •  84 FRAME / NHÂN VẬT  •  CHUNG NHỊP VFX", Vector2(30, 57), Vector2(900, 26), 16, Color("67ddff"))
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(subtitle)
	for row in 3:
		for column in 3:
			var stage := Panel.new()
			stage.position = Vector2(10.0 + column * 315.0, 115.0 + row * 180.0)
			stage.size = Vector2(310, 170)
			var style := StyleBoxFlat.new()
			style.bg_color = Color("092b4e")
			style.border_color = Color("27c8ff")
			style.set_border_width_all(2)
			style.set_corner_radius_all(16)
			stage.add_theme_stylebox_override("panel", style)
			add_child(stage)
	_status_label = _label("IDLE DOWN  •  shared neutral VFX", Vector2(180, 686), Vector2(600, 26), 15, Color("ffd665"))
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_status_label)


func _capture_sequence() -> void:
	await get_tree().create_timer(0.8).timeout
	await _capture(IDLE_OUTPUT)
	_status_label.text = "BUBBLE  •  shared shell + countdown VFX"
	for visual in _visuals:
		visual.set_bubble(true)
		visual.set_bubble_progress(0.45)
	await get_tree().create_timer(0.8).timeout
	await _capture(BUBBLE_OUTPUT)
	print("CHARACTER_V13_CAST_CAPTURE PASS")
	_run_showcase.call_deferred()


func _run_showcase() -> void:
	while is_inside_tree():
		for action: String in SHOWCASE_ACTIONS:
			_apply_showcase_action(action)
			await get_tree().create_timer(1.0).timeout


func _apply_showcase_action(action: String) -> void:
	_status_label.text = "%02d / %02d  •  %s  •  shared timing + VFX" % [SHOWCASE_ACTIONS.find(action) + 1, SHOWCASE_ACTIONS.size(), action.to_upper()]
	for visual in _visuals:
		if action == "bubble":
			visual.set_bubble(true)
			visual.set_bubble_progress(0.45)
			continue
		if visual.bubble.visible:
			visual.set_bubble(false)
		visual.one_shot_active = false
		visual.terminal_animation = false
		visual.sprite.position = visual.sprite_base_position
		visual.sprite.scale = visual.sprite_character_scale
		visual.shadow.visible = true
		visual.status_vfx.set_mode(&"win" if action == "win" else &"idle")
		if visual.sprite.sprite_frames.has_animation(action):
			visual.sprite.play(action)


func _capture(path: String) -> void:
	RenderingServer.force_draw()
	await get_tree().process_frame
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://tests/artifacts"))
	var image := get_viewport().get_texture().get_image()
	var error := image.save_png(path) if image != null and not image.is_empty() else ERR_CANT_CREATE
	print("CHARACTER_V13_CAST_CAPTURE error=", error, " path=", ProjectSettings.globalize_path(path))


func _label(text_value: String, pos: Vector2, label_size: Vector2, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text_value
	label.position = pos
	label.size = label_size
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label
