class_name InventoryView
extends Control
static var _digital_font: FontFile = null
static func _get_digital_font() -> FontFile:
	if _digital_font == null:
		_digital_font = FontFile.new()
		_digital_font.load_dynamic_font("res://assets/fonts/DSEG7Classic-Bold.ttf")
	return _digital_font

static func _format_digital_number(value: int) -> String:
	var s := str(value)
	var formatted := ""
	var count := 0
	for i in range(s.length() - 1, -1, -1):
		formatted = s[i] + formatted
		count += 1
		if count % 3 == 0 and i > 0:
			formatted = "," + formatted
	return formatted


# Signals emitted by inventory
signal closed
signal skin_selected(skin_id: StringName)
signal character_selected(char_id: StringName)

# Preloads & Paths
const COKE_ICON_PATH := "res://assets/ui/coke_coin.png"
const BACK_ARROW_PATH := "res://assets/ui/back_arrow.png"
const ROUND_CLIP_SHADER := preload("res://assets/shaders/rounded_clip.gdshader")
const PLAYER_CARD_PREVIEW_SCRIPT := preload("res://scripts/ui/PlayerCardPreview.gd")

# Data & State
var characters: Array[Dictionary] = []
var selected_character_index: int = 0
var all_owned_skins: Array[Dictionary] = []
var current_category: String = "all" # "all", "balloon", "flag", "player_background"
var selected_skin_id: StringName = &""

# Left Panel References
var char_option_btn: OptionButton
var player_card_preview: PlayerCardPreview
var player_name_val: Label
var player_id_val: Label
var char_name_val: Label
var level_val: Label
var exp_val: Label
var exp_bar: ProgressBar
var active_skin_val: Label
var collection_val: Label
var coke_val_lbl: Label
var back_btn: Button

# Right Panel References
var category_buttons: Dictionary = {}
var item_grid: GridContainer
var empty_grid_label: Label
var item_cards: Dictionary = {}

# Preview References
var preview_art: TextureRect
var preview_name: Label
var preview_rarity: Label
var preview_status: Label
var preview_action_btn: Button

func _ready() -> void:
	anchors_preset = PRESET_FULL_RECT
	mouse_filter = MOUSE_FILTER_STOP
	custom_minimum_size = Vector2(960, 720)
	position = Vector2.ZERO
	size = Vector2(960, 720)
	z_index = 100
	_load_characters()
	_load_owned_skins()
	_build_ui()
	_update_left_panel()
	if not all_owned_skins.is_empty():
		_select_item(all_owned_skins[0].id)
	refresh()
	
	if has_node("/root/GameSession"):
		GameSession.cokecy_changed.connect(_on_cokecy_changed)
		GameSession.progression_changed.connect(_on_progression_changed)
	if has_node("/root/PlayerEquipmentService"):
		PlayerEquipmentService.equipment_changed.connect(_on_equipment_changed)

func _load_characters() -> void:
	characters.clear()
	for def in ActiveCharacterRoster.definitions():
		var card_tex: Texture2D = _get_character_art(def.id)
		characters.append({
			"id": def.id,
			"name": def.display_name,
			"art": card_tex,
			"definition": def
		})
	characters.sort_custom(func(a, b): return a.name < b.name)
	var selected_id := ActiveCharacterRoster.normalize_id(GameSession.selected_character_id)
	for index in range(characters.size()):
		if StringName(characters[index].id) == selected_id:
			selected_character_index = index
			break

func _get_character_art(char_id: StringName) -> Texture2D:
	# Character art must come from the same V13 runtime canvas as gameplay and
	# every other preview.  The old v9-v11 files have different crop bounds;
	# using them here makes the newer characters lose feet/side pixels in cards.
	var definition := load("res://resources/characters/%s.tres" % char_id) as CharacterDefinition
	if definition != null:
		return CharacterPresentation.idle_texture(definition, &"idle_down", 0)
	return null

func _load_owned_skins() -> void:
	all_owned_skins.clear()
	var all_balloon_ids := WaterBalloonSkinRegistry.get_all_skin_ids()
	for skin_id in all_balloon_ids:
		if GameSession.owns_balloon_skin(skin_id):
			var def := WaterBalloonSkinRegistry.get_skin(skin_id)
			if def != null:
				var icon_tex: Texture2D = def.icon if def.icon != null else _get_skin_fallback(skin_id)
				var hd_tex: Texture2D = _get_skin_hd_texture(skin_id)
				if hd_tex == null:
					hd_tex = icon_tex
				all_owned_skins.append({
					"id": skin_id,
					"kind": "balloon",
					"category": "balloon",
					"name": def.display_name.to_upper(),
					"price": def.price,
					"texture": icon_tex,
					"hd_texture": hd_tex,
					"rarity": def.rarity,
					"theme": def.theme,
					"desc": def.description,
				})
				
	var all_defs: Array = CosmeticRegistry.visible_definitions()
	for def in all_defs:
		if def == null:
			continue
		if not PlayerEquipmentService.owns(def.id):
			continue
		var art: Texture2D = def.icon
		if art == null:
			art = def.lobby_asset if def.lobby_asset != null else def.match_list_asset
		all_owned_skins.append({
			"id": def.id,
			"kind": "cosmetic",
			"category": def.category,
			"name": def.display_name,
			"price": def.price,
			"texture": art,
			"hd_texture": def.lobby_asset if def.lobby_asset != null else art,
			"rarity": "default" if def.is_default else "equipment",
			"theme": def.category,
			"desc": def.description,
		})

