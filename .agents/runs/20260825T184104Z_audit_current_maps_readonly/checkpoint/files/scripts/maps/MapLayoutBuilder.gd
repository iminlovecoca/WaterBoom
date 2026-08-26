class_name MapLayoutBuilder
extends RefCounted

const LEGO_LAYOUT: Array[String] = [
	"BBBBBBBBBBBBBBB",
	"B...XXRRRXX...B",
	"B.OXX.RRR.XXO.B",
	"B.XO.XRRRX.OX.B",
	"BXX.OXRRRXO.XXB",
	"BX.XX.RRR.XX.XB",
	"BRRRRRRRRRRRRRB",
	"BRRRRRRRRRRRRRB",
	"BRRRRRRRRRRRRRB",
	"BX.XX.RRR.XX.XB",
	"BXX.OXRRRXO.XXB",
	"B.XO.XRRRX.OX.B",
	"B.OXX.RRR.XXO.B",
	"B...XXRRRXX...B",
	"BBBBBBBBBBBBBBB"
]

const PLANNING_PLAZA_LAYOUT: Array[String] = [
	"BBBBBBBBBBBBBBB",
	"B..XX.X.X.XX..B",
	"B.XHX.X.X.XHX.B",
	"BXXXX.X.X.XXXXB",
	"B.XH.XX.XX.HX.B",
	"BXX.X.....X.XXB",
	"B.X.X.FFF.X.X.B",
	"B.....FFF.....B",
	"B.X.X.FFF.X.X.B",
	"BXX.X.....X.XXB",
	"B.XH.XX.XX.HX.B",
	"BXXXX.X.X.XXXXB",
	"B.XHX.X.X.XHX.B",
	"B..XX.X.X.XX..B",
	"BBBBBBBBBBBBBBB"
]

const AQUA_LAYOUT: Array[String] = [
	"BBBBBBBBBBBBBBBB",
	"BSSWXXXFFXXXWSSB",
	"BSDWXXXBBXXXWDSB",
	"BXXSXXXXXXXXSXXB",
	"BXXXCBXXXXBCXXXB",
	"BXXXB.WWWW.BXXXB",
	"BXXXXWWWWWWXXXXB",
	"BFBXXWOOOOWXXBFB",
	"BFBXXWOOOOWXXBFB",
	"BXXXXWOOOOWXXXXB",
	"BXXXB.WWWW.BXXXB",
	"BXXXCBXXXXBCXXXB",
	"BXXSXXXXXXXXSXXB",
	"BSDWXXXBBXXXWDSB",
	"BSSWXXXFFXXXWSSB",
	"BBBBBBBBBBBBBBBB"
]

static func build(definition: MapDefinition) -> void:
	if definition.id in [&"training_plaza", &"aqua_park", &"lego_city", &"egypt_temple", &"pirate_harbor", &"snow_village"]:
		_build_full_grid_dense(definition)
		return

	definition.layout.clear()
	for y in range(definition.height):
		var row := PackedInt32Array()
		row.resize(definition.width)
		for x in range(definition.width):
			var cell := Vector2i(x, y)
			var pattern_cell := _canonical_pattern_cell(cell, definition)
			if _is_border(cell, definition):
				row[x] = GameConstants.TileType.WALL
			elif _is_signature_wall(definition.id, pattern_cell):
				row[x] = GameConstants.TileType.WALL
			elif _should_place_soft_block(definition, pattern_cell, cell):
				row[x] = GameConstants.TileType.DESTRUCTIBLE
			else:
				row[x] = GameConstants.TileType.FLOOR
		definition.layout.append(row)
	_clear_signature_routes(definition)
	_clear_spawn_areas(definition)
	_restore_decoration_anchors(definition)

static func _build_training_plaza(definition: MapDefinition) -> void:
	definition.width = PLANNING_PLAZA_LAYOUT[0].length()
	definition.height = PLANNING_PLAZA_LAYOUT.size()
	definition.layout.clear()
	for y in range(definition.height):
		var row := PackedInt32Array()
		row.resize(definition.width)
		for x in range(definition.width):
			var c = PLANNING_PLAZA_LAYOUT[y][x]
			if c == 'B' or c == 'F' or c == 'H' or c == 'P':
				row[x] = GameConstants.TileType.WALL
			elif c == 'X' or c == 'W':
				row[x] = GameConstants.TileType.DESTRUCTIBLE
			else:
				row[x] = GameConstants.TileType.FLOOR
		definition.layout.append(row)
	# The authored plaza blueprint already contains four safe spawn pockets.
	# Do not clear a generic plus-shape here: it would erode the intentional
	# high crate density and make the layout procedural again.
	_restore_decoration_anchors(definition)

