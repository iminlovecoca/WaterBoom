class_name MatchHUD
extends Control

const VICTORY_TITLE: Texture2D = preload("res://assets/ui/results/victory_vi.png")
const DEFEAT_TITLE: Texture2D = preload("res://assets/ui/results/defeat_vi.png")
const BUBBLE_PIN_ICON: Texture2D = preload("res://assets/items/item_bubble_pin.png")
const SHIELD_ICON: Texture2D = preload("res://assets/items/item_shield.png")
const COKECY_ICON: Texture2D = preload("res://assets/ui/coke_coin.png")
const RESULT_FONT: Font = preload("res://assets/fonts/ChakraPetch-SemiBold.ttf")

const ROUNDED_CLIP_SHADER := preload("res://assets/shaders/rounded_clip.gdshader")

var MEDAL_WINNER: Texture2D
var MEDAL_SILVER: Texture2D
var ICON_SAC_NUOC: Texture2D

@onready var banner_label: Label = $CenterBanner/BannerLabel
@onready var p1_stats_label: Label = $BottomBar/P1Stats
@onready var p2_stats_label: Label = $BottomBar/P2Stats
@onready var result_panel: Panel = $ResultModal
@onready var result_title: TextureRect = $ResultModal/ResultTitle
@onready var result_names: Label = $ResultModal/ResultTable/NameColumn
@onready var result_outcomes: RichTextLabel = $ResultModal/ResultTable/ResultColumn
@onready var result_money: Label = $ResultModal/ResultTable/MoneyColumn
@onready var reward_label: Label = $ResultModal/ResultTable/Reward
@onready var balance_label: Label = $ResultModal/ResultTable/Balance
@onready var restart_btn: Button = $ResultModal/VBox/RestartButton
@onready var menu_btn: Button = $ResultModal/VBox/MenuButton

var match_manager = null
var reward_granted := false
var boss_signals_connected := false
var result_rows: VBoxContainer
var result_exp_bar: ProgressBar
var result_level_label: Label
var result_exp_label: Label
var result_balance_label: Label
var result_return_label: Label
var auto_return_generation := 0

# CLASSIC BOOM ONLINE SIDEBAR
var sidebar_panel: Panel
var sidebar_timer_label: Label
var sidebar_boom_label: Label
var player_slot_panels: Array[Panel] = []
var player_slot_avatars: Array[TextureRect] = []
var player_slot_names: Array[Label] = []
var player_slot_badges: Array[Label] = []
var player_slot_empty_panels: Array[Panel] = []
var player_slot_flags: Array[TextureRect] = []
var player_slot_backgrounds: Array[TextureRect] = []
var player_slot_frames: Array[TextureRect] = []
var player_slot_heads: Array[TextureRect] = []
var item_slot_icon: TextureRect
var item_panel: Panel
var btn_sidebar_exit: Button

func _ready() -> void:
	if ResourceLoader.exists("res://assets/ui/results/medal_winner.png"):
		MEDAL_WINNER = load("res://assets/ui/results/medal_winner.png")
	if ResourceLoader.exists("res://assets/ui/results/medal_silver.png"):
		MEDAL_SILVER = load("res://assets/ui/results/medal_silver.png")
	if ResourceLoader.exists("res://assets/ui/results/icon_sac_nuoc.png"):
		ICON_SAC_NUOC = load("res://assets/ui/results/icon_sac_nuoc.png")

	if has_node("TopBar"):
		$TopBar.visible = false
	if has_node("BottomBar"):
		$BottomBar.visible = false
	if has_node("PauseModal"):
		$PauseModal.visible = false
		
	result_panel.visible = false
	banner_label.text = ""
	_build_result_board()
	
	if not restart_btn.pressed.is_connected(_on_restart_pressed):
		restart_btn.pressed.connect(_on_restart_pressed)
	if not menu_btn.pressed.is_connected(_on_menu_pressed):
		menu_btn.pressed.connect(_on_menu_pressed)
	
	if not EventBus.match_state_changed.is_connected(_on_match_state_changed):
		EventBus.match_state_changed.connect(_on_match_state_changed)
	if not EventBus.match_countdown_tick.is_connected(_on_countdown_tick):
		EventBus.match_countdown_tick.connect(_on_countdown_tick)
	if not EventBus.match_started.is_connected(_on_match_started):
		EventBus.match_started.connect(_on_match_started)
	if not EventBus.match_ended.is_connected(_on_match_ended):
		EventBus.match_ended.connect(_on_match_ended)
	
	if match_manager == null:
		match_manager = get_parent()
	_apply_result_style()
	_build_classic_sidebar()
	_resize_to_viewport()
	if not get_viewport().size_changed.is_connected(_resize_to_viewport):
		get_viewport().size_changed.connect(_resize_to_viewport)

