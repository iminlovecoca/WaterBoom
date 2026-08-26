class_name LiftButton
extends Button

var base_y := 0.0
var motion_tween: Tween

func _ready() -> void:
	pivot_offset = size * 0.5
	base_y = position.y
	mouse_entered.connect(_on_hover)
	mouse_exited.connect(_on_leave)
	button_down.connect(_on_down)
	button_up.connect(_on_up)
	focus_entered.connect(_on_focus)
	focus_exited.connect(_on_leave)
	resized.connect(func(): pivot_offset = size * 0.5)

func _animate(target_scale: Vector2, target_y: float, color: Color, duration: float) -> void:
	if motion_tween != null and motion_tween.is_valid():
		motion_tween.kill()
	motion_tween = create_tween().set_parallel(true)
	motion_tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	motion_tween.tween_property(self, "scale", target_scale, duration)
	motion_tween.tween_property(self, "position:y", target_y, duration)
	motion_tween.tween_property(self, "self_modulate", color, duration)

func _on_hover() -> void:
	_animate(Vector2(1.045, 1.045), base_y - 5.0, Color(1.12, 1.12, 1.12), 0.14)

func _on_leave() -> void:
	if button_pressed:
		return
	_animate(Vector2.ONE, base_y, Color.WHITE, 0.16)

func _on_down() -> void:
	_animate(Vector2(0.965, 0.965), base_y + 2.0, Color(1.2, 1.08, 0.72), 0.07)

func _on_up() -> void:
	_animate(Vector2(1.055, 1.055), base_y - 4.0, Color(1.2, 1.2, 1.2), 0.1)

func _on_focus() -> void:
	_animate(Vector2(1.025, 1.025), base_y - 2.0, Color(1.12, 1.07, 0.82), 0.13)