func _get_skin_fallback(skin_id: StringName) -> Texture2D:
	var p := "res://assets/water_balloons/skins/%s/icon.png" % skin_id
	if ResourceLoader.exists(p):
		return load(p)
	var fallback_path := "res://assets/water_balloons/skins/skin_066/icon.png"
	return load(fallback_path) if ResourceLoader.exists(fallback_path) else null

func _get_skin_hd_texture(skin_id: StringName) -> Texture2D:
	var p := "res://assets/water_balloons/skins/%s/idle_0.png" % skin_id
	if ResourceLoader.exists(p):
		return load(p)
	return null

func _rounded_slot_material(rect_size: Vector2, radius: float = 8.0) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = ROUND_CLIP_SHADER
	material.set_shader_parameter("rect_size", rect_size)
	material.set_shader_parameter("radius_px", radius)
	return material

func _is_background(skin: Dictionary) -> bool:
	return skin.get("kind", "") == "cosmetic" and str(skin.get("category", "")) == "player_background"

# ==============================================================================
# STYLEBOX HELPERS
# ==============================================================================
func _style_panel_outer() -> StyleBoxFlat:
	var s := UITheme.panel_modal()
	s.content_margin_left = 12
	s.content_margin_right = 12
	s.content_margin_top = 10
	s.content_margin_bottom = 10
	return s

func _style_panel_left() -> StyleBoxFlat:
	var s := UITheme.panel_main()
	s.border_width_bottom = 3
	s.content_margin_left = 10
	s.content_margin_right = 10
	s.content_margin_top = 10
	s.content_margin_bottom = 10
	return s

func _style_panel_right() -> StyleBoxFlat:
	var s := UITheme.panel_main()
	s.border_width_bottom = 3
	s.content_margin_left = 10
	s.content_margin_right = 10
	s.content_margin_top = 10
	s.content_margin_bottom = 10
	return s

func _style_3d_btn(bg: Color, border_bottom: Color, border_top: Color, radius: int = 8) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border_bottom
	s.set_border_width_all(2)
	s.border_width_bottom = 4
	s.border_width_top = 2
	s.set_corner_radius_all(radius)
	s.shadow_color = Color(0, 0, 0, 0.35)
	s.shadow_size = 2
	s.shadow_offset = Vector2(0, 2)
	s.content_margin_left = 6
	s.content_margin_right = 6
	s.content_margin_top = 4
	s.content_margin_bottom = 6
	return s

func _style_3d_pressed(bg: Color, border_bottom: Color, radius: int = 8) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border_bottom
	s.set_border_width_all(2)
	s.border_width_bottom = 2
	s.set_corner_radius_all(radius)
	s.content_margin_left = 8
	s.content_margin_right = 8
	s.content_margin_top = 6
	s.content_margin_bottom = 4
	return s

func _style_currency_box() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color("#00245a")
	s.border_color = Color("#004da6")
	s.set_border_width_all(2)
	s.border_width_bottom = 4
	s.set_corner_radius_all(10)
	s.content_margin_left = 8
	s.content_margin_right = 8
	s.content_margin_top = 4
	s.content_margin_bottom = 4
	return s

func _style_card_box(bg: Color, border_color: Color, border_w: int = 2) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border_color
	s.set_border_width_all(border_w)
	s.border_width_bottom = border_w + 3
	s.set_corner_radius_all(10)
	s.content_margin_left = 4
	s.content_margin_right = 4
	s.content_margin_top = 4
	s.content_margin_bottom = 6
	return s

