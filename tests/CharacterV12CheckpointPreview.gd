extends Control

## Isolated v12 golden-checkpoint preview.
## This scene deliberately reads only v12_staging and never mutates production resources.

const OUTPUT := "res://tests/artifacts/character_v12_checkpoint.png"
const CHARACTER_ROOT := "res://assets/characters/boom_mascot/v12_staging/runtime_frames"
const BALLOON_ROOT := "res://assets/water_balloons/v12_staging/samples"
const ANIMATIONS := [
	"idle_down", "idle_up", "idle_left", "idle_right",
	"walk_down", "walk_up", "walk_left", "walk_right",
	"rescue", "water_hit", "bubble", "rescued", "die", "win", "lose"
]
const BALLOONS := [
	{"id": "crystal_prism", "name": "Crystal Prism", "rarity": "EPIC", "path": "res://assets/water_balloons/samples/crystal_prism/icon_64.png"},
	{"id": "aqua_classic_reforge", "name": "Aqua Classic", "rarity": "COMMON", "path": "res://assets/water_balloons/v12_staging/samples/aqua_classic_reforge/icon_64.png"},
	{"id": "watermelon_fresh", "name": "Watermelon Fresh", "rarity": "RARE", "path": "res://assets/water_balloons/v12_staging/samples/watermelon_fresh/icon_64.png"},
	{"id": "moonlit_abyss", "name": "Moonlit Abyss", "rarity": "EPIC", "path": "res://assets/water_balloons/v12_staging/samples/moonlit_abyss/icon_64.png"},
	{"id": "starlight_aurora", "name": "Starlight Aurora", "rarity": "LEGENDARY", "path": "res://assets/water_balloons/v12_staging/samples/starlight_aurora/icon_64.png"}
]

var _sprite: AnimatedSprite2D
var _sequence_index := 0
var _sequence_elapsed := 0.0
var _sequence_label: Label
var _frame_label: Label


func _ready() -> void:
	_build_surface()
	_sprite = AnimatedSprite2D.new()
	_sprite.sprite_frames = _build_character_frames()
	_sprite.position = Vector2(355, 320)
	_sprite.scale = Vector2(3.05, 3.05)
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(_sprite)
	_sprite.play(ANIMATIONS[0])
	_sequence_label.text = "PLAYING  •  %s" % ANIMATIONS[0]
	_update_frame_label()
	_capture_after_settle.call_deferred()


func _process(delta: float) -> void:
	_sequence_elapsed += delta
	if _sequence_elapsed >= 1.15:
		_sequence_elapsed = 0.0
		_sequence_index = (_sequence_index + 1) % ANIMATIONS.size()
		_sprite.play(ANIMATIONS[_sequence_index])
		_sequence_label.text = "PLAYING  •  %s" % ANIMATIONS[_sequence_index]
	_update_frame_label()


