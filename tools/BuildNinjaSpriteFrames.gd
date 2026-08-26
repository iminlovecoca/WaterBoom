extends SceneTree

const SOURCE_DIR := "res://assets/characters/ninja/runtime/animations_v1"
const OUTPUT := "res://resources/characters/ninja_frames_v2.tres"
const DIRECTIONS := ["down", "up", "left", "right"]
const FRAME_COUNTS := {
	"idle": 4,
	"walk": 6,
	"place": 5,
	"pickup": 5,
	"hurt": 6,
	"bubbled": 4,
	"die": 6,
	"win": 6,
	"lose": 4,
}
const SPEEDS := {
	"idle": 4.0,
	"walk": 10.0,
	"place": 12.0,
	"pickup": 10.0,
	"hurt": 14.0,
	"bubbled": 5.0,
	"die": 8.0,
	"win": 8.0,
	"lose": 5.0,
}

func _init() -> void:
	var frames := SpriteFrames.new()
	frames.remove_animation(&"default")
	for animation in FRAME_COUNTS:
		for direction in DIRECTIONS:
			var animation_name := StringName("%s_%s" % [animation, direction])
			frames.add_animation(animation_name)
			frames.set_animation_speed(animation_name, SPEEDS[animation])
			frames.set_animation_loop(animation_name, animation in ["idle", "walk", "bubbled"])
			for frame_index in FRAME_COUNTS[animation]:
				var path := "%s/ninja_%s_%s_%02d.png" % [SOURCE_DIR, animation, direction, frame_index]
				var texture := load(path) as Texture2D
				if texture == null:
					printerr("Missing imported texture: ", path)
					quit(1)
					return
				frames.add_frame(animation_name, texture)
	var error := ResourceSaver.save(frames, OUTPUT)
	print("NINJA_SPRITE_FRAMES: ", "PASS" if error == OK else "FAIL", " | animations=", frames.get_animation_names().size())
	quit(0 if error == OK else 1)
