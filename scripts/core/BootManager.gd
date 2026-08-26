class_name BootManager
extends Control
static var _digital_font: FontFile = null
static func _get_digital_font() -> FontFile:
	if _digital_font == null:
		_digital_font = FontFile.new()
		_digital_font.load_dynamic_font("res://assets/fonts/DSEG7Classic-Bold.ttf")
	return _digital_font


const PAGE_SIZE := 15
const LIFT_BUTTON_SCRIPT := preload("res://scripts/ui/LiftButton.gd")
const SHOP_VIEW_SCRIPT := preload("res://scripts/ui/ShopView.gd")
const INVENTORY_VIEW_SCRIPT := preload("res://scripts/ui/InventoryView.gd")
const MAP_SELECT_POPUP_SCRIPT := preload("res://scripts/ui/MapSelectPopup.gd")

var characters: Array[CharacterDefinition] = []
var character_buttons: Array[Button] = []
var character_card_backgrounds: Array[TextureRect] = []
var character_card_selfies: Array[TextureRect] = []
var character_check_badges: Array[TextureRect] = []
var character_empty_labels: Array[Label] = []
var map_cards: Array[PanelContainer] = []
var room_portraits: Array[AnimatedSprite2D] = []
var room_labels: Array[Label] = []
var room_badge_labels: Array[Label] = []
var room_badge_icons: Array[TextureRect] = []
var room_empty_labels: Array[Label] = []
var room_name_panels: Array[Panel] = []
var room_role_labels: Array[Label] = []
var room_slot_panels: Array[Panel] = []
var room_background_views: Array[TextureRect] = []
var room_frame_views: Array[TextureRect] = []
var room_head_views: Array[TextureRect] = []
var room_flag_views: Array[TextureRect] = []
var room_flag_masts: Array[Control] = []
var room_status_panels: Array[Panel] = []
var room_frame_texture_cache: Dictionary = {}
var room_crown_texture_cache: Texture2D
var room_cosmetic_time := 0.0
var selected_character_index := 0
var current_color_index: int = 0
var character_page := 0
var selected_map_index := 0
var player_count: int = 1
var bot_count: int = 0
var team_mode := false
var boss_mode := false
var difficulty := GameConstants.BotDifficulty.NORMAL

var character_page_label: Label
var character_banner_background: TextureRect
var character_banner_selfie: TextureRect
var character_stats_ui: Control
var map_preview: TextureButton
var map_name_label: Label
var map_info_name_label: Label
var map_info_players_label: Label
var map_info_diff_label: Label
var map_info_size_label: Label
var btn_select_map: Button
var chat_log: RichTextLabel
var chat_input: LineEdit
var chat_send_btn: Button
var settings_panel: Panel
var map_picker_panel: Panel
var map_select_popup: Control
var shop_panel: Control
var inventory_panel: Control
var balloon_skin_buttons: Array[Button] = []
var balloon_skin_labels: Array[Label] = []
var balloon_skin_status: Label
var inventory_currency_label: Label
var shop_currency_label: Label
var shop_skin_buttons: Array[Button] = []
var shop_skin_labels: Array[Label] = []
var master_slider: HSlider
var bgm_slider: HSlider
var sfx_slider: HSlider
var resolution_option: OptionButton
var graphics_quality_option: OptionButton
var btn_start: Button
var is_local_ready: bool = false
var fullscreen_check: CheckButton
var vsync_check: CheckButton
var server_badge: Label
var room_name_header: Label
var room_id_header: Label

func _ready() -> void:
	_discover_characters()
	for index in range(characters.size()):
		if characters[index].id == GameSession.selected_character_id:
			selected_character_index = index
			break
	character_page = selected_character_index / PAGE_SIZE
	
	if has_node("/root/RoomManager"):
		RoomManager.room_players_updated.connect(_on_room_players_updated)
		RoomManager.room_settings_updated.connect(_on_room_settings_updated)
		RoomManager.room_data_updated.connect(_on_room_data_updated)
		RoomManager.match_started.connect(_do_start_match)
		RoomManager.chat_message_received.connect(func(sender, msg, is_sys):
			var is_mine: bool = (str(sender) == GameSession.player_nickname or str(sender) == "Tôi")
			_append_chat_message(sender, msg, Color("#ffd45d") if is_sys else (Color("#66ff66") if is_mine else Color("#55e6ff")))
		)
		RoomManager.rpc_id(1, "request_room_sync", RoomManager.current_room_id)
		_sync_player_status_to_server()

	SoundManager.play_bgm("res://assets/audio/music/lobby.mp3", true)
	NetworkManager.connection_status_changed.connect(func(_c): _refresh_server_badge())
	GameSession.cokecy_changed.connect(_on_cokecy_changed)
	PlayerEquipmentService.equipment_changed.connect(func(_equipment):
		_refresh_room_slots()
		_sync_player_status_to_server()
	)
	selected_map_index = maxi(MapCatalog.MAP_IDS.find(GameSession.selected_map_id), 0)
	player_count = 1
	bot_count = 0
	difficulty = GameSession.bot_difficulty
	boss_mode = GameSession.play_mode == &"boss"
	team_mode = GameSession.play_mode == &"team"
	_build_interface()
	_refresh_all()
	if "--server" in OS.get_cmdline_user_args():
		_start_dedicated_server()

func _process(delta: float) -> void:
	room_cosmetic_time += delta
	for head_view in room_head_views:
		if not head_view.visible or not head_view.has_meta("base_position"):
			continue
		var base_position: Vector2 = head_view.get_meta("base_position")
		head_view.position = base_position
		if str(head_view.get_meta("animation", "none")) == "bob":
			var speed := float(head_view.get_meta("animation_speed", 1.0))
			var amplitude := float(head_view.get_meta("animation_amplitude", 1.5))
			head_view.position.y += sin(room_cosmetic_time * speed * 3.0) * amplitude

func _on_room_players_updated(_players: Dictionary) -> void:
	_refresh_room_slots()

func _on_room_data_updated(_data: Dictionary) -> void:
	_refresh_room_slots()
	_refresh_room_info()

func _sync_player_status_to_server() -> void:
	if has_node("/root/RoomManager"):
		RoomManager.rpc_id(1, "update_player_status", GameSession.player_nickname, str(_selected_character_id()), current_color_index, is_local_ready, str(GameSession.selected_balloon_skin), GameSession.equipped_cosmetics)

func _discover_characters() -> void:
	characters.clear()
	for res_path in ActiveCharacterRoster.PATHS:
		if ResourceLoader.exists(res_path):
			var resource = load(res_path)
			if resource is CharacterDefinition:
				var definition := resource as CharacterDefinition
				if definition.id != &"":
					characters.append(definition)
	characters.sort_custom(func(a: CharacterDefinition, b: CharacterDefinition): return a.display_name < b.display_name)

