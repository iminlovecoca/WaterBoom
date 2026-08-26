extends Control

## Lightweight GPU proof scene for the rebuilt character bundle.
## It intentionally shows movement only; bubble/status art is deferred.

const TARGETS := [
	["boom_mascot", "GẤU NÂU"],
	["cloud_bunny", "THỎ TRẮNG"],
	["shadow_ninja", "SHADOW NINJA"],
	["aqua_pacifier", "AQUA PACIFIER"],
]
const ACTIONS := ["idle_down", "walk_down", "walk_left", "walk_right", "walk_up", "idle_down"]

var _sprites: Array[AnimatedSprite2D] = []
var _action_index := 0
var _elapsed := 0.0
var _status: Label

func _ready() -> void:
	_build_surface()
	for index in TARGETS.size():
		var id: String = TARGETS[index][0]
		var character := load("res://resources/characters/%s.tres" % id) as CharacterDefinition
		var sprite := AnimatedSprite2D.new()
		sprite.sprite_frames = character.sprite_frames
		sprite.animation = &"idle_down"
		sprite.position = Vector2(240.0 + float(index % 2) * 480.0, 280.0 + float(index / 2) * 260.0)
		sprite.scale = Vector2(2.25, 2.25)
		sprite.play()
		add_child(sprite)
		_sprites.append(sprite)
		var label := Label.new()
		label.text = TARGETS[index][1]
		label.position = sprite.position + Vector2(-180.0, 100.0)
		label.size = Vector2(360.0, 30.0)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 20)
		label.add_theme_color_override("font_color", Color("eafcff"))
		add_child(label)
	_set_action(ACTIONS[0])

func _process(delta: float) -> void:
	_elapsed += delta
	if _elapsed >= 1.25:
		_elapsed = 0.0
		_action_index = (_action_index + 1) % ACTIONS.size()
		_set_action(ACTIONS[_action_index])

func _set_action(action: String) -> void:
	_status.text = "V14 CHARACTER PASS  •  %s  •  112×112  •  shared feet anchor" % action.to_upper()
	for sprite in _sprites:
		if sprite.sprite_frames.has_animation(action):
			sprite.play(action)

func _build_surface() -> void:
	var bg := ColorRect.new()
	bg.color = Color("06172c")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	var title := Label.new()
	title.text = "BOOM WATER ARCADE  •  REBUILT CHARACTERS"
	title.position = Vector2(30.0, 22.0)
	title.size = Vector2(900.0, 42.0)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color("f4fcff"))
	add_child(title)
	for row in 2:
		for column in 2:
			var panel := Panel.new()
			panel.position = Vector2(35.0 + column * 480.0, 90.0 + row * 260.0)
			panel.size = Vector2(410.0, 220.0)
			var style := StyleBoxFlat.new()
			style.bg_color = Color("092b4e")
			style.border_color = Color("27c8ff")
			style.set_border_width_all(2)
			style.set_corner_radius_all(16)
			panel.add_theme_stylebox_override("panel", style)
			add_child(panel)
	_status = Label.new()
	_status.position = Vector2(60.0, 670.0)
	_status.size = Vector2(840.0, 28.0)
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status.add_theme_font_size_override("font_size", 16)
	_status.add_theme_color_override("font_color", Color("67ddff"))
	add_child(_status)