# ==============================================================================
# UI CONSTRUCTION
# ==============================================================================
func _build_ui() -> void:
	var backdrop := TextureRect.new()
	backdrop.anchors_preset = PRESET_FULL_RECT
	backdrop.texture = load("res://ui/assets_generated/backgrounds/checkered_bg.png")
	backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	backdrop.stretch_mode = TextureRect.STRETCH_TILE
	backdrop.modulate = Color("#68b9ff")
	add_child(backdrop)
	
	var center_root := CenterContainer.new()
	center_root.anchors_preset = PRESET_FULL_RECT
	center_root.custom_minimum_size = Vector2(960, 720)
	add_child(center_root)
	
	var outer_panel := PanelContainer.new()
	outer_panel.custom_minimum_size = Vector2(936, 690)
	outer_panel.add_theme_stylebox_override("panel", _style_panel_outer())
	center_root.add_child(outer_panel)
	
	# Main 2-Panel Split HBox (Left: ~270px, Right: ~640px)
	var main_split := HBoxContainer.new()
	main_split.add_theme_constant_override("separation", 10)
	outer_panel.add_child(main_split)
	
	# -------------------------------------------------------------
	# 1. LEFT PANEL: PERSONAL / CHARACTER INFO PANEL (270px)
	# -------------------------------------------------------------
	var left_panel := PanelContainer.new()
	left_panel.custom_minimum_size = Vector2(270, 665)
	left_panel.size_flags_horizontal = SIZE_SHRINK_BEGIN
	left_panel.add_theme_stylebox_override("panel", _style_panel_left())
	main_split.add_child(left_panel)
	
	var left_vbox := VBoxContainer.new()
	left_vbox.add_theme_constant_override("separation", 8)
	left_panel.add_child(left_vbox)
	
	# Title Header
	var l_title := Label.new()
	l_title.text = "THÔNG TIN CÁ NHÂN"
	l_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l_title.add_theme_font_size_override("font_size", 16)
	l_title.add_theme_color_override("font_color", Color.WHITE)
	l_title.add_theme_color_override("font_outline_color", Color("#040d16"))
	l_title.add_theme_constant_override("outline_size", 3)
	left_vbox.add_child(l_title)
	
	# Character Switcher Dropdown
	char_option_btn = OptionButton.new()
	char_option_btn.custom_minimum_size = Vector2(245, 36)
	char_option_btn.add_theme_font_size_override("font_size", 12)
	char_option_btn.add_theme_stylebox_override("normal", _style_3d_btn(Color("#0088dd"), Color("#0044aa"), Color("#33aaff"), 8))
	char_option_btn.add_theme_stylebox_override("hover", _style_3d_btn(Color("#33bbff"), Color("#0077dd"), Color("#77ddff"), 8))
	char_option_btn.add_theme_stylebox_override("pressed", _style_3d_pressed(Color("#0088dd"), Color("#0044aa"), 8))
	char_option_btn.add_theme_color_override("font_color", Color.WHITE)
	for i in range(characters.size()):
		char_option_btn.add_item("NHÂN VẬT: " + characters[i].name.to_upper(), i)
	char_option_btn.item_selected.connect(_on_character_option_selected)
	left_vbox.add_child(char_option_btn)
	
	# Profile Card Box (Holds Character Art - fit with background preview)
	var card_center := CenterContainer.new()
	card_center.custom_minimum_size = Vector2(245, 108)
	left_vbox.add_child(card_center)
	
	player_card_preview = PLAYER_CARD_PREVIEW_SCRIPT.new()
	player_card_preview.custom_minimum_size = Vector2(144, 100)
	card_center.add_child(player_card_preview)
	
	# Large COKE Balance LCD Box (Exact match to lobby LCD screen)
	var coke_box := Panel.new()
	coke_box.custom_minimum_size = Vector2(245, 36)
	coke_box.size = Vector2(245, 36)
	var cb_style := StyleBoxFlat.new()
	cb_style.bg_color = Color("#07111c")
	cb_style.border_color = Color("#223244")
	cb_style.set_border_width_all(2)
	cb_style.border_width_bottom = 3
	cb_style.set_corner_radius_all(8)
	cb_style.shadow_color = Color(0, 0, 0, 0.5)
	cb_style.shadow_size = 4
	cb_style.shadow_offset = Vector2(0, 2)
	coke_box.add_theme_stylebox_override("panel", cb_style)
	left_vbox.add_child(coke_box)

	var lcd_screen := Panel.new()
	lcd_screen.position = Vector2(4, 4)
	lcd_screen.size = Vector2(237, 28)
	var lcd_style := StyleBoxFlat.new()
	lcd_style.bg_color = Color("#031320")
	lcd_style.border_color = Color("#0c3f5d")
	lcd_style.set_border_width_all(1)
	lcd_style.set_corner_radius_all(5)
	lcd_screen.add_theme_stylebox_override("panel", lcd_style)
	coke_box.add_child(lcd_screen)

	var ghost_label := Label.new()
	ghost_label.position = Vector2(4, 0)
	ghost_label.size = Vector2(225, 28)
	ghost_label.text = "88,888,888"
	ghost_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	ghost_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	ghost_label.add_theme_font_override("font", _get_digital_font())
	ghost_label.add_theme_font_size_override("font_size", 16)
	ghost_label.add_theme_color_override("font_color", Color(0.04, 0.20, 0.26, 0.4))
	lcd_screen.add_child(ghost_label)

	coke_val_lbl = Label.new()
	coke_val_lbl.position = Vector2(4, 0)
	coke_val_lbl.size = Vector2(225, 28)
	coke_val_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	coke_val_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	coke_val_lbl.add_theme_font_override("font", _get_digital_font())
	coke_val_lbl.add_theme_font_size_override("font_size", 16)
	coke_val_lbl.add_theme_color_override("font_color", Color("#00ffc8"))
	lcd_screen.add_child(coke_val_lbl)
	
	# Detailed Info Rows (Compact Digital List)
	var info_vbox := VBoxContainer.new()
	info_vbox.add_theme_constant_override("separation", 4)
	left_vbox.add_child(info_vbox)
	
	player_name_val = _create_info_row(info_vbox, "TÊN NGƯỜI CHƠI", "---")
	player_id_val = _create_info_row(info_vbox, "ID TÀI KHOẢN", "---")
	char_name_val = _create_info_row(info_vbox, "NHÂN VẬT", "---")
	level_val = _create_info_row(info_vbox, "CẤP ĐỘ", "1")
	exp_val = _create_info_row(info_vbox, "KINH NGHIỆM", "0 / 100")
	exp_bar = ProgressBar.new()
	exp_bar.custom_minimum_size = Vector2(245, 13)
	exp_bar.min_value = 0.0
	exp_bar.max_value = 100.0
	exp_bar.show_percentage = false
	var exp_bg := StyleBoxFlat.new()
	exp_bg.bg_color = Color("#001f5c")
	exp_bg.border_color = Color("#004db2")
	exp_bg.set_border_width_all(1)
	exp_bg.set_corner_radius_all(4)
	var exp_fill := StyleBoxFlat.new()
	exp_fill.bg_color = Color("#ffd447")
	exp_fill.set_corner_radius_all(4)
	exp_bar.add_theme_stylebox_override("background", exp_bg)
	exp_bar.add_theme_stylebox_override("fill", exp_fill)
	info_vbox.add_child(exp_bar)
	active_skin_val = _create_info_row(info_vbox, "BÓNG TRANG BỊ", "---")
	collection_val = _create_info_row(info_vbox, "BỘ SƯU TẬP", "0 / %d" % WaterBalloonSkinRegistry.get_skin_count())
	
	var left_spacer := Control.new()
	left_spacer.size_flags_vertical = SIZE_EXPAND_FILL
	left_vbox.add_child(left_spacer)
	
	# Back Button at bottom of Left Panel
	back_btn = Button.new()
	back_btn.custom_minimum_size = Vector2(245, 42)
	back_btn.text = " QUAY LẠI PHÒNG"
	back_btn.add_theme_font_size_override("font_size", 13)
	back_btn.add_theme_stylebox_override("normal", _style_3d_btn(Color("#0088dd"), Color("#0044aa"), Color("#33aaff"), 10))
	back_btn.add_theme_stylebox_override("hover", _style_3d_btn(Color("#33bbff"), Color("#0077dd"), Color("#77ddff"), 10))
	back_btn.add_theme_stylebox_override("pressed", _style_3d_pressed(Color("#0088dd"), Color("#0044aa"), 10))
	back_btn.add_theme_color_override("font_color", Color.WHITE)
	if ResourceLoader.exists(BACK_ARROW_PATH):
		back_btn.icon = load(BACK_ARROW_PATH)
		back_btn.expand_icon = true
	back_btn.pressed.connect(func(): closed.emit(); visible = false)
	left_vbox.add_child(back_btn)
	
	# -------------------------------------------------------------
	# 2. RIGHT PANEL: INVENTORY & STORAGE (640px)
	# -------------------------------------------------------------
	var right_panel := PanelContainer.new()
	right_panel.custom_minimum_size = Vector2(640, 665)
	right_panel.size_flags_horizontal = SIZE_EXPAND_FILL
	right_panel.add_theme_stylebox_override("panel", _style_panel_right())
	main_split.add_child(right_panel)
	
	var right_vbox := VBoxContainer.new()
	right_vbox.add_theme_constant_override("separation", 8)
	right_panel.add_child(right_vbox)
	
	# Right Header
	var right_hdr_hbox := HBoxContainer.new()
	right_vbox.add_child(right_hdr_hbox)
	
	var r_title := Label.new()
	r_title.text = "KHO ĐỒ • TRANG BỊ NHÂN VẬT"
	r_title.add_theme_font_size_override("font_size", 20)
	r_title.add_theme_color_override("font_color", Color.WHITE)
	r_title.add_theme_color_override("font_outline_color", Color("#040d16"))
	r_title.add_theme_constant_override("outline_size", 4)
	right_hdr_hbox.add_child(r_title)
	
	var r_spacer := Control.new()
	r_spacer.size_flags_horizontal = SIZE_EXPAND_FILL
	right_hdr_hbox.add_child(r_spacer)
	
	# Category Tabs
	var tabs_hbox := HBoxContainer.new()
	tabs_hbox.add_theme_constant_override("separation", 6)
	right_vbox.add_child(tabs_hbox)
	
	var categories := [
		{"id": "all", "label": "TẤT CẢ"},
		{"id": "balloon", "label": "BÓNG"},
		{"id": "head_accessory", "label": "PHỤ KIỆN"},
		{"id": "flag", "label": "CỜ"},
		{"id": "player_background", "label": "NỀN"}
	]
	for cat in categories:
		var c_btn := Button.new()
		c_btn.text = cat.label
		c_btn.custom_minimum_size = Vector2(90, 30)
		c_btn.add_theme_font_size_override("font_size", 11)
		_style_tab_button(c_btn, cat.id == current_category)
		c_btn.pressed.connect(func(): _on_category_selected(cat.id))
		tabs_hbox.add_child(c_btn)
		category_buttons[cat.id] = c_btn
		
	# Inventory Content Split (Grid on left ~430px, Preview on right ~190px)
	var content_split := HBoxContainer.new()
	content_split.size_flags_vertical = SIZE_EXPAND_FILL
	content_split.add_theme_constant_override("separation", 8)
	right_vbox.add_child(content_split)
	
	# Grid Container Frame (430px)
	var grid_frame := PanelContainer.new()
	grid_frame.custom_minimum_size = Vector2(430, 0)
	grid_frame.size_flags_horizontal = SIZE_EXPAND_FILL
	grid_frame.size_flags_vertical = SIZE_EXPAND_FILL
	var gf_style := StyleBoxFlat.new()
	gf_style.bg_color = Color("#054e9e")
	gf_style.border_color = Color("#007cd8")
	gf_style.set_border_width_all(2)
	gf_style.border_width_bottom = 4
	gf_style.set_corner_radius_all(10)
	gf_style.content_margin_left = 6
	gf_style.content_margin_right = 6
	gf_style.content_margin_top = 6
	gf_style.content_margin_bottom = 6
	grid_frame.add_theme_stylebox_override("panel", gf_style)
	content_split.add_child(grid_frame)
	
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.size_flags_horizontal = SIZE_EXPAND_FILL
	scroll.size_flags_vertical = SIZE_EXPAND_FILL
	grid_frame.add_child(scroll)
	
	item_grid = GridContainer.new()
	item_grid.columns = 4
	item_grid.add_theme_constant_override("h_separation", 6)
	item_grid.add_theme_constant_override("v_separation", 6)
	item_grid.size_flags_horizontal = SIZE_EXPAND_FILL
	scroll.add_child(item_grid)
	
	empty_grid_label = Label.new()
	empty_grid_label.text = "CHƯA CÓ VẬT PHẨM TRONG MỤC NÀY"
	empty_grid_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	empty_grid_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	empty_grid_label.add_theme_font_size_override("font_size", 13)
	empty_grid_label.add_theme_color_override("font_color", Color("#c2e4ff"))
	empty_grid_label.size_flags_horizontal = SIZE_EXPAND_FILL
	empty_grid_label.size_flags_vertical = SIZE_EXPAND_FILL
	empty_grid_label.visible = false
	grid_frame.add_child(empty_grid_label)
	
	# Preview Panel (195px)
	var prev_frame := PanelContainer.new()
	prev_frame.custom_minimum_size = Vector2(195, 0)
	prev_frame.size_flags_horizontal = SIZE_SHRINK_END
	var pf_style := StyleBoxFlat.new()
	pf_style.bg_color = Color("#054e9e")
	pf_style.border_color = Color("#007cd8")
	pf_style.set_border_width_all(2)
	pf_style.border_width_bottom = 4
	pf_style.set_corner_radius_all(10)
	pf_style.content_margin_left = 8
	pf_style.content_margin_right = 8
	pf_style.content_margin_top = 8
	pf_style.content_margin_bottom = 8
	prev_frame.add_theme_stylebox_override("panel", pf_style)
	content_split.add_child(prev_frame)
	
	var prev_vbox := VBoxContainer.new()
	prev_vbox.add_theme_constant_override("separation", 6)
	prev_frame.add_child(prev_vbox)
	
	var p_hdr := Label.new()
	p_hdr.text = "XEM TRƯỚC VẬT PHẨM"
	p_hdr.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	p_hdr.add_theme_font_size_override("font_size", 11)
	p_hdr.add_theme_color_override("font_color", Color("#c2e4ff"))
	prev_vbox.add_child(p_hdr)
	
	# Artwork box
	var p_art_frame := PanelContainer.new()
	p_art_frame.custom_minimum_size = Vector2(140, 140)
	var paf_style := StyleBoxFlat.new()
	paf_style.bg_color = Color("#064d9f")
	paf_style.border_color = Color("#007cd8")
	paf_style.set_border_width_all(2)
	paf_style.border_width_bottom = 4
	paf_style.set_corner_radius_all(10)
	p_art_frame.add_theme_stylebox_override("panel", paf_style)
	prev_vbox.add_child(p_art_frame)
	
	var p_art_center := CenterContainer.new()
	p_art_center.anchors_preset = PRESET_FULL_RECT
	p_art_frame.add_child(p_art_center)
	
	preview_art = TextureRect.new()
	preview_art.custom_minimum_size = Vector2(120, 120)
	preview_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	preview_art.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	p_art_center.add_child(preview_art)
	
	preview_name = Label.new()
	preview_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	preview_name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	preview_name.add_theme_font_size_override("font_size", 14)
	preview_name.add_theme_color_override("font_color", Color.WHITE)
	preview_name.add_theme_color_override("font_outline_color", Color("#040d16"))
	preview_name.add_theme_constant_override("outline_size", 4)
	prev_vbox.add_child(preview_name)
	
	preview_rarity = Label.new()
	preview_rarity.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	preview_rarity.add_theme_font_size_override("font_size", 11)
	preview_rarity.add_theme_color_override("font_color", Color("#ffd040"))
	prev_vbox.add_child(preview_rarity)
	
	preview_status = Label.new()
	preview_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	preview_status.add_theme_font_size_override("font_size", 12)
	preview_status.add_theme_color_override("font_color", Color("#42e0a2"))
	prev_vbox.add_child(preview_status)
	
	var p_spacer := Control.new()
	p_spacer.size_flags_vertical = SIZE_EXPAND_FILL
	prev_vbox.add_child(p_spacer)
	
	preview_action_btn = Button.new()
	preview_action_btn.custom_minimum_size.y = 40
	preview_action_btn.add_theme_font_size_override("font_size", 13)
	preview_action_btn.pressed.connect(_on_action_button_pressed)
	prev_vbox.add_child(preview_action_btn)