func _build_interface() -> void:
	_add_section_panel("RoomSection", Rect2(25, 70, 606, 558), Color("#0b75cd"))
	_add_section_panel("SelectionSection", Rect2(638, 70, 300, 558), Color("#0855bf"))
	# This is inset content inside RoomSection, so it must not cast a second
	# floating shadow over the lobby artwork.
	_build_room_slots()
	_build_room_chat()
	_build_character_grid()
	
	var map_title := _add_label("MapSectionTitle", Rect2(650, 372, 276, 16), "BẢN ĐỒ", 11, HORIZONTAL_ALIGNMENT_LEFT, Color("#c2e4ff"))
	map_title.add_theme_color_override("font_outline_color", Color("#040d16"))
	map_title.add_theme_constant_override("outline_size", 3)
	
	var preview_frame := Panel.new()
	preview_frame.name = "MapPreviewFrame"
	preview_frame.position = Vector2(648, 390)
	preview_frame.size = Vector2(280, 162)
	preview_frame.add_theme_stylebox_override("panel", _panel_style(Color("#002976"), Color("#004db2"), 2, 8, true))
	add_child(preview_frame)
	
	var left_thumb_panel := Panel.new()
	left_thumb_panel.position = Vector2(6, 6)
	left_thumb_panel.size = Vector2(146, 150)
	left_thumb_panel.add_theme_stylebox_override("panel", _panel_style(Color("#001f5c"), Color("#004094"), 1, 6, false))
	preview_frame.add_child(left_thumb_panel)
	
	map_preview = TextureButton.new()
	map_preview.name = "MapPreview"
	map_preview.position = Vector2(4, 4)
	map_preview.size = Vector2(138, 142)
	map_preview.ignore_texture_size = true
	map_preview.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	map_preview.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	map_preview.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	map_preview.pressed.connect(_open_map_picker)
	left_thumb_panel.add_child(map_preview)
	
	var right_info_box := Control.new()
	right_info_box.position = Vector2(158, 6)
	right_info_box.size = Vector2(116, 150)
	preview_frame.add_child(right_info_box)
	
	map_info_name_label = _build_info_row(right_info_box, 0, 22, "", Color.WHITE, 10, true)
	map_info_players_label = _build_info_row(right_info_box, 24, 18, "Người: 4", Color("#9be2ff"), 9)
	map_info_diff_label = _build_info_row(right_info_box, 44, 18, "Cấp: Dễ", Color("#9be2ff"), 9)
	map_info_size_label = _build_info_row(right_info_box, 64, 18, "Sao: ★☆☆☆☆", Color("#9be2ff"), 9)
	
	btn_select_map = Button.new()
	btn_select_map.name = "SelectMapButton"
	btn_select_map.position = Vector2(0, 86)
	btn_select_map.size = Vector2(116, 58)
	btn_select_map.text = "CHỌN\nBẢN ĐỒ"
	btn_select_map.add_theme_font_size_override("font_size", 13)
	btn_select_map.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_apply_button_skin(btn_select_map, "secondary")
	btn_select_map.pressed.connect(_open_map_picker)
	right_info_box.add_child(btn_select_map)
	
	map_name_label = map_info_name_label
	server_badge = _add_label("ServerBadge", Rect2(54, 79, 24, 24), "", 14, HORIZONTAL_ALIGNMENT_CENTER)
	room_name_header = _add_label("RoomNameHeader", Rect2(78, 80, 342, 22), "", 12, HORIZONTAL_ALIGNMENT_LEFT, Color("#dff8ff"))
	room_id_header = _add_label("RoomIdHeader", Rect2(420, 80, 180, 22), "", 11, HORIZONTAL_ALIGNMENT_RIGHT, Color("#73dcff"))
	var btn_leave = _add_button("LeaveRoomButton", Rect2(20, 20, 160, 42), "THOÁT PHÒNG", 14)
	_apply_button_skin(btn_leave, "secondary")
	btn_leave.pressed.connect(_leave_room)

	lobby_currency_label = _build_digital_lcd_box(self, Rect2(650, 18, 280, 42), "COKE", preload("res://assets/ui/coke_coin.png"))
	btn_start = _add_button("StartButton", Rect2(653, 560, 275, 60), "BẮT ĐẦU", 24)
	btn_start.add_theme_color_override("font_color", Color.WHITE)
	btn_start.add_theme_color_override("font_outline_color", Color("#7a2e03"))
	btn_start.add_theme_constant_override("outline_size", 6)
	btn_start.pressed.connect(_start_selected_mode)
	_build_bottom_navigation()
	_build_settings_panel()
	shop_panel = _build_shop_panel()
	inventory_panel = _build_inventory_panel()
	_build_map_picker()

const SLOT_W := 132
const SLOT_H := 94
const SLOT_NAME_H := 20
const SLOT_STATUS_H := 22
const SLOT_TOTAL_H := 140
const SLOT_BACKGROUND_INSET := 4
const SLOT_FRAME_RISE := 7
const SLOT_COLS := 4
const SLOT_GAP_X := 6
const SLOT_GAP_Y := 10
const SLOT_ORIGIN_X := 55
const SLOT_ORIGIN_Y := 112
const ROOM_FRAME_SOURCE_RECTS := {
	"angel_cloud_lobby.png": Rect2i(45, 15, 936, 988),
	"blossom_day_lobby.png": Rect2i(35, 21, 954, 986),
	"ember_dragon_lobby.png": Rect2i(52, 22, 924, 982),
	"neon_star_lobby.png": Rect2i(51, 10, 922, 997),
	"ocean_coral_lobby.png": Rect2i(25, 18, 979, 987),
}
const ROOM_FRAME_LAYOUT_RECTS := {
	# Destination rectangles are measured from each frame's main vertical rails,
	# not its outer ornaments. Bottoms stay aligned while decorative tops rise.
	"angel_cloud_lobby.png": Rect2(-2.0, -7.0, 136.0, 105.0),
	"blossom_day_lobby.png": Rect2(-2.0, -6.0, 136.0, 104.0),
	"ember_dragon_lobby.png": Rect2(0.0, -7.0, 132.0, 105.0),
	"neon_star_lobby.png": Rect2(-1.5, -7.0, 135.0, 105.0),
	"ocean_coral_lobby.png": Rect2(-2.5, -11.0, 137.0, 109.0),
}

func _build_room_slots() -> void:
	for index in range(8):
		var column := index % SLOT_COLS
		var row := index / SLOT_COLS
		var origin := Vector2(SLOT_ORIGIN_X + column * (SLOT_W + SLOT_GAP_X), SLOT_ORIGIN_Y + row * (SLOT_TOTAL_H + SLOT_GAP_Y))
		var slot_panel := Panel.new()
		slot_panel.name = "RoomSlotPanel%d" % index
		slot_panel.position = origin
		slot_panel.size = Vector2(SLOT_W, SLOT_H)
		# Cosmetic frames are allowed to rise slightly above the card as a visual
		# effect. The background keeps its own rounded mask inside the layout.
		slot_panel.clip_contents = false
		slot_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot_panel.add_theme_stylebox_override("panel", _panel_style(Color("#064681"), Color("#48cfff"), 0, 13, false))
		add_child(slot_panel)
		room_slot_panels.append(slot_panel)
		
		var background_view := TextureRect.new()
		background_view.name = "RoomSlotBackground%d" % index
		background_view.position = Vector2.ZERO
		background_view.size = Vector2(SLOT_W, SLOT_H)
		background_view.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		background_view.stretch_mode = TextureRect.STRETCH_SCALE
		background_view.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		background_view.material = _rounded_clip_material(Vector2(SLOT_W, SLOT_H), 13.0)
		background_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot_panel.add_child(background_view)
		room_background_views.append(background_view)

		var portrait := AnimatedSprite2D.new()
		# Room cards use the same complete 112x112 V13 canvas as gameplay and
		# character selection. The former 0.80 scale pushed tall hats/helmets and
		# the lower six silhouettes outside the 94px card surface.
		portrait.position = Vector2(48, 48)
		portrait.scale = Vector2.ONE * CharacterPresentation.SLOT_SCALE
		portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		# The decorative frame is a border layer, never a mask over the
		# character. Keep every body/VFX pixel above its bottom rail.
		portrait.z_index = 3
		slot_panel.add_child(portrait)
		room_portraits.append(portrait)

		var mast := Control.new()
		mast.name = "RoomSlotFlagMast%d" % index
		mast.position = Vector2(87, 38)
		mast.size = Vector2(39, 46)
		mast.mouse_filter = Control.MOUSE_FILTER_IGNORE
		mast.z_index = 4
		slot_panel.add_child(mast)
		room_flag_masts.append(mast)

		var mast_pole := TextureRect.new()
		mast_pole.name = "MastPole"
		mast_pole.position = Vector2(0, 0)
		mast_pole.size = Vector2(14, 46)
		mast_pole.texture = preload("res://assets/ui/flagpole_gold.png")
		mast_pole.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		mast_pole.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		mast_pole.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		mast_pole.mouse_filter = Control.MOUSE_FILTER_IGNORE
		mast.add_child(mast_pole)

		var flag_view := TextureRect.new()
		flag_view.name = "RoomSlotFlag%d" % index
		flag_view.position = Vector2(9, 7)
		flag_view.size = Vector2(29, 19)
		flag_view.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		flag_view.stretch_mode = TextureRect.STRETCH_SCALE
		flag_view.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		flag_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
		mast.add_child(flag_view)
		room_flag_views.append(flag_view)

		var head_view := TextureRect.new()
		head_view.name = "RoomSlotHead%d" % index
		head_view.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		head_view.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		head_view.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		head_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
		head_view.z_index = 4
		slot_panel.add_child(head_view)
		room_head_views.append(head_view)

		var frame_view := TextureRect.new()
		frame_view.name = "RoomSlotFrame%d" % index
		frame_view.position = Vector2(0, -SLOT_FRAME_RISE)
		frame_view.size = Vector2(SLOT_W, SLOT_H + SLOT_FRAME_RISE)
		frame_view.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		frame_view.stretch_mode = TextureRect.STRETCH_SCALE
		frame_view.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		frame_view.material = _rounded_clip_material(frame_view.size, 9.0)
		frame_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
		# Draw the frame behind the portrait. Its bottom rail must not crop
		# feet, bubble shells, win, lose or death poses.
		frame_view.z_index = 1
		slot_panel.add_child(frame_view)
		room_frame_views.append(frame_view)

		var empty_label := _add_label("RoomSlotEmpty%d" % index, Rect2(origin.x, origin.y + 20, SLOT_W, 52), "", 28, HORIZONTAL_ALIGNMENT_CENTER, Color("#d8f8ff"))
		empty_label.add_theme_constant_override("outline_size", 3)
		room_empty_labels.append(empty_label)

		var name_panel := Panel.new()
		name_panel.name = "RoomSlotNamePanel%d" % index
		name_panel.position = origin + Vector2(0, SLOT_H + 2)
		name_panel.size = Vector2(SLOT_W, SLOT_NAME_H)
		name_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		name_panel.z_index = 6
		name_panel.add_theme_stylebox_override("panel", _panel_style(Color("#02172e"), Color("#0e4977"), 1, 5, false))
		add_child(name_panel)
		room_name_panels.append(name_panel)

		var badge_icon := TextureRect.new()
		badge_icon.name = "RoomSlotBadgeIcon%d" % index
		badge_icon.position = origin + Vector2(6, SLOT_H + 5)
		badge_icon.size = Vector2(16, 14)
		badge_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		badge_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		badge_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		badge_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		badge_icon.z_index = 8
		badge_icon.visible = false
		add_child(badge_icon)
		room_badge_icons.append(badge_icon)

		var badge_label := _add_label("RoomSlotBadge%d" % index, Rect2(origin.x + 4, origin.y + SLOT_H + 3, 18, SLOT_NAME_H - 2), "", 10, HORIZONTAL_ALIGNMENT_CENTER, Color("#55e68a"))
		badge_label.add_theme_constant_override("outline_size", 2)
		badge_label.z_index = 7
		badge_label.visible = false
		room_badge_labels.append(badge_label)
		var label := _add_label("RoomSlot%d" % index, Rect2(origin.x, origin.y + SLOT_H + 2, SLOT_W, SLOT_NAME_H), "", 11, HORIZONTAL_ALIGNMENT_CENTER)
		label.add_theme_constant_override("outline_size", 2)
		label.z_index = 7
		room_labels.append(label)
		var status_panel := Panel.new()
		status_panel.name = "RoomSlotStatus%d" % index
		status_panel.position = origin + Vector2(0, SLOT_H + SLOT_NAME_H + 4)
		status_panel.size = Vector2(SLOT_W, SLOT_STATUS_H)
		status_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		status_panel.z_index = 6
		status_panel.add_theme_stylebox_override("panel", _panel_style(Color("#031f3d"), Color("#1874ad"), 1, 5, false))
		add_child(status_panel)
		room_status_panels.append(status_panel)
		var role_lbl := _add_label("RoomSlotRole%d" % index, Rect2(origin.x + 4, origin.y + SLOT_H + SLOT_NAME_H + 6, SLOT_W - 8, SLOT_STATUS_H - 4), "", 10, HORIZONTAL_ALIGNMENT_CENTER)
		role_lbl.add_theme_constant_override("outline_size", 2)
		role_lbl.z_index = 7
		room_role_labels.append(role_lbl)
		
		if index >= 4:
			var click_btn := Button.new()
			click_btn.name = "SlotBtn%d" % index
			click_btn.position = origin
			click_btn.size = Vector2(SLOT_W, SLOT_TOTAL_H)
			click_btn.flat = true
			click_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
			var captured_idx := index
			click_btn.pressed.connect(func(): _on_slot_clicked(captured_idx))
			add_child(click_btn)