func _build_classic_sidebar() -> void:
	sidebar_panel = Panel.new()
	sidebar_panel.name = "ClassicSidebar"
	sidebar_panel.mouse_filter = Control.MOUSE_FILTER_PASS
	var side_s := StyleBoxFlat.new()
	side_s.bg_color = Color("#082c58")
	side_s.border_color = Color("#19609e")
	side_s.set_border_width_all(3)
	side_s.border_width_bottom = 5
	side_s.set_corner_radius_all(10)
	side_s.shadow_color = Color(0, 0, 0, 0.45)
	side_s.shadow_size = 6
	sidebar_panel.add_theme_stylebox_override("panel", side_s)
	add_child(sidebar_panel)
	
	# -------------------------------------------------------------
	# 1. HEADER TIMER BOX (BOOM COUNTER + TIMER)
	# -------------------------------------------------------------
	var timer_box := Panel.new()
	timer_box.position = Vector2(8, 8)
	timer_box.size = Vector2(188, 34)
	var tb_s := StyleBoxFlat.new()
	tb_s.bg_color = Color("#031836")
	tb_s.border_color = Color("#12467b")
	tb_s.set_border_width_all(2)
	tb_s.border_width_bottom = 4
	tb_s.set_corner_radius_all(6)
	timer_box.add_theme_stylebox_override("panel", tb_s)
	sidebar_panel.add_child(timer_box)
	
	var boom_ico := TextureRect.new()
	boom_ico.position = Vector2(6, 7)
	boom_ico.size = Vector2(20, 20)
	boom_ico.texture = preload("res://assets/water_balloons/skins/skin_066/idle_0.png")
	boom_ico.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	boom_ico.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	boom_ico.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	timer_box.add_child(boom_ico)
	
	sidebar_boom_label = Label.new()
	sidebar_boom_label.position = Vector2(28, 0)
	sidebar_boom_label.size = Vector2(68, 34)
	sidebar_boom_label.text = "BOOM ×1"
	sidebar_boom_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	sidebar_boom_label.add_theme_font_size_override("font_size", 11)
	sidebar_boom_label.add_theme_color_override("font_color", Color("#c2e4ff"))
	sidebar_boom_label.add_theme_color_override("font_outline_color", Color("#040d16"))
	sidebar_boom_label.add_theme_constant_override("outline_size", 3)
	timer_box.add_child(sidebar_boom_label)
	
	sidebar_timer_label = Label.new()
	sidebar_timer_label.position = Vector2(96, 0)
	sidebar_timer_label.size = Vector2(84, 34)
	sidebar_timer_label.text = "03:00"
	sidebar_timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	sidebar_timer_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	sidebar_timer_label.add_theme_font_size_override("font_size", 18)
	sidebar_timer_label.add_theme_color_override("font_color", Color("#ffd45d"))
	sidebar_timer_label.add_theme_color_override("font_outline_color", Color("#5c2d00"))
	sidebar_timer_label.add_theme_constant_override("outline_size", 4)
	timer_box.add_child(sidebar_timer_label)
	
	# -------------------------------------------------------------
	# 2. PLAYER SLOTS CONTAINER (8 SLOTS)
	# -------------------------------------------------------------
	var slots_box := VBoxContainer.new()
	slots_box.name = "SlotsContainer"
	slots_box.position = Vector2(8, 48)
	slots_box.size = Vector2(188, 510)
	slots_box.add_theme_constant_override("separation", 5)
	sidebar_panel.add_child(slots_box)
	
	player_slot_panels.clear()
	player_slot_avatars.clear()
	player_slot_names.clear()
	player_slot_badges.clear()
	player_slot_empty_panels.clear()
	player_slot_flags.clear()
	player_slot_backgrounds.clear()
	player_slot_frames.clear()
	player_slot_heads.clear()
	
	for slot_idx in range(8):
		var slot_p := Panel.new()
		slot_p.custom_minimum_size = Vector2(188, 58)
		slot_p.clip_contents = true
		var slot_s := StyleBoxFlat.new()
		slot_s.bg_color = Color("#031836")
		slot_s.border_color = Color("#12467b")
		slot_s.set_border_width_all(1)
		slot_s.border_width_bottom = 2
		slot_s.set_corner_radius_all(5)
		slot_p.add_theme_stylebox_override("panel", slot_s)
		slots_box.add_child(slot_p)
		player_slot_panels.append(slot_p)

		var background_view := TextureRect.new()
		background_view.position = Vector2.ZERO
		background_view.size = Vector2(188, 58)
		background_view.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		background_view.stretch_mode = TextureRect.STRETCH_SCALE
		background_view.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		background_view.material = _rounded_clip_material(Vector2(188, 58), 5.0)
		background_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot_p.add_child(background_view)
		player_slot_backgrounds.append(background_view)
		
		# Avatar square container with clip_contents to show ONLY the big chibi head!
		var av_panel := Panel.new()
		av_panel.position = Vector2(4, 5)
		av_panel.size = Vector2(48, 48)
		av_panel.clip_contents = true
		var av_s := StyleBoxFlat.new()
		av_s.bg_color = Color("#050c15")
		av_s.border_color = Color("#142230")
		av_s.set_border_width_all(1)
		av_s.set_corner_radius_all(4)
		av_panel.add_theme_stylebox_override("panel", av_s)
		slot_p.add_child(av_panel)
		
		var av_tex := TextureRect.new()
		av_tex.set_anchors_preset(PRESET_FULL_RECT)
		av_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		av_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		av_tex.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		av_panel.add_child(av_tex)
		player_slot_avatars.append(av_tex)

		var head_view := TextureRect.new()
		head_view.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		head_view.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		head_view.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		head_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot_p.add_child(head_view)
		player_slot_heads.append(head_view)
		
		# Player Name
		var name_lbl := Label.new()
		name_lbl.position = Vector2(58, 6)
		name_lbl.size = Vector2(122, 22)
		name_lbl.text = "Player %d" % (slot_idx + 1)
		name_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		name_lbl.add_theme_font_size_override("font_size", 11)
		name_lbl.add_theme_color_override("font_color", Color.WHITE)
		name_lbl.add_theme_color_override("font_outline_color", Color("#040d16"))
		name_lbl.add_theme_constant_override("outline_size", 3)
		name_lbl.clip_text = true
		name_lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		slot_p.add_child(name_lbl)
		player_slot_names.append(name_lbl)

		# Badge Tag
		var badge_lbl := Label.new()
		badge_lbl.position = Vector2(58, 30)
		badge_lbl.size = Vector2(80, 20)
		badge_lbl.text = "SỐNG"
		badge_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		badge_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		badge_lbl.add_theme_font_size_override("font_size", 10)
		badge_lbl.add_theme_color_override("font_color", Color("#42e0a2"))
		badge_lbl.add_theme_color_override("font_outline_color", Color("#040d16"))
		badge_lbl.add_theme_constant_override("outline_size", 2)
		slot_p.add_child(badge_lbl)
		player_slot_badges.append(badge_lbl)

		var flag_view := TextureRect.new()
		flag_view.position = Vector2(160, 34)
		flag_view.size = Vector2(22, 17)
		flag_view.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		flag_view.stretch_mode = TextureRect.STRETCH_SCALE
		flag_view.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		flag_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot_p.add_child(flag_view)
		player_slot_flags.append(flag_view)

		var frame_view := TextureRect.new()
		frame_view.position = Vector2(3, 3)
		frame_view.size = Vector2(182, 52)
		frame_view.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		frame_view.stretch_mode = TextureRect.STRETCH_SCALE
		frame_view.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		frame_view.material = _rounded_clip_material(Vector2(182, 52), 5.0)
		frame_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot_p.add_child(frame_view)
		# Keep the frame directly above the background and below avatar/text.
		# It remains visible at the outer edge without covering the character.
		slot_p.move_child(frame_view, 1)
		player_slot_frames.append(frame_view)
		
		# Empty placeholder overlay
		var empty_panel := Panel.new()
		empty_panel.set_anchors_preset(PRESET_FULL_RECT)
		var emp_s := StyleBoxFlat.new()
		emp_s.bg_color = Color("#050c15")
		emp_s.border_color = Color("#142230")
		emp_s.set_border_width_all(1)
		emp_s.set_corner_radius_all(5)
		empty_panel.add_theme_stylebox_override("panel", emp_s)
		
		var emp_av := Panel.new()
		emp_av.position = Vector2(4, 5)
		emp_av.size = Vector2(48, 48)
		var emp_av_s := StyleBoxFlat.new()
		emp_av_s.bg_color = Color("#03080e")
		emp_av_s.border_color = Color("#101c28")
		emp_av_s.set_border_width_all(1)
		emp_av_s.set_corner_radius_all(4)
		emp_av.add_theme_stylebox_override("panel", emp_av_s)
		empty_panel.add_child(emp_av)
		
		var emp_bar := Panel.new()
		emp_bar.position = Vector2(58, 16)
		emp_bar.size = Vector2(122, 26)
		var emp_bar_s := StyleBoxFlat.new()
		emp_bar_s.bg_color = Color("#03080e")
		emp_bar_s.border_color = Color("#101c28")
		emp_bar_s.set_border_width_all(1)
		emp_bar_s.set_corner_radius_all(4)
		emp_bar.add_theme_stylebox_override("panel", emp_bar_s)
		empty_panel.add_child(emp_bar)
		
		empty_panel.visible = true
		slot_p.add_child(empty_panel)
		player_slot_empty_panels.append(empty_panel)
		
	# -------------------------------------------------------------
	# 3. MATCH ITEM SECTION ("VẬT PHẨM") - PINNED NEAR BOTTOM
	# -------------------------------------------------------------
	item_panel = Panel.new()
	item_panel.name = "ItemPanel"
	item_panel.position = Vector2(8, 566)
	item_panel.size = Vector2(188, 80)
	var ip_s := StyleBoxFlat.new()
	ip_s.bg_color = Color("#041a38")
	ip_s.border_color = Color("#1c2e42")
	ip_s.set_border_width_all(2)
	ip_s.border_width_bottom = 4
	ip_s.set_corner_radius_all(6)
	item_panel.add_theme_stylebox_override("panel", ip_s)
	sidebar_panel.add_child(item_panel)
	
	var item_title := Label.new()
	item_title.position = Vector2(8, 4)
	item_title.size = Vector2(172, 18)
	item_title.text = "VẬT PHẨM"
	item_title.add_theme_font_size_override("font_size", 11)
	item_title.add_theme_color_override("font_color", Color("#c2e4ff"))
	item_title.add_theme_color_override("font_outline_color", Color("#040d16"))
	item_title.add_theme_constant_override("outline_size", 3)
	item_panel.add_child(item_title)
	
	var item_slot := Panel.new()
	item_slot.position = Vector2(66, 22)
	item_slot.size = Vector2(54, 52)
	var is_s := StyleBoxFlat.new()
	is_s.bg_color = Color("#050c15")
	is_s.border_color = Color("#182636")
	is_s.set_border_width_all(2)
	is_s.border_width_bottom = 3
	is_s.set_corner_radius_all(5)
	item_slot.add_theme_stylebox_override("panel", is_s)
	item_panel.add_child(item_slot)
	
	var ctrl_tag := Label.new()
	ctrl_tag.position = Vector2(3, 2)
	ctrl_tag.size = Vector2(28, 14)
	ctrl_tag.text = "Ctrl"
	ctrl_tag.add_theme_font_size_override("font_size", 9)
	ctrl_tag.add_theme_color_override("font_color", Color("#8ecfff"))
	item_slot.add_child(ctrl_tag)
	
	item_slot_icon = TextureRect.new()
	item_slot_icon.position = Vector2(8, 8)
	item_slot_icon.size = Vector2(38, 38)
	item_slot_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	item_slot_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	item_slot_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	item_slot.add_child(item_slot_icon)
	
	# -------------------------------------------------------------
	# 4. EXIT BUTTON ("THOÁT RA") - PINNED AT VERY BOTTOM
	# -------------------------------------------------------------
	btn_sidebar_exit = Button.new()
	btn_sidebar_exit.name = "ExitButton"
	btn_sidebar_exit.position = Vector2(8, 652)
	btn_sidebar_exit.size = Vector2(188, 40)
	btn_sidebar_exit.text = "THOÁT RA"
	btn_sidebar_exit.add_theme_font_size_override("font_size", 14)
	UITheme.apply_button_theme(btn_sidebar_exit, "primary")
	btn_sidebar_exit.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn_sidebar_exit.pressed.connect(_on_menu_pressed)
	sidebar_panel.add_child(btn_sidebar_exit)

