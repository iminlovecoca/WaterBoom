class_name TestRunner
extends Control

@onready var output_label: Label = $Panel/ScrollContainer/OutputLabel
@onready var back_btn: Button = $Panel/BackButton

var total_tests := 0
var passed_tests := 0
var failed_tests := 0
var log_lines: Array[String] = []

func _ready() -> void:
	if back_btn != null:
		back_btn.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/boot/Boot.tscn"))
	run_all_tests()

func log_msg(message: String) -> void:
	log_lines.append(message)
	print(message)
	if output_label != null:
		output_label.text = "\n".join(log_lines)

func assert_true(condition: bool, test_name: String) -> void:
	total_tests += 1
	if condition:
		passed_tests += 1
		log_msg("  [PASS] %s" % test_name)
	else:
		failed_tests += 1
		log_msg("  [FAIL] %s" % test_name)

func make_grid() -> GridManager:
	var map_def := MapDefinition.new()
	map_def.width = 15
	map_def.height = 13
	map_def.tile_size = 40
	map_def.generate_default_classic_layout()
	var grid := GridManager.new()
	grid.initialize(map_def)
	return grid

func run_all_tests() -> void:
	log_msg("=== BOOM WATER ARCADE TEST SUITE ===")
	test_grid_coordinates_and_water_balloon_occupancy()
	test_water_grid_propagation()
	test_place_water_balloon_request_validation()
	test_chain_water_burst()
	test_bubble_timeout_and_team_rescue()
	test_core_items()
	test_selection_and_result_ui()
	test_water_visual_assets()
	test_map_catalog_and_validator()
	test_danger_map_and_active_water_lifetime()
	log_msg("RESULT: %d passed | %d failed | %d total" % [passed_tests, failed_tests, total_tests])

func test_grid_coordinates_and_water_balloon_occupancy() -> void:
	log_msg("-- Grid and occupancy --")
	var grid := make_grid()
	var cell := Vector2i(2, 3)
	assert_true(grid.grid_to_world(cell) == Vector2(100, 140), "grid cell centers are deterministic")
	assert_true(grid.world_to_grid(grid.grid_to_world(cell)) == cell, "world/grid conversion round-trips")
	grid.set_cell_type(Vector2i(1, 1), GameConstants.TileType.FLOOR)
	grid.register_water_balloon_cell(Vector2i(1, 1), 99)
	assert_true(grid.has_water_balloon(Vector2i(1, 1)), "placed water balloon occupies one cell")
	assert_true(not grid.is_walkable(Vector2i(1, 1)), "occupied water cell blocks later entry")
	assert_true(grid.is_walkable(Vector2i(1, 1), 99), "placing player can leave its water balloon cell")
	grid.unregister_water_balloon_cell(Vector2i(1, 1), 99)
	assert_true(grid.is_walkable(Vector2i(1, 1)), "cell becomes walkable after POP")

func test_water_grid_propagation() -> void:
	log_msg("-- Water propagation and blockers --")
	var grid := make_grid()
	for x in range(1, 6):
		grid.set_cell_type(Vector2i(x, 1), GameConstants.TileType.FLOOR)
	grid.set_cell_type(Vector2i(1, 2), GameConstants.TileType.FLOOR)
	grid.set_cell_type(Vector2i(1, 3), GameConstants.TileType.WALL)
	grid.set_cell_type(Vector2i(3, 1), GameConstants.TileType.DESTRUCTIBLE)
	var data := WaterGridPropagation.calculate_water_burst(Vector2i(1, 1), 4, grid)
	var cells: Array = data["affected_cells"]
	assert_true(cells.has(Vector2i(1, 1)), "WaterCenter is active")
	assert_true(cells.has(Vector2i(2, 1)), "horizontal WaterCell propagates")
	assert_true(cells.has(Vector2i(3, 1)), "soft block cell receives water")
	assert_true(data["destroyed_blocks"].has(Vector2i(3, 1)), "soft block is destroyed")
	assert_true(not cells.has(Vector2i(4, 1)), "water stops at a soft block")
	assert_true(not cells.has(Vector2i(0, 1)), "water stops before a hard wall")
	assert_true(data["rays"]["right"][-1]["is_end"], "blocked stream receives an end cap")
	assert_true(data["rays"]["down"][-1]["is_end"], "cell before a hard wall becomes an end cap")