func _create_info_row(parent: Control, label_text: String, default_val: String) -> Label:
	var hbox := HBoxContainer.new()
	hbox.custom_minimum_size.y = 26
	parent.add_child(hbox)
	
	var lbl_box := PanelContainer.new()
	lbl_box.custom_minimum_size = Vector2(95, 26)
	var ls := StyleBoxFlat.new()
	ls.bg_color = Color("#0054a8")
	ls.border_color = Color("#0084dc")
	ls.set_border_width_all(1)
	ls.border_width_bottom = 2
	ls.set_corner_radius_all(6)
	lbl_box.add_theme_stylebox_override("panel", ls)
	hbox.add_child(lbl_box)
	
	var lbl := Label.new()
	lbl.text = label_text
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 9)
	lbl.add_theme_color_override("font_color", Color("#c2e4ff"))
	lbl_box.add_child(lbl)
	
	var val_box := PanelContainer.new()
	val_box.size_flags_horizontal = SIZE_EXPAND_FILL
	var vs := StyleBoxFlat.new()
	vs.bg_color = Color("#003d82")
	vs.border_color = Color("#0060b8")
	vs.set_border_width_all(1)
	vs.border_width_bottom = 2
	vs.set_corner_radius_all(6)
	vs.content_margin_left = 6
	vs.content_margin_right = 6
	val_box.add_theme_stylebox_override("panel", vs)
	hbox.add_child(val_box)
	
	var val := Label.new()
	val.text = default_val
	val.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	val.add_theme_font_size_override("font_size", 11)
	val.add_theme_color_override("font_color", Color.WHITE)
	val.clip_text = true
	val.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	val_box.add_child(val)
	return val