static func _build_lego_city(definition: MapDefinition) -> void:
	definition.width = LEGO_LAYOUT[0].length()
	definition.height = LEGO_LAYOUT.size()
	definition.layout.clear()
	for y in range(definition.height):
		var row := PackedInt32Array()
		row.resize(definition.width)
		for x in range(definition.width):
			var c = LEGO_LAYOUT[y][x]
			if c == 'B' or c == 'b' or c == 'O':
				row[x] = GameConstants.TileType.WALL
			elif c == 'X':
				row[x] = GameConstants.TileType.DESTRUCTIBLE
			else:
				row[x] = GameConstants.TileType.FLOOR
		definition.layout.append(row)
	_clear_spawn_areas(definition)
	_restore_decoration_anchors(definition)

static func _build_aqua_park(definition: MapDefinition) -> void:
	definition.width = AQUA_LAYOUT[0].length()
	definition.height = AQUA_LAYOUT.size()
	definition.layout.clear()
	for y in range(definition.height):
		var row := PackedInt32Array()
		row.resize(definition.width)
		for x in range(definition.width):
			var c = AQUA_LAYOUT[y][x]
			if c == 'B' or c == 'W':
				row[x] = GameConstants.TileType.WALL if c == 'B' else GameConstants.TileType.FLOOR
			elif c == 'X':
				row[x] = GameConstants.TileType.DESTRUCTIBLE
			else:
				row[x] = GameConstants.TileType.FLOOR
		definition.layout.append(row)
	_clear_spawn_areas(definition)
	_restore_decoration_anchors(definition)

static func _build_full_grid_dense(definition: MapDefinition) -> void:
	# Every standard arena owns all 256 cells. Apart from the eight authored
	# three-cell spawn pockets, every cell is occupied by a hard or breakable block.
	# This gives all maps the same density and removes the long empty avenues that
	# made players detour around the centre.
	definition.width = 16
	definition.height = 16
	definition.layout.clear()
	for y in range(definition.height):
		var row := PackedInt32Array()
		row.resize(definition.width)
		for x in range(definition.width):
			row[x] = GameConstants.TileType.DESTRUCTIBLE
		definition.layout.append(row)

	var reserved_floor: Dictionary = {}
	for spawn_index in range(definition.spawn_points.size()):
		var spawn: Vector2i = definition.spawn_points[spawn_index]
		var inward_x := 1 if spawn.x < definition.width / 2 else -1
		var inward_y := 1 if spawn.y < definition.height / 2 else -1
		# The four corner players use exactly three walkable cells in a connected L
		# path. The optional 5-8 player team spawns use a symmetric 2x2 pocket, which
		# keeps all four edges balanced and gives both immediate escape directions.
		var safe_offsets: Array[Vector2i]
		if spawn_index < 4:
			safe_offsets = [Vector2i.ZERO, Vector2i(inward_x, 0), Vector2i(inward_x, inward_y)]
		elif spawn.y in [1, definition.height - 2]:
			safe_offsets = [Vector2i.ZERO, Vector2i(inward_x, 0), Vector2i(0, inward_y), Vector2i(inward_x, inward_y)]
		else:
			safe_offsets = [Vector2i.ZERO, Vector2i(0, inward_y), Vector2i(inward_x, 0), Vector2i(inward_x, inward_y)]
		for offset in safe_offsets:
			var safe_cell: Vector2i = spawn + offset
			if safe_cell.x >= 0 and safe_cell.y >= 0 and safe_cell.x < definition.width and safe_cell.y < definition.height:
				reserved_floor[safe_cell] = true

	# Ten four-way orbits create 40 indestructible blocks. The complete central
	# 4x4 stays breakable so a straight route can always be opened through it.
	var hard_origins: Array[Vector2i] = []
	match definition.id:
		&"lego_city":
			hard_origins = [Vector2i(2, 3), Vector2i(3, 2), Vector2i(4, 4), Vector2i(5, 2), Vector2i(2, 5), Vector2i(5, 5), Vector2i(3, 6), Vector2i(6, 3), Vector2i(4, 6), Vector2i(3, 3)]
		&"egypt_temple":
			hard_origins = [Vector2i(5, 3), Vector2i(5, 2), Vector2i(3, 4), Vector2i(4, 3), Vector2i(2, 6), Vector2i(6, 2), Vector2i(5, 5), Vector2i(3, 6), Vector2i(4, 6), Vector2i(3, 3)]
		&"pirate_harbor":
			hard_origins = [Vector2i(2, 3), Vector2i(4, 2), Vector2i(5, 4), Vector2i(3, 5), Vector2i(2, 6), Vector2i(6, 2), Vector2i(4, 6), Vector2i(6, 4), Vector2i(5, 5), Vector2i(3, 3)]
		&"snow_village":
			hard_origins = [Vector2i(2, 4), Vector2i(4, 2), Vector2i(5, 5), Vector2i(3, 6), Vector2i(6, 3), Vector2i(4, 5), Vector2i(5, 2), Vector2i(2, 5), Vector2i(4, 6), Vector2i(3, 3)]
		&"aqua_park":
			hard_origins = [Vector2i(3, 4), Vector2i(4, 2), Vector2i(2, 4), Vector2i(4, 4), Vector2i(5, 2), Vector2i(2, 5), Vector2i(5, 5), Vector2i(3, 6), Vector2i(6, 3), Vector2i(3, 3)]
		_:
			hard_origins = [Vector2i(3, 4), Vector2i(4, 2), Vector2i(2, 4), Vector2i(4, 4), Vector2i(5, 2), Vector2i(2, 5), Vector2i(5, 5), Vector2i(3, 6), Vector2i(6, 3), Vector2i(3, 3)]
	var hard_cells: Dictionary = {}
	for origin in hard_origins:
		for hard_cell in _four_way_orbit(origin, definition):
			if not reserved_floor.has(hard_cell):
				hard_cells[hard_cell] = true
	# The outermost gameplay row is a regular themed hard-block safety buffer,
	# not a decorative frame. It keeps the full chibi body inside the viewport
	# even after nearby crates are destroyed and the player walks upward.
	for edge_x in range(definition.width):
		hard_cells[Vector2i(edge_x, 0)] = true
		hard_cells[Vector2i(edge_x, definition.height - 1)] = true
	for edge_y in range(1, definition.height - 1):
		hard_cells[Vector2i(0, edge_y)] = true
		hard_cells[Vector2i(definition.width - 1, edge_y)] = true

	for hard_cell in hard_cells:
		definition.layout[hard_cell.y][hard_cell.x] = GameConstants.TileType.WALL
	for safe_cell in reserved_floor:
		definition.layout[safe_cell.y][safe_cell.x] = GameConstants.TileType.FLOOR

	var breakable_count := 0
	for row in definition.layout:
		for tile in row:
			breakable_count += 1 if tile == GameConstants.TileType.DESTRUCTIBLE else 0
	var expected_breakable := definition.width * definition.height - reserved_floor.size() - hard_cells.size()
	if breakable_count != expected_breakable:
		push_error("%s must contain %d destructible blocks, got %d" % [definition.id, expected_breakable, breakable_count])

