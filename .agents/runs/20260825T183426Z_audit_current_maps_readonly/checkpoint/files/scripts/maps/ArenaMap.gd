class_name ArenaMap
extends Node2D

@export var map_definition: MapDefinition

var grid_manager: GridManager
var destructible_nodes: Dictionary = {} # Vector2i -> Sprite2D
var map_theme: MapThemeDefinition

@onready var floor_layer: Node2D = $FloorLayer
@onready var walls_layer: Node2D = $WallsLayer
@onready var destructibles_layer: Node2D = $DestructiblesLayer
@onready var decorations_layer: Node2D = $DecorationsLayer

func setup_map(p_grid_manager: GridManager, p_map_def: MapDefinition) -> void:
	grid_manager = p_grid_manager
	map_definition = p_map_def
	map_theme = MapThemeCatalog.create_theme(map_definition.theme)
	
	floor_layer.z_index = 0
	destructibles_layer.z_index = 1
	walls_layer.z_index = 4
	decorations_layer.z_index = 5
	
	_clear_layers()
	_build_visuals()
	
	if not EventBus.block_destroyed.is_connected(_on_block_destroyed):
		EventBus.block_destroyed.connect(_on_block_destroyed)

func _clear_layers() -> void:
	for child in floor_layer.get_children():
		child.queue_free()
	for child in walls_layer.get_children():
		child.queue_free()
	for child in destructibles_layer.get_children():
		child.queue_free()
	for child in decorations_layer.get_children():
		child.queue_free()
	destructible_nodes.clear()

func _build_visuals() -> void:
	var decoration_entries := MapDecorationCatalog.entries_for_map(map_definition.id)
	var decorated_cells: Dictionary = {}
	for entry in decoration_entries:
		var origin: Vector2i = entry["cell"]
		var footprint: Vector2i = entry["size"]
		for footprint_y in range(origin.y, origin.y + footprint.y):
			for footprint_x in range(origin.x, origin.x + footprint.x):
				decorated_cells[Vector2i(footprint_x, footprint_y)] = true
	for y in range(grid_manager.height):
		for x in range(grid_manager.width):
			var cell = Vector2i(x, y)
			var cell_pos = grid_manager.grid_to_world(cell)
			var cell_type = grid_manager.get_cell_type(cell)
			
			# Interior blocks use transparent silhouettes, so keep the real ground
			# beneath them. Only the opaque outer frame replaces the floor entirely.
			var is_outer_frame := _is_in_grid_frame_cell(cell)
			if cell_type != GameConstants.TileType.WALL or decorated_cells.has(cell) or not is_outer_frame:
				var floor_sprite = Sprite2D.new()
				var tex = _floor_texture_for_cell(cell)
				floor_sprite.texture = tex
				floor_sprite.position = cell_pos
				floor_sprite.scale = Vector2(float(grid_manager.tile_size) / tex.get_size().x, float(grid_manager.tile_size) / tex.get_size().y)
				# Source textures ship with bled edges, so linear+mipmap sampling
				# no longer leaks bright gutters between cells while keeping the
				# heavy tile downscale (256px art in ~40px cells) crisp.
				floor_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
				floor_layer.add_child(floor_sprite)
			
			# Wall (indestructible)
			if cell_type == GameConstants.TileType.WALL and not decorated_cells.has(cell):
				_spawn_wall(cell, cell_pos)
			# Destructible block 鈥?also skip on decorated cells
			elif cell_type == GameConstants.TileType.DESTRUCTIBLE and not decorated_cells.has(cell):
				_spawn_destructible(cell, cell_pos)
	_build_decorations(decoration_entries)

func _spawn_wall(cell: Vector2i, cell_pos: Vector2) -> void:
	var hash_val := absi(cell.x * 41 + cell.y * 73 + map_definition.layout_seed * 103)
	var wall_tex := _wall_texture_for_cell(cell, hash_val)
	var wall_sprite = Sprite2D.new()
	wall_sprite.texture = wall_tex
	var is_outer_frame := _is_in_grid_frame_cell(cell)
	var exact_cell_scale := Vector2(float(grid_manager.tile_size) / wall_tex.get_size().x, float(grid_manager.tile_size) / wall_tex.get_size().y)
	wall_sprite.scale = exact_cell_scale if is_outer_frame else exact_cell_scale * 1.02
	wall_sprite.position = cell_pos if is_outer_frame else cell_pos + Vector2(0, -float(grid_manager.tile_size) * 0.045)
	# Authored frame pixels meet exactly at the cell boundary. With bled edge
	# colors the linear filter blends against matching neighbors instead of
	# transparent garbage, so mipmapped sampling stays seam-free and smooth.
	wall_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	walls_layer.add_child(wall_sprite)

	# Runtime block art already contains its own contact edge. The additional
	# generic shadow used here produced a clipped black line below hard blocks.

