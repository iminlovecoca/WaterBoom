class_name MatchManager
extends Node2D

const BOOM_MASCOT: CharacterDefinition = preload("res://resources/characters/boom_mascot.tres")
const CLOUD_BUNNY: CharacterDefinition = preload("res://resources/characters/cloud_bunny.tres")
const SHADOW_NINJA: CharacterDefinition = preload("res://resources/characters/shadow_ninja.tres")
const AQUA_PACIFIER: CharacterDefinition = preload("res://resources/characters/aqua_pacifier.tres")

@export var map_definition: MapDefinition
@export var match_config: MatchConfig
@export var match_rules: MatchRules
@export var player_scene: PackedScene = preload("res://scenes/characters/Player.tscn")

var current_state: GameConstants.MatchState = GameConstants.MatchState.WAITING
var time_left_seconds: float = 180.0
var countdown_timer: float = 3.0

var grid_manager: GridManager
var players: Dictionary = {} # player_id -> PlayerController
var spawn_slots: Array = []
var bot_controllers: Array[BotController] = []
var boss_encounter: BossEncounterManager

@onready var arena_map: ArenaMap = $ArenaMap
@onready var water_balloon_manager: WaterBalloonManager = $WaterBalloonManager
@onready var item_manager: ItemManager = $ItemManager
@onready var water_stream_renderer: WaterStreamRenderer = $WaterStreamRenderer
@onready var hud: Control = $MatchHUD

func _ready() -> void:
	if multiplayer.has_multiplayer_peer():
		multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	SoundManager.stop_bgm()
	if map_definition == null:
		map_definition = MapCatalog.create_map(GameSession.selected_map_id)
	if match_config == null:
		match_config = MatchConfig.new()
	if match_rules == null:
		match_rules = MatchRules.new()
	match_config.team_mode = GameSession.team_mode
	match_rules.mode = MatchRules.Mode.TEAM if match_config.team_mode else MatchRules.Mode.FREE_FOR_ALL
	if not EventBus.player_died.is_connected(_on_player_died):
		EventBus.player_died.connect(_on_player_died)
		
	start_match_session()

