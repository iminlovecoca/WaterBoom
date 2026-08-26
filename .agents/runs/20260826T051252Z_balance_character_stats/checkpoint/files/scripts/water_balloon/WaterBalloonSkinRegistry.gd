extends Node

const CATALOG_PATH := "res://assets/water_balloons/water_balloon_catalog.json"
const FALLBACK_SKIN := &"skin_066"
const RUNTIME_TARGET_AREA := 10000.0
const ICON_TARGET_AREA := 2916.0

var skins: Dictionary = {}  # StringName -> WaterBalloonSkinDefinition
var skin_order: Array[StringName] = []
var vfx_profiles: Dictionary = {}
var display_scale_cache: Dictionary = {}

func _ready() -> void:
	_load_catalog()

func _load_catalog() -> void:
	display_scale_cache.clear()
	var file := FileAccess.open(CATALOG_PATH, FileAccess.READ)
	if file == null:
		push_warning("WaterBalloonSkinRegistry: Cannot load catalog at %s" % CATALOG_PATH)
		return
	var json_text := file.get_as_text()
	file.close()
	var json := JSON.new()
	var err := json.parse(json_text)
	if err != OK:
		push_warning("WaterBalloonSkinRegistry: JSON parse error: %s" % json.get_error_message())
		return
	var data: Dictionary = json.data
	if not data.has("skins"):
		push_warning("WaterBalloonSkinRegistry: Catalog missing 'skins' key")
		return
	for skin_data in data["skins"]:
		var def := WaterBalloonSkinDefinition.new()
		def.id = StringName(skin_data.get("id", ""))
		def.display_name = skin_data.get("name", "")
		def.theme = skin_data.get("theme", "basic")
		def.primary_color = Color.html(skin_data.get("primary_color", "#ffffff"))
		def.secondary_color = Color.html(skin_data.get("secondary_color", "#ffffff"))
		def.outline_color = Color.html(skin_data.get("outline_color", "#000000"))
		def.motif = skin_data.get("motif", "basic")
		def.description = skin_data.get("description", "")
		def.rarity = skin_data.get("rarity", "common")
		def.price = skin_data.get("price", 0)
		def.vfx_profile = skin_data.get("vfx_profile", "water_default")
		def.burst_accent = skin_data.get("burst_accent", "blue_splash")
		def.icon = _load_texture("res://assets/water_balloons/skins/%s/icon.png" % def.id)
		def.sprite_frames = _load_resource("res://assets/water_balloons/skins/%s/%s_frames.tres" % [def.id, def.id])
		if def.id != &"":
			skins[def.id] = def
			skin_order.append(def.id)
	if data.has("vfx_profiles"):
		vfx_profiles = data["vfx_profiles"]
	# Keep the four legacy-compatible shipped skins and all new skins in catalog
	# order, with Aqua Classic Reforge as the only runtime fallback.
	if not skins.has(FALLBACK_SKIN) and not skin_order.is_empty():
		skin_order.insert(0, FALLBACK_SKIN)
	if skins.has(FALLBACK_SKIN):
		skin_order.erase(FALLBACK_SKIN)
		skin_order.insert(0, FALLBACK_SKIN)

func _load_texture(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		return load(path)
	return null

func _load_resource(path: String) -> Resource:
	if ResourceLoader.exists(path):
		return load(path)
	return null

func get_skin(skin_id: StringName) -> WaterBalloonSkinDefinition:
	if skins.has(skin_id):
		return skins[skin_id]
	if skins.has(FALLBACK_SKIN):
		return skins[FALLBACK_SKIN]
	return null

func get_textures(skin_id: StringName) -> Array[Texture2D]:
	var def := get_skin(skin_id)
	if def == null:
		return _get_classic_textures()
	if def.sprite_frames != null and def.sprite_frames.has_animation(&"idle"):
		var textures: Array[Texture2D] = []
		for i in range(def.sprite_frames.get_frame_count(&"idle")):
			textures.append(def.sprite_frames.get_frame_texture(&"idle", i))
		if textures.size() > 0:
			return textures
	return _get_classic_textures()

func _get_classic_textures() -> Array[Texture2D]:
	var textures: Array[Texture2D] = []
	for i in range(4):
		var path := "res://assets/water_balloons/skins/%s/idle_%d.png" % [FALLBACK_SKIN, i]
		if ResourceLoader.exists(path):
			textures.append(load(path))
	return textures

func get_vfx_tint(skin_id: StringName) -> Color:
	var def := get_skin(skin_id)
	if def != null:
		return def.get_vfx_tint()
	return Color.WHITE

func get_icon(skin_id: StringName) -> Texture2D:
	var def := get_skin(skin_id)
	if def != null and def.icon != null:
		return def.icon
	return _get_fallback_icon()

func _texture_used_area(texture: Texture2D) -> float:
	if texture == null:
		return 1.0
	var used := texture.get_image().get_used_rect()
	if used.size.x <= 0 or used.size.y <= 0:
		return 1.0
	return maxf(float(used.size.x) * float(used.size.y), 1.0)

func _scale_for_texture(texture: Texture2D, target_area: float) -> float:
	return sqrt(target_area / _texture_used_area(texture))

## Shared runtime correction for source sheets whose transparent margins differ.
## It preserves the art and only normalizes the rendered footprint.
func get_runtime_scale(skin_id: StringName) -> float:
	var key := "%s:runtime" % String(skin_id)
	if display_scale_cache.has(key):
		return float(display_scale_cache[key])
	var textures := get_textures(skin_id)
	var scale := _scale_for_texture(textures[0], RUNTIME_TARGET_AREA) if not textures.is_empty() else 1.0
	display_scale_cache[key] = scale
	return scale

## Shared icon correction used by shop, inventory and gallery cards.
func get_icon_scale(skin_id: StringName) -> float:
	var key := "%s:icon" % String(skin_id)
	if display_scale_cache.has(key):
		return float(display_scale_cache[key])
	var def := get_skin(skin_id)
	var scale := _scale_for_texture(def.icon, ICON_TARGET_AREA) if def != null and def.icon != null else 1.0
	display_scale_cache[key] = scale
	return scale

func _get_fallback_icon() -> Texture2D:
	var path := "res://assets/water_balloons/skins/%s/icon.png" % FALLBACK_SKIN
	if ResourceLoader.exists(path):
		return load(path)
	return null

func get_all_skin_ids() -> Array[StringName]:
	return skin_order.duplicate()

func get_skins_by_theme(theme: String) -> Array[WaterBalloonSkinDefinition]:
	var result: Array[WaterBalloonSkinDefinition] = []
	for id in skin_order:
		var def: WaterBalloonSkinDefinition = skins[id]
		if def.theme.begins_with(theme):
			result.append(def)
	return result

func get_skins_by_rarity(rarity: String) -> Array[WaterBalloonSkinDefinition]:
	var result: Array[WaterBalloonSkinDefinition] = []
	for id in skin_order:
		var def: WaterBalloonSkinDefinition = skins[id]
		if def.rarity == rarity:
			result.append(def)
	return result

func get_skin_count() -> int:
	return skins.size()

func get_display_name(skin_id: StringName) -> String:
	var def := get_skin(skin_id)
	if def != null:
		return def.display_name
	return "Unknown"

func get_price(skin_id: StringName) -> int:
	var def := get_skin(skin_id)
	if def != null:
		return def.price
	return 0

func register_skin(def: WaterBalloonSkinDefinition) -> void:
	if def.id != &"" and not skins.has(def.id):
		skins[def.id] = def
		skin_order.append(def.id)
