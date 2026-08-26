# Central Game Constants
extends RefCounted
class_name GameConstants

# Grid & Movement Dimensions
const TILE_SIZE: int = 40
const HALF_TILE: float = 20.0
const SIMULATION_TICK_RATE: int = 60
const FIXED_DELTA: float = 1.0 / 60.0

# Gameplay Default Stats
const DEFAULT_MOVE_SPEED: float = 160.0
const DEFAULT_WATER_BALLOON_CAPACITY: int = 1
const DEFAULT_WATER_POWER: int = 1
const DEFAULT_WATER_BALLOON_TIMER: float = 2.5
const DEFAULT_WATER_BURST_DURATION: float = 0.5
const DEFAULT_BUBBLE_DURATION: float = 4.5

# Item Maximum Stacks
const MAX_WATER_BALLOON_CAPACITY: int = 8
const MAX_WATER_POWER: int = 8
const MAX_MOVE_SPEED: float = 280.0
const SPEED_BOOST_PER_ITEM: float = 20.0

# Enums
enum Direction {
	NONE = 0,
	UP = 1,
	DOWN = 2,
	LEFT = 3,
	RIGHT = 4
}

enum PlayerState {
	NORMAL,
	WALKING,
	PLACING,
	WATER_HIT,
	BUBBLED,
	RESCUED,
	DEAD
}

enum TileType {
	FLOOR = 0,
	WALL = 1,
	DESTRUCTIBLE = 2,
	HAZARD = 3
}

enum ItemType {
	NONE = 0,
	WATER_BALLOON_UP = 1,
	WATER_POWER_UP = 2,
	SPEED_UP = 3,
	BUBBLE_PIN = 4,
	SHIELD = 5
}

enum MatchState {
	WAITING,
	COUNTDOWN,
	PLAYING,
	ENDING,
	RESULT
}

enum BotDifficulty {
	EASY,
	NORMAL,
	HARD,
	EXTREME
}

enum BotState {
	IDLE,
	MOVE,
	SEEK_BLOCK,
	SEEK_ITEM,
	PLACE_BALLOON,
	ESCAPE_DANGER,
	CHASE_ENEMY,
	AVOID_WATER,
	BUBBLED,
	DEAD
}

enum RoomState {
	WAITING,
	READY,
	STARTING,
	PLAYING,
	FINISHED
}

# Direction Vectors Mapping
const DIR_VECTORS: Dictionary = {
	Direction.NONE: Vector2i.ZERO,
	Direction.UP: Vector2i(0, -1),
	Direction.DOWN: Vector2i(0, 1),
	Direction.LEFT: Vector2i(-1, 0),
	Direction.RIGHT: Vector2i(1, 0)
}

static func vector_to_direction(v: Vector2) -> Direction:
	if abs(v.x) > abs(v.y):
		if v.x > 0.1: return Direction.RIGHT
		elif v.x < -0.1: return Direction.LEFT
	else:
		if v.y > 0.1: return Direction.DOWN
		elif v.y < -0.1: return Direction.UP
	return Direction.NONE

static func direction_to_vector(dir: Direction) -> Vector2:
	match dir:
		Direction.UP: return Vector2(0, -1)
		Direction.DOWN: return Vector2(0, 1)
		Direction.LEFT: return Vector2(-1, 0)
		Direction.RIGHT: return Vector2(1, 0)
		_: return Vector2.ZERO

static func direction_to_string(dir: Direction) -> String:
	match dir:
		Direction.UP: return "up"
		Direction.DOWN: return "down"
		Direction.LEFT: return "left"
		Direction.RIGHT: return "right"
		_: return "idle"
