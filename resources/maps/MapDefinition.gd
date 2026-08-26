class_name MapDefinition
extends Resource

@export var id: StringName = &"training_plaza"
@export var display_name: String = "Training Plaza"
@export var width: int = 16
@export var height: int = 16
@export var tile_size: int = 40
@export var spawn_points: Array[Vector2i] = [
	Vector2i(1, 1),
	Vector2i(14, 14),
	Vector2i(14, 1),
	Vector2i(1, 14),
	Vector2i(7, 1),
	Vector2i(8, 14),
	Vector2i(1, 7),
	Vector2i(14, 8)
]
# Layout matrix: 0 = Floor, 1 = Wall, 2 = Destructible Block
@export var layout: Array[PackedInt32Array] = []
@export var item_drop_rate: float = 0.65
@export var soft_block_density: float = 0.68
@export var layout_seed: int = 1
@export var max_players: int = 8
@export var theme: StringName = &"plaza"
@export var preview: Texture2D
@export var background_color: Color = Color(0.18, 0.54, 0.34, 1.0)
@export var floor_color: Color = Color(0.24, 0.68, 0.42, 1.0)
@export var wall_color: Color = Color(0.45, 0.45, 0.55, 1.0)
@export var destructible_color: Color = Color(0.82, 0.56, 0.28, 1.0)

func generate_default_classic_layout() -> void:
	layout.clear()
	for y in range(height):
		var row = PackedInt32Array()
		row.resize(width)
		for x in range(width):
			# Border walls
			if x == 0 or x == width - 1 or y == 0 or y == height - 1:
				row[x] = GameConstants.TileType.WALL
			# Pillar grid walls
			elif x % 2 == 0 and y % 2 == 0:
				row[x] = GameConstants.TileType.WALL
			# Keep spawn areas clear
			elif is_near_spawn(Vector2i(x, y)):
				row[x] = GameConstants.TileType.FLOOR
			# Keep the central combat cross readable.
			elif abs(x - width / 2) + abs(y - height / 2) <= 2:
				row[x] = GameConstants.TileType.FLOOR
			else:
				var symmetric_x := mini(x, width - 1 - x)
				var symmetric_y := mini(y, height - 1 - y)
				var roll: int = absi((symmetric_x * 37 + symmetric_y * 61 + layout_seed * 17) % 100)
				if roll < int(soft_block_density * 100.0):
					row[x] = GameConstants.TileType.DESTRUCTIBLE
				else:
					row[x] = GameConstants.TileType.FLOOR
		layout.append(row)

func is_near_spawn(cell: Vector2i) -> bool:
	for sp in spawn_points:
		if cell == sp or (abs(cell.x - sp.x) + abs(cell.y - sp.y)) <= 1:
			return true
	return false
