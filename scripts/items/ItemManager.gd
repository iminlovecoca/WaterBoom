class_name ItemManager
extends Node2D

@export var item_scene: PackedScene = preload("res://scenes/items/Item.tscn")

var next_item_id: int = 1
var active_items_by_cell: Dictionary = {} # Vector2i -> ItemEntity
var grid_manager: GridManager
var match_manager: Node
var item_drop_rate: float = 0.65

var rng = RandomNumberGenerator.new()

func initialize(p_grid: GridManager, p_match_mgr: Node, drop_rate: float = 0.65) -> void:
	for child in get_children():
		child.queue_free()
	grid_manager = p_grid
	match_manager = p_match_mgr
	item_drop_rate = drop_rate
	if GameSession.play_mode == &"multiplayer" and RoomManager.current_room_id != "":
		rng.seed = RoomManager.current_room_id.hash()
	else:
		rng.randomize()
	active_items_by_cell.clear()
	next_item_id = 1
	
	if not EventBus.block_destroyed.is_connected(_on_block_destroyed):
		EventBus.block_destroyed.connect(_on_block_destroyed)
	if not EventBus.player_moved.is_connected(_on_player_moved):
		EventBus.player_moved.connect(_on_player_moved)

func _on_block_destroyed(cell: Vector2i) -> void:
	var seed_val: int = rng.seed if rng.seed != 0 else 1234567
	var cell_hash := absi(cell.x * 73856093 ^ cell.y * 19349663 ^ seed_val)
	var drop_roll := (cell_hash % 1000) / 1000.0
	if drop_roll <= item_drop_rate:
		var type_roll := ((cell_hash / 1000) % 1000) / 1000.0
		var item_type := GameConstants.ItemType.WATER_BALLOON_UP
		if type_roll < 0.26:
			item_type = GameConstants.ItemType.WATER_BALLOON_UP
		elif type_roll < 0.52:
			item_type = GameConstants.ItemType.WATER_POWER_UP
		elif type_roll < 0.76:
			item_type = GameConstants.ItemType.SPEED_UP
		elif type_roll < 0.88:
			item_type = GameConstants.ItemType.BUBBLE_PIN
		else:
			item_type = GameConstants.ItemType.SHIELD
		spawn_item_at_cell(cell, item_type)

func spawn_item_at_cell(cell: Vector2i, item_type: int) -> ItemEntity:
	if active_items_by_cell.has(cell):
		return null
		
	var item_id = next_item_id
	next_item_id += 1
	
	var item_instance = item_scene.instantiate() as ItemEntity
	item_instance.position = grid_manager.grid_to_world(cell)
	add_child(item_instance)
	
	item_instance.initialize(item_id, item_type, cell)
	active_items_by_cell[cell] = item_instance
	grid_manager.set_item_cell(cell, true)
	
	EventBus.item_spawned.emit(item_id, item_type, cell)
	return item_instance

func _on_player_moved(player_id: int, cell: Vector2i, _pos: Vector2) -> void:
	if active_items_by_cell.has(cell):
		var item = active_items_by_cell[cell]
		# A Ctrl-activated item owns the single held slot until it is used. Walking
		# over another held item must leave that pickup on the map instead of
		# deleting it or silently replacing the player's current item.
		if (
			match_manager != null
			and match_manager.has_method("can_player_collect_item")
			and not match_manager.can_player_collect_item(player_id, item.item_type)
		):
			return
		active_items_by_cell.erase(cell)
		grid_manager.set_item_cell(cell, false)
		
		var item_id = item.item_id
		var item_type = item.item_type
		
		item.collect()
		
		# Notify match manager to apply item
		if match_manager != null and match_manager.has_method("apply_item_to_player"):
			match_manager.apply_item_to_player(player_id, item_type)
			
		EventBus.item_collected.emit(item_id, player_id, item_type, cell)

func destroy_items_in_cells(cells: Array) -> void:
	for cell in cells:
		if active_items_by_cell.has(cell):
			var item = active_items_by_cell[cell]
			if is_instance_valid(item) and item.invulnerable_time > 0:
				continue
			active_items_by_cell.erase(cell)
			grid_manager.set_item_cell(cell, false)
			if is_instance_valid(item):
				item.destroy_by_water()
