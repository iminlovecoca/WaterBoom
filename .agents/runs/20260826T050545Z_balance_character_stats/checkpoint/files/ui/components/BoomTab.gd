class_name BoomTab
extends Control

signal pressed

const BoomPalette = preload("res://ui/theme/palette.gd")

@export var text: String = 'TAB':
	set(val):
		text = val
		if label != null: label.text = text

@export var is_active: bool = false:
	set(val):
		is_active = val
		_update_style()

@onready var bg: NinePatchRect = get_node_or_null('Background')
@onready var label: Label = get_node_or_null('Label')
@onready var btn: Button = get_node_or_null('Button')

func _ready() -> void:
	if btn != null:
		btn.pressed.connect(func(): pressed.emit())
	_update_style()
	resized.connect(func():
		if bg != null: bg.size = size
		if label != null: label.size = size
		if btn != null: btn.size = size
	)

func _update_style() -> void:
	if bg == null: return
	bg.texture = preload('res://ui/assets_generated/tabs/tab_cyan_active.png') if is_active else preload('res://ui/assets_generated/tabs/tab_cyan_inactive.png')
	if label != null:
		label.text = text
		label.add_theme_color_override('font_color', BoomPalette.TEXT_WHITE if is_active else BoomPalette.TEXT_CYAN_LIGHT)
