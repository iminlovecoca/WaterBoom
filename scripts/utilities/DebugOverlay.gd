class_name DebugOverlay
extends CanvasLayer

var is_debug_visible: bool = false
var debug_panel: Panel
var debug_label: Label
var match_manager: MatchManager

func _ready() -> void:
	layer = 100
	_build_ui()
	visible = false
	match_manager = get_parent() as MatchManager

func _build_ui() -> void:
	debug_panel = Panel.new()
	debug_panel.custom_minimum_size = Vector2(280, 200)
	debug_panel.offset_left = 10
	debug_panel.offset_top = 10
	debug_panel.offset_right = 290
	debug_panel.offset_bottom = 210
	add_child(debug_panel)
	
	debug_label = Label.new()
	debug_label.add_theme_font_size_override("font_size", 12)
	debug_label.add_theme_color_override("font_color", Color(0.2, 1.0, 0.4))
	debug_label.offset_left = 10
	debug_label.offset_top = 10
	debug_label.offset_right = 270
	debug_label.offset_bottom = 190
	debug_panel.add_child(debug_label)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_debug"):
		is_debug_visible = not is_debug_visible
		visible = is_debug_visible
		if has_node("/root/EventBus"):
			get_node("/root/EventBus").debug_overlay_toggled.emit(is_debug_visible)

func _process(_delta: float) -> void:
	if not visible:
		return
		
	var fps = Engine.get_frames_per_second()
	var static_mem = Performance.get_monitor(Performance.MEMORY_STATIC) / (1024.0 * 1024.0)
	var node_count = Performance.get_monitor(Performance.OBJECT_NODE_COUNT)
	
	var text = "=== BOOM WATER ARCADE DEBUG (F1) ===\n"
	text += "FPS: %d | Mem: %.2f MB\n" % [fps, static_mem]
	text += "Nodes: %d | Tick: 60 Hz\n" % [node_count]
	
	if match_manager != null:
		var state_str = ["WAITING", "COUNTDOWN", "PLAYING", "ENDING", "RESULT"][match_manager.current_state]
		text += "Match State: %s\n" % state_str
		text += "Time Left: %.1fs\n" % match_manager.time_left_seconds
		if match_manager.water_balloon_manager != null:
			text += "Active WaterBalloons: %d\n" % match_manager.water_balloon_manager.active_water_balloons.size()
		if match_manager.players.has(1):
			var p1 = match_manager.players[1]
			text += "P1 Pos: %s | Cell: %s | State: %s\n" % [str(p1.global_position.round()), str(p1.grid_cell), str(p1.current_state)]
			text += "Speed: %.0f | Power: %d | Water: %d/%d\n" % [p1.move_speed, p1.water_power, p1.active_water_balloons, p1.max_water_balloons]
		if match_manager.players.has(2):
			var p2 = match_manager.players[2]
			text += "P2 Cell: %s | Alive: %s | Bubble: %s\n" % [str(p2.grid_cell), str(p2.is_alive), str(p2.is_in_bubble)]
			
	debug_label.text = text