func _rounded_clip_material(rect_size: Vector2, radius: float) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = ROUNDED_CLIP_SHADER
	material.set_shader_parameter("rect_size", rect_size)
	material.set_shader_parameter("radius_px", radius)
	return material

func _resize_to_viewport() -> void:
	position = Vector2.ZERO
	size = get_viewport_rect().size
	_layout_arcade_hud()

func _layout_arcade_hud() -> void:
	var viewport_size := get_viewport_rect().size
	var sidebar := MatchFrameUI.sidebar_rect_for_size(viewport_size)
	var board_size := Vector2(600.0, 520.0)
	if match_manager != null and "map_definition" in match_manager and match_manager.map_definition != null:
		board_size = Vector2(match_manager.map_definition.width, match_manager.map_definition.height) * match_manager.map_definition.tile_size
	var board_origin := MatchFrameUI.board_origin_for(viewport_size, board_size)
	var board_rect := Rect2(board_origin, board_size)
	
	if sidebar_panel != null:
		_place_control(sidebar_panel, sidebar)
		# Ensure Item Box and Exit Button are always attached to the bottom
		if btn_sidebar_exit != null:
			btn_sidebar_exit.position = Vector2(8, sidebar.size.y - 48)
		if item_panel != null:
			item_panel.position = Vector2(8, sidebar.size.y - 48 - 80 - 6)
		
	_place_control($CenterBanner, Rect2(board_rect.position + board_rect.size * 0.5 - Vector2(200.0, 60.0), Vector2(400.0, 120.0)))
	var result_size := Vector2(minf(520.0, board_rect.size.x - 20.0), minf(340.0, board_rect.size.y - 20.0))
	_place_control($ResultModal, Rect2(board_rect.position + (board_rect.size - result_size) * 0.5, result_size))
	_place_control($BossHUD, Rect2(board_rect.position.x + 150.0, 7.0, board_rect.size.x - 210.0, 38.0))

