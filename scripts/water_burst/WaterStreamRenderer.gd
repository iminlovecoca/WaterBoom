class_name WaterStreamRenderer
extends Node2D

var textures: Dictionary = {}
var active_segments_by_cell: Dictionary = {}
var segment_duration: float = GameConstants.DEFAULT_WATER_BURST_DURATION

func _ready() -> void:
	_load_textures()

func _load_textures() -> void:
	var list = [
		"center", "center_t_down", "center_t_up", "center_t_left", "center_t_right",
		"center_corner_rd", "center_corner_ld", "center_corner_ru", "center_corner_lu",
		"horizontal", "vertical", "end_left", "end_right", "end_up", "end_down", "cross"
	]
	for k in list:
		# V3 is authored from one pixel-art master tube. Its body, junctions and
		# terminal caps share the same cross-section at every cell boundary.
		var res_path = "res://assets/visual_overhaul_v3/water_stream/runtime/water_%s.png" % k
		if not ResourceLoader.exists(res_path):
			res_path = "res://assets/visual_overhaul_v2/water_stream/runtime/water_%s.png" % k
		if not ResourceLoader.exists(res_path):
			res_path = "res://assets/visual_overhaul_v1/water_stream/runtime/water_%s.png" % k
		if not ResourceLoader.exists(res_path):
			res_path = "res://assets/water_stream/water_%s.png" % k
		var tex: Texture2D = null
		if ResourceLoader.exists(res_path):
			tex = load(res_path)
		if tex == null:
			var global_p = ProjectSettings.globalize_path(res_path)
			if FileAccess.file_exists(global_p):
				var img = Image.load_from_file(global_p)
				if img != null:
					tex = ImageTexture.create_from_image(img)
		if tex != null:
			textures[k] = tex

func spawn_water_burst(rays_data: Dictionary, grid: GridManager, skin_id: StringName = &"skin_066") -> void:
	var center_cell: Vector2i = rays_data["center"][0]
	var has_up: bool = not rays_data["up"].is_empty()
	var has_down: bool = not rays_data["down"].is_empty()
	var has_left: bool = not rays_data["left"].is_empty()
	var has_right: bool = not rays_data["right"].is_empty()
	
	var center_piece := "center"
	if has_up and has_down and has_left and has_right:
		center_piece = "center"
	elif not has_up and has_down and has_left and has_right:
		center_piece = "center_t_down"
	elif has_up and not has_down and has_left and has_right:
		center_piece = "center_t_up"
	elif has_up and has_down and has_left and not has_right:
		center_piece = "center_t_left"
	elif has_up and has_down and not has_left and has_right:
		center_piece = "center_t_right"
	elif not has_up and has_down and not has_left and has_right:
		center_piece = "center_corner_rd"
	elif not has_up and has_down and has_left and not has_right:
		center_piece = "center_corner_ld"
	elif has_up and not has_down and not has_left and has_right:
		center_piece = "center_corner_ru"
	elif has_up and not has_down and has_left and not has_right:
		center_piece = "center_corner_lu"
	elif (has_left or has_right) and not has_up and not has_down:
		# The balloon cell is always the burst origin. Keep the authored impact
		# center visible even when obstacles reduce the burst to one horizontal
		# axis; using a body segment here made the origin disappear.
		center_piece = "center"
	elif (has_up or has_down) and not has_left and not has_right:
		# Same rule for a vertical-only burst.
		center_piece = "center"
	else:
		center_piece = "center"

	var g_size: int = grid.tile_size if grid != null else 48
	_spawn_piece(center_cell, grid.grid_to_world(center_cell), center_piece, skin_id, g_size)
	for dir_name in ["up", "down", "left", "right"]:
		var ray_list: Array = rays_data[dir_name]
		for item in ray_list:
			var cell: Vector2i = item["cell"]
			var is_end: bool = item["is_end"]
			var world_pos = grid.grid_to_world(cell)
			var piece_name = ""
			if is_end:
				piece_name = "end_" + dir_name
			else:
				piece_name = "vertical" if (dir_name == "up" or dir_name == "down") else "horizontal"
			_spawn_piece(cell, world_pos, piece_name, skin_id, g_size)

func _spawn_piece(cell: Vector2i, world_pos: Vector2, piece_type: String, skin_id: StringName, grid_tile_size: int = 48) -> void:
	var target_size := float(grid_tile_size)
	if active_segments_by_cell.has(cell) and is_instance_valid(active_segments_by_cell[cell]):
		var existing: Sprite2D = active_segments_by_cell[cell]
		var center_tex: Texture2D = textures.get("center", existing.texture)
		existing.texture = center_tex
		var existing_w := float(existing.texture.get_width()) if existing.texture != null else 80.0
		var existing_scale := Vector2.ONE * (target_size / existing_w)
		existing.scale = existing_scale
		return
	var sprite = Sprite2D.new()
	sprite.position = world_pos
	var target_tex: Texture2D = textures.get(piece_type, null)
	if target_tex == null or piece_type == "cross":
		target_tex = textures.get("center", null)
	if target_tex == null and not textures.is_empty():
		target_tex = textures.values()[0]
	sprite.texture = target_tex
	# Bled source edges let mipmapped linear sampling shrink 64px water pieces
	# to the map cell smoothly, without arcade-style chunky aliasing.
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	var tex_w := float(sprite.texture.get_width()) if sprite.texture != null else 80.0
	var tile_scale := Vector2.ONE * (target_size / tex_w)
	# Exact one-cell size: authored edges meet at the grid boundary, without
	# overlapping adjacent sprites or leaving a sampling seam.
	sprite.scale = tile_scale
	var burst_tint := WaterBalloonSkinRegistry.get_vfx_tint(skin_id)
	burst_tint.a = 0.0
	sprite.modulate = burst_tint
	add_child(sprite)
	active_segments_by_cell[cell] = sprite

	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(sprite, "modulate:a", 1.0, 0.04)
	tween.set_parallel(false)
	var sustain_time := maxf(segment_duration - 0.18, 0.12)
	tween.tween_interval(sustain_time)
	tween.tween_property(sprite, "modulate:a", 0.0, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_callback(func():
		if active_segments_by_cell.get(cell) == sprite:
			active_segments_by_cell.erase(cell)
		sprite.queue_free()
	)
