extends Control

class MockPlayer extends RefCounted:
	var player_id: int = 1
	var display_name: String = "phucthuan51"
	var is_local: bool = false
	var team_id: int = 0
	var equipment_snapshot: Dictionary = {}
	var is_alive: bool = true
	var is_in_bubble: bool = false
	var max_water_balloons: int = 1
	var visual = null

class MockMatchMgr extends RefCounted:
	var players: Dictionary = {}
	var current_state: int = 0
	var time_left_seconds: float = 120.0
	var boss_encounter = null
	var map_definition = null
	func get_local_player():
		return players.get(1, null)

func _ready() -> void:
	custom_minimum_size = Vector2(800, 600)
	size = Vector2(800, 600)
	
	# Background arena grass & stone blocks & trees
	var arena = ColorRect.new()
	arena.size = Vector2(800, 600)
	arena.color = Color("#41982b")
	add_child(arena)
	
	for i in range(10):
		for j in range(8):
			if (i + j) % 2 == 0:
				var stone = ColorRect.new()
				stone.position = Vector2(25 + i * 78, 20 + j * 72)
				stone.size = Vector2(50, 46)
				stone.color = Color("#8d7d6f")
				add_child(stone)
			elif (i * 3 + j) % 4 == 0:
				var log_b = ColorRect.new()
				log_b.position = Vector2(25 + i * 78, 20 + j * 72)
				log_b.size = Vector2(44, 44)
				log_b.color = Color("#b87333")
				add_child(log_b)

	var hud: MatchHUD = preload("res://scenes/ui/MatchHUD.tscn").instantiate()
	
	var mm = MockMatchMgr.new()
	var p1 = MockPlayer.new()
	p1.player_id = 1
	p1.display_name = "phucthuan51"
	p1.is_local = true
	mm.players[1] = p1

	var p2 = MockPlayer.new()
	p2.player_id = 2
	p2.display_name = "b0b051"
	mm.players[2] = p2

	var p3 = MockPlayer.new()
	p3.player_id = 3
	p3.display_name = "ngdeptaydo"
	mm.players[3] = p3

	var p4 = MockPlayer.new()
	p4.player_id = 4
	p4.display_name = "prince1511"
	mm.players[4] = p4

	hud.match_manager = mm
	add_child(hud)
	
	hud._populate_result_rows(1, false)
	hud.result_panel.visible = true
	
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	
	var img = get_viewport().get_texture().get_image()
	img.save_png("C:/Users/khang/.gemini/antigravity/brain/8d5450db-5a47-4a4a-af37-9aad2b7203db/final_match_result_unified.png")
	print("SAVED final_match_result_unified.png")
	get_tree().quit(0)