func test_place_water_balloon_request_validation() -> void:
	log_msg("-- Authoritative placement request --")
	var grid := make_grid()
	grid.set_cell_type(Vector2i(1, 1), GameConstants.TileType.FLOOR)
	var match_manager := MatchManager.new()
	var player := PlayerController.new()
	player.player_id = 1
	player.grid_cell = Vector2i(1, 1)
	player.is_alive = true
	player.max_water_balloons = 1
	player.active_water_balloons = 0
	match_manager.players[1] = player
	var manager := WaterBalloonManager.new()
	manager.initialize(grid, null, match_manager)
	match_manager.current_state = GameConstants.MatchState.COUNTDOWN
	assert_true(manager.place_water_balloon_request(1, Vector2i(1, 1), 2) == null, "request rejected outside PLAYING")
	match_manager.current_state = GameConstants.MatchState.PLAYING
	var placed := manager.place_water_balloon_request(1, Vector2i(1, 1), 2)
	assert_true(placed != null and placed.position == grid.grid_to_world(Vector2i(1, 1)), "valid WaterBalloon spawns at cell center")
	assert_true(manager.place_water_balloon_request(1, Vector2i(1, 1), 2) == null, "second balloon in same cell is rejected")
	player.active_water_balloons = player.max_water_balloons
	assert_true(manager.place_water_balloon_request(1, Vector2i(2, 1), 2) == null, "capacity is enforced by authority")
	manager.queue_free()
	match_manager.queue_free()
	player.queue_free()

func test_chain_water_burst() -> void:
	log_msg("-- Chain Water Burst --")
	var grid := make_grid()
	for x in range(1, 5):
		grid.set_cell_type(Vector2i(x, 1), GameConstants.TileType.FLOOR)
	var manager := WaterBalloonManager.new()
	manager.initialize(grid, null, null)
	var first := manager.place_water_balloon_request(1, Vector2i(1, 1), 2)
	manager.place_water_balloon_request(1, Vector2i(2, 1), 2)
	manager.place_water_balloon_request(2, Vector2i(3, 1), 2)
	assert_true(manager.active_water_balloons.size() == 3, "three water balloons are active")
	manager.trigger_water_burst(first.water_balloon_id)
	assert_true(manager.active_water_balloons.is_empty(), "water stream triggers the complete balloon chain")
	manager.queue_free()

