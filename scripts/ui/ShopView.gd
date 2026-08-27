class_name ShopView
extends Control
static var _digital_font: FontFile = null
static func _get_digital_font() -> FontFile:
	if _digital_font == null:
		_digital_font = FontFile.new()
		_digital_font.load_dynamic_font("res://assets/fonts/DSEG7Classic-Bold.ttf")
	return _digital_font


signal closed
signal skin_purchased(skin_id: StringName)
signal skin_selected(skin_id: StringName)
signal cosmetic_purchased(cosmetic_id: StringName)
signal equipment_selected(category: StringName, cosmetic_id: StringName)

const COKE_ICON_PATH := "res://assets/ui/coke_coin.png"
const BACK_ARROW_PATH := "res://assets/ui/icons/arrow_back.svg"
const ROUND_CLIP_SHADER := preload("res://assets/shaders/rounded_clip.gdshader")

var current_category: String = "all"
var current_filter: String = "all"
var selected_skin_id: StringName = &""
var all_skins: Array[Dictionary] = []

# UI Node References
var outer_panel: PanelContainer
var cokecy_label: Label
var owned_count_label: Label
var category_buttons: Dictionary = {} # cat_key -> Button
var filter_buttons: Dictionary = {}   # filter_key -> Button
var item_grid: GridContainer
var empty_grid_label: Label
var item_cards: Dictionary = {}       # skin_id -> PanelContainer

# Preview Panel References
var preview_art: TextureRect
var preview_name: Label
var preview_rarity: Label
var preview_price_info: Label
var preview_status: Label
var preview_action_btn: Button
var back_button: Button
var purchase_pending: bool = false
var pending_cosmetic_id: StringName = &""
var pending_balloon_id: StringName = &""

func _is_background(skin: Dictionary) -> bool:
	return skin.get("kind", "") == "cosmetic" and str(skin.get("category", "")) == "player_background"

func _rounded_art_material(rect_size: Vector2, radius: float) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = ROUND_CLIP_SHADER
	material.set_shader_parameter("rect_size", rect_size)
	material.set_shader_parameter("radius_px", radius)
	return material

func _ready() -> void:
	anchors_preset = PRESET_FULL_RECT
	mouse_filter = MOUSE_FILTER_STOP
	custom_minimum_size = Vector2(960, 720)
	position = Vector2.ZERO
	size = Vector2(960, 720)
	z_index = 100
	_load_all_skins()
	_build_ui()
	if not all_skins.is_empty():
		_select_item(all_skins[0].id)
	refresh()
	
	if has_node("/root/GameSession"):
		GameSession.cokecy_changed.connect(_on_cokecy_changed)
	if has_node("/root/AccountDatabase"):
		AccountDatabase.cosmetic_purchase_received.connect(_on_cosmetic_purchase_received)
		AccountDatabase.skin_purchase_received.connect(_on_skin_purchase_received)

