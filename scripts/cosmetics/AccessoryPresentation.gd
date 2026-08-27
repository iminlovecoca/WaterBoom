class_name AccessoryPresentation
extends RefCounted

## One placement contract for every head-accessory presentation surface.
## Individual CosmeticDefinition offsets/scales remain small art-specific
## corrections; the profile owns the shared silhouette and anchor rules.

const PROFILE_RING: StringName = &"ring"
const PROFILE_FACE: StringName = &"face"
const PROFILE_HAT: StringName = &"hat"

const CONTEXT_CARD: StringName = &"card"
const CONTEXT_ROOM: StringName = &"room"
const CONTEXT_MATCH_LIST: StringName = &"match_list"
const CONTEXT_WORLD: StringName = &"world"

const VALID_PROFILES: Array[StringName] = [PROFILE_RING, PROFILE_FACE, PROFILE_HAT]


static func profile_for(definition: CosmeticDefinition) -> StringName:
	if definition == null:
		return PROFILE_RING
	var profile := StringName(definition.placement_profile)
	return profile if VALID_PROFILES.has(profile) else PROFILE_RING


static func texture_for(definition: CosmeticDefinition, context: StringName) -> Texture2D:
	if definition == null:
		return null
	match context:
		CONTEXT_MATCH_LIST:
			return definition.match_list_asset if definition.match_list_asset != null else definition.icon
		CONTEXT_WORLD:
			return definition.world_asset if definition.world_asset != null else definition.icon
		_:
			return definition.lobby_asset if definition.lobby_asset != null else definition.icon


static func control_rect(definition: CosmeticDefinition, context: StringName) -> Rect2:
	var profile := profile_for(definition)
	var center := Vector2.ZERO
	var desired_size := Vector2.ZERO
	var fine_offset := Vector2.ZERO
	var fine_scale := 1.0

	match context:
		CONTEXT_MATCH_LIST:
			center = _match_list_center(profile)
			desired_size = _match_list_size(profile)
			fine_offset = definition.match_list_offset if definition != null else Vector2.ZERO
			fine_scale = definition.match_list_scale if definition != null else 1.0
		_:
			# PlayerCardPreview and room cards share the same complete 112x112
			# character canvas and feet anchor, so they intentionally share one
			# head anchor too.
			center = _card_center(profile)
			desired_size = _card_size(profile)
			fine_offset = definition.lobby_offset if definition != null else Vector2.ZERO
			fine_scale = definition.lobby_scale if definition != null else 1.0

	desired_size *= maxf(fine_scale, 0.05)
	return Rect2(center + fine_offset - desired_size * 0.5, desired_size)


static func world_position(definition: CosmeticDefinition) -> Vector2:
	var position := Vector2.ZERO
	match profile_for(definition):
		PROFILE_FACE:
			position = Vector2(0.0, -47.0)
		PROFILE_HAT:
			position = Vector2(0.0, -60.0)
		_:
			# A ring is deliberately wider than the character head and sits around
			# its upper contour, not as a small icon floating above it.
			position = Vector2(0.0, -53.0)
	if definition != null:
		position += definition.world_offset
	return position


static func world_sprite_scale(definition: CosmeticDefinition, texture: Texture2D) -> Vector2:
	if texture == null:
		return Vector2.ONE
	var target := _world_size(profile_for(definition))
	var texture_size := texture.get_size()
	if texture_size.x <= 0.0 or texture_size.y <= 0.0:
		return Vector2.ONE
	var uniform := minf(target.x / texture_size.x, target.y / texture_size.y)
	if definition != null:
		uniform *= maxf(definition.world_scale, 0.05)
	return Vector2.ONE * uniform


static func uses_bob_animation(definition: CosmeticDefinition) -> bool:
	# Rings may gently float around the head. Face items and hats must remain
	# locked to facial/head anchors so they never swim during idle animation.
	return definition != null and profile_for(definition) == PROFILE_RING and definition.animation == "bob"


static func _card_center(profile: StringName) -> Vector2:
	match profile:
		PROFILE_FACE:
			return Vector2(48, 43)
		PROFILE_HAT:
			return Vector2(48, 25)
		_:
			return Vector2(48, 31)


static func _card_size(profile: StringName) -> Vector2:
	match profile:
		PROFILE_FACE:
			return Vector2(58, 42)
		PROFILE_HAT:
			return Vector2(74, 62)
		_:
			return Vector2(86, 72)


static func _match_list_center(profile: StringName) -> Vector2:
	match profile:
		PROFILE_FACE:
			return Vector2(28, 29)
		PROFILE_HAT:
			return Vector2(28, 22)
		_:
			# Keep the complete ring inside the 58 px sidebar row. Earlier anchors
			# put its top three pixels outside the slot and visibly clipped the halo.
			return Vector2(28, 24)


static func _match_list_size(profile: StringName) -> Vector2:
	match profile:
		PROFILE_FACE:
			return Vector2(38, 28)
		PROFILE_HAT:
			return Vector2(48, 42)
		_:
			return Vector2(54, 46)


static func _world_size(profile: StringName) -> Vector2:
	match profile:
		PROFILE_FACE:
			return Vector2(54, 54)
		PROFILE_HAT:
			return Vector2(70, 70)
		_:
			return Vector2(78, 78)
