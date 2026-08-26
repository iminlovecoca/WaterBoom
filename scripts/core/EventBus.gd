extends Node

# WaterBalloon Signals
signal water_balloon_placed(water_balloon_id: int, owner_id: int, cell: Vector2i, timer_duration: float, water_power: int)
signal water_balloon_popped(water_balloon_id: int, cell: Vector2i, water_cells: Array)

# WaterBurst & Environment Signals
signal water_burst_started(origin_cell: Vector2i, rays: Dictionary)
signal chain_water_burst(source_id: int, triggered_id: int)
signal block_destroyed(cell: Vector2i)
signal item_spawned(item_id: int, item_type: int, cell: Vector2i)
signal item_collected(item_id: int, player_id: int, item_type: int, cell: Vector2i)

# Player Signals
signal player_spawned(player_id: int, character_id: String, cell: Vector2i)
signal player_moved(player_id: int, cell: Vector2i, world_pos: Vector2)
signal player_water_hit(player_id: int, source_cell: Vector2i)
signal player_bubbled(player_id: int)
signal player_rescued(player_id: int, rescuer_id: int)
signal player_died(player_id: int)
signal player_inventory_updated(player_id: int)

# Match Signals
signal match_state_changed(old_state: int, new_state: int)
signal match_countdown_tick(seconds_left: int)
signal match_started()
signal match_ended(winner_id: int, is_draw: bool)

# Network & Room Signals
signal network_connected(peer_id: int)
signal network_disconnected(peer_id: int)
signal room_state_updated(room_data: Dictionary)
signal debug_overlay_toggled(is_visible: bool)