# ==============================================================================
# LOGIC & BINDING
# ==============================================================================
func _update_left_panel() -> void:
	if not has_node("/root/GameSession"):
		return
	var nickname: String = GameSession.player_nickname
	player_name_val.text = nickname if nickname != "" else "Player"
	var uid: int = 1
	if has_node("/root/AccountDatabase"):
		uid = AccountDatabase.current_user_id if AccountDatabase.current_user_id > 0 else 1
	player_id_val.text = "#%05d" % uid
	
	if not characters.is_empty():
		var char_data := characters[selected_character_index]
		char_name_val.text = char_data.name
		_refresh_character_card(char_data)
		
	var exp_req: int = GameSession.experience_required_for_level()
	level_val.text = "%02d" % GameSession.level
	exp_val.text = "%04d / %04d (%d%%)" % [GameSession.experience, exp_req, int(GameSession.experience_percent())]
	exp_bar.max_value = exp_req
	exp_bar.value = GameSession.experience
	
	var active_skin_name := "Default"
	var active_skin_def := WaterBalloonSkinRegistry.get_skin(GameSession.selected_balloon_skin)
	if active_skin_def != null:
		active_skin_name = active_skin_def.display_name
	active_skin_val.text = active_skin_name
	
	var total_skins_count: int = WaterBalloonSkinRegistry.get_all_skin_ids().size()
	collection_val.text = "%d / %d" % [all_owned_skins.size(), max(total_skins_count, all_owned_skins.size())]
	coke_val_lbl.text = _format_digital_number(GameSession.cokecy)

