extends Node

var passed := 0
var failed := 0

func check(condition: bool, message: String) -> void:
	if condition:
		passed += 1
		print("[BOSS PASS] ", message)
	else:
		failed += 1
		push_error("[BOSS FAIL] %s" % message)

func _ready() -> void:
	GameSession.configure_boss(&"training_plaza", &"coral_diver")
	var arena: MatchManager = load("res://scenes/match/MatchArena.tscn").instantiate()
	add_child(arena)
	await get_tree().process_frame
	await get_tree().process_frame
	check(GameSession.play_mode == &"boss" and GameSession.bot_count == 0, "Boss mode is explicitly bot-free")
	check(arena.players.size() == 1 and arena.players.has(1), "Boss mode spawns only the invited/local human roster")
	check(arena.bot_controllers.is_empty(), "Boss mode never creates BotController opponents")
	check(is_instance_valid(arena.boss_encounter), "Boss encounter system is attached to the arena")
	arena.current_state = GameConstants.MatchState.PLAYING
	arena.boss_encounter.start_round(1)
	check(arena.map_definition.id == &"boss_pirate_ship", "Boss mode always loads the open pirate ship deck")
	check(GameSession.selected_map_id == &"pirate_harbor", "Boss mode locks map selection to Pirate Harbor")
	check(arena.boss_encounter.entities.size() == 4, "Round 1 starts with four simple squid minions")
	var round_signatures: Dictionary = {}
	for round_index in range(1, 4):
		var round_map := MapCatalog.create_boss_pirate_round(round_index)
		var breakables := 0
		var signature := ""
		for row in round_map.layout:
			for tile in row:
				if tile == GameConstants.TileType.DESTRUCTIBLE:
					breakables += 1
				signature += str(tile)
		round_signatures[signature] = true
		check(breakables >= 45, "Round %d has a full destructible cargo field" % round_index)
	check(round_signatures.size() == 3, "Rounds 1–3 use three distinct pirate-deck terrain layouts")
	var minion := arena.boss_encounter.entities[0]
	check(not minion.is_boss and minion.max_health == 1, "Round 1 minions are intentionally weak")
	check(minion.visual.sprite_frames.has_animation(&"walk_down") and minion.visual.sprite_frames.get_frame_count(&"walk_down") == 6, "Squid minions move with a real six-frame sprite-sheet cycle")
	var minion_cell := arena.grid_manager.world_to_grid(minion.global_position)
	check(arena.boss_encounter.damage_entities_in_cells([minion_cell], 1) == 1 and minion.trapped_in_bubble and minion.health > 0, "Player water traps a minion instead of killing it immediately")
	minion.pop_trapped_by_player()
	check(minion.health == 0, "A player crossing a trapped minion pops it and completes the defeat")
	for entity in arena.boss_encounter.entities.duplicate():
		if is_instance_valid(entity):
			entity.queue_free()
	arena.boss_encounter.entities.clear()
	arena.boss_encounter.start_round(4)
	var breakable_count := 0
	for row in arena.map_definition.layout:
		for tile in row:
			if tile == GameConstants.TileType.DESTRUCTIBLE:
				breakable_count += 1
	check(breakable_count == 16, "Round 4 has exactly four wood blocks around each of four pillars")
	var boss := arena.boss_encounter.entities[0]
	check(boss.is_boss and boss.max_health == 36, "Round 4 spawns the giant Pirate Octopus boss")
	check(boss.visual.sprite_frames.get_animation_names().size() == 4 and boss.visual.sprite_frames.get_frame_count(&"walk_left") == 6, "Boss cannon movement uses a four-direction animation sheet")
	check(boss.visual.sprite_frames.get_frame_texture(&"walk_up", 0) != boss.visual.sprite_frames.get_frame_texture(&"walk_down", 0), "Boss back view is a distinct directional pose")
	boss.take_water_damage(22, 1)
	check(boss.phase == 2 and boss.move_speed > 62.0, "Boss enrages after losing sixty percent health")
	check(is_equal_approx(boss.spiral_cooldown, 5.0), "Phase-two spiral skill uses the requested five-second cadence")
	arena.boss_encounter.warn_cross(Vector2i(8, 8), 2, 1.5)
	check(arena.boss_encounter.warning_cells.size() >= 5, "Close burst exposes an avoidable 1.5-second warning pattern")
	var cover_origin := Vector2i(4, 4)
	arena.grid_manager.set_cell_type(cover_origin + Vector2i.RIGHT, GameConstants.TileType.WALL)
	check(not arena.boss_encounter._line_clear(cover_origin, cover_origin + Vector2i.RIGHT * 2), "Boss water is blocked by cover, so hiding behind a block is safe")
	print("BOSS RESULT: %d passed | %d failed" % [passed, failed])
	arena.queue_free()
	get_tree().quit(1 if failed > 0 else 0)
