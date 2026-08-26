class_name BoomSlot
extends Control

signal clicked(slot_index: int)

@export var slot_index: int = 0
@export var is_selected: bool = false:
	set(val):
		is_selected = val
		_update_style()

@onready var bg: TextureRect = get_node_or_null('Background')
@onready var icon: TextureRect = get_node_or_null('Icon')
@onready var check_badge: TextureRect = get_node_or_null('CheckBadge')
@onready var btn: Button = get_node_or_null('Button')

func _ready() -> void:
	if btn != null:
		btn.pressed.connect(func(): clicked.emit(slot_index))
	_update_style()
	resized.connect(func():
		if bg != null: bg.size = size
		if btn != null: btn.size = size
	)

func _update_style() -> void:
	if bg == null:
		return
	bg.texture = preload('res://ui/assets_generated/slots/char_slot_x_selected.png') if is_selected else preload('res://ui/assets_generated/slots/char_slot_x_normal.png')
	if check_badge != null:
		check_badge.visible = is_selected

func set_character_icon(tex: Texture2D, character_def: CharacterDefinition = null) -> void:
	if icon != null:
		icon.texture = tex
		icon.visible = tex != null
		icon.pivot_offset = icon.size * 0.5
		icon.scale = CharacterPresentation.content_scale_vector(character_def) if character_def != null else Vector2.ONE