func _spawn_destructible(cell: Vector2i, cell_pos: Vector2) -> void:
	var hash_val := absi(cell.x * 37 + cell.y * 61 + map_definition.layout_seed * 101)
	var dest_tex := _destructible_texture_for_cell(cell, hash_val)
	var dest_sprite = Sprite2D.new()
	dest_sprite.texture = dest_tex
	dest_sprite.scale = Vector2(float(grid_manager.tile_size) / dest_tex.get_size().x, float(grid_manager.tile_size) / dest_tex.get_size().y) * 1.02
	dest_sprite.position = cell_pos + Vector2(0, -float(grid_manager.tile_size) * 0.055)
	dest_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	destructibles_layer.add_child(dest_sprite)
	destructible_nodes[cell] = dest_sprite

	# Destructible art also owns its baked bottom face; do not stack a second
	# blurred shadow underneath adjacent crates.

func _wall_texture_for_cell(cell: Vector2i, hash_value: int = 0) -> Texture2D:
	# Authored outer-frame modules take precedence over generic neighbor rules.
	# Corners use genuine L-shaped sprites instead of rotated square blocks.
	if _is_in_grid_frame_cell(cell) and map_theme.wall_edge_top_texture != null:
		if cell == Vector2i(0, 0): return map_theme.wall_corner_tl_texture
		if cell == Vector2i(map_definition.width - 1, 0): return map_theme.wall_corner_tr_texture
		if cell == Vector2i(0, map_definition.height - 1): return map_theme.wall_corner_bl_texture
		if cell == Vector2i(map_definition.width - 1, map_definition.height - 1): return map_theme.wall_corner_br_texture
		if cell.y == 0: return map_theme.wall_edge_top_texture
		if cell.y == map_definition.height - 1: return map_theme.wall_edge_bottom_texture
		if cell.x == 0: return map_theme.wall_edge_left_texture
		return map_theme.wall_edge_right_texture

	# Regular PvP maps no longer have a border-wall ring.  A hard block on x=0
	# or y=0 is still a normal gameplay block, never a frame edge/corner module.
	if not _uses_in_grid_frame() and map_theme.wall_textures.size() > 0:
		if map_definition.id == &"lego_city" and map_theme.wall_textures.size() >= 3:
			return map_theme.wall_textures[2]
		return map_theme.get_wall_variant(hash_value)

	# If theme has no autotile pieces, use the basic wall or its variants
	if map_theme.wall_edge_top_texture == null:
		if _is_in_grid_frame_cell(cell) and map_theme.wall_textures.size() > 0:
			return map_theme.wall_textures[0]
		return map_theme.get_wall_variant(hash_value)

	var has_n := _is_wall(cell + Vector2i(0, -1))
	var has_s := _is_wall(cell + Vector2i(0, 1))
	var has_w := _is_wall(cell + Vector2i(-1, 0))
	var has_e := _is_wall(cell + Vector2i(1, 0))

	# Count neighbors
	var count := int(has_n) + int(has_s) + int(has_w) + int(has_e)

	# Isolated 鈥?no neighbors
	if count == 0:
		return map_theme.wall_cap_texture

	# Edge pieces 鈥?exactly one neighbor
	if count == 1:
		if has_n: return map_theme.wall_edge_bottom_texture
		if has_s: return map_theme.wall_edge_top_texture
		if has_w: return map_theme.wall_edge_right_texture
		if has_e: return map_theme.wall_edge_left_texture

	# Corner pieces 鈥?two neighbors not opposite
	if count == 2:
		if has_n and has_e: return map_theme.wall_corner_br_texture
		if has_n and has_w: return map_theme.wall_corner_bl_texture
		if has_s and has_e: return map_theme.wall_corner_tr_texture
		if has_s and has_w: return map_theme.wall_corner_tl_texture
		# Opposite 鈥?use edge
		if has_n and has_s: return map_theme.wall_edge_left_texture
		if has_w and has_e: return map_theme.wall_edge_top_texture

	# T-junction or cross 鈥?use center
	return map_theme.wall_center_texture

