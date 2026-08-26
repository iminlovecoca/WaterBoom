class_name RoomWaitScreen
extends Control

signal leave_room_requested
signal start_game_requested
signal open_shop_requested
signal open_inventory_requested
signal open_settings_requested

const BoomPalette = preload("res://ui/theme/palette.gd")
const BoomTypography = preload("res://ui/theme/typography.gd")
const SHOP_VIEW_SCRIPT = preload("res://scripts/ui/ShopView.gd")
const INVENTORY_VIEW_SCRIPT = preload("res://scripts/ui/InventoryView.gd")
const MAP_SELECT_POPUP_SCRIPT = preload("res://scripts/ui/MapSelectPopup.gd")

@onready var left_panel: BoomPanel = get_node_or_null("LeftPanel")
@onready var right_panel: BoomPanel = get_node_or_null("RightPanel")
@onready var header: BoomHeader = get_node_or_null("LeftPanel/Header")
@onready var map_card: BoomMapCard = get_node_or_null("RightPanel/MapCard")
@onready var status_box: BoomStatusBox = get_node_or_null("RightPanel/StatusBox")
@onready var start_btn: BoomButton = get_node_or_null("RightPanel/StartButton")
@onready var auto_ready_btn: BoomButton = get_node_or_null("RightPanel/AutoReadyButton")
@onready var cycle_color_btn: BoomButton = get_node_or_null("RightPanel/CycleColorButton")
@onready var chat_log: RichTextLabel = get_node_or_null("LeftPanel/ChatLogBox/ChatLog")
@onready var chat_input: LineEdit = get_node_or_null("LeftPanel/ChatInputBox/ChatInput")
@onready var chat_send_btn: BoomButton = get_node_or_null("LeftPanel/ChatSendBtn")

var room_slots: Array[BoomRoomSlot] = []
var char_slots: Array[BoomSlot] = []

var characters: Array[CharacterDefinition] = []
var selected_char_idx: int = 0
var current_color_idx: int = 0
var is_ready_state: bool = false
var bot_count: int = 0
var team_mode: bool = false
var selected_team: String = ""

var shop_view: Control = null
var inventory_view: Control = null
var map_select_popup: Control = null
var settings_panel: Panel = null

func _ready() -> void:
	SoundManager.play_bgm("res://assets/audio/music/lobby.mp3", true)
	_discover_characters()
	_bind_components()
	_build_room_slots()
	_build_character_grid()
	_refresh_display()
	_refresh_room_header()
	
	if has_node("/root/RoomManager"):
		RoomManager.room_players_updated.connect(func(_p): _refresh_room_slots())
		RoomManager.room_data_updated.connect(func(_d): 
			_refresh_room_slots()
			_refresh_room_header()
		)
		RoomManager.room_settings_updated.connect(_on_room_settings_updated)
		RoomManager.match_started.connect(_do_start_match)
		RoomManager.chat_message_received.connect(_on_chat_received)
		RoomManager.rpc_id(1, "request_room_sync", RoomManager.current_room_id)
		_sync_player_status()
		
	PlayerEquipmentService.equipment_changed.connect(func(_eq):
		_refresh_room_slots()
		_sync_player_status()
	)

func _discover_characters() -> void:
	characters.clear()
	for p in ActiveCharacterRoster.PATHS:
		if ResourceLoader.exists(p):
			var res = load(p)
			if res is CharacterDefinition:
				characters.append(res)
				
	for i in range(characters.size()):
		if characters[i].id == GameSession.selected_character_id:
			selected_char_idx = i
			break

func _bind_components() -> void:
	if start_btn != null: start_btn.pressed.connect(_on_start_pressed)
	if auto_ready_btn != null: auto_ready_btn.pressed.connect(_on_auto_ready_pressed)
	if cycle_color_btn != null: cycle_color_btn.pressed.connect(_on_cycle_color)
	if chat_send_btn != null: chat_send_btn.pressed.connect(_on_chat_submit)
	if chat_input != null: chat_input.text_submitted.connect(func(_t): _on_chat_submit())
	
	var red_btn = get_node_or_null("RightPanel/TeamSelectBox/RedTeamBtn")
	if red_btn != null: red_btn.pressed.connect(func(): _select_team("red"))
	var blue_btn = get_node_or_null("RightPanel/TeamSelectBox/BlueTeamBtn")
	if blue_btn != null: blue_btn.pressed.connect(func(): _select_team("blue"))
	
	var leave_btn = get_node_or_null("FooterNavigation/LeaveBtn")
	if leave_btn != null: leave_btn.pressed.connect(_on_leave_pressed)
	var shop_btn = get_node_or_null("FooterNavigation/ShopBtn")
	if shop_btn != null: shop_btn.pressed.connect(_open_shop)
	var inv_btn = get_node_or_null("FooterNavigation/InventoryBtn")
	if inv_btn != null: inv_btn.pressed.connect(_open_inventory)
	var set_btn = get_node_or_null("FooterNavigation/SettingsBtn")
	if set_btn != null: set_btn.pressed.connect(_open_settings)
	
	if map_card != null:
		map_card.map_change_requested.connect(_open_map_picker)