static func _four_way_orbit(cell: Vector2i, definition: MapDefinition) -> Array[Vector2i]:
	return [
		cell,
		Vector2i(definition.width - 1 - cell.x, cell.y),
		Vector2i(cell.x, definition.height - 1 - cell.y),
		Vector2i(definition.width - 1 - cell.x, definition.height - 1 - cell.y),
	]

static func _rework_candidate_score(map_id: StringName, cell: Vector2i) -> int:
	var motif := absi(cell.x * 37 + cell.y * 61)
	match map_id:
		&"lego_city":
			# Preserve the broadest possible four-way city avenue around the landmark.
			return motif + (900 if cell.x >= 6 or cell.y >= 6 else 0)
		&"egypt_temple":
			# Diagonal processional gaps make the temple layout distinct from Plaza.
			return motif + (900 if cell.x == cell.y or cell.x + cell.y in [8, 9] else 0)
		&"pirate_harbor":
			# Long orthogonal deck lanes and staggered cargo bays keep the harbor
			# readable while the selected 26 orbits still provide 104 crates.
			return motif + (900 if cell.x in [3, 7] or cell.y in [4, 7] else 0)
		&"snow_village":
			# Preserve a broad ice cross and small diagonal village approaches.
			return motif + (900 if cell.x in [5, 7] or cell.y in [5, 7] or cell.x == cell.y else 0)
		_:
			# Plaza keeps orthogonal garden paths and an open approach to the fountain.
			return motif + (900 if cell.x in [4, 7] or cell.y in [4, 7] else 0)

static func _is_border(cell: Vector2i, definition: MapDefinition) -> bool:
	return cell.x == 0 or cell.y == 0 or cell.x == definition.width - 1 or cell.y == definition.height - 1

static func _canonical_pattern_cell(cell: Vector2i, definition: MapDefinition) -> Vector2i:
	return Vector2i(
		mini(cell.x, definition.width - 1 - cell.x),
		mini(cell.y, definition.height - 1 - cell.y)
	)