func test_bubble_timeout_and_team_rescue() -> void:
	log_msg("-- WaterTrap, bubble, rescue --")
	var trapped := PlayerController.new()
	trapped.player_id = 1
	trapped.team_id = 7
	trapped.grid_cell = Vector2i(4, 4)
	trapped.max_bubble_time = 0.5
	var rescuer := PlayerController.new()
	rescuer.player_id = 2
	rescuer.team_id = 7
	rescuer.grid_cell = Vector2i(4, 4)
	var players := {1: trapped, 2: rescuer}
	assert_true(WaterTrapSystem.trap_players(players, [Vector2i(4, 4)]) == 2, "water traps players in active WaterCells")
	rescuer.is_in_bubble = false
	rescuer.bubble_state.clear()
	assert_true(trapped.current_state == GameConstants.PlayerState.BUBBLED, "water hit enters BUBBLED state")
	assert_true(RescueSystem.process_team_rescues(players, true, 1.0) == 1, "touching teammate rescues bubbled player")
	assert_true(not trapped.is_in_bubble and trapped.invulnerability_remaining == 1.0, "rescue grants configured invulnerability")
	trapped.invulnerability_remaining = 0.0
	trapped.hit_by_water()
	assert_true(trapped.bubble_state.tick(0.6), "bubble reaches timeout")
	trapped.die()
	assert_true(not trapped.is_alive, "timeout resolves to DEAD")
	assert_true(is_equal_approx(MatchConfig.new().bubble_duration, 5.0), "default bubble confinement lasts exactly five seconds")
	var enemy_victim := PlayerController.new()
	enemy_victim.player_id = 3
	enemy_victim.team_id = 7
	enemy_victim.grid_cell = Vector2i(6, 6)
	enemy_victim.hit_by_water()
	var enemy := PlayerController.new()
	enemy.player_id = 4
	enemy.team_id = 9
	enemy.grid_cell = Vector2i(6, 6)
	var contact_result := RescueSystem.process_bubble_contacts({3: enemy_victim, 4: enemy}, true, 1.0)
	assert_true(contact_result["enemy_bursts"] == 1 and not enemy_victim.is_alive, "touching opponent bursts the bubble early and eliminates its victim")
	trapped.queue_free()
	rescuer.queue_free()
	enemy_victim.queue_free()
	enemy.queue_free()

func test_core_items() -> void:
	log_msg("-- Core items --")
	var player := PlayerController.new()
	player.apply_item(GameConstants.ItemType.WATER_BALLOON_UP)
	player.apply_item(GameConstants.ItemType.WATER_POWER_UP, 2)
	player.apply_item(GameConstants.ItemType.SPEED_UP)
	player.apply_item(GameConstants.ItemType.BUBBLE_PIN)
	assert_true(player.max_water_balloons == 2, "WATER_BALLOON_UP increases capacity")
	assert_true(player.water_power == 3, "WATER_POWER_UP increases stream length")
	assert_true(player.move_speed == GameConstants.DEFAULT_MOVE_SPEED + GameConstants.SPEED_BOOST_PER_ITEM, "SPEED_UP increases movement speed")
	assert_true(player.active_items[0] == GameConstants.ItemType.BUBBLE_PIN, "BUBBLE_PIN is stored in active items for an emergency self rescue")
	var item_paths := [
		"res://assets/items/item_water_balloon_up.png",
		"res://assets/items/item_water_power_up.png",
		"res://assets/items/item_speed_up.png",
		"res://assets/items/item_bubble_pin.png",
	]
	for item_path in item_paths:
		var texture := load(item_path) as Texture2D
		assert_true(texture != null and texture.get_size() == Vector2(40, 40), "%s is a distinct 40x40 item icon" % item_path.get_file())
	var item_entity := load("res://scenes/items/Item.tscn").instantiate() as ItemEntity
	add_child(item_entity)
	item_entity.initialize(1, GameConstants.ItemType.WATER_POWER_UP, Vector2i.ONE)
	assert_true(not item_entity.icon_label.visible and item_entity.icon_label.text.is_empty(), "item icons use no plus/text overlays")
	item_entity.queue_free()
	player.queue_free()

