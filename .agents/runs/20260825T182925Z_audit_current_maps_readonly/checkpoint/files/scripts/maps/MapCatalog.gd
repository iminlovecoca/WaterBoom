class_name MapCatalog
extends RefCounted

const MAP_IDS: Array[StringName] = [
	&"training_plaza", &"pirate_harbor", &"lego_city", &"aqua_park",
	&"snow_village", &"egypt_temple"
]

static func get_map_metadata(map_id: StringName) -> Dictionary:
	match map_id:
		&"pirate_harbor":
			return {
				"name": "Pirate Harbor",
				"mode": "Đấu đội",
				"players": "2 - 8",
				"diff": "Trung bình",
				"stars": "★★★☆☆",
				"rank": "S",
				"level": "1",
				"category": "team",
				"desc": "Bến cảng cướp biển ven biển với các thùng gỗ và lối đi hiểm trở, thích hợp cho các trận giao tranh đồng đội."
			}
		&"lego_city":
			return {
				"name": "Toy Brick City",
				"mode": "Cổ điển",
				"players": "2 - 4",
				"diff": "Trung bình",
				"stars": "★★★☆☆",
				"rank": "A",
				"level": "2",
				"category": "classic",
				"desc": "Thành phố đồ chơi rực rỡ với các khối gạch sắc màu, bố cục mê cung đa chiều đầy thử thách và vui nhộn."
			}
		&"aqua_park":
			return {
				"name": "Aqua Park",
				"mode": "Sinh tồn",
				"players": "2 - 4",
				"diff": "Khó",
				"stars": "★★★★☆",
				"rank": "S",
				"level": "3",
				"category": "survival",
				"desc": "Khu công viên nước mùa hè mát lạnh với các hồ bơi và lối trượt nước tốc độ cao, yêu cầu phản xạ nhanh nhạy."
			}
		&"snow_village":
			return {
				"name": "Snow Village",
				"mode": "Cổ điển",
				"players": "2 - 4",
				"diff": "Dễ",
				"stars": "★★☆☆☆",
				"rank": "A",
				"level": "1",
				"category": "classic",
				"desc": "Ngôi làng mùa đông phủ đầy tuyết trắng yên bình, địa hình thoáng đãng thích hợp cho các tân thủ rèn luyện."
			}
		&"egypt_temple":
			return {
				"name": "Egypt Temple",
				"mode": "Đấu đội",
				"players": "2 - 8",
				"diff": "Khó",
				"stars": "★★★★☆",
				"rank": "S",
				"level": "3",
				"category": "team",
				"desc": "Ngôi đền cổ kim tự tháp huyền bí với các bẫy cát vàng và cổ vật ngàn năm ẩn chứa nhiều bất ngờ."
			}
		_:
			return {
				"name": "Planning Plaza",
				"mode": "Cổ điển",
				"players": "2 - 4",
				"diff": "Dễ",
				"stars": "★☆☆☆☆",
				"rank": "SS",
				"level": "1",
				"category": "classic",
				"desc": "Khu quảng trường huấn luyện cơ bản, phù hợp cho người chơi mới làm quen với lối chơi đặt bóng nước và kỹ năng cơ bản."
			}

static func create_map(map_id: StringName) -> MapDefinition:
	var definition := MapDefinition.new()
	definition.id = map_id if map_id in MAP_IDS else &"training_plaza"
	match definition.id:
		&"aqua_park":
			_apply_theme(definition, "Aqua Park", &"pool", 2, 0.85, Color("#61c8ed"), Color("#298fb9"), Color("#ffc857"))
		&"pirate_harbor":
			_apply_theme(definition, "Pirate Harbor", &"harbor", 3, 0.88, Color("#a87947"), Color("#384b5c"), Color("#d18a3b"))
		&"snow_village":
			_apply_theme(definition, "Snow Village", &"snow", 4, 0.94, Color("#d9f3ff"), Color("#6c8fb3"), Color("#b98c67"))
		&"lego_city":
			_apply_theme(definition, "Toy Brick City", &"lego", 6, 0.92, Color("#79d52b"), Color("#f04422"), Color("#ffc42e"))
		&"egypt_temple":
			_apply_theme(definition, "Egypt Temple", &"egypt_temple", 8, 0.94, Color("#e8b653"), Color("#b9792c"), Color("#d88d3c"))
		_:
			_apply_theme(definition, "Planning Plaza", &"plaza", 1, 0.50, Color("#76d69b"), Color("#65758a"), Color("#db9654"))
	# Regular arenas use the complete 16x16 grid. Spawn pockets stay one cell in
	# from the edge so the full chibi sprite remains visible; the outer row is still
	# normal playable terrain rather than a sacrificed frame ring.
	definition.spawn_points = [
		Vector2i(1, 1), Vector2i(14, 14), Vector2i(14, 1), Vector2i(1, 14),
		Vector2i(7, 1), Vector2i(8, 14), Vector2i(1, 7), Vector2i(14, 8),
	]
	MapLayoutBuilder.build(definition)
	return definition

