class_name CharacterStatusVFX
extends Node2D

var mode: StringName = &"idle"
var elapsed := 0.0
var idle_elapsed := 0.0
var burst_remaining := 0.0
var facing_direction: GameConstants.Direction = GameConstants.Direction.DOWN

func set_direction(value: GameConstants.Direction) -> void:
	if value != GameConstants.Direction.NONE:
		facing_direction = value

func set_mode(value: StringName) -> void:
	burst_remaining = 0.0
	if mode != value:
		mode = value
		elapsed = 0.0
	if mode != &"idle":
		idle_elapsed = 0.0
	queue_redraw()

func burst(value: StringName, duration: float = 0.45) -> void:
	mode = value
	burst_remaining = duration
	elapsed = 0.0
	idle_elapsed = 0.0
	queue_redraw()

func _process(delta: float) -> void:
	elapsed += delta
	if mode == &"idle":
		idle_elapsed += delta
	if burst_remaining > 0.0:
		burst_remaining = maxf(burst_remaining - delta, 0.0)
		if burst_remaining == 0.0:
			mode = &"idle"
	queue_redraw()

func _draw() -> void:
	if mode == &"idle" and idle_elapsed > 2.8:
		_draw_sleep_marks()
	elif mode == &"walk":
		_draw_movement_dust()
	elif mode == &"hurt":
		_draw_lightning()
		_draw_crying(false)
	elif mode == &"bubbled":
		_draw_crying(true)
	elif mode == &"place":
		_draw_water_balloon_hint()
	elif mode == &"pickup" or mode == &"win":
		_draw_sparkles(Color(0.35, 0.95, 1.0) if mode == &"pickup" else Color(1.0, 0.88, 0.25))
	elif mode == &"pin_escape":
		_draw_pin_escape()
	elif mode == &"lose":
		draw_circle(Vector2(0, -39), 5.0, Color(0.25, 0.3, 0.42, 0.65))

func _draw_sleep_marks() -> void:
	var rise := fmod(elapsed * 9.0, 12.0)
	var alpha := 1.0 - rise / 14.0
	draw_string(ThemeDB.fallback_font, Vector2(16, -34 - rise), "Z", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.72, 0.92, 1.0, alpha))
	draw_string(ThemeDB.fallback_font, Vector2(24, -43 - rise * 0.6), "z", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.72, 0.92, 1.0, alpha * 0.8))

func _draw_lightning() -> void:
	var flicker := 1.0 if int(elapsed * 16.0) % 2 == 0 else 0.55
	var color := Color(1.0, 0.9, 0.2, flicker)
	draw_polyline(PackedVector2Array([Vector2(-26, -34), Vector2(-18, -28), Vector2(-23, -20), Vector2(-14, -24)]), color, 3.0)
	draw_polyline(PackedVector2Array([Vector2(25, -36), Vector2(17, -29), Vector2(23, -23), Vector2(14, -19)]), color, 3.0)

func _draw_crying(inside_bubble: bool) -> void:
	var sob := sin(elapsed * 13.0) * 1.5
	var face_y := -20.0 + sob
	var tear_color := Color(0.35, 0.86, 1.0, 0.9)
	# Two animated tear streams stay within the bubble shell.
	for side in [-1.0, 1.0]:
		var tear_phase := fmod(elapsed * 2.8 + (0.22 if side > 0.0 else 0.0), 1.0)
		var eye := Vector2(side * 7.0, face_y)
		draw_line(eye, eye + Vector2(side * 1.5, 7.0), tear_color, 2.2)
		draw_circle(eye + Vector2(side * 2.0, 8.0 + tear_phase * 8.0), 2.6 * (1.0 - tear_phase * 0.35), tear_color)
	# Trembling mouth and small distress marks make the emotion readable at game scale.
	draw_arc(Vector2(0.0, face_y + 11.0), 4.0, PI + 0.25, TAU - 0.25, 10, Color("#24364f"), 1.8, true)
	if inside_bubble:
		var alpha := 0.55 + sin(elapsed * 9.0) * 0.2
		draw_string(ThemeDB.fallback_font, Vector2(15.0, -29.0), "SOB", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(0.85, 0.96, 1.0, alpha))

