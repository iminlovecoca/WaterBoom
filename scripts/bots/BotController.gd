class_name BotController
extends Node

var brain := BotBrain.new()
var player: PlayerController
var current_target_cell: Vector2i
var decision_timer: float = 0.0
var decision_interval: float = 0.22
var use_pin_timer: float = 0.0
var pin_delay: float = 0.15

func initialize(p_player: PlayerController, grid: GridManager, water_balloon_manager: WaterBalloonManager, item_manager: ItemManager, match_manager: MatchManager, difficulty: GameConstants.BotDifficulty) -> void:
	player = p_player
	decision_interval = [0.14, 0.08, 0.04, 0.022][difficulty]
	pin_delay = [0.30, 0.15, 0.08, 0.03][difficulty]
	brain.initialize(player, grid, water_balloon_manager, item_manager, match_manager, difficulty)
	current_target_cell = player.grid_cell

func _physics_process(delta: float) -> void:
	if player == null or not player.is_alive:
		return

	# If bubbled, try to use bubble pin immediately
	if player.is_in_bubble:
		if player.active_items.size() > 0 and player.active_items[0] == GameConstants.ItemType.BUBBLE_PIN:
			use_pin_timer -= delta
			if use_pin_timer <= 0.0:
				use_pin_timer = pin_delay
				if player.use_bubble_pin():
					player.active_items[0] = GameConstants.ItemType.NONE
					EventBus.player_inventory_updated.emit(player.player_id)
		return
	use_pin_timer = 0.0

	if brain.match_manager.current_state != GameConstants.MatchState.PLAYING:
		player.apply_movement_intent(Vector2.ZERO, delta)
		return
	decision_timer -= delta
	if decision_timer <= 0.0:
		decision_timer = decision_interval
		var decision := brain.decide()
		current_target_cell = decision["target_cell"]
		if decision["place"]:
			player.place_water_balloon_request()

	var target_world := brain.grid.grid_to_world(current_target_cell)
	var offset := target_world - player.global_position
	var movement := offset.normalized() if offset.length() > 2.0 else Vector2.ZERO
	player.apply_movement_intent(movement, delta)