func start_match_session() -> void:
	current_state = GameConstants.MatchState.WAITING
	if GameSession.play_mode == &"boss":
		map_definition = MapCatalog.create_boss_pirate_round(1)
	elif map_definition == null or map_definition.id != GameSession.selected_map_id:
		map_definition = MapCatalog.create_map(GameSession.selected_map_id)
	var map_errors := MapValidator.validate(map_definition)
	if not map_errors.is_empty():
		push_error("Invalid map '%s': %s" % [map_definition.display_name, "; ".join(map_errors)])
	# 1. Dynamically calculate optimal tile size to fill available arena space
	var viewport_size := get_viewport_rect().size
	var sidebar := MatchFrameUI.sidebar_rect_for_size(viewport_size)
	var available_w: float = sidebar.position.x - MatchFrameUI.PANEL_GAP - MatchFrameUI.OUTER_MARGIN
	var available_h: float = viewport_size.y - MatchFrameUI.TOP_MARGIN - MatchFrameUI.BOTTOM_MARGIN
	var tile_w: float = floor(available_w / float(map_definition.width))
	var tile_h: float = floor(available_h / float(map_definition.height))
	# Scale the complete board to the largest square that fits beside the fixed
	# sidebar. All map sprites/collisions derive their size from this value.
	map_definition.tile_size = maxi(24, int(minf(tile_w, tile_h)))

	grid_manager = GridManager.new()
	grid_manager.initialize(map_definition)
	grid_manager.corner_assist_strength = match_config.corner_assist_strength
	var board_size := Vector2(map_definition.width, map_definition.height) * map_definition.tile_size
	grid_manager.world_origin = MatchFrameUI.board_origin_for(viewport_size, board_size)
	RenderingServer.set_default_clear_color(Color("#081424"))
	
	# 2. Setup Subsystems
	arena_map.setup_map(grid_manager, map_definition)
	water_balloon_manager.initialize(grid_manager, water_stream_renderer, self)
	item_manager.initialize(grid_manager, self, map_definition.item_drop_rate)
	
	# 3. Clear existing players
	for p in players.values():
		if is_instance_valid(p):
			p.queue_free()
	players.clear()
	bot_controllers.clear()
	if is_instance_valid(boss_encounter):
		boss_encounter.queue_free()
	boss_encounter = null
	
	# 4. Spawn either a Solo roster (human + bots) or local two-player roster.
	if GameSession.play_mode == &"boss":
		spawn_player(1, map_definition.spawn_points[0], "p1", GameSession.player_nickname, Color(0.2, 0.72, 1.0), 1, false)
		boss_encounter = BossEncounterManager.new()
		add_child(boss_encounter)
		boss_encounter.initialize(self, grid_manager)
	elif GameSession.play_mode == &"solo":
		spawn_player(1, map_definition.spawn_points[0], "p1", GameSession.player_nickname, Color(0.2, 0.72, 1.0), 1, false)
		var requested_bots := mini(GameSession.bot_count, map_definition.spawn_points.size() - 1)
		for bot_index in range(requested_bots):
			var bot_id := bot_index + 2
			spawn_player(bot_id, map_definition.spawn_points[bot_index + 1], "bot", "Aqua Bot %d" % (bot_index + 1), Color(1.0, 0.45 + bot_index * 0.12, 0.3), bot_id, true)
		for bot in bot_controllers:
			bot.initialize(bot.player, grid_manager, water_balloon_manager, item_manager, self, GameSession.bot_difficulty)
	elif GameSession.play_mode == &"multiplayer":
		var room_data = {}
		if has_node("/root/RoomManager") and RoomManager.current_room_id != "":
			room_data = RoomManager.active_rooms.get(RoomManager.current_room_id, {})
		
		var players = room_data.get("players", [1])
		var spawn_idx = 0
		
		var host_id = room_data.get("host", 1)
		var bots_to_spawn = room_data.get("bots", 0)
		var diff = room_data.get("diff", GameConstants.BotDifficulty.NORMAL)
		
		var frozen_players: Dictionary = room_data.get("match_player_snapshot", {})
		for p_id in players:
			if spawn_idx >= map_definition.spawn_points.size():
				break
			var p_data = {}
			if frozen_players.has(p_id):
				p_data = frozen_players[p_id]
			elif has_node("/root/RoomManager"):
				p_data = RoomManager.room_players.get(p_id, {})
			
			var char_id_str = str(p_data.get("char_id", ""))
			var col_idx = p_data.get("color_idx", 0)
			var p_name = p_data.get("name", "Player " + str(p_id))
			var is_local = (p_id == multiplayer.get_unique_id())
			var control = "p1" if is_local else "bot"
			
			var p_inst = spawn_player(p_id, map_definition.spawn_points[spawn_idx], control, p_name, Color(0.2 + col_idx*0.2, 0.7, 1.0), 1, false)
			p_inst.balloon_skin_id = StringName(p_data.get("balloon_skin", "skin_066"))
			p_inst.set_equipment_snapshot(p_data.get("equipment", CosmeticRegistry.default_equipment()))
			
			var correct_def: CharacterDefinition = null
			if char_id_str != "":
				correct_def = _character_for_id(StringName(char_id_str))
			else:
				var char_idx = p_data.get("char_idx", 0)
				var player_roster: Array[CharacterDefinition] = [BOOM_MASCOT, CLOUD_BUNNY, SHADOW_NINJA, AQUA_PACIFIER]
				correct_def = player_roster[char_idx % player_roster.size()]
				
			if p_inst.has_method("_apply_character_definition"):
				p_inst._apply_character_definition(correct_def)
			if p_inst.visual != null and p_inst.visual.has_method("setup"):
				p_inst.visual.setup(correct_def)
			spawn_idx += 1
			
		for b in range(bots_to_spawn):
			if spawn_idx >= map_definition.spawn_points.size():
				break
			var bot_id = 9000 + b
			var p_name = "Aqua Bot %d" % (b + 1)
			var p_inst = spawn_player(bot_id, map_definition.spawn_points[spawn_idx], "bot", p_name, Color(1.0, 0.45 + b * 0.12, 0.3), bot_id, true)
			p_inst.set_multiplayer_authority(host_id) # The host controls the bots
			
			var bot_roster: Array[CharacterDefinition] = [CLOUD_BUNNY, BOOM_MASCOT, SHADOW_NINJA, AQUA_PACIFIER]
			var bot_def = bot_roster[b % bot_roster.size()]
			if p_inst.has_method("_apply_character_definition"):
				p_inst._apply_character_definition(bot_def)
			if p_inst.visual != null and p_inst.visual.has_method("setup"):
				p_inst.visual.setup(bot_def)
			spawn_idx += 1
			
		for bot in bot_controllers:
			if multiplayer.get_unique_id() == host_id:
				bot.initialize(bot.player, grid_manager, water_balloon_manager, item_manager, self, diff)

	elif GameSession.play_mode == &"team":
		var roster_size := mini(GameSession.player_count, mini(map_definition.spawn_points.size(), 8))
		for player_index in range(roster_size):
			var player_id := player_index + 1
			var team_id := 1 if player_id % 2 == 1 else 2
			spawn_player(player_id, map_definition.spawn_points[player_index], "p1" if player_id == 1 else "bot", GameSession.player_nickname if player_id == 1 else "Team Bot %d" % player_id, Color("#43bfff") if team_id == 1 else Color("#ff6262"), team_id, player_id != 1)
		for bot in bot_controllers:
			bot.initialize(bot.player, grid_manager, water_balloon_manager, item_manager, self, GameSession.bot_difficulty)
	else:
		spawn_player(1, map_definition.spawn_points[0], "p1", GameSession.player_nickname, Color(0.2, 0.72, 1.0), 1, false)
		spawn_player(2, map_definition.spawn_points[1], "p2", "Player 2", Color(1.0, 0.42, 0.4), 2, false)
	
	# 5. Set State to Countdown
	time_left_seconds = float(match_config.match_duration_seconds)
	countdown_timer = float(match_config.countdown_seconds)
	_set_match_state(GameConstants.MatchState.COUNTDOWN)

