class_name PlayerController
extends CharacterBody2D

@export var player_id: int = 1
@export var team_id: int = 0
@export var character_def: CharacterDefinition
@export var is_local_control: bool = true
@export var control_scheme: String = "p1"
var display_name: String = "Player"
var is_bot: bool = false

var move_speed: float = GameConstants.DEFAULT_MOVE_SPEED
var max_water_balloons: int = GameConstants.DEFAULT_WATER_BALLOON_CAPACITY
var active_water_balloons: int = 0
var water_power: int = GameConstants.DEFAULT_WATER_POWER
var max_move_speed: float = GameConstants.MAX_MOVE_SPEED
var max_water_power: int = GameConstants.MAX_WATER_POWER
var max_water_balloon_limit: int = GameConstants.MAX_WATER_BALLOON_CAPACITY
var speed_up_amount: float = GameConstants.SPEED_BOOST_PER_ITEM
var active_items: Array[int] = [GameConstants.ItemType.NONE]
var shield_active_time: float = 0.0

var current_state: GameConstants.PlayerState = GameConstants.PlayerState.NORMAL
var current_direction: GameConstants.Direction = GameConstants.Direction.DOWN
var is_alive: bool = true
var is_in_bubble: bool = false
var max_bubble_time: float = GameConstants.DEFAULT_BUBBLE_DURATION
var invulnerability_remaining: float = 0.0
var bubble_state := BubbleState.new()

var grid_cell: Vector2i = Vector2i.ZERO
var overlapping_water_balloon_id: int = -1
var overlapping_water_balloon_cell: Vector2i = Vector2i(-1, -1)
var grid_manager: GridManager
var water_balloon_manager: Node
var balloon_skin_id: StringName = &"skin_066"
var equipment_snapshot: Dictionary = {
	"head_accessory": "",
	"flag": "flag_default_water",
	"player_frame": "frame_default_aqua",
	"player_background": "background_default_aqua",
}

var _target_network_pos: Vector2 = Vector2.ZERO
var _last_synced_pos: Vector2 = Vector2.ZERO
var _network_sync_timer: float = 0.0
var _last_synced_state: int = -1
var _last_synced_dir: int = -1
const NETWORK_SYNC_INTERVAL: float = 0.02

@onready var visual: Node2D = $Visual

func _ready() -> void:
	if is_local_control and GameSession.selected_balloon_skin != &"":
		balloon_skin_id = GameSession.selected_balloon_skin
		equipment_snapshot = CosmeticRegistry.sanitize_equipment(GameSession.equipped_cosmetics, GameSession.owned_cosmetics)

	if GameSession.play_mode == &"multiplayer":
		if has_node("/root/RoomManager"):
			RoomManager.match_player_state_received.connect(_on_match_player_state_received)

	if not InputMap.has_action("use_item"):
		InputMap.add_action("use_item")
		var ctrl_key := InputEventKey.new()
		ctrl_key.physical_keycode = KEY_CTRL
		InputMap.action_add_event("use_item", ctrl_key)
	if character_def != null:
		_apply_character_definition(character_def)
	if visual != null and visual.has_method("setup"):
		visual.setup(character_def)
		visual.apply_equipment(equipment_snapshot)

func set_equipment_snapshot(equipment: Dictionary) -> void:
	equipment_snapshot = CosmeticRegistry.sanitize_equipment(equipment)
	if is_node_ready() and visual != null and visual.has_method("apply_equipment"):
		visual.apply_equipment(equipment_snapshot)

func _apply_character_definition(cdef: CharacterDefinition) -> void:
	character_def = cdef
	move_speed = cdef.base_speed
	max_water_balloons = cdef.base_water_balloon_capacity
	water_power = cdef.base_water_power

func initialize(p_id: int, p_cell: Vector2i, p_grid: GridManager, p_water_balloon_mgr: Node, p_team_id: int = 0) -> void:
	player_id = p_id
	team_id = p_team_id
	grid_manager = p_grid
	water_balloon_manager = p_water_balloon_mgr
	if water_balloon_manager != null and water_balloon_manager.match_manager != null and water_balloon_manager.match_manager.match_config != null:
		var config: MatchConfig = water_balloon_manager.match_manager.match_config
		if character_def == null:
			move_speed = config.base_speed
			max_water_balloons = config.base_water_balloon_capacity
			water_power = config.base_water_power
			max_move_speed = config.max_speed
			max_water_power = config.max_water_power
			max_water_balloon_limit = config.max_water_balloon_capacity
		else:
			max_move_speed = character_def.max_speed
			max_water_power = character_def.max_water_power
			max_water_balloon_limit = character_def.max_water_balloon_capacity
		speed_up_amount = config.speed_up_amount
	grid_cell = p_cell
	global_position = grid_manager.grid_to_world(grid_cell)
	_target_network_pos = global_position
	is_alive = true
	is_in_bubble = false
	active_items = [GameConstants.ItemType.NONE]
	shield_active_time = 0.0
	active_water_balloons = 0
	current_direction = GameConstants.Direction.DOWN
	current_state = GameConstants.PlayerState.NORMAL
	EventBus.player_spawned.emit(player_id, character_def.id if character_def else "boom_mascot", grid_cell)

