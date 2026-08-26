class_name GridManager
extends RefCounted

var width: int = 15
var height: int = 13
var tile_size: int = 40
var half_tile: float = 20.0
var world_origin: Vector2 = Vector2.ZERO
var corner_assist_strength: float = 0.85
const BODY_HALF_SIZE: float = 13.0 # 26x26 box on 40x40 grid ensures perfect lane clearance and zero trapping

# 2D Grid arrays
var grid_cells: Array[PackedInt32Array] = []
var active_water_balloons_by_cell: Dictionary = {} # Vector2i -> Array of WaterBalloon ids
var reserved_cells: Dictionary = {}
var item_cells: Dictionary = {}

func initialize(map_def: MapDefinition) -> void:
	width = map_def.width
	height = map_def.height
	tile_size = map_def.tile_size
	half_tile = float(tile_size) / 2.0
	
	grid_cells.clear()
	active_water_balloons_by_cell.clear()
	reserved_cells.clear()
	item_cells.clear()
	
	if map_def.layout.is_empty():
		map_def.generate_default_classic_layout()
		
	for y in range(height):
		var row = PackedInt32Array()
		row.resize(width)
		for x in range(width):
			if y < map_def.layout.size() and x < map_def.layout[y].size():
				row[x] = map_def.layout[y][x]
			else:
				row[x] = GameConstants.TileType.FLOOR
		grid_cells.append(row)

func world_to_grid(world_pos: Vector2) -> Vector2i:
	var local_pos := world_pos - world_origin
	var gx = int(floor(local_pos.x / float(tile_size)))
	var gy = int(floor(local_pos.y / float(tile_size)))
	return Vector2i(gx, gy)

func grid_to_world(cell: Vector2i) -> Vector2:
	return world_origin + Vector2(
		float(cell.x * tile_size) + half_tile,
		float(cell.y * tile_size) + half_tile
	)