func spawn_player(p_id: int, cell: Vector2i, control: String, nickname: String, col: Color, team_id: int = 0, as_bot: bool = false) -> PlayerController:
	var p_inst = player_scene.instantiate() as PlayerController
	if p_id == 1 or p_id == multiplayer.get_unique_id():
		p_inst.character_def = _character_for_id(GameSession.selected_character_id)
	else:
		var bot_roster: Array[CharacterDefinition] = [CLOUD_BUNNY, BOOM_MASCOT, SHADOW_NINJA, AQUA_PACIFIER]
		p_inst.character_def = bot_roster[(p_id - 2) % bot_roster.size()]
	p_inst.control_scheme = control
	p_inst.is_local_control = (control == "p1" or control == "p2") and not as_bot
	p_inst.is_bot = as_bot
	p_inst.display_name = nickname
	p_inst.player_id = p_id
	p_inst.team_id = team_id if team_id != 0 else p_id
	p_inst.equipment_snapshot = GameSession.equipped_cosmetics.duplicate(true) if p_inst.is_local_control else CosmeticRegistry.default_equipment()
	p_inst.set_multiplayer_authority(p_id)
	add_child(p_inst)
	p_inst.initialize(p_id, cell, grid_manager, water_balloon_manager, team_id if team_id != 0 else p_id)
	p_inst.max_bubble_time = match_config.bubble_duration
	
	if p_inst.visual != null and p_inst.visual.has_method("set_player_name"):
		p_inst.visual.set_player_name(nickname, col)
		p_inst.visual.set_development_color(col)
		
	players[p_id] = p_inst
	if as_bot:
		var bot := BotController.new()
		bot.player = p_inst
		p_inst.add_child(bot)
		bot_controllers.append(bot)
	return p_inst

