extends SceneTree


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	root.size = Vector2i(960, 720)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://tests/artifacts"))
	var preview := load("res://tests/CharacterV13CastPreview.tscn").instantiate() as Control
	root.add_child(preview)
	await create_timer(2.5).timeout
	var idle_ok := FileAccess.file_exists("res://tests/artifacts/character_v13_cast_idle.png")
	var bubble_ok := FileAccess.file_exists("res://tests/artifacts/character_v13_cast_bubble.png")
	if not idle_ok or not bubble_ok:
		push_error("V13 full-cast preview did not produce both captures")
		quit(1)
		return
	print("CHARACTER_V13_CAST_PREVIEW_RUNNER PASS")
	quit(0)