func is_valid_cell(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.x < width and cell.y >= 0 and cell.y < height

func get_cell_type(cell: Vector2i) -> int:
	if not is_valid_cell(cell):
		return GameConstants.TileType.WALL
	return grid_cells[cell.y][cell.x]

func set_cell_type(cell: Vector2i, type: int) -> void:
	if is_valid_cell(cell):
		grid_cells[cell.y][cell.x] = type

func is_wall(cell: Vector2i) -> bool:
	return get_cell_type(cell) == GameConstants.TileType.WALL

func is_destructible(cell: Vector2i) -> bool:
	return get_cell_type(cell) == GameConstants.TileType.DESTRUCTIBLE

func is_blocked(cell: Vector2i) -> bool:
	var t = get_cell_type(cell)
	return t == GameConstants.TileType.WALL or t == GameConstants.TileType.DESTRUCTIBLE

func is_walkable(cell: Vector2i, ignorable_water_balloon_id: int = -1) -> bool:
	if not is_valid_cell(cell):
		return false
	if is_blocked(cell):
		return false
	if active_water_balloons_by_cell.has(cell):
		var water_balloons = active_water_balloons_by_cell[cell]
		if water_balloons.size() > 0:
			if ignorable_water_balloon_id != -1 and water_balloons.size() == 1 and water_balloons[0] == ignorable_water_balloon_id:
				return true
			return false
	return true

func register_water_balloon_cell(cell: Vector2i, water_balloon_id: int) -> void:
	if not active_water_balloons_by_cell.has(cell):
		active_water_balloons_by_cell[cell] = []
	if not active_water_balloons_by_cell[cell].has(water_balloon_id):
		active_water_balloons_by_cell[cell].append(water_balloon_id)

func unregister_water_balloon_cell(cell: Vector2i, water_balloon_id: int) -> void:
	if active_water_balloons_by_cell.has(cell):
		active_water_balloons_by_cell[cell].erase(water_balloon_id)
		if active_water_balloons_by_cell[cell].is_empty():
			active_water_balloons_by_cell.erase(cell)

func has_water_balloon(cell: Vector2i) -> bool:
	return active_water_balloons_by_cell.has(cell) and not active_water_balloons_by_cell[cell].is_empty()

func world_to_cell(world_pos: Vector2) -> Vector2i:
	return world_to_grid(world_pos)

func cell_to_world(cell: Vector2i) -> Vector2:
	return grid_to_world(cell)

func is_hard_block(cell: Vector2i) -> bool:
	return is_wall(cell)

func is_soft_block(cell: Vector2i) -> bool:
	return is_destructible(cell)

func get_cell(cell: Vector2i) -> int:
	return get_cell_type(cell)

func set_cell(cell: Vector2i, cell_type: int) -> void:
	set_cell_type(cell, cell_type)

func reserve_cell(cell: Vector2i, owner: Variant = true) -> bool:
	if not is_valid_cell(cell) or reserved_cells.has(cell):
		return false
	reserved_cells[cell] = owner
	return true

func release_cell(cell: Vector2i) -> void:
	reserved_cells.erase(cell)

func set_item_cell(cell: Vector2i, occupied: bool) -> void:
	if occupied:
		item_cells[cell] = true
	else:
		item_cells.erase(cell)

func has_item(cell: Vector2i) -> bool:
	return item_cells.has(cell)

# Arcade Corner Sliding & Precise AABB Movement:
func compute_movement_with_corner_sliding(current_pos: Vector2, move_delta: Vector2, ignorable_water_balloon_id: int = -1) -> Vector2:
	if move_delta == Vector2.ZERO:
		return current_pos
	var result := current_pos
	var step_count := maxi(1, ceili(move_delta.length() / 4.0))
	var step := move_delta / float(step_count)
	
	for _index in range(step_count):
		# 1. Try X movement
		if step.x != 0.0:
			var x_candidate := result + Vector2(step.x, 0.0)
			if _body_fits(x_candidate, ignorable_water_balloon_id):
				result.x = x_candidate.x
			else:
				# X blocked: assist vertically if within lane tolerance
				var current_cell := world_to_grid(result)
				var center_y := float(current_cell.y * tile_size) + half_tile + world_origin.y
				var offset_y := result.y - center_y
				if absf(offset_y) <= 14.0 and offset_y != 0.0:
					var nudge_y := -signf(offset_y) * minf(absf(offset_y), absf(step.x) * corner_assist_strength)
					var nudge_candidate := result + Vector2(0.0, nudge_y)
					if _body_fits(nudge_candidate, ignorable_water_balloon_id):
						result.y = nudge_candidate.y
		
		# 2. Try Y movement
		if step.y != 0.0:
			var y_candidate := result + Vector2(0.0, step.y)
			if _body_fits(y_candidate, ignorable_water_balloon_id):
				result.y = y_candidate.y
			else:
				# Y blocked: assist horizontally if within lane tolerance
				var current_cell := world_to_grid(result)
				var center_x := float(current_cell.x * tile_size) + half_tile + world_origin.x
				var offset_x := result.x - center_x
				if absf(offset_x) <= 14.0 and offset_x != 0.0:
					var nudge_x := -signf(offset_x) * minf(absf(offset_x), absf(step.y) * corner_assist_strength)
					var nudge_candidate := result + Vector2(nudge_x, 0.0)
					if _body_fits(nudge_candidate, ignorable_water_balloon_id):
						result.x = nudge_candidate.x
							
	return result

func _body_fits(world_pos: Vector2, ignorable_water_balloon_id: int = -1) -> bool:
	# Standard Arcade AABB Collision box (26x26 on 40x40 tile)
	var min_cell = world_to_grid(world_pos - Vector2(BODY_HALF_SIZE, BODY_HALF_SIZE))
	var max_cell = world_to_grid(world_pos + Vector2(BODY_HALF_SIZE, BODY_HALF_SIZE))
	
	for cy in range(min_cell.y, max_cell.y + 1):
		for cx in range(min_cell.x, max_cell.x + 1):
			var cell = Vector2i(cx, cy)
			if not is_walkable(cell, ignorable_water_balloon_id):
				return false
	return true
