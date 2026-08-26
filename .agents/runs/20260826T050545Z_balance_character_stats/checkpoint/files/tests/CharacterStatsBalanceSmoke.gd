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
			if not directory.current_is_dir() and entry.ends_with(".tres") and not entry.ends_with("_frames.tres"):
				definition_count += 1
				var resource := load("res://resources/characters/" + entry)
				if not resource is CharacterDefinition:
					failures.append("%s is not CharacterDefinition" % entry)
				else:
					var definition := resource as CharacterDefinition
					if definition.base_water_balloon_capacity != 2:
						failures.append("%s starts with %d balloons" % [definition.id, definition.base_water_balloon_capacity])
					if definition.base_water_power < 1 or definition.base_water_power > 6:
						failures.append("%s base power out of range" % definition.id)
					if definition.base_speed < 140.0 or definition.base_speed > 200.0:
						failures.append("%s base speed out of range" % definition.id)
					if definition.max_water_balloon_capacity != 6:
						failures.append("%s max balloons=%d" % [definition.id, definition.max_water_balloon_capacity])
					if definition.max_water_power != 6:
						failures.append("%s max power=%d" % [definition.id, definition.max_water_power])
					if not is_equal_approx(definition.max_speed, 240.0):
						failures.append("%s max speed=%.1f" % [definition.id, definition.max_speed])
			entry = directory.get_next()
		directory.list_dir_end()
	if definition_count != 10:
		failures.append("expected 10 character definitions, got %d" % definition_count)
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
