extends Node

func _init() -> void:
	_run.call_deferred()

func _run() -> void:
	var slot := preload("res://ui/components/BoomRoomSlot.tscn").instantiate()
	add_child(slot)
	await get_tree().process_frame
	var errors: Array[String] = []
	var card := slot.get_node_or_null("CardPanel") as NinePatchRect
	var portrait := slot.get_node_or_null("CardPanel/Portrait") as AnimatedSprite2D
	var head := slot.get_node_or_null("CardPanel/HeadView") as TextureRect
	var flag := slot.get_node_or_null("CardPanel/FlagView") as TextureRect
	if card == null or card.clip_contents:
		errors.append("CardPanel must not clip the complete runtime canvas")
	if portrait == null or portrait.z_index < 3:
		errors.append("Portrait must be above card/frame layers")
	if head == null or head.z_index < 4:
		errors.append("Head VFX must be above portrait")
	if flag == null or flag.z_index < 4:
		errors.append("Flag must be above portrait")
	var report := {"ok": errors.is_empty(), "errors": errors, "card_clip_contents": card.clip_contents if card != null else null, "portrait_z": portrait.z_index if portrait != null else null}
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://tests/artifacts"))
	var file := FileAccess.open("res://tests/artifacts/room_slot_layer_smoke.json", FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(report, "  "))
		file.close()
	if errors.is_empty():
		print("ROOM_SLOT_LAYER_RESULT: pass")
		get_tree().quit(0)
	else:
		push_error("ROOM_SLOT_LAYER_RESULT: " + "; ".join(errors))
		get_tree().quit(1)
