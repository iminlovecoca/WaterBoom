extends Control

const SHOP_VIEW_SCRIPT := preload("res://scripts/ui/ShopView.gd")
const INVENTORY_VIEW_SCRIPT := preload("res://scripts/ui/InventoryView.gd")
const LIFT_BUTTON_SCRIPT := preload("res://scripts/ui/LiftButton.gd")

var background: TextureRect
var title_label: Label
var room_list_container: VBoxContainer
var btn_create_room: Button
var btn_back: Button
var error_label: Label

var shop_panel: Control
var inventory_panel: Control
var settings_panel: Panel
var master_slider: HSlider
var bgm_slider: HSlider
var sfx_slider: HSlider
var resolution_option: OptionButton
var graphics_quality_option: OptionButton
var fullscreen_check: CheckButton
var vsync_check: CheckButton

func _ready() -> void:
	SoundManager.play_bgm("res://assets/audio/music/lobby.mp3", true)
	_build_ui()
	
	if has_node("/root/RoomManager"):
		RoomManager.room_list_updated.connect(_on_room_list_updated)
		RoomManager.room_joined.connect(_on_room_joined)
		RoomManager.room_error.connect(_on_room_error)
		
		if NetworkManager.is_client_active:
			RoomManager.rpc_id(1, "request_room_list")