func _character_for_id(character_id: StringName) -> CharacterDefinition:
	match character_id:
		&"boom_mascot": return BOOM_MASCOT
		&"cloud_bunny": return CLOUD_BUNNY
		&"shadow_ninja": return SHADOW_NINJA
		&"aqua_pacifier": return AQUA_PACIFIER
		_: return BOOM_MASCOT

func apply_boss_round_layout(round_index: int) -> void:
	if GameSession.play_mode != &"boss" or grid_manager == null:
		return
	map_definition = MapCatalog.create_boss_pirate_round(round_index)
	var origin := grid_manager.world_origin
	grid_manager.initialize(map_definition)
	grid_manager.world_origin = origin
	arena_map.setup_map(grid_manager, map_definition)
	water_balloon_manager.initialize(grid_manager, water_stream_renderer, self)
	item_manager.initialize(grid_manager, self, map_definition.item_drop_rate)
	for player_id in players:
		var player: PlayerController = players[player_id]
		if player == null or not player.is_alive:
			continue
		var spawn_index := mini(int(player_id) - 1, map_definition.spawn_points.size() - 1)
		player.grid_cell = map_definition.spawn_points[spawn_index]
		player.global_position = grid_manager.grid_to_world(player.grid_cell)

func _process(delta: float) -> void:
	match current_state:
		GameConstants.MatchState.COUNTDOWN:
			countdown_timer -= delta
			var sec = int(ceil(countdown_timer))
			EventBus.match_countdown_tick.emit(sec)
			if countdown_timer <= 0.0:
				_set_match_state(GameConstants.MatchState.PLAYING)
				EventBus.match_started.emit()
				
		GameConstants.MatchState.PLAYING:
			time_left_seconds -= delta
			check_water_cells(water_balloon_manager.active_water_cells.keys())
			if time_left_seconds <= 0.0:
				time_left_seconds = 0.0
				_evaluate_game_over(true) # Time out draw/winner
			_check_rescue_interactions()

func _set_match_state(new_state: GameConstants.MatchState) -> void:
	var old_state = current_state
	current_state = new_state
	EventBus.match_state_changed.emit(old_state, new_state)

func check_water_cells(water_cells: Array) -> void:
	WaterTrapSystem.trap_players(players, water_cells)
	if item_manager != null and item_manager.has_method("destroy_items_in_cells"):
		item_manager.destroy_items_in_cells(water_cells)

func check_enemy_water_cells(water_cells: Array, owner_id: int) -> int:
	if GameSession.play_mode == &"boss" and is_instance_valid(boss_encounter):
		return boss_encounter.damage_entities_in_cells(water_cells, owner_id)
	return 0

func _check_rescue_interactions() -> void:
	RescueSystem.process_bubble_contacts(players, match_config.team_mode, match_config.rescue_invulnerability_seconds)

func can_player_place_water_balloon(player_id: int, requested_cell: Vector2i) -> bool:
	if current_state != GameConstants.MatchState.PLAYING or not players.has(player_id):
		return false
	var player: PlayerController = players[player_id]
	return player.is_alive and not player.is_in_bubble and player.grid_cell == requested_cell and player.active_water_balloons < player.max_water_balloons

func notify_player_water_balloon_popped(owner_id: int) -> void:
	if players.has(owner_id):
		players[owner_id].on_water_balloon_popped()

func _on_player_died(_player_id: int) -> void:
	_check_win_conditions()

func resolve_bubble_timeout(player: PlayerController) -> void:
	match_rules.resolve_bubble_timeout(player)

func apply_item_to_player(player_id: int, item_type: int) -> void:
	if players.has(player_id):
		players[player_id].apply_item(item_type)


