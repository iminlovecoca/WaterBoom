extends Node

const OUTPUT_DIR := "res://tests/artifacts"

func _ready() -> void:
	_run.call_deferred()

func _capture(file_name: String) -> void:
	await get_tree().process_frame
	RenderingServer.force_draw()
	var image := get_viewport().get_texture().get_image()
	if image == null or image.is_empty():
		push_error("VISUAL_CAPTURE failed: no framebuffer for %s" % file_name)
		return
	var error := image.save_png("%s/%s" % [OUTPUT_DIR, file_name])
	print("VISUAL_CAPTURE ", file_name, " error=", error)

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	# Never leave stale screenshots behind when a capture run fails halfway.
	for stale_name in ["character_animation_preview.png", "water_burst.png", "water_burst_horizontal.png"]:
		var stale_path := "%s/%s" % [OUTPUT_DIR, stale_name]
		if FileAccess.file_exists(stale_path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(stale_path))
	var menu: Control = load("res://scenes/boot/Boot.tscn").instantiate()
	add_child(menu)
	await get_tree().process_frame
	await _capture("menu.png")
	var boot := menu as BootManager
	boot._open_feature_panel(boot.shop_panel)
	await get_tree().process_frame
	await _capture("shop.png")
	boot.shop_panel.visible = false
	boot._open_feature_panel(boot.inventory_panel)
	await get_tree().process_frame
	await _capture("inventory.png")
	boot.inventory_panel.visible = false
	boot.map_picker_panel.visible = true
	await _capture("map_picker.png")
	boot.map_picker_panel.visible = false
	menu.queue_free()
	await get_tree().process_frame

	GameSession.selected_balloon_skin = &"watermelon"
	GameSession.configure_solo(1, GameConstants.BotDifficulty.NORMAL, &"training_plaza")
	var arena := load("res://scenes/match/MatchArena.tscn").instantiate() as MatchManager
	add_child(arena)
	await get_tree().process_frame
	arena.countdown_timer = 0.05
	await get_tree().create_timer(0.15).timeout
	await _capture("match.png")

	var human: PlayerController = arena.players[1]
	human.place_water_balloon_request()
	human.position += Vector2(52, 0)
	await get_tree().create_timer(0.12).timeout
	await _capture("watermelon_balloon.png")
	var first_balloon: WaterBalloon = arena.water_balloon_manager.active_water_balloons.values()[0]
	# Keep the capture actor outside the first burst. Updating only position left
	# grid_cell at the balloon origin and made the actor bubbled in stale tests.
	var safe_cell := Vector2i(arena.grid_manager.width - 2, arena.grid_manager.height - 2)
	arena.grid_manager.set_cell_type(safe_cell, GameConstants.TileType.FLOOR)
	human.grid_cell = safe_cell
	human.position = arena.grid_manager.grid_to_world(safe_cell)
	arena.water_balloon_manager.trigger_water_burst(first_balloon.water_balloon_id)
	await get_tree().create_timer(arena.match_config.water_active_duration + 0.05).timeout
	var burst_center := Vector2i(7, 4)
	for direction in [Vector2i.ZERO, Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
		for distance in range(1, 4):
			var cell: Vector2i = burst_center if direction == Vector2i.ZERO else burst_center + direction * distance
			arena.grid_manager.set_cell_type(cell, GameConstants.TileType.FLOOR)
	human.grid_cell = burst_center
	human.position = arena.grid_manager.grid_to_world(burst_center)
	human.active_water_balloons = 0
	human.water_power = 3
	human.place_water_balloon_request()
	var center_balloon: WaterBalloon = arena.water_balloon_manager.active_water_balloons.values()[0]
	arena.water_balloon_manager.trigger_water_burst(center_balloon.water_balloon_id)
	await get_tree().create_timer(0.12).timeout
	await _capture("water_burst.png")
	await get_tree().create_timer(arena.match_config.water_active_duration + 0.05).timeout
	var horizontal_rays := {
		"center": [burst_center],
		"up": [],
		"down": [],
		"left": [
			{"cell": burst_center + Vector2i.LEFT, "is_end": false},
			{"cell": burst_center + Vector2i.LEFT * 2, "is_end": true}
		],
		"right": [
			{"cell": burst_center + Vector2i.RIGHT, "is_end": false},
			{"cell": burst_center + Vector2i.RIGHT * 2, "is_end": true}
		]
	}
	arena.water_stream_renderer.spawn_water_burst(horizontal_rays, arena.grid_manager, &"skin_066")
	await get_tree().create_timer(0.12).timeout
	await _capture("water_burst_horizontal.png")
	var bot: PlayerController = arena.players[2]
	bot.max_bubble_time = 0.6
	bot.hit_by_water(bot.grid_cell)
	await get_tree().create_timer(0.18).timeout
	await _capture("character_bubbled.png")
	arena.hud.result_panel.visible = true
	arena.hud._on_match_ended(1, false)
	# Let the square EXP bar finish its level-up sweep before recording the
	# stable result state used by visual QA.
	await get_tree().create_timer(1.2).timeout
	await _capture("result_victory.png")
	arena.hud._on_match_ended(2, false)
	await _capture("result_defeat.png")
	await _capture("result.png")
	arena.queue_free()
	await get_tree().process_frame
	GameSession.configure_team(8, GameConstants.BotDifficulty.NORMAL, &"lego_city", &"red_rider")
	var team_arena := load("res://scenes/match/MatchArena.tscn").instantiate() as MatchManager
	add_child(team_arena)
	await get_tree().process_frame
	team_arena.countdown_timer = 0.05
	await get_tree().create_timer(0.15).timeout
	await _capture("team_8_players.png")
	team_arena.queue_free()
	await get_tree().process_frame
	var character_preview: Control = load("res://tests/CharacterAnimationPreview.tscn").instantiate()
	add_child(character_preview)
	await get_tree().process_frame
	character_preview.animation_option.select(1)
	character_preview.direction_option.select(0)
	character_preview._refresh_animation()
	await get_tree().create_timer(0.25).timeout
	await _capture("character_animation_preview.png")
	character_preview.queue_free()
	await get_tree().process_frame
	RenderingServer.set_default_clear_color(Color(0.08, 0.11, 0.17))
	var idle_player := load("res://scenes/characters/Player.tscn").instantiate() as PlayerController
	idle_player.is_local_control = false
	idle_player.position = Vector2(640, 380)
	idle_player.scale = Vector2(3.0, 3.0)
	add_child(idle_player)
	await get_tree().process_frame
	idle_player.visual.set_player_name("")
	await get_tree().create_timer(3.2).timeout
	await _capture("character_idle_sleep.png")
	get_tree().quit()