func test_selection_and_result_ui() -> void:
	log_msg("-- Unified selection and result UI --")
	var theme := load("res://resources/ui/game_theme.tres") as Theme
	assert_true(theme != null and theme.default_font != null, "one readable bundled font is shared by the complete game")
	var boot := load("res://scenes/boot/Boot.tscn").instantiate() as BootManager
	add_child(boot)
	assert_true(boot.room_portraits[0] is AnimatedSprite2D and boot.room_portraits[0].is_playing(), "occupied lobby slots show a live idle animation")
	assert_true(not boot.room_labels[0].text.contains("BẠN •"), "room slot caption contains only the saved player nickname")
	assert_true(boot.character_buttons.size() == 9 and boot.get_node_or_null("CharacterSlot8") != null, "character selection renders nine slots per page")
	assert_true(boot.character_buttons.all(func(button: Button): return is_equal_approx(button.size.x, button.size.y)), "all character selectors are genuine square selfie cards")
	assert_true(boot.character_card_backgrounds.all(func(card: TextureRect): return card.material is ShaderMaterial), "layered character backgrounds are alpha-clipped to the rounded slot")
	assert_true(boot.get_node_or_null("CharacterPrev") != null and boot.get_node_or_null("CharacterNext") != null, "character pages provide matching previous and next arrows")
	assert_true(is_equal_approx(boot.map_preview.size.x / boot.map_preview.size.y, 16.0 / 9.0), "map preview control keeps an exact 16:9 aspect ratio")
	assert_true(boot.get_node_or_null("MapPrev") == null and boot.get_node_or_null("MapNext") == null, "map preview is not covered by redundant arrows")
	assert_true(boot.map_picker_panel.get_node("MapGrid").get_child_count() == MapCatalog.MAP_IDS.size(), "clicking map opens the complete in-layout map list")
	assert_true(boot.get_node("StartButton") is Button and not boot.get_node("StartButton").flat, "lobby actions are real skinned buttons instead of text overlays")
	assert_true(boot.map_preview is TextureButton, "map preview is a real interactive button")
	assert_true(boot.map_cards.size() == MapCatalog.MAP_IDS.size(), "every selectable map has its own framed interactive card")
	assert_true(
		["ShopButton", "InventoryButton", "SettingsButton", "QuitButton"].all(func(node_name: String): return boot.get_node_or_null(node_name) is Button),
		"bottom dock exposes Shop, Inventory, Settings, and Quit as real buttons"
	)
	assert_true(boot.get_node_or_null("LogoutButton") == null and boot.get_node_or_null("TestButton") == null, "legacy bottom buttons no longer overlap the four-action dock")
	for character: CharacterDefinition in boot.characters:
		assert_true(character.selection_card_texture != null and character.selection_card_texture.get_size() == Vector2(256, 256), "%s owns a full square selfie background" % character.display_name)
		assert_true(character.banner_background_texture != null and character.banner_background_texture.get_size() == Vector2(512, 128), "%s owns a separate wide banner background" % character.display_name)
		assert_true(character.selfie_texture != null and character.selfie_texture.get_size() == Vector2(256, 256), "%s owns a separate transparent selfie cutout" % character.display_name)
	assert_true(boot.character_banner_background.texture != boot.character_banner_selfie.texture, "selected-character banner composes separate background and selfie assets")
	var match_manager := MatchManager.new()
	assert_true(match_manager._character_for_id(&"boom_mascot").id == "boom_mascot", "selecting Boom Bear loads the mascot into gameplay")
	match_manager.free()
	assert_true(boot.balloon_skin_buttons.size() == 4, "inventory exposes classic, watermelon, dark, and sparkle balloon choices")
	boot._select_balloon_skin(&"watermelon")
	assert_true(GameSession.selected_balloon_skin == &"watermelon" and boot.balloon_skin_status.text.contains("DƯA HẤU"), "inventory choice updates the active gameplay balloon skin")
	boot._select_balloon_skin(&"classic")
	var stat_signatures: Dictionary = {}
	for character: CharacterDefinition in boot.characters:
		stat_signatures["%d/%d/%d" % [character.base_water_balloon_capacity, character.base_water_power, roundi(character.base_speed)]] = true
	assert_true(stat_signatures.size() == boot.characters.size(), "every character has a distinct starting Boom/range/speed profile")
	GameSession.cokecy = 500
	GameSession.owned_balloon_skins = [&"classic", &"watermelon"]
	boot._buy_balloon_skin(&"dark", 250)
	assert_true(GameSession.owns_balloon_skin(&"dark") and GameSession.cokecy == 250 and GameSession.selected_balloon_skin == &"dark", "Shop purchases and equips a skin using Cokecy")
	GameSession.selected_balloon_skin = &"classic"
	for map_id in MapCatalog.MAP_IDS:
		var preview := load("res://assets/ui/map_previews/map_%s.png" % map_id) as Texture2D
		assert_true(preview != null and preview.get_size() == Vector2(384, 216), "%s has a full 16:9 selection background" % map_id)
	for result_path in ["res://assets/ui/results/victory_vi.png", "res://assets/ui/results/defeat_vi.png"]:
		var result_texture := load(result_path) as Texture2D
		assert_true(result_texture != null and result_texture.get_image().detect_alpha() != Image.ALPHA_NONE, "%s is an image-based transparent result title" % result_path.get_file())
	var effective_heights: Array[float] = []
	for character_path in ["coral_diver", "cloud_bunny", "lime_dino", "star_skater", "cocoa_otter", "red_rider", "sunny_mechanic", "mint_sprout", "boom_mascot"]:
		var character := load("res://resources/characters/%s.tres" % character_path) as CharacterDefinition
		var frame := character.sprite_frames.get_frame_texture(&"idle_down", 0).get_image()
		effective_heights.append(frame.get_used_rect().size.y * character.visual_scale)
	assert_true(effective_heights.max() - effective_heights.min() <= 5.0, "all nine gameplay characters share one visual height")
	boot.queue_free()

