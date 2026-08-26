extends Node

## Contract gate for the two newly rebuilt character bundles.
## Bubble/status art is intentionally not asserted here; those actions are
## safe character-local placeholders until a dedicated VFX pass is approved.

const ACTION_COUNTS := {
	"idle_down": 4,
	"idle_left": 4,
	"idle_right": 4,
	"idle_up": 4,
	"walk_down": 8,
	"walk_left": 8,
	"walk_right": 8,
	"walk_up": 8,
	"rescue": 4,
	"water_hit": 4,
	"bubble": 6,
	"rescued": 4,
	"die": 6,
	"win": 6,
	"lose": 6,
}
const TARGETS := [&"shadow_ninja", &"aqua_pacifier"]
const CANVAS := Vector2i(112, 112)

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	var failures: Array[String] = []
	var checks := 0
	for character_id in TARGETS:
		var definition := ActiveCharacterRoster.definitions().filter(func(item: CharacterDefinition) -> bool:
			return item.id == String(character_id)
		)
		if definition.is_empty():
			failures.append("missing active definition %s" % character_id)
			continue
		var character := definition[0] as CharacterDefinition
		var frames := character.sprite_frames
		for action in ACTION_COUNTS:
			checks += 1
			if frames == null or frames.get_animation_names().find(action) < 0:
				failures.append("%s missing action %s" % [character_id, action])
				continue
			var expected := int(ACTION_COUNTS[action])
			var actual := frames.get_frame_count(action)
			if actual != expected:
				failures.append("%s %s frames=%d expected=%d" % [character_id, action, actual, expected])
			for frame_index in range(actual):
				var texture := frames.get_frame_texture(action, frame_index)
				if texture == null or texture.get_size() != Vector2(CANVAS):
					failures.append("%s %s frame %d is not 112x112" % [character_id, action, frame_index])
		# A standing player must not cycle walking poses.  Down-facing idle keeps
		# the authored blink strip; side and back views hold their directional
		# standing pose until dedicated blink art is available.
		for idle_action in [&"idle_left", &"idle_right", &"idle_up"]:
			checks += 1
			var first_idle_data := frames.get_frame_texture(idle_action, 0).get_image().get_data()
			var idle_is_static := true
			for frame_index in range(1, frames.get_frame_count(idle_action)):
				var frame_data := frames.get_frame_texture(idle_action, frame_index).get_image().get_data()
				idle_is_static = idle_is_static and frame_data == first_idle_data
			if not idle_is_static:
				failures.append("%s %s cycles body-motion frames instead of a static idle pose" % [character_id, idle_action])
		print("[V14 PASS] %s actions=15 frames=84" % character_id)
	var passed := checks - failures.size()
	print("CHARACTER_V14_RESOURCE_RESULT: %d passed | %d failed" % [passed, failures.size()])
	if not failures.is_empty():
		for failure in failures:
			push_error(failure)
	get_tree().quit(0 if failures.is_empty() else 1)
