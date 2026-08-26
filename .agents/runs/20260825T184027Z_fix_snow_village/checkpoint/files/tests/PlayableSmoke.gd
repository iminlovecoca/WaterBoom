extends Node

var failures: Array[String] = []
var checks_run := 0
var water_balloon_popped_seen := false
var bot_placed_seen := false

func _ready() -> void:
	EventBus.water_balloon_popped.connect(func(_id, _cell, _cells): water_balloon_popped_seen = true)
	EventBus.water_balloon_placed.connect(func(_id, owner_id, _cell, _duration, _power):
		if owner_id > 1:
			bot_placed_seen = true
	)
	_run.call_deferred()

func check(condition: bool, label: String) -> void:
	checks_run += 1
	if condition:
		print("[PLAYABLE PASS] ", label)
	else:
		print("[PLAYABLE FAIL] ", label)
		failures.append(label)

func _run() -> void:
	GameSession.configure_solo(1, GameConstants.BotDifficulty.NORMAL, &"training_plaza")
	var arena := load("res://scenes/match/MatchArena.tscn").instantiate() as MatchManager
	add_child(arena)
	await get_tree().process_frame
	arena.countdown_timer = 0.05
	await get_tree().create_timer(0.2).timeout
	check(arena.current_state == GameConstants.MatchState.PLAYING, "Solo reaches PLAYING")
	check(arena.players.size() == 2 and arena.players[2].is_bot, "Solo spawns one human and one bot")
	var viewport_size := get_viewport().get_visible_rect().size
	var sidebar_rect := MatchFrameUI.sidebar_rect_for_size(viewport_size)
	var arena_rect := MatchFrameUI.arena_panel_rect_for_size(viewport_size)
	check(is_equal_approx(sidebar_rect.size.x, MatchFrameUI.SIDEBAR_WIDTH), "player list keeps its compact width")
	check(is_equal_approx(sidebar_rect.end.x, viewport_size.x - MatchFrameUI.OUTER_MARGIN), "player list is flush with the right frame")
	check(is_equal_approx(arena_rect.position.x, MatchFrameUI.OUTER_MARGIN) and is_equal_approx(arena_rect.end.x + MatchFrameUI.PANEL_GAP, sidebar_rect.position.x), "arena fills the complete remaining width")

	var bot: PlayerController = arena.players[2]
	var bot_start := bot.global_position
	await get_tree().create_timer(3.0).timeout
	check(bot.global_position.distance_to(bot_start) > 4.0, "bot moves through normal movement API")
	check(bot_placed_seen or bot.active_water_balloons > 0, "bot seeks blocks and places a Water Balloon")

	var human: PlayerController = arena.players[1]
	human.place_water_balloon_request()
	await get_tree().create_timer(arena.match_config.water_balloon_duration + 0.25).timeout
	check(water_balloon_popped_seen, "Water Balloon reaches POP during live match")

	# Item drops are live during this smoke test; remove any pin the bot may
	# have collected so this assertion specifically covers natural timeout.
	if bot.is_in_bubble:
		bot.rescue(0, 0.0)
	bot.active_items = [GameConstants.ItemType.NONE]
	bot.invulnerability_remaining = 0.0
	bot.max_bubble_time = 0.1
	bot.hit_by_water(bot.grid_cell)
	await get_tree().create_timer(0.25).timeout
	check(not bot.is_alive, "bubbled bot reaches timeout and dies")
	await get_tree().create_timer(1.7).timeout
	check(arena.current_state == GameConstants.MatchState.RESULT, "winner reaches RESULT state")
	check(arena.hud.result_panel.visible, "Result screen is visible")
	check(not arena.hud.restart_btn.is_visible_in_tree() and not arena.hud.menu_btn.is_visible_in_tree(),
		"legacy result buttons stay hidden")
	check(arena.hud.result_return_label != null and arena.hud.auto_return_generation > 0,
		"result screen schedules the automatic three-second room return")

	arena.restart_match()
	await get_tree().process_frame
	check(arena.current_state == GameConstants.MatchState.COUNTDOWN and arena.players.size() == 2,
		"Play Again resets the arena and starts a fresh countdown")
	arena.queue_free()
	await get_tree().process_frame

	GameSession.configure_team(8, GameConstants.BotDifficulty.NORMAL, &"lego_city", &"cloud_bunny")
	var team_arena := load("res://scenes/match/MatchArena.tscn").instantiate() as MatchManager
	add_child(team_arena)
	await get_tree().process_frame
	check(team_arena.players.size() == 8 and team_arena.match_config.team_mode, "Team mode supports an eight-player roster")
	check(team_arena.players[1].character_def.id == "cloud_bunny", "active character selection is applied to the local player")
	var team_one := 0
	var team_two := 0
	for team_player in team_arena.players.values():
		team_one += 1 if team_player.team_id == 1 else 0
		team_two += 1 if team_player.team_id == 2 else 0
	check(team_one == 4 and team_two == 4, "eight-player team mode creates balanced 4v4 teams")

	print("PLAYABLE_SMOKE_RESULT: %d passed | %d failed" % [checks_run - failures.size(), failures.size()])
	get_tree().quit(0 if failures.is_empty() else 1)
