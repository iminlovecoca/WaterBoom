class_name MapValidator
extends RefCounted

static func validate(definition: MapDefinition) -> Array[String]:
	var errors: Array[String] = []
	if definition.width < 7 or definition.height < 7:
		errors.append("Map dimensions must be at least 7x7.")
	if definition.spawn_points.size() < 2:
		errors.append("At least two spawn points are required.")
	if definition.spawn_points.size() > definition.max_players:
		errors.append("Spawn count exceeds max_players.")
	if definition.layout.size() != definition.height:
		errors.append("Layout row count does not match height.")
		return errors
	var seen := {}
	for spawn in definition.spawn_points:
		if spawn.x < 0 or spawn.x >= definition.width or spawn.y < 0 or spawn.y >= definition.height:
			errors.append("Spawn %s is outside the map." % spawn)
			continue
		if seen.has(spawn):
			errors.append("Duplicate spawn at %s." % spawn)
		seen[spawn] = true
		if definition.layout[spawn.y][spawn.x] != GameConstants.TileType.FLOOR:
			errors.append("Spawn %s is blocked." % spawn)
		# A corner spawn deliberately sits at the end of a three-cell L. Validate
		# the connected escape route instead of requiring two cells directly beside
		# the player (which would force a plus-shaped empty area).
		var reachable_floor: Dictionary = {spawn: true}
		var frontier: Array[Vector2i] = [spawn]
		while not frontier.is_empty() and reachable_floor.size() < 3:
			var current: Vector2i = frontier.pop_front()
			for direction in GameConstants.DIR_VECTORS.values():
				var cell: Vector2i = current + direction
				if direction == Vector2i.ZERO or reachable_floor.has(cell):
					continue
				if cell.x >= 0 and cell.x < definition.width and cell.y >= 0 and cell.y < definition.height and definition.layout[cell.y][cell.x] == GameConstants.TileType.FLOOR:
					reachable_floor[cell] = true
					frontier.append(cell)
		if reachable_floor.size() < 3:
			errors.append("Spawn %s needs a connected three-cell escape route." % spawn)
	return errors
