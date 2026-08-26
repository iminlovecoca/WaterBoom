class_name MapThemeDefinition
extends Resource

@export var id: StringName = &"plaza"
@export var preview_texture: Texture2D

# ── Floor tiles (6 variants for visual variety) ──
@export var floor_textures: Array[Texture2D] = []
@export var alternate_floor_textures: Array[Texture2D] = []
@export_range(0.0, 1.0, 0.01) var alternate_floor_frequency: float = 0.18

# ── Wall / indestructible block (connected autotile pieces) ──
@export var wall_textures: Array[Texture2D] = []
@export var wall_texture: Texture2D
@export var wall_center_texture: Texture2D
@export var wall_edge_top_texture: Texture2D
@export var wall_edge_bottom_texture: Texture2D
@export var wall_edge_left_texture: Texture2D
@export var wall_edge_right_texture: Texture2D
@export var wall_corner_tl_texture: Texture2D
@export var wall_corner_tr_texture: Texture2D
@export var wall_corner_bl_texture: Texture2D
@export var wall_corner_br_texture: Texture2D
@export var wall_cap_texture: Texture2D

# ── Destructible block (multiple visual variants) ──
@export var destructible_textures: Array[Texture2D] = []
@export var destructible_weights: Array[float] = []

# ── Contact shadow texture (drawn beneath blocks) ──
@export var contact_shadow_texture: Texture2D

# ── Legacy single textures (backward compat) ──
@export var floor_texture: Texture2D:
	get:
		if floor_textures.size() > 0:
			return floor_textures[0]
		return null
@export var alternate_floor_texture: Texture2D:
	get:
		if alternate_floor_textures.size() > 0:
			return alternate_floor_textures[0]
		return null
@export var destructible_texture: Texture2D:
	get:
		if destructible_textures.size() > 0:
			return destructible_textures[0]
		return null

func get_floor_variant(hash_value: int, use_alternate: bool) -> Texture2D:
	if use_alternate and alternate_floor_textures.size() > 0:
		return alternate_floor_textures[hash_value % alternate_floor_textures.size()]
	elif floor_textures.size() > 0:
		return floor_textures[hash_value % floor_textures.size()]
	return floor_texture

func get_destructible_variant(hash_value: int) -> Texture2D:
	if destructible_textures.size() > 0:
		if destructible_weights.size() == destructible_textures.size():
			var total := 0.0
			for w in destructible_weights:
				total += w
			var pick := (hash_value % 1000) / 1000.0 * total
			var accum := 0.0
			for i in range(destructible_textures.size()):
				accum += destructible_weights[i]
				if pick < accum:
					return destructible_textures[i]
			return destructible_textures[0]
		return destructible_textures[hash_value % destructible_textures.size()]
	return destructible_texture

func get_wall_variant(hash_value: int) -> Texture2D:
	if wall_textures.size() > 0:
		return wall_textures[hash_value % wall_textures.size()]
	return wall_texture
