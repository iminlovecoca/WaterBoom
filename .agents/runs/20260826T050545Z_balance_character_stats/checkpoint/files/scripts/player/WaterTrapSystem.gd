class_name WaterTrapSystem
extends RefCounted

static func trap_players(players: Dictionary, water_cells: Array, source_cell: Vector2i = Vector2i.ZERO) -> int:
	var trapped_count := 0
	for player in players.values():
		if player != null and player.is_alive and not player.is_in_bubble and water_cells.has(player.grid_cell):
			player.hit_by_water(source_cell)
			if player.is_in_bubble:
				trapped_count += 1
	return trapped_count