func _refresh_character_card(char_data: Dictionary) -> void:
	var def: CharacterDefinition = char_data.get("definition", null)
	var active_eq: Dictionary = PlayerEquipmentService.current_equipment()
	player_card_preview.configure(def, active_eq, GameSession.player_nickname)

func _on_character_option_selected(idx: int) -> void:
	selected_character_index = idx
	if idx >= 0 and idx < characters.size():
		GameSession.selected_character_id = characters[idx].id
		GameSession.save_profile()
		_update_left_panel()
		character_selected.emit(characters[idx].id)

func _style_tab_button(btn: Button, active: bool) -> void:
	if active:
		btn.add_theme_stylebox_override("normal", _style_3d_pressed(Color("#0088dd"), Color("#0044aa"), 6))
		btn.add_theme_color_override("font_color", Color.WHITE)
		btn.add_theme_color_override("font_outline_color", Color("#002b55"))
		btn.add_theme_constant_override("outline_size", 3)
	else:
		btn.add_theme_stylebox_override("normal", _style_3d_btn(Color("#08121c"), Color("#040a10"), Color("#182536"), 6))
		btn.add_theme_color_override("font_color", Color("#85c2ee"))
		btn.add_theme_color_override("font_outline_color", Color("#001122"))
		btn.add_theme_constant_override("outline_size", 2)