func _place_control(control: Control, rect: Rect2) -> void:
	control.anchor_left = 0.0
	control.anchor_top = 0.0
	control.anchor_right = 0.0
	control.anchor_bottom = 0.0
	control.position = rect.position
	control.size = rect.size

var _last_timer_sec: int = -1

func _process(_delta: float) -> void:
	_connect_boss_hud()
	if match_manager != null and "current_state" in match_manager and match_manager.current_state == GameConstants.MatchState.PLAYING:
		var total_sec = int(match_manager.time_left_seconds)
		if total_sec != _last_timer_sec:
			_last_timer_sec = total_sec
			var m = total_sec / 60
			var s = total_sec % 60
			if sidebar_timer_label != null:
				sidebar_timer_label.text = "%02d:%02d" % [m, s]
	if sidebar_boom_label != null and match_manager != null and match_manager.has_method("get_local_player"):
		var local_p = match_manager.get_local_player()
		if local_p != null and "max_water_balloons" in local_p:
			sidebar_boom_label.text = "BOOM ×%d" % local_p.max_water_balloons
	_update_sidebar_players()

func _update_sidebar_players() -> void:
	if match_manager == null: return
	var ids: Array = match_manager.players.keys()
	ids.sort()
	
	for slot_idx in range(8):
		if slot_idx < ids.size():
			var p: PlayerController = match_manager.players[ids[slot_idx]]
			player_slot_empty_panels[slot_idx].visible = false
			player_slot_names[slot_idx].text = p.display_name
			var equipment := CosmeticRegistry.sanitize_equipment(p.equipment_snapshot)
			var flag := CosmeticRegistry.get_definition(equipment.get("flag", "flag_default_water"))
			player_slot_flags[slot_idx].texture = flag.match_list_asset if flag != null else null
			player_slot_flags[slot_idx].visible = player_slot_flags[slot_idx].texture != null
			var background := CosmeticRegistry.get_definition(equipment.get("player_background", "background_default_aqua"))
			player_slot_backgrounds[slot_idx].texture = background.match_list_asset if background != null else null
			player_slot_frames[slot_idx].texture = null
			var head := CosmeticRegistry.get_definition(equipment.get("head_accessory", ""))
			player_slot_heads[slot_idx].texture = AccessoryPresentation.texture_for(head, AccessoryPresentation.CONTEXT_MATCH_LIST)
			player_slot_backgrounds[slot_idx].visible = player_slot_backgrounds[slot_idx].texture != null
			player_slot_frames[slot_idx].visible = false
			player_slot_heads[slot_idx].visible = player_slot_heads[slot_idx].texture != null
			if head != null:
				var head_rect := AccessoryPresentation.control_rect(head, AccessoryPresentation.CONTEXT_MATCH_LIST)
				player_slot_heads[slot_idx].position = head_rect.position
				player_slot_heads[slot_idx].size = head_rect.size
			
			var is_local: bool = (match_manager != null and match_manager.get_local_player() == p)
			player_slot_badges[slot_idx].text = "🔥 96" if is_local else "🎖️ %d" % (slot_idx + 1)
			# Keep the full 112×112 portrait canvas centered on every active slot.
			# Bunny art is narrower than the shared bear baseline, so only its
			# horizontal footprint is corrected; the vertical feet anchor is shared.
			player_slot_avatars[slot_idx].pivot_offset = player_slot_avatars[slot_idx].size * 0.5
			player_slot_avatars[slot_idx].scale = CharacterPresentation.content_scale_vector(p.character_def)
			
			# Use the complete 112x112 idle frame as the avatar source. The old
			# hard-coded head crop assumed one silhouette and clipped the six newer
			# characters (helmets, bows, hats and hair sit at different heights).
			# TextureRect keeps the whole canvas centered inside the 48x48 panel.
			if p.visual != null and p.visual.sprite != null and p.visual.sprite.sprite_frames != null:
				var frames: SpriteFrames = p.visual.sprite.sprite_frames
				if frames.has_animation(&"idle_down") and frames.get_frame_count(&"idle_down") > 0:
					var count := frames.get_frame_count(&"idle_down")
					var frame_idx := int(Time.get_ticks_msec() / 200.0) % count
					var base_tex: Texture2D = frames.get_frame_texture(&"idle_down", frame_idx)
					if base_tex != null:
						player_slot_avatars[slot_idx].texture = CharacterPresentation.full_frame_atlas(base_tex)
					
			var slot_s: StyleBoxFlat = player_slot_panels[slot_idx].get_theme_stylebox("panel").duplicate()
			if not p.is_alive:
				slot_s.bg_color = Color("#1a2634")
				slot_s.border_color = Color("#364a5c")
				player_slot_names[slot_idx].modulate = Color("#7f93a8")
				player_slot_avatars[slot_idx].modulate = Color(0.4, 0.4, 0.4, 0.7)
			elif p.is_in_bubble:
				slot_s.bg_color = Color("#084c76")
				slot_s.border_color = Color("#1c9cd8")
				player_slot_names[slot_idx].modulate = Color("#8ee6ff")
				player_slot_avatars[slot_idx].modulate = Color(0.7, 0.9, 1.0, 1.0)
			else:
				if is_local:
					slot_s.bg_color = Color("#a8440c")
					slot_s.border_color = Color("#f59e0b")
				else:
					slot_s.bg_color = Color("#084474")
					slot_s.border_color = Color("#1e8cc4")
				player_slot_names[slot_idx].modulate = Color.WHITE
				player_slot_avatars[slot_idx].modulate = Color.WHITE
			player_slot_panels[slot_idx].add_theme_stylebox_override("panel", slot_s)
		else:
			player_slot_empty_panels[slot_idx].visible = true
			player_slot_avatars[slot_idx].texture = null
			player_slot_avatars[slot_idx].scale = Vector2.ONE
			player_slot_flags[slot_idx].visible = false
			player_slot_backgrounds[slot_idx].visible = false
			player_slot_frames[slot_idx].visible = false
			player_slot_heads[slot_idx].visible = false
			
	var local_player = match_manager.get_local_player() if match_manager != null else null
	if local_player != null and item_slot_icon != null:
		var held_item = local_player.active_items[0] if local_player.active_items.size() > 0 else GameConstants.ItemType.NONE
		if held_item == GameConstants.ItemType.BUBBLE_PIN:
			item_slot_icon.texture = BUBBLE_PIN_ICON
			item_slot_icon.visible = true
		elif held_item == GameConstants.ItemType.SHIELD:
			item_slot_icon.texture = SHIELD_ICON
			item_slot_icon.visible = true
		else:
			item_slot_icon.texture = null
			item_slot_icon.visible = false