func _physics_process(delta: float) -> void:
	if invulnerability_remaining > 0.0:
		invulnerability_remaining = maxf(invulnerability_remaining - delta, 0.0)
	if shield_active_time > 0.0:
		shield_active_time -= delta
		if shield_active_time <= 0.0:
			if visual != null and visual.has_method("set_shield_active"):
				visual.set_shield_active(false)
	if not is_alive:
		return

	# Remote player smooth network position interpolation (fast, accurate, zero wall clipping)
	if GameSession.play_mode == &"multiplayer" and not is_multiplayer_authority():
		if _target_network_pos != Vector2.ZERO:
			var dist: float = global_position.distance_to(_target_network_pos)
			if dist > 70.0:
				global_position = _target_network_pos
			elif dist > 0.05:
				global_position = global_position.lerp(_target_network_pos, clampf(35.0 * delta, 0.0, 1.0))

		if visual != null and visual.has_method("update_state"):
			visual.update_state(current_state, current_direction)

		if grid_manager != null:
			var new_cell = grid_manager.world_to_grid(global_position)
			if new_cell != grid_cell:
				grid_cell = new_cell
				EventBus.player_moved.emit(player_id, grid_cell, global_position)
		return

	var is_ctrl_item_pressed: bool = (
		Input.is_action_just_pressed("use_item")
		or Input.is_action_just_pressed("use_item_1")
		or Input.is_physical_key_pressed(KEY_CTRL)
		or Input.is_key_pressed(KEY_CTRL)
	)

	if is_in_bubble:
		if is_local_control and control_scheme == "p1":
			if is_ctrl_item_pressed and active_items.size() > 0 and active_items[0] == GameConstants.ItemType.BUBBLE_PIN:
				if use_bubble_pin():
					active_items[0] = GameConstants.ItemType.NONE
					EventBus.player_inventory_updated.emit(player_id)
		_process_bubble_state(delta)
		_sync_network_state_throttled(delta)
		return

	if is_local_control and control_scheme == "p1":
		if is_ctrl_item_pressed and active_items.size() > 0 and active_items[0] == GameConstants.ItemType.SHIELD:
			if activate_shield():
				active_items[0] = GameConstants.ItemType.NONE
				EventBus.player_inventory_updated.emit(player_id)
		_process_local_input(delta)

	if grid_manager == null:
		return

	if visual != null and visual.has_method("update_state"):
		visual.update_state(current_state, current_direction)

	var new_cell = grid_manager.world_to_grid(global_position)
	if new_cell != grid_cell:
		grid_cell = new_cell
		EventBus.player_moved.emit(player_id, grid_cell, global_position)
		if overlapping_water_balloon_id != -1 and _fully_clear_of_placed_balloon():
			overlapping_water_balloon_id = -1
			overlapping_water_balloon_cell = Vector2i(-1, -1)
	elif overlapping_water_balloon_id != -1 and _fully_clear_of_placed_balloon():
		overlapping_water_balloon_id = -1
		overlapping_water_balloon_cell = Vector2i(-1, -1)

	_sync_network_state_throttled(delta)

func _sync_network_state_throttled(delta: float) -> void:
	if GameSession.play_mode != &"multiplayer" or not is_multiplayer_authority():
		return
	_network_sync_timer += delta
	var state_changed: bool = (current_state != _last_synced_state or current_direction != _last_synced_dir)
	var pos_changed: bool = (global_position.distance_squared_to(_last_synced_pos) > 0.25)
	if _network_sync_timer >= NETWORK_SYNC_INTERVAL or state_changed or pos_changed:
		_network_sync_timer = 0.0
		_last_synced_state = current_state
		_last_synced_dir = current_direction
		_last_synced_pos = global_position
		_send_network_state()

func _send_network_state() -> void:
	if has_node("/root/RoomManager") and RoomManager.current_room_id != "":
		RoomManager.rpc_id(1, "relay_player_state", RoomManager.current_room_id, player_id, global_position, current_state, current_direction, is_alive, is_in_bubble)

