extends SceneTree

const IDS := [
	&"boom_mascot", &"cloud_bunny"
]
const CONTRACT := {
	&"idle_down": 4, &"idle_left": 4, &"idle_right": 4, &"idle_up": 4,
	&"walk_down": 8, &"walk_left": 8, &"walk_right": 8, &"walk_up": 8,
	&"rescue": 4, &"water_hit": 4, &"bubble": 6, &"rescued": 4,
	&"die": 6, &"win": 6, &"lose": 6
}

func _init() -> void:
	_run.call_deferred()

func _run() -> void:
	var errors: Array[String] = []
	for id: StringName in IDS:
		var definition := load("res://resources/characters/%s.tres" % id) as CharacterDefinition
		if definition == null or definition.sprite_frames == null:
			errors.append("%s missing V13 SpriteFrames" % id)
			continue
		var frames := definition.sprite_frames
		if frames.get_animation_names().size() != CONTRACT.size():
			errors.append("%s action_count=%d" % [id, frames.get_animation_names().size()])
		for action: StringName in CONTRACT:
			if not frames.has_animation(action):
				errors.append("%s missing %s" % [id, action])
			elif frames.get_frame_count(action) != int(CONTRACT[action]):
				errors.append("%s %s count=%d" % [id, action, frames.get_frame_count(action)])
			else:
				for frame_index in frames.get_frame_count(action):
					var texture := frames.get_frame_texture(action, frame_index)
					if texture == null:
						errors.append("%s %s frame=%d missing texture" % [id, action, frame_index])
					elif texture.get_size() != Vector2(112, 112):
						errors.append("%s %s frame=%d size=%s" % [id, action, frame_index, texture.get_size()])
					elif action in [&"idle_down", &"idle_left", &"idle_right", &"idle_up", &"walk_down", &"walk_left", &"walk_right", &"walk_up"]:
						# A missing lower row is the signature of the old source-cell crop.
						# Keep a hard runtime check on the shared feet band for the active roster.
						var image := texture.get_image()
						var alpha_box := image.get_used_rect()
						if alpha_box.size.y == 0 or alpha_box.end.y < 100:
							errors.append("%s %s frame=%d lower body crop bbox=%s" % [id, action, frame_index, alpha_box])
	var report := {"character_count": IDS.size(), "action_count": CONTRACT.size(), "contract": CONTRACT, "errors": errors, "ok": errors.is_empty()}
	var artifact := FileAccess.open("res://tests/artifacts/character_v13_resource_consistency.json", FileAccess.WRITE)
	if artifact != null:
		artifact.store_string(JSON.stringify(report, "  "))
		artifact.close()
	if not errors.is_empty():
		push_error("CHARACTER_V13_RESOURCE_CONSISTENCY FAIL: %s" % "; ".join(errors))
		quit(1)
		return
	print("CHARACTER_V13_RESOURCE_CONSISTENCY PASS characters=%d actions=15 frames_per_character=84" % IDS.size())
	quit(0)