func _on_countdown_tick(sec: int) -> void:
	if sec > 0:
		var sec_str = str(sec)
		if banner_label.text != sec_str:
			banner_label.text = sec_str
			banner_label.visible = true
			SoundManager.play_sfx("match_countdown_%s" % sec_str)

func _on_match_started() -> void:
	reward_granted = false
	banner_label.text = "START!"
	var tween = create_tween()
	tween.tween_property(banner_label, "modulate:a", 0.0, 1.0)
	tween.tween_callback(func(): banner_label.visible = false; banner_label.modulate.a = 1.0)

func _on_match_state_changed(_old: int, new_state: int) -> void:
	if new_state == GameConstants.MatchState.RESULT:
		result_panel.visible = true
		_schedule_auto_return()
	elif new_state == GameConstants.MatchState.COUNTDOWN:
		auto_return_generation += 1
		result_panel.visible = false

func _on_match_ended(winner_id: int, is_draw: bool) -> void:
	var local_player = match_manager.get_local_player() if match_manager != null else null
	var local_won := false
	if not is_draw and local_player != null and match_manager != null and match_manager.players.has(winner_id):
		var winner = match_manager.players[winner_id]
		local_won = (local_player.player_id == winner_id) or (local_player.team_id != 0 and local_player.team_id == winner.team_id)
	var reward := 120 if local_won else (20 if is_draw else 0)
	var exp_reward := 100 if local_won else (50 if is_draw else 25)
	var progress: Dictionary = {
		"gained": exp_reward,
		"old_level": GameSession.level,
		"old_experience": GameSession.experience,
		"old_required": GameSession.experience_required_for_level(),
		"new_level": GameSession.level,
		"new_experience": GameSession.experience,
		"new_required": GameSession.experience_required_for_level(),
		"percent": GameSession.experience_percent(),
		"leveled_up": false,
	}
	if not reward_granted:
		GameSession.add_cokecy(reward)
		progress = GameSession.add_experience(exp_reward)
		reward_granted = true
	_populate_result_rows(winner_id, is_draw)
	_update_result_progress(progress)
	if result_balance_label != null:
		result_balance_label.text = _format_digital(GameSession.cokecy)

var result_banner_rect: TextureRect
var result_backdrop_rect: ColorRect
var result_table_box: Control

static var _digital_font: FontFile = null
static var _digital_alpha_font: FontFile = null

static func get_digital_font() -> FontFile:
	if _digital_font == null:
		_digital_font = FontFile.new()
		_digital_font.load_dynamic_font("res://assets/fonts/DSEG7Classic-Bold.ttf")
	return _digital_font

static func get_digital_alpha_font() -> FontFile:
	if _digital_alpha_font == null:
		_digital_alpha_font = FontFile.new()
		_digital_alpha_font.load_dynamic_font("res://assets/fonts/DSEG14Classic-Bold.ttf")
	return _digital_alpha_font

func _get_ui_tex(res_path: String) -> Texture2D:
	var global_path := ProjectSettings.globalize_path(res_path)
	if FileAccess.file_exists(global_path):
		var img := Image.load_from_file(global_path)
		if img != null:
			return ImageTexture.create_from_image(img)
	if ResourceLoader.exists(res_path):
		var res = load(res_path)
		if res is Texture2D:
			return res
	return null

