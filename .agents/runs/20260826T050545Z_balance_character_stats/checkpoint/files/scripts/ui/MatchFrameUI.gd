class_name MatchFrameUI
extends Control

const OUTER_MARGIN := 0.0
const TOP_MARGIN := 0.0
const BOTTOM_MARGIN := 0.0
const PANEL_GAP := 0.0
const SIDEBAR_WIDTH := 204.0
const BOOM_ICON: Texture2D = preload("res://assets/water_balloons/skins/skin_066/idle_0.png")
const BUBBLE_PIN_ICON: Texture2D = preload("res://assets/items/item_bubble_pin.png")
const SHIELD_ICON: Texture2D = preload("res://assets/items/item_shield.png")

var redraw_elapsed := 0.0

static func sidebar_rect_for_size(viewport_size: Vector2) -> Rect2:
	var arena_height := viewport_size.y - TOP_MARGIN - BOTTOM_MARGIN
	var sidebar_x: float = viewport_size.x - OUTER_MARGIN - SIDEBAR_WIDTH
	return Rect2(
		sidebar_x,
		TOP_MARGIN,
		SIDEBAR_WIDTH,
		arena_height
	)

static func arena_panel_rect_for_size(viewport_size: Vector2) -> Rect2:
	var sidebar := sidebar_rect_for_size(viewport_size)
	var arena_height := viewport_size.y - TOP_MARGIN - BOTTOM_MARGIN
	return Rect2(
		OUTER_MARGIN,
		TOP_MARGIN,
		sidebar.position.x - PANEL_GAP - OUTER_MARGIN,
		arena_height
	)

static func board_origin_for(viewport_size: Vector2, board_size: Vector2) -> Vector2:
	var arena_panel := arena_panel_rect_for_size(viewport_size)
	return Vector2(
		floor(arena_panel.position.x + (arena_panel.size.x - board_size.x) * 0.5),
		floor(arena_panel.position.y + (arena_panel.size.y - board_size.y) * 0.5)
	)

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_resize_to_viewport()
	get_viewport().size_changed.connect(_resize_to_viewport)

func _resize_to_viewport() -> void:
	position = Vector2.ZERO
	size = get_viewport_rect().size
	queue_redraw()

func _process(delta: float) -> void:
	redraw_elapsed += delta
	if redraw_elapsed >= 0.1:
		redraw_elapsed = 0.0
		queue_redraw()

func _draw() -> void:
	var viewport_size := size
	var full_rect := Rect2(-1000.0, -1000.0, viewport_size.x + 2000.0, viewport_size.y + 2000.0)
	var sidebar := sidebar_rect_for_size(viewport_size)
	var manager := get_parent() as MatchManager
	var board_size := Vector2(600.0, 520.0)
	if manager != null and manager.map_definition != null:
		board_size = Vector2(manager.map_definition.width, manager.map_definition.height) * manager.map_definition.tile_size
	var board_origin := board_origin_for(viewport_size, board_size)

	# Solid dark background to prevent any white edge
	draw_rect(full_rect, Color("#041b38"))
	
	# The arena itself is the visual boundary. Do not spend screen space on a
	# second decorative frame around the full 16x16 board.
	_draw_panel(sidebar, Color("#063c7d"), Color("#43d5ff"), 3.0)

func _draw_panel(rect: Rect2, fill: Color, border: Color, border_width: float, top_highlight := true) -> void:
	draw_rect(rect, fill)
	draw_rect(rect, Color("#021222"), false, border_width + 2.0)
	draw_rect(rect.grow(-3.0), border, false, border_width)
	if top_highlight:
		draw_line(rect.position + Vector2(8.0, 8.0), Vector2(rect.end.x - 8.0, rect.position.y + 8.0), Color(0.65, 0.88, 1.0, 0.4), 1.5)
