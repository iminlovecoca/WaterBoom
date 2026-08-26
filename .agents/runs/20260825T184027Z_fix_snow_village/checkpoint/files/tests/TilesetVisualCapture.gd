extends Node

const OUTPUT_DIR := "res://tests/artifacts/tileset_validation"

func _ready() -> void:
	_run.call_deferred()

func _capture(file_name: String) -> void:
	await get_tree().process_frame
	RenderingServer.force_draw()
	var image := get_viewport().get_texture().get_image()
	if image == null or image.is_empty():
		push_error("TILESET_CAPTURE failed: no framebuffer for %s" % file_name)
		return
	var error := image.save_png("%s/%s" % [OUTPUT_DIR, file_name])
	print("TILESET_CAPTURE ", file_name, " error=", error)

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	for map_id in MapCatalog.MAP_IDS:
		var output_path := "%s/map_%s.png" % [OUTPUT_DIR, map_id]
		var absolute_output := ProjectSettings.globalize_path(output_path)
		if FileAccess.file_exists(output_path):
			DirAccess.remove_absolute(absolute_output)
		GameSession.configure_solo(1, GameConstants.BotDifficulty.NORMAL, map_id)
		var arena := load("res://scenes/match/MatchArena.tscn").instantiate() as MatchManager
		add_child(arena)
		await get_tree().process_frame
		# This is a visual fixture, not a playable match. Freeze all gameplay before
		# bots can place balloons or trigger a result-screen scene transition.
		arena.current_state = GameConstants.MatchState.WAITING
		arena.set_process(false)
		arena.set_physics_process(false)
		for player in arena.players.values():
			player.set_process(false)
			player.set_physics_process(false)
			player.visible = false
		for controller in arena.bot_controllers:
			controller.set_process(false)
			controller.set_physics_process(false)
		var center_banner := arena.hud.get_node_or_null("CenterBanner") as Control
		if center_banner != null:
			center_banner.visible = false
		await get_tree().process_frame
		await get_tree().process_frame
		await _capture("map_%s.png" % map_id)
		arena.queue_free()
		await get_tree().process_frame
		await get_tree().process_frame
	get_tree().quit()