func _build_result_board() -> void:
	# Hide legacy child controls
	result_title.visible = false
	if has_node("ResultModal/ResultTable"):
		$ResultModal/ResultTable.visible = false
	if has_node("ResultModal/VBox"):
		$ResultModal/VBox.visible = false

	# 1. TOP RESULT BANNER ("THẮNG !!" / "THUA CUỘC")
	result_banner_rect = TextureRect.new()
	result_banner_rect.name = "ResultBannerImage"
	result_banner_rect.texture = VICTORY_TITLE
	result_banner_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	result_banner_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	result_banner_rect.position = Vector2(72, 0)
	result_banner_rect.size = Vector2(320, 80)
	result_banner_rect.z_index = 5
	result_panel.add_child(result_banner_rect)

	# 2. SOFT DARK TRANSLUCENT BACKDROP (1:1 with reference - NO borders!)
	result_backdrop_rect = ColorRect.new()
	result_backdrop_rect.name = "ResultBackdrop"
	result_backdrop_rect.color = Color(0.04, 0.08, 0.12, 0.55) # Soft clean dark glass
	result_backdrop_rect.position = Vector2(0, 82)
	result_backdrop_rect.size = Vector2(464, 250)
	result_panel.add_child(result_backdrop_rect)

	# 3. TABLE HEADER BAR (NHÂN VẬT | WP | EXP | VÀNG)
	var header_bar := TextureRect.new()
	header_bar.name = "TableHeaderBar"
	header_bar.texture = _get_ui_tex("res://assets/ui/results/table_header_exact.png")
	header_bar.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	header_bar.stretch_mode = TextureRect.STRETCH_SCALE
	header_bar.position = Vector2(0, 84)
	header_bar.size = Vector2(464, 22)
	result_panel.add_child(header_bar)

	var h_hbox := HBoxContainer.new()
	h_hbox.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	h_hbox.offset_left = 2
	h_hbox.offset_right = -2
	h_hbox.add_theme_constant_override("separation", 2)
	header_bar.add_child(h_hbox)

	# Rank tag spacer (64px + 4px = 68px)
	var h_spacer := Control.new()
	h_spacer.custom_minimum_size = Vector2(66, 20)
	h_hbox.add_child(h_spacer)

	# NHÂN VẬT Column (154px)
	var h_name := _result_label("NHÂN VẬT", 11, Color.WHITE)
	h_name.custom_minimum_size = Vector2(152, 20)
	h_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	h_hbox.add_child(h_name)

	# WP Column (44px)
	var h_wp := _result_label("WP", 11, Color("#ffd700"))
	h_wp.custom_minimum_size = Vector2(42, 20)
	h_wp.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	h_hbox.add_child(h_wp)

	# EXP Column (98px)
	var h_exp := _result_label("EXP", 11, Color.WHITE)
	h_exp.custom_minimum_size = Vector2(96, 20)
	h_exp.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	h_hbox.add_child(h_exp)

	# VÀNG Column (90px)
	var h_gold := _result_label("VÀNG", 11, Color.WHITE)
	h_gold.custom_minimum_size = Vector2(90, 20)
	h_gold.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	h_hbox.add_child(h_gold)

	# 4. RESULT ROWS CONTAINER
	result_rows = VBoxContainer.new()
	result_rows.name = "ResultRows"
	result_rows.position = Vector2(0, 110)
	result_rows.size = Vector2(464, 180)
	result_rows.add_theme_constant_override("separation", 4)
	result_panel.add_child(result_rows)

	# 5. BOTTOM AUTO-RETURN COUNTDOWN LABEL
	result_return_label = _result_label("TỰ ĐỘNG VỀ PHÒNG SAU 5 GIÂY...", 11, Color("#9bdfff"))
	result_return_label.position = Vector2(0, 296)
	result_return_label.size = Vector2(464, 20)
	result_return_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_panel.add_child(result_return_label)

func _result_label(text_value: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text_value
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_override("font", RESULT_FONT)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color("#04101d"))
	label.add_theme_constant_override("outline_size", 2)
	return label

func _result_digital_label(text_value: String, font_size: int, color: Color, use_alpha: bool = false) -> Label:
	var label := Label.new()
	label.text = text_value
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var f := get_digital_alpha_font() if use_alpha else get_digital_font()
	label.add_theme_font_override("font", f)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color("#04101d"))
	label.add_theme_constant_override("outline_size", 2)
	return label

