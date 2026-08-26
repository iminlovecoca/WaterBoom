class_name ItemEntity
extends Node2D

@export var item_id: int = 0
@export var item_type: GameConstants.ItemType = GameConstants.ItemType.WATER_BALLOON_UP
@export var grid_cell: Vector2i = Vector2i.ZERO

var invulnerable_time: float = 1.0 # Immune to water for 1 second after spawning
const DISPLAY_SIZE := 38.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var icon_label: Label = $IconLabel

var item_textures: Dictionary = {
	GameConstants.ItemType.WATER_BALLOON_UP: preload("res://assets/items/item_water_balloon_up.png"),
	GameConstants.ItemType.WATER_POWER_UP: preload("res://assets/items/item_water_power_up.png"),
	GameConstants.ItemType.SPEED_UP: preload("res://assets/items/item_speed_up.png"),
	GameConstants.ItemType.BUBBLE_PIN: preload("res://assets/items/item_bubble_pin.png"),
	GameConstants.ItemType.SHIELD: preload("res://assets/items/item_shield.png")
}

func initialize(p_id: int, p_type: int, p_cell: Vector2i) -> void:
	item_id = p_id
	item_type = p_type as GameConstants.ItemType
	grid_cell = p_cell
	
	if item_textures.has(item_type):
		sprite.texture = item_textures[item_type]
		var source_size := float(maxi(sprite.texture.get_width(), sprite.texture.get_height()))
		var fit_scale := DISPLAY_SIZE / source_size if source_size > 0.0 else 1.0
		sprite.scale = Vector2.ONE * fit_scale
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	icon_label.text = ""
	icon_label.visible = false
		
	# Bobbing animation
	var tween = create_tween().set_loops()
	tween.tween_property(sprite, "position:y", -4.0, 0.4)
	tween.tween_property(sprite, "position:y", 2.0, 0.4)

func _process(delta: float) -> void:
	if invulnerable_time > 0:
		invulnerable_time -= delta

func collect() -> void:
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.4, 1.4), 0.1)
	tween.parallel().tween_property(self, "modulate:a", 0.0, 0.1)
	tween.tween_callback(queue_free)

func destroy_by_water() -> void:
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.5, 0.2), 0.15).set_trans(Tween.TRANS_BACK)
	tween.parallel().tween_property(self, "modulate", Color(0.5, 0.9, 1.5, 0.0), 0.15)
	tween.tween_callback(queue_free)