func can_player_collect_item(player_id: int, item_type: int) -> bool:
	if not players.has(player_id):
		return false
	var player: PlayerController = players[player_id]
	return player != null and player.can_collect_item(item_type)

func _check_win_conditions() -> void:
	if current_state != GameConstants.MatchState.PLAYING:
		return
	if GameSession.play_mode == &"boss":
		var local_player: PlayerController = get_local_player()
		if local_player == null or not local_player.is_alive:
			finish_boss_encounter(false)
		return
	if match_config.team_mode:
		var alive_teams: Dictionary = {}
		for team_player in players.values():
			if team_player != null and team_player.is_alive:
				alive_teams[team_player.team_id] = true
		if alive_teams.size() <= 1:
			_evaluate_game_over(false)
		return

	var alive_players: Array[int] = []
	for p_id in players.keys():
		var p: PlayerController = players[p_id]
		if p != null and p.is_alive:
			alive_players.append(p_id)
			
	if alive_players.size() <= 1:
		_evaluate_game_over(false)

func _evaluate_game_over(is_timeout: bool) -> void:
	if current_state == GameConstants.MatchState.RESULT or current_state == GameConstants.MatchState.ENDING:
		return
		
	_set_match_state(GameConstants.MatchState.ENDING)
	
	var alive_players: Array[int] = []
	for p_id in players.keys():
		var p: PlayerController = players[p_id]
		if p != null and p.is_alive:
			alive_players.append(p_id)
			
	var winner_id = 0
	var winning_team_id := 0
	var is_draw = false

	if match_config.team_mode and not alive_players.is_empty():
		winning_team_id = players[alive_players[0]].team_id
		for alive_id in alive_players:
			if players[alive_id].team_id != winning_team_id:
				winning_team_id = 0
				break
		if winning_team_id != 0:
			winner_id = alive_players[0]
		else:
			is_draw = true
	elif alive_players.size() == 1:
		winner_id = alive_players[0]
	else:
		is_draw = true

	for player_id in players:
		var player: PlayerController = players[player_id]
		if player == null or player.visual == null:
			continue
		var player_won: bool = not is_draw and (player_id == winner_id or (winning_team_id != 0 and player.team_id == winning_team_id))
		if player_won and player.visual.has_method("play_win"):
			player.visual.play_win()
		elif player.visual.has_method("play_lose"):
			player.visual.play_lose()
		
	EventBus.match_ended.emit(winner_id, is_draw)
	
	# Delay transition to result screen
	var timer = get_tree().create_timer(1.5)
	timer.timeout.connect(func(): _set_match_state(GameConstants.MatchState.RESULT))

func restart_match() -> void:
	start_match_session()

func finish_boss_encounter(success: bool) -> void:
	if current_state == GameConstants.MatchState.ENDING or current_state == GameConstants.MatchState.RESULT:
		return
	_set_match_state(GameConstants.MatchState.ENDING)
	var local_player: PlayerController = get_local_player()
	if local_player != null and local_player.visual != null:
		if success and local_player.visual.has_method("play_win"):
			local_player.visual.play_win()
		elif not success and local_player.visual.has_method("play_lose"):
			local_player.visual.play_lose()
	EventBus.match_ended.emit(1 if success else 0, false)
	get_tree().create_timer(1.5).timeout.connect(func(): _set_match_state(GameConstants.MatchState.RESULT))

func _on_peer_disconnected(id: int) -> void:
	if players.has(id):
		var p = players[id]
		if p != null and is_instance_valid(p):
			p.queue_free()
		players.erase(id)
	_check_win_conditions()


func get_player(id: int) -> PlayerController:
	return players.get(id)

func get_local_player() -> PlayerController:
	var uid = multiplayer.get_unique_id()
	if players.has(uid):
		return players[uid]
	if players.has(1):
		return players[1]
	for p in players.values():
		if p != null and (p.is_local_control or p.is_multiplayer_authority()):
			return p
	return null