func _refresh_room_header() -> void:
	if header == null: return
	var room_name := "PHÒNG LUYỆN TẬP"
	var room_id := "LOCAL"
	if has_node("/root/RoomManager") and not RoomManager.current_room_id.is_empty():
		var room_data = RoomManager.active_rooms.get(RoomManager.current_room_id, {})
		room_name = str(room_data.get("name", "PHÒNG LUYỆN TẬP"))
		room_id = str(room_data.get("id", RoomManager.current_room_id))
		var compact := room_id.trim_prefix("ROOM_")
		if compact.length() > 8:
			compact = compact.right(8)
		room_id = compact if not compact.is_empty() else "LOCAL"
	header.room_name = room_name.to_upper()
	header.room_id = room_id

func _select_team(team: String) -> void:
	selected_team = team
	team_mode = true
	_append_chat("HỆ THỐNG", "Đã đổi sang " + ("Đội Đỏ" if team == "red" else "Đội Xanh") + "!", BoomPalette.TEXT_GOLD)
	_sync_player_status()

func _on_leave_pressed() -> void:
	leave_room_requested.emit()
	if has_node("/root/RoomManager") and not RoomManager.current_room_id.is_empty():
		RoomManager.rpc_id(1, "request_leave_room")
	get_tree().change_scene_to_file("res://scenes/lobby/Lobby.tscn")

func _build_room_slots() -> void:
	room_slots.clear()
	var container = get_node_or_null("LeftPanel/SlotsContainer")
	if container == null: return
	var slot_scene = preload("res://ui/components/BoomRoomSlot.tscn")
	
	var col_w := 106
	var row_h := 154
	for i in range(8):
		var col := i % 4
		var row := i / 4
		var slot: BoomRoomSlot = slot_scene.instantiate()
		slot.slot_index = i
		slot.position = Vector2(col * col_w, row * row_h)
		slot.clicked.connect(_on_slot_clicked)
		container.add_child(slot)
		room_slots.append(slot)

func _build_character_grid() -> void:
	char_slots.clear()
	var container = get_node_or_null("RightPanel/CharGridContainer")
	if container == null: return
	var slot_scene = preload("res://ui/components/BoomSlot.tscn")
	
	var col_w := 71
	var row_h := 41
	for i in range(12):
		var col := i % 4
		var row := i / 4
		var slot: BoomSlot = slot_scene.instantiate()
		slot.slot_index = i
		slot.position = Vector2(col * col_w, row * row_h)
		if i < characters.size():
			# Selection slots show the same in-game idle frame for every character.
			# Using the full 112x112 runtime canvas avoids the old selfie crop that
			# cut hats/hair off for Coral, Lime, Mint, Red, Star and Sunny.
				slot.set_character_icon(CharacterPresentation.idle_texture(characters[i]), characters[i])
		slot.clicked.connect(_on_char_slot_clicked)
		container.add_child(slot)
		char_slots.append(slot)

func _refresh_display() -> void:
	if selected_char_idx < characters.size() and status_box != null:
		var c = characters[selected_char_idx]
		status_box.set_character(c)
	for i in range(char_slots.size()):
		char_slots[i].is_selected = (i == selected_char_idx)
	if map_card != null:
		map_card.set_map(GameSession.selected_map_id)
	_refresh_room_slots()