func _on_slot_clicked(index: int) -> void:
	var room_data = {}
	if has_node("/root/RoomManager") and RoomManager.current_room_id != "":
		room_data = RoomManager.active_rooms.get(RoomManager.current_room_id, {})
	var host_id = room_data.get("host", 1)
	var is_host = room_data.is_empty() or host_id == multiplayer.get_unique_id()
	if not is_host:
		return

	if index >= 4 and not boss_mode:
		var target_bot_num := index - 4 + 1
		if bot_count == target_bot_num:
			bot_count = target_bot_num - 1
		else:
			bot_count = target_bot_num
		_refresh_room_slots()
		_sync_settings_to_server()

func _build_character_grid() -> void:
	var banner_frame := Panel.new()
	banner_frame.name = "CharacterBannerFrame"
	banner_frame.position = Vector2(648, 75)
	banner_frame.size = Vector2(280, 80)
	banner_frame.clip_contents = true
	banner_frame.add_theme_stylebox_override("panel", _panel_style(Color("#0776d2"), Color("#004c96"), 2, 8, true))
	add_child(banner_frame)
	
	character_banner_background = TextureRect.new()
	character_banner_background.name = "CharacterBannerBackground"
	character_banner_background.position = Vector2(4, 4)
	character_banner_background.size = Vector2(100, 72)
	character_banner_background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	character_banner_background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	character_banner_background.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	character_banner_background.material = _rounded_clip_material(Vector2(100, 72), 6.0)
	character_banner_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	banner_frame.add_child(character_banner_background)
	
	character_banner_selfie = TextureRect.new()
	character_banner_selfie.name = "CharacterBannerSelfie"
	character_banner_selfie.position = Vector2(16, 5)
	character_banner_selfie.size = Vector2(76, 70)
	character_banner_selfie.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	character_banner_selfie.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	character_banner_selfie.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	character_banner_selfie.mouse_filter = Control.MOUSE_FILTER_IGNORE
	banner_frame.add_child(character_banner_selfie)
	
	var StatBarUI = load("res://scripts/ui/StatBarUI.gd")
	character_stats_ui = StatBarUI.new()
	character_stats_ui.name = "CharacterStatsUI"
	character_stats_ui.position = Vector2(108, 4)
	banner_frame.add_child(character_stats_ui)
	
	character_buttons.clear()
	character_card_selfies.clear()
	character_check_badges.clear()
	character_empty_labels.clear()
	
	for slot in range(PAGE_SIZE):
		var col := slot % 5
		var row := slot / 5
		var slot_x := 648 + col * 57
		var slot_y := 158 + row * 57
		
		var button := _add_button("CharacterSlot%d" % slot, Rect2(slot_x, slot_y, 52, 52), "", 12)
		button.tooltip_text = "Ô nhân vật"
		var captured_slot := slot
		button.pressed.connect(func(): _select_character_slot(captured_slot))
		character_buttons.append(button)
		
		var card_selfie := TextureRect.new()
		card_selfie.position = Vector2(3, 3)
		card_selfie.size = Vector2(46, 46)
		card_selfie.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		card_selfie.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		card_selfie.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		card_selfie.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(card_selfie)
		character_card_selfies.append(card_selfie)
		
		var empty_lbl := Label.new()
		empty_lbl.position = Vector2(0, 0)
		empty_lbl.size = Vector2(52, 52)
		empty_lbl.text = "✕"
		empty_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		empty_lbl.add_theme_font_size_override("font_size", 22)
		empty_lbl.add_theme_color_override("font_color", Color(0.12, 0.35, 0.65, 0.45))
		empty_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		empty_lbl.visible = false
		button.add_child(empty_lbl)
		character_empty_labels.append(empty_lbl)
		
		var badge := TextureRect.new()
		badge.position = Vector2(34, -4)
		badge.size = Vector2(20, 20)
		badge.texture = preload("res://assets/ui/icons/check_badge.svg")
		badge.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		badge.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		badge.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		badge.visible = false
		button.add_child(badge)
		character_check_badges.append(badge)
		
	var btn_cycle = _add_button("CycleColorBtn", Rect2(648, 334, 280, 32), "ĐỔI MÀU SẮC (4 màu)", 13)
	_apply_button_skin(btn_cycle, "secondary")
	btn_cycle.pressed.connect(_cycle_color)