func _build_ui() -> void:
	# Background
	background = TextureRect.new()
	background.texture = load("res://ui/assets_generated/backgrounds/checkered_bg.png")
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_TILE
	background.modulate = Color("#6cbcff")
	background.set_anchors_preset(PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	
	# Main Panel
	_add_section_panel("MainPanel", Rect2(50, 70, 860, 558), Color("#0b75cd"))
	
	# Title
	title_label = _add_label("TitleLabel", Rect2(50, 25, 860, 40), "ĐẠI SẢNH BOOM ONLINE", 26, HORIZONTAL_ALIGNMENT_CENTER, Color("#fff09a"))
	title_label.add_theme_color_override("font_outline_color", Color("#0b75cd"))
	title_label.add_theme_constant_override("outline_size", 6)
	
	# Room List
	var scroll = ScrollContainer.new()
	scroll.position = Vector2(70, 90)
	scroll.size = Vector2(820, 430)
	add_child(scroll)
	
	room_list_container = VBoxContainer.new()
	room_list_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	room_list_container.add_theme_constant_override("separation", 15)
	scroll.add_child(room_list_container)
	
	# Error Label
	error_label = _add_label("ErrorLabel", Rect2(70, 530, 500, 30), "", 16, HORIZONTAL_ALIGNMENT_LEFT, Color("#ff5555"))
	
	# -------------------------------------------------------------
	# Bottom Navigation Buttons
	# -------------------------------------------------------------
	# Left: Back (Square) + Shop (Text) + Inventory (Text)
	btn_back = _add_button("BackBtn", Rect2(65, 646, 48, 48), "", 14)
	_apply_button_skin(btn_back, "icon_secondary")
	_set_button_icon_centered(btn_back, "res://assets/ui/icons/arrow_back.png", 32)
	btn_back.tooltip_text = "Đăng xuất / Quay lại"
	btn_back.pressed.connect(func(): 
		NetworkManager.disconnect_network()
		get_tree().change_scene_to_file("res://scenes/login/Login.tscn")
	)
	
	var btn_shop := _add_button("ShopBtn", Rect2(121, 646, 140, 48), "CỬA HÀNG", 15)
	btn_shop.tooltip_text = "Cửa hàng"
	_apply_button_skin(btn_shop, "secondary")
	btn_shop.add_theme_constant_override("outline_size", 6)
	btn_shop.pressed.connect(func(): _open_feature_panel(shop_panel))
	
	var btn_inventory := _add_button("InventoryBtn", Rect2(269, 646, 140, 48), "TÚI ĐỒ", 15)
	btn_inventory.tooltip_text = "Kho đồ / Túi đồ"
	_apply_button_skin(btn_inventory, "secondary")
	btn_inventory.add_theme_constant_override("outline_size", 6)
	btn_inventory.pressed.connect(func(): _open_feature_panel(inventory_panel))
	
	# Right: Settings (Square) + Create Room
	var btn_settings := _add_button("SettingsBtn", Rect2(660, 646, 48, 48), "", 14)
	btn_settings.tooltip_text = "Cài đặt"
	_apply_button_skin(btn_settings, "icon_secondary")
	_set_button_icon_centered(btn_settings, "res://assets/ui/icons/gear.png", 36)
	btn_settings.pressed.connect(func(): 
		settings_panel.visible = true
		settings_panel.move_to_front()
	)
	
	btn_create_room = _add_button("CreateRoomBtn", Rect2(716, 646, 180, 48), "TẠO PHÒNG", 18)
	_apply_button_skin(btn_create_room, "gold")
	btn_create_room.pressed.connect(func(): 
		error_label.text = ""
		btn_create_room.disabled = true
		btn_create_room.text = "ĐANG TẠO..."
		await get_tree().process_frame
		if not NetworkManager.is_connected_to_server():
			if NetworkManager.start_host(7777):
				if has_node("/root/RoomManager"):
					RoomManager.request_create_room("Pirate Harbor", GameSession.player_nickname, str(GameSession.selected_character_id), str(GameSession.selected_balloon_skin), GameSession.equipped_cosmetics)
			else:
				error_label.text = "Lỗi: Không thể khởi tạo Máy Chủ Cục Bộ."
				btn_create_room.disabled = false
				btn_create_room.text = "TẠO PHÒNG"
		else:
			if has_node("/root/RoomManager"):
				RoomManager.rpc_id(1, "request_create_room", "Pirate Harbor", GameSession.player_nickname, str(GameSession.selected_character_id), str(GameSession.selected_balloon_skin), GameSession.equipped_cosmetics)
	)
	
	# Build Feature Panels
	_build_settings_panel()
	shop_panel = SHOP_VIEW_SCRIPT.new()
	shop_panel.name = "ShopPanel"
	shop_panel.visible = false
	shop_panel.closed.connect(func(): shop_panel.visible = false)
	add_child(shop_panel)
	
	inventory_panel = INVENTORY_VIEW_SCRIPT.new()
	inventory_panel.name = "InventoryPanel"
	inventory_panel.visible = false
	inventory_panel.closed.connect(func(): inventory_panel.visible = false)
	add_child(inventory_panel)

func _open_feature_panel(panel: Control) -> void:
	if settings_panel: settings_panel.visible = false
	if shop_panel: shop_panel.visible = panel == shop_panel
	if inventory_panel: inventory_panel.visible = panel == inventory_panel
	if panel == inventory_panel and inventory_panel.has_method("refresh"):
		inventory_panel.refresh()
	if panel == shop_panel and shop_panel.has_method("refresh"):
		shop_panel.refresh()
	if panel:
		panel.move_to_front()

func _build_settings_panel() -> void:
	settings_panel = Panel.new()
	settings_panel.name = "SettingsPanel"
	settings_panel.position = Vector2(230, 95)
	settings_panel.size = Vector2(500, 530)
	settings_panel.visible = false
	settings_panel.add_theme_stylebox_override("panel", UITheme.panel_main())
	add_child(settings_panel)
	
	var title := Label.new()
	title.position = Vector2(30, 18)
	title.size = Vector2(440, 42)
	title.text = "CÀI ĐẶT HỆ THỐNG"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color.WHITE)
	title.add_theme_color_override("font_outline_color", Color("#042347"))
	title.add_theme_constant_override("outline_size", 5)
	settings_panel.add_child(title)
	
	var box := VBoxContainer.new()
	box.position = Vector2(40, 68)
	box.size = Vector2(420, 380)
	box.add_theme_constant_override("separation", 10)
	settings_panel.add_child(box)
	
	master_slider = _add_slider_row(box, "ÂM LƯỢNG TỔNG", SettingsStore.master_volume)
	bgm_slider = _add_slider_row(box, "NHẠC NỀN (BGM)", SettingsStore.bgm_volume)
	sfx_slider = _add_slider_row(box, "HIỆU ỨNG (SFX)", SettingsStore.sfx_volume)
	
	var qual_label := Label.new()
	qual_label.text = "CHẤT LƯỢNG ĐỒ HỌA (HD / UHD)"
	qual_label.add_theme_font_size_override("font_size", 13)
	qual_label.add_theme_color_override("font_color", Color("#c4f3ff"))
	box.add_child(qual_label)
	
	graphics_quality_option = OptionButton.new()
	graphics_quality_option.custom_minimum_size = Vector2(0, 36)
	for qual in SettingsStore.QUALITY_PRESETS:
		graphics_quality_option.add_item(qual)
	graphics_quality_option.select(SettingsStore.graphics_quality)
	box.add_child(graphics_quality_option)

	var res_label := Label.new()
	res_label.text = "ĐỘ PHÂN GIẢI MÀN HÌNH"
	res_label.add_theme_font_size_override("font_size", 13)
	res_label.add_theme_color_override("font_color", Color("#c4f3ff"))
	box.add_child(res_label)
	
	resolution_option = OptionButton.new()
	resolution_option.custom_minimum_size = Vector2(0, 36)
	for res_name in SettingsStore.RESOLUTION_NAMES:
		resolution_option.add_item(res_name)
	resolution_option.select(SettingsStore.resolution_index)
	box.add_child(resolution_option)
	
	var toggle_row := HBoxContainer.new()
	toggle_row.add_theme_constant_override("separation", 24)
	box.add_child(toggle_row)
	
	fullscreen_check = CheckButton.new()
	fullscreen_check.text = "Toàn màn hình"
	fullscreen_check.button_pressed = SettingsStore.fullscreen
	toggle_row.add_child(fullscreen_check)
	
	vsync_check = CheckButton.new()
	vsync_check.text = "Đồng bộ VSync"
	vsync_check.button_pressed = SettingsStore.vsync
	toggle_row.add_child(vsync_check)
	
	var close := Button.new()
	close.name = "SaveSettingsButton"
	close.position = Vector2(150, 460)
	close.size = Vector2(200, 48)
	close.text = "XÁC NHẬN"
	close.add_theme_font_size_override("font_size", 16)
	_apply_button_skin(close, "gold")
	settings_panel.add_child(close)
	close.pressed.connect(_save_and_close_settings)

