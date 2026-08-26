extends Node

var failures: Array[String] = []
var checks_run := 0

const V13_CONTRACT := {
	&"idle_down": 4, &"idle_left": 4, &"idle_right": 4, &"idle_up": 4,
	&"walk_down": 8, &"walk_left": 8, &"walk_right": 8, &"walk_up": 8,
	&"rescue": 4, &"water_hit": 4, &"bubble": 6, &"rescued": 4,
	&"die": 6, &"win": 6, &"lose": 6
}

func _ready() -> void:
	_run.call_deferred()

func check(condition: bool, label: String) -> void:
	checks_run += 1
	if condition:
		print("[CHARACTER PASS] ", label)
	else:
		print("[CHARACTER FAIL] ", label)
		failures.append(label)

func _spawn_player() -> PlayerController:
	var player := preload("res://scenes/characters/Player.tscn").instantiate() as PlayerController
	player.is_local_control = false
	add_child(player)
	return player

func _run() -> void:
	var player := _spawn_player()
	await get_tree().process_frame
	var visual := player.visual as PlayerVisual
	check(player.character_def != null and player.character_def.id == "boom_mascot", "Player scene uses Brown Bear CharacterDefinition")
	check(visual.sprite.visible and not visual.development_character.visible, "approved sprite replaces procedural fallback")
	check(visual.sprite.sprite_frames.get_animation_names().size() == V13_CONTRACT.size(), "all 15 rebuilt animation clips are loaded")
	var red_character: CharacterDefinition = load("res://resources/characters/red_rider.tres")
	check(red_character != null and red_character.sprite_frames.get_animation_names().size() == V13_CONTRACT.size(), "Red Comet uses the rebuilt animation set")
	var sunny_character: CharacterDefinition = load("res://resources/characters/sunny_mechanic.tres")
	var mint_character: CharacterDefinition = load("res://resources/characters/mint_sprout.tres")
	var mascot_character: CharacterDefinition = load("res://resources/characters/boom_mascot.tres")
	var cloud_character: CharacterDefinition = load("res://resources/characters/cloud_bunny.tres")
	var lime_character: CharacterDefinition = load("res://resources/characters/lime_dino.tres")
	var star_character: CharacterDefinition = load("res://resources/characters/star_skater.tres")
	var cocoa_character: CharacterDefinition = load("res://resources/characters/cocoa_otter.tres")
	var ninja_character: CharacterDefinition = load("res://resources/characters/shadow_ninja.tres")
	var aqua_character: CharacterDefinition = load("res://resources/characters/aqua_pacifier.tres")
	check(sunny_character != null and sunny_character.sprite_frames.get_animation_names().size() == V13_CONTRACT.size(), "Sunny Mechanic uses the rebuilt animation set")
	check(mint_character != null and mint_character.sprite_frames.get_animation_names().size() == V13_CONTRACT.size(), "Mint Sprout uses the rebuilt animation set")
	check(mascot_character != null and mascot_character.sprite_frames.get_animation_names().size() == V13_CONTRACT.size(), "Boom Bear mascot uses the rebuilt animation set")
	check(cloud_character != null and cloud_character.sprite_frames.get_animation_names().size() == V13_CONTRACT.size(), "Cloud Bunny uses the rebuilt animation set")
	check(lime_character != null and lime_character.sprite_frames.get_animation_names().size() == V13_CONTRACT.size(), "Lime Dino uses the rebuilt animation set")
	check(star_character != null and star_character.sprite_frames.get_animation_names().size() == V13_CONTRACT.size(), "Star Skater uses the rebuilt animation set")
	check(cocoa_character != null and cocoa_character.sprite_frames.get_animation_names().size() == V13_CONTRACT.size(), "Cocoa Otter uses the rebuilt animation set")
	check(ninja_character != null and ninja_character.sprite_frames.get_animation_names().size() == V13_CONTRACT.size(), "Shadow Ninja uses the V14 animation set")
	check(aqua_character != null and aqua_character.sprite_frames.get_animation_names().size() == V13_CONTRACT.size(), "Aqua Pacifier uses the V14 animation set")
	var stepping_ok := true
	var authored_idle_ok := true
	var shared_contract_ok := true
	# Only the player-facing roster is part of the production contract.  The
	# older nine sheets stay on disk as rollback content, but they are not
	# discoverable by the game and should not make the active-art gate fail.
	var active_characters := ActiveCharacterRoster.definitions()
	for character: CharacterDefinition in active_characters:
		var frames := character.sprite_frames
		for action: StringName in V13_CONTRACT:
			shared_contract_ok = shared_contract_ok and frames.has_animation(action)
			if frames.has_animation(action):
				shared_contract_ok = shared_contract_ok and frames.get_frame_count(action) == int(V13_CONTRACT[action])
		stepping_ok = stepping_ok and frames.get_frame_count(&"walk_down") == 8
		var first_step := frames.get_frame_texture(&"walk_down", 0).get_image().get_data()
		var opposite_step := frames.get_frame_texture(&"walk_down", 2).get_image().get_data()
		stepping_ok = stepping_ok and first_step != opposite_step
	# The two new V14 sheets have authored idle frames in every direction.  The
	# older mascot sheets intentionally keep their existing idle cadence, so do
	# not reject those rollback assets here.
	for character: CharacterDefinition in [ninja_character, aqua_character]:
		var frames := character.sprite_frames
		for idle_name: StringName in [&"idle_down", &"idle_up", &"idle_left", &"idle_right"]:
			authored_idle_ok = authored_idle_ok and frames.get_frame_count(idle_name) == 4
			for frame_index in range(4):
				authored_idle_ok = authored_idle_ok and frames.get_frame_texture(idle_name, frame_index) != null
	check(stepping_ok, "active characters use eight alternating short-foot step frames")
	check(authored_idle_ok, "V14 characters use four authored idle frames in every direction")
	check(shared_contract_ok, "active characters share the same action names and frame counts")

	visual.update_state(GameConstants.PlayerState.WALKING, GameConstants.Direction.LEFT)
	check(visual.sprite.animation == &"walk_left", "movement selects the matching direction")
	visual.play_place(GameConstants.Direction.RIGHT)
	check(visual.sprite.animation == &"idle_right" and not visual.one_shot_active, "Water Balloon placement keeps the directional idle pose")
	await get_tree().create_timer(0.5).timeout
	visual.play_pickup()
	check(visual.sprite.animation == &"idle_right" and not visual.sprite.sprite_frames.has_animation(&"pickup"), "item collection uses VFX without a pickup animation clip")
	await get_tree().create_timer(0.55).timeout

	visual.play_hurt_then_bubble(GameConstants.Direction.DOWN)
	visual.set_bubble(true)
	check(visual.sprite.animation == &"water_hit" and visual.bubble.visible, "water hit starts hurt pose and bubble layer")
	await get_tree().create_timer(0.5).timeout
	check(visual.sprite.animation == &"bubble" and visual.status_vfx.mode == &"bubbled", "hurt transitions into bubbled crying loop")
	visual.set_bubble_progress(0.25)
	check(is_equal_approx(visual.bubble.time_progress, 0.25) and visual.bubble.modulate.r < 1.0, "bubble becomes denser/darker as the five-second timer expires")
	visual.set_bubble(false)
	check(visual.sprite.animation == &"rescued", "rescue plays its dedicated release animation")
	visual.play_death()
	check(visual.sprite.animation == &"die", "death animation is wired")

	var winner := _spawn_player()
	await get_tree().process_frame
	var winner_visual := winner.visual as PlayerVisual
	winner_visual.play_win()
	check(winner_visual.sprite.animation == &"win" and winner_visual.status_vfx.mode == &"win", "winner animation and sparkles are wired")
	var loser := _spawn_player()
	await get_tree().process_frame
	var loser_visual := loser.visual as PlayerVisual
	loser_visual.play_lose()
	check(loser_visual.sprite.animation == &"lose", "lose animation is wired")

	print("CHARACTER_ANIMATION_RESULT: %d passed | %d failed" % [checks_run - failures.size(), failures.size()])
	get_tree().quit(0 if failures.is_empty() else 1)
