class_name CharacterPresentation
extends RefCounted

## Shared presentation contract for every small character surface.
##
## V13 characters are authored on a 112x112 canvas with their feet on y=103.
## UI cards must scale that canvas as one unit; cropping a guessed "head"
## rectangle makes characters with taller hats, hair, or helmets disappear.
const RUNTIME_CANVAS := Vector2(112.0, 112.0)
const CARD_SCALE := 0.72
const SLOT_SCALE := 0.72

# Correct transparent-margin differences at presentation time without
# cropping or rewriting the source character frames. The bunny is narrower
# than the bear baseline on the same 112x112 canvas.
const CHARACTER_CONTENT_SCALE_OVERRIDES := {
	&"cloud_bunny": 1.18,
}

static func idle_texture(definition: CharacterDefinition, animation: StringName = &"idle_down", frame: int = 0) -> Texture2D:
	if definition == null or definition.sprite_frames == null:
		return null
	var frames := definition.sprite_frames
	if not frames.has_animation(animation):
		animation = &"idle_down"
	if not frames.has_animation(animation) or frames.get_frame_count(animation) <= 0:
		return null
	return frames.get_frame_texture(animation, clampi(frame, 0, frames.get_frame_count(animation) - 1))

static func full_frame_atlas(texture: Texture2D) -> AtlasTexture:
	if texture == null:
		return null
	var atlas := AtlasTexture.new()
	atlas.atlas = texture
	atlas.region = Rect2(Vector2.ZERO, RUNTIME_CANVAS)
	return atlas

static func content_scale(definition: CharacterDefinition) -> float:
	if definition == null:
		return 1.0
	return float(CHARACTER_CONTENT_SCALE_OVERRIDES.get(StringName(definition.id), 1.0))

static func content_scale_vector(definition: CharacterDefinition) -> Vector2:
	# The bunny's art is narrower, not shorter. Correct its horizontal
	# footprint only so feet stay on the shared baseline and never clip cards.
	return Vector2(content_scale(definition), 1.0)

static func runtime_scale(definition: CharacterDefinition) -> float:
	if definition == null:
		return 1.0
	return float(definition.visual_scale)

static func runtime_scale_vector(definition: CharacterDefinition) -> Vector2:
	if definition == null:
		return Vector2.ONE
	return Vector2.ONE * float(definition.visual_scale) * content_scale_vector(definition)

static func card_scale_for(definition: CharacterDefinition) -> float:
	return CARD_SCALE

static func card_scale_vector_for(definition: CharacterDefinition) -> Vector2:
	return Vector2.ONE * CARD_SCALE * content_scale_vector(definition)

static func slot_scale_for(definition: CharacterDefinition) -> float:
	return SLOT_SCALE

static func slot_scale_vector_for(definition: CharacterDefinition) -> Vector2:
	return Vector2.ONE * SLOT_SCALE * content_scale_vector(definition)

static func card_scale(character_scale: float = 1.25) -> float:
	# character_scale belongs to gameplay; UI cards use one fixed safe scale so
	# all silhouettes remain inside the same rounded card.
	return CARD_SCALE

static func slot_scale(character_scale: float = 1.25) -> float:
	return SLOT_SCALE
