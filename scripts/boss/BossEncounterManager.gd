class_name BossEncounterManager
extends Node2D

signal round_changed(round_index: int, title: String)
signal boss_health_changed(current: int, maximum: int, phase: int)

var match_manager: MatchManager
var grid: GridManager
var entities: Array[PirateOctopusEnemy] = []
var current_round := 0
var threat: Dictionary = {}
var warning_cells: Dictionary = {}
var encounter_finished := false
var summon_cooldown := 0.0
var summon_wave := 0

func initialize(manager: MatchManager, grid_manager: GridManager) -> void:
	match_manager = manager
	grid = grid_manager
	z_index = 6
	if not EventBus.match_started.is_connected(_on_match_started):
		EventBus.match_started.connect(_on_match_started)

func _exit_tree() -> void:
	if EventBus.match_started.is_connected(_on_match_started):
		EventBus.match_started.disconnect(_on_match_started)

func _process(delta: float) -> void:
	for cell in warning_cells.keys():
		warning_cells[cell] = float(warning_cells[cell]) - delta
		if warning_cells[cell] <= 0.0:
			warning_cells.erase(cell)
	_process_trapped_contacts()
	if current_round == 4 and not encounter_finished:
		var boss := _active_boss()
		if boss != null and _active_minion_count() == 0:
			summon_cooldown -= delta
			if summon_cooldown <= 0.0:
				_summon_boss_pet_wave(boss)
	queue_redraw()

func _draw() -> void:
	if grid == null:
		return
	for cell in warning_cells:
		var center := grid.grid_to_world(cell) - global_position
		var pulse := 0.28 + sin(Time.get_ticks_msec() * 0.018) * 0.12
		draw_circle(center, 15.0, Color(1.0, 0.18, 0.12, pulse))
		draw_arc(center, 17.0, 0.0, TAU, 24, Color(1.0, 0.78, 0.22, 0.9), 2.0)

func _on_match_started() -> void:
	if GameSession.play_mode == &"boss":
		start_round(1)

func start_round(round_index: int) -> void:
	current_round = round_index
	match_manager.apply_boss_round_layout(current_round)
	grid = match_manager.grid_manager
	if current_round <= 3:
		round_changed.emit(current_round, "ROUND %d • LÍNH MỰC" % current_round)
		var counts := [4, 5, 6]
		for index in range(counts[current_round - 1]):
			spawn_enemy(false, _spawn_cell_for(index, counts[current_round - 1]))
	else:
		round_changed.emit(4, "ROUND 4 • BẠCH TUỘC HẢI TẶC")
		spawn_enemy(true, Vector2i(12, 12))
		summon_wave = 0
		summon_cooldown = 2.0

func spawn_enemy(as_boss: bool, cell: Vector2i) -> PirateOctopusEnemy:
	var enemy := PirateOctopusEnemy.new()
	add_child(enemy)
	enemy.initialize(self, as_boss, current_round, _nearest_open_cell(cell))
	enemy.defeated.connect(_on_enemy_defeated)
	entities.append(enemy)
	return enemy

func _spawn_cell_for(index: int, total: int) -> Vector2i:
	var cells := [Vector2i(13, 2), Vector2i(13, 13), Vector2i(8, 2), Vector2i(8, 13), Vector2i(3, 13), Vector2i(12, 7), Vector2i(4, 7)]
	return cells[index % mini(total, cells.size())]

func _nearest_open_cell(origin: Vector2i) -> Vector2i:
	if grid.is_valid_cell(origin) and not grid.is_blocked(origin):
		return origin
	for radius in range(1, 8):
		for y in range(origin.y - radius, origin.y + radius + 1):
			for x in range(origin.x - radius, origin.x + radius + 1):
				var cell := Vector2i(x, y)
				if grid.is_valid_cell(cell) and not grid.is_blocked(cell):
					return cell
	return Vector2i(8, 8)

func damage_entities_in_cells(cells: Array, owner_id: int) -> int:
	var damaged := 0
	for enemy in entities.duplicate():
		if not is_instance_valid(enemy) or enemy.health <= 0:
			continue
		if grid.world_to_grid(enemy.global_position) in cells:
			enemy.take_water_damage(1, owner_id)
			damaged += 1
	return damaged

func _process_trapped_contacts() -> void:
	for enemy in entities.duplicate():
		if not is_instance_valid(enemy) or not enemy.trapped_in_bubble:
			continue
		for player in match_manager.players.values():
			if player != null and player.is_alive and not player.is_in_bubble:
				var contact_radius := 48.0 if enemy.is_boss else 26.0
				if player.global_position.distance_to(enemy.global_position) <= contact_radius:
					enemy.pop_trapped_by_player()
					break

func _active_boss() -> PirateOctopusEnemy:
	for enemy in entities:
		if is_instance_valid(enemy) and enemy.is_boss and enemy.health > 0:
			return enemy
	return null

func _active_minion_count() -> int:
	var count := 0
	for enemy in entities:
		if is_instance_valid(enemy) and not enemy.is_boss and enemy.health > 0:
			count += 1
	return count

func _summon_boss_pet_wave(boss: PirateOctopusEnemy) -> void:
	summon_wave += 1
	var count := 4 + ((summon_wave - 1) % 3)
	var boss_cell := grid.world_to_grid(boss.global_position)
	warn_cross(boss_cell, 2, 0.8)
	for index in range(count):
		spawn_enemy(false, _spawn_cell_for(index + summon_wave, count))
	summon_cooldown = 999.0 # Armed again only after the complete wave is cleared.

func register_threat(owner_id: int, amount: int) -> void:
	threat[owner_id] = int(threat.get(owner_id, 0)) + amount

