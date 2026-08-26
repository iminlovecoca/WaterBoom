class_name DevelopmentCharacter
extends Node2D

var state: GameConstants.PlayerState = GameConstants.PlayerState.NORMAL
var direction: GameConstants.Direction = GameConstants.Direction.DOWN
var body_color: Color = Color(0.22, 0.72, 1.0)
var walk_phase: float = 0.0

func set_character_state(p_state: GameConstants.PlayerState, p_direction: GameConstants.Direction) -> void:
	state = p_state
	direction = p_direction
	queue_redraw()

func set_body_color(color: Color) -> void:
	body_color = color
	queue_redraw()

func _process(delta: float) -> void:
	if state == GameConstants.PlayerState.WALKING:
		walk_phase += delta * 12.0
		position.y = -4.0 + sin(walk_phase) * 1.5
		queue_redraw()
	else:
		position.y = -4.0

func _draw() -> void:
	var draw_color := body_color
	if state == GameConstants.PlayerState.WATER_HIT or state == GameConstants.PlayerState.BUBBLED:
		draw_color = body_color.lerp(Color(0.55, 0.95, 1.0), 0.5)
	elif state == GameConstants.PlayerState.DEAD:
		draw_color = Color(0.42, 0.48, 0.55)

	# Original development-only chibi made entirely from Godot drawing primitives.
	draw_circle(Vector2(0, 1), 12.5, Color(0.04, 0.18, 0.32))
	draw_circle(Vector2(0, 0), 11.0, draw_color)
	draw_circle(Vector2(-4, -5), 3.4, Color(0.78, 0.97, 1.0, 0.72))
	draw_arc(Vector2.ZERO, 10.2, 0.2, 2.8, 20, Color(0.75, 0.96, 1.0), 1.2)

	var face_offset := Vector2.ZERO
	match direction:
		GameConstants.Direction.UP: face_offset = Vector2(0, -2)
		GameConstants.Direction.LEFT: face_offset = Vector2(-2, 0)
		GameConstants.Direction.RIGHT: face_offset = Vector2(2, 0)
		_: face_offset = Vector2(0, 1)

	if state == GameConstants.PlayerState.DEAD:
		for eye_x in [-4.0, 4.0]:
			var eye := face_offset + Vector2(eye_x, -1)
			draw_line(eye - Vector2(2, 2), eye + Vector2(2, 2), Color.WHITE, 1.5)
			draw_line(eye + Vector2(-2, 2), eye + Vector2(2, -2), Color.WHITE, 1.5)
	else:
		draw_circle(face_offset + Vector2(-4, -1), 1.8, Color.WHITE)
		draw_circle(face_offset + Vector2(4, -1), 1.8, Color.WHITE)
		draw_circle(face_offset + Vector2(-4, -1), 0.8, Color(0.02, 0.08, 0.15))
		draw_circle(face_offset + Vector2(4, -1), 0.8, Color(0.02, 0.08, 0.15))

	var foot_step := sin(walk_phase) * 2.0 if state == GameConstants.PlayerState.WALKING else 0.0
	draw_line(Vector2(-5, 10), Vector2(-6 - foot_step, 13), Color(0.04, 0.16, 0.25), 3.0)
	draw_line(Vector2(5, 10), Vector2(6 + foot_step, 13), Color(0.04, 0.16, 0.25), 3.0)

	# Direction marker remains readable even when final character art is absent.
	var marker := Vector2(0, 7)
	match direction:
		GameConstants.Direction.UP: marker = Vector2(0, -10)
		GameConstants.Direction.LEFT: marker = Vector2(-10, 2)
		GameConstants.Direction.RIGHT: marker = Vector2(10, 2)
	draw_circle(marker, 1.6, Color(1.0, 0.88, 0.24))
