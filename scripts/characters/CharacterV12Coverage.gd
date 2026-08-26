class_name CharacterV12Coverage
extends RefCounted

## Read-only coverage report for the v12 character staging bundle.
## It never touches production resources and is safe to run in CI/headless Godot.

const CHARACTER_IDS := [
	&"boom_mascot", &"cloud_bunny", &"cocoa_otter", &"coral_diver", &"lime_dino",
	&"mint_sprout", &"red_rider", &"star_skater", &"sunny_mechanic"
]

const EXPECTED_FRAMES := {
	&"idle_down": 4, &"idle_up": 4, &"idle_left": 4, &"idle_right": 4,
	&"walk_down": 8, &"walk_up": 8, &"walk_left": 8, &"walk_right": 8,
	&"rescue": 4, &"water_hit": 4, &"bubble": 6, &"rescued": 4,
	&"die": 6, &"win": 6, &"lose": 6
}

static func build_report(root: String = "res://assets/characters") -> Dictionary:
	var characters: Array[Dictionary] = []
	var complete_count := 0
	for character_id in CHARACTER_IDS:
		var coverage := _character_coverage(root, String(character_id))
		if bool(coverage["complete"]):
			complete_count += 1
		characters.append(coverage)
	return {
		"schema_version": 1,
		"expected_character_count": CHARACTER_IDS.size(),
		"complete_character_count": complete_count,
		"characters": characters
	}

static func _character_coverage(root: String, character_id: String) -> Dictionary:
	var actions: Array[Dictionary] = []
	var total := 0
	var expected_total := 0
	var complete := true
	for action in EXPECTED_FRAMES:
		var expected: int = int(EXPECTED_FRAMES[action])
		var directory := "%s/%s/v12_staging/runtime_frames/%s" % [root, character_id, action]
		var actual := _count_pngs(directory)
		var passed := actual == expected
		total += actual
		expected_total += expected
		if not passed:
			complete = false
		actions.append({"name": String(action), "expected": expected, "actual": actual, "complete": passed})
	return {
		"id": character_id,
		"complete": complete,
		"total_frames": total,
		"expected_frames": expected_total,
		"actions": actions
	}

static func _count_pngs(directory: String) -> int:
	var dir := DirAccess.open(directory)
	if dir == null:
		return 0
	var count := 0
	dir.list_dir_begin()
	var entry := dir.get_next()
	while entry != "":
		if not dir.current_is_dir() and entry.to_lower().ends_with(".png"):
			count += 1
		entry = dir.get_next()
	dir.list_dir_end()
	return count
