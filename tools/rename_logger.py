import os
import glob

base_dir = r'c:\Users\khang\Documents\Build\Boom'
logger_path = os.path.join(base_dir, 'scripts', 'core', 'Logger.gd')
new_logger_path = os.path.join(base_dir, 'scripts', 'core', 'GameLogger.gd')

logger_code = """class_name GameLogger
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
"""

with open(new_logger_path, 'w', encoding='utf-8') as f:
    f.write(logger_code)

if os.path.exists(logger_path):
    os.remove(logger_path)

# Update references in all .gd files
for root, _, files in os.walk(os.path.join(base_dir, 'scripts')):
    for file in files:
        if file.endswith('.gd'):
            fp = os.path.join(root, file)
            with open(fp, 'r', encoding='utf-8') as f:
                content = f.read()
            if 'Logger.' in content:
                content = content.replace('Logger.', 'GameLogger.')
                with open(fp, 'w', encoding='utf-8') as f:
                    f.write(content)
                print(f"Updated references in: {file}")

print("Logger successfully renamed to GameLogger.")