func _load_all_skins() -> void:
	all_skins.clear()
	var all_ids := WaterBalloonSkinRegistry.get_all_skin_ids()
	for s_id in all_ids:
		var def := WaterBalloonSkinRegistry.get_skin(s_id)
		if def == null or def.price <= 0:
			continue
		var icon_tex: Texture2D = def.icon if def.icon != null else _get_skin_fallback(s_id)
		var hd_tex: Texture2D = _get_skin_hd_texture(s_id)
		if hd_tex == null:
			hd_tex = icon_tex
		all_skins.append({
			"id": s_id,
			"kind": "balloon",
			"category": "balloon",
			"name": def.display_name,
			"price": def.price,
			"texture": icon_tex,
			"hd_texture": hd_tex,
			"rarity": def.rarity.to_lower(),
			"theme": def.theme.to_lower(),
			"desc": def.description
		})
	for definition in CosmeticRegistry.visible_definitions():
		var art: Texture2D = definition.icon
		if art == null:
			art = definition.lobby_asset if definition.lobby_asset != null else definition.match_list_asset
		all_skins.append({
			"id": definition.id,
			"kind": "cosmetic",
			"category": definition.category,
			"name": definition.display_name,
			"price": definition.price,
			"texture": art,
			"hd_texture": definition.lobby_asset if definition.lobby_asset != null else art,
			"rarity": "default" if definition.is_default else "equipment",
			"theme": definition.category,
			"desc": definition.description,
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

# ==============================================================================
# STYLEBOX HELPERS
# ==============================================================================
func _style_outer_panel() -> StyleBoxFlat:
	var s := UITheme.panel_modal()
	s.content_margin_left = 14
	s.content_margin_right = 14
	return s

func _style_inset_panel() -> StyleBoxFlat:
	var s := UITheme.panel_inset()
	s.border_width_bottom = 3
	s.content_margin_left = 8
	s.content_margin_right = 8
	s.content_margin_top = 8
	s.content_margin_bottom = 8
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

func _style_3d_button(bg: Color, border_bottom: Color, border_top: Color, radius: int = 8) -> StyleBoxFlat:
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
	s.content_margin_left = 6
	s.content_margin_right = 6
	s.content_margin_top = 6
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
	# Shared Aqua Arcade checkerboard keeps every HUB surface visually continuous.
	var backdrop := TextureRect.new()
	backdrop.anchors_preset = PRESET_FULL_RECT
	backdrop.texture = load("res://ui/assets_generated/backgrounds/checkered_bg.png")
	backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	backdrop.stretch_mode = TextureRect.STRETCH_TILE
	backdrop.modulate = Color("#68b9ff")
	add_child(backdrop)
	
	# Centered root container filling exact 960x720 space
	var center_root := CenterContainer.new()
	center_root.anchors_preset = PRESET_FULL_RECT
	center_root.custom_minimum_size = Vector2(960, 720)
	add_child(center_root)
	
	outer_panel = PanelContainer.new()
	outer_panel.custom_minimum_size = Vector2(936, 690)
	outer_panel.add_theme_stylebox_override("panel", _style_outer_panel())
	center_root.add_child(outer_panel)
	
	var main_vbox := VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 8)
	outer_panel.add_child(main_vbox)
	
	# -------------------------------------------------------------
	# 1. TOP HEADER (SHOP text left, 2 Currency boxes right)
	# -------------------------------------------------------------
	var header := HBoxContainer.new()
	header.custom_minimum_size.y = 42
	main_vbox.add_child(header)
	
	var title_lbl := Label.new()
	title_lbl.text = "SHOP"
	title_lbl.add_theme_font_size_override("font_size", 28)
	title_lbl.add_theme_color_override("font_color", Color.WHITE)
	title_lbl.add_theme_color_override("font_outline_color", Color("#052044"))
	title_lbl.add_theme_constant_override("outline_size", 6)
	title_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	header.add_child(title_lbl)
	
	var header_spacer := Control.new()
	header_spacer.size_flags_horizontal = SIZE_EXPAND_FILL
	header.add_child(header_spacer)
	
	# Currency 1: COKE Coin
	var cur1_panel := PanelContainer.new()
	cur1_panel.add_theme_stylebox_override("panel", _style_currency_box())
	header.add_child(cur1_panel)
	var cur1_hbox := HBoxContainer.new()
	cur1_hbox.add_theme_constant_override("separation", 6)
	cur1_panel.add_child(cur1_hbox)
	if ResourceLoader.exists(COKE_ICON_PATH):
		var coke_ico := TextureRect.new()
		coke_ico.texture = load(COKE_ICON_PATH)
		coke_ico.custom_minimum_size = Vector2(22, 22)
		coke_ico.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		coke_ico.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		cur1_hbox.add_child(coke_ico)
	var c1_tag := Label.new()
	c1_tag.text = "COKE"
	c1_tag.add_theme_font_size_override("font_size", 11)
	c1_tag.add_theme_color_override("font_color", Color("#7feeff"))
	c1_tag.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	cur1_hbox.add_child(c1_tag)
	cokecy_label = Label.new()
	cokecy_label.custom_minimum_size.x = 85
	cokecy_label.text = "0"
	cokecy_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	cokecy_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	cokecy_label.add_theme_font_size_override("font_size", 14)
	cokecy_label.add_theme_color_override("font_color", Color("#00ffc4"))
	cur1_hbox.add_child(cokecy_label)
	
	# Currency 2: SỞ HỮU / OWNED SKINS
	var cur2_panel := PanelContainer.new()
	cur2_panel.add_theme_stylebox_override("panel", _style_currency_box())
	header.add_child(cur2_panel)
	var cur2_hbox := HBoxContainer.new()
	cur2_hbox.add_theme_constant_override("separation", 6)
	cur2_panel.add_child(cur2_hbox)
	var c2_tag := Label.new()
	c2_tag.text = "SỞ HỮU"
	c2_tag.add_theme_font_size_override("font_size", 11)
	c2_tag.add_theme_color_override("font_color", Color("#ffd040"))
	c2_tag.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	cur2_hbox.add_child(c2_tag)
	owned_count_label = Label.new()
	owned_count_label.custom_minimum_size.x = 80
	owned_count_label.text = "0 / %d" % WaterBalloonSkinRegistry.get_skin_count()
	owned_count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	owned_count_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	owned_count_label.add_theme_font_size_override("font_size", 14)
	owned_count_label.add_theme_color_override("font_color", Color.WHITE)
	cur2_hbox.add_child(owned_count_label)
	
	# -------------------------------------------------------------
	# 2. MAIN BODY (Fixed Widths: Sidebar=140px, Center=515px, Preview=235px)
	# -------------------------------------------------------------
	var body_hbox := HBoxContainer.new()
	body_hbox.size_flags_vertical = SIZE_EXPAND_FILL
	body_hbox.add_theme_constant_override("separation", 8)
	main_vbox.add_child(body_hbox)
	
	# Left Category Sidebar (FIXED 140px)
	var sidebar := PanelContainer.new()
	sidebar.custom_minimum_size = Vector2(140, 0)
	sidebar.size_flags_horizontal = SIZE_SHRINK_BEGIN
	sidebar.add_theme_stylebox_override("panel", _style_inset_panel())
	body_hbox.add_child(sidebar)
	var sb_vbox := VBoxContainer.new()
	sb_vbox.add_theme_constant_override("separation", 8)
	sidebar.add_child(sb_vbox)
	
	var cat_hdr := Label.new()
	cat_hdr.text = "DANH MỤC"
	cat_hdr.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cat_hdr.add_theme_font_size_override("font_size", 12)
	cat_hdr.add_theme_color_override("font_color", Color("#5dd0fd"))
	cat_hdr.add_theme_color_override("font_outline_color", Color("#052044"))
	cat_hdr.add_theme_constant_override("outline_size", 3)
	sb_vbox.add_child(cat_hdr)
	
	var categories := [
		{"id": "all", "label": "TẤT CẢ"},
		{"id": "balloon", "label": "BÓNG NƯỚC"},
		{"id": "head_accessory", "label": "PHỤ KIỆN"},
		{"id": "flag", "label": "CỜ"},
		{"id": "player_background", "label": "NỀN"},
		{"id": "player_frame", "label": "KHUNG"}
	]
	
	for cat in categories:
		var btn := Button.new()
		btn.text = cat.label
		btn.custom_minimum_size.y = 38
		btn.add_theme_font_size_override("font_size", 12)
		_style_category_button(btn, cat.id == current_category)
		btn.pressed.connect(func(): _on_category_selected(cat.id))
		sb_vbox.add_child(btn)
		category_buttons[cat.id] = btn
		
	# Center Content Area (FIXED 515px, ALWAYS STAYS 515px!)
	var center_vbox := VBoxContainer.new()
	center_vbox.custom_minimum_size = Vector2(515, 0)
	center_vbox.size_flags_horizontal = SIZE_EXPAND_FILL
	center_vbox.size_flags_vertical = SIZE_EXPAND_FILL
	center_vbox.add_theme_constant_override("separation", 8)
	body_hbox.add_child(center_vbox)
	
	# Filter Tabs
	var tabs_hbox := HBoxContainer.new()
	tabs_hbox.add_theme_constant_override("separation", 8)
	center_vbox.add_child(tabs_hbox)
	
	var filters := [
		{"id": "all", "label": "TẤT CẢ"},
		{"id": "unowned", "label": "CHƯA SỞ HỮU"},
		{"id": "owned", "label": "ĐÃ SỞ HỮU"},
		{"id": "price_asc", "label": "GIÁ RẺ"}
	]
	for flt in filters:
		var t_btn := Button.new()
		t_btn.text = flt.label
		t_btn.custom_minimum_size = Vector2(90, 30)
		t_btn.add_theme_font_size_override("font_size", 11)
		_style_filter_button(t_btn, flt.id == current_filter)
		t_btn.pressed.connect(func(): _on_filter_selected(flt.id))
		tabs_hbox.add_child(t_btn)
		filter_buttons[flt.id] = t_btn
		
	# Scrollable Grid Container (FIXED 515px minimum width)
	var grid_panel := PanelContainer.new()
	grid_panel.custom_minimum_size = Vector2(515, 0)
	grid_panel.size_flags_horizontal = SIZE_EXPAND_FILL
	grid_panel.size_flags_vertical = SIZE_EXPAND_FILL
	grid_panel.add_theme_stylebox_override("panel", _style_inset_panel())
	center_vbox.add_child(grid_panel)
	
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(495, 0)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.size_flags_horizontal = SIZE_EXPAND_FILL
	scroll.size_flags_vertical = SIZE_EXPAND_FILL
	grid_panel.add_child(scroll)
	
	item_grid = GridContainer.new()
	item_grid.columns = 4
	item_grid.add_theme_constant_override("h_separation", 8)
	item_grid.add_theme_constant_override("v_separation", 8)
	item_grid.size_flags_horizontal = SIZE_EXPAND_FILL
	scroll.add_child(item_grid)
	
	empty_grid_label = Label.new()
	empty_grid_label.text = "ĐÃ SỞ HỮU TOÀN BỘ BÓNG NƯỚC"
	empty_grid_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	empty_grid_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	empty_grid_label.add_theme_font_size_override("font_size", 14)
	empty_grid_label.add_theme_color_override("font_color", Color("#5dd0fd"))
	empty_grid_label.size_flags_horizontal = SIZE_EXPAND_FILL
	empty_grid_label.size_flags_vertical = SIZE_EXPAND_FILL
	empty_grid_label.visible = false
	grid_panel.add_child(empty_grid_label)
	
	# Right Preview Panel (FIXED 235px)
	var preview_panel := PanelContainer.new()
	preview_panel.custom_minimum_size = Vector2(235, 0)
	preview_panel.size_flags_horizontal = SIZE_SHRINK_END
	preview_panel.add_theme_stylebox_override("panel", _style_inset_panel())
	body_hbox.add_child(preview_panel)
	
	var prev_vbox := VBoxContainer.new()
	prev_vbox.add_theme_constant_override("separation", 8)
	preview_panel.add_child(prev_vbox)
	
	var prev_hdr := Label.new()
	prev_hdr.text = "XEM TRƯỚC"
	prev_hdr.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prev_hdr.add_theme_font_size_override("font_size", 13)
	prev_hdr.add_theme_color_override("font_color", Color("#5dd0fd"))
	prev_hdr.add_theme_color_override("font_outline_color", Color("#052044"))
	prev_hdr.add_theme_constant_override("outline_size", 3)
	prev_vbox.add_child(prev_hdr)
	
	# Large Artwork frame
	var art_frame := PanelContainer.new()
	art_frame.custom_minimum_size = Vector2(170, 170)
	var art_frame_style := StyleBoxFlat.new()
	art_frame_style.bg_color = Color("#021024")
	art_frame_style.border_color = Color("#1c64a4")
	art_frame_style.set_border_width_all(2)
	art_frame_style.set_corner_radius_all(12)
	art_frame.add_theme_stylebox_override("panel", art_frame_style)
	prev_vbox.add_child(art_frame)
	
	var art_center := CenterContainer.new()
	art_center.anchors_preset = PRESET_FULL_RECT
	art_frame.add_child(art_center)
	
	preview_art = TextureRect.new()
	preview_art.custom_minimum_size = Vector2(145, 145)
	preview_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	preview_art.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	art_center.add_child(preview_art)
	
	preview_name = Label.new()
	preview_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	preview_name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	preview_name.add_theme_font_size_override("font_size", 15)
	preview_name.add_theme_color_override("font_color", Color.WHITE)
	preview_name.add_theme_color_override("font_outline_color", Color("#052044"))
	preview_name.add_theme_constant_override("outline_size", 4)
	prev_vbox.add_child(preview_name)
	
	preview_rarity = Label.new()
	preview_rarity.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	preview_rarity.add_theme_font_size_override("font_size", 11)
	preview_rarity.add_theme_color_override("font_color", Color("#ffd040"))
	prev_vbox.add_child(preview_rarity)
	
	preview_price_info = Label.new()
	preview_price_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	preview_price_info.add_theme_font_size_override("font_size", 14)
	preview_price_info.add_theme_color_override("font_color", Color("#ffd040"))
	preview_price_info.add_theme_color_override("font_outline_color", Color("#052044"))
	preview_price_info.add_theme_constant_override("outline_size", 3)
	prev_vbox.add_child(preview_price_info)
	
	preview_status = Label.new()
	preview_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	preview_status.add_theme_font_size_override("font_size", 13)
	preview_status.add_theme_color_override("font_color", Color("#22d2ff"))
	prev_vbox.add_child(preview_status)
	
	var prev_spacer := Control.new()
	prev_spacer.size_flags_vertical = SIZE_EXPAND_FILL
	prev_vbox.add_child(prev_spacer)
	
	preview_action_btn = Button.new()
	preview_action_btn.custom_minimum_size.y = 42
	preview_action_btn.add_theme_font_size_override("font_size", 13)
	preview_action_btn.pressed.connect(_on_action_button_pressed)
	prev_vbox.add_child(preview_action_btn)
	
	# -------------------------------------------------------------
	# 3. BOTTOM BAR (Back Button at bottom-left)
	# -------------------------------------------------------------
	var bottom_bar := HBoxContainer.new()
	main_vbox.add_child(bottom_bar)
	
	back_button = Button.new()
	back_button.custom_minimum_size = Vector2(44, 44)
	back_button.tooltip_text = "Quay lại"
	back_button.add_theme_stylebox_override("normal", _style_3d_button(Color("#0088dd"), Color("#0044aa"), Color("#33aaff"), 10))
	back_button.add_theme_stylebox_override("hover", _style_3d_button(Color("#33bbff"), Color("#0077dd"), Color("#77ddff"), 10))
	back_button.add_theme_stylebox_override("pressed", _style_3d_pressed(Color("#0088dd"), Color("#0044aa"), 10))
	if ResourceLoader.exists(BACK_ARROW_PATH):
		back_button.icon = load(BACK_ARROW_PATH)
		back_button.expand_icon = true
	else:
		back_button.text = "←"
		back_button.add_theme_font_size_override("font_size", 22)
		back_button.add_theme_color_override("font_color", Color("#fbc02d"))
	back_button.pressed.connect(func(): closed.emit(); visible = false)
	bottom_bar.add_child(back_button)

# ==============================================================================
# LOGIC & FILTERING
# ==============================================================================
func _style_category_button(btn: Button, selected: bool) -> void:
	if selected:
		btn.add_theme_stylebox_override("normal", _style_3d_button(Color("#0099ee"), Color("#0055aa"), Color("#66ccff"), 8))
		btn.add_theme_stylebox_override("hover", _style_3d_button(Color("#33bbff"), Color("#0077dd"), Color("#88ddff"), 8))
		btn.add_theme_color_override("font_color", Color.WHITE)
		btn.add_theme_color_override("font_outline_color", Color("#002b55"))
		btn.add_theme_constant_override("outline_size", 4)
	else:
		btn.add_theme_stylebox_override("normal", _style_3d_button(Color("#07386c"), Color("#031f3e"), Color("#145894"), 8))
		btn.add_theme_stylebox_override("hover", _style_3d_button(Color("#0c4a8a"), Color("#052c54"), Color("#2c82cc"), 8))
		btn.add_theme_color_override("font_color", Color("#b0d8ff"))
		btn.add_theme_color_override("font_outline_color", Color("#001122"))
		btn.add_theme_constant_override("outline_size", 2)

func _style_filter_button(btn: Button, selected: bool) -> void:
	if selected:
		btn.add_theme_stylebox_override("normal", _style_3d_button(Color("#0099ee"), Color("#0055aa"), Color("#66ccff"), 6))
		btn.add_theme_color_override("font_color", Color.WHITE)
		btn.add_theme_color_override("font_outline_color", Color("#002b55"))
		btn.add_theme_constant_override("outline_size", 3)
	else:
		btn.add_theme_stylebox_override("normal", _style_3d_button(Color("#06284e"), Color("#031428"), Color("#0e4478"), 6))
		btn.add_theme_color_override("font_color", Color("#85c2ee"))
		btn.add_theme_color_override("font_outline_color", Color("#001122"))
		btn.add_theme_constant_override("outline_size", 2)

func _on_category_selected(cat_id: String) -> void:
	current_category = cat_id
	for id in category_buttons:
		_style_category_button(category_buttons[id], id == current_category)
	_populate_grid()

func _on_filter_selected(filter_id: String) -> void:
	current_filter = filter_id
	for id in filter_buttons:
		_style_filter_button(filter_buttons[id], id == current_filter)
	_populate_grid()

func _get_filtered_skins() -> Array[Dictionary]:
	var list: Array[Dictionary] = []
	for s in all_skins:
		var match_cat := false
		if current_category == "all":
			match_cat = true
		else:
			match_cat = str(s.get("category", "balloon")) == current_category
			
		if not match_cat:
			continue
			
		var owned := _item_owned(s)
		if current_filter == "unowned" and owned:
			continue
		if current_filter == "owned" and not owned:
			continue
			
		list.append(s)
		
	if current_filter == "price_asc":
		list.sort_custom(func(a, b): return a.price < b.price)
		
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
		card.custom_minimum_size = Vector2(116, 138)
		card.size_flags_horizontal = SIZE_EXPAND_FILL
		_style_card(card, skin_id == selected_skin_id)
		
		var card_vbox := VBoxContainer.new()
		card_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		card_vbox.mouse_filter = MOUSE_FILTER_IGNORE
		card_vbox.add_theme_constant_override("separation", 2)
		card.add_child(card_vbox)
		
		# Center box for balloon image
		var img_box := CenterContainer.new()
		img_box.custom_minimum_size = Vector2(116, 62)
		img_box.size_flags_horizontal = SIZE_EXPAND_FILL
		img_box.size_flags_vertical = SIZE_EXPAND_FILL
		img_box.mouse_filter = MOUSE_FILTER_IGNORE
		card_vbox.add_child(img_box)
		
		var img := TextureRect.new()
		img.texture = skin.texture
		img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		img.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		img.mouse_filter = MOUSE_FILTER_IGNORE
		if _is_background(skin) and skin.texture != null:
			img.custom_minimum_size = Vector2(96, 68)
			img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
			img.material = _rounded_art_material(Vector2(96, 68), 9.0)
		else:
			img.custom_minimum_size = Vector2(54, 54)
			img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			if str(skin.get("kind", "balloon")) == "balloon":
				img.pivot_offset = Vector2(27, 27)
				img.scale = Vector2.ONE * WaterBalloonSkinRegistry.get_icon_scale(skin_id)
		img_box.add_child(img)
		
		var name_lbl := Label.new()
		name_lbl.text = skin.name
		name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_lbl.add_theme_font_size_override("font_size", 10)
		name_lbl.add_theme_color_override("font_color", Color.WHITE)
		name_lbl.add_theme_color_override("font_outline_color", Color("#052044"))
		name_lbl.add_theme_constant_override("outline_size", 3)
		name_lbl.clip_text = true
		name_lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		name_lbl.mouse_filter = MOUSE_FILTER_IGNORE
		card_vbox.add_child(name_lbl)
		
		var owned := _item_owned(skin)
		var price_badge := Label.new()
		price_badge.text = "ĐÃ MỞ" if owned else "%s" % _format_number(skin.price)
		price_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		price_badge.add_theme_font_size_override("font_size", 11)
		price_badge.add_theme_color_override("font_color", Color("#22d2ff") if owned else Color("#ffd040"))
		price_badge.add_theme_color_override("font_outline_color", Color("#052044"))
		price_badge.add_theme_constant_override("outline_size", 3)
		price_badge.mouse_filter = MOUSE_FILTER_IGNORE
		card_vbox.add_child(price_badge)
		
		# Overlay click button
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
		card.add_theme_stylebox_override("panel", _style_card_box(Color("#0b4d8c"), Color("#00f0ff"), 3))
	else:
		card.add_theme_stylebox_override("panel", _style_card_box(Color("#062d54"), Color("#145892"), 2))

func _select_item(skin_id: StringName) -> void:
	selected_skin_id = skin_id
	for id in item_cards:
		if is_instance_valid(item_cards[id]):
			_style_card(item_cards[id], id == selected_skin_id)
	_update_preview(skin_id)

func _update_preview(skin_id: StringName) -> void:
	var skin_dict: Dictionary = {}
	for s in all_skins:
		if s.id == skin_id:
			skin_dict = s
			break
	if skin_dict.is_empty():
		return
		
	preview_art.texture = skin_dict.get("hd_texture", skin_dict.texture)
	if _is_background(skin_dict) and preview_art.texture != null:
		preview_art.scale = Vector2.ONE
		preview_art.custom_minimum_size = Vector2(145, 103)
		preview_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		preview_art.material = _rounded_art_material(Vector2(145, 103), 11.0)
	else:
		preview_art.custom_minimum_size = Vector2(145, 145)
		preview_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		preview_art.material = null
		if str(skin_dict.get("kind", "balloon")) == "balloon":
			preview_art.pivot_offset = Vector2(72.5, 72.5)
			preview_art.scale = Vector2.ONE * WaterBalloonSkinRegistry.get_runtime_scale(skin_id)
		else:
			preview_art.scale = Vector2.ONE
	preview_name.text = skin_dict.name
	preview_rarity.text = "ĐỘ HIẾM: %s" % skin_dict.rarity.to_upper()
	
	preview_price_info.text = "Giá: %s COKE" % _format_number(skin_dict.price)
	
	var owned := _item_owned(skin_dict)
	var is_active := _item_active(skin_dict)
	var user_coke: int = GameSession.cokecy if has_node("/root/GameSession") else 0
	
	if is_active:
		preview_status.text = "TRẠNG THÁI: ĐANG DÙNG"
		preview_status.add_theme_color_override("font_color", Color("#34d399"))
		var can_unequip := str(skin_dict.get("category", "")) == str(CosmeticDefinition.HEAD_ACCESSORY)
		preview_action_btn.text = "THÁO" if can_unequip else "ĐANG DÙNG"
		preview_action_btn.disabled = not can_unequip
		preview_action_btn.add_theme_stylebox_override("normal", _style_3d_button(Color("#065f46"), Color("#023626"), Color("#34d399"), 10))
		preview_action_btn.add_theme_color_override("font_color", Color.WHITE)
	elif owned:
		preview_status.text = "TRẠNG THÁI: ĐÃ SỞ HỮU"
		preview_status.add_theme_color_override("font_color", Color("#22d2ff"))
		preview_action_btn.text = "TRANG BỊ"
		preview_action_btn.disabled = false
		preview_action_btn.add_theme_stylebox_override("normal", _style_3d_button(Color("#00aaff"), Color("#0066cc"), Color("#55ccff"), 10))
		preview_action_btn.add_theme_stylebox_override("hover", _style_3d_button(Color("#33bbff"), Color("#0077dd"), Color("#77ddff"), 10))
		preview_action_btn.add_theme_color_override("font_color", Color.WHITE)
	else:
		preview_status.text = "TRẠNG THÁI: CHƯA MỞ KHÓA"
		preview_status.add_theme_color_override("font_color", Color("#ffd040"))
		if user_coke >= skin_dict.price:
			preview_action_btn.text = "MUA NGAY"
			preview_action_btn.disabled = false
			preview_action_btn.add_theme_stylebox_override("normal", _style_3d_button(Color("#ffa600"), Color("#cc6600"), Color("#ffcc55"), 10))
			preview_action_btn.add_theme_stylebox_override("hover", _style_3d_button(Color("#ffbb33"), Color("#e67700"), Color("#ffdd77"), 10))
			preview_action_btn.add_theme_color_override("font_color", Color.WHITE)
		else:
			preview_action_btn.text = "KHÔNG ĐỦ TIỀN"
			preview_action_btn.disabled = true
			preview_action_btn.add_theme_stylebox_override("normal", _style_3d_button(Color("#3f3f46"), Color("#27272a"), Color("#71717a"), 10))
			preview_action_btn.add_theme_color_override("font_color", Color("#a1a1aa"))

func _on_action_button_pressed() -> void:
	if purchase_pending or selected_skin_id == &"" or not has_node("/root/GameSession"):
		return
	var item := _item_for_id(selected_skin_id)
	if item.is_empty():
		return
	var owned := _item_owned(item)
	if owned:
		if item.get("kind", "balloon") == "cosmetic":
			var category := StringName(str(item.category))
			if category == CosmeticDefinition.HEAD_ACCESSORY and _item_active(item):
				PlayerEquipmentService.unequip(category)
				equipment_selected.emit(category, &"")
			else:
				PlayerEquipmentService.equip(category, selected_skin_id)
				equipment_selected.emit(category, selected_skin_id)
		else:
			GameSession.selected_balloon_skin = selected_skin_id
			GameSession.save_profile()
			skin_selected.emit(selected_skin_id)
		refresh()
	else:
		if item.get("kind", "balloon") == "cosmetic":
			_request_cosmetic_purchase(selected_skin_id)
		else:
			_request_balloon_purchase(selected_skin_id)

func _request_balloon_purchase(skin_id: StringName) -> void:
	if not has_node("/root/AccountDatabase"):
		_show_purchase_feedback("Không thể kết nối cửa hàng.", true)
		return
	purchase_pending = true
	pending_balloon_id = skin_id
	preview_action_btn.text = "ĐANG MUA..."
	preview_action_btn.disabled = true
	preview_status.text = "Đang xác nhận giao dịch..."
	preview_status.add_theme_color_override("font_color", Color("#7dd3fc"))

	var online := has_node("/root/NetworkManager") and NetworkManager.is_connected_to_server()
	if online:
		AccountDatabase.rpc_id(1, "request_unlock_skin", skin_id)
		return

	# Local/editor sessions use the server-equivalent transaction directly and
	# route through the same callback so the UI has one authoritative code path.
	var result := AccountDatabase.purchase_balloon_skin_for_current_user(skin_id)
	AccountDatabase.receive_skin_unlocked(
		bool(result.get("success", false)),
		skin_id,
		int(result.get("balance", -1)),
		str(result.get("message", "Không thể mua bóng nước."))
	)

func _request_cosmetic_purchase(cosmetic_id: StringName) -> void:
	if not has_node("/root/AccountDatabase"):
		_show_purchase_feedback("Không thể kết nối cửa hàng.", true)
		return
	purchase_pending = true
	pending_cosmetic_id = cosmetic_id
	preview_action_btn.text = "ĐANG MUA..."
	preview_action_btn.disabled = true
	preview_status.text = "Đang xác nhận giao dịch..."
	preview_status.add_theme_color_override("font_color", Color("#7dd3fc"))

	if has_node("/root/NetworkManager") and NetworkManager.is_connected_to_server():
		AccountDatabase.rpc_id(1, "request_purchase_cosmetic", str(cosmetic_id))
		return

	# The editor and offline test scenes do not own a multiplayer peer. Keep the
	# shop functional there by using the same SQL transaction locally.
	var result := AccountDatabase.purchase_cosmetic_for_current_user(cosmetic_id)
	AccountDatabase.receive_cosmetic_purchase(
		bool(result.get("success", false)),
		cosmetic_id,
		int(result.get("balance", -1)),
		str(result.get("message", "Không thể mua vật phẩm."))
	)

func _item_for_id(item_id: StringName) -> Dictionary:
	for item in all_skins:
		if item.id == item_id:
			return item
	return {}

func _item_owned(item: Dictionary) -> bool:
	if not has_node("/root/GameSession"):
		return false
	if item.get("kind", "balloon") == "cosmetic":
		return GameSession.owns_cosmetic(StringName(str(item.id)))
	return GameSession.owns_balloon_skin(StringName(str(item.id)))

func _item_active(item: Dictionary) -> bool:
	if not has_node("/root/GameSession"):
		return false
	if item.get("kind", "balloon") == "cosmetic":
		return str(GameSession.equipped_cosmetics.get(str(item.category), "")) == str(item.id)
	return GameSession.selected_balloon_skin == StringName(str(item.id))

func _on_cosmetic_purchase_received(success: bool, cosmetic_id: StringName, _balance: int, message: String) -> void:
	purchase_pending = false
	pending_cosmetic_id = &""
	if success:
		cosmetic_purchased.emit(cosmetic_id)
		var definition := CosmeticRegistry.get_definition(cosmetic_id)
		if definition != null:
			PlayerEquipmentService.equip(definition.category_id(), cosmetic_id)
	refresh()
	_show_purchase_feedback(message, not success)

func _on_skin_purchase_received(success: bool, skin_id: StringName, _balance: int, message: String) -> void:
	if pending_balloon_id != &"" and skin_id != pending_balloon_id:
		return
	purchase_pending = false
	pending_balloon_id = &""
	if success and has_node("/root/GameSession"):
		if not GameSession.owned_balloon_skins.has(skin_id):
			GameSession.owned_balloon_skins.append(skin_id)
		GameSession.selected_balloon_skin = skin_id
		GameSession.save_profile()
		skin_purchased.emit(skin_id)
	refresh()
	_show_purchase_feedback(message, not success)

func _show_purchase_feedback(message: String, is_error: bool) -> void:
	if preview_status == null:
		return
	preview_status.text = message.to_upper()
	preview_status.add_theme_color_override("font_color", Color("#ff7b7b") if is_error else Color("#34d399"))

func _on_cokecy_changed(_new_value: int) -> void:
	refresh()

func refresh() -> void:
	if has_node("/root/GameSession"):
		if cokecy_label:
			cokecy_label.text = _format_number(GameSession.cokecy)
		if owned_count_label:
			owned_count_label.text = "%d / %d" % [GameSession.owned_balloon_skins.size() + GameSession.owned_cosmetics.size(), all_skins.size()]
	_populate_grid()
	if selected_skin_id != &"":
		_update_preview(selected_skin_id)

func _format_number(value: int) -> String:
	var s := str(value)
	var formatted := ""
	var count := 0
	for i in range(s.length() - 1, -1, -1):
		formatted = s[i] + formatted
		count += 1
		if count % 3 == 0 and i > 0:
			formatted = "," + formatted
	return formatted
