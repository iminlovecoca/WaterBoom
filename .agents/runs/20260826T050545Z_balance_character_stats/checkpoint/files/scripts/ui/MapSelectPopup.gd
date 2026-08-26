class_name MapSelectPopup
extends Control

signal map_selected(map_id: StringName)
signal closed()

var modal_panel: Panel
var preview_thumb: TextureRect
var preview_title_lbl: Label
var preview_players_lbl: Label
var preview_mode_lbl: Label
var preview_diff_lbl: Label
var preview_rank_lbl: Label
var preview_desc_lbl: Label

var map_list_container: VBoxContainer
var current_selected_id: StringName = &"training_plaza"
var temporary_selected_id: StringName = &"training_plaza"

var active_mode_filter: String = "all"
var mode_filter_buttons: Dictionary = {}
var map_row_buttons: Dictionary = {}

func _init() -> void:
	set_anchors_preset(PRESET_FULL_RECT)
	z_index = 120
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build_ui()

func _build_ui() -> void:
	# 1. Dimming Backdrop
	var backdrop := ColorRect.new()
	backdrop.set_anchors_preset(PRESET_FULL_RECT)
	backdrop.color = Color(0.01, 0.05, 0.12, 0.82)
	add_child(backdrop)
	
	# 2. Main Modal Popup Window (760 x 530, centered at 100, 95)
	modal_panel = Panel.new()
	modal_panel.position = Vector2(100, 95)
	modal_panel.size = Vector2(760, 530)
	
	var modal_s := StyleBoxFlat.new()
	modal_s.bg_color = Color("#082c58")
	modal_s.border_color = Color("#19609e")
	modal_s.set_border_width_all(3)
	modal_s.border_width_bottom = 6
	modal_s.set_corner_radius_all(14)
	modal_s.shadow_color = Color(0, 0, 0, 0.45)
	modal_s.shadow_size = 12
	modal_s.shadow_offset = Vector2(0, 6)
	modal_panel.add_theme_stylebox_override("panel", modal_s)
	add_child(modal_panel)
	
	# Top Header Title
	var title_lbl := Label.new()
	title_lbl.position = Vector2(24, 14)
	title_lbl.size = Vector2(300, 36)
	title_lbl.text = "CHỌN BẢN ĐỒ"
	title_lbl.add_theme_font_size_override("font_size", 24)
	title_lbl.add_theme_color_override("font_color", Color.WHITE)
	title_lbl.add_theme_color_override("font_outline_color", Color("#062446"))
	title_lbl.add_theme_constant_override("outline_size", 4)
	modal_panel.add_child(title_lbl)
	
	# -------------------------------------------------------------
	# LEFT COLUMN: PREVIEW & METADATA (Width: 260px)
	# -------------------------------------------------------------
	var left_box := Control.new()
	left_box.position = Vector2(24, 58)
	left_box.size = Vector2(260, 402)
	modal_panel.add_child(left_box)
	
	# Map Name Tag Header
	var name_tag_panel := Panel.new()
	name_tag_panel.position = Vector2(0, 0)
	name_tag_panel.size = Vector2(260, 28)
	var tag_s := StyleBoxFlat.new()
	tag_s.bg_color = Color("#042044")
	tag_s.border_color = Color("#144c80")
	tag_s.set_border_width_all(1)
	tag_s.border_width_bottom = 2
	tag_s.set_corner_radius_all(4)
	name_tag_panel.add_theme_stylebox_override("panel", tag_s)
	left_box.add_child(name_tag_panel)
	
	preview_title_lbl = Label.new()
	preview_title_lbl.set_anchors_preset(PRESET_FULL_RECT)
	preview_title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	preview_title_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	preview_title_lbl.add_theme_font_size_override("font_size", 12)
	preview_title_lbl.add_theme_color_override("font_color", Color("#c2e4ff"))
	preview_title_lbl.add_theme_color_override("font_outline_color", Color("#040d16"))
	preview_title_lbl.add_theme_constant_override("outline_size", 3)
	name_tag_panel.add_child(preview_title_lbl)
	
	# Map Thumbnail Frame (Dark Inset)
	var thumb_panel := Panel.new()
	thumb_panel.position = Vector2(0, 34)
	thumb_panel.size = Vector2(260, 160)
	var thumb_s := StyleBoxFlat.new()
	thumb_s.bg_color = Color("#031836")
	thumb_s.border_color = Color("#12467b")
	thumb_s.set_border_width_all(2)
	thumb_s.border_width_bottom = 4
	thumb_s.set_corner_radius_all(6)
	thumb_panel.add_theme_stylebox_override("panel", thumb_s)
	left_box.add_child(thumb_panel)
	
	preview_thumb = TextureRect.new()
	preview_thumb.position = Vector2(4, 4)
	preview_thumb.size = Vector2(252, 152)
	preview_thumb.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview_thumb.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	preview_thumb.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	thumb_panel.add_child(preview_thumb)
	
	# Attribute Rows
	var attrs_box := VBoxContainer.new()
	attrs_box.position = Vector2(0, 200)
	attrs_box.size = Vector2(260, 94)
	attrs_box.add_theme_constant_override("separation", 2)
	left_box.add_child(attrs_box)
	
	preview_players_lbl = _add_attr_row(attrs_box, "Người:", "4")
	preview_mode_lbl = _add_attr_row(attrs_box, "Chế độ:", "Cổ điển")
	preview_diff_lbl = _add_attr_row(attrs_box, "Độ khó map:", "Dễ ★☆☆☆☆")
	preview_rank_lbl = _add_attr_row(attrs_box, "Xếp hạng:", "Level 1 (Hạng SS)")
	
	# Description Lore Box
	var desc_panel := Panel.new()
	desc_panel.position = Vector2(0, 300)
	desc_panel.size = Vector2(260, 102)
	var desc_s := StyleBoxFlat.new()
	desc_s.bg_color = Color("#031836")
	desc_s.border_color = Color("#12467b")
	desc_s.set_border_width_all(1)
	desc_s.border_width_bottom = 2
	desc_s.set_corner_radius_all(4)
	desc_s.content_margin_left = 6
	desc_s.content_margin_right = 6
	desc_s.content_margin_top = 6
	desc_s.content_margin_bottom = 6
	desc_panel.add_theme_stylebox_override("panel", desc_s)
	left_box.add_child(desc_panel)
	
	preview_desc_lbl = Label.new()
	preview_desc_lbl.set_anchors_preset(PRESET_FULL_RECT)
	preview_desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	preview_desc_lbl.add_theme_font_size_override("font_size", 10)
	preview_desc_lbl.add_theme_color_override("font_color", Color("#bde5ff"))
	desc_panel.add_child(preview_desc_lbl)
	
	# -------------------------------------------------------------
	# RIGHT COLUMN: FILTER TABS & MAP LIST (Width: 446px)
	# -------------------------------------------------------------
	var right_box := Control.new()
	right_box.position = Vector2(294, 58)
	right_box.size = Vector2(446, 402)
	modal_panel.add_child(right_box)
	
	# Mode Filter Tabs
	var mode_tabs_row := HBoxContainer.new()
	mode_tabs_row.position = Vector2(0, 0)
	mode_tabs_row.size = Vector2(446, 30)
	mode_tabs_row.add_theme_constant_override("separation", 6)
	right_box.add_child(mode_tabs_row)
	
	var modes: Array[Array] = [
		["all", "TẤT CẢ BẢN ĐỒ", false],
		["classic", "CỔ ĐIỂN", false],
		["team", "ĐẤU ĐỘI (Khóa)", true],
		["survival", "SINH TỒN (Khóa)", true]
	]
	for m in modes:
		var btn := Button.new()
		btn.text = m[1]
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.add_theme_font_size_override("font_size", 10)
		btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		var captured_mode: String = m[0]
		var is_locked: bool = m[2]
		
		if is_locked:
			btn.disabled = true
			btn.tooltip_text = "Chế độ đang được hoàn thiện, sẽ sớm ra mắt!"
			btn.add_theme_color_override("font_disabled_color", Color("#688fa8"))
			var locked_s := StyleBoxFlat.new()
			locked_s.bg_color = Color("#031d36")
			locked_s.border_color = Color("#0a375e")
			locked_s.set_border_width_all(1)
			locked_s.set_corner_radius_all(4)
			btn.add_theme_stylebox_override("disabled", locked_s)
		else:
			btn.pressed.connect(func(): _set_mode_filter(captured_mode))
		
		mode_tabs_row.add_child(btn)
		mode_filter_buttons[captured_mode] = btn
		
	# Table Header Row
	var table_header := Panel.new()
	table_header.position = Vector2(0, 36)
	table_header.size = Vector2(446, 26)
	var th_s := StyleBoxFlat.new()
	th_s.bg_color = Color("#052952")
	th_s.border_color = Color("#1772bf")
	th_s.set_border_width_all(1)
	th_s.set_corner_radius_all(3)
	table_header.add_theme_stylebox_override("panel", th_s)
	right_box.add_child(table_header)
	
	_add_header_label(table_header, Rect2(10, 0, 160, 26), "BẢN ĐỒ", HORIZONTAL_ALIGNMENT_LEFT)
	_add_header_label(table_header, Rect2(180, 0, 80, 26), "CHẾ ĐỘ", HORIZONTAL_ALIGNMENT_CENTER)
	_add_header_label(table_header, Rect2(270, 0, 70, 26), "ĐỘ KHÓ", HORIZONTAL_ALIGNMENT_CENTER)
	_add_header_label(table_header, Rect2(350, 0, 45, 26), "HẠNG", HORIZONTAL_ALIGNMENT_CENTER)
	_add_header_label(table_header, Rect2(405, 0, 35, 26), "NHẠC", HORIZONTAL_ALIGNMENT_CENTER)
	
	# Scrollable Map List Container
	var scroll := ScrollContainer.new()
	scroll.position = Vector2(0, 66)
	scroll.size = Vector2(446, 336)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	right_box.add_child(scroll)
	
	map_list_container = VBoxContainer.new()
	map_list_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	map_list_container.add_theme_constant_override("separation", 4)
	scroll.add_child(map_list_container)
	
	# -------------------------------------------------------------
	# BOTTOM ACTION BUTTONS
	# -------------------------------------------------------------
	var btn_confirm := Button.new()
	btn_confirm.position = Vector2(230, 470)
	btn_confirm.size = Vector2(140, 44)
	btn_confirm.text = "XÁC NHẬN"
	btn_confirm.add_theme_font_size_override("font_size", 16)
	UITheme.apply_button_theme(btn_confirm, "primary")
	btn_confirm.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn_confirm.pressed.connect(confirm_selection)
	modal_panel.add_child(btn_confirm)
	
	var btn_cancel := Button.new()
	btn_cancel.position = Vector2(390, 470)
	btn_cancel.size = Vector2(140, 44)
	btn_cancel.text = "HỦY"
	btn_cancel.add_theme_font_size_override("font_size", 16)
	UITheme.apply_button_theme(btn_cancel, "secondary")
	btn_cancel.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn_cancel.pressed.connect(cancel_selection)
	modal_panel.add_child(btn_cancel)
	
	_update_filter_button_styles()

