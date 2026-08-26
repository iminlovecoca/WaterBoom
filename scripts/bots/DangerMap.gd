class_name DangerMap
extends RefCounted

var danger_time_by_cell: Dictionary = {}

func rebuild(grid: GridManager, water_balloon_manager: WaterBalloonManager) -> void:
	danger_time_by_cell.clear()
	if water_balloon_manager == null:
		return
	for water_balloon in water_balloon_manager.active_water_balloons.values():
		if water_balloon == null or water_balloon.has_popped:
			continue
		var result := WaterGridPropagation.calculate_water_burst(water_balloon.grid_cell, water_balloon.water_power, grid)
		for cell in result["affected_cells"]:
			var previous := float(danger_time_by_cell.get(cell, INF))
			danger_time_by_cell[cell] = minf(previous, water_balloon.time_left)
	for cell in water_balloon_manager.active_water_cells.keys():
		danger_time_by_cell[cell] = 0.0

func is_dangerous(cell: Vector2i, prediction_horizon: float = INF) -> bool:
	return danger_time_by_cell.has(cell) and float(danger_time_by_cell[cell]) <= prediction_horizon
