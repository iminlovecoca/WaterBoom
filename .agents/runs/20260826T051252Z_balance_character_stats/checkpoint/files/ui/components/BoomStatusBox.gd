class_name BoomStatusBox
extends Control

@onready var character_name: Label = get_node_or_null('CharacterName')
@onready var stat_ui_host: Control = get_node_or_null('StatContainer')

func set_character(char_def: CharacterDefinition) -> void:
	if char_def == null: return
	if character_name != null:
		character_name.text = char_def.display_name.to_upper()
	if stat_ui_host != null and stat_ui_host.has_method("update_stats"):
		stat_ui_host.update_stats(
			char_def.display_name,
			char_def.base_water_balloon_capacity,
			char_def.max_water_balloon_capacity,
			char_def.base_water_power,
			char_def.max_water_power,
			char_def.base_speed,
			char_def.max_speed
		)