static func _is_signature_wall(map_id: StringName, cell: Vector2i) -> bool:
	var x := cell.x
	var y := cell.y
	# Keep the 6x6 courtyard around the 4x4 centerpiece completely clear of hard walls
	if x >= 4 and x <= 11 and y >= 4 and y <= 11:
		return false

	match map_id:
		&"aqua_park":
			return (x in [4, 11] and y not in [3, 6, 9]) \
				or (y in [3, 12] and x in [2, 6, 9, 13])
		&"pirate_harbor":
			return (y in [2, 13] and x in [3, 7, 8, 12]) \
				or (x in [3, 12] and y in [3, 7, 8, 12])
		&"snow_village":
			return (x in [3, 12] and y in [2, 13]) \
				or (y in [2, 13] and x in [6, 9])
		&"lego_city":
			return (x in [3, 11] and y in [2, 4, 10, 12]) \
				or (y in [3, 11] and x in [2, 4, 10, 12])
		&"egypt_temple":
			return (y in [3, 12] and x not in [3, 7, 8, 12]) \
				or (x in [3, 12] and y in [2, 13])
		&"training_plaza":
			return (x in [3, 12] and y in [3, 12])
		_:
			return x % 2 == 0 and y % 2 == 0

static func _should_place_soft_block(definition: MapDefinition, pattern_cell: Vector2i, cell: Vector2i) -> bool:
	var x := cell.x
	var y := cell.y
	if definition.id == &"snow_village":
		# Keep the 4x4 centerpiece footprint clear of soft blocks
		if cell.x >= 6 and cell.x <= 9 and cell.y >= 6 and cell.y <= 9:
			return false
		# Place soft blocks along the central ice lanes and walkways
		if (cell.x in [5, 10] and cell.y >= 5 and cell.y <= 10) or (cell.y in [5, 10] and cell.x >= 5 and cell.x <= 10):
			return (cell.x + cell.y) % 2 == 0
	elif definition.id != &"egypt_temple" and definition.id != &"training_plaza" and cell.x >= 5 and cell.x <= 10 and cell.y >= 5 and cell.y <= 10:
		# Keep the 6x6 courtyard around the centerpiece clear of soft blocks
		return false
		
	var sym_hash := absi(pattern_cell.x * 37 + pattern_cell.y * 61 + definition.layout_seed * 17) % 100
	var threshold := int(definition.soft_block_density * 100.0)
	
	match definition.id:
		&"lego_city":
			return not _is_lego_road(cell)
		_:
			return sym_hash < threshold

static func _clear_signature_routes(definition: MapDefinition) -> void:
	var center_x := definition.width / 2
	var center_y := definition.height / 2
	for y in range(1, definition.height - 1):
		for x in range(1, definition.width - 1):
			var cell := Vector2i(x, y)
			var clear := false
			match definition.id:
				&"lego_city":
					clear = _is_lego_road(cell)
				&"aqua_park":
					clear = (y in [center_y - 1, center_y] and x in range(center_x - 3, center_x + 3)) or (x in [center_x - 1, center_x] and y in range(center_y - 3, center_y + 3))
				&"pirate_harbor":
					clear = (y in [center_y - 1, center_y]) or (x in [center_x - 1, center_x]) or (y in [4, 5, 10, 11] and x in [4, 5, 10, 11])
				_:
					clear = (y in [center_y - 1, center_y]) or (x in [center_x - 1, center_x])
			if clear:
				definition.layout[y][x] = GameConstants.TileType.FLOOR

static func _clear_spawn_areas(definition: MapDefinition) -> void:
	for spawn in definition.spawn_points:
		# Even-sized maps have no single center column. Clear every reflected spawn
		# pocket as one orbit so an edge spawn never makes only one quadrant sparse.
		var reflected_spawns: Array[Vector2i] = [
			spawn,
			Vector2i(definition.width - 1 - spawn.x, spawn.y),
			Vector2i(spawn.x, definition.height - 1 - spawn.y),
			Vector2i(definition.width - 1 - spawn.x, definition.height - 1 - spawn.y),
		]
		for reflected_spawn in reflected_spawns:
			for offset in [Vector2i.ZERO, Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
				var cell: Vector2i = reflected_spawn + offset
				if cell.x > 0 and cell.y > 0 and cell.x < definition.width - 1 and cell.y < definition.height - 1:
					definition.layout[cell.y][cell.x] = GameConstants.TileType.FLOOR

static func _restore_decoration_anchors(definition: MapDefinition) -> void:
	for spec in MapDecorationCatalog.specs_for_map(definition.id):
		if not spec.get("blocks_movement", true):
			continue
		var origin: Vector2i = spec["cell"]
		var footprint: Vector2i = spec["size"]
		for y in range(origin.y, origin.y + footprint.y):
			for x in range(origin.x, origin.x + footprint.x):
				definition.layout[y][x] = GameConstants.TileType.WALL

static func _is_lego_road(cell: Vector2i) -> bool:
	return cell.x in [6, 7, 8, 9] or cell.y in [6, 7, 8, 9]