func _refresh_room_slots() -> void:
	if room_slots.is_empty():
		return
		
	var is_room_host := true
	if has_node("/root/RoomManager") and not RoomManager.current_room_id.is_empty():
		var r_data = RoomManager.active_rooms.get(RoomManager.current_room_id, {})
		is_room_host = r_data.is_empty() or r_data.get("host", 1) == multiplayer.get_unique_id()
		
	# Local slot 0
	var slot0 = room_slots[0]
	slot0.is_empty = false
	slot0.player_name = GameSession.player_nickname
	slot0.is_master = is_room_host
	slot0.status_text = "TRƯỞNG PHÒNG" if is_room_host else ("SẴN SÀNG" if is_ready_state else "CHỜ")
	if selected_char_idx < characters.size():
		slot0.set_character(characters[selected_char_idx].sprite_frames, characters[selected_char_idx])
	# Head rings/accessories were retired from presentation.  Keep the account
	# data intact but never project it into the room card.
	slot0.set_head_accessory(null)
	var flag_def = CosmeticRegistry.get_definition(GameSession.equipped_cosmetics.get("flag", ""))
	if flag_def != null:
		slot0.set_flag(flag_def.lobby_asset)
		
	# Check other multiplayer players if connected
	var remote_players: Array = []
	if has_node("/root/RoomManager") and not RoomManager.current_room_id.is_empty():
		var r_data = RoomManager.active_rooms.get(RoomManager.current_room_id, {})
		var p_list: Array = r_data.get("players", [])
		for pid in p_list:
			if pid != multiplayer.get_unique_id():
				remote_players.append(RoomManager.room_players.get(pid, {}))
				
	for i in range(1, 4):
		if i < room_slots.size():
			var slot = room_slots[i]
			var r_idx = i - 1
			if r_idx < remote_players.size():
				var p_info = remote_players[r_idx]
				slot.is_empty = false
				slot.player_name = str(p_info.get("name", "Người chơi"))
				slot.is_master = false
				var rdy = p_info.get("is_ready", false)
				slot.status_text = "SẴN SÀNG" if rdy else "CHỜ"
			else:
				slot.is_empty = true

	# Row 2 (Slots 4..7) for Bots
	for i in range(4, 8):
		if i < room_slots.size():
			var slot = room_slots[i]
			var bot_idx := i - 4
			if bot_idx < bot_count:
				slot.is_empty = false
				slot.player_name = "Bot %d" % (bot_idx + 1)
				slot.is_master = false
				slot.status_text = "SẴN SÀNG"
				if characters.size() > 0:
					var bot_character: CharacterDefinition = characters[(bot_idx + 1) % characters.size()]
					slot.set_character(bot_character.sprite_frames, bot_character)
			else:
				slot.is_empty = true

func _on_char_slot_clicked(idx: int) -> void:
	if idx < characters.size():
		selected_char_idx = idx
		GameSession.selected_character_id = characters[idx].id
		GameSession.save_profile()
		_sync_player_status()
		_refresh_display()

func _on_slot_clicked(idx: int) -> void:
	if idx >= 4:
		var target := idx - 4 + 1
		bot_count = 0 if bot_count == target else target
		_refresh_room_slots()
		_sync_settings_to_server()

func _on_cycle_color() -> void:
	current_color_idx = (current_color_idx + 1) % 4
	_sync_player_status()

func _on_auto_ready_pressed() -> void:
	is_ready_state = not is_ready_state
	_sync_player_status()
	_refresh_room_slots()

func _on_start_pressed() -> void:
	start_game_requested.emit()
	if not NetworkManager.is_connected_to_server():
		NetworkManager.connect_to_default_server()
		await get_tree().create_timer(0.2).timeout
		
	var is_host := true
	if has_node("/root/RoomManager") and not RoomManager.current_room_id.is_empty():
		var r_data = RoomManager.active_rooms.get(RoomManager.current_room_id, {})
		is_host = r_data.is_empty() or r_data.get("host", 1) == multiplayer.get_unique_id()
		
	if not is_host:
		is_ready_state = not is_ready_state
		_sync_player_status()
		_refresh_room_slots()
		return
		
	if has_node("/root/RoomManager") and not RoomManager.current_room_id.is_empty() and RoomManager.active_rooms.has(RoomManager.current_room_id):
		RoomManager.rpc_id(1, "request_start_match")
	else:
		_do_start_match()

func _do_start_match() -> void:
	var selected_id: StringName = characters[selected_char_idx].id if selected_char_idx < characters.size() else &"boom_mascot"
	if team_mode:
		GameSession.configure_team(1 + bot_count, GameSession.bot_difficulty, GameSession.selected_map_id, selected_id)
	else:
		GameSession.configure_solo(bot_count, GameSession.bot_difficulty, GameSession.selected_map_id, selected_id)
	get_tree().change_scene_to_file("res://scenes/match/MatchArena.tscn")

