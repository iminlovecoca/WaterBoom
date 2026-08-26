class_name CharacterShadow
extends Node2D

@export var radius := Vector2(13.0, 5.0)
@export var shadow_color := Color(0.015, 0.035, 0.08, 0.32)

func _draw() -> void:
	var points := PackedVector2Array()
	for index in 24:
		var angle := TAU * index / 24.0
		points.append(Vector2(cos(angle) * radius.x, sin(angle) * radius.y))
	draw_colored_polygon(points, shadow_color)
