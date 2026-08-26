class_name WaterGridPropagation
extends RefCounted

static func calculate_water_burst(origin: Vector2i, water_power: int, grid: GridManager) -> Dictionary:
	var result = {
		"origin": origin,
		"affected_cells": [origin],
		"destroyed_blocks": [],
		"rays": {
			"center": [origin],
			"up": [],
			"down": [],
			"left": [],
			"right": []
		}
	}
	
	var directions = {
		"up": Vector2i(0, -1),
		"down": Vector2i(0, 1),
		"left": Vector2i(-1, 0),
		"right": Vector2i(1, 0)
	}
	
	for dir_name in directions.keys():
		var dir_vec: Vector2i = directions[dir_name]
		for step in range(1, water_power + 1):
			var target_cell = origin + dir_vec * step
			
			if not grid.is_valid_cell(target_cell):
				_mark_last_as_end(result["rays"][dir_name])
				break
				
			# Check Wall
			if grid.is_wall(target_cell):
				_mark_last_as_end(result["rays"][dir_name])
				break
				
			# Check Destructible Block
			if grid.is_destructible(target_cell):
				result["affected_cells"].append(target_cell)
				result["destroyed_blocks"].append(target_cell)
				result["rays"][dir_name].append({
					"cell": target_cell,
					"is_end": true
				})
				break
			# Check Other Water Balloons (Chain Reaction)
			elif grid.has_water_balloon(target_cell):
				result["affected_cells"].append(target_cell)
				result["rays"][dir_name].append({
					"cell": target_cell,
					"is_end": true
				})
				break
			else:
				# Open floor or water_balloon
				result["affected_cells"].append(target_cell)
				var is_cap = (step == water_power)
				result["rays"][dir_name].append({
					"cell": target_cell,
					"is_end": is_cap
				})
				
	return result

static func _mark_last_as_end(ray: Array) -> void:
	if not ray.is_empty():
		ray[-1]["is_end"] = true
