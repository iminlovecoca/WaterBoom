extends Node

func _ready() -> void:
	var errors: Array[String] = []
	var definitions := ActiveCharacterRoster.definitions()
	if definitions.size() != 4:
		errors.append("expected exactly 4 active definitions, got %d" % definitions.size())
	var ids: Array[StringName] = []
	for definition in definitions:
		ids.append(definition.id)
	if not ids.has(&"boom_mascot") or not ids.has(&"cloud_bunny") or not ids.has(&"shadow_ninja") or not ids.has(&"aqua_pacifier"):
		errors.append("active ids=%s" % ids)
	if ActiveCharacterRoster.normalize_id(&"coral_diver") != &"boom_mascot":
		errors.append("retired id did not normalize to boom_mascot")
	if ActiveCharacterRoster.normalize_id(&"cloud_bunny") != &"cloud_bunny":
		errors.append("cloud_bunny was not preserved")
	if ActiveCharacterRoster.normalize_id(&"shadow_ninja") != &"shadow_ninja":
		errors.append("shadow_ninja was not preserved")
	if ActiveCharacterRoster.normalize_id(&"aqua_pacifier") != &"aqua_pacifier":
		errors.append("aqua_pacifier was not preserved")
	if not errors.is_empty():
		push_error("ACTIVE_CHARACTER_ROSTER FAIL: %s" % "; ".join(errors))
		get_tree().quit(1)
		return
	print("ACTIVE_CHARACTER_ROSTER PASS active=boom_mascot,cloud_bunny,shadow_ninja,aqua_pacifier")
	get_tree().quit(0)