func _populate_result_rows(winner_id: int, is_draw: bool) -> void:
	for child in result_rows.get_children():
		child.queue_free()
	if match_manager == null:
		return
	
	var local_player = match_manager.get_local_player()
	var local_won := false
	if not is_draw and local_player != null and match_manager.players.has(winner_id):
		var winner_p = match_manager.players[winner_id]
		local_won = (local_player.player_id == winner_id) or (local_player.team_id != 0 and local_player.team_id == winner_p.team_id)
	
	# Update Title Banner
	if is_draw:
		result_banner_rect.texture = VICTORY_TITLE
	elif local_won:
		result_banner_rect.texture = VICTORY_TITLE
	else:
		result_banner_rect.texture = DEFEAT_TITLE

	var ids: Array = match_manager.players.keys()
	ids.sort_custom(func(a, b):
		var a_wins := _player_won_result(int(a), winner_id, is_draw)
		var b_wins := _player_won_result(int(b), winner_id, is_draw)
		return a_wins and not b_wins if a_wins != b_wins else int(a) < int(b)
	)

	var num_players: int = max(ids.size(), 2)
	var rows_height: int = num_players * 20 + (num_players - 1) * 4
	result_rows.size = Vector2(464, rows_height)
	var total_board_height: int = 28 + rows_height + 26 + 6
	result_backdrop_rect.size = Vector2(464, total_board_height)
	result_return_label.position = Vector2(0, 110 + rows_height + 6)

	var winner_count := 0
	for row_index in range(ids.size()):
		var player_id: int = int(ids[row_index])
		var player = match_manager.players[player_id]
		var won := _player_won_result(player_id, winner_id, is_draw)
		if won:
			winner_count += 1
		var is_sac_nuoc := not won and not is_draw
		var slot_num := row_index + 1
		
		# Single Row Container
		var row_box := HBoxContainer.new()
		row_box.custom_minimum_size = Vector2(464, 20)
		row_box.add_theme_constant_override("separation", 2)
		result_rows.add_child(row_box)

		# -------------------------------------------------------------
		# A. LEFT COMPACT RANK BADGE ([1] THẮNG / [2] THUA)
		# -------------------------------------------------------------
		var badge_rect := TextureRect.new()
		badge_rect.custom_minimum_size = Vector2(64, 18)
		badge_rect.size_flags_vertical = SIZE_SHRINK_CENTER
		badge_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		badge_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		var badge_path := "res://assets/ui/results/rank_win_%d.png" % slot_num if won else "res://assets/ui/results/rank_lose_%d.png" % slot_num
		badge_rect.texture = _get_ui_tex(badge_path)
		row_box.add_child(badge_rect)

		# -------------------------------------------------------------
		# B. RIGHT MAIN ROW (Blue Bar for Winner / Transparent for Defeated)
		# -------------------------------------------------------------
		var main_bar := Panel.new()
		main_bar.custom_minimum_size = Vector2(398, 20)
		main_bar.size_flags_horizontal = SIZE_EXPAND_FILL
		var mb_s := StyleBoxFlat.new()
		if won:
			mb_s.bg_color = Color("#299cf7")
			mb_s.border_color = Color("#0f5faf")
			mb_s.set_border_width_all(1)
		else:
			mb_s.bg_color = Color(0, 0, 0, 0)
			mb_s.set_border_width_all(0)
		mb_s.set_corner_radius_all(2)
		main_bar.add_theme_stylebox_override("panel", mb_s)
		row_box.add_child(main_bar)

		var mb_hbox := HBoxContainer.new()
		mb_hbox.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
		mb_hbox.offset_left = 2
		mb_hbox.offset_right = -2
		mb_hbox.add_theme_constant_override("separation", 2)
		main_bar.add_child(mb_hbox)

		# 1. Badge / Medal / Sặc Nước Icon
		var badge_icon := TextureRect.new()
		badge_icon.custom_minimum_size = Vector2(16, 16)
		badge_icon.size_flags_vertical = SIZE_SHRINK_CENTER
		badge_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		badge_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		if won:
			badge_icon.texture = MEDAL_WINNER if winner_count <= 1 else MEDAL_SILVER
		else:
			badge_icon.texture = ICON_SAC_NUOC
		mb_hbox.add_child(badge_icon)

		# 2. Player Name (134px)
		var name_lbl := _result_label(player.display_name, 11, Color.WHITE)
		name_lbl.custom_minimum_size = Vector2(134, 20)
		name_lbl.size_flags_horizontal = SIZE_EXPAND_FILL
		name_lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		mb_hbox.add_child(name_lbl)

		# 3. WP Column (Digital Clock Font "00", 42px)
		var wp_lbl := _result_digital_label("00", 11, Color.WHITE)
		wp_lbl.custom_minimum_size = Vector2(42, 20)
		mb_hbox.add_child(wp_lbl)

		# 4. EXP Column (Exact 1:1 Yellow/Orange Progress Bar with Digital Numbers + Clean %)
		var demo_percents: Array[float] = [71.6, 98.5, 73.8, 37.4, 65.2, 82.1, 45.0, 90.5]
		var exp_pct: float = demo_percents[row_index % demo_percents.size()]
		if player_id == (local_player.player_id if local_player != null else -1) and GameSession.experience > 0:
			exp_pct = float(GameSession.experience_percent())
		
		var exp_box := Panel.new()
		exp_box.custom_minimum_size = Vector2(96, 16)
		exp_box.size_flags_vertical = SIZE_SHRINK_CENTER
		var exp_s := StyleBoxFlat.new()
		exp_s.bg_color = Color("#111111")
		exp_s.border_color = Color("#000000")
		exp_s.set_border_width_all(1)
		exp_box.add_theme_stylebox_override("panel", exp_s)
		mb_hbox.add_child(exp_box)

		var exp_fill := TextureRect.new()
		exp_fill.position = Vector2(1, 1)
		var fill_w := maxf(2.0, 94.0 * clampf(exp_pct / 100.0, 0.0, 1.0))
		exp_fill.size = Vector2(fill_w, 14)
		exp_fill.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		exp_fill.stretch_mode = TextureRect.STRETCH_SCALE
		exp_fill.texture = _get_ui_tex("res://assets/ui/results/exp_bar_fill_exact.png")
		exp_box.add_child(exp_fill)

		var exp_hbox := HBoxContainer.new()
		exp_hbox.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
		exp_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
		exp_hbox.add_theme_constant_override("separation", 1)
		exp_box.add_child(exp_hbox)

		var exp_num_lbl := Label.new()
		exp_num_lbl.text = "%.1f" % exp_pct
		exp_num_lbl.add_theme_font_override("font", get_digital_font())
		exp_num_lbl.add_theme_font_size_override("font_size", 11)
		exp_num_lbl.add_theme_color_override("font_color", Color.WHITE)
		exp_num_lbl.add_theme_color_override("font_outline_color", Color.BLACK)
		exp_num_lbl.add_theme_constant_override("outline_size", 2)
		exp_num_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		exp_num_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		exp_hbox.add_child(exp_num_lbl)

		var exp_pct_lbl := Label.new()
		exp_pct_lbl.text = "%"
		exp_pct_lbl.add_theme_font_override("font", RESULT_FONT)
		exp_pct_lbl.add_theme_font_size_override("font_size", 10)
		exp_pct_lbl.add_theme_color_override("font_color", Color.WHITE)
		exp_pct_lbl.add_theme_color_override("font_outline_color", Color.BLACK)
		exp_pct_lbl.add_theme_constant_override("outline_size", 2)
		exp_pct_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		exp_pct_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		exp_hbox.add_child(exp_pct_lbl)

		# 5. VÀNG Column (Black LCD Box with Dim Gray Leading Zeros + White Active Amount, 90px)
		var gold_val: int = (60 if (won and winner_count <= 1) else (25 if won else 40 if row_index == 2 else 60))
		var gold_box := Panel.new()
		gold_box.custom_minimum_size = Vector2(90, 16)
		gold_box.size_flags_vertical = SIZE_SHRINK_CENTER
		var gold_s := StyleBoxFlat.new()
		gold_s.bg_color = Color("#060606")
		gold_s.border_color = Color("#222222")
		gold_s.set_border_width_all(1)
		gold_box.add_theme_stylebox_override("panel", gold_s)
		mb_hbox.add_child(gold_box)

		var gold_hbox := HBoxContainer.new()
		gold_hbox.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
		gold_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
		gold_hbox.add_theme_constant_override("separation", 0)
		gold_box.add_child(gold_hbox)

		var full_gold_str := "%06d" % gold_val
		var val_gold_str := str(gold_val)
		var leading_zeros_count := 6 - val_gold_str.length()

		if leading_zeros_count > 0:
			var gold_dim_lbl := Label.new()
			gold_dim_lbl.text = full_gold_str.substr(0, leading_zeros_count)
			gold_dim_lbl.add_theme_font_override("font", get_digital_font())
			gold_dim_lbl.add_theme_font_size_override("font_size", 11)
			gold_dim_lbl.add_theme_color_override("font_color", Color("#383e4a")) # dim unlit gray
			gold_dim_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			gold_hbox.add_child(gold_dim_lbl)

		var gold_val_lbl := Label.new()
		gold_val_lbl.text = val_gold_str
		gold_val_lbl.add_theme_font_override("font", get_digital_font())
		gold_val_lbl.add_theme_font_size_override("font_size", 11)
		gold_val_lbl.add_theme_color_override("font_color", Color.WHITE) # active white
		gold_val_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		gold_hbox.add_child(gold_val_lbl)