func pick_target(from_position: Vector2) -> PlayerController:
	var best: PlayerController
	var best_score := -INF
	for player_id in match_manager.players:
		var player: PlayerController = match_manager.players[player_id]
		if player == null or not player.is_alive:
			continue
		var score := float(threat.get(player_id, 0)) * 1000.0 - from_position.distance_to(player.global_position)
		if score > best_score:
			best_score = score
			best = player
	return best

func _on_enemy_defeated(enemy: PirateOctopusEnemy) -> void:
	entities.erase(enemy)
	if encounter_finished:
		return
	if current_round == 4:
		if enemy.is_boss:
			encounter_finished = true
			match_manager.finish_boss_encounter(true)
		elif _active_minion_count() == 0 and _active_boss() != null:
			summon_cooldown = 4.0
		return
	if not entities.is_empty():
		return
	if current_round < 4:
		var next_round := current_round + 1
		round_changed.emit(current_round, "ROUND %d HOÀN THÀNH!" % current_round)
		get_tree().create_timer(1.5).timeout.connect(func(): start_round(next_round))

func next_grid_direction(from_position: Vector2, target_position: Vector2) -> Vector2:
	var start := grid.world_to_grid(from_position)
	var goal := grid.world_to_grid(target_position)
	if start == goal:
		return from_position.direction_to(target_position)
	var frontier: Array[Vector2i] = [start]
	var came_from: Dictionary = {start: start}
	var found := false
	while not frontier.is_empty() and came_from.size() < grid.width * grid.height:
		var current: Vector2i = frontier.pop_front()
		if current == goal:
			found = true
			break
		for direction: Vector2i in [Vector2i.UP, Vector2i.LEFT, Vector2i.RIGHT, Vector2i.DOWN]:
			var next := current + direction
			if came_from.has(next) or not grid.is_valid_cell(next):
				continue
			if grid.is_blocked(next) and next != goal:
				continue
			came_from[next] = current
			frontier.append(next)
	if not found and not came_from.has(goal):
		return Vector2.ZERO
	var step := goal
	while came_from.has(step) and came_from[step] != start and came_from[step] != step:
		step = came_from[step]
	var center := grid.grid_to_world(step)
	var delta := center - from_position
	if delta.length() < 2.0:
		return Vector2(step - start).normalized()
	return delta.normalized()

func warn_cross(origin: Vector2i, radius: int, duration: float) -> void:
	warning_cells[origin] = duration
	for direction: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
		for step in range(1, radius + 1):
			var cell: Vector2i = origin + direction * step
			if not grid.is_valid_cell(cell) or grid.is_blocked(cell):
				break
			warning_cells[cell] = duration

func boss_cross_burst(origin: Vector2i, radius: int) -> void:
	var cells: Array = [origin]
	var rays := {"left": [], "right": [], "up": [], "down": []}
	var directions := {"left": Vector2i.LEFT, "right": Vector2i.RIGHT, "up": Vector2i.UP, "down": Vector2i.DOWN}
	for key in directions:
		for step in range(1, radius + 1):
			var cell: Vector2i = origin + directions[key] * step
			if not grid.is_valid_cell(cell) or grid.is_blocked(cell):
				break
			rays[key].append({"cell": cell, "is_end": step == radius})
			cells.append(cell)
	_emit_hostile_water(origin, rays, cells)

func start_spiral_skill(boss: PirateOctopusEnemy) -> void:
	_spiral_sequence(boss)

func _spiral_sequence(boss: PirateOctopusEnemy) -> void:
	if not is_instance_valid(boss):
		return
	var origin := grid.world_to_grid(boss.global_position)
	for pulse in range(5):
		if not is_instance_valid(boss) or boss.health <= 0:
			return
		var cells: Array = []
		var angle_offset := pulse % 4
		var directions := [Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT, Vector2i.UP]
		for arm in range(4):
			var direction: Vector2i = directions[(arm + angle_offset) % 4]
			var cell := origin + direction * (pulse + 1)
			if grid.is_valid_cell(cell) and not grid.is_blocked(cell) and _line_clear(origin, cell):
				warning_cells[cell] = 0.62
				cells.append(cell)
		await get_tree().create_timer(0.62).timeout
		var rays := {"left": [], "right": [], "up": [], "down": []}
		_emit_hostile_water(origin, rays, cells)
		await get_tree().create_timer(0.22).timeout

func _emit_hostile_water(origin: Vector2i, rays: Dictionary, cells: Array) -> void:
	for cell in cells:
		match_manager.water_balloon_manager.active_water_cells[cell] = 0.65
	if rays["left"].is_empty() and rays["right"].is_empty() and rays["up"].is_empty() and rays["down"].is_empty():
		for cell in cells:
			match_manager.water_stream_renderer.spawn_water_burst({"center": [cell], "left": [], "right": [], "up": [], "down": []}, grid, &"dark")
	else:
		rays["center"] = [origin]
		match_manager.water_stream_renderer.spawn_water_burst(rays, grid, &"dark")
	match_manager.check_water_cells(cells)

func _line_clear(origin: Vector2i, target: Vector2i) -> bool:
	var delta := target - origin
	var direction := Vector2i(signi(delta.x), signi(delta.y))
	var steps := maxi(absi(delta.x), absi(delta.y))
	for step in range(1, steps + 1):
		var cell := origin + direction * step
		# Walls, breakable blocks, and decoration footprints all live in the
		# authoritative blocked grid, so hostile water can never pass behind them.
		if not grid.is_valid_cell(cell) or grid.is_blocked(cell):
			return false
	return true
