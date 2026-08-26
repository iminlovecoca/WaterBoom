extends Node

var failures: Array[String] = []
var checks_run := 0

func _ready() -> void:
	_run.call_deferred()

func check(condition: bool, label: String) -> void:
	checks_run += 1
	if condition:
		print("[MAP LAYOUT PASS] ", label)
	else:
		print("[MAP LAYOUT FAIL] ", label)
		failures.append(label)

func _run() -> void:
	for map_id in MapCatalog.MAP_IDS:
		GameSession.configure_solo(1, GameConstants.BotDifficulty.NORMAL, map_id)
		var arena := load("res://scenes/match/MatchArena.tscn").instantiate() as MatchManager
		add_child(arena)
		await get_tree().process_frame
		# Keep this smoke test deterministic: it validates construction/navigation
		# data, not bot combat. A bot ending the match would abort the remaining maps.
		arena.current_state = GameConstants.MatchState.WAITING
		for player in arena.players.values():
			player.set_process(false)
			player.set_physics_process(false)
		for controller in arena.bot_controllers:
			controller.set_process(false)
			controller.set_physics_process(false)
		check(arena.grid_manager != null, "%s initializes gameplay grid" % map_id)
		check(arena.map_definition.width == 16 and arena.map_definition.height == 16, "%s provides the standard 16x16 arena" % map_id)
		check(arena.grid_manager.tile_size > 40, "%s enlarges cells beyond 40px to fill the available arena" % map_id)
		var layout := arena.map_definition.layout
		var expected_corner_spawns: Array[Vector2i] = [
			Vector2i(1, 1), Vector2i(14, 14), Vector2i(14, 1), Vector2i(1, 14)
		]
		check(
			arena.map_definition.spawn_points.slice(0, 4) == expected_corner_spawns,
			"%s keeps full character sprites one cell inside the frame-free 16x16 corners" % map_id
		)
		var symmetric := true
		var mismatch := ""
		for y in range(arena.map_definition.height):
			for x in range(arena.map_definition.width):
				var tile = layout[y][x]
				if tile != layout[y][arena.map_definition.width - 1 - x] or tile != layout[arena.map_definition.height - 1 - y][x]:
					symmetric = false
					mismatch = "%s=%s, mirror-x=%s, mirror-y=%s" % [Vector2i(x, y), tile, layout[y][arena.map_definition.width - 1 - x], layout[arena.map_definition.height - 1 - y][x]]
					break
			if not symmetric:
				break
		check(symmetric, "%s keeps tile and breakable placement balanced in all four corners%s" % [map_id, " (" + mismatch + ")" if not mismatch.is_empty() else ""])
		var expected_decor_count := MapDecorationCatalog.specs_for_map(map_id).size()
		check(expected_decor_count == 0 and arena.arena_map.decorations_layer.get_child_count() == 0, "%s removes the legacy giant centre decoration" % map_id)
		var specs := MapDecorationCatalog.specs_for_map(map_id)
		check(specs.is_empty(), "%s reserves no hidden landmark footprint" % map_id)
		var occupied_decor_cells: Dictionary = {}
		var decor_overlap := false
		for spec in specs:
			var decor_origin: Vector2i = spec["cell"]
			var decor_size: Vector2i = spec["size"]
			for decor_y in range(decor_origin.y, decor_origin.y + decor_size.y):
				for decor_x in range(decor_origin.x, decor_origin.x + decor_size.x):
					var decor_cell := Vector2i(decor_x, decor_y)
					decor_overlap = decor_overlap or occupied_decor_cells.has(decor_cell)
					occupied_decor_cells[decor_cell] = true
		check(not decor_overlap, "%s has no overlapping gameplay decoration footprints" % map_id)
		var spawn_safe := true
		for spawn in arena.map_definition.spawn_points:
			var reachable: Dictionary = {spawn: true}
			var frontier: Array[Vector2i] = [spawn]
			while not frontier.is_empty() and reachable.size() < 3:
				var current: Vector2i = frontier.pop_front()
				for direction in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
					var neighbour: Vector2i = current + direction
					if neighbour.x >= 0 and neighbour.y >= 0 and neighbour.x < 16 and neighbour.y < 16 and not reachable.has(neighbour) and layout[neighbour.y][neighbour.x] == GameConstants.TileType.FLOOR:
						reachable[neighbour] = true
						frontier.append(neighbour)
			spawn_safe = spawn_safe and layout[spawn.y][spawn.x] == GameConstants.TileType.FLOOR and reachable.size() >= 3
		check(spawn_safe, "%s keeps every spawn clear with a connected escape route" % map_id)
		var perimeter_wall_count := 0
		for border_index in range(16):
			perimeter_wall_count += 1 if layout[0][border_index] == GameConstants.TileType.WALL else 0
			perimeter_wall_count += 1 if layout[15][border_index] == GameConstants.TileType.WALL else 0
			if border_index not in [0, 15]:
				perimeter_wall_count += 1 if layout[border_index][0] == GameConstants.TileType.WALL else 0
				perimeter_wall_count += 1 if layout[border_index][15] == GameConstants.TileType.WALL else 0
		check(perimeter_wall_count == 60, "%s uses the outer row as a themed hard-block visual safety buffer" % map_id)
		check(DirAccess.dir_exists_absolute("res://assets/visual_overhaul_v2/maps/%s/runtime" % map_id), "%s resolves from the V2 runtime asset tree" % map_id)
		var soft_count := 0
		var floor_count := 0
		for count_row in layout:
			for count_tile in count_row:
				soft_count += 1 if count_tile == GameConstants.TileType.DESTRUCTIBLE else 0
				floor_count += 1 if count_tile == GameConstants.TileType.FLOOR else 0
		check(soft_count == 128, "%s fills every non-spawn/non-hard cell with exactly 128 destructible blocks" % map_id)
		check(floor_count == 28, "%s reserves four L pockets and four symmetric team pockets only" % map_id)
		var l_pockets_valid := true
		for spawn_index in range(4):
			var spawn: Vector2i = arena.map_definition.spawn_points[spawn_index]
			var inward_x := 1 if spawn.x < 8 else -1
			var inward_y := 1 if spawn.y < 8 else -1
			var pocket_cells: Array[Vector2i]
			if spawn.y in [1, 14]:
				pocket_cells = [spawn, spawn + Vector2i(inward_x, 0), spawn + Vector2i(inward_x, inward_y)]
			else:
				pocket_cells = [spawn, spawn + Vector2i(0, inward_y), spawn + Vector2i(inward_x, inward_y)]
			for pocket_cell in pocket_cells:
				l_pockets_valid = l_pockets_valid and layout[pocket_cell.y][pocket_cell.x] == GameConstants.TileType.FLOOR
		check(l_pockets_valid, "%s gives all four corner players an exact connected three-cell L spawn pocket" % map_id)
		var center_hard_count := 0
		var center_soft_count := 0
		for center_y in range(6, 10):
			for center_x in range(6, 10):
				center_hard_count += 1 if layout[center_y][center_x] == GameConstants.TileType.WALL else 0
				center_soft_count += 1 if layout[center_y][center_x] == GameConstants.TileType.DESTRUCTIBLE else 0
		check(center_hard_count == 0 and center_soft_count == 16, "%s keeps the complete central 4x4 field breakable for straight routes" % map_id)
		arena.queue_free()
		await get_tree().process_frame
		await get_tree().process_frame
	print("MAP_LAYOUT_SMOKE_RESULT: %d passed | %d failed" % [checks_run - failures.size(), failures.size()])
	get_tree().quit(0 if failures.is_empty() else 1)