func _build_character_frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	for animation_name in ANIMATIONS:
		frames.add_animation(animation_name)
		frames.set_animation_speed(animation_name, 8.0 if animation_name.begins_with("walk") else 6.0)
		frames.set_animation_loop(animation_name, animation_name.begins_with("idle") or animation_name.begins_with("walk") or animation_name == "bubble")
		var paths := _sorted_frame_paths("%s/%s" % [CHARACTER_ROOT, animation_name])
		for path in paths:
			var texture := load(path) as Texture2D
			if texture != null:
				frames.add_frame(animation_name, texture)
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
	header.position = Vector2(0, 0)
	header.size = Vector2(960, 96)
	add_child(header)

	var title := _label("CHARACTER v12  •  GOLDEN CHECKPOINT", Vector2(24, 18), Vector2(912, 34), 26, Color("eafcff"))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(title)
	var subtitle := _label("GẤU NÂU  •  84 KHUNG  •  TAY CHÂN NGẮN MỘT MẨU  •  CHỈ ĐỌC VÙNG STAGING", Vector2(24, 56), Vector2(912, 24), 13, Color("62ddff"))
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(subtitle)

	var stage := Panel.new()
	stage.position = Vector2(42, 126)
	stage.size = Vector2(626, 392)
	var stage_style := StyleBoxFlat.new()
	stage_style.bg_color = Color("0a2c50")
	stage_style.border_color = Color("24c9ff")
	stage_style.set_border_width_all(3)
	stage_style.set_corner_radius_all(18)
	stage.add_theme_stylebox_override("panel", stage_style)
	add_child(stage)
	var stage_title := _label("ANIMATION PREVIEW", Vector2(18, 14), Vector2(590, 28), 18, Color("f7fcff"))
	stage.add_child(stage_title)
	_sequence_label = _label("PLAYING", Vector2(18, 50), Vector2(590, 24), 14, Color("65dcff"))
	stage.add_child(_sequence_label)
	var grid := GridContainer.new()
	grid.columns = 4
	grid.position = Vector2(30, 312)
	grid.size = Vector2(566, 56)
	grid.add_theme_constant_override("h_separation", 10)
	stage.add_child(grid)
	for action_name in ["idle_down", "walk_down", "bubble", "water_hit", "rescued", "die", "win", "lose"]:
		var chip := _label(action_name, Vector2.ZERO, Vector2(0, 0), 11, Color("c4efff"))
		chip.custom_minimum_size = Vector2(128, 24)
		chip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		grid.add_child(chip)

	var side := Panel.new()
	side.position = Vector2(694, 126)
	side.size = Vector2(224, 392)
	var side_style := StyleBoxFlat.new()
	side_style.bg_color = Color("0a2c50")
	side_style.border_color = Color("1b86b9")
	side_style.set_border_width_all(2)
	side_style.set_corner_radius_all(16)
	side.add_theme_stylebox_override("panel", side_style)
	add_child(side)
	var counts := _label("FRAME CONTRACT\n\nIdle  4 × 4 hướng\nWalk  8 × 4 hướng\nRescue / Hit / Freed  4\nBubble  6\nDie / Win / Lose  6\n\nTOTAL 84", Vector2(18, 18), Vector2(188, 230), 15, Color("eafcff"))
	side.add_child(counts)
	_frame_label = _label("", Vector2(18, 288), Vector2(188, 76), 13, Color("65dcff"))
	side.add_child(_frame_label)

	var balloons_title := _label("BALLOON SAMPLE STRIP  •  128 GAME / 64 ICON", Vector2(42, 548), Vector2(876, 26), 16, Color("eafcff"))
	add_child(balloons_title)
	var balloon_row := HBoxContainer.new()
	balloon_row.position = Vector2(42, 585)
	balloon_row.size = Vector2(876, 110)
	balloon_row.add_theme_constant_override("separation", 14)
	add_child(balloon_row)
	for item in BALLOONS:
		balloon_row.add_child(_build_balloon_card(item))


func _build_balloon_card(item: Dictionary) -> Control:
	var card := Panel.new()
	card.custom_minimum_size = Vector2(160, 100)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("0b345d")
	style.border_color = Color("1e9ed4")
	style.set_border_width_all(2)
	style.set_corner_radius_all(12)
	card.add_theme_stylebox_override("panel", style)
	var icon := TextureRect.new()
	icon.position = Vector2(8, 18)
	icon.size = Vector2(64, 64)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.texture = load(str(item["path"])) as Texture2D
	card.add_child(icon)
	var name_label := _label(str(item["name"]), Vector2(78, 20), Vector2(76, 42), 12, Color("f4fbff"))
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	card.add_child(name_label)
	var rarity := _label(str(item["rarity"]), Vector2(78, 65), Vector2(76, 18), 10, _rarity_color(str(item["rarity"])))
	card.add_child(rarity)
	return card


func _label(text: String, position: Vector2, size: Vector2, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.position = position
	label.size = size
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label


func _rarity_color(rarity: String) -> Color:
	match rarity:
		"RARE": return Color("58d9ff")
		"EPIC": return Color("d69cff")
		"LEGENDARY": return Color("ffc451")
		_: return Color("9ce7b8")


func _update_frame_label() -> void:
	if _frame_label == null or _sprite == null:
		return
	var count := _sprite.sprite_frames.get_frame_count(_sprite.animation)
	_frame_label.text = "Animation: %s\nFrame: %d / %d\nCanvas: 112 × 112" % [_sprite.animation, _sprite.frame + 1, count]


func _capture_after_settle() -> void:
	await get_tree().create_timer(0.85).timeout
	RenderingServer.force_draw()
	await get_tree().process_frame
	var image := get_viewport().get_texture().get_image()
	var error := image.save_png(OUTPUT) if image != null and not image.is_empty() else ERR_CANT_CREATE
	print("CHARACTER_V12_CAPTURE error=", error, " path=", ProjectSettings.globalize_path(OUTPUT))