func _build_room_chat() -> void:
	var chat_frame := Panel.new()
	chat_frame.name = "RoomChatFrame"
	chat_frame.position = Vector2(38, 410)
	chat_frame.size = Vector2(580, 204)
	chat_frame.add_theme_stylebox_override("panel", _panel_style(Color("#0776d2"), Color("#004c96"), 2, 8, true))
	add_child(chat_frame)
	
	var chat_header := Label.new()
	chat_header.position = Vector2(14, 6)
	chat_header.size = Vector2(552, 22)
	chat_header.text = "💬  TRÒ CHUYỆN PHÒNG"
	chat_header.add_theme_font_size_override("font_size", 12)
	chat_header.add_theme_color_override("font_color", Color("#c2e4ff"))
	chat_header.add_theme_color_override("font_outline_color", Color("#040d16"))
	chat_header.add_theme_constant_override("outline_size", 3)
	chat_frame.add_child(chat_header)
	
	var log_panel := Panel.new()
	log_panel.position = Vector2(14, 30)
	log_panel.size = Vector2(552, 122)
	var log_s := StyleBoxFlat.new()
	log_s.bg_color = Color("#055fae")
	log_s.border_color = Color("#003e7e")
	log_s.set_border_width_all(1)
	log_s.border_width_bottom = 2
	log_s.set_corner_radius_all(4)
	log_s.content_margin_left = 8
	log_s.content_margin_right = 8
	log_s.content_margin_top = 6
	log_s.content_margin_bottom = 6
	log_panel.add_theme_stylebox_override("panel", log_s)
	chat_frame.add_child(log_panel)
	
	chat_log = RichTextLabel.new()
	chat_log.set_anchors_preset(PRESET_FULL_RECT)
	chat_log.bbcode_enabled = true
	chat_log.scroll_following = true
	chat_log.mouse_filter = Control.MOUSE_FILTER_PASS
	chat_log.add_theme_font_size_override("normal_font_size", 11)
	log_panel.add_child(chat_log)
	
	_append_chat_message("Hệ thống", "Chào mừng bạn đến với phòng chơi Boom Online!", Color("#ffd45d"))
	_append_chat_message("Hệ thống", "Hãy sẵn sàng và bấm BẮT ĐẦU khi mọi người đã chuẩn bị xong.", Color("#55e6ff"))
	
	var input_box := HBoxContainer.new()
	input_box.position = Vector2(14, 160)
	input_box.size = Vector2(552, 32)
	input_box.add_theme_constant_override("separation", 6)
	chat_frame.add_child(input_box)
	
	chat_input = LineEdit.new()
	chat_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	chat_input.placeholder_text = "Nhập nội dung trò chuyện..."
	chat_input.add_theme_font_size_override("font_size", 11)
	chat_input.add_theme_color_override("font_color", Color.WHITE)
	chat_input.add_theme_color_override("placeholder_color", Color("#588cae"))
	var input_s := StyleBoxFlat.new()
	input_s.bg_color = Color("#042044")
	input_s.border_color = Color("#1e70b8")
	input_s.set_border_width_all(1)
	input_s.set_corner_radius_all(4)
	input_s.content_margin_left = 8
	input_s.content_margin_right = 8
	chat_input.add_theme_stylebox_override("normal", input_s)
	chat_input.text_submitted.connect(_on_chat_submitted)
	input_box.add_child(chat_input)
	
	chat_send_btn = Button.new()
	chat_send_btn.custom_minimum_size = Vector2(66, 32)
	chat_send_btn.text = "GỬI"
	chat_send_btn.add_theme_font_size_override("font_size", 12)
	UITheme.apply_button_theme(chat_send_btn, "primary")
	chat_send_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	chat_send_btn.pressed.connect(func(): _on_chat_submitted(chat_input.text))
	input_box.add_child(chat_send_btn)

func _append_chat_message(sender: String, message: String, sender_color: Color = Color("#55e6ff")) -> void:
	if chat_log == null: return
	var hex := sender_color.to_html(false)
	chat_log.append_text("[color=#%s][%s][/color] %s\n" % [hex, sender, message])

func _on_chat_submitted(text: String) -> void:
	var clean_text := text.strip_edges()
	if clean_text.is_empty(): return
	if chat_input != null:
		chat_input.text = ""
	
	if has_node("/root/RoomManager"):
		RoomManager.rpc_id(1, "send_chat_message", clean_text)

func _build_bottom_navigation() -> void:
	# Compact navigation is flush with the bottom edge, leaving more breathing
	# room for the two independent room-card rows above it.
	var shop := _add_button("ShopButton", Rect2(52, 669, 132, 37), "CỬA HÀNG", 13)
	shop.tooltip_text = "Cửa hàng"
	_apply_button_skin(shop, "secondary")
	shop.add_theme_constant_override("outline_size", 6)
	
	var inventory := _add_button("InventoryButton", Rect2(192, 669, 132, 37), "TÚI ĐỒ", 13)
	inventory.tooltip_text = "Kho đồ / Túi đồ"
	_apply_button_skin(inventory, "secondary")
	inventory.add_theme_constant_override("outline_size", 6)
	
	# Right: Square Settings & Quit Icon Buttons (Aligned with right section x=926)
	var settings := _add_button("SettingsButton", Rect2(846, 669, 37, 37), "", 12)
	settings.tooltip_text = "Cài đặt"
	_apply_button_skin(settings, "icon_secondary")
	_set_button_icon_centered(settings, "res://assets/ui/icons/gear.png", 28)
	
	var quit := _add_button("QuitButton", Rect2(891, 669, 37, 37), "", 12)
	quit.tooltip_text = "Tắt game"
	_apply_button_skin(quit, "icon_danger")
	_set_button_icon_centered(quit, "res://assets/ui/icons/power.png", 28)
	
	shop.pressed.connect(func(): _open_feature_panel(shop_panel))
	inventory.pressed.connect(func(): _open_feature_panel(inventory_panel))
	settings.pressed.connect(func(): settings_panel.z_index = 100; settings_panel.visible = true; settings_panel.move_to_front())
	quit.pressed.connect(ExitSequence.play_and_quit)

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

func _build_feature_panel(node_name: String, title_text: String, body_text: String) -> Panel:
	var panel := Panel.new()
	panel.name = node_name
	panel.position = Vector2(255, 205)
	panel.size = Vector2(450, 260)
	panel.visible = false
	panel.add_theme_stylebox_override("panel", _panel_style(Color("#063f78"), Color("#74e9ff"), 5, 18, true))
	add_child(panel)
	var title := Label.new()
	title.position = Vector2(30, 24)
	title.size = Vector2(390, 46)
	title.text = title_text
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	panel.add_child(title)
	var body := Label.new()
	body.position = Vector2(40, 82)
	body.size = Vector2(370, 90)
	body.text = body_text
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	body.add_theme_color_override("font_color", Color("#bcefff"))
	panel.add_child(body)
	var close := Button.new()
	close.position = Vector2(130, 190)
	close.size = Vector2(190, 46)
	close.text = "X"
	close.add_theme_font_size_override("font_size", 16)
	_apply_button_skin(close, "blue")
	close.set_script(LIFT_BUTTON_SCRIPT)
	panel.add_child(close)
	close.pressed.connect(func(): panel.visible = false)
	return panel

var lobby_currency_label: Label = null

func _format_digital_number(value: int) -> String:
	var s := str(value)
	var formatted := ""
	var count := 0
	for i in range(s.length() - 1, -1, -1):
		formatted = s[i] + formatted
		count += 1
		if count % 3 == 0 and i > 0:
			formatted = "," + formatted
	return formatted

func _build_digital_lcd_box(parent: Control, rect: Rect2, label_text: String, icon_texture: Texture2D) -> Label:
	var box := Panel.new()
	box.position = rect.position
	box.size = rect.size
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#07111c")
	style.border_color = Color("#223244")
	style.set_border_width_all(2)
	style.border_width_bottom = 4
	style.set_corner_radius_all(8)
	style.shadow_color = Color(0, 0, 0, 0.5)
	style.shadow_size = 4
	style.shadow_offset = Vector2(0, 2)
	box.add_theme_stylebox_override("panel", style)
	parent.add_child(box)
	
	if icon_texture != null:
		var icon := TextureRect.new()
		icon.position = Vector2(6, (rect.size.y - 24) * 0.5)
		icon.size = Vector2(24, 24)
		icon.texture = icon_texture
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		box.add_child(icon)
		
	var badge_label := Label.new()
	badge_label.position = Vector2(34 if icon_texture != null else 8, 2)
	badge_label.size = Vector2(50, rect.size.y - 4)
	badge_label.text = label_text
	badge_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	badge_label.add_theme_font_size_override("font_size", 12)
	badge_label.add_theme_color_override("font_color", Color("#7feeff"))
	box.add_child(badge_label)
	
	var lcd_x := 88.0 if icon_texture != null else 58.0
	var lcd_w := rect.size.x - lcd_x - 6.0
	var lcd_h := rect.size.y - 8.0
	var lcd_screen := Panel.new()
	lcd_screen.position = Vector2(lcd_x, 4)
	lcd_screen.size = Vector2(lcd_w, lcd_h)
	var lcd_style := StyleBoxFlat.new()
	lcd_style.bg_color = Color("#031320")
	lcd_style.border_color = Color("#0c3f5d")
	lcd_style.set_border_width_all(1)
	lcd_style.set_corner_radius_all(5)
	lcd_screen.add_theme_stylebox_override("panel", lcd_style)
	box.add_child(lcd_screen)
	
	var ghost_label := Label.new()
	ghost_label.position = Vector2(4, 0)
	ghost_label.size = Vector2(lcd_w - 8, lcd_h)
	ghost_label.text = "88,888,888"
	ghost_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	ghost_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	ghost_label.add_theme_font_override("font", _get_digital_font())
	ghost_label.add_theme_font_size_override("font_size", 15)
	ghost_label.add_theme_color_override("font_color", Color(0.04, 0.20, 0.26, 0.4))
	lcd_screen.add_child(ghost_label)
	
	var val_label := Label.new()
	val_label.position = Vector2(4, 0)
	val_label.size = Vector2(lcd_w - 8, lcd_h)
	val_label.text = "0"
	val_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	val_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	val_label.add_theme_font_override("font", _get_digital_font())
	val_label.add_theme_font_size_override("font_size", 15)
	val_label.add_theme_color_override("font_color", Color("#00ffc4"))
	lcd_screen.add_child(val_label)
	
	return val_label

