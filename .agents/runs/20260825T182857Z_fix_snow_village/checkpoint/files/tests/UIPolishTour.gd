extends Node


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	var login := load("res://scenes/login/Login.tscn").instantiate() as LoginScreen
	add_child(login)
	await get_tree().create_timer(3.0).timeout
	login.queue_free()
	await get_tree().process_frame

	GameSession.player_nickname = "admin"
	GameSession.play_mode = &"multiplayer"
	GameSession.owned_cosmetics = [
		&"flag_default_water", &"background_default_aqua", &"balloon_default",
	]
	GameSession.equipped_cosmetics = {
		"head_accessory": "head_flower_wreath",
		"flag": "flag_default_water",
		"player_frame": "frame_ocean_coral",
		"player_background": "background_default_aqua",
	}
	RoomManager.current_room_id = "ROOM_UI_V2"
	RoomManager.active_rooms = {
		"ROOM_UI_V2": {
			"id": "ROOM_UI_V2", "name": "Phòng của admin", "map": "training_plaza",
			"mode": "solo", "bots": 1, "diff": 1, "host": 1, "players": [1],
			"max_players": 8, "state": "WAITING",
		}
	}
	RoomManager.room_players = {
		1: {
			"name": "admin", "char_id": "cocoa_otter", "color_idx": 0,
			"is_ready": true, "balloon_skin": "skin_066",
			"equipment": GameSession.equipped_cosmetics.duplicate(true),
		},
	}
	var boot := load("res://scenes/boot/Boot.tscn").instantiate() as BootManager
	add_child(boot)
	await get_tree().create_timer(3.5).timeout
	boot._open_feature_panel(boot.shop_panel)
	await get_tree().create_timer(3.5).timeout
	boot.shop_panel.visible = false
	boot._open_feature_panel(boot.inventory_panel)
	await get_tree().create_timer(3.5).timeout
	boot.queue_free()
	await get_tree().process_frame

	GameSession.configure_solo(1, GameConstants.BotDifficulty.NORMAL, &"training_plaza", &"cocoa_otter")
	var arena := load("res://scenes/match/MatchArena.tscn").instantiate() as MatchManager
	add_child(arena)
	await get_tree().create_timer(4.5).timeout
	get_tree().quit(0)
