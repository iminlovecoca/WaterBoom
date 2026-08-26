extends Node

func _ready() -> void:
	var failures: Array[String] = []
	var directory := DirAccess.open("res://resources/characters")
	var definition_count := 0
	if directory == null:
		failures.append("character resource directory missing")
	else:
		directory.list_dir_begin()
		var entry := directory.get_next()
		while entry != "":
			if not directory.current_is_dir() and entry.ends_with(".tres") and not entry.contains("_frames"):
				definition_count += 1
				var values := _read_definition_values("res://resources/characters/" + entry)
				if values.is_empty():
					failures.append("%s could not be parsed" % entry)
				else:
					if int(values.get("base_water_balloon_capacity", -1)) != 2:
						failures.append("%s starts with %d balloons" % [entry, int(values.get("base_water_balloon_capacity", -1))])
					if int(values.get("base_water_power", -1)) < 1 or int(values.get("base_water_power", -1)) > 6:
						failures.append("%s base power out of range" % entry)
					if float(values.get("base_speed", -1.0)) < 140.0 or float(values.get("base_speed", -1.0)) > 200.0:
						failures.append("%s base speed out of range" % entry)
					if int(values.get("max_water_balloon_capacity", -1)) != 6:
						failures.append("%s max balloons=%d" % [entry, int(values.get("max_water_balloon_capacity", -1))])
					if int(values.get("max_water_power", -1)) != 6:
						failures.append("%s max power=%d" % [entry, int(values.get("max_water_power", -1))])
					if not is_equal_approx(float(values.get("max_speed", -1.0)), 240.0):
						failures.append("%s max speed=%.1f" % [entry, float(values.get("max_speed", -1.0))])
			entry = directory.get_next()
		directory.list_dir_end()
	if definition_count != 11:
		failures.append("expected 11 character definitions, got %d" % definition_count)
	var char_def := CharacterDefinition.new()
	if char_def.base_water_balloon_capacity != 2:
		failures.append("CharacterDefinition default capacity=%d" % char_def.base_water_balloon_capacity)
	if char_def.max_water_balloon_capacity != 6:
		failures.append("CharacterDefinition max capacity=%d" % char_def.max_water_balloon_capacity)
	if char_def.max_water_power != 6:
		failures.append("CharacterDefinition max power=%d" % char_def.max_water_power)
	if not is_equal_approx(char_def.max_speed, 240.0):
		failures.append("CharacterDefinition max speed=%.1f" % char_def.max_speed)
	var match_config := MatchConfig.new()
	if match_config.base_water_balloon_capacity != 2:
		failures.append("MatchConfig default capacity=%d" % match_config.base_water_balloon_capacity)
	if match_config.max_water_balloon_capacity != 6:
		failures.append("MatchConfig max capacity=%d" % match_config.max_water_balloon_capacity)
	if match_config.max_water_power != 6:
		failures.append("MatchConfig max power=%d" % match_config.max_water_power)
	if not is_equal_approx(match_config.max_speed, 240.0):
		failures.append("MatchConfig max speed=%.1f" % match_config.max_speed)
	if GameConstants.DEFAULT_WATER_BALLOON_CAPACITY != 2:
		failures.append("GameConstants default capacity=%d" % GameConstants.DEFAULT_WATER_BALLOON_CAPACITY)
	if GameConstants.MAX_WATER_BALLOON_CAPACITY != 6:
		failures.append("GameConstants max capacity=%d" % GameConstants.MAX_WATER_BALLOON_CAPACITY)
	if GameConstants.MAX_WATER_POWER != 6:
		failures.append("GameConstants max power=%d" % GameConstants.MAX_WATER_POWER)
	if not is_equal_approx(GameConstants.MAX_MOVE_SPEED, 240.0):
		failures.append("GameConstants max speed=%.1f" % GameConstants.MAX_MOVE_SPEED)
	if failures.is_empty():
		print("CHARACTER_STATS_BALANCE_RESULT: 0 failed | definitions=%d | base_balloons=2 | caps=6/6/240" % definition_count)
		get_tree().quit(0)
	else:
		push_error("CHARACTER_STATS_BALANCE_RESULT: %d failed | %s" % [failures.size(), "; ".join(failures)])
		get_tree().quit(1)

func _read_definition_values(path: String) -> Dictionary:
	var values: Dictionary = {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return values
	while not file.eof_reached():
		var line := file.get_line().strip_edges()
		for key in ["base_speed", "base_water_balloon_capacity", "base_water_power", "max_speed", "max_water_balloon_capacity", "max_water_power"]:
			if line.begins_with(key + " ="):
				values[key] = line.get_slice("=", 1).strip_edges().to_float()
	file.close()
	return values
