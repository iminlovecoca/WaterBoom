class_name MapThemeCatalog
extends RefCounted

const THEME_TO_FOLDER := {
	&"plaza": "training_plaza",
	&"pool": "aqua_park",
	&"harbor": "pirate_harbor",
	&"snow": "snow_village",
	&"lego": "lego_city",
	&"egypt_temple": "egypt_temple",
}

static func create_theme(theme_id: StringName) -> MapThemeDefinition:
	var resolved_id: StringName = theme_id
	var folder: String = str(theme_id)
	
	# Support legacy mapping, else dynamically check if folder exists
	if THEME_TO_FOLDER.has(theme_id):
		folder = THEME_TO_FOLDER[theme_id]
	elif not DirAccess.dir_exists_absolute("res://assets/tilesets/" + folder):
		resolved_id = &"plaza"
		folder = THEME_TO_FOLDER[&"plaza"]
		
	var base_path := "res://assets/visual_overhaul_v2/maps/%s/runtime" % folder
	if not DirAccess.dir_exists_absolute(base_path):
		base_path = "res://assets/visual_overhaul_v1/maps/%s/runtime" % folder
	if not DirAccess.dir_exists_absolute(base_path):
		base_path = "res://assets/tilesets_v2/%s/runtime" % folder
	if not DirAccess.dir_exists_absolute(base_path):
		base_path = "res://assets/tilesets/%s/runtime" % folder
	
	var theme := MapThemeDefinition.new()
	theme.id = resolved_id
	theme.alternate_floor_frequency = 0.24 if resolved_id in [&"pool", &"neon"] else 0.18

	# ── Floor variants ──
	theme.floor_textures = []
	theme.alternate_floor_textures = []
	
	# Load floor_A as primary, floor_B as subtle variation (80/20 weighting)
	var floor_a := _load_tex(base_path + "/floor_A.png")
	var floor_b := _load_tex(base_path + "/floor_B.png")
	if floor_a and floor_b:
		theme.floor_textures = [floor_a, floor_a, floor_a, floor_a, floor_a, floor_a, floor_a, floor_a, floor_a, floor_b]
	elif floor_a:
		theme.floor_textures = [floor_a]
	# Fallback to single floor.png
	if theme.floor_textures.is_empty():
		var floor_single := _load_tex(base_path + "/floor.png")
		if floor_single: theme.floor_textures = [floor_single]
	
	# Alternate floor: only primary variant for consistency
	var floor_alt_a := _load_tex(base_path + "/floor_alt_A.png")
	if floor_alt_a:
		theme.alternate_floor_textures = [floor_alt_a]
	else:
		var floor_alt_single := _load_tex(base_path + "/floor_alt.png")
		if floor_alt_single: theme.alternate_floor_textures = [floor_alt_single]

	# ── Wall ──
	theme.wall_textures = []
	var hard_names := ["hard_block_A", "hard_block_B", "hard_block_C", "hard_block_D", "hard_block_E"]
	for h_name in hard_names:
		var h_tex := _load_tex("%s/%s.png" % [base_path, h_name])
		if h_tex:
			theme.wall_textures.append(h_tex)
	if theme.wall_textures.is_empty():
		var hard_single := _load_tex(base_path + "/hard_block.png")
		if hard_single:
			theme.wall_textures = [hard_single]
	
	theme.wall_texture = _load_tex(base_path + "/hard_block.png")
	theme.wall_center_texture = _load_tex(base_path + "/wall_center.png")
	theme.wall_edge_top_texture = _load_tex(base_path + "/wall_edge_top.png")
	theme.wall_edge_bottom_texture = _load_tex(base_path + "/wall_edge_bottom.png")
	theme.wall_edge_left_texture = _load_tex(base_path + "/wall_edge_left.png")
	theme.wall_edge_right_texture = _load_tex(base_path + "/wall_edge_right.png")
	theme.wall_corner_tl_texture = _load_tex(base_path + "/wall_corner_tl.png")
	theme.wall_corner_tr_texture = _load_tex(base_path + "/wall_corner_tr.png")
	theme.wall_corner_bl_texture = _load_tex(base_path + "/wall_corner_bl.png")
	theme.wall_corner_br_texture = _load_tex(base_path + "/wall_corner_br.png")
	theme.wall_cap_texture = _load_tex(base_path + "/wall_cap.png")

	# ── Destructible variants ──
	theme.destructible_textures = []
	theme.destructible_weights = []
	var dest_names: Array[String] = []
	if resolved_id == &"plaza":
		dest_names = ["soft_crate_a", "soft_crate_b", "soft_crate_c", "soft_crate_d"]
	else:
		dest_names = ["soft_crate_a", "soft_crate_b", "soft_crate_c", "soft_crate_d", "soft_barrel", "soft_bush", "soft_training_box"]
	for j in range(dest_names.size()):
		var path := "%s/%s.png" % [base_path, dest_names[j]]
		if ResourceLoader.exists(path):
			theme.destructible_textures.append(load(path) as Texture2D)
			theme.destructible_weights.append(1.0)
	if theme.destructible_textures.is_empty():
		if ResourceLoader.exists(base_path + "/soft_block.png"):
			theme.destructible_textures.append(load(base_path + "/soft_block.png") as Texture2D)
			theme.destructible_weights.append(1.0)

	# ── Contact shadow & Preview ──
	theme.contact_shadow_texture = _load_tex(base_path + "/contact_shadow.png")
	theme.preview_texture = _load_tex(base_path + "/preview.png")

	return theme

static func runtime_texture_paths(theme_id: StringName) -> PackedStringArray:
	var resolved_id: StringName = theme_id if THEME_TO_FOLDER.has(theme_id) else &"plaza"
	var folder: String = THEME_TO_FOLDER[resolved_id]
	var base_path := "res://assets/visual_overhaul_v2/maps/%s/runtime" % folder
	if not DirAccess.dir_exists_absolute(base_path):
		base_path = "res://assets/visual_overhaul_v1/maps/%s/runtime" % folder
	if not DirAccess.dir_exists_absolute(base_path):
		base_path = "res://assets/tilesets/%s/runtime" % folder
	return PackedStringArray([
		base_path + "/floor.png",
		base_path + "/floor_alt.png",
		base_path + "/hard_block.png",
		base_path + "/soft_block.png",
	])

static func _load_tex(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		return load(path) as Texture2D
	return null
