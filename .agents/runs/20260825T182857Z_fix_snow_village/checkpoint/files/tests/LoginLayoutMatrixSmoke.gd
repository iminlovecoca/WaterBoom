extends Node

const LOGIN_SCENE := preload("res://scenes/login/Login.tscn")
const TEST_SIZES: Array[Vector2i] = [
	Vector2i(760, 570),
	Vector2i(960, 720),
	Vector2i(1280, 720),
	Vector2i(1280, 960),
	Vector2i(1440, 1080),
]

var failures: Array[String] = []
var checks_run := 0


func _ready() -> void:
	_run.call_deferred()


func _check(condition: bool, label: String) -> void:
	checks_run += 1
	if condition:
		print("[LOGIN LAYOUT PASS] ", label)
	else:
		failures.append(label)
		push_error("[LOGIN LAYOUT FAIL] %s" % label)


func _run() -> void:
	for test_size in TEST_SIZES:
		var viewport := SubViewport.new()
		viewport.size = test_size
		viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		add_child(viewport)

		var login := LOGIN_SCENE.instantiate() as LoginScreen
		viewport.add_child(login)
		await get_tree().process_frame
		await get_tree().process_frame

		var bounds := Rect2(Vector2.ZERO, Vector2(test_size))
		var panel_rect := login.login_panel.get_global_rect()
		var title := login.get_node("SafeArea/Flow/Title") as Control
		var subtitle := login.get_node("SafeArea/Flow/Subtitle") as Control
		var suffix := " @ %dx%d" % [test_size.x, test_size.y]
		_check(bounds.encloses(panel_rect), "login panel remains inside safe area" + suffix)
		_check(bounds.encloses(title.get_global_rect()), "title remains visible" + suffix)
		_check(bounds.encloses(subtitle.get_global_rect()), "subtitle remains visible" + suffix)
		_check(title.get_global_rect().end.y <= panel_rect.position.y, "title never overlaps login panel" + suffix)
		for button in [login.login_button, login.create_button, login.forgot_button]:
			_check(button.size.x >= 100.0 and button.size.y >= 44.0, "%s keeps a usable hit target%s" % [button.name, suffix])
		_check(not login.account_input.focus_neighbor_bottom.is_empty(), "keyboard focus path is configured" + suffix)

		viewport.queue_free()
		await get_tree().process_frame

	print("LOGIN_LAYOUT_MATRIX_RESULT: %d passed | %d failed" % [checks_run - failures.size(), failures.size()])
	get_tree().quit(0 if failures.is_empty() else 1)
