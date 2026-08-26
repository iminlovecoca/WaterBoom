class_name BoomMapCard
extends Control

signal map_change_requested

@onready var map_preview: TextureRect = get_node_or_null('MapFrame/MapPreview')
@onready var map_name: Label = get_node_or_null('InfoRows/NameRow/Val')
@onready var map_players: Label = get_node_or_null('InfoRows/PlayersRow/Val')
@onready var map_diff: Label = get_node_or_null('InfoRows/DiffRow/Val')
@onready var map_size: Label = get_node_or_null('InfoRows/SizeRow/Val')
@onready var select_btn: TextureButton = get_node_or_null('SelectMapBtn')

func _ready() -> void:
	if select_btn != null:
		select_btn.pressed.connect(func(): map_change_requested.emit())

func set_map(map_id: StringName) -> void:
	var meta: Dictionary = MapCatalog.get_map_metadata(map_id)
	if map_preview != null:
		var p := "res://assets/ui/map_previews/map_%s.png" % str(map_id)
		if ResourceLoader.exists(p):
			map_preview.texture = load(p)
	if map_name != null:
		map_name.text = str(meta.get("name", map_id))
	if map_players != null:
		map_players.text = str(meta.get("players", "4"))
	if map_diff != null:
		map_diff.text = str(meta.get("diff", "Dễ"))
	if map_size != null:
		map_size.text = str(meta.get("stars", "★☆☆☆☆"))