static func create_boss_pirate_map() -> MapDefinition:
	return create_boss_pirate_round(1)

static func create_boss_pirate_round(round_index: int) -> MapDefinition:
	var definition := MapDefinition.new()
	definition.id = &"boss_pirate_ship"
	definition.display_name = "Pirate Boss Deck"
	definition.theme = &"harbor"
	definition.layout_seed = 41
	definition.soft_block_density = 0.72 if round_index <= 3 else 0.0
	definition.item_drop_rate = 0.32
	definition.background_color = Color("#172b43")
	definition.spawn_points = [Vector2i(2, 2), Vector2i(13, 13), Vector2i(13, 2), Vector2i(2, 13)]
	definition.layout.clear()
	for y in range(definition.height):
		var row := PackedInt32Array()
		row.resize(definition.width)
		for x in range(definition.width):
			row[x] = GameConstants.TileType.WALL if x == 0 or y == 0 or x == definition.width - 1 or y == definition.height - 1 else GameConstants.TileType.FLOOR
		definition.layout.append(row)
	var pillar_cells := [Vector2i(4, 4), Vector2i(11, 4), Vector2i(4, 11), Vector2i(11, 11)]
	if round_index <= 3:
		# Three genuinely different, horizontally/vertically balanced cargo fields.
		# Every round keeps a safe two-cell route around each player spawn.
		for y in range(2, 14):
			for x in range(2, 14):
				var cell := Vector2i(x, y)
				var pattern := ((x + y) % 2 == 0) if round_index == 1 else (((x * 2 + y) % 3 != 0) if round_index == 2 else ((x + y * 2) % 3 != 1))
				if pattern:
					definition.layout[y][x] = GameConstants.TileType.DESTRUCTIBLE
	elif round_index == 4:
		# Four pillars, each wrapped by exactly four destructible wood blocks.
		for pillar in pillar_cells:
			definition.layout[pillar.y][pillar.x] = GameConstants.TileType.WALL
			for offset in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
				var wood: Vector2i = pillar + offset
				definition.layout[wood.y][wood.x] = GameConstants.TileType.DESTRUCTIBLE
	# Decorations are real collision footprints. They replace any generated cargo.
	for spec in MapDecorationCatalog.specs_for_map(definition.id):
		var origin: Vector2i = spec["cell"]
		var footprint: Vector2i = spec["size"]
		for fy in range(origin.y, origin.y + footprint.y):
			for fx in range(origin.x, origin.x + footprint.x):
				definition.layout[fy][fx] = GameConstants.TileType.WALL
	for spawn in definition.spawn_points:
		for offset in [Vector2i.ZERO, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT, Vector2i.UP]:
			var safe: Vector2i = spawn + offset
			if safe.x > 0 and safe.y > 0 and safe.x < definition.width - 1 and safe.y < definition.height - 1:
				definition.layout[safe.y][safe.x] = GameConstants.TileType.FLOOR
	return definition

static func _apply_theme(definition: MapDefinition, title: String, theme_id: StringName, seed: int, density: float, floor: Color, wall: Color, soft: Color) -> void:
	definition.display_name = title
	definition.theme = theme_id
	definition.layout_seed = seed
	definition.soft_block_density = density
	definition.floor_color = floor
	definition.wall_color = wall
	definition.destructible_color = soft
	definition.background_color = floor.darkened(0.45)

static func display_names() -> Array[String]:
	var names: Array[String] = []
	for map_id in MAP_IDS:
		names.append(create_map(map_id).display_name)
	return names

static func suggested_bot_difficulty(map_id: StringName) -> GameConstants.BotDifficulty:
	var meta := get_map_metadata(map_id)
	match meta.get("diff", "Dễ"):
		"Dễ": return GameConstants.BotDifficulty.EASY
		"Trung bình": return GameConstants.BotDifficulty.NORMAL
		"Khó": return GameConstants.BotDifficulty.HARD
		_: return GameConstants.BotDifficulty.NORMAL
