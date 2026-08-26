class_name BoomHeader
extends Control

@export var room_name: String = 'PHÒNG LUYỆN TẬP':
	set(val):
		room_name = val
		if room_label != null: room_label.text = room_name

@export var room_id: String = 'LOCAL':
	set(val):
		room_id = val
		if id_label != null: id_label.text = 'PHÒNG #' + room_id

@onready var room_label: Label = get_node_or_null('RoomLabel')
@onready var id_label: Label = get_node_or_null('IdLabel')

func _ready() -> void:
	if room_label != null: room_label.text = room_name
	if id_label != null: id_label.text = 'PHÒNG #' + room_id
