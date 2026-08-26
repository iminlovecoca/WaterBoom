class_name GameLogger
extends RefCounted

static func _get_timestamp() -> String:
	var time = Time.get_time_dict_from_system()
	return "%02d:%02d:%02d" % [time.hour, time.minute, time.second]

static func debug(tag: String, message: String) -> void:
	print("[%s][DEBUG][%s] %s" % [_get_timestamp(), tag, message])

static func info(tag: String, message: String) -> void:
	print("[%s][INFO][%s] %s" % [_get_timestamp(), tag, message])

static func warn(tag: String, message: String) -> void:
	push_warning("[%s][WARN][%s] %s" % [_get_timestamp(), tag, message])

static func error(tag: String, message: String) -> void:
	push_error("[%s][ERROR][%s] %s" % [_get_timestamp(), tag, message])