func _build_inventory_panel() -> Control:
	var view: Control = INVENTORY_VIEW_SCRIPT.new()
	view.name = "InventoryPanel"
	view.visible = false
	view.closed.connect(func(): view.visible = false)
	view.skin_selected.connect(func(_id):
		_sync_player_status_to_server()
		_refresh_all()
		_refresh_room_slots()
	)
	view.character_selected.connect(func(char_id):
		for i in range(characters.size()):
			if characters[i].id == char_id:
				selected_character_index = i
				break
		_sync_player_status_to_server()
		_refresh_all()
		_refresh_character_page()
		_refresh_room_slots()
	)
	add_child(view)
	return view

func _balloon_skin_catalog() -> Array[Dictionary]:
	var catalog: Array[Dictionary] = []
	var all_ids := WaterBalloonSkinRegistry.get_all_skin_ids()
	for skin_id in all_ids:
		var def := WaterBalloonSkinRegistry.get_skin(skin_id)
		if def == null:
			continue
		if def.price <= 0:
			continue
		var icon_tex: Texture2D = def.icon if def.icon != null else _get_skin_fallback_texture(skin_id)
		catalog.append({
			"id": skin_id,
			"name": def.display_name.to_upper(),
			"price": def.price,
			"texture": icon_tex,
			"rarity": def.rarity,
			"theme": def.theme,
		})
	return catalog

func _get_skin_fallback_texture(skin_id: StringName) -> Texture2D:
	var paths := [
		"res://assets/water_balloons/skins/%s/icon.png" % skin_id,
	]
	for path in paths:
		if ResourceLoader.exists(path):
			return load(path)
	if ResourceLoader.exists("res://assets/water_balloons/skins/skin_066/icon.png"):
		return load("res://assets/water_balloons/skins/skin_066/icon.png")
	return null

func _build_shop_panel() -> Control:
	var view: Control = SHOP_VIEW_SCRIPT.new()
	view.name = "ShopPanel"
	view.visible = false
	view.closed.connect(func(): view.visible = false)
	view.skin_purchased.connect(func(_id): _refresh_balloon_skin_selection())
	view.skin_selected.connect(func(_id): _refresh_balloon_skin_selection())
	add_child(view)
	return view

func _on_cokecy_changed(_new_value: int) -> void:
	if lobby_currency_label != null:
		lobby_currency_label.text = _format_digital_number(GameSession.cokecy)
	if inventory_currency_label != null:
		inventory_currency_label.text = _format_digital_number(GameSession.cokecy)
	_refresh_shop()

func _buy_balloon_skin(skin_id: StringName, price: int) -> void:
	if GameSession.buy_balloon_skin(skin_id, price):
		GameSession.selected_balloon_skin = skin_id
		GameSession.save_profile()
	_refresh_shop()
	_refresh_balloon_skin_selection()

func _refresh_shop() -> void:
	if shop_panel is ShopView:
		(shop_panel as ShopView).refresh()

func _select_balloon_skin(skin_id: StringName) -> void:
	if not GameSession.owns_balloon_skin(skin_id):
		return
	GameSession.selected_balloon_skin = skin_id
	GameSession.save_profile()
	_refresh_balloon_skin_selection()

func _refresh_balloon_skin_selection() -> void:
	if balloon_skin_buttons.is_empty() or balloon_skin_status == null:
		return
	var skins := _balloon_skin_catalog()
	if not GameSession.owns_balloon_skin(GameSession.selected_balloon_skin):
		GameSession.selected_balloon_skin = &"skin_066"
	for index in range(balloon_skin_buttons.size()):
		var skin: Dictionary = skins[index]
		var owned: bool = GameSession.owns_balloon_skin(skin.id)
		var selected: bool = GameSession.selected_balloon_skin == StringName(skin.id)
		_apply_button_skin(balloon_skin_buttons[index], "slot", selected)
		balloon_skin_buttons[index].self_modulate = Color(1.12, 1.12, 1.12) if selected else Color(0.75, 0.8, 0.9, 0.9)
		balloon_skin_buttons[index].tooltip_text = "Đang dùng" if selected else "Đã sở hữu"
		balloon_skin_labels[index].text = "%s\n%s" % [skin.name, "ĐANG DÙNG" if selected else "ĐÃ MỞ KHÓA"]
		balloon_skin_buttons[index].visible = owned
	var active_name := "BÓNG MẶC ĐỊNH"
	for skin: Dictionary in skins:
		if skin.id == GameSession.selected_balloon_skin:
			active_name = skin.name
	balloon_skin_status.text = "ĐANG DÙNG: %s" % active_name
	if inventory_currency_label != null:
		inventory_currency_label.text = _format_digital_number(GameSession.cokecy)

func _open_feature_panel(panel: Control) -> void:
	settings_panel.visible = false
	shop_panel.visible = panel == shop_panel
	inventory_panel.visible = panel == inventory_panel
	if panel == inventory_panel and inventory_panel.has_method("refresh"):
		inventory_panel.refresh()
	if panel == shop_panel and shop_panel.has_method("refresh"):
		shop_panel.refresh()
	panel.move_to_front()

func _build_settings_panel() -> void:
	settings_panel = Panel.new()
	settings_panel.name = "SettingsPanel"
	settings_panel.position = Vector2(230, 95)
	settings_panel.size = Vector2(500, 530)
	settings_panel.visible = false
	settings_panel.z_as_relative = false
	settings_panel.z_index = 100
	settings_panel.add_theme_stylebox_override("panel", _panel_style(Color("#0855bf"), Color("#00d2ff"), 4, 20, true))
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
	close.text = "X"
	close.add_theme_font_size_override("font_size", 16)
	close.add_theme_color_override("font_color", Color.WHITE)
	close.add_theme_color_override("font_outline_color", Color("#7a2e03"))
	close.add_theme_constant_override("outline_size", 4)
	_apply_button_skin(close, "gold")
	close.set_script(LIFT_BUTTON_SCRIPT)
	settings_panel.add_child(close)
	close.pressed.connect(_close_settings)

func _build_map_picker() -> void:
	map_select_popup = MAP_SELECT_POPUP_SCRIPT.new()
	map_select_popup.name = "MapSelectPopup"
	map_select_popup.visible = false
	map_select_popup.map_selected.connect(_on_map_picker_selected)
	add_child(map_select_popup)
	map_picker_panel = map_select_popup.modal_panel

func _on_map_picker_selected(map_id: StringName) -> void:
	var idx := MapCatalog.MAP_IDS.find(map_id)
	if idx != -1:
		selected_map_index = idx
		GameSession.selected_map_id = map_id
		_refresh_map()
		_sync_settings_to_server()

func _add_slider_row(parent: VBoxContainer, caption: String, value: float) -> HSlider:
	var label := Label.new()
	label.text = caption
	parent.add_child(label)
	var slider := HSlider.new()
	slider.max_value = 1.0
	slider.step = 0.05
	slider.value = value
	parent.add_child(slider)
	return slider

func _add_label(node_name: String, rect: Rect2, text: String, font_size: int, alignment := HORIZONTAL_ALIGNMENT_LEFT, color := Color("#d9f5ff")) -> Label:
	var label := Label.new()
	label.name = node_name
	label.position = rect.position
	label.size = rect.size
	label.text = text
	label.horizontal_alignment = alignment
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color("#05264b"))
	label.add_theme_constant_override("outline_size", 4)
	add_child(label)
	return label

func _add_section_panel(node_name: String, rect: Rect2, background: Color, shadow := true) -> Panel:
	var panel := Panel.new()
	panel.name = node_name
	panel.position = rect.position
	panel.size = rect.size
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel", _panel_style(background, Color("#2a3b4e"), 3, 16, shadow))
	add_child(panel)
	return panel

func _add_button(node_name: String, rect: Rect2, text: String, font_size: int) -> Button:
	var button := Button.new()
	button.name = node_name
	button.position = rect.position
	button.size = rect.size
	button.text = text
	button.flat = false
	button.add_theme_font_size_override("font_size", font_size)
	button.add_theme_color_override("font_color", Color("#ecfbff"))
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", Color("#fff5b6"))
	button.add_theme_color_override("font_outline_color", Color("#05264b"))
	button.add_theme_constant_override("outline_size", 3)
	_apply_button_skin(button, "gold" if node_name == "StartButton" else "blue")
	button.set_script(LIFT_BUTTON_SCRIPT)
	add_child(button)
	return button

func _refresh_all() -> void:
	_refresh_server_badge()
	_refresh_character_page()
	_refresh_map()
	_refresh_room_slots()
	if lobby_currency_label != null:
		lobby_currency_label.text = _format_digital_number(GameSession.cokecy)

func _refresh_server_badge() -> void:
	if server_badge == null:
		return
	if NetworkManager.is_connected_to_server():
		server_badge.text = "●"
		server_badge.modulate = Color("#75ff96")
		server_badge.tooltip_text = "Máy chủ trực tuyến • cổng 7777"
	else:
		server_badge.text = "●"
		server_badge.modulate = Color("#ff7575")
		server_badge.tooltip_text = "Máy chủ ngoại tuyến"

