extends SceneTree


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	root.size = Vector2i(960, 720)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://tests/artifacts"))
	var preview := load("res://tests/CharacterV13PilotPreview.tscn").instantiate() as Control
	root.add_child(preview)
	await process_frame
	await create_timer(1.25).timeout
	var output := "res://tests/artifacts/character_v13_cloud_bunny_pilot.png"
	if not FileAccess.file_exists(output):
		push_error("V13 pilot preview did not produce a capture")
		quit(1)
	else:
		print("CHARACTER_V13_PILOT_RUNNER PASS")
		quit(0)