func _fully_clear_of_placed_balloon() -> bool:
	if grid_manager == null or overlapping_water_balloon_cell.x < 0:
		return true
	var min_cell := grid_manager.world_to_grid(global_position - Vector2(GridManager.BODY_HALF_SIZE, GridManager.BODY_HALF_SIZE))
	var max_cell := grid_manager.world_to_grid(global_position + Vector2(GridManager.BODY_HALF_SIZE, GridManager.BODY_HALF_SIZE))
	if overlapping_water_balloon_cell.x < min_cell.x or overlapping_water_balloon_cell.x > max_cell.x or \
	   overlapping_water_balloon_cell.y < min_cell.y or overlapping_water_balloon_cell.y > max_cell.y:
		return true
	return false

func _process_local_input(delta: float) -> void:
	var input_vec := Vector2.ZERO
	var prefix := "" if control_scheme == "p1" else "p2_"
	if Input.is_action_pressed(prefix + "move_up"): input_vec.y -= 1.0
	if Input.is_action_pressed(prefix + "move_down"): input_vec.y += 1.0
	if Input.is_action_pressed(prefix + "move_left"): input_vec.x -= 1.0
	if Input.is_action_pressed(prefix + "move_right"): input_vec.x += 1.0
	input_vec = input_vec.normalized()

	apply_movement_intent(input_vec, delta)

	if Input.is_action_just_pressed(prefix + "place_water_balloon"):
		place_water_balloon_request()
	if visual != null and visual.has_method("update_state"):
		visual.update_state(current_state, current_direction)

func apply_movement_intent(input_vec: Vector2, delta: float) -> void:
	if not is_alive or is_in_bubble or grid_manager == null:
		return
	if water_balloon_manager != null and water_balloon_manager.match_manager != null and water_balloon_manager.match_manager.current_state != GameConstants.MatchState.PLAYING:
		return
	var normalized_input := input_vec.normalized()
	if normalized_input != Vector2.ZERO:
		var move_delta := normalized_input * move_speed * delta
		global_position = grid_manager.compute_movement_with_corner_sliding(global_position, move_delta, overlapping_water_balloon_id)
		current_direction = GameConstants.vector_to_direction(normalized_input)
		current_state = GameConstants.PlayerState.WALKING
	else:
		current_state = GameConstants.PlayerState.NORMAL
	if visual != null and visual.has_method("update_state"):
		visual.update_state(current_state, current_direction)

func place_water_balloon_request() -> void:
	if grid_manager == null: return
	grid_cell = grid_manager.world_to_grid(global_position)
	if GameSession.play_mode == &"multiplayer":
		if is_multiplayer_authority():
			if has_node("/root/RoomManager") and RoomManager.current_room_id != "":
				RoomManager.rpc_id(1, "relay_place_balloon", RoomManager.current_room_id, player_id, grid_cell, str(balloon_skin_id))
				_send_network_state()
			_do_place_balloon_at(grid_cell)
	else:
		_do_place_balloon_at(grid_cell)

func _do_place_balloon() -> void:
	if grid_manager == null: return
	grid_cell = grid_manager.world_to_grid(global_position)
	_do_place_balloon_at(grid_cell)

func _do_place_balloon_at(target_cell: Vector2i) -> void:
	if not is_alive or is_in_bubble or active_water_balloons >= max_water_balloons:
		return
	if water_balloon_manager != null and water_balloon_manager.has_method("place_water_balloon_request"):
		var duration := GameConstants.DEFAULT_WATER_BALLOON_TIMER
		if water_balloon_manager.match_manager != null and water_balloon_manager.match_manager.match_config != null:
			duration = water_balloon_manager.match_manager.match_config.water_balloon_duration
		var placed = water_balloon_manager.place_water_balloon_request(player_id, target_cell, water_power, duration, balloon_skin_id)
		if placed != null:
			active_water_balloons += 1
			overlapping_water_balloon_id = placed.water_balloon_id
			overlapping_water_balloon_cell = target_cell
			current_state = GameConstants.PlayerState.NORMAL

func on_water_balloon_popped() -> void:
	active_water_balloons = maxi(active_water_balloons - 1, 0)

func apply_item(item_type: int, value: float = 1.0) -> void:
	match item_type:
		GameConstants.ItemType.WATER_BALLOON_UP:
			max_water_balloons = mini(max_water_balloons + int(value), max_water_balloon_limit)
		GameConstants.ItemType.WATER_POWER_UP:
			water_power = mini(water_power + int(value), max_water_power)
		GameConstants.ItemType.SPEED_UP:
			move_speed = minf(move_speed + speed_up_amount * value, max_move_speed)
		GameConstants.ItemType.BUBBLE_PIN:
			_add_active_item(item_type)
		GameConstants.ItemType.SHIELD:
			_add_active_item(item_type)