func _refresh_character_page() -> void:
	var pages := maxi(ceili(float(characters.size()) / PAGE_SIZE), 1)
	character_page = wrapi(character_page, 0, pages)
	if character_page_label != null:
		character_page_label.text = "%d / %d" % [character_page + 1, pages]
		character_page_label.visible = pages > 1
	if has_node("CharacterPrev"):
		get_node("CharacterPrev").visible = pages > 1
	if has_node("CharacterNext"):
		get_node("CharacterNext").visible = pages > 1
		
	if not characters.is_empty():
		var selected := characters[selected_character_index]
		character_banner_background.texture = selected.banner_background_texture
		var transparent_selfie: Texture2D = _get_character_portrait(selected)
		character_banner_selfie.texture = transparent_selfie
		character_banner_selfie.pivot_offset = character_banner_selfie.size * 0.5
		character_banner_selfie.scale = CharacterPresentation.content_scale_vector(selected)
		character_stats_ui.update_stats(
			selected.display_name,
			selected.base_water_balloon_capacity, selected.max_water_balloon_capacity,
			selected.base_water_power, selected.max_water_power,
			selected.base_speed, selected.max_speed
		)
		
	for slot in range(PAGE_SIZE):
		var index := character_page * PAGE_SIZE + slot
		var button := character_buttons[slot]
		var selfie: TextureRect = character_card_selfies[slot]
		var empty_lbl: Label = character_empty_labels[slot]
		var check_badge: TextureRect = character_check_badges[slot]
		
		if index < characters.size():
			var character := characters[index]
			var is_selected := (index == selected_character_index)
			selfie.visible = true
			# Character slots use the same full, anchored idle frame as gameplay.
			# The old 96px portrait crop was a scenic square and caused newer
			# silhouettes to disappear beyond the small slot bounds.
			selfie.texture = CharacterPresentation.idle_texture(character)
			selfie.pivot_offset = selfie.size * 0.5
			selfie.scale = CharacterPresentation.content_scale_vector(character)
			empty_lbl.visible = false
			check_badge.visible = is_selected
			button.tooltip_text = character.display_name
			button.disabled = false
			button.self_modulate = Color.WHITE
			if is_selected:
				button.add_theme_stylebox_override("normal", UITheme.slot_character_selected())
				button.add_theme_stylebox_override("hover", UITheme.slot_character_selected())
			else:
				button.add_theme_stylebox_override("normal", UITheme.slot_character_normal())
				button.add_theme_stylebox_override("hover", UITheme.slot_character_selected())
		else:
			selfie.visible = false
			selfie.texture = null
			selfie.scale = Vector2.ONE
			empty_lbl.visible = true
			check_badge.visible = false
			button.tooltip_text = "Ô trống"
			button.disabled = true
			button.self_modulate = Color.WHITE
			button.add_theme_stylebox_override("normal", UITheme.slot_character_empty())
			button.add_theme_stylebox_override("hover", UITheme.slot_character_empty())

func _get_character_portrait(character: CharacterDefinition) -> Texture2D:
	if character == null:
		return null
	var path := "res://assets/ui/character_portraits/%s.png" % character.id
	if ResourceLoader.exists(path):
		return load(path)
	if character.selfie_texture != null:
		return character.selfie_texture
	return character.preview_texture

func _build_info_row(parent: Control, y_pos: int, height: int, default_text: String, text_color: Color, font_size: int, is_bold: bool = false) -> Label:
	var row_panel := Panel.new()
	row_panel.position = Vector2(0, y_pos)
	row_panel.size = Vector2(116, height)
	row_panel.add_theme_stylebox_override("panel", _panel_style(Color("#002976"), Color("#004db2"), 1, 3, false))
	parent.add_child(row_panel)
	
	var lbl := Label.new()
	lbl.set_anchors_preset(PRESET_FULL_RECT)
	lbl.text = default_text
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER if is_bold else HORIZONTAL_ALIGNMENT_LEFT
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", font_size)
	lbl.add_theme_color_override("font_color", text_color)
	if not is_bold:
		lbl.position.x = 4
	row_panel.add_child(lbl)
	return lbl

func _refresh_map() -> void:
	var map_id := MapCatalog.MAP_IDS[selected_map_index]
	var map_definition := MapCatalog.create_map(map_id)
	
	if map_info_name_label != null:
		map_info_name_label.text = map_definition.display_name
	if map_info_players_label != null:
		map_info_players_label.text = "Người:  8" if map_id == &"pirate_harbor" else "Người:  4"
	if map_info_diff_label != null:
		var meta := MapCatalog.get_map_metadata(map_id)
		map_info_diff_label.text = "Cấp:    %s" % meta.get("diff", "Dễ")
	if map_info_size_label != null:
		var stars := "★☆☆☆☆" if map_id == &"training_plaza" else ("★★☆☆☆" if map_id == &"aqua_park" else ("★★★☆☆" if map_id == &"pirate_harbor" else "★★★★☆"))
		map_info_size_label.text = "Sao:    %s" % stars
		
	var preview_path := "res://assets/ui/map_previews/map_%s.png" % map_id
	var preview_texture := load(preview_path) if ResourceLoader.exists(preview_path) else null
	if map_preview != null:
		map_preview.texture_normal = preview_texture
		map_preview.texture_hover = preview_texture
		map_preview.texture_pressed = preview_texture
	_refresh_room_info()

func _refresh_room_slots() -> void:
	# RoomManager can answer a local-host sync during _ready(), before the
	# dynamic lobby controls have been built.  The final _refresh_all() call
	# repaints once all eight cards exist.
	if room_portraits.size() < 8 or room_flag_views.size() < 8 or room_frame_views.size() < 8 or room_background_views.size() < 8 or room_head_views.size() < 8 or room_name_panels.size() < 8 or room_empty_labels.size() < 8:
		return
	var roster := characters
	
	var room_data = {}
	if has_node("/root/RoomManager") and RoomManager.current_room_id != "":
		room_data = RoomManager.active_rooms.get(RoomManager.current_room_id, {})
	
	var players = room_data.get("players", [1])
	var host_id = room_data.get("host", 1)
	var is_host = room_data.is_empty() or host_id == multiplayer.get_unique_id()
	
	for index in range(8):
		var is_player = index < players.size()
		var active = is_player or (index >= 4 and (index - 4) < bot_count and not boss_mode)
		room_portraits[index].visible = active
		room_flag_masts[index].visible = active
		room_flag_views[index].visible = active
		room_status_panels[index].visible = true
		room_name_panels[index].visible = true
		room_empty_labels[index].visible = not active
		
		if is_player and not roster.is_empty():
			var p_id = players[index]
			var p_data = {}
			if has_node("/root/RoomManager") and RoomManager.room_players.has(p_id):
				p_data = RoomManager.room_players[p_id]
			
			var char_id_str = str(p_data.get("char_id", ""))
			var color_idx = p_data.get("color_idx", 0) if p_id != multiplayer.get_unique_id() else current_color_index
			var p_name = p_data.get("name", "Player " + str(p_id)) if p_id != multiplayer.get_unique_id() else GameSession.player_nickname
			var is_ready = p_data.get("is_ready", false) if p_id != host_id else true
			var equipment: Dictionary = p_data.get("equipment", CosmeticRegistry.default_equipment())
			if p_id == multiplayer.get_unique_id():
				equipment = GameSession.equipped_cosmetics
			_apply_room_slot_equipment(index, equipment)
			
			var character: CharacterDefinition = null
			if p_id == multiplayer.get_unique_id():
				character = characters[selected_character_index]
			elif char_id_str != "":
				for c in characters:
					if str(c.id) == char_id_str:
						character = c
						break
			if character == null:
				var char_idx = p_data.get("char_idx", 0)
				character = roster[char_idx % roster.size()]
				
			room_portraits[index].sprite_frames = character.sprite_frames
			room_portraits[index].scale = CharacterPresentation.slot_scale_vector_for(character)
			room_portraits[index].play(&"idle_down")
			
			if room_portraits[index].material == null:
				room_portraits[index].material = ShaderMaterial.new()
				room_portraits[index].material.shader = preload("res://assets/shaders/hue_shift.gdshader")
			room_portraits[index].material.set_shader_parameter("shift_amount", color_idx * 0.25)
			
			room_labels[index].text = p_name
			room_labels[index].modulate = Color.WHITE
			
			if p_id == host_id:
				room_badge_icons[index].visible = true
				room_badge_icons[index].texture = _get_crown_texture()
				room_badge_labels[index].text = ""
				_set_room_slot_status(index, "TRƯỞNG PHÒNG", Color("#55e6ff"), Color("#0058a8"), Color("#00d2ff"))
			else:
				room_badge_icons[index].visible = false
				room_badge_labels[index].text = ""
				if is_ready:
					_set_room_slot_status(index, "SẴN SÀNG", Color("#ffe45e"), Color("#0058a8"), Color("#00a2e8"))
				else:
					_set_room_slot_status(index, "CHUẨN BỊ", Color("#c2e4ff"), Color("#004484"), Color("#003060"))
				
		elif active and not roster.is_empty():
			var bot_idx = index - 4
			var character = roster[(bot_idx + 1) % roster.size()]
			room_portraits[index].sprite_frames = character.sprite_frames
			room_portraits[index].scale = CharacterPresentation.slot_scale_vector_for(character)
			room_portraits[index].play(&"idle_down")
			
			if room_portraits[index].material != null:
				room_portraits[index].material.set_shader_parameter("shift_amount", 0.0)
			
			room_labels[index].text = "BOT %d" % (bot_idx + 1)
			_apply_room_slot_equipment(index, CosmeticRegistry.default_equipment())
			room_labels[index].modulate = Color(1.0, 0.85, 0.6)
			room_badge_icons[index].visible = false
			room_badge_labels[index].text = ""
			_set_room_slot_status(index, "SẴN SÀNG", Color("#ffe45e"), Color("#0058a8"), Color("#00a2e8"))
		else:
			room_portraits[index].scale = Vector2.ONE * CharacterPresentation.SLOT_SCALE
			room_flag_views[index].texture = null
			room_background_views[index].texture = null
			room_frame_views[index].texture = null
			room_head_views[index].texture = null
			room_badge_icons[index].visible = false
			room_slot_panels[index].add_theme_stylebox_override("panel", _panel_style(Color("#00aef0"), Color("#004c96"), 2, 13, false))
			room_name_panels[index].add_theme_stylebox_override("panel", _panel_style(Color("#0058a8"), Color("#003870"), 1, 5, false))
			room_labels[index].text = ""
			room_badge_labels[index].text = ""
			var can_add_bot: bool = index >= 4 and not boss_mode and bool(is_host)
			room_empty_labels[index].text = ""
			_set_room_slot_status(index, "+ THÊM BOT" if can_add_bot else "", Color("#9be2ff"), Color("#004890"), Color("#003060"))
	
	if btn_start != null:
		if is_host:
			btn_start.text = "BẮT ĐẦU"
		else:
			btn_start.text = "HỦY SẴN SÀNG" if is_local_ready else "SẴN SÀNG"
			
		if map_preview != null: 
			map_preview.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if is_host else Control.CURSOR_ARROW
		if btn_select_map != null:
			btn_select_map.disabled = not is_host

