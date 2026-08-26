class_name BotBrain
extends RefCounted

var state: GameConstants.BotState = GameConstants.BotState.IDLE
var danger_map := DangerMap.new()
var player: PlayerController
var grid: GridManager
var water_balloon_manager: WaterBalloonManager
var item_manager: ItemManager
var match_manager: MatchManager
var difficulty: GameConstants.BotDifficulty = GameConstants.BotDifficulty.NORMAL
var _profile: Dictionary = {}

func initialize(p_player: PlayerController, p_grid: GridManager, p_water_balloon_manager: WaterBalloonManager, p_item_manager: ItemManager, p_match_manager: MatchManager, p_difficulty: GameConstants.BotDifficulty) -> void:
	player = p_player
	grid = p_grid
	water_balloon_manager = p_water_balloon_manager
	item_manager = p_item_manager
	match_manager = p_match_manager
	difficulty = p_difficulty
	_build_profile()

func _build_profile() -> void:
	#                                                        EASY    NORMAL  HARD   EXTREME
	_profile = {
		"danger_horizon":            [2.0,  3.5,  5.0,  6.5][difficulty],
		"escape_depth":              [4,    7,    10,   14][difficulty],
		"item_safety":               [4.0,  3.0,  2.0,  1.5][difficulty],
		"attack_range_sq":           [9,    16,   25,   36][difficulty],
		"chase_range_sq":            [16,   25,   49,   64][difficulty],
		"strategic_range_sq":        [16,   36,   49,   64][difficulty],
		"wander_safety":             [2.0,  3.0,  4.0,  5.5][difficulty],
		"block_search_walkable":     [2.0,  2.5,  2.5,  3.0][difficulty],
		"max_escape_time":           [3.0,  2.8,  2.5,  2.3][difficulty],
		"prefers_items":             [true, true, false, false][difficulty],
		"predict_steps":             [0,    1,    2,    3][difficulty],
		"can_chain_danger":          [false, false, true, true][difficulty],
		"enemy_escape_threshold":    [3,    2,    2,    1][difficulty],
	}

func decide() -> Dictionary:
	var decision := {"target_cell": player.grid_cell, "place": false}
	if player == null or not player.is_alive:
		state = GameConstants.BotState.DEAD
		return decision
	if player.is_in_bubble:
		state = GameConstants.BotState.BUBBLED
		return decision

	danger_map.rebuild(grid, water_balloon_manager)

	# 1. IMMEDIATE DANGER EVASION
	if danger_map.is_dangerous(player.grid_cell, _profile.danger_horizon):
		state = GameConstants.BotState.ESCAPE_DANGER
		var safe_cell := _find_nearest_safe_cell()
		decision["target_cell"] = _next_path_cell(safe_cell, false)
		return decision

	# 2. POP TRAPPED ENEMY — highest priority after survival
	var bubbled_enemy_cell := _nearest_bubbled_enemy_cell()
	if bubbled_enemy_cell != Vector2i(-1, -1):
		state = GameConstants.BotState.CHASE_ENEMY
		decision["target_cell"] = _next_path_cell(bubbled_enemy_cell, true)
		return decision

	# 3. COLLECT ITEMS — only if item-seeking is a priority at this difficulty
	if _profile.prefers_items:
		var item_cell := _nearest_safe_item_cell()
		if item_cell != Vector2i(-1, -1):
			state = GameConstants.BotState.SEEK_ITEM
			decision["target_cell"] = _next_path_cell(item_cell, true)
			return decision

	# 4. ATTACK: Place balloon near enemy or soft block
	var can_place := player.active_water_balloons < player.max_water_balloons
	if can_place and (_is_adjacent_to_soft_block() or _enemy_is_nearby()):
		if _can_safely_escape_after_placement():
			state = GameConstants.BotState.PLACE_BALLOON
			decision["place"] = true
			var safe_cell := _find_escape_after_place(player.grid_cell, player.water_power)
			decision["target_cell"] = _next_path_cell(safe_cell, false)
			return decision

	# 5. STRATEGIC BOMB PLACEMENT — try to trap enemies in corridors
	if can_place and _enemy_is_in_killable_position():
		if _can_safely_escape_after_placement():
			state = GameConstants.BotState.PLACE_BALLOON
			decision["place"] = true
			var safe_cell := _find_escape_after_place(player.grid_cell, player.water_power)
			decision["target_cell"] = _next_path_cell(safe_cell, false)
			return decision

	# 6. PATH TO DESTROYABLE BLOCKS
	var block_goal := _nearest_open_cell_beside_soft_block()
	if block_goal != Vector2i(-1, -1):
		state = GameConstants.BotState.SEEK_BLOCK
		decision["target_cell"] = _next_path_cell(block_goal, true)
		return decision

	# 7. COLLECT ITEMS — lower priority at high difficulty
	if not _profile.prefers_items:
		var item_cell := _nearest_safe_item_cell()
		if item_cell != Vector2i(-1, -1):
			state = GameConstants.BotState.SEEK_ITEM
			decision["target_cell"] = _next_path_cell(item_cell, true)
			return decision

	# 8. CHASE ENEMY
	var enemy_cell := _nearest_enemy_cell()
	if enemy_cell != player.grid_cell:
		state = GameConstants.BotState.CHASE_ENEMY
		var path = _next_path_cell(enemy_cell, true)
		if path != player.grid_cell:
			decision["target_cell"] = path
			return decision

	# 9. WANDER (Fallback if stuck)
	state = GameConstants.BotState.IDLE
	var open_neighbors: Array[Vector2i] = []
	for dir in GameConstants.DIR_VECTORS.values():
		if dir == Vector2i.ZERO:
			continue
		var neighbor: Vector2i = player.grid_cell + dir
		if grid.is_walkable(neighbor) and not danger_map.is_dangerous(neighbor, _profile.wander_safety):
			open_neighbors.append(neighbor)
	if open_neighbors.size() > 0:
		decision["target_cell"] = open_neighbors[randi() % open_neighbors.size()]

	return decision