func _add_slider_row(parent: VBoxContainer, label_text: String, current_value: float) -> HSlider:
	var label := Label.new()
	label.text = label_text
	label.add_theme_font_size_override("font_size", 13)
	label.add_theme_color_override("font_color", Color("#c4f3ff"))
	parent.add_child(label)
	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.05
	slider.value = current_value
	parent.add_child(slider)
	return slider

func _save_and_close_settings() -> void:
	if master_slider and bgm_slider and sfx_slider:
		SettingsStore.update_audio(master_slider.value, bgm_slider.value, sfx_slider.value)
	if fullscreen_check and vsync_check and resolution_option:
		var quality_idx := graphics_quality_option.selected if graphics_quality_option != null else 2
		SettingsStore.update_display(fullscreen_check.button_pressed, vsync_check.button_pressed, resolution_option.selected, quality_idx)
	if settings_panel:
		settings_panel.visible = false

func _on_room_list_updated(rooms: Dictionary) -> void:
	for child in room_list_container.get_children():
		child.queue_free()
		
	if rooms.is_empty():
		var empty_lbl = Label.new()
		empty_lbl.text = "Hiện tại không có phòng nào. Hãy tạo phòng mới!"
		empty_lbl.add_theme_font_size_override("font_size", 18)
		empty_lbl.add_theme_color_override("font_color", Color("#aaddff"))
		empty_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_lbl.custom_minimum_size = Vector2(820, 100)
		empty_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		room_list_container.add_child(empty_lbl)
		return
		
	for room_id in rooms:
		var room = rooms[room_id]
		var panel = Panel.new()
		panel.custom_minimum_size = Vector2(810, 80)
		panel.add_theme_stylebox_override("panel", UITheme.panel_inset())
		
		var icon = TextureRect.new()
		icon.texture = preload("res://assets/ui/map_previews/map_pirate_harbor.png")
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		icon.position = Vector2(10, 10)
		icon.size = Vector2(106, 60)
		panel.add_child(icon)
		
		var name_lbl = _add_label_to("RoomName", Rect2(130, 15, 300, 30), room.name, 20, HORIZONTAL_ALIGNMENT_LEFT, Color("#ffffff"), panel)
		var map_lbl = _add_label_to("MapName", Rect2(130, 45, 300, 20), "Bản đồ: " + room.map, 14, HORIZONTAL_ALIGNMENT_LEFT, Color("#aaddff"), panel)
		
		var is_full = room.players.size() >= room.max_players
		var is_playing = room.state != "WAITING"
		
		var status_text = "ĐANG ĐỢI"
		var status_color = Color("#75ff5d")
		if is_playing:
			status_text = "ĐANG CHƠI"
			status_color = Color("#ff5555")
		elif is_full:
			status_text = "ĐẦY PHÒNG"
			status_color = Color("#f4a719")
			
		var players_lbl = _add_label_to("Players", Rect2(500, 25, 150, 30), "%d/%d - %s" % [room.players.size(), room.max_players, status_text], 16, HORIZONTAL_ALIGNMENT_RIGHT, status_color, panel)
		
		var join_btn = Button.new()
		join_btn.text = "THAM GIA"
		join_btn.position = Vector2(670, 20)
		join_btn.size = Vector2(120, 40)
		join_btn.add_theme_font_size_override("font_size", 14)
		join_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		_apply_button_skin(join_btn, "classic")
		join_btn.disabled = is_full or is_playing
		var captured_id = room_id
		join_btn.pressed.connect(func(): 
			error_label.text = ""
			if has_node("/root/RoomManager"):
				RoomManager.rpc_id(1, "request_join_room", captured_id, GameSession.player_nickname, str(GameSession.selected_character_id), str(GameSession.selected_balloon_skin), GameSession.equipped_cosmetics)
		)
		panel.add_child(join_btn)
		
		room_list_container.add_child(panel)