func open(initial_map_id: StringName) -> void:
	current_selected_id = initial_map_id
	temporary_selected_id = initial_map_id
	visible = true
	move_to_front()
	_rebuild_map_list()
	_preview_map(temporary_selected_id)

func _set_mode_filter(mode_key: String) -> void:
	active_mode_filter = mode_key
	_update_filter_button_styles()
	_rebuild_map_list()

func _update_filter_button_styles() -> void:
	for mode_key in mode_filter_buttons:
		var btn: Button = mode_filter_buttons[mode_key]
		if btn.disabled: continue
		if mode_key == active_mode_filter:
			UITheme.apply_button_theme(btn, "primary")
		else:
			UITheme.apply_button_theme(btn, "secondary")

func _rebuild_map_list() -> void:
	for child in map_list_container.get_children():
		child.queue_free()
	map_row_buttons.clear()
	
	for map_id in MapCatalog.MAP_IDS:
		var meta: Dictionary = MapCatalog.get_map_metadata(map_id)
		var cat: String = meta.get("category", "classic")
		if active_mode_filter != "all" and cat != active_mode_filter:
			continue
			
		var row := _create_map_row(map_id, meta)
		map_list_container.add_child(row)
		map_row_buttons[map_id] = row
		
	_refresh_row_highlights()