func _draw_movement_dust() -> void:
	var direction_vector := _direction_vector(facing_direction)
	var behind := -direction_vector * 11.0 + Vector2(0.0, 9.0)
	for index in range(3):
		var phase := fmod(elapsed * 7.0 + index * 0.33, 1.0)
		var side := Vector2(-direction_vector.y, direction_vector.x) * (index - 1) * 5.0
		var center := behind - direction_vector * phase * 10.0 + side
		draw_circle(center, 3.2 * (1.0 - phase), Color(0.82, 0.9, 0.96, 0.5 * (1.0 - phase)))
	var streak_color := Color(0.55, 0.86, 1.0, 0.45)
	draw_line(behind - Vector2(6.0, 2.0), behind - direction_vector * 10.0 - Vector2(6.0, 2.0), streak_color, 2.0)
	draw_line(behind + Vector2(6.0, 2.0), behind - direction_vector * 8.0 + Vector2(6.0, 2.0), streak_color, 2.0)
	# Alternating contact rings visually lock each short foot to the floor.
	var foot_phase := fmod(elapsed * 10.5, 1.0)
	var foot_side := -1.0 if int(elapsed * 10.5) % 2 == 0 else 1.0
	var foot := behind + Vector2(-direction_vector.y, direction_vector.x) * foot_side * 6.0
	draw_arc(foot, 3.0 + foot_phase * 5.0, 0.15, PI - 0.15, 10, Color(0.55, 0.9, 1.0, 0.55 * (1.0 - foot_phase)), 1.6)

func _direction_vector(direction: GameConstants.Direction) -> Vector2:
	match direction:
		GameConstants.Direction.UP:
			return Vector2.UP
		GameConstants.Direction.LEFT:
			return Vector2.LEFT
		GameConstants.Direction.RIGHT:
			return Vector2.RIGHT
		_:
			return Vector2.DOWN

func _draw_water_balloon_hint() -> void:
	var pulse := 1.0 + sin(elapsed * 18.0) * 0.08
	draw_circle(Vector2(23, 2), 7.0 * pulse, Color(0.12, 0.78, 1.0, 0.9))
	draw_circle(Vector2(21, 0), 2.0 * pulse, Color(0.82, 1.0, 1.0, 0.9))
	draw_colored_polygon(PackedVector2Array([Vector2(21, 8), Vector2(25, 8), Vector2(23, 12)]), Color(0.08, 0.55, 0.9))
	var ring_phase := fmod(elapsed * 4.0, 1.0)
	draw_arc(Vector2(0, 10), 8.0 + ring_phase * 14.0, 0.0, TAU, 24, Color(0.35, 0.9, 1.0, 0.55 * (1.0 - ring_phase)), 2.0)

func _draw_sparkles(color: Color) -> void:
	for index in 4:
		var angle := elapsed * 5.0 + index * TAU / 4.0
		var center := Vector2(cos(angle), sin(angle)) * 27.0 + Vector2(0, -17)
		draw_line(center - Vector2(3, 0), center + Vector2(3, 0), color, 2.0)
		draw_line(center - Vector2(0, 3), center + Vector2(0, 3), color, 2.0)

func _draw_pin_escape() -> void:
	var radius := 10.0 + elapsed * 34.0
	var alpha := maxf(1.0 - elapsed / 0.65, 0.0)
	draw_arc(Vector2(0, -14), radius, 0.0, TAU, 28, Color(0.35, 0.95, 1.0, alpha), 3.0)
	for index in range(6):
		var angle := index * TAU / 6.0 + elapsed * 2.0
		var tip := Vector2(cos(angle), sin(angle)) * radius + Vector2(0, -14)
		draw_circle(tip, 2.7, Color(1.0, 0.88, 0.22, alpha))