func _on_room_joined(room_data: Dictionary) -> void:
	var boot_scene = load("res://scenes/boot/Boot.tscn")
	get_tree().change_scene_to_packed(boot_scene)

func _on_room_error(msg: String) -> void:
	if error_label:
		error_label.text = "Lỗi: " + msg

# UI HELPER FUNCTIONS

func _add_section_panel(node_name: String, rect: Rect2, background_col: Color, shadow := true) -> Panel:
	var panel := Panel.new()
	panel.name = node_name
	panel.position = rect.position
	panel.size = rect.size
	panel.add_theme_stylebox_override("panel", UITheme.panel_main())
	add_child(panel)
	return panel

func _panel_style(background_col: Color, border: Color, width: int, radius: int, shadow: bool) -> StyleBoxFlat:
	return UITheme.panel_inset()

func _add_label(node_name: String, rect: Rect2, text: String, font_size: int, alignment := HORIZONTAL_ALIGNMENT_LEFT, color := Color("#d9f5ff")) -> Label:
	return _add_label_to(node_name, rect, text, font_size, alignment, color, self)

func _add_label_to(node_name: String, rect: Rect2, text: String, font_size: int, alignment: int, color: Color, parent: Node) -> Label:
	var label := Label.new()
	label.name = node_name
	label.position = rect.position
	label.size = rect.size
	label.text = text
	label.horizontal_alignment = alignment
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	parent.add_child(label)
	return label

func _add_button(node_name: String, rect: Rect2, text: String, font_size: int) -> Button:
	var button := Button.new()
	button.name = node_name
	button.position = rect.position
	button.size = rect.size
	button.text = text
	button.add_theme_font_size_override("font_size", font_size)
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_apply_button_skin(button, "secondary")
	add_child(button)
	return button

func _set_button_icon(button: Button, icon_path: String) -> void:
	if ResourceLoader.exists(icon_path):
		button.icon = load(icon_path)
		button.expand_icon = true
		button.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.vertical_icon_alignment = VERTICAL_ALIGNMENT_CENTER
		button.add_theme_constant_override("icon_max_width", 32)

func _set_button_icon_centered(button: Button, icon_path: String, max_w: int = 34) -> void:
	if ResourceLoader.exists(icon_path):
		button.icon = load(icon_path)
		button.expand_icon = true
		button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		button.vertical_icon_alignment = VERTICAL_ALIGNMENT_CENTER
		button.add_theme_constant_override("icon_max_width", max_w)

func _apply_button_skin(button: Button, kind: String, selected := false) -> void:
	if kind == "gold":
		UITheme.apply_button_theme(button, "primary")
	elif kind == "danger":
		UITheme.apply_button_theme(button, "danger")
	elif kind == "icon_secondary":
		UITheme.apply_icon_button_theme(button, "secondary")
	elif kind == "icon_danger":
		UITheme.apply_icon_button_theme(button, "danger")
	elif kind == "slot":
		if selected:
			button.add_theme_stylebox_override("normal", UITheme.slot_master())
			button.add_theme_stylebox_override("hover", UITheme.slot_master())
		else:
			button.add_theme_stylebox_override("normal", UITheme.slot_empty())
			button.add_theme_stylebox_override("hover", UITheme.slot_active())
	else:
		UITheme.apply_button_theme(button, "secondary")
