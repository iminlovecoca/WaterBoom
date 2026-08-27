extends Node

signal equipment_changed(equipment: Dictionary)
signal equip_rejected(message: String)

func current_equipment() -> Dictionary:
	if not has_node("/root/GameSession"):
		return CosmeticRegistry.default_equipment()
	return CosmeticRegistry.sanitize_equipment(GameSession.equipped_cosmetics, GameSession.owned_cosmetics)

func owns(cosmetic_id: StringName) -> bool:
	var definition := CosmeticRegistry.get_definition(cosmetic_id)
	return definition != null and (definition.is_default or GameSession.owned_cosmetics.has(cosmetic_id))

func equip(category: StringName, cosmetic_id: StringName) -> bool:
	if category == CosmeticDefinition.HEAD_ACCESSORY and cosmetic_id == &"":
		return _commit(category, cosmetic_id)
	var definition := CosmeticRegistry.get_definition(cosmetic_id)
	if definition == null or definition.category_id() != category:
		equip_rejected.emit("Vật phẩm không hợp lệ.")
		return false
	if not owns(cosmetic_id):
		equip_rejected.emit("Bạn chưa sở hữu vật phẩm này.")
		return false
	return _commit(category, cosmetic_id)

func unequip(category: StringName) -> bool:
	if category == CosmeticDefinition.HEAD_ACCESSORY:
		return _commit(category, &"")
	var fallback := StringName(str(CosmeticRegistry.DEFAULT_EQUIPMENT.get(str(category), "")))
	return _commit(category, fallback)

func apply_server_equipment(equipment: Dictionary) -> void:
	GameSession.equipped_cosmetics = CosmeticRegistry.sanitize_equipment(equipment, GameSession.owned_cosmetics)
	equipment_changed.emit(GameSession.equipped_cosmetics.duplicate(true))

func _commit(category: StringName, cosmetic_id: StringName) -> bool:
	var next := current_equipment()
	next[str(category)] = str(cosmetic_id)
	GameSession.equipped_cosmetics = CosmeticRegistry.sanitize_equipment(next, GameSession.owned_cosmetics)
	equipment_changed.emit(GameSession.equipped_cosmetics.duplicate(true))
	GameSession.save_profile()
	if has_node("/root/AccountDatabase") and NetworkManager.is_connected_to_server():
		AccountDatabase.rpc_id(1, "request_equip_cosmetic", str(category), str(cosmetic_id))
	# Room equipment is a second channel from the account save.  Only send it
	# while an actual multiplayer peer exists; a local/offline room can still
	# have a stale room id and would otherwise try to RPC peer 1.
	if has_node("/root/RoomManager") and RoomManager.current_room_id != "" and NetworkManager.is_connected_to_server():
		if multiplayer.is_server():
			RoomManager.request_update_equipment(GameSession.equipped_cosmetics)
		elif NetworkManager.is_peer_connected(1):
			RoomManager.rpc_id(1, "request_update_equipment", GameSession.equipped_cosmetics)
	return true