func _on_category_selected(cat_id: String) -> void:
	current_category = cat_id
	for id in category_buttons:
		_style_tab_button(category_buttons[id], id == current_category)
	_populate_grid()

func _get_filtered_skins() -> Array[Dictionary]:
	var list: Array[Dictionary] = []
	for s in all_owned_skins:
		var match_cat := false
		if current_category == "all":
			match_cat = true
		else:
			match_cat = str(s.get("category", "balloon")) == current_category
			
		if match_cat:
			list.append(s)
	return list

func _populate_grid() -> void:
	for c in item_grid.get_children():
		c.queue_free()
	item_cards.clear()
	
	var list := _get_filtered_skins()
	empty_grid_label.visible = list.is_empty()
	
	for skin in list:
		var skin_id: StringName = skin.id
		var card := PanelContainer.new()
		card.custom_minimum_size = Vector2(98, 126)
		card.size_flags_horizontal = SIZE_EXPAND_FILL
		_style_card(card, skin_id == selected_skin_id)
		
		var card_vbox := VBoxContainer.new()
		card_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		card_vbox.mouse_filter = MOUSE_FILTER_IGNORE
		card_vbox.add_theme_constant_override("separation", 2)
		card.add_child(card_vbox)
		
		var img_box := CenterContainer.new()
		img_box.custom_minimum_size = Vector2(98, 54)
		img_box.size_flags_horizontal = SIZE_EXPAND_FILL
		img_box.size_flags_vertical = SIZE_EXPAND_FILL
		img_box.mouse_filter = MOUSE_FILTER_IGNORE
		card_vbox.add_child(img_box)
		
		var img := TextureRect.new()
		img.texture = skin.texture
		img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		img.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		img.mouse_filter = MOUSE_FILTER_IGNORE
		
		if _is_background(skin) and img.texture != null:
			img.custom_minimum_size = Vector2(82, 58)
			img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
			img.material = _rounded_slot_material(Vector2(82, 58), 6.0)
		else:
			img.custom_minimum_size = Vector2(46, 46)
			img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			img.material = null
			if str(skin.get("kind", "balloon")) == "balloon":
				img.pivot_offset = Vector2(23, 23)
				img.scale = Vector2.ONE * WaterBalloonSkinRegistry.get_icon_scale(skin_id)
			
		img_box.add_child(img)
		
		var name_lbl := Label.new()
		name_lbl.text = skin.name
		name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_lbl.add_theme_font_size_override("font_size", 10)
		name_lbl.add_theme_color_override("font_color", Color.WHITE)
		name_lbl.clip_text = true
		name_lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		card_vbox.add_child(name_lbl)
		
		var tag_lbl := Label.new()
		var is_active := _item_active(skin)
		tag_lbl.text = "ĐANG DÙNG" if is_active else "ĐÃ MỞ"
		tag_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tag_lbl.add_theme_font_size_override("font_size", 9)
		tag_lbl.add_theme_color_override("font_color", Color("#00ffcc") if is_active else Color("#88c4ee"))
		card_vbox.add_child(tag_lbl)
		
		var click_btn := Button.new()
		click_btn.set_anchors_preset(PRESET_FULL_RECT)
		click_btn.flat = true
		click_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		click_btn.pressed.connect(func(): _select_item(skin_id))
		card.add_child(click_btn)
		
		item_grid.add_child(card)
		item_cards[skin_id] = card
		
	if not list.is_empty() and not item_cards.has(selected_skin_id):
		_select_item(list[0].id)

func _style_card(card: PanelContainer, selected: bool) -> void:
	if selected:
		card.add_theme_stylebox_override("panel", _style_card_box(Color("#0e68d0"), Color("#ffd84a"), 3))
	else:
		card.add_theme_stylebox_override("panel", _style_card_box(Color("#064d9f"), Color("#0084dc"), 2))

func _select_item(skin_id: StringName) -> void:
	selected_skin_id = skin_id
	for id in item_cards:
		if is_instance_valid(item_cards[id]):
			_style_card(item_cards[id], id == selected_skin_id)
	_update_preview(skin_id)

