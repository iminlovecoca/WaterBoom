extends Node

const OUTPUT_PATH := "res://tests/artifacts/performance_baseline.json"
const WARMUP_FRAMES := 30
const SAMPLE_FRAMES := 180


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	var report := {
		"captured_at_unix": Time.get_unix_time_from_system(),
		"engine": Engine.get_version_info().get("string", "unknown"),
		"renderer": RenderingServer.get_video_adapter_name(),
		"logical_viewport": [get_viewport().get_visible_rect().size.x, get_viewport().get_visible_rect().size.y],
		"samples": [],
	}

	var login_load_start := Time.get_ticks_usec()
	var login := load("res://scenes/login/Login.tscn").instantiate() as LoginScreen
	add_child(login)
	await get_tree().process_frame
	await get_tree().process_frame
	var login_load_ms := (Time.get_ticks_usec() - login_load_start) / 1000.0
	var login_sample := await _sample_frames("login", login_load_ms)
	report["samples"].append(login_sample)
	login.queue_free()
	await get_tree().process_frame

	GameSession.configure_solo(1, GameConstants.BotDifficulty.NORMAL, &"training_plaza")
	var match_load_start := Time.get_ticks_usec()
	var arena := load("res://scenes/match/MatchArena.tscn").instantiate() as MatchManager
	add_child(arena)
	await get_tree().process_frame
	await get_tree().process_frame
	var match_load_ms := (Time.get_ticks_usec() - match_load_start) / 1000.0
	var match_sample := await _sample_frames("match_training_plaza", match_load_ms)
	report["samples"].append(match_sample)
	arena.queue_free()
	await get_tree().process_frame

	var file := FileAccess.open(OUTPUT_PATH, FileAccess.WRITE)
	if file == null:
		push_error("Unable to write performance baseline: %s" % FileAccess.get_open_error())
		get_tree().quit(1)
		return
	file.store_string(JSON.stringify(report, "\t"))
	file.close()
	print("PERFORMANCE_BASELINE: ", JSON.stringify(report))
	get_tree().quit(0)


func _sample_frames(label: String, load_ms: float) -> Dictionary:
	for _frame in WARMUP_FRAMES:
		await get_tree().process_frame

	var frame_times: Array[float] = []
	var previous := Time.get_ticks_usec()
	for _frame in SAMPLE_FRAMES:
		await get_tree().process_frame
		var now := Time.get_ticks_usec()
		frame_times.append((now - previous) / 1000.0)
		previous = now

	var sorted := frame_times.duplicate()
	sorted.sort()
	var sum := 0.0
	for value in frame_times:
		sum += value
	var average_ms := sum / maxf(float(frame_times.size()), 1.0)
	var p95_index := clampi(int(ceil(sorted.size() * 0.95)) - 1, 0, sorted.size() - 1)
	return {
		"name": label,
		"load_ms": snappedf(load_ms, 0.01),
		"frame_count": frame_times.size(),
		"average_frame_ms": snappedf(average_ms, 0.01),
		"p95_frame_ms": snappedf(sorted[p95_index], 0.01),
		"max_frame_ms": snappedf(sorted[-1], 0.01),
		"estimated_fps": snappedf(1000.0 / maxf(average_ms, 0.001), 0.1),
	}
