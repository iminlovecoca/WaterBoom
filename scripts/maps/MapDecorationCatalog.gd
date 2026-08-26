class_name MapDecorationCatalog
extends RefCounted

static func entries_for_map(map_id: StringName) -> Array[Dictionary]:
	var known_ids: Array[StringName] = [
		&"training_plaza",
		&"aqua_park",
		&"pirate_harbor",
		&"snow_village",
		&"lego_city",
		&"egypt_temple",
		&"boss_pirate_ship"
	]

	var resolved_id: StringName = map_id if map_id in known_ids else &"training_plaza"
	var specs := specs_for_map(resolved_id)
	var entries: Array[Dictionary] = []

	for spec in specs:
		var entry: Dictionary = spec.duplicate()

		var texture_path: String = str(entry.get("texture_path", (
			"res://assets/boss_arena/runtime/pirate_mast.png"
			if entry["name"] == "pirate_mast"
			else "res://assets/decorations/%s/runtime/%s.png" % [
				"pirate_harbor" if resolved_id == &"boss_pirate_ship" else resolved_id,
				entry["name"]
			]
		)))

		# Prefer v2 if exists
		var v2_path: String = texture_path.replace(
			"assets/decorations",
			"assets/decorations_v2"
		)

		if ResourceLoader.exists(v2_path):
			texture_path = v2_path

		entry["texture"] = load(texture_path) as Texture2D
		entries.append(entry)

	return entries


static func specs_for_map(map_id: StringName) -> Array[Dictionary]:
	if map_id == &"boss_pirate_ship":
		return [
				{
					"cell": Vector2i(4, 4),
					"size": Vector2i.ONE,
					"name": "harbor_lamp",
					"animated": false
				},
				{
					"cell": Vector2i(11, 4),
					"size": Vector2i.ONE,
					"name": "harbor_lamp",
					"animated": false
				},
				{
					"cell": Vector2i(4, 11),
					"size": Vector2i.ONE,
					"name": "harbor_lamp",
					"animated": false
				},
				{
					"cell": Vector2i(11, 11),
					"size": Vector2i.ONE,
					"name": "harbor_lamp",
					"animated": false
				},
		]

	# Standard PvP maps are now block-only.  Keeping this catalog empty prevents
	# legacy 4x4 landmarks/one-cell props from reserving or visually covering cells.
	return []


static func _center_and_corners(
	center_name: String,
	left_name: String,
	right_name: String,
	center_animated: bool
) -> Array[Dictionary]:
	return [
		{
			"cell": Vector2i(6, 6),
			"size": Vector2i(4, 4),
			"visual_size": Vector2(160, 160),
			"visual_offset": Vector2.ZERO,
			"name": center_name,
			"animated": center_animated
		},
		{
			"cell": Vector2i(3, 3),
			"size": Vector2i.ONE,
			"name": left_name,
			"animated": false
		},
		{
			"cell": Vector2i(12, 3),
			"size": Vector2i.ONE,
			"name": right_name,
			"animated": false
		},
		{
			"cell": Vector2i(3, 12),
			"size": Vector2i.ONE,
			"name": right_name,
			"animated": false
		},
		{
			"cell": Vector2i(12, 12),
			"size": Vector2i.ONE,
			"name": left_name,
			"animated": false
		},
	]