func _create_map_row(map_id: StringName, meta: Dictionary) -> Button:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(436, 34)
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.flat = true
	
	var is_selected := (map_id == temporary_selected_id)
	_apply_row_style(btn, is_selected)
	
	var row_layout := HBoxContainer.new()
	row_layout.set_anchors_preset(PRESET_FULL_RECT)
	row_layout.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row_layout.add_theme_constant_override("separation", 8)
	btn.add_child(row_layout)
	
	# Icon / Bullet
	var icon_lbl := Label.new()
	icon_lbl.text = " 🗺"
	icon_lbl.custom_minimum_size = Vector2(24, 0)
	icon_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row_layout.add_child(icon_lbl)
	
	# Map Name
	var name_lbl := Label.new()
	name_lbl.text = meta.get("name", String(map_id))
	name_lbl.custom_minimum_size = Vector2(140, 0)
	name_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_lbl.add_theme_font_size_override("font_size", 11)
	name_lbl.add_theme_color_override("font_color", Color.WHITE)
	row_layout.add_child(name_lbl)
	
	# Mode
	var mode_lbl := Label.new()
	mode_lbl.text = meta.get("mode", "Cổ điển")
	mode_lbl.custom_minimum_size = Vector2(80, 0)
	mode_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mode_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	mode_lbl.add_theme_font_size_override("font_size", 10)
	mode_lbl.add_theme_color_override("font_color", Color("#8dd5ff"))
	row_layout.add_child(mode_lbl)
	
	# Difficulty
	var diff_lbl := Label.new()
	diff_lbl.text = meta.get("diff", "Dễ")
	diff_lbl.custom_minimum_size = Vector2(70, 0)
	diff_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	diff_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	diff_lbl.add_theme_font_size_override("font_size", 10)
	diff_lbl.add_theme_color_override("font_color", Color("#ffd45d"))
	row_layout.add_child(diff_lbl)
	
	# Rank
	var rank_lbl := Label.new()
	rank_lbl.text = meta.get("rank", "S")
	rank_lbl.custom_minimum_size = Vector2(40, 0)
	rank_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rank_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	rank_lbl.add_theme_font_size_override("font_size", 11)
	rank_lbl.add_theme_color_override("font_color", Color("#aaff66"))
	row_layout.add_child(rank_lbl)
	
	# Music Note Icon
	var music_lbl := Label.new()
	music_lbl.text = "♫"
	music_lbl.custom_minimum_size = Vector2(30, 0)
	music_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	music_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	music_lbl.add_theme_font_size_override("font_size", 12)
	music_lbl.add_theme_color_override("font_color", Color("#ff9933"))
	row_layout.add_child(music_lbl)
	
	var captured_id: StringName = map_id
	btn.pressed.connect(func(): 
		temporary_selected_id = captured_id
		_refresh_row_highlights()
		_preview_map(temporary_selected_id)
	)
	
	return btn

