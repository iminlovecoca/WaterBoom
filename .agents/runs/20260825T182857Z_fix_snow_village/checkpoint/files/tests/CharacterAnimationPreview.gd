extends Control

const ANIMATIONS := ["idle", "walk", "water_hit", "bubble", "rescued", "die", "win", "lose"]
const DIRECTIONS := ["down", "up", "left", "right"]

@onready var sprite: AnimatedSprite2D = $PreviewSprite
@onready var animation_option: OptionButton = $TopBar/AnimationOption
@onready var direction_option: OptionButton = $TopBar/DirectionOption
@onready var info_label: Label = $InfoLabel

func _ready() -> void:
	# Keep the diagnostic preview on the production V13 contract. Legacy
	# resources remain available only for rollback and must not be shown here.
	sprite.sprite_frames = preload("res://resources/characters/coral_diver_frames_v13.tres")
	for animation in ANIMATIONS:
		animation_option.add_item(animation)
	for direction in DIRECTIONS:
		direction_option.add_item(direction)
	animation_option.item_selected.connect(func(_index): _refresh_animation())
	direction_option.item_selected.connect(func(_index): _refresh_animation())
	$Controls/PreviousButton.pressed.connect(_previous_frame)
	$Controls/NextButton.pressed.connect(_next_frame)
	$Controls/PlayButton.pressed.connect(func(): sprite.play())
	$Controls/PauseButton.pressed.connect(func(): sprite.pause())
	_refresh_animation()
	queue_redraw()

func _process(_delta: float) -> void:
	var frame_count := sprite.sprite_frames.get_frame_count(sprite.animation)
	var fps := sprite.sprite_frames.get_animation_speed(sprite.animation)
	info_label.text = "Frame %d / %d    FPS %.1f    Pivot (56, 107)    Canvas 112x112" % [sprite.frame, frame_count - 1, fps]

func _refresh_animation() -> void:
	var base_name: String = ANIMATIONS[animation_option.selected]
	var animation_name := StringName("%s_%s" % [base_name, DIRECTIONS[direction_option.selected]]) if base_name in ["idle", "walk"] else StringName(base_name)
	sprite.play(animation_name)

func _previous_frame() -> void:
	sprite.pause()
	var count := sprite.sprite_frames.get_frame_count(sprite.animation)
	sprite.frame = wrapi(sprite.frame - 1, 0, count)

func _next_frame() -> void:
	sprite.pause()
	var count := sprite.sprite_frames.get_frame_count(sprite.animation)
	sprite.frame = wrapi(sprite.frame + 1, 0, count)

func _draw() -> void:
	var center := Vector2(640, 350)
	var half_canvas := Vector2(144, 144)
	draw_rect(Rect2(center - half_canvas, half_canvas * 2.0), Color(0.35, 0.7, 1.0, 0.8), false, 2.0)
	var pivot := center + Vector2(0, 120)
	draw_line(pivot - Vector2(10, 0), pivot + Vector2(10, 0), Color.YELLOW, 2.0)
	draw_line(pivot - Vector2(0, 10), pivot + Vector2(0, 10), Color.YELLOW, 2.0)
	draw_line(Vector2(center.x - 170, pivot.y), Vector2(center.x + 170, pivot.y), Color(1.0, 0.55, 0.2, 0.7), 1.0)