func _player_won_result(player_id: int, winner_id: int, is_draw: bool) -> bool:
	if is_draw or match_manager == null or not match_manager.players.has(player_id):
		return false
	var player = match_manager.players[player_id]
	return player_id == winner_id or (player.team_id != 0 and match_manager.players.has(winner_id) and player.team_id == match_manager.players[winner_id].team_id)

func _update_result_progress(_progress: Dictionary) -> void:
	# Handled dynamically in row population
	pass

func _schedule_auto_return() -> void:
	auto_return_generation += 1
	var generation := auto_return_generation
	for seconds_left in [5, 4, 3, 2, 1]:
		if generation != auto_return_generation:
			return
		if result_return_label != null:
			result_return_label.text = "TỰ ĐỘNG VỀ PHÒNG SAU %02d GIÂY..." % seconds_left
		await get_tree().create_timer(1.0).timeout
	if generation == auto_return_generation and result_panel.visible:
		_on_menu_pressed()

func _apply_result_style() -> void:
	# Clean transparent result modal overlay so the game arena map is fully visible!
	var result_style := StyleBoxFlat.new()
	result_style.bg_color = Color(0, 0, 0, 0.0)
	result_panel.add_theme_stylebox_override("panel", result_style)
	result_panel.custom_minimum_size = Vector2(500, 320)
	result_panel.size = Vector2(500, 320)
	$BossHUD/Background.add_theme_stylebox_override("panel", UITheme.panel_inset())
	
	var health_bg := StyleBoxFlat.new()
	health_bg.bg_color = Color("#0a2238")
	health_bg.border_color = Color("#ff3b30")
	health_bg.set_border_width_all(2)
	health_bg.set_corner_radius_all(4)
	$BossHUD/HealthBar.add_theme_stylebox_override("background", health_bg)
	
	var health_fill := StyleBoxFlat.new()
	health_fill.bg_color = Color("#ff3333")
	health_fill.set_corner_radius_all(3)
	$BossHUD/HealthBar.add_theme_stylebox_override("fill", health_fill)

func _connect_boss_hud() -> void:
	if boss_signals_connected or match_manager == null:
		return
	if not GameSession.play_mode == &"boss":
		$BossHUD.visible = false
		return
	if match_manager.boss_encounter == null:
		return
	$BossHUD.visible = true
	$BossHUD/BossName.text = "☠ HẢI TẶC BẠO CHÚA (BOSS)"
	$BossHUD/BossName.add_theme_color_override("font_color", Color("#ff5555"))
	$BossHUD/HealthBar.max_value = 100
	$BossHUD/HealthBar.value = 100
	match_manager.boss_encounter.boss_health_changed.connect(func(cur, max_hp, _phase):
		$BossHUD/HealthBar.max_value = max_hp
		$BossHUD/HealthBar.value = cur
	)
	boss_signals_connected = true

func _on_restart_pressed() -> void:
	if match_manager != null:
		match_manager.restart_match()

func _on_menu_pressed() -> void:
	if has_node("/root/RoomManager"):
		RoomManager.reset_match_state_to_lobby()
	get_tree().change_scene_to_file("res://scenes/boot/Boot.tscn")

func _format_digital(value: int) -> String:
	var s := str(value)
	var formatted := ""
	var count := 0
	for i in range(s.length() - 1, -1, -1):
		formatted = s[i] + formatted
		count += 1
		if count % 3 == 0 and i > 0:
			formatted = "," + formatted
	return formatted
