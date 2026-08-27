extends Node


func _ready() -> void:
	var visible := CosmeticRegistry.visible_definitions()
	var all := CosmeticRegistry.all_definitions()
	var has_flag := false
	var has_background := false
	var has_frame := false
	var head_count := 0
	var frame_count := 0
	var head_profiles := {}
	for definition in visible:
		if definition.category == CosmeticDefinition.PLAYER_FRAME:
			frame_count += 1
			has_frame = has_frame or definition.lobby_asset != null
			if definition.lobby_asset != null and AccessoryPresentation.texture_for(definition, AccessoryPresentation.CONTEXT_CARD) != null:
				pass
		if definition.category == CosmeticDefinition.HEAD_ACCESSORY:
			head_count += 1
			head_profiles[str(definition.id)] = str(definition.placement_profile)
			if not AccessoryPresentation.VALID_PROFILES.has(StringName(definition.placement_profile)):
				push_error("COSMETIC_PRESENTATION FAIL invalid head placement profile: %s" % definition.id)
				get_tree().quit(1)
				return
			for context in [AccessoryPresentation.CONTEXT_CARD, AccessoryPresentation.CONTEXT_ROOM, AccessoryPresentation.CONTEXT_MATCH_LIST, AccessoryPresentation.CONTEXT_WORLD]:
				if AccessoryPresentation.texture_for(definition, context) == null:
					push_error("COSMETIC_PRESENTATION FAIL missing %s asset: %s" % [context, definition.id])
					get_tree().quit(1)
					return
			var card_rect := AccessoryPresentation.control_rect(definition, AccessoryPresentation.CONTEXT_CARD)
			if card_rect.position.x < 0.0 or card_rect.position.y < -8.0 or card_rect.end.x > 144.0 or card_rect.end.y > 100.0:
				push_error("COSMETIC_PRESENTATION FAIL card accessory clips authored bounds: %s %s" % [definition.id, card_rect])
				get_tree().quit(1)
				return
			var match_rect := AccessoryPresentation.control_rect(definition, AccessoryPresentation.CONTEXT_MATCH_LIST)
			if match_rect.position.x < 0.0 or match_rect.position.y < 0.0 or match_rect.end.x > 58.0 or match_rect.end.y > 58.0:
				push_error("COSMETIC_PRESENTATION FAIL match accessory clips sidebar slot: %s %s" % [definition.id, match_rect])
				get_tree().quit(1)
				return
			var world_scale := AccessoryPresentation.world_sprite_scale(definition, AccessoryPresentation.texture_for(definition, AccessoryPresentation.CONTEXT_WORLD))
			if world_scale.x <= 0.0 or not is_equal_approx(world_scale.x, world_scale.y):
				push_error("COSMETIC_PRESENTATION FAIL invalid uniform world scale: %s %s" % [definition.id, world_scale])
				get_tree().quit(1)
				return
		has_flag = has_flag or definition.category == CosmeticDefinition.FLAG
		has_background = has_background or definition.category == CosmeticDefinition.PLAYER_BACKGROUND
	for definition in all:
		# All definitions remain discoverable for save compatibility, including
		# frame data that older accounts may not have equipped yet.
		if definition.category == CosmeticDefinition.PLAYER_FRAME:
			has_frame = has_frame or definition.lobby_asset != null
	var equipped_head := CosmeticRegistry.sanitize_equipment({"head_accessory": "head_halo_aqua"})
	var unequipped_head := CosmeticRegistry.sanitize_equipment({"head_accessory": ""})
	if str(equipped_head.get("head_accessory", "")) != "head_halo_aqua" or not str(unequipped_head.get("head_accessory", "")).is_empty():
		push_error("COSMETIC_PRESENTATION FAIL equip/unequip sanitation contract is broken")
		get_tree().quit(1)
		return
	if head_profiles.get("head_sunglasses_red", "") != "face":
		push_error("COSMETIC_PRESENTATION FAIL red sunglasses profile is not face")
		get_tree().quit(1)
		return
	if head_profiles.get("head_cowboy_hat", "") != "hat" or head_profiles.get("head_conical_hat_vietnam", "") != "hat":
		push_error("COSMETIC_PRESENTATION FAIL hat accessory profiles are not hat")
		get_tree().quit(1)
		return
	if not has_flag or not has_background or not has_frame or frame_count < 5 or head_count < 9:
		push_error("COSMETIC_PRESENTATION FAIL enabled presentation or compatibility data is missing")
		get_tree().quit(1)
		return
	print("COSMETIC_PRESENTATION PASS visible=%d compatible_total=%d" % [visible.size(), all.size()])
	get_tree().quit(0)