func _apply_row_style(btn: Button, selected: bool) -> void:
	var s := StyleBoxFlat.new()
	if selected:
		s.bg_color = Color("#142538")
		s.border_color = Color("#ffd84a")
		s.set_border_width_all(2)
		s.border_width_bottom = 3
		s.set_corner_radius_all(4)
		s.shadow_color = Color(1, 0.85, 0.3, 0.3)
		s.shadow_size = 3
	else:
		s.bg_color = Color("#07111c")
		s.border_color = Color("#182636")
		s.set_border_width_all(1)
		s.border_width_bottom = 2
		s.set_corner_radius_all(4)
	s.content_margin_left = 4
	s.content_margin_right = 4
	btn.add_theme_stylebox_override("normal", s)
	
	var hover_s := s.duplicate()
	hover_s.bg_color = Color("#182f48") if selected else Color("#0d1b28")
	btn.add_theme_stylebox_override("hover", hover_s)

func _refresh_row_highlights() -> void:
	for map_id in map_row_buttons:
		var btn: Button = map_row_buttons[map_id]
		_apply_row_style(btn, map_id == temporary_selected_id)

func _preview_map(map_id: StringName) -> void:
	var meta: Dictionary = MapCatalog.get_map_metadata(map_id)
	preview_title_lbl.text = "🗺  %s" % meta.get("name", String(map_id)).to_upper()
	
	var preview_path := "res://assets/ui/map_previews/map_%s.png" % map_id
	if ResourceLoader.exists(preview_path):
		preview_thumb.texture = load(preview_path)
	else:
		preview_thumb.texture = null
		
	preview_players_lbl.text = "Người:   %s" % meta.get("players", "2 - 4")
	preview_mode_lbl.text = "Chế độ: %s" % meta.get("mode", "Cổ điển")
	preview_diff_lbl.text = "Độ khó map: %s (%s)" % [meta.get("diff", "Dễ"), meta.get("stars", "★☆☆☆☆")]
	preview_rank_lbl.text = "Hạng:   Level %s (Hạng %s)" % [meta.get("level", "1"), meta.get("rank", "S")]
	preview_desc_lbl.text = meta.get("desc", "Bản đồ thi đấu sôi động và hấp dẫn.")

