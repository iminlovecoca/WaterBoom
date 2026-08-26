extends Node

var failures: Array[String] = []
var checks_run := 0


func _ready() -> void:
	_run.call_deferred()


func _check(condition: bool, code: String, message: String) -> void:
	checks_run += 1
	if condition:
		print("[AGENT MAP PASS] ", code, ": ", message)
	else:
		failures.append("%s: %s" % [code, message])
		push_error("[AGENT MAP FAIL] %s: %s" % [code, message])


func _task_path() -> String:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--agent-task="):
			return argument.trim_prefix("--agent-task=")
	return ""


func _run() -> void:
	var path := _task_path()
	if path.is_empty() or not FileAccess.file_exists(path):
		_check(false, "task_file", "--agent-task must point to the task JSON")
		_finish()
		return
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	if typeof(parsed) != TYPE_DICTIONARY:
		_check(false, "task_json", "task JSON is invalid")
		_finish()
		return
	var contract: Dictionary = {}
	for criterion in parsed.get("acceptance_criteria", []):
		if criterion.get("type", "") == "map_contract":
			contract = criterion
			break
	if contract.is_empty():
		_check(false, "map_contract", "task has no map_contract acceptance criterion")
		_finish()
		return

	var map_id := StringName(contract.get("map_id", ""))
	_check(map_id in MapCatalog.MAP_IDS, "map_id", "%s is a standard map" % map_id)
	if not map_id in MapCatalog.MAP_IDS:
		_finish()
		return
	var definition := MapCatalog.create_map(map_id)
	_check(definition.width == int(contract.get("width", definition.width)), "width", "expected %d, got %d" % [int(contract.get("width", definition.width)), definition.width])
	_check(definition.height == int(contract.get("height", definition.height)), "height", "expected %d, got %d" % [int(contract.get("height", definition.height)), definition.height])
	_check(definition.tile_size == int(contract.get("tile_size", definition.tile_size)), "tile_size", "expected %d, got %d" % [int(contract.get("tile_size", definition.tile_size)), definition.tile_size])

	var counts := {0: 0, 1: 0, 2: 0}
	for row in definition.layout:
		for tile in row:
			counts[tile] = int(counts.get(tile, 0)) + 1
	if contract.has("breakables"):
		_check(counts.get(GameConstants.TileType.DESTRUCTIBLE, 0) == int(contract["breakables"]), "breakables", "expected %d, got %d" % [int(contract["breakables"]), counts.get(GameConstants.TileType.DESTRUCTIBLE, 0)])
	_check(int(counts.get(0, 0)) + int(counts.get(1, 0)) + int(counts.get(2, 0)) == definition.width * definition.height, "cell_total", "layout covers every cell")

	if contract.get("four_way_symmetry", false):
		var symmetric := true
		for y in range(definition.height):
			for x in range(definition.width):
				var tile = definition.layout[y][x]
				if tile != definition.layout[y][definition.width - 1 - x] or tile != definition.layout[definition.height - 1 - y][x]:
					symmetric = false
		_check(symmetric, "symmetry", "layout is mirrored on both axes")

	if contract.has("center"):
		var center: Dictionary = contract["center"]
		var center_size: Array = center.get("size", [4, 4])
		var origin: Array = center.get("origin", [(definition.width - int(center_size[0])) / 2, (definition.height - int(center_size[1])) / 2])
		var allowed: Array[int] = []
		for tile_value in center.get("allowed_tile_types", [GameConstants.TileType.DESTRUCTIBLE]):
			allowed.append(int(tile_value))
		var center_ok := true
		for y in range(int(origin[1]), int(origin[1]) + int(center_size[1])):
			for x in range(int(origin[0]), int(origin[0]) + int(center_size[0])):
				center_ok = center_ok and x >= 0 and y >= 0 and x < definition.width and y < definition.height and definition.layout[y][x] in allowed
		_check(center_ok, "center", "%dx%d footprint at %s uses allowed tile types %s" % [int(center_size[0]), int(center_size[1]), origin, allowed])

	var required_escape := int(contract.get("spawn_safe_cells", 3))
	var spawns_safe := true
	for spawn in definition.spawn_points:
		var reachable: Dictionary = {spawn: true}
		var frontier: Array[Vector2i] = [spawn]
		while not frontier.is_empty() and reachable.size() < required_escape:
			var current: Vector2i = frontier.pop_front()
			for direction in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
				var next: Vector2i = current + direction
				if next.x >= 0 and next.y >= 0 and next.x < definition.width and next.y < definition.height and not reachable.has(next) and definition.layout[next.y][next.x] == GameConstants.TileType.FLOOR:
					reachable[next] = true
					frontier.append(next)
		spawns_safe = spawns_safe and definition.layout[spawn.y][spawn.x] == GameConstants.TileType.FLOOR and reachable.size() >= required_escape
	_check(spawns_safe, "spawn_safe", "all %d spawns have %d connected floor cells" % [definition.spawn_points.size(), required_escape])

	if contract.get("hard_border", false):
		var border_ok := true
		for x in range(definition.width):
			border_ok = border_ok and definition.layout[0][x] == GameConstants.TileType.WALL and definition.layout[definition.height - 1][x] == GameConstants.TileType.WALL
		for y in range(definition.height):
			border_ok = border_ok and definition.layout[y][0] == GameConstants.TileType.WALL and definition.layout[y][definition.width - 1] == GameConstants.TileType.WALL
		_check(border_ok, "hard_border", "outermost cells are hard walls")
	_finish()


func _finish() -> void:
	var report := {"ok": failures.is_empty(), "checks": checks_run, "failures": failures}
	print("AGENT_QA_JSON:", JSON.stringify(report))
	get_tree().quit(0 if failures.is_empty() else 1)
