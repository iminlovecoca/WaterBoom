extends Control

const OUTPUT := "res://tests/artifacts/water_balloon_samples_runtime.png"
const FRAME_DURATION := 0.14
const ITEMS := [
	{"slug": "crystal_prism", "name": "CRYSTAL PRISM", "rarity": "EPIC"},
]

var _previews: Array[TextureRect] = []
var _elapsed := 0.0
var _frame_index := 0


func _ready() -> void:
	_build_gallery()
	_capture_after_settle.call_deferred()


func _process(delta: float) -> void:
	_elapsed += delta
	if _elapsed < FRAME_DURATION:
		return
	_elapsed = fmod(_elapsed, FRAME_DURATION)
	_frame_index = (_frame_index + 1) % 4
	for index in _previews.size():
		_previews[index].texture = _load_frame(str(ITEMS[index]["slug"]), _frame_index)


func _build_gallery() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var background := ColorRect.new()
	background.color = Color("071a33")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var glow := ColorRect.new()
	glow.color = Color("0b3154")
	glow.position = Vector2(0, 0)
	glow.size = Vector2(960, 112)
	add_child(glow)

	var title := Label.new()
	title.text = "CRYSTAL PRISM  •  APPROVED ART BASELINE"
	title.position = Vector2(30, 22)
	title.size = Vector2(900, 42)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 29)
	title.add_theme_color_override("font_color", Color("effcff"))
	title.add_theme_color_override("font_shadow_color", Color("00101f"))
	title.add_theme_constant_override("shadow_offset_x", 2)
	title.add_theme_constant_override("shadow_offset_y", 3)
	add_child(title)

	var subtitle := Label.new()
	subtitle.text = "4-FRAME IDLE  •  TRANSPARENT PNG  •  128 PX RUNTIME TARGET"
	subtitle.position = Vector2(30, 66)
	subtitle.size = Vector2(900, 28)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 15)
	subtitle.add_theme_color_override("font_color", Color("65dcff"))
	add_child(subtitle)

	var grid := GridContainer.new()
	grid.columns = 1
	grid.position = Vector2(334, 214)
	grid.size = Vector2(292, 278)
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 14)
	add_child(grid)

	for item in ITEMS:
		grid.add_child(_build_card(item))


func _build_card(item: Dictionary) -> Control:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(292, 278)
	var card_style := StyleBoxFlat.new()
	card_style.bg_color = Color("0c3158")
	card_style.border_color = _rarity_color(str(item["rarity"])).darkened(0.12)
	card_style.set_border_width_all(3)
	card_style.set_corner_radius_all(18)
	card_style.shadow_color = Color(0.0, 0.0, 0.0, 0.38)
	card_style.shadow_size = 7
	card_style.shadow_offset = Vector2(0, 5)
	card.add_theme_stylebox_override("panel", card_style)

	var content := Control.new()
	content.custom_minimum_size = Vector2(286, 272)
	card.add_child(content)

	var preview_bg := Panel.new()
	preview_bg.position = Vector2(18, 16)
	preview_bg.size = Vector2(250, 188)
	var preview_style := StyleBoxFlat.new()
	preview_style.bg_color = Color("061b34")
	preview_style.border_color = Color("1a82b3")
	preview_style.set_border_width_all(2)
	preview_style.set_corner_radius_all(14)
	preview_bg.add_theme_stylebox_override("panel", preview_style)
	content.add_child(preview_bg)

	var preview := TextureRect.new()
	preview.position = Vector2(49, 17)
	preview.size = Vector2(152, 152)
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	preview.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	preview.texture = _load_frame(str(item["slug"]), 0)
	preview_bg.add_child(preview)
	_previews.append(preview)

	var rarity := Label.new()
	rarity.text = str(item["rarity"])
	rarity.position = Vector2(18, 176)
	rarity.size = Vector2(214, 22)
	rarity.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rarity.add_theme_font_size_override("font_size", 13)
	rarity.add_theme_color_override("font_color", _rarity_color(str(item["rarity"])))
	preview_bg.add_child(rarity)

	var name_label := Label.new()
	name_label.text = str(item["name"])
	name_label.position = Vector2(12, 214)
	name_label.size = Vector2(262, 32)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 20)
	name_label.add_theme_color_override("font_color", Color("f4fbff"))
	content.add_child(name_label)

	var spec := Label.new()
	spec.text = "256 MASTER  •  128 GAME  •  64 ICON"
	spec.position = Vector2(12, 247)
	spec.size = Vector2(262, 20)
	spec.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	spec.add_theme_font_size_override("font_size", 11)
	spec.add_theme_color_override("font_color", Color("6ecce9"))
	content.add_child(spec)
	return card


func _load_frame(slug: String, index: int) -> Texture2D:
	return load("res://assets/water_balloons/samples/%s/idle_%d_128.png" % [slug, index]) as Texture2D


func _rarity_color(rarity: String) -> Color:
	match rarity:
		"RARE": return Color("44d7ff")
		"EPIC": return Color("d18cff")
		"LEGENDARY": return Color("ffb83e")
		"MYTHIC": return Color("ff6fcf")
		_: return Color("8ce7b1")


func _capture_after_settle() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().create_timer(0.55).timeout
	RenderingServer.force_draw()
	await get_tree().process_frame
	var image := get_viewport().get_texture().get_image()
	var error := image.save_png(OUTPUT) if image != null and not image.is_empty() else ERR_CANT_CREATE
	print("WATER_BALLOON_SAMPLE_CAPTURE error=", error, " path=", ProjectSettings.globalize_path(OUTPUT))
	get_tree().quit(0 if error == OK else 1)
