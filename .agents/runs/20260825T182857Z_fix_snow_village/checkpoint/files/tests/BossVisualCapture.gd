extends Node

const OUTPUT := "res://tests/artifacts"

func _capture(name: String) -> void:
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	image.save_png(ProjectSettings.globalize_path("%s/%s" % [OUTPUT, name]))

func _ready() -> void:
	GameSession.configure_boss(&"training_plaza", &"boom_mascot")
	var menu: Control = load("res://scenes/boot/Boot.tscn").instantiate()
	add_child(menu)
	await get_tree().process_frame
	await _capture("boss_mode_lobby.png")
	menu.queue_free()
	await get_tree().process_frame
	var arena: MatchManager = load("res://scenes/match/MatchArena.tscn").instantiate()
	add_child(arena)
	await get_tree().process_frame
	await get_tree().process_frame
	arena.current_state = GameConstants.MatchState.PLAYING
	arena.boss_encounter.start_round(1)
	await get_tree().create_timer(0.35).timeout
	await _capture("boss_round_1.png")
	for entity in arena.boss_encounter.entities.duplicate():
		if is_instance_valid(entity):
			entity.queue_free()
	arena.boss_encounter.entities.clear()
	arena.boss_encounter.start_round(4)
	await get_tree().create_timer(0.35).timeout
	await _capture("boss_round_4.png")
	var boss := arena.boss_encounter.entities[0]
	boss.take_water_damage(22, 1)
	await get_tree().create_timer(0.25).timeout
	await _capture("boss_phase_2.png")
	get_tree().quit()
