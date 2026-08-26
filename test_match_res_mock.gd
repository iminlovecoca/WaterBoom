extends Control

class MockPlayer:
	var player_id: int
	var display_name: String
	var is_local: bool = false
	var team_id: int = 0
	var equipment_snapshot: Dictionary = {}

class MockMatchMgr:
	var players: Dictionary = {}
	var current_state: int = 0
	var time_left_seconds: float = 120.0
	var boss_encounter = null
	func get_local_player():
		return players.get(1, null)

func _ready() -> void:
	custom_minimum_size = Vector2(800, 600)
	size = Vector2(800, 600)
	
	# Background arena grass & trees (clearly showing map is visible underneath!)
	var arena = ColorRect.new()
	arena.size = Vector2(800, 600)
	arena.color = Color("#3e8e2b")
	add_child(arena)
	
	for i in range(10):
		for j in range(8):
			if (i + j) % 2 == 0:
				var block = ColorRect.new()
				block.position = Vector2(30 + i * 75, 30 + j * 70)
				block.size = Vector2(48, 48)
				block.color = Color("#8c6e4e")
				add_child(block)
			elif (i + j) % 3 == 0:
				var tree = ColorRect.new()
				tree.position = Vector2(30 + i * 75, 30 + j * 70)
				tree.size = Vector2(48, 48)
				tree.color = Color("#1e5a1b")
				add_child(tree)

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
	img.save_png("C:/Users/khang/.gemini/antigravity/brain/8d5450db-5a47-4a4a-af37-9aad2b7203db/match_result_test_shot.png")
	print("SAVED match_result_test_shot.png")
	get_tree().quit(0)
