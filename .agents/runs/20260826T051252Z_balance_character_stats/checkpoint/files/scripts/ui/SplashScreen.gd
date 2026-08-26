class_name SplashScreen
extends Control

@onready var background: TextureRect = $Background
@onready var emblem: TextureRect = $EmblemContainer/Emblem
@onready var emblem_container: Control = $EmblemContainer
@onready var title_label: Label = $TitleLabel
@onready var subtitle_label: Label = $SubtitleLabel
@onready var progress_bar: ProgressBar = $ProgressBar
@onready var loading_label: Label = $LoadingLabel

var target_scene := "res://scenes/login/Login.tscn"
var is_transitioning := false

func _ready() -> void:
	# Headless / server mode bypasses splash directly
	var args := OS.get_cmdline_user_args()
	if "--server" in args or DisplayServer.get_name() == "headless":
		get_tree().change_scene_to_file("res://scenes/login/Login.tscn")
		return

	_setup_initial_state()
	_start_splash_sequence()

func _setup_initial_state() -> void:
	modulate = Color(1, 1, 1, 0)
	emblem_container.scale = Vector2(0.85, 0.85)
	emblem_container.pivot_offset = emblem_container.size * 0.5
	progress_bar.value = 0.0
	loading_label.text = "ĐANG KHỞI ĐỘNG..."

func _start_splash_sequence() -> void:
	var tween := create_tween().set_parallel(true)
	# Fade in screen
	tween.tween_property(self, "modulate:a", 1.0, 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	# Scale up emblem with spring bounce
	tween.tween_property(emblem_container, "scale", Vector2(1.0, 1.0), 0.7).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	
	# Animate loading progress bar
	var load_tween := create_tween()
	load_tween.tween_interval(0.3)
	load_tween.tween_property(progress_bar, "value", 45.0, 0.6)
	load_tween.tween_callback(func(): loading_label.text = "ĐANG TẢI DỮ LIỆU GAME...")
	load_tween.tween_property(progress_bar, "value", 100.0, 0.7)
	load_tween.tween_callback(func(): loading_label.text = "HOÀN TẤT!")
	load_tween.tween_interval(0.3)
	load_tween.tween_callback(_transition_to_login)

func _input(event: InputEvent) -> void:
	if is_transitioning:
		return
	if event.is_pressed() and (event is InputEventKey or event is InputEventMouseButton):
		_transition_to_login()

func _transition_to_login() -> void:
	if is_transitioning:
		return
	is_transitioning = true
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.35).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	tween.tween_callback(func(): get_tree().change_scene_to_file(target_scene))
