extends Node

## Regression test for the six newer character silhouettes that were reported
## as losing feet or side pixels in lobby/room cards.  Every surface must use
## the complete 112x112 V13 canvas and a shared scale/anchor envelope.

var failures: Array[String] = []
var checks := 0

func _ready() -> void:
	_run.call_deferred()

func _check(condition: bool, label: String) -> void:
	checks += 1
	if condition:
		print("[PRESENTATION PASS] ", label)
	else:
		failures.append(label)
		print("[PRESENTATION FAIL] ", label)

func _run() -> void:
	var slot_scene := preload("res://ui/components/BoomRoomSlot.tscn")
	var active_characters := ActiveCharacterRoster.definitions()
	_check(active_characters.size() >= 2, "active roster has at least two characters")
	for character in active_characters:
		var frame := CharacterPresentation.idle_texture(character)
		_check(character != null, "%s definition loads" % character.id)
		_check(frame != null and frame.get_size() == CharacterPresentation.RUNTIME_CANVAS, "%s uses complete 112x112 idle frame" % character.id)
		var atlas := CharacterPresentation.full_frame_atlas(frame)
		_check(atlas != null and atlas.region.size == CharacterPresentation.RUNTIME_CANVAS, "%s keeps the complete frame region" % character.id)

		var slot: BoomRoomSlot = slot_scene.instantiate()
		add_child(slot)
		await get_tree().process_frame
		slot.set_character(character.sprite_frames, character)
		var portrait := slot.get_node("CardPanel/Portrait") as AnimatedSprite2D
		var half_size := CharacterPresentation.RUNTIME_CANVAS * CharacterPresentation.slot_scale_vector_for(character) * 0.5
		var rect := Rect2(portrait.position - half_size, half_size * 2.0)
		_check(rect.position.x >= 0.0 and rect.end.x <= 96.0 and rect.position.y >= 0.0 and rect.end.y <= 94.0, "%s room card silhouette stays inside card" % character.id)
		slot.queue_free()

	var card := PlayerCardPreview.new()
	add_child(card)
	await get_tree().process_frame
	card.configure(active_characters[0] as CharacterDefinition, {})
	_check(card.portrait != null, "player card preview owns a shared anchored portrait")
	var card_half := CharacterPresentation.RUNTIME_CANVAS * CharacterPresentation.card_scale_vector_for(active_characters[0]) * 0.5
	var card_rect := Rect2(card.portrait.position - card_half, card_half * 2.0)
	_check(card_rect.position.x >= 0.0 and card_rect.end.x <= 144.0 and card_rect.position.y >= 0.0 and card_rect.end.y <= 100.0, "large player card silhouette stays inside rounded card")
	var bunny: CharacterDefinition = null
	for character in active_characters:
		if StringName(character.id) == &"cloud_bunny":
			bunny = character
			break
	_check(bunny != null and CharacterPresentation.content_scale(bunny) > 1.0, "white bunny receives the shared width correction")

	print("CHARACTER_PRESENTATION_RESULT: %d passed | %d failed" % [checks - failures.size(), failures.size()])
	get_tree().quit(0 if failures.is_empty() else 1)
