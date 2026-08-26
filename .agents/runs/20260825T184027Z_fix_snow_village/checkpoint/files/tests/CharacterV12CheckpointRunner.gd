extends SceneTree

func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://tests/artifacts"))
	if FileAccess.file_exists("res://tests/artifacts/character_v12_checkpoint.png"):
		DirAccess.remove_absolute(ProjectSettings.globalize_path("res://tests/artifacts/character_v12_checkpoint.png"))
	var preview: Control = load("res://tests/CharacterV12CheckpointPreview.tscn").instantiate() as Control
	root.add_child(preview)
	await process_frame
	await create_timer(1.25).timeout
	if not FileAccess.file_exists("res://tests/artifacts/character_v12_checkpoint.png"):
		push_error("v12 preview did not produce a capture")
		quit(1)
	else:
		print("CHARACTER_V12_RUNNER PASS")
		quit(0)
