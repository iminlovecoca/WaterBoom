extends Node

const DEFINITION_DIR := "res://resources/cosmetics/definitions"
const VALID_CATEGORIES: Array[StringName] = [
	CosmeticDefinition.HEAD_ACCESSORY,
	CosmeticDefinition.FLAG,
	CosmeticDefinition.PLAYER_FRAME,
	CosmeticDefinition.PLAYER_BACKGROUND,
]

# Player frames are part of the live cosmetic presentation.  Old accounts can
# still fall back to the default frame, while the shop/inventory expose every
# frame definition through the dedicated “Khung” category.
const RETIRED_PRESENTATION_CATEGORIES: Array[StringName] = []

const DEFAULT_EQUIPMENT := {
	"head_accessory": "",
	"flag": "flag_default_water",
	"player_frame": "frame_default_aqua",
	"player_background": "background_default_aqua",
}

var _definitions: Dictionary = {}

func _ready() -> void:
	reload_definitions()

func reload_definitions() -> void:
	_definitions.clear()
	var directory := DirAccess.open(DEFINITION_DIR)
	if directory == null:
		push_warning("Cosmetic definition directory is missing: %s" % DEFINITION_DIR)
		return
	for file_name in directory.get_files():
		if not file_name.ends_with(".tres"):
			continue
		var resource := load(DEFINITION_DIR.path_join(file_name))
		if resource is CosmeticDefinition:
			var definition := resource as CosmeticDefinition
			if definition.id != &"" and VALID_CATEGORIES.has(definition.category_id()):
				_definitions[definition.id] = definition

func get_definition(cosmetic_id: Variant) -> CosmeticDefinition:
	return _definitions.get(StringName(str(cosmetic_id))) as CosmeticDefinition

func has_definition(cosmetic_id: Variant) -> bool:
	return _definitions.has(StringName(str(cosmetic_id)))

func definitions_for_category(category: StringName) -> Array[CosmeticDefinition]:
	var result: Array[CosmeticDefinition] = []
	for definition in _definitions.values():
		if definition.category_id() == category:
			result.append(definition)
	result.sort_custom(func(a: CosmeticDefinition, b: CosmeticDefinition): return a.price < b.price)
	return result

func is_presentation_category_enabled(category: StringName) -> bool:
	return not RETIRED_PRESENTATION_CATEGORIES.has(category)

func visible_definitions() -> Array[CosmeticDefinition]:
	var result: Array[CosmeticDefinition] = []
	for definition in _definitions.values():
		if is_presentation_category_enabled(definition.category_id()):
			result.append(definition)
	result.sort_custom(func(a: CosmeticDefinition, b: CosmeticDefinition):
		if a.category == b.category:
			return a.price < b.price
		return a.category < b.category
	)
	return result

func get_all_definitions() -> Array[CosmeticDefinition]:
	return all_definitions()

func all_definitions() -> Array[CosmeticDefinition]:
	var result: Array[CosmeticDefinition] = []
	for definition in _definitions.values():
		result.append(definition)
	result.sort_custom(func(a: CosmeticDefinition, b: CosmeticDefinition):
		if a.category == b.category:
			return a.price < b.price
		return a.category < b.category
	)
	return result

func default_equipment() -> Dictionary:
	return DEFAULT_EQUIPMENT.duplicate(true)

func sanitize_equipment(source: Dictionary, owned: Array = []) -> Dictionary:
	var result := default_equipment()
	for category in VALID_CATEGORIES:
		var key := str(category)
		var value := str(source.get(key, result[key]))
		if category == CosmeticDefinition.HEAD_ACCESSORY and value.is_empty():
			result[key] = ""
			continue
		var definition := get_definition(value)
		if definition == null or definition.category_id() != category:
			continue
		if not owned.is_empty() and not owned.has(value) and not owned.has(StringName(value)) and not definition.is_default:
			continue
		result[key] = value
	return result

func all_default_owned_ids() -> Array[StringName]:
	var result: Array[StringName] = []
	for definition in _definitions.values():
		if definition.is_default:
			result.append(definition.id)
	return result