# ── Escape-after-placement — the core survival logic ──

func _can_safely_escape_after_placement() -> bool:
	return _find_escape_after_place(player.grid_cell, player.water_power) != player.grid_cell

func _find_escape_after_place(bomb_cell: Vector2i, power: int) -> Vector2i:
	# Merge the simulated bomb danger with existing danger map
	var simulated := WaterGridPropagation.calculate_water_burst(bomb_cell, power, grid)
	var sim_danger: Dictionary = {}
	for cell in simulated["affected_cells"]:
		sim_danger[cell] = true
	for cell in danger_map.danger_time_by_cell.keys():
		sim_danger[cell] = true

	# BFS from the bomb cell.  Any non-danger cell reached within max_depth
	# qualifies as a safe escape.  depth is scaled by difficulty.
	var max_depth: int = _profile.escape_depth
	var queue: Array[Vector2i] = [bomb_cell]
	var visited := {bomb_cell: true}
	var distances := {bomb_cell: 0}
	while not queue.is_empty():
		var current: Vector2i = queue.pop_front()
		if not sim_danger.has(current) and current != bomb_cell:
			return current
		if distances[current] >= max_depth:
			continue
		for direction in GameConstants.DIR_VECTORS.values():
			if direction == Vector2i.ZERO:
				continue
			var next: Vector2i = current + direction
			if not visited.has(next) and grid.is_walkable(next, player.overlapping_water_balloon_id):
				visited[next] = true
				distances[next] = distances[current] + 1
				queue.append(next)
	# No escape found — stay put (caller must not place)
	return bomb_cell

# ── Find nearest safe cell (no simulated bomb) ──

func _find_nearest_safe_cell() -> Vector2i:
	var queue: Array[Vector2i] = [player.grid_cell]
	var visited := {player.grid_cell: true}
	while not queue.is_empty():
		var current: Vector2i = queue.pop_front()
		if not danger_map.is_dangerous(current, _profile.danger_horizon):
			return current
		for direction in GameConstants.DIR_VECTORS.values():
			if direction == Vector2i.ZERO:
				continue
			var next: Vector2i = current + direction
			if not visited.has(next) and grid.is_walkable(next, player.overlapping_water_balloon_id):
				visited[next] = true
				queue.append(next)
	return player.grid_cell

# ── Find nearest bubbled enemy to pop ──

func _nearest_bubbled_enemy_cell() -> Vector2i:
	var best := Vector2i(-1, -1)
	var best_distance := INF
	if match_manager == null:
		return best
	for other in match_manager.players.values():
		if other == player or not other.is_alive:
			continue
		if not other.is_in_bubble:
			continue
		if GameSession.play_mode == &"team" and other.team_id == player.team_id:
			continue
		var distance := player.grid_cell.distance_squared_to(other.grid_cell)
		if distance < best_distance:
			best_distance = distance
			best = other.grid_cell
	return best

