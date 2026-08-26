class_name ActiveCharacterRoster
extends RefCounted

## The player-facing roster contains the two production mascots plus the two
## rebuilt character sheets. Legacy nine-character assets remain on disk as
## rollback content, but are not discoverable by the game.
const IDS: Array[StringName] = [&"boom_mascot", &"cloud_bunny", &"shadow_ninja", &"aqua_pacifier"]
const PATHS: Array[String] = [
	"res://resources/characters/boom_mascot.tres",
	"res://resources/characters/cloud_bunny.tres",
	"res://resources/characters/shadow_ninja.tres",
	"res://resources/characters/aqua_pacifier.tres",
]

static func definitions() -> Array[CharacterDefinition]:
	var result: Array[CharacterDefinition] = []
	for path in PATHS:
		if not ResourceLoader.exists(path):
			continue
		var resource := load(path)
		if resource is CharacterDefinition:
			result.append(resource as CharacterDefinition)
	return result

static func is_active(character_id: StringName) -> bool:
	return IDS.has(character_id)

static func normalize_id(character_id: StringName) -> StringName:
	return character_id if is_active(character_id) else IDS[0]

static func id_for_index(index: int) -> StringName:
	return IDS[posmod(index, IDS.size())]