func can_collect_item(item_type: int) -> bool:
	if item_type not in [GameConstants.ItemType.BUBBLE_PIN, GameConstants.ItemType.SHIELD]:
		return true
	return active_items.is_empty() or active_items[0] == GameConstants.ItemType.NONE

func _add_active_item(item_type: int) -> void:
	if active_items.is_empty():
		active_items.append(item_type)
	elif active_items[0] == GameConstants.ItemType.NONE:
		active_items[0] = item_type
	else:
		return
	EventBus.player_inventory_updated.emit(player_id)

func activate_shield() -> bool:
	if not is_alive or is_in_bubble or shield_active_time > 0.0:
		return false
	shield_active_time = 3.0
	if visual != null and visual.has_method("set_shield_active"):
		visual.set_shield_active(true)
	return true

func use_bubble_pin() -> bool:
	if not is_alive or not is_in_bubble:
		return false
	rescue(player_id, 0.75)
	if visual != null and visual.has_method("play_pin_escape"):
		visual.play_pin_escape()
	return true

func hit_by_water(source_cell: Vector2i = Vector2i.ZERO, force_remote: bool = false) -> void:
	if GameSession.play_mode == &"multiplayer" and not is_multiplayer_authority() and not force_remote:
		return
	if not is_alive or is_in_bubble or invulnerability_remaining > 0.0 or shield_active_time > 0.0:
		return
		
	current_state = GameConstants.PlayerState.WATER_HIT
	EventBus.player_water_hit.emit(player_id, source_cell)
	is_in_bubble = true
	bubble_state.begin(max_bubble_time)
	current_state = GameConstants.PlayerState.BUBBLED
	EventBus.player_bubbled.emit(player_id)
	if visual != null and visual.has_method("play_hurt_then_bubble"):
		visual.play_hurt_then_bubble(current_direction)
	if visual != null and visual.has_method("set_bubble"):
		visual.set_bubble(true)

func _process_bubble_state(delta: float) -> void:
	if visual != null and visual.has_method("set_bubble_progress"):
		visual.set_bubble_progress(bubble_state.time_left / maxf(max_bubble_time, 0.001))
	if bubble_state.tick(delta):
		if water_balloon_manager != null and water_balloon_manager.match_manager != null and water_balloon_manager.match_manager.has_method("resolve_bubble_timeout"):
			water_balloon_manager.match_manager.resolve_bubble_timeout(self)
		else:
			die()

func rescue(rescuer_id: int, invulnerability_seconds: float = 0.0, force_remote: bool = false) -> void:
	if GameSession.play_mode == &"multiplayer" and not is_multiplayer_authority() and not force_remote:
		return
	if not is_in_bubble or not is_alive:
		return
	is_in_bubble = false
	bubble_state.clear()
	invulnerability_remaining = maxf(invulnerability_seconds, 0.0)
	current_state = GameConstants.PlayerState.RESCUED
	EventBus.player_rescued.emit(player_id, rescuer_id)
	if visual != null and visual.has_method("set_bubble"):
		visual.set_bubble(false)
	if visual != null and visual.has_method("play_rescued"):
		visual.play_rescued()
	current_state = GameConstants.PlayerState.NORMAL

func die(force_remote: bool = false) -> void:
	if GameSession.play_mode == &"multiplayer" and not is_multiplayer_authority() and not force_remote:
		return
	var was_bubbled := is_in_bubble
	is_alive = false
	is_in_bubble = false
	bubble_state.clear()
	current_state = GameConstants.PlayerState.DEAD
	EventBus.player_died.emit(player_id)
	if visual != null:
		if was_bubbled and visual.has_method("play_bubble_pop_and_death"):
			visual.play_bubble_pop_and_death()
		elif visual.has_method("play_death"):
			visual.play_death()


func _on_match_player_state_received(p_id: int, p_pos: Vector2, p_state: int, p_dir: int, p_is_alive: bool, p_is_in_bubble: bool) -> void:
	if p_id != player_id: return
	if is_multiplayer_authority(): return
	
	_target_network_pos = p_pos
	current_state = p_state as GameConstants.PlayerState
	current_direction = p_dir as GameConstants.Direction
	
	if global_position == Vector2.ZERO or global_position.distance_squared_to(p_pos) > 6400.0:
		global_position = p_pos
		
	if is_alive and not p_is_alive:
		die(true)
	elif not is_in_bubble and p_is_in_bubble:
		hit_by_water(Vector2i.ZERO, true)
	elif is_in_bubble and not p_is_in_bubble:
		rescue(-1, 0.0, true)
		
	is_alive = p_is_alive
	is_in_bubble = p_is_in_bubble
	if visual != null and visual.has_method("update_state"):
		visual.update_state(current_state, current_direction)
