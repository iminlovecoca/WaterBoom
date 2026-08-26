extends Node

# Intentional visual QA artifact for the authored Planning Plaza blueprint.
func _ready() -> void:
	GameSession.configure_solo(1, GameConstants.BotDifficulty.NORMAL, &"training_plaza")
	var arena := load("res://scenes/match/MatchArena.tscn").instantiate() as MatchManager
	add_child(arena)
	arena.countdown_timer = 0.05
	await get_tree().create_timer(1.2).timeout
	for player in arena.players.values():
		player.hide()
	arena.get_node("WaterBalloonManager").hide()
	arena.get_node("ItemManager").hide()
	await get_tree().process_frame
	var image := get_viewport().get_texture().get_image()
	image.save_png("res://tests/artifacts/planning_plaza_runtime.png")
	print("PLANNING_PLAZA_CAPTURE_SAVED")
	get_tree().quit()
