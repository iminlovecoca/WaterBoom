extends Control

var selected_skin_id: StringName = &""
var preview_sprite: AnimatedSprite2D
var name_label: Label
var rarity_label: Label
var theme_label: Label
var skin_grid: GridContainer
var scroll: ScrollContainer
var preview_panel: Panel
var filter_option: OptionButton
var current_filter: String = "all"
var skin_buttons: Array[Button] = []

const LIFT_BUTTON_SCRIPT := preload("res://scripts/ui/LiftButton.gd")

func _ready() -> void:
	_build_ui()
	_populate_grid()

func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.06, 0.08, 0.14)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	
	var title := Label.new()
	title.text = "WATER BALLOON GALLERY - QA TOOL"
	title.position = Vector2(20, 10)
	title.size = Vector2(600, 36)
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color("#c4f3ff"))
	add_child(title)
	
	filter_option = OptionButton.new()
	filter_option.position = Vector2(640, 12)
	filter_option.size = Vector2(300, 32)
	filter_option.add_item("All Skins", 0)
	filter_option.add_item("Common", 1)
	filter_option.add_item("Uncommon", 2)
	filter_option.add_item("Rare", 3)
	filter_option.item_selected.connect(_on_filter_changed)
	add_child(filter_option)
	
	preview_panel = Panel.new()
	preview_panel.position = Vector2(640, 60)
	preview_panel.size = Vector2(300, 640)
	preview_panel.add_theme_stylebox_override("panel", _panel_style(Color("#0a1830"), Color("#48cfff")))
	add_child(preview_panel)
	
	preview_sprite = AnimatedSprite2D.new()
	preview_sprite.position = Vector2(790, 200)
	preview_sprite.scale = Vector2.ONE * 2.5
	preview_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	add_child(preview_sprite)
	
	name_label = Label.new()
	name_label.position = Vector2(660, 340)
	name_label.size = Vector2(260, 36)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 18)
	name_label.add_theme_color_override("font_color", Color.WHITE)
	add_child(name_label)
	
	rarity_label = Label.new()
	rarity_label.position = Vector2(660, 380)
	rarity_label.size = Vector2(260, 28)
	rarity_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rarity_label.add_theme_font_size_override("font_size", 14)
	rarity_label.add_theme_color_override("font_color", Color("#aaddff"))
	add_child(rarity_label)
	
	theme_label = Label.new()
	theme_label.position = Vector2(660, 410)
	theme_label.size = Vector2(260, 28)
	theme_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	theme_label.add_theme_font_size_override("font_size", 14)
	theme_label.add_theme_color_override("font_color", Color("#88bbdd"))
	add_child(theme_label)
	
	var scale_label := Label.new()
	scale_label.text = "64x64 Preview:"
	scale_label.position = Vector2(660, 460)
	scale_label.size = Vector2(260, 24)
	scale_label.add_theme_font_size_override("font_size", 12)
	scale_label.add_theme_color_override("font_color", Color("#8899aa"))
	add_child(scale_label)
	
	var preview_64 := TextureRect.new()
	preview_64.name = "Preview64"
	preview_64.position = Vector2(730, 490)
	preview_64.size = Vector2(64, 64)
	preview_64.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview_64.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	preview_64.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	add_child(preview_64)
	
	var preview_32_label := Label.new()
	preview_32_label.text = "32x32 Preview:"
	preview_32_label.position = Vector2(660, 570)
	preview_32_label.size = Vector2(260, 24)
	preview_32_label.add_theme_font_size_override("font_size", 12)
	preview_32_label.add_theme_color_override("font_color", Color("#8899aa"))
	add_child(preview_32_label)
	
	var preview_32 := TextureRect.new()
	preview_32.name = "Preview32"
	preview_32.position = Vector2(746, 600)
	preview_32.size = Vector2(32, 32)
	preview_32.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview_32.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	preview_32.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(preview_32)
	
	scroll = ScrollContainer.new()
	scroll.position = Vector2(10, 55)
	scroll.size = Vector2(620, 640)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	
	skin_grid = GridContainer.new()
	skin_grid.columns = 4
	skin_grid.add_theme_constant_override("h_separation", 8)
	skin_grid.add_theme_constant_override("v_separation", 8)
	skin_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(skin_grid)

func _populate_grid() -> void:
	for child in skin_grid.get_children():
		child.queue_free()
	skin_buttons.clear()
	
	var all_ids := WaterBalloonSkinRegistry.get_all_skin_ids()
	for skin_id in all_ids:
		var def := WaterBalloonSkinRegistry.get_skin(skin_id)
		if def == null:
			continue
		if current_filter != "all" and def.rarity != current_filter:
			continue
		
		var button := Button.new()
		button.custom_minimum_size = Vector2(140, 160)
		button.set_script(LIFT_BUTTON_SCRIPT)
		skin_grid.add_child(button)
		
		var art := TextureRect.new()
		art.position = Vector2(10, 5)
		art.size = Vector2(120, 110)
		art.texture = def.icon
		art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		art.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		art.mouse_filter = Control.MOUSE_FILTER_IGNORE
		art.pivot_offset = Vector2(60, 55)
		art.scale = Vector2.ONE * WaterBalloonSkinRegistry.get_icon_scale(skin_id)
		button.add_child(art)
		
		var lbl := Label.new()
		lbl.position = Vector2(2, 118)
		lbl.size = Vector2(136, 38)
		lbl.text = def.display_name
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lbl.add_theme_font_size_override("font_size", 10)
		lbl.add_theme_color_override("font_color", Color.WHITE)
		lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(lbl)
		
		var captured_id := skin_id
		button.pressed.connect(func(): _select_skin(captured_id))
		skin_buttons.append(button)

func _select_skin(skin_id: StringName) -> void:
	selected_skin_id = skin_id
	var def := WaterBalloonSkinRegistry.get_skin(skin_id)
	if def == null:
		return
	
	name_label.text = def.display_name
	rarity_label.text = "Rarity: " + def.rarity.to_upper()
	theme_label.text = "Theme: " + def.theme
	
	if def.sprite_frames != null and def.sprite_frames.has_animation(&"idle"):
		preview_sprite.sprite_frames = def.sprite_frames
		preview_sprite.scale = Vector2.ONE * (2.5 * WaterBalloonSkinRegistry.get_runtime_scale(skin_id))
		preview_sprite.play(&"idle")
	
	var icon_64 = def.icon
	var preview_64 := get_node_or_null("Preview64") as TextureRect
	var preview_32 := get_node_or_null("Preview32") as TextureRect
	if preview_64 != null:
		preview_64.texture = icon_64
		preview_64.pivot_offset = Vector2(32, 32)
		preview_64.scale = Vector2.ONE * WaterBalloonSkinRegistry.get_icon_scale(skin_id)
	if preview_32 != null:
		preview_32.texture = icon_64
		preview_32.pivot_offset = Vector2(16, 16)
		preview_32.scale = Vector2.ONE * WaterBalloonSkinRegistry.get_icon_scale(skin_id)

func _on_filter_changed(index: int) -> void:
	match index:
		0: current_filter = "all"
		1: current_filter = "common"
		2: current_filter = "uncommon"
		3: current_filter = "rare"
	_populate_grid()

func _panel_style(bg_color: Color, border_color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = border_color
	style.set_border_width_all(3)
	style.set_corner_radius_all(12)
	style.set_content_margin_all(12)
	return style
