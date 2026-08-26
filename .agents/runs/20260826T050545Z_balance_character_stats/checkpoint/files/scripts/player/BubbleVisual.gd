class_name BubbleVisual
extends Node2D

const POP_SHEET: Texture2D = preload("res://assets/vfx/bubble_pop_burst.png")

var time_progress := 1.0
var is_popping := false

func set_time_progress(value: float) -> void:
	time_progress = clampf(value, 0.0, 1.0)
	queue_redraw()

func _process(_delta: float) -> void:
	if not is_popping and visible:
		queue_redraw()

func _draw() -> void:
	if is_popping:
		return
		
	var urgency: float = 1.0 - time_progress
	var pulse_speed := 0.008 + urgency * 0.024
	var pulse := 1.0 + urgency * 0.12 + sin(Time.get_ticks_msec() * pulse_speed) * (0.03 + urgency * 0.05)
	var radius := 28.0 * pulse
	
	# Density & Color: Soft glassy cyan at start, dense pulsating cobalt/crimson when near timeout
	var base_alpha := lerpf(0.35, 0.82, urgency)
	var main_color: Color
	var rim_color: Color
	
	if urgency > 0.75: # Critical danger (< 25% time left)
		var flash := 0.5 + sin(Time.get_ticks_msec() * 0.03) * 0.5
		main_color = Color(0.85, 0.18, 0.28, base_alpha).lerp(Color(0.2, 0.65, 1.0, base_alpha), flash * 0.3)
		rim_color = Color(1.0, 0.45, 0.55, 0.95).lerp(Color(0.8, 0.95, 1.0, 0.95), flash * 0.3)
	else:
		main_color = Color(0.12, 0.55, 0.98, base_alpha)
		rim_color = Color(0.75, 0.95, 1.0, 0.92)

	# 1. Back shadow / depth
	draw_circle(Vector2(0, 4), radius * 0.95, Color(0.02, 0.15, 0.35, base_alpha * 0.6))
	
	# 2. Main dense water body
	draw_circle(Vector2.ZERO, radius, main_color)
	
	# 3. Inner refractive liquid rings
	draw_arc(Vector2.ZERO, radius - 2.5, 0.0, TAU, 48, rim_color, 2.5, true)
	draw_arc(Vector2.ZERO, radius - 6.0, 0.0, TAU, 36, Color(main_color.r + 0.2, main_color.g + 0.2, main_color.b + 0.2, base_alpha * 0.4), 1.5, true)
	
	# 4. Glossy specular highlights
	var hl_offset := Vector2(-radius * 0.35, -radius * 0.35)
	draw_circle(hl_offset, radius * 0.22, Color(1.0, 1.0, 1.0, 0.85))
	draw_circle(hl_offset + Vector2(-3, -3), radius * 0.08, Color.WHITE)
	draw_arc(Vector2(radius * 0.2, radius * 0.25), radius * 0.45, 0.3, 1.3, 16, Color(1.0, 1.0, 1.0, 0.45), 2.0, true)

func play_pop_burst() -> void:
	if is_popping:
		return
	is_popping = true
	queue_redraw()
	
	var pop_sprite := Sprite2D.new()
	pop_sprite.texture = POP_SHEET
	pop_sprite.hframes = 8
	pop_sprite.frame = 0
	pop_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	pop_sprite.scale = Vector2.ONE * 1.35
	add_child(pop_sprite)
	
	var tween := create_tween()
	for f in range(8):
		tween.tween_callback(func(): pop_sprite.frame = f)
		tween.tween_interval(0.035)
	tween.tween_callback(func():
		pop_sprite.queue_free()
		is_popping = false
		visible = false
	)