func confirm_selection() -> void:
	current_selected_id = temporary_selected_id
	map_selected.emit(current_selected_id)
	visible = false
	closed.emit()

func cancel_selection() -> void:
	temporary_selected_id = current_selected_id
	visible = false
	closed.emit()

# HELPER UI BUILDERS

func _add_attr_row(parent: VBoxContainer, key: String, val: String) -> Label:
	var row_panel := Panel.new()
	row_panel.custom_minimum_size = Vector2(260, 20)
	var s := StyleBoxFlat.new()
	s.bg_color = Color("#042242")
	s.border_color = Color("#0e497d")
	s.set_border_width_all(1)
	s.set_corner_radius_all(3)
	s.content_margin_left = 6
	s.content_margin_right = 6
	row_panel.add_theme_stylebox_override("panel", s)
	parent.add_child(row_panel)
	
	var lbl := Label.new()
	lbl.set_anchors_preset(PRESET_FULL_RECT)
	lbl.text = "%s  %s" % [key, val]
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 10)
	lbl.add_theme_color_override("font_color", Color("#a9e1ff"))
	row_panel.add_child(lbl)
	return lbl

func _add_header_label(parent: Panel, rect: Rect2, text: String, align: int) -> void:
	var lbl := Label.new()
	lbl.position = rect.position
	lbl.size = rect.size
	lbl.text = text
	lbl.horizontal_alignment = align
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 10)
	lbl.add_theme_color_override("font_color", Color("#88d5ff"))
	lbl.add_theme_color_override("font_outline_color", Color("#031d3d"))
	lbl.add_theme_constant_override("outline_size", 2)
	parent.add_child(lbl)
