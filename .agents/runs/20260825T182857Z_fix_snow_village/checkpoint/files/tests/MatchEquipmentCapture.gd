extends Node

func _ready() -> void:
	GameSession.player_nickname = "admin"
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
	GameSession.configure_solo(1, GameConstants.BotDifficulty.NORMAL, &"training_plaza", &"cocoa_otter")
	var arena := load("res://scenes/match/MatchArena.tscn").instantiate() as MatchManager
	add_child(arena)
	await get_tree().process_frame
	await get_tree().process_frame
	RenderingServer.force_draw()
	var image := get_viewport().get_texture().get_image()
	var path := "res://tests/artifacts/match_sidebar_layered_cosmetics.png"
	var error := image.save_png(path) if image != null and not image.is_empty() else ERR_CANT_CREATE
	print("MATCH_EQUIPMENT_CAPTURE error=", error, " path=", ProjectSettings.globalize_path(path))
	get_tree().quit(0 if error == OK else 1)