func _uses_in_grid_frame() -> bool:
	# Boss rounds retain their ship boundary. Standard maps use all 16x16 cells.
	return map_definition != null and map_definition.id == &"boss_pirate_ship"

func _is_in_grid_frame_cell(cell: Vector2i) -> bool:
	return _uses_in_grid_frame() and MapLayoutBuilder._is_border(cell, map_definition)

func _is_wall(cell: Vector2i) -> bool:
	if not grid_manager.is_valid_cell(cell):
		return true  # Treat out-of-bounds as wall (border)
	return grid_manager.get_cell_type(cell) == GameConstants.TileType.WALL

func _destructible_texture_for_cell(cell: Vector2i, hash_value: int) -> Texture2D:
	# Use a controlled two-material palette. This keeps gameplay blocks readable
	# and prevents the rainbow/noise effect caused by four equally weighted props.
	if map_definition.id in MapCatalog.MAP_IDS and map_theme.destructible_textures.size() >= 2:
		var mirror_x := mini(cell.x, map_definition.width - 1 - cell.x)
		var mirror_y := mini(cell.y, map_definition.height - 1 - cell.y)
		var balanced_hash := absi(mirror_x * 37 + mirror_y * 61 + map_definition.layout_seed * 101)
		if map_definition.id == &"pirate_harbor":
			# Treasure chests are accents, not half the cargo field.  A 1:3 mix
			# keeps the harbor warm/readable and prevents red-gold visual noise.
			return map_theme.destructible_textures[0] if balanced_hash % 4 == 0 else map_theme.destructible_textures[1]
		return map_theme.destructible_textures[balanced_hash % 2]
	return map_theme.get_destructible_variant(hash_value)

func _floor_texture_for_cell(cell: Vector2i) -> Texture2D:
	var use_alternate := false
	var hash_value := absi(cell.x * 37 + cell.y * 61 + map_definition.layout_seed * 101)
	var cx = map_definition.width / 2
	var cy = map_definition.height / 2

	if map_definition.id == &"lego_city":
		if MapLayoutBuilder._is_lego_road(cell):
			var base_path := "res://assets/visual_overhaul_v2/maps/lego_city/runtime"
			var is_crosswalk := (
				(cell.y in [4, 5] and cell.x in [6, 7, 8, 9])
				or (cell.y in [10, 11] and cell.x in [6, 7, 8, 9])
				or (cell.x in [4, 5] and cell.y in [6, 7, 8, 9])
				or (cell.x in [10, 11] and cell.y in [6, 7, 8, 9])
			)
			if is_crosswalk:
				return load(base_path + "/floor_alt_B.png") as Texture2D
			return load(base_path + "/floor_alt_A.png") as Texture2D
		else:
			var base_path := "res://assets/visual_overhaul_v2/maps/lego_city/runtime"
			return load(base_path + "/floor_A.png") as Texture2D
	elif map_definition.id == &"aqua_park":
		# Read directly from AQUA_LAYOUT to get exact W (Water) and S (Sand)
		var c = MapLayoutBuilder.AQUA_LAYOUT[cell.y][cell.x]
		if c == 'W' or c == 'O' or c == 'D':
			# The V2 atlas authors pool water as the first alternate floor.
			var base_path := "res://assets/visual_overhaul_v2/maps/aqua_park/runtime"
			return load(base_path + "/floor_alt_A.png") as Texture2D
		else:
			var base_path := "res://assets/visual_overhaul_v2/maps/aqua_park/runtime"
			return load(base_path + "/floor_A.png") as Texture2D
	elif map_definition.id == &"snow_village":
		var base_path := "res://assets/visual_overhaul_v2/maps/snow_village/runtime"
		# Ice roads (Đường băng) across central cross and surrounding walkway
		var is_ice_road := (
			(cell.x in [7, 8]) or (cell.y in [7, 8])
			or (cell.x in [5, 10] and cell.y >= 5 and cell.y <= 10)
			or (cell.y in [5, 10] and cell.x >= 5 and cell.x <= 10)
		)
		var is_ice_pattern := (
			(cell.x in [4, 11] and cell.y in [7, 8])
			or (cell.y in [4, 11] and cell.x in [7, 8])
		)
		if is_ice_pattern:
			return load(base_path + "/floor_alt_B.png") as Texture2D
		elif is_ice_road:
			return load(base_path + "/floor_alt_A.png") as Texture2D
		else:
			return load(base_path + "/floor_A.png") as Texture2D
	elif map_definition.id == &"pirate_harbor":
		var base_path := "res://assets/visual_overhaul_v2/maps/pirate_harbor/runtime"
		# One continuous wood tile across the complete deck. Mixing captain-lane,
		# alternate and random floor cells was the source of the visible white seams.
		return load(base_path + "/floor_A.png") as Texture2D
	elif map_definition.id == &"training_plaza":
		# V2 Plaza uses a calm grass field with an authored two-tile-wide stone cross.
		var base_path := "res://assets/visual_overhaul_v2/maps/training_plaza/runtime"
		var is_stone_path := cell.x in [7, 8] or cell.y in [7, 8]
		if is_stone_path:
			return load(base_path + "/floor_alt_A.png") as Texture2D
		else:
			return load(base_path + "/floor_A.png") as Texture2D
	else:
		# Central cross paths (2 tiles wide)
		if cell.x in [cx - 1, cx] or cell.y in [cy - 1, cy]:
			use_alternate = true
		# Inner base for 4x4 center landmark (6x6 stone pad)
		if cell.x >= cx - 3 and cell.x <= cx + 2 and cell.y >= cy - 3 and cell.y <= cy + 2:
			use_alternate = true

	return map_theme.get_floor_variant(hash_value, use_alternate)

