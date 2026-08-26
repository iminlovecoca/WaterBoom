extends Node

var failures: Array[String] = []
var checks_run := 0


func _ready() -> void:
	_run.call_deferred()


func _check(condition: bool, code: String, message: String) -> void:
	checks_run += 1
	if condition:
		print("[AGENT UI PASS] ", code, ": ", message)
	else:
		failures.append("%s: %s" % [code, message])
		push_error("[AGENT UI FAIL] %s: %s" % [code, message])


func _task_path() -> String:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--agent-task="):
			return argument.trim_prefix("--agent-task=")
	return ""


func _run() -> void:
	var path := _task_path()
	if path.is_empty() or not FileAccess.file_exists(path):
		_check(false, "task_file", "--agent-task must point to the task JSON")
		_finish()
		return
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	var contract: Dictionary = {}
	if typeof(parsed) == TYPE_DICTIONARY:
		for criterion in parsed.get("acceptance_criteria", []):
			if criterion.get("type", "") == "ui_layout_contract":
				contract = criterion
				break
	if contract.is_empty():
		_check(false, "ui_contract", "task has no ui_layout_contract acceptance criterion")
		_finish()
		return
	var scene_path := String(contract.get("scene", ""))
	_check(ResourceLoader.exists(scene_path), "scene", "%s exists" % scene_path)
	for asset_path in contract.get("required_assets", []):
		_check(ResourceLoader.exists(String(asset_path)), "asset", "%s exists" % asset_path)
	if not ResourceLoader.exists(scene_path):
		_finish()
		return

	for size_value in contract.get("viewports", [[960, 720]]):
		var viewport := SubViewport.new()
		viewport.size = Vector2i(int(size_value[0]), int(size_value[1]))
		viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		add_child(viewport)
		var root = load(scene_path).instantiate()
		viewport.add_child(root)
		await get_tree().process_frame
		await get_tree().process_frame
		var viewport_rect := Rect2(Vector2.ZERO, Vector2(viewport.size))
		for node_rule in contract.get("nodes", []):
			var node := root.get_node_or_null(String(node_rule.get("path", ""))) as Control
			var node_code := "node_%s_%dx%d" % [String(node_rule.get("path", "missing")).replace("/", "_"), viewport.size.x, viewport.size.y]
			_check(node != null, node_code, "required Control exists")
			if node == null:
				continue
			var rect := node.get_global_rect()
			if node_rule.get("inside_viewport", true):
				_check(viewport_rect.encloses(rect), node_code + "_overflow", "Control stays inside viewport")
			_check(rect.size.x >= float(node_rule.get("min_width", 0.0)), node_code + "_width", "width %.1f >= %.1f" % [rect.size.x, float(node_rule.get("min_width", 0.0))])
			_check(rect.size.y >= float(node_rule.get("min_height", 0.0)), node_code + "_height", "height %.1f >= %.1f" % [rect.size.y, float(node_rule.get("min_height", 0.0))])
			if node_rule.has("bounds"):
				var bounds: Dictionary = node_rule["bounds"]
				var bounds_ok := rect.position.x >= float(bounds.get("min_x", -INF)) and rect.position.x <= float(bounds.get("max_x", INF)) and rect.position.y >= float(bounds.get("min_y", -INF)) and rect.position.y <= float(bounds.get("max_y", INF)) and rect.end.x >= float(bounds.get("min_right", -INF)) and rect.end.x <= float(bounds.get("max_right", INF)) and rect.end.y >= float(bounds.get("min_bottom", -INF)) and rect.end.y <= float(bounds.get("max_bottom", INF))
				_check(bounds_ok, node_code + "_bounds", "Control matches target bounds")
		for relation in contract.get("relations", []):
			var first := root.get_node_or_null(String(relation.get("first", ""))) as Control
			var second := root.get_node_or_null(String(relation.get("second", ""))) as Control
			var relation_code := "relation_%s_%dx%d" % [String(relation.get("id", "unnamed")), viewport.size.x, viewport.size.y]
			if first == null or second == null:
				_check(false, relation_code, "both relation Controls must exist")
				continue
			var first_rect := first.get_global_rect()
			var second_rect := second.get_global_rect()
			var relation_type := String(relation.get("relation", "no_overlap"))
			if relation_type == "no_overlap":
				_check(not first_rect.intersects(second_rect), relation_code, "Controls do not overlap")
			elif relation_type == "vertical_gap":
				var gap := second_rect.position.y - first_rect.end.y
				_check(gap >= float(relation.get("min", 0.0)) and gap <= float(relation.get("max", INF)), relation_code, "vertical gap %.1f is in range" % gap)
			elif relation_type == "horizontal_gap":
				var gap := second_rect.position.x - first_rect.end.x
				_check(gap >= float(relation.get("min", 0.0)) and gap <= float(relation.get("max", INF)), relation_code, "horizontal gap %.1f is in range" % gap)
		root.queue_free()
		viewport.queue_free()
		await get_tree().process_frame
	_finish()


func _finish() -> void:
	var report := {"ok": failures.is_empty(), "checks": checks_run, "failures": failures}
	print("AGENT_QA_JSON:", JSON.stringify(report))
	get_tree().quit(0 if failures.is_empty() else 1)
