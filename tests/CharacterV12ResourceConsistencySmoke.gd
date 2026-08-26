extends SceneTree

const IDS := [
	&"boom_mascot", &"cloud_bunny", &"cocoa_otter", &"coral_diver", &"lime_dino",
	&"mint_sprout", &"red_rider", &"star_skater", &"sunny_mechanic"
]
const CONTRACT := {
	&"idle_down": 4, &"idle_left": 4, &"idle_right": 4, &"idle_up": 4,
	&"walk_down": 8, &"walk_left": 8, &"walk_right": 8, &"walk_up": 8,
	&"bubble": 6, &"rescued": 4, &"lose": 6, &"win": 6, &"die": 6, &"water_hit": 4
}

func _init() -> void:
	_run.call_deferred()

func _run() -> void:
	var errors: Array[String] = []
	for id in IDS:
		var definition := load("res://resources/characters/%s.tres" % id) as CharacterDefinition
		if definition == null or definition.sprite_frames == null:
			errors.append("%s missing v12 SpriteFrames" % id)
			continue
		var frames := definition.sprite_frames
		for action in CONTRACT:
			if not frames.has_animation(action):
				errors.append("%s missing %s" % [id, action])
			elif frames.get_frame_count(action) != int(CONTRACT[action]):
				errors.append("%s %s count=%d" % [id, action, frames.get_frame_count(action)])
	var report := {"character_count": IDS.size(), "contract": CONTRACT, "errors": errors, "ok": errors.is_empty()}
	var artifact := FileAccess.open("res://tests/artifacts/character_v12_resource_consistency.json", FileAccess.WRITE)
	if artifact != null:
		artifact.store_string(JSON.stringify(report, "  "))
		artifact.close()
	if not errors.is_empty():
		push_error("CHARACTER_V12_RESOURCE_CONSISTENCY FAIL: %s" % "; ".join(errors))
		quit(1)
		return
	print("CHARACTER_V12_RESOURCE_CONSISTENCY PASS characters=9 actions=14")
	quit(0)
