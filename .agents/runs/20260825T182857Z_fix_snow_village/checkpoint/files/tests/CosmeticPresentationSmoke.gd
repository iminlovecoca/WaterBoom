extends Node


func _ready() -> void:
	var visible := CosmeticRegistry.visible_definitions()
	var all := CosmeticRegistry.all_definitions()
	var has_flag := false
	var has_background := false
	var has_retired_data := false
	for definition in visible:
		if definition.category == CosmeticDefinition.HEAD_ACCESSORY or definition.category == CosmeticDefinition.PLAYER_FRAME:
			push_error("COSMETIC_PRESENTATION FAIL retired category remains visible: %s" % definition.id)
			get_tree().quit(1)
			return
		has_flag = has_flag or definition.category == CosmeticDefinition.FLAG
		has_background = has_background or definition.category == CosmeticDefinition.PLAYER_BACKGROUND
	for definition in all:
		has_retired_data = has_retired_data or definition.category == CosmeticDefinition.HEAD_ACCESSORY or definition.category == CosmeticDefinition.PLAYER_FRAME
	if not has_flag or not has_background or not has_retired_data:
		push_error("COSMETIC_PRESENTATION FAIL enabled presentation or compatibility data is missing")
		get_tree().quit(1)
		return
	print("COSMETIC_PRESENTATION PASS visible=%d compatible_total=%d" % [visible.size(), all.size()])
	get_tree().quit(0)