func _set_room_slot_status(index: int, text: String, text_color: Color, background: Color, border: Color) -> void:
	room_role_labels[index].text = text
	room_role_labels[index].modulate = text_color
	room_status_panels[index].add_theme_stylebox_override("panel", _panel_style(background, border, 1, 5, false))

func _apply_room_slot_equipment(index: int, equipment: Dictionary) -> void:
	if index < 0 or index >= room_flag_views.size():
		return
	var sanitized := CosmeticRegistry.sanitize_equipment(equipment)
	var flag := CosmeticRegistry.get_definition(sanitized.get("flag", "flag_default_water"))
	room_flag_views[index].texture = flag.lobby_asset if flag != null else null
	room_flag_views[index].visible = room_flag_masts[index].visible and room_flag_views[index].texture != null

	var head := CosmeticRegistry.get_definition(sanitized.get("head_accessory", ""))
	room_head_views[index].texture = head.lobby_asset if head != null else null
	room_head_views[index].visible = room_portraits[index].visible and room_head_views[index].texture != null
	if head != null:
		var head_size := Vector2(76, 48) * head.lobby_scale
		room_head_views[index].size = head_size
		var head_base := Vector2(45, 33) + head.lobby_offset - head_size * 0.5
		room_head_views[index].position = head_base
		room_head_views[index].set_meta("base_position", head_base)
		room_head_views[index].set_meta("animation", head.animation)
		room_head_views[index].set_meta("animation_speed", head.animation_speed)
		room_head_views[index].set_meta("animation_amplitude", head.animation_amplitude)

	var frame := CosmeticRegistry.get_definition(sanitized.get("player_frame", "frame_default_aqua"))
	var background := CosmeticRegistry.get_definition(sanitized.get("player_background", "background_default_aqua"))
	var has_frame: bool = (frame != null and frame.lobby_asset != null)
	room_frame_views[index].texture = _normalized_room_frame_texture(frame.lobby_asset) if has_frame else null
	var frame_file: String = frame.lobby_asset.resource_path.get_file() if has_frame else ""
	var frame_rect: Rect2 = ROOM_FRAME_LAYOUT_RECTS.get(
		frame_file,
		Rect2(0, -SLOT_FRAME_RISE, SLOT_W, SLOT_H + SLOT_FRAME_RISE + 4)
	)
	room_frame_views[index].position = frame_rect.position
	room_frame_views[index].size = frame_rect.size
	room_frame_views[index].z_index = 1
	room_frame_views[index].texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	room_frame_views[index].material = _rounded_clip_material(frame_rect.size, 9.0)

	var background_size := Vector2(SLOT_W, SLOT_H) - Vector2.ONE * (SLOT_BACKGROUND_INSET * 2.0)
	room_background_views[index].position = Vector2.ONE * float(SLOT_BACKGROUND_INSET)
	room_background_views[index].size = background_size
	room_background_views[index].texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	room_background_views[index].material.set_shader_parameter("rect_size", background_size)
	room_background_views[index].material.set_shader_parameter("radius_px", 9.0)

	room_background_views[index].texture = background.lobby_asset if background != null else null
	room_frame_views[index].visible = room_portraits[index].visible and room_frame_views[index].texture != null
	room_background_views[index].visible = room_portraits[index].visible and room_background_views[index].texture != null
	var border := frame.accent_color if frame != null else Color("#25384c")
	var slot_style := _panel_style(Color.TRANSPARENT, border, 2, 13, false)
	room_slot_panels[index].add_theme_stylebox_override("panel", slot_style)

func _normalized_room_frame_texture(texture: Texture2D) -> Texture2D:
	if texture == null:
		return null
	var file_name: String = texture.resource_path.get_file()
	var source_rect: Rect2i = ROOM_FRAME_SOURCE_RECTS.get(file_name, Rect2i())
	if source_rect.size == Vector2i.ZERO:
		return texture
	if room_frame_texture_cache.has(file_name):
		return room_frame_texture_cache[file_name]
	var cropped := AtlasTexture.new()
	cropped.atlas = texture
	cropped.region = Rect2(source_rect)
	room_frame_texture_cache[file_name] = cropped
	return cropped

func _get_crown_texture() -> Texture2D:
	if room_crown_texture_cache != null:
		return room_crown_texture_cache
	if ResourceLoader.exists("res://assets/ui/crown_gold.png"):
		room_crown_texture_cache = load("res://assets/ui/crown_gold.png")
	if room_crown_texture_cache == null and FileAccess.file_exists("res://assets/ui/crown_gold.png"):
		var img := Image.load_from_file("res://assets/ui/crown_gold.png")
		if img != null and not img.is_empty():
			room_crown_texture_cache = ImageTexture.create_from_image(img)
	return room_crown_texture_cache

func _refresh_room_info() -> void:
	if room_name_header == null or room_id_header == null:
		return
	var room: Dictionary = {}
	if has_node("/root/RoomManager") and not RoomManager.current_room_id.is_empty():
		room = RoomManager.active_rooms.get(RoomManager.current_room_id, {})
	var room_name := str(room.get("name", "PHÒNG LUYỆN TẬP"))
	var room_id := str(room.get("id", RoomManager.current_room_id if has_node("/root/RoomManager") else "LOCAL"))
	var compact_id := room_id.trim_prefix("ROOM_")
	if compact_id.length() > 8:
		compact_id = compact_id.right(8)
	room_name_header.text = room_name.to_upper()
	room_id_header.text = "PHÒNG #%s" % (compact_id if not compact_id.is_empty() else "LOCAL")

func _select_character_slot(slot: int) -> void:
	var index := character_page * PAGE_SIZE + slot
	if index < characters.size():
		selected_character_index = index
		GameSession.selected_character_id = characters[selected_character_index].id
		GameSession.save_profile()
		_sync_player_status_to_server()
		_refresh_all()
		_refresh_character_page()
		_refresh_room_slots()

func _cycle_color() -> void:
	current_color_index = (current_color_index + 1) % 4
	_sync_player_status_to_server()
	_refresh_room_slots()

func _change_character_page(delta: int) -> void:
	var pages := maxi(ceili(float(characters.size()) / PAGE_SIZE), 1)
	character_page = wrapi(character_page + delta, 0, pages)
	_refresh_character_page()

func _open_map_picker() -> void:
	if map_select_popup != null:
		map_select_popup.open(MapCatalog.MAP_IDS[selected_map_index])

func _animate_map_preview(target_scale: Vector2, target_color: Color) -> void:
	if map_preview != null and map_preview.disabled: return
	var tween := create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(map_preview, "scale", target_scale, 0.14)
	tween.tween_property(map_preview, "self_modulate", target_color, 0.14)

