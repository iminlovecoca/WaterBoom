extends Node

const OUTPUT := "res://tests/artifacts/login.png"

func _ready() -> void:
	_run.call_deferred()

func _run() -> void:
	var login := load("res://scenes/login/Login.tscn").instantiate() as LoginScreen
	add_child(login)
	await get_tree().process_frame
	await get_tree().process_frame
	RenderingServer.force_draw()
	var error := get_viewport().get_texture().get_image().save_png(OUTPUT)
	print("LOGIN_CAPTURE error=", error)
	var button: LiftButton = login.login_button
	button.mouse_entered.emit()
	await get_tree().create_timer(0.2).timeout
	var hover_ok := button.scale.x > 1.02 and button.position.y < button.base_y
	button.button_down.emit()
	await get_tree().create_timer(0.1).timeout
	var pressed_ok := button.scale.x < 1.0 and button.position.y >= button.base_y
	print("[LOGIN PASS] hover lifts button" if hover_ok else "[LOGIN FAIL] hover lifts button")
	print("[LOGIN PASS] press depresses button differently" if pressed_ok else "[LOGIN FAIL] press depresses button differently")
	get_tree().quit(0 if hover_ok and pressed_ok and error == OK else 1)