func _build_decorations(entries: Array[Dictionary]) -> void:
	for entry in entries:
		var cell: Vector2i = entry["cell"]
		var footprint: Vector2i = entry["size"]
		var decoration := Sprite2D.new()
		decoration.name = String(entry["name"]).to_pascal_case()
		decoration.texture = entry["texture"]
		var visual_offset: Vector2 = entry.get("visual_offset", Vector2.ZERO)
		var prop_lift := -float(grid_manager.tile_size) * 0.12 if footprint == Vector2i.ONE else 0.0
		decoration.position = grid_manager.grid_to_world(cell) + Vector2(footprint - Vector2i.ONE) * grid_manager.tile_size * 0.5 + visual_offset + Vector2(0, prop_lift)
		var target_size := Vector2(footprint * grid_manager.tile_size)
		var visual_size: Vector2 = entry.get("visual_size", target_size)
		var source_size := decoration.texture.get_size()
		var fit_scale := minf(visual_size.x / source_size.x, visual_size.y / source_size.y)
		var scale_mod: float = entry.get("scale_mod", 1.0)
		decoration.scale = Vector2.ONE * fit_scale * scale_mod
		# Bled source edges make mipmapped linear sampling safe for every prop,
		# so small props stay clean under fractional scaling instead of aliasing.
		decoration.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		decorations_layer.add_child(decoration)
		
		# Ground decorations with a shadow
		if map_definition.id != &"training_plaza" and map_theme.contact_shadow_texture and "shadow" not in entry.get("name", ""):
			var shadow_sprite = Sprite2D.new()
			shadow_sprite.texture = map_theme.contact_shadow_texture
			# Position shadow at the bottom edge of the sprite
			shadow_sprite.position = Vector2(0, source_size.y * 0.45)
			shadow_sprite.z_index = -1
			# Scale shadow horizontally for wider decorations (like bench or fountain)
			shadow_sprite.scale = Vector2(source_size.x / 120.0, 1.0)
			shadow_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
			decoration.add_child(shadow_sprite)
			
		if entry["animated"]:
			var base_scale := decoration.scale
			var tween := decoration.create_tween().set_loops()
			tween.tween_property(decoration, "scale", base_scale * Vector2(1.025, 0.985), 0.75).set_trans(Tween.TRANS_SINE)
			tween.tween_property(decoration, "scale", base_scale, 0.75).set_trans(Tween.TRANS_SINE)

func _on_block_destroyed(cell: Vector2i) -> void:
	if destructible_nodes.has(cell):
		var node: Sprite2D = destructible_nodes[cell]
		destructible_nodes.erase(cell)
		# The water VFX already communicates the hit. Remove the tile immediately
		# so its old sprite never enlarges into a blurry overlay above the stream.
		node.queue_free()
