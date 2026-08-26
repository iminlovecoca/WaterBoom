class_name WaterBalloonManager
extends Node2D

@export var water_balloon_scene: PackedScene = preload("res://scenes/water_balloon/WaterBalloon.tscn")

var next_water_balloon_id: int = 1
var active_water_balloons: Dictionary = {} # water_balloon_id -> WaterBalloon
var water_balloons_by_cell: Dictionary = {} # Vector2i -> WaterBalloon
var active_water_cells: Dictionary = {} # Vector2i -> remaining seconds
var water_active_duration: float = GameConstants.DEFAULT_WATER_BURST_DURATION

var grid_manager: GridManager
var water_stream_renderer: WaterStreamRenderer
var match_manager: Node

func initialize(p_grid: GridManager, p_renderer: WaterStreamRenderer, p_match_mgr: Node) -> void:
	for child in get_children():
		child.queue_free()
	grid_manager = p_grid
	water_stream_renderer = p_renderer
	match_manager = p_match_mgr
	active_water_balloons.clear()
	water_balloons_by_cell.clear()
	active_water_cells.clear()
	next_water_balloon_id = 1
	if match_manager != null and match_manager.match_config != null:
		water_active_duration = match_manager.match_config.water_active_duration
	if water_stream_renderer != null:
		water_stream_renderer.segment_duration = water_active_duration

func _process(delta: float) -> void:
	for cell in active_water_cells.keys():
		active_water_cells[cell] = float(active_water_cells[cell]) - delta
		if active_water_cells[cell] <= 0.0:
			active_water_cells.erase(cell)

func place_water_balloon_request(owner_id: int, cell: Vector2i, water_power: int, timer_duration: float = GameConstants.DEFAULT_WATER_BALLOON_TIMER, skin_id: StringName = &"skin_066") -> WaterBalloon:
	# This is the authoritative validation point used by local and network requests.
	if match_manager != null:
		if match_manager.current_state != GameConstants.MatchState.PLAYING:
			return null
		if match_manager.has_method("can_player_place_water_balloon") and not match_manager.can_player_place_water_balloon(owner_id, cell):
			return null
	if not grid_manager.is_valid_cell(cell):
		return null
	if grid_manager.is_blocked(cell):
		return null
	if water_balloons_by_cell.has(cell):
		return null
		
	var water_balloon_id = next_water_balloon_id
	next_water_balloon_id += 1
	
	var water_balloon_instance = water_balloon_scene.instantiate() as WaterBalloon
	water_balloon_instance.position = grid_manager.grid_to_world(cell)
	add_child(water_balloon_instance)
	
	water_balloon_instance.initialize(water_balloon_id, owner_id, cell, water_power, timer_duration, self, skin_id)
	
	active_water_balloons[water_balloon_id] = water_balloon_instance
	water_balloons_by_cell[cell] = water_balloon_instance
	grid_manager.register_water_balloon_cell(cell, water_balloon_id)
	
	EventBus.water_balloon_placed.emit(water_balloon_id, owner_id, cell, timer_duration, water_power)
	return water_balloon_instance

func on_water_balloon_timer_expired(water_balloon: WaterBalloon) -> void:
	trigger_water_burst(water_balloon.water_balloon_id)

func trigger_water_burst(initial_water_balloon_id: int) -> void:
	var pending_queue: Array[WaterBalloon] = []
	var processed_ids: Dictionary = {}
	
	if active_water_balloons.has(initial_water_balloon_id):
		pending_queue.append(active_water_balloons[initial_water_balloon_id])
		processed_ids[initial_water_balloon_id] = true
		
	while not pending_queue.is_empty():
		var water_balloon = pending_queue.pop_front()
		var water_balloon_id = water_balloon.water_balloon_id
		var cell = water_balloon.grid_cell
		var water_power = water_balloon.water_power
		var owner_id = water_balloon.owner_id
		var skin_id: StringName = water_balloon.skin_id
		
		# Unregister from active tracking
		active_water_balloons.erase(water_balloon_id)
		water_balloons_by_cell.erase(cell)
		grid_manager.unregister_water_balloon_cell(cell, water_balloon_id)
		
		# Notify owner to decrement active water_balloon count
		if match_manager != null and match_manager.has_method("notify_player_water_balloon_popped"):
			match_manager.notify_player_water_balloon_popped(owner_id)
			
		# Calculate 4-direction rays
		var water_data = WaterGridPropagation.calculate_water_burst(cell, water_power, grid_manager)
		var affected_cells: Array = water_data["affected_cells"]
		var destroyed_blocks: Array = water_data["destroyed_blocks"]
		for water_cell in affected_cells:
			active_water_cells[water_cell] = maxf(float(active_water_cells.get(water_cell, 0.0)), water_active_duration)
			
		# Chain reaction: check if affected cells hit any other active balloons
		for water_cell in affected_cells:
			if water_balloons_by_cell.has(water_cell):
				var chained_balloon = water_balloons_by_cell[water_cell]
				if not processed_ids.has(chained_balloon.water_balloon_id):
					pending_queue.append(chained_balloon)
					processed_ids[chained_balloon.water_balloon_id] = true
		
		# Notify MatchManager to check player damage in affected cells
		if match_manager != null and match_manager.has_method("check_water_cells"):
			match_manager.check_water_cells(affected_cells)
		if match_manager != null and match_manager.has_method("check_enemy_water_cells"):
			match_manager.check_enemy_water_cells(affected_cells, owner_id)
			
		# Destroy destructible blocks
		for block_cell in destroyed_blocks:
			grid_manager.set_cell_type(block_cell, GameConstants.TileType.FLOOR)
			EventBus.block_destroyed.emit(block_cell)
			
		# Render VFX
		if water_stream_renderer != null:
			water_stream_renderer.spawn_water_burst(water_data["rays"], grid_manager, skin_id)
		
		EventBus.water_burst_started.emit(cell, water_data["rays"])
		EventBus.water_balloon_popped.emit(water_balloon_id, cell, affected_cells)
			
		if is_instance_valid(water_balloon):
			water_balloon.has_popped = true
			water_balloon.queue_free()
