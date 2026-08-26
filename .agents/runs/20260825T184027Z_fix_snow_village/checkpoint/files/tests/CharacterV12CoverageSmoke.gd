extends SceneTree

const Coverage = preload("res://scripts/characters/CharacterV12Coverage.gd")

func _init() -> void:
	_run.call_deferred()

func _run() -> void:
	var report := Coverage.build_report()
	var artifact := FileAccess.open("res://tests/artifacts/character_v12_coverage.json", FileAccess.WRITE)
	if artifact != null:
		artifact.store_string(JSON.stringify(report, "  "))
		artifact.close()
	var expected := int(report.get("expected_character_count", 0))
	var complete := int(report.get("complete_character_count", 0))
	if expected != 9:
		push_error("CHARACTER_V12_COVERAGE FAIL: expected 9 characters, got %d" % expected)
		quit(1)
		return
	print("CHARACTER_V12_COVERAGE PASS complete=%d/%d" % [complete, expected])
	for character in report.get("characters", []):
		print("  ", character.get("id"), " ", character.get("total_frames"), "/", character.get("expected_frames"))
	quit(0)
