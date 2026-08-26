extends Node

var failures: Array[String] = []
var checks_run := 0


class InventoryGate:
	extends Node
	var allow_collect := false
	var applied_count := 0

	func can_player_collect_item(_player_id: int, _item_type: int) -> bool:
		return allow_collect

	func apply_item_to_player(_player_id: int, _item_type: int) -> void:
		applied_count += 1


func _ready() -> void:
	_run.call_deferred()


func check(condition: bool, label: String) -> void:
	checks_run += 1
	if condition:
		print("[MAP GAMEPLAY PASS] ", label)
	else:
		print("[MAP GAMEPLAY FAIL] ", label)
		failures.append(label)


func _run() -> void:
	for map_id in MapCatalog.MAP_IDS:
		var definition := MapCatalog.create_map(map_id)
		var grid := GridManager.new()
		grid.initialize(definition)
		var spawn: Vector2i = definition.spawn_points[0]
		check(grid.is_walkable(spawn), "%s spawn cell is walkable" % map_id)
		var outside := Vector2i(-1, spawn.y)
		check(not grid.is_valid_cell(outside) and not grid.is_walkable(outside), "%s world boundary replaces the removed in-grid frame" % map_id)

		var border_burst := WaterGridPropagation.calculate_water_burst(spawn, 6, grid)
		check(not border_burst["affected_cells"].has(outside), "%s Water Burst stops at the true 16x16 world boundary" % map_id)

		var soft_test := _find_floor_to_soft_pair(definition)
		check(not soft_test.is_empty(), "%s exposes a valid floor-to-breakable test lane" % map_id)
		if not soft_test.is_empty():
			var origin: Vector2i = soft_test["origin"]
			var soft: Vector2i = soft_test["soft"]
			var beyond: Vector2i = soft + (soft - origin)
			var burst := WaterGridPropagation.calculate_water_burst(origin, 6, grid)
			check(burst["affected_cells"].has(soft), "%s Water Burst reaches the first breakable" % map_id)
			check(burst["destroyed_blocks"].has(soft), "%s breakable is registered for destruction" % map_id)
			check(not grid.is_valid_cell(beyond) or not burst["affected_cells"].has(beyond), "%s Water Burst stops after the breakable" % map_id)
	_test_item_drop_pipeline()
	_test_held_item_pickup_gate()
	print("MAP_GAMEPLAY_REGRESSION_RESULT: %d passed | %d failed" % [checks_run - failures.size(), failures.size()])
	get_tree().quit(0 if failures.is_empty() else 1)


func _find_floor_to_soft_pair(definition: MapDefinition) -> Dictionary:
	for y in range(1, definition.height - 1):
		for x in range(1, definition.width - 1):
			var origin := Vector2i(x, y)
			if definition.layout[y][x] != GameConstants.TileType.FLOOR:
				continue
			for direction in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
				var soft: Vector2i = origin + direction
				if definition.layout[soft.y][soft.x] == GameConstants.TileType.DESTRUCTIBLE:
					return {"origin": origin, "soft": soft}
	return {}


func _test_item_drop_pipeline() -> void:
	var definition := MapCatalog.create_map(&"aqua_park")
	var grid := GridManager.new()
	grid.initialize(definition)
	var test_cell := Vector2i(2, 2)
	grid.set_cell_type(test_cell, GameConstants.TileType.FLOOR)
	var item_manager := ItemManager.new()
	add_child(item_manager)
	item_manager.initialize(grid, null, 1.0)
	item_manager._on_block_destroyed(test_cell)
	check(item_manager.active_items_by_cell.has(test_cell) and grid.has_item(test_cell), "destroyed breakable can still produce a collectible item drop")
	item_manager.queue_free()


func _test_held_item_pickup_gate() -> void:
	var player := PlayerController.new()
	player.active_items = [GameConstants.ItemType.BUBBLE_PIN]
	check(not player.can_collect_item(GameConstants.ItemType.SHIELD), "occupied Ctrl slot rejects a replacement held item")
	player._add_active_item(GameConstants.ItemType.SHIELD)
	check(player.active_items[0] == GameConstants.ItemType.BUBBLE_PIN, "rejected pickup never overwrites the unused held item")
	player.free()

	var definition := MapCatalog.create_map(&"training_plaza")
	var grid := GridManager.new()
	grid.initialize(definition)
	var gate := InventoryGate.new()
	add_child(gate)
	var item_manager := ItemManager.new()
	add_child(item_manager)
	item_manager.initialize(grid, gate, 0.0)
	var test_cell := Vector2i(2, 2)
	item_manager.spawn_item_at_cell(test_cell, GameConstants.ItemType.SHIELD)
	item_manager._on_player_moved(1, test_cell, Vector2.ZERO)
	check(
		item_manager.active_items_by_cell.has(test_cell) and grid.has_item(test_cell),
		"a second held item stays on the ground while the current Ctrl item is unused"
	)
	gate.allow_collect = true
	item_manager._on_player_moved(1, test_cell, Vector2.ZERO)
	check(
		not item_manager.active_items_by_cell.has(test_cell) and not grid.has_item(test_cell),
		"held item is removed from the ground only when the inventory slot can accept it"
	)
	check(gate.applied_count == 1, "accepted held item is applied exactly once")
	item_manager.queue_free()
	gate.queue_free()