func _update_preview(skin_id: StringName) -> void:
	var skin_dict: Dictionary = {}
	for s in all_owned_skins:
		if s.id == skin_id:
			skin_dict = s
			break
	if skin_dict.is_empty():
		return
		
	preview_art.texture = skin_dict.get("hd_texture", skin_dict.texture)
	if _is_background(skin_dict) and preview_art.texture != null:
		preview_art.scale = Vector2.ONE
		preview_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		preview_art.custom_minimum_size = Vector2(120, 85)
		preview_art.material = _rounded_slot_material(Vector2(120, 85), 10.0)
	else:
		preview_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		preview_art.custom_minimum_size = Vector2(120, 120)
		preview_art.material = null
		if str(skin_dict.get("kind", "balloon")) == "balloon":
			preview_art.pivot_offset = Vector2(60, 60)
			preview_art.scale = Vector2.ONE * WaterBalloonSkinRegistry.get_runtime_scale(skin_id)
		else:
			preview_art.scale = Vector2.ONE
	preview_name.text = skin_dict.name
	preview_rarity.text = "ĐỘ HIẾM: %s" % skin_dict.rarity.to_upper()
	
	var is_active := _item_active(skin_dict)
	if is_active:
		preview_status.text = "TRẠNG THÁI: ĐANG TRANG BỊ"
		preview_status.add_theme_color_override("font_color", Color("#00ffcc"))
		var can_unequip := str(skin_dict.get("category", "")) == str(CosmeticDefinition.HEAD_ACCESSORY)
		preview_action_btn.text = "THÁO" if can_unequip else "ĐANG DÙNG"
		preview_action_btn.disabled = not can_unequip
		preview_action_btn.add_theme_stylebox_override("normal", _style_3d_btn(Color("#004e8c"), Color("#003560"), Color("#0070c0"), 8))
		preview_action_btn.add_theme_stylebox_override("disabled", _style_3d_btn(Color("#004e8c"), Color("#003560"), Color("#0070c0"), 8))
		preview_action_btn.add_theme_color_override("font_color", Color("#7ee8ff"))
	else:
		preview_status.text = "TRẠNG THÁI: ĐÃ SỞ HỮU"
		preview_status.add_theme_color_override("font_color", Color("#88c4ee"))
		preview_action_btn.text = "TRANG BỊ"
		preview_action_btn.disabled = false
		preview_action_btn.add_theme_stylebox_override("normal", _style_3d_btn(Color("#ffa600"), Color("#cc6600"), Color("#ffcc55"), 8))
		preview_action_btn.add_theme_stylebox_override("hover", _style_3d_btn(Color("#ffbb33"), Color("#e67700"), Color("#ffdd77"), 8))
		preview_action_btn.add_theme_stylebox_override("pressed", _style_3d_pressed(Color("#e68a00"), Color("#994400"), 8))
		preview_action_btn.add_theme_color_override("font_color", Color.WHITE)

func _item_active(skin_dict: Dictionary) -> bool:
	if str(skin_dict.get("kind", "")) == "balloon":
		return GameSession.selected_balloon_skin == skin_dict.id
	var category: String = str(skin_dict.get("category", ""))
	var eq: Dictionary = PlayerEquipmentService.current_equipment()
	var active_id: String = str(eq.get(category, ""))
	return active_id == str(skin_dict.id)

func _on_action_button_pressed() -> void:
	if selected_skin_id == &"":
		return
	var skin_dict: Dictionary = {}
	for s in all_owned_skins:
		if s.id == selected_skin_id:
			skin_dict = s
			break
	if skin_dict.is_empty():
		return
		
	if str(skin_dict.get("kind", "")) == "balloon":
		GameSession.selected_balloon_skin = selected_skin_id
		GameSession.save_profile()
	else:
		var category: String = str(skin_dict.get("category", ""))
		if category == str(CosmeticDefinition.HEAD_ACCESSORY) and _item_active(skin_dict):
			PlayerEquipmentService.unequip(StringName(category))
		else:
			PlayerEquipmentService.equip(StringName(category), selected_skin_id)
		
	_update_left_panel()
	_populate_grid()
	_update_preview(selected_skin_id)
	skin_selected.emit(selected_skin_id)

func _on_cokecy_changed(_val: int) -> void:
	if coke_val_lbl != null:
		coke_val_lbl.text = str(GameSession.cokecy)

func _on_progression_changed() -> void:
	_update_left_panel()

func _on_equipment_changed(_equipped: Dictionary = {}) -> void:
	_load_owned_skins()
	_update_left_panel()
	_populate_grid()
	if selected_skin_id != &"":
		_update_preview(selected_skin_id)

func refresh() -> void:
	_load_owned_skins()
	_update_left_panel()
	_populate_grid()
	if selected_skin_id != &"":
		_update_preview(selected_skin_id)
