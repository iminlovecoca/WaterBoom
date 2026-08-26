class_name GridDebugRenderer
extends Node2D

var show_grid: bool = false
var show_gameplay_cells: bool = false
var match_manager: MatchManager
var redraw_timer: float = 0.0

func _ready() -> void:
	z_index = 50
	match_manager = get_parent() as MatchManager

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_grid"):
		show_grid = not show_grid
		queue_redraw()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("toggle_danger"):
		show_gameplay_cells = not show_gameplay_cells
		queue_redraw()
		get_viewport().set_input_as_handled()

func _process(delta: float) -> void:
	if not show_gameplay_cells:
		return
	redraw_timer -= delta
	if redraw_timer <= 0.0:
		redraw_timer = 0.12
		queue_redraw()

func _draw() -> void:
	if match_manager == null or match_manager.grid_manager == null:
		return
	var grid := match_manager.grid_manager
	var origin := grid.world_origin
	var map_size := Vector2(grid.width * grid.tile_size, grid.height * grid.tile_size)
	if show_grid:
		for x in range(grid.width + 1):
			var px := origin.x + x * grid.tile_size
			draw_line(Vector2(px, origin.y), Vector2(px, origin.y + map_size.y), Color(0.35, 0.9, 1.0, 0.34), 1.0)
		for y in range(grid.height + 1):
			var py := origin.y + y * grid.tile_size
			draw_line(Vector2(origin.x, py), Vector2(origin.x + map_size.x, py), Color(0.35, 0.9, 1.0, 0.34), 1.0)
	if show_gameplay_cells:
		var predicted := {}
		for water_balloon in match_manager.water_balloon_manager.active_water_balloons.values():
			var result := WaterGridPropagation.calculate_water_burst(water_balloon.grid_cell, water_balloon.water_power, grid)
			for cell in result["affected_cells"]:
				predicted[cell] = true
		for y in range(grid.height):
			for x in range(grid.width):
				var cell := Vector2i(x, y)
				var rect := Rect2(origin + Vector2(cell * grid.tile_size), Vector2.ONE * grid.tile_size)
				if grid.is_wall(cell):
					draw_rect(rect.grow(-3.0), Color(1.0, 0.25, 0.3, 0.16), true)
				elif grid.is_destructible(cell):
					draw_rect(rect.grow(-5.0), Color(1.0, 0.65, 0.2, 0.18), true)
				if predicted.has(cell):
					draw_rect(rect.grow(-8.0), Color(1.0, 0.2, 0.75, 0.26), true)
				if match_manager.water_balloon_manager.active_water_cells.has(cell):
					draw_rect(rect.grow(-5.0), Color(0.1, 0.9, 1.0, 0.34), true)
