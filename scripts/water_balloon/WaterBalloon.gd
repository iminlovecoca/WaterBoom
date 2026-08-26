class_name WaterBalloon
extends Node2D

@export var water_balloon_id: int = 0
@export var owner_id: int = 0
@export var grid_cell: Vector2i = Vector2i.ZERO
@export var timer_duration: float = GameConstants.DEFAULT_WATER_BALLOON_TIMER
@export var water_power: int = GameConstants.DEFAULT_WATER_POWER

var has_popped: bool = false
var time_left: float = GameConstants.DEFAULT_WATER_BALLOON_TIMER
var water_balloon_manager: Node
var skin_id: StringName = &"skin_066"

@onready var sprite: Sprite2D = $Sprite2D

var water_balloon_textures: Array[Texture2D] = []

func initialize(p_id: int, p_owner: int, p_cell: Vector2i, p_water_power: int, p_timer_duration: float, p_mgr: Node, p_skin_id: StringName = &"skin_066") -> void:
	water_balloon_id = p_id
	owner_id = p_owner
	grid_cell = p_cell
	water_power = p_water_power
	timer_duration = p_timer_duration
	time_left = p_timer_duration
	water_balloon_manager = p_mgr
	has_popped = false
	scale = Vector2.ONE
	skin_id = p_skin_id if p_skin_id != &"" else &"skin_066"
	water_balloon_textures = WaterBalloonSkinRegistry.get_textures(skin_id)
	if water_balloon_textures.is_empty():
		water_balloon_textures = WaterBalloonSkinRegistry.get_textures(&"skin_066")
	if sprite == null:
		sprite = get_node("Sprite2D") as Sprite2D
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	var tex: Texture2D = water_balloon_textures[0] if water_balloon_textures.size() > 0 else null
	if tex != null and tex.get_width() > 0:
		var b_size: float = float(p_mgr.grid_manager.tile_size) * 1.15 if (p_mgr != null and p_mgr.grid_manager != null) else 55.0
		var normalization := WaterBalloonSkinRegistry.get_runtime_scale(skin_id)
		sprite.scale = Vector2(b_size / float(tex.get_width()), b_size / float(tex.get_height())) * normalization
	sprite.texture = tex
	_start_wobble_animation()

func _start_wobble_animation() -> void:
	var tween = create_tween().set_loops()
	tween.tween_property(self, "scale", Vector2(1.035, 0.975), 0.24)
	tween.parallel().tween_property(self, "rotation", 0.035, 0.24)
	tween.tween_property(self, "scale", Vector2(0.98, 1.035), 0.24)
	tween.parallel().tween_property(self, "rotation", -0.035, 0.24)

func _process(delta: float) -> void:
	if has_popped:
		return
	time_left -= delta
	var progress = clamp(1.0 - (time_left / timer_duration), 0.0, 1.0)
	var frame_idx = clamp(int(progress * float(water_balloon_textures.size())), 0, water_balloon_textures.size() - 1)
	sprite.texture = water_balloon_textures[frame_idx]
	var wobble_speed = lerp(3.0, 13.0, progress)
	rotation = sin(Time.get_ticks_msec() * 0.001 * wobble_speed) * lerp(0.015, 0.065, progress)
	if time_left <= 0.0:
		pop()

func pop() -> void:
	if has_popped:
		return
	has_popped = true
	if water_balloon_manager != null and water_balloon_manager.has_method("on_water_balloon_timer_expired"):
		water_balloon_manager.on_water_balloon_timer_expired(self)
	queue_free()