func _sync_player_status() -> void:
	if has_node("/root/RoomManager"):
		var selected_id = str(characters[selected_char_idx].id) if selected_char_idx < characters.size() else "boom_mascot"
		RoomManager.rpc_id(1, "update_player_status", GameSession.player_nickname, selected_id, current_color_idx, is_ready_state, str(GameSession.selected_balloon_skin), GameSession.equipped_cosmetics)

func _sync_settings_to_server() -> void:
	if has_node("/root/RoomManager"):
		var map_id = str(GameSession.selected_map_id)
		var mode = "team" if team_mode else "solo"
		RoomManager.rpc_id(1, "request_update_settings", map_id, mode, bot_count, GameSession.bot_difficulty)

func _on_room_settings_updated(settings: Dictionary) -> void:
	var map_id = settings.get("map", "")
	if map_id != "":
		GameSession.selected_map_id = StringName(map_id)
		if map_card != null:
			map_card.set_map(GameSession.selected_map_id)
	bot_count = settings.get("bots", bot_count)
	_refresh_room_slots()

func _on_chat_submit() -> void:
	if chat_input == null: return
	var msg = chat_input.text.strip_edges()
	if msg.is_empty(): return
	chat_input.text = ""
	_append_chat(GameSession.player_nickname, msg, BoomPalette.TEXT_GREEN_READY)
	if has_node("/root/RoomManager"):
		RoomManager.rpc_id(1, "send_chat_message", msg)

func _on_chat_received(sender, msg, is_sys) -> void:
	var is_mine = (str(sender) == GameSession.player_nickname or str(sender) == "Tôi")
	var col = BoomPalette.TEXT_GOLD if is_sys else (BoomPalette.TEXT_GREEN_READY if is_mine else BoomPalette.TEXT_CYAN_LIGHT)
	_append_chat(str(sender), str(msg), col)

func _append_chat(sender: String, message: String, color: Color) -> void:
	if chat_log == null: return
	var hex = color.to_html(false)
	chat_log.append_text("[color=#%s][b]%s:[/b] %s[/color]\n" % [hex, sender, message])

func _open_map_picker() -> void:
	if map_select_popup == null:
		map_select_popup = MAP_SELECT_POPUP_SCRIPT.new()
		add_child(map_select_popup)
		map_select_popup.map_selected.connect(func(map_id):
			GameSession.selected_map_id = map_id
			if map_card != null:
				map_card.set_map(map_id)
			_sync_settings_to_server()
		)
	map_select_popup.open(GameSession.selected_map_id)

func _open_shop() -> void:
	if shop_view == null:
		shop_view = SHOP_VIEW_SCRIPT.new()
		add_child(shop_view)
		shop_view.closed.connect(func(): shop_view.visible = false)
	shop_view.visible = true
	shop_view.open()

func _open_inventory() -> void:
	if inventory_view == null:
		inventory_view = INVENTORY_VIEW_SCRIPT.new()
		add_child(inventory_view)
		inventory_view.closed.connect(func(): inventory_view.visible = false)
	inventory_view.visible = true
	inventory_view.open()

func _open_settings() -> void:
	if settings_panel == null:
		_build_settings_panel()
	settings_panel.visible = true

func _build_settings_panel() -> void:
	settings_panel = Panel.new()
	settings_panel.name = "SettingsPanel"
	settings_panel.position = Vector2(150, 50)
	settings_panel.size = Vector2(500, 500)
	settings_panel.add_theme_stylebox_override("panel", UITheme.panel_modal())
	add_child(settings_panel)
	
	var title = Label.new()
	title.text = "CÀI ĐẶT HỆ THỐNG"
	title.position = Vector2(0, 16)
	title.size = Vector2(500, 32)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color("#ffe45e"))
	settings_panel.add_child(title)
	
	var close_btn = Button.new()
	close_btn.text = "XÁC NHẬN"
	close_btn.position = Vector2(175, 430)
	close_btn.size = Vector2(150, 44)
	UITheme.apply_button_theme(close_btn, "primary")
	close_btn.pressed.connect(func(): settings_panel.visible = false)
	settings_panel.add_child(close_btn)
