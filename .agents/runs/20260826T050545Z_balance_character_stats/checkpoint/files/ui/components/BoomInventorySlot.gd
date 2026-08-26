class_name BoomInventorySlot
extends Control

signal clicked

@export var item_name: String = '':
	set(val):
		item_name = val
		if label != null: label.text = item_name

@export var is_equipped: bool = false:
	set(val):
		is_equipped = val
		if equipped_badge != null: equipped_badge.visible = is_equipped

@onready var bg: NinePatchRect = get_node_or_null('Background')
@onready var icon: TextureRect = get_node_or_null('Icon')
@onready var label: Label = get_node_or_null('Label')
@onready var equipped_badge: Label = get_node_or_null('EquippedBadge')
@onready var btn: Button = get_node_or_null('Button')

func _ready() -> void:
	if btn != null:
		btn.pressed.connect(func(): clicked.emit())

func set_item(t: Texture2D, name_str: String, equipped: bool) -> void:
	if icon != null: icon.texture = t
	item_name = name_str
	is_equipped = equipped
