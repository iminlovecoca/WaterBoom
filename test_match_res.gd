extends Control

class MockPlayer:
	var player_id: int
	var display_name: String
	var is_local: bool = false
	var team_id: int = 0

class MockMatchManager:
	var players: Dictionary = {}
	func get_local_player() -> MockPlayer:
		return players.get(1, null)

func _ready() -> void:
	# Add background mockup of game arena (grass/blocks/trees)
	var bg = ColorRect.new()
	bg.anchors_preset = PRESET_FULL_RECT
	bg.color = Color("#2d882d") # Green arena grass
	add_child(bg)
	
	# Add mock arena blocks/trees
	for x in range(8):
		for y in range(6):
			var block = ColorRect.new()
			block.position = Vector2(80 + x * 90, 60 + y * 70)
			block.size = Vector2(40, 40)
			block.color = Color("#a08060") if (x+y)%2==0 else Color("#557733")
			add_child(block)
	
	var hud: MatchHUD = preload("res://scenes/ui/MatchHUD.tscn").instantiate()
	add_child(hud)
	
	var mm = MockMatchManager.new()
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
	
	hud.match_manager = mm as Variant
	hud._populate_result_rows(1, false)
	hud.result_panel.visible = true
	
	await get_tree().process_frame
	await get_tree().process_frame
	
	var img = get_viewport().get_texture().get_image()
	img.save_png("C:/Users/khang/.gemini/antigravity/brain/8d5450db-5a47-4a4a-af37-9aad2b7203db/match_result_test_render.png")
	print("SAVED match_result_test_render.png")
	get_tree().quit(0)