# ── Item collection ──

func _nearest_safe_item_cell() -> Vector2i:
	if item_manager == null:
		return Vector2i(-1, -1)
	var best := Vector2i(-1, -1)
	var best_distance := INF
	for cell in item_manager.active_items_by_cell.keys():
		if not danger_map.is_dangerous(cell, _profile.item_safety):
			var distance := player.grid_cell.distance_squared_to(cell)
			if distance < best_distance:
				best_distance = distance
				best = cell
	return best

# ── Adjacent to soft block ──

func _is_adjacent_to_soft_block() -> bool:
	for direction in GameConstants.DIR_VECTORS.values():
		if direction != Vector2i.ZERO and grid.is_destructible(player.grid_cell + direction):
			return true
	return false

# ── Enemy nearby ──

func _enemy_is_nearby() -> bool:
	if match_manager == null:
		return false
	var range_sq: int = _profile.attack_range_sq
	for other in match_manager.players.values():
		if other != player and other.is_alive and not other.is_in_bubble:
			if player.grid_cell.distance_squared_to(other.grid_cell) <= range_sq:
				return true
	return false

# ── Killable position: enemy in a corridor we can reach ──

func _enemy_is_in_killable_position() -> bool:
	if match_manager == null:
		return false
	var range_sq: int = _profile.strategic_range_sq
	for other in match_manager.players.values():
		if other == player or not other.is_alive or other.is_in_bubble:
			continue
		if GameSession.play_mode == &"team" and other.team_id == player.team_id:
			continue
		# Count enemy escape routes (walkable non-danger neighbors)
		var escape_count := 0
		for direction in GameConstants.DIR_VECTORS.values():
			if direction == Vector2i.ZERO:
				continue
			var neighbor: Vector2i = other.grid_cell + direction
			if grid.is_walkable(neighbor) and not danger_map.is_dangerous(neighbor, 1.5):
				escape_count += 1
		if escape_count <= _profile.enemy_escape_threshold:
			var distance_sq := player.grid_cell.distance_squared_to(other.grid_cell)
			if distance_sq <= range_sq:
				return true
	return false

# ── Find nearest enemy ──

func _nearest_enemy_cell() -> Vector2i:
	var best := player.grid_cell
	var best_distance := INF
	if match_manager != null:
		for other in match_manager.players.values():
			if other == player or not other.is_alive:
				continue
			if GameSession.play_mode == &"team" and other.team_id == player.team_id:
				continue
			var distance := player.grid_cell.distance_squared_to(other.grid_cell)
			if distance < best_distance:
				best_distance = distance
				best = other.grid_cell
	return best

# ── Find open cell beside a soft block ──

func _nearest_open_cell_beside_soft_block() -> Vector2i:
	var best := Vector2i(-1, -1)
	var best_distance := INF
	for y in range(grid.height):
		for x in range(grid.width):
			var block_cell := Vector2i(x, y)
			if not grid.is_destructible(block_cell):
				continue
			for direction in GameConstants.DIR_VECTORS.values():
				if direction == Vector2i.ZERO:
					continue
				var candidate: Vector2i = block_cell + direction
				if grid.is_walkable(candidate) and not danger_map.is_dangerous(candidate, _profile.block_search_walkable):
					var distance := player.grid_cell.distance_squared_to(candidate)
					if distance < best_distance:
						best_distance = distance
						best = candidate
	return best

# ── BFS pathfinding ──

func _next_path_cell(goal: Vector2i, avoid_danger: bool) -> Vector2i:
	if goal == player.grid_cell or goal == Vector2i(-1, -1):
		return player.grid_cell
	var queue: Array[Vector2i] = [player.grid_cell]
	var came_from := {player.grid_cell: player.grid_cell}
	while not queue.is_empty():
		var current: Vector2i = queue.pop_front()
		if current == goal:
			break
		for direction in GameConstants.DIR_VECTORS.values():
			if direction == Vector2i.ZERO:
				continue
			var next: Vector2i = current + direction
			if came_from.has(next) or not grid.is_walkable(next, player.overlapping_water_balloon_id):
				continue
			if avoid_danger and danger_map.is_dangerous(next, _profile.danger_horizon):
				continue
			came_from[next] = current
			queue.append(next)
	if not came_from.has(goal):
		return player.grid_cell
	var step := goal
	while came_from[step] != player.grid_cell:
		step = came_from[step]
	return step
