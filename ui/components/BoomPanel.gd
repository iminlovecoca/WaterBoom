class_name BoomPanel
extends Control

const BoomPalette = preload("res://ui/theme/palette.gd")

enum Variant {
	LEFT_MAIN,
	RIGHT_MAIN,
	INSET_DARK,
	CHAT_LOG,
	CHAT_INPUT
}

@export var variant: Variant = Variant.LEFT_MAIN:
	set(val):
		variant = val
		_update_style()

@onready var patch: NinePatchRect = get_node_or_null("NinePatchRect")

func _ready() -> void:
	if patch == null:
		patch = NinePatchRect.new()
		patch.name = "NinePatchRect"
		add_child(patch)
		move_child(patch, 0)
	patch.set_anchors_preset(PRESET_FULL_RECT)
	patch.mouse_filter = MOUSE_FILTER_IGNORE
	_update_style()

func _update_style() -> void:
	if patch == null:
		patch = get_node_or_null("NinePatchRect")
	if patch == null:
		return
	match variant:
		Variant.LEFT_MAIN:
			patch.texture = preload("res://ui/assets_generated/panels/left_room_panel.png")
			patch.patch_margin_left = 16
			patch.patch_margin_top = 16
			patch.patch_margin_right = 16
			patch.patch_margin_bottom = 16
		Variant.RIGHT_MAIN:
			patch.texture = preload("res://ui/assets_generated/panels/right_section_panel.png")
			patch.patch_margin_left = 16
			patch.patch_margin_top = 16
			patch.patch_margin_right = 16
			patch.patch_margin_bottom = 16
		Variant.INSET_DARK:
			patch.texture = preload("res://ui/assets_generated/panels/inset_dark_box.png")
			patch.patch_margin_left = 10
			patch.patch_margin_top = 10
			patch.patch_margin_right = 10
			patch.patch_margin_bottom = 10
		Variant.CHAT_LOG:
			patch.texture = preload("res://ui/assets_generated/panels/chat_log_box.png")
			patch.patch_margin_left = 8
			patch.patch_margin_top = 8
			patch.patch_margin_right = 8
			patch.patch_margin_bottom = 8
		Variant.CHAT_INPUT:
			patch.texture = preload("res://ui/assets_generated/panels/chat_input_box.png")
			patch.patch_margin_left = 6
			patch.patch_margin_top = 6
			patch.patch_margin_right = 6
			patch.patch_margin_bottom = 6