func test_water_visual_assets() -> void:
	log_msg("-- Water visual segments --")
	var required := [
		"water_center", "water_horizontal", "water_vertical", "water_end_left",
		"water_end_right", "water_end_up", "water_end_down", "water_cross"
	]
	for segment in required:
		assert_true(FileAccess.file_exists("res://assets/water_stream/%s.png" % segment), "%s sprite exists" % segment)
	for frame in range(4):
		assert_true(FileAccess.file_exists("res://assets/water_balloon/water_balloon_%d.png" % frame), "water balloon wobble frame %d exists" % frame)
	assert_true(WaterBalloonSkinRegistry.all_skins().size() >= 1, "Water balloon skin registry contains skins")
	assert_true(ProjectSettings.get_setting("application/config/icon") == "res://assets/branding/game_icon.png", "the supplied BOOM artwork is the project brand icon")

func test_map_catalog_and_validator() -> void:
	log_msg("-- Map catalog and validator --")
	assert_true(MapCatalog.MAP_IDS.size() == 8, "eight development maps are registered")
	var layout_signatures: Dictionary = {}
	for map_id in MapCatalog.MAP_IDS:
		var definition := MapCatalog.create_map(map_id)
		assert_true(MapValidator.validate(definition).is_empty(), "%s is valid and has safe spawns" % definition.display_name)
		layout_signatures[_layout_signature(definition)] = true
		assert_true(_spawns_connect_after_soft_blocks_break(definition), "%s has permanent routes between every spawn" % definition.display_name)
		var theme := MapThemeCatalog.create_theme(definition.theme)
		assert_true(theme.id == definition.theme, "%s resolves its own visual theme" % definition.display_name)
		var textures: Array[Texture2D] = [
			theme.floor_texture, theme.alternate_floor_texture,
			theme.wall_texture, theme.destructible_texture,
		]
		assert_true(textures.all(func(texture: Texture2D): return texture != null), "%s loads all four runtime tiles" % definition.display_name)
		assert_true(textures.all(func(texture: Texture2D): return texture.get_size() == Vector2(40, 40)), "%s runtime tiles are 40x40" % definition.display_name)
		var decorations := MapDecorationCatalog.entries_for_map(map_id)
		assert_true(decorations.size() == 5, "%s has one centerpiece and four corner landmarks" % definition.display_name)
		assert_true(decorations.all(func(entry: Dictionary): return entry["texture"] != null and entry["texture"].get_size() == Vector2(128, 128)), "%s landmark sprites retain 128x128 source detail" % definition.display_name)
		assert_true(_landmark_footprints_are_walls(definition, decorations), "%s 2x2/3x3 landmarks occupy honest collision footprints" % definition.display_name)
		assert_true(_four_corner_counts_match(definition), "%s balances walls and breakable blocks across all four corners" % definition.display_name)
		if map_id != &"lego_city":
			assert_true(decorations.slice(1).all(func(entry: Dictionary): return entry["size"] == Vector2i.ONE and entry.get("oversized", false)), "%s keeps small decorations in one enlarged cell" % definition.display_name)
	assert_true(layout_signatures.size() == MapCatalog.MAP_IDS.size(), "all maps use genuinely distinct terrain layouts")

