extends Node2D

func _ready() -> void:
	# Add nice background of game arena
	var arena = ColorRect.new()
	arena.size = Vector2(1024, 768)
	arena.color = Color("#48a038") # Grass
	add_child(arena)
	
	# Add mock arena tiles / blocks
	for i in range(12):
		for j in range(9):
			if (i + j) % 3 == 0:
				var block = ColorRect.new()
				block.position = Vector2(40 + i * 80, 40 + j * 70)
				block.size = Vector2(50, 50)
				block.color = Color("#8c6b4e")
				add_child(block)
			elif (i + j) % 3 == 1:
				var tree = ColorRect.new()
				tree.position = Vector2(40 + i * 80, 40 + j * 70)
				tree.size = Vector2(50, 50)
				tree.color = Color("#2d6e24")
				add_child(tree)

	var hud = preload("res://scenes/ui/MatchHUD.tscn").instantiate()
	add_child(hud)
	
	# Mock players
	var p1 = Node.new()
	p1.set_script(preload("res://scripts/player/PlayerController.gd"))
	p1.player_id = 1
	p1.display_name = "phucthuan51"
	p1.is_local = true

	var p2 = Node.new()
	p2.set_script(preload("res://scripts/player/PlayerController.gd"))
	p2.player_id = 2
	p2.display_name = "b0b051"
	p2.is_local = false

	var p3 = Node.new()
	p3.set_script(preload("res://scripts/player/PlayerController.gd"))
	p3.player_id = 3
	p3.display_name = "ngdeptaydo"
	p3.is_local = false

	var p4 = Node.new()
	p4.set_script(preload("res://scripts/player/PlayerController.gd"))
	p4.player_id = 4
	p4.display_name = "prince1511"
	p4.is_local = false

	# Mock MatchManager
	var mm_node = Node2D.new()
	mm_node.set_script(preload("res://scripts/match/MatchManager.gd"))
	mm_node.players = { 1: p1, 2: p2, 3: p3, 4: p4 }
	hud.match_manager = mm_node
	
	hud._populate_result_rows(1, false)
	hud.result_panel.visible = true
	
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	
	var img = get_viewport().get_texture().get_image()
	img.save_png("C:/Users/khang/.gemini/antigravity/brain/8d5450db-5a47-4a4a-af37-9aad2b7203db/match_result_perfect.png")
	print("SAVED match_result_perfect.png")
	get_tree().quit(0)