func _select_map(index: int) -> void:
	selected_map_index = clampi(index, 0, MapCatalog.MAP_IDS.size() - 1)
	_refresh_map()
	_refresh_map_cards()
	map_picker_panel.visible = false
	_sync_settings_to_server()
	_sync_settings_to_server()

func _refresh_map_cards() -> void:
	for index in range(map_cards.size()):
		map_cards[index].visible = not boss_mode or MapCatalog.MAP_IDS[index] == &"pirate_harbor"
		map_cards[index].add_theme_stylebox_override("panel", _map_card_style(index == selected_map_index, false))

func _set_map_card_hover(index: int, hovered: bool) -> void:
	if index < 0 or index >= map_cards.size():
		return
	var card := map_cards[index]
	card.pivot_offset = card.size * 0.5
	card.add_theme_stylebox_override("panel", _map_card_style(index == selected_map_index, hovered))
	var tween := create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(card, "scale", Vector2.ONE * (1.025 if hovered else 1.0), 0.14)
	tween.tween_property(card, "self_modulate", Color(1.1, 1.1, 1.1) if hovered else Color.WHITE, 0.14)

func _panel_style(background: Color, border: Color, width: int, radius: int, shadow: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(width)
	if width > 0:
		style.border_width_bottom = width + 2
	style.set_corner_radius_all(radius)
	style.anti_aliasing = true
	style.content_margin_left = 12.0
	style.content_margin_right = 12.0
	style.content_margin_top = 8.0
	style.content_margin_bottom = 8.0
	if shadow:
		style.shadow_color = Color(0.0, 0.0, 0.0, 0.6)
		style.shadow_size = 6
		style.shadow_offset = Vector2(0, 4)
	return style

func _rounded_clip_material(rect_size: Vector2, radius: float) -> ShaderMaterial:
	# Control.clip_contents only clips to a rectangle. This shader supplies the
	# actual rounded mask so banner art can never poke through its frame corners.
	var material := ShaderMaterial.new()
	material.shader = preload("res://assets/shaders/rounded_clip.gdshader")
	material.set_shader_parameter("rect_size", rect_size)
	material.set_shader_parameter("radius_px", radius)
	return material

func _map_card_style(selected: bool, hovered: bool) -> StyleBoxFlat:
	var border := Color("#ffd45d") if selected else (Color("#42586e") if hovered else Color("#223244"))
	var bg := Color("#142538") if hovered else Color("#08121c")
	var style := _panel_style(bg, border, 4 if selected else 2, 12, true)
	style.content_margin_left = 0.0
	style.content_margin_right = 0.0
	style.content_margin_top = 0.0
	style.content_margin_bottom = 0.0
	style.shadow_size = 12 if hovered else 6
	style.shadow_offset = Vector2(0, 5 if hovered else 3)
	return style

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

func _toggle_mode() -> void:
	if not team_mode and not boss_mode:
		team_mode = true
		player_count = maxi(player_count, 2)
	elif team_mode:
		team_mode = false
		boss_mode = true
		player_count = 1
		selected_map_index = MapCatalog.MAP_IDS.find(&"pirate_harbor")
	else:
		boss_mode = false
		team_mode = false
		player_count = 2
	_refresh_map()
	_refresh_room_slots()
	_sync_settings_to_server()

func _apply_mode_visibility() -> void:
	pass

func _cycle_players() -> void:
	bot_count = (bot_count + 1) % 5
	_refresh_room_slots()
	_sync_settings_to_server()

func _cycle_difficulty() -> void:
	difficulty = (difficulty + 1) % 4
	_sync_settings_to_server()

func _selected_character_id() -> StringName:
	return characters[selected_character_index].id

func _start_selected_mode() -> void:
	if not NetworkManager.is_connected_to_server():
		NetworkManager.connect_to_default_server()
		await get_tree().create_timer(0.35).timeout
		
	if not NetworkManager.is_connected_to_server():
		_append_chat_message("Hệ thống", "CẢNH BÁO: Chưa kết nối Máy chủ! Vui lòng chạy start_server.bat trên cổng 7777 để bắt đầu trận đấu.", Color("#ff5555"))
		_refresh_server_badge()
		return
		
	var room_data = {}
	if has_node("/root/RoomManager") and RoomManager.current_room_id != "":
		room_data = RoomManager.active_rooms.get(RoomManager.current_room_id, {})
		
	var is_host = room_data.is_empty() or room_data.get("host", 1) == multiplayer.get_unique_id()
	
	if not is_host:
		is_local_ready = not is_local_ready
		_sync_player_status_to_server()
		_refresh_room_slots()
		return
		
	var players: Array = room_data.get("players", [1])
	var peers: Array = Array(multiplayer.get_peers()) if multiplayer.has_multiplayer_peer() else []
	var other_human_players: Array = []
	for p in players:
		if p != multiplayer.get_unique_id() and (p in peers or (multiplayer.is_server() and p != 1)):
			other_human_players.append(p)
			
	for p in other_human_players:
		var p_data = RoomManager.room_players.get(p, {})
		if not p_data.get("is_ready", false):
			_append_chat_message("Hệ thống", "CHƯA THỂ BẮT ĐẦU: Có người chơi chưa Sẵn Sàng hoặc chưa về phòng!", Color("#ffe15d"))
			return # Real human player is not ready
				
	if has_node("/root/RoomManager") and RoomManager.current_room_id != "" and RoomManager.active_rooms.has(RoomManager.current_room_id):
		RoomManager.rpc_id(1, "request_start_match")
	else:
		_do_start_match()

func _do_start_match() -> void:
	if boss_mode:
		GameSession.configure_boss(MapCatalog.MAP_IDS[selected_map_index], _selected_character_id())
	elif team_mode:
		GameSession.configure_team(1 + bot_count, difficulty, MapCatalog.MAP_IDS[selected_map_index], _selected_character_id())
	else:
		var room_data = {}
		if has_node("/root/RoomManager") and RoomManager.current_room_id != "":
			room_data = RoomManager.active_rooms.get(RoomManager.current_room_id, {})
		
		if room_data.has("players") and room_data.players.size() > 1:
			GameSession.play_mode = &"multiplayer"
			GameSession.selected_map_id = MapCatalog.MAP_IDS[selected_map_index]
			GameSession.selected_character_id = _selected_character_id()
		else:
			GameSession.configure_solo(bot_count, difficulty, MapCatalog.MAP_IDS[selected_map_index], _selected_character_id())
	get_tree().change_scene_to_file("res://scenes/match/MatchArena.tscn")


func _close_settings() -> void:
	SettingsStore.update_audio(master_slider.value, bgm_slider.value, sfx_slider.value)
	var quality_idx := graphics_quality_option.selected if graphics_quality_option != null else 2
	SettingsStore.update_display(fullscreen_check.button_pressed, vsync_check.button_pressed, resolution_option.selected, quality_idx)
	settings_panel.visible = false

func _start_dedicated_server() -> void:
	var port := 7777
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--port="):
			port = int(arg.trim_prefix("--port="))
	if NetworkManager.start_host(port, 8):
		GameSession.play_mode = &"online"
		get_tree().change_scene_to_file("res://scenes/match/MatchArena.tscn")

func _add_grid_hover(button: Button) -> void:
	button.mouse_entered.connect(func():
		var tw := create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(button, "scale", Vector2(1.05, 1.05), 0.12)
		tw.tween_property(button, "self_modulate", Color(1.12, 1.12, 1.12), 0.12)
	)
	button.mouse_exited.connect(func():
		var tw := create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(button, "scale", Vector2.ONE, 0.14)
		tw.tween_property(button, "self_modulate", Color.WHITE, 0.14)
	)

func _leave_room() -> void:
	if has_node("/root/RoomManager"):
		RoomManager.rpc_id(1, "request_leave_room")
	get_tree().change_scene_to_file("res://scenes/lobby/Lobby.tscn")


func _sync_settings_to_server() -> void:
	if has_node("/root/RoomManager"):
		var map_id = str(MapCatalog.MAP_IDS[selected_map_index])
		var mode = "boss" if boss_mode else ("team" if team_mode else "solo")
		RoomManager.rpc_id(1, "request_update_settings", map_id, mode, bot_count, difficulty)

func _on_room_settings_updated(settings: Dictionary) -> void:
	var map_id = settings.get("map", "")
	if map_id != "":
		var found_map_idx = MapCatalog.MAP_IDS.find(StringName(map_id))
		if found_map_idx != -1:
			selected_map_index = found_map_idx
	var mode = settings.get("mode", "solo")
	boss_mode = (mode == "boss")
	team_mode = (mode == "team")
	bot_count = settings.get("bots", 0)
	difficulty = settings.get("diff", 1)
	_apply_mode_visibility()
	_refresh_map()
	_refresh_map_cards()
	_refresh_room_slots()
	_refresh_room_info()