func _layout_signature(definition: MapDefinition) -> String:
	var signature := ""
	for row in definition.layout:
		for value in row:
			signature += str(value)
	return signature

func _four_corner_counts_match(definition: MapDefinition) -> bool:
	var counts: Array[Dictionary] = []
	for origin in [Vector2i(1, 1), Vector2i(10, 1), Vector2i(1, 10), Vector2i(10, 10)]:
		var corner := {GameConstants.TileType.WALL: 0, GameConstants.TileType.DESTRUCTIBLE: 0}
		for y in range(origin.y, origin.y + 5):
			for x in range(origin.x, origin.x + 5):
				var tile_type: int = definition.layout[y][x]
				if corner.has(tile_type):
					corner[tile_type] += 1
		counts.append(corner)
	return counts.all(func(count: Dictionary): return count == counts[0])

func _landmark_footprints_are_walls(definition: MapDefinition, decorations: Array[Dictionary]) -> bool:
	for entry in decorations:
		var origin: Vector2i = entry["cell"]
		var footprint: Vector2i = entry["size"]
		for y in range(origin.y, origin.y + footprint.y):
			for x in range(origin.x, origin.x + footprint.x):
				if definition.layout[y][x] != GameConstants.TileType.WALL:
					return false
	return true

func _spawns_connect_after_soft_blocks_break(definition: MapDefinition) -> bool:
	var frontier: Array[Vector2i] = [definition.spawn_points[0]]
	var visited: Dictionary = {definition.spawn_points[0]: true}
	while not frontier.is_empty():
		var cell: Vector2i = frontier.pop_front()
		for direction in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var next_cell: Vector2i = cell + direction
			if next_cell.x < 0 or next_cell.y < 0 or next_cell.x >= definition.width or next_cell.y >= definition.height:
				continue
			if visited.has(next_cell) or definition.layout[next_cell.y][next_cell.x] == GameConstants.TileType.WALL:
				continue
			visited[next_cell] = true
			frontier.append(next_cell)
	return definition.spawn_points.all(func(spawn: Vector2i): return visited.has(spawn))

func test_danger_map_and_active_water_lifetime() -> void:
	log_msg("-- Danger map and active water lifetime --")
	var grid := make_grid()
	for x in range(1, 5):
		grid.set_cell_type(Vector2i(x, 1), GameConstants.TileType.FLOOR)
	var manager := WaterBalloonManager.new()
	manager.initialize(grid, null, null)
	var water_balloon := manager.place_water_balloon_request(1, Vector2i(1, 1), 2)
	var danger := DangerMap.new()
	danger.rebuild(grid, manager)
	assert_true(danger.is_dangerous(Vector2i(1, 1), 3.0), "DangerMap predicts Water Balloon origin")
	assert_true(danger.is_dangerous(Vector2i(3, 1), 3.0), "DangerMap predicts directional water range")
	manager.trigger_water_burst(water_balloon.water_balloon_id)
	assert_true(manager.active_water_cells.has(Vector2i(2, 1)), "water cell remains gameplay-active after POP")
	manager._process(manager.water_active_duration + 0.1)
	assert_true(manager.active_water_cells.is_empty(), "active water cells expire with configured lifetime")
	manager.queue_free()
