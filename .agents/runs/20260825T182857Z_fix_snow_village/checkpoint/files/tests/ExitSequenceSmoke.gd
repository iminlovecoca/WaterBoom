extends Node

func _ready() -> void:
	var failures: Array[String] = []
	var passed := 0
	var stream := load("res://assets/audio/ui/out.ogg") as AudioStream
	passed += _check(stream != null, "exit sound loads", failures)
	if stream != null:
		passed += _check(stream.get_length() > 0.0, "exit sound has playable length", failures)
	passed += _check(has_node("/root/ExitSequence"), "ExitSequence autoload exists", failures)

	var boot_scene := load("res://scenes/boot/Boot.tscn") as PackedScene
	passed += _check(boot_scene != null, "lobby scene loads", failures)
	if boot_scene != null:
		var boot := boot_scene.instantiate()
		add_child(boot)
		await get_tree().process_frame
		var quit_button := boot.get_node_or_null("QuitButton") as Button
		passed += _check(quit_button != null, "QuitButton exists", failures)
		if quit_button != null:
			passed += _check(_has_exit_sequence_connection(quit_button), "QuitButton uses exit audio fade sequence", failures)
		boot.queue_free()

	for message in failures:
		push_error(message)
	print("EXIT_SEQUENCE_RESULT: %d passed | %d failed" % [passed, failures.size()])
	get_tree().quit(0 if failures.is_empty() else 1)

func _has_exit_sequence_connection(button: Button) -> bool:
	for connection in button.pressed.get_connections():
		var callable := connection["callable"] as Callable
		if callable.get_object() == ExitSequence and callable.get_method() == "play_and_quit":
			return true
	return false

func _check(condition: bool, label: String, failures: Array[String]) -> int:
	if condition:
		print("[EXIT PASS] %s" % label)
		return 1
	else:
		failures.append("[EXIT FAIL] %s" % label)
		return 0
