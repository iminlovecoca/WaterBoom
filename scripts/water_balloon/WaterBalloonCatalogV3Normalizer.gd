class_name WaterBalloonCatalogV3Normalizer
extends RefCounted

## Non-mutating validator for the current 16-skin catalog.
## It never writes JSON or SQL; callers can use the preview result to gate a
## later migration once purchase/equip authority and art are ready.

const DEFAULT_SOURCE_PATH := "res://assets/water_balloons/water_balloon_catalog.json"
const ACTIVE_SKIN_COUNT := 16
const EXPECTED_ID_MIN := 66
const EXPECTED_ID_MAX := 81
const ALLOWED_STATUS := [&"active", &"hidden_legacy"]

static func load_source(path: String = DEFAULT_SOURCE_PATH) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var json := JSON.new()
	var error := json.parse(file.get_as_text())
	file.close()
	if error != OK or not (json.data is Dictionary):
		return {}
	return json.data as Dictionary

static func normalize(source: Dictionary) -> Dictionary:
	var result := {
		"schema_version": 3,
		"source_version": int(source.get("version", 0)),
		"active_skin_count": 0,
		"migration_pending": true,
		"skins": []
	}
	var normalized_skins: Array[Dictionary] = []
	for raw in source.get("skins", []):
		if not (raw is Dictionary):
			continue
		var skin: Dictionary = (raw as Dictionary).duplicate(true)
		var id := str(skin.get("id", ""))
		skin["status"] = "active"
		skin.erase("alias_to")
		normalized_skins.append(skin)
	result["skins"] = normalized_skins
	result["active_skin_count"] = _count_status(normalized_skins, "active")
	return result

static func validate(v3: Dictionary, require_assets: bool = false, asset_root: String = "res://assets/water_balloons/skins") -> Dictionary:
	var errors: Array[String] = []
	var warnings: Array[String] = []
	var skins: Array = v3.get("skins", [])
	if int(v3.get("schema_version", 0)) != 3:
		errors.append("schema_version must be 3")
	var by_id: Dictionary = {}
	for raw in skins:
		if not (raw is Dictionary):
			errors.append("skins contains a non-object entry")
			continue
		var skin: Dictionary = raw as Dictionary
		var id := str(skin.get("id", ""))
		if id.is_empty():
			errors.append("skin entry is missing id")
			continue
		if by_id.has(id):
			errors.append("duplicate id: %s" % id)
		by_id[id] = skin
		var status := StringName(str(skin.get("status", "")))
		if not ALLOWED_STATUS.has(status):
			errors.append("%s has invalid status '%s'" % [id, status])
		if status == &"active":
			for key in ["name", "rarity", "icon_path", "frames_path"]:
				if not skin.has(key) and key in ["icon_path", "frames_path"]:
					warnings.append("%s needs v3 %s before migration" % [id, key])
			if require_assets:
				var icon_path := str(skin.get("icon_path", "%s/%s/icon.png" % [asset_root, id]))
				var frames_path := str(skin.get("frames_path", "%s/%s/%s_frames.tres" % [asset_root, id, id]))
				if not ResourceLoader.exists(icon_path):
					errors.append("%s missing icon: %s" % [id, icon_path])
				if not ResourceLoader.exists(frames_path):
					errors.append("%s missing frames: %s" % [id, frames_path])
	var expected_ids: Array[String] = []
	for number in range(EXPECTED_ID_MIN, EXPECTED_ID_MAX + 1):
		expected_ids.append("skin_%03d" % number)
	for id in expected_ids:
		if not by_id.has(id):
			errors.append("missing stable id: %s" % id)
	var active_count := _count_status(skins, "active")
	if active_count != ACTIVE_SKIN_COUNT:
		errors.append("expected %d active skins, got %d" % [ACTIVE_SKIN_COUNT, active_count])
	return {
		"ok": errors.is_empty(),
		"errors": errors,
		"warnings": warnings,
		"active_count": active_count,
		"id_count": by_id.size()
	}

static func _count_status(skins: Array, status: String) -> int:
	var count := 0
	for raw in skins:
		if raw is Dictionary and str((raw as Dictionary).get("status", "")) == status:
			count += 1
	return count
