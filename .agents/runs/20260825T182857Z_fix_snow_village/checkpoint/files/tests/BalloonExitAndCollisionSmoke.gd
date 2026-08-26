extends Node

func _ready() -> void:
	_run.call_deferred()

func _run() -> void:
	var definition := MapDefinition.new()
	definition.width = 7
	definition.height = 7
	definition.tile_size = 40
	definition.layout.clear()
	for y in range(7):
		var row := PackedInt32Array()
		row.resize(7)
		for x in range(7):
			row[x] = GameConstants.TileType.WALL if x == 0 or y == 0 or x == 6 or y == 6 else GameConstants.TileType.FLOOR
		definition.layout.append(row)
	var grid := GridManager.new()
	grid.initialize(definition)
	var balloon_cell := Vector2i(3, 3)
	var balloon_id := 77
	grid.register_water_balloon_cell(balloon_cell, balloon_id)
	var position := grid.grid_to_world(balloon_cell)
	for _step in range(14):
		position = grid.compute_movement_with_corner_sliding(position, Vector2(4, 0), balloon_id)
	var left_origin := grid.world_to_grid(position) == Vector2i(4, 3)
	var before_reentry := position
	for _step in range(14):
		position = grid.compute_movement_with_corner_sliding(position, Vector2(-4, 0), -1)
	var reentry_blocked := grid.world_to_grid(position) == Vector2i(4, 3) and position.x > grid.grid_to_world(balloon_cell).x + 12.0
	var player := load("res://scenes/characters/Player.tscn").instantiate() as PlayerController
	add_child(player)
	player.is_local_control = false
	player.initialize(1, balloon_cell, grid, null)
	player.overlapping_water_balloon_id = balloon_id
	player.overlapping_water_balloon_cell = balloon_cell
	for _step in range(18):
		player.apply_movement_intent(Vector2.RIGHT, 0.03)
		await get_tree().physics_frame
	var body_fully_exited := player.global_position.x >= grid.grid_to_world(balloon_cell).x + 32.0
	var pass_through_released := player.overlapping_water_balloon_id == -1
	print("[BALLOON PASS] owner leaves placed balloon cell" if left_origin else "[BALLOON FAIL] owner could not leave placed balloon cell")
	print("[BALLOON PASS] re-entry locks after leaving" if reentry_blocked else "[BALLOON FAIL] owner re-entered placed balloon cell")
	print("[BALLOON PASS] real PlayerController clears its full body" if body_fully_exited else "[BALLOON FAIL] real PlayerController remains pinned on its own balloon")
	print("[BALLOON PASS] pass-through closes only after full exit" if pass_through_released else "[BALLOON FAIL] pass-through state never closed")
	var passed := left_origin and reentry_blocked and before_reentry != position and body_fully_exited and pass_through_released
	print("BALLOON_EXIT_RESULT: %s" % ("PASS" if passed else "FAIL"))
	get_tree().quit(0 if passed else 1)
