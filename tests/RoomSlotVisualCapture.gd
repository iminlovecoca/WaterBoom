extends Node

var boot: Control

func _ready() -> void:
	boot = preload("res://scenes/boot/Boot.tscn").instantiate()
	add_child(boot)
	await get_tree().process_frame
	await get_tree().process_frame
	# Render all authored characters through the same dynamic room-card path.
	if boot is BootManager:
		boot.bot_count = 5
		boot._refresh_room_slots()
	await get_tree().process_frame
	var viewport_texture := get_viewport().get_texture()
	if viewport_texture == null:
		# The dummy headless renderer has no readable screen texture. Keep the
		# capture test green there; the Windows/OpenGL run below is the visual gate.
		print("ROOM_SLOT_VISUAL_CAPTURE: skipped (headless renderer)")
		get_tree().quit()
		return
	var image := viewport_texture.get_image()
	image.save_png("res://tests/artifacts/room_slot_visual_capture.png")
	print("ROOM_SLOT_VISUAL_CAPTURE: saved")
	get_tree().quit()
