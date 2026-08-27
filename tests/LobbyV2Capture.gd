extends Node

const OUTPUT := "res://tests/artifacts/lobby_v2_layered_cosmetics.png"

func _ready() -> void:
	GameSession.player_nickname = "admin"
	GameSession.play_mode = &"multiplayer"
	GameSession.owned_cosmetics = [
		&"flag_default_water", &"frame_default_aqua", &"background_default_aqua",
		&"head_flower_wreath", &"frame_ocean_coral", &"background_ocean_coral",
	]
	GameSession.equipped_cosmetics = {
		"head_accessory": "head_flower_wreath",
		"flag": "flag_default_water",
		"player_frame": "frame_ocean_coral",
		"player_background": "background_ocean_coral",
	}
	RoomManager.current_room_id = "ROOM_82910427"
	RoomManager.active_rooms = {
		"ROOM_82910427": {
			"id": "ROOM_82910427",
			"name": "Phòng của admin",
			"map": "training_plaza",
			"mode": "solo",
			"bots": 1,
			"diff": 1,
			"host": 1,
			"players": [1],
			"max_players": 8,
			"state": "WAITING",
		}
	}
	RoomManager.room_players = {
		1: {
			"name": "admin",
			"char_id": "cocoa_otter",
			"color_idx": 0,
			"is_ready": true,
			"balloon_skin": "skin_066",
			"equipment": GameSession.equipped_cosmetics.duplicate(true),
		},
	}
	var boot := load("res://scenes/boot/Boot.tscn").instantiate() as BootManager
	add_child(boot)
	await get_tree().process_frame
	await get_tree().process_frame
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://tests/artifacts"))
	var error := _capture(OUTPUT)
	boot._open_feature_panel(boot.shop_panel)
	await get_tree().process_frame
	error = maxi(error, _capture("res://tests/artifacts/shop_equipment_categories.png"))
	var shop := boot.shop_panel as ShopView
	shop._on_category_selected("head_accessory")
	await get_tree().process_frame
	error = maxi(error, _capture("res://tests/artifacts/shop_head_accessory_category.png"))
	boot.shop_panel.visible = false
	boot._open_feature_panel(boot.inventory_panel)
	await get_tree().process_frame
	error = maxi(error, _capture("res://tests/artifacts/inventory_equipment_categories.png"))
	var inventory := boot.inventory_panel as InventoryView
	inventory._on_category_selected("head_accessory")
	await get_tree().process_frame
	error = maxi(error, _capture("res://tests/artifacts/inventory_head_accessory_category.png"))
	print("LOBBY_V2_CAPTURE error=", error, " path=", ProjectSettings.globalize_path(OUTPUT))
	get_tree().quit(0 if error == OK else 1)

func _capture(path: String) -> int:
	RenderingServer.force_draw()
	var image := get_viewport().get_texture().get_image()
	if image == null or image.is_empty():
		push_error("LOBBY_V2_CAPTURE has no framebuffer for %s" % path)
		return ERR_CANT_CREATE
	return image.save_png(path)
