class_name BoomButton
extends Control

signal pressed

const BoomPalette = preload("res://ui/theme/palette.gd")
const BoomTypography = preload("res://ui/theme/typography.gd")

enum Variant {
	PRIMARY_GOLD,
	ACTION_BLUE,
	CYCLE_COLOR,
	AUTO_READY
}

@export var text: String = "BUTTON":
	set(val):
		text = val
		_update_text()

@export var variant: Variant = Variant.ACTION_BLUE:
	set(val):
		variant = val
		_update_style()

@export var font_size: int = 14:
	set(val):
		font_size = val
		_update_text()

@onready var texture_button: TextureButton = get_node_or_null("TextureButton")
@onready var label: Label = get_node_or_null("Label")

func _ready() -> void:
	if texture_button == null:
		texture_button = TextureButton.new()
		texture_button.name = "TextureButton"
		add_child(texture_button)
	texture_button.set_anchors_preset(PRESET_FULL_RECT)
	texture_button.ignore_texture_size = true
	texture_button.stretch_mode = TextureButton.STRETCH_SCALE
	texture_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	if not texture_button.pressed.is_connected(_on_btn_pressed):
		texture_button.pressed.connect(_on_btn_pressed)

	if label == null:
		label = Label.new()
		label.name = "Label"
		add_child(label)
	label.set_anchors_preset(PRESET_FULL_RECT)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = MOUSE_FILTER_IGNORE
	_deferred_update()


func _deferred_update() -> void:
	_update_style()
	_update_text()

func _on_btn_pressed() -> void:
	pressed.emit()


func _update_text() -> void:
	if label == null:
		label = get_node_or_null("Label")
	if label != null:
		label.text = text
		label.add_theme_font_size_override("font_size", font_size)


func _update_style() -> void:
	if texture_button == null:
		texture_button = get_node_or_null("TextureButton")
	if label == null:
		label = get_node_or_null("Label")
	if texture_button == null:
		return
	match variant:
		Variant.PRIMARY_GOLD:
			_set_button_textures(
				preload("res://ui/assets_generated/buttons/btn_gold_normal.png"),
				preload("res://ui/assets_generated/buttons/btn_gold_hover.png"),
				preload("res://ui/assets_generated/buttons/btn_gold_pressed.png")
			)
			if label != null:
				BoomTypography.apply_label_style(label, font_size, BoomPalette.TEXT_WHITE, BoomPalette.TEXT_GOLD_OUTLINE, 4, HORIZONTAL_ALIGNMENT_CENTER)
		Variant.ACTION_BLUE:
			_set_button_textures(
				preload("res://ui/assets_generated/buttons/btn_blue_normal.png"),
				preload("res://ui/assets_generated/buttons/btn_blue_hover.png"),
				preload("res://ui/assets_generated/buttons/btn_blue_pressed.png")
			)
			if label != null:
				BoomTypography.apply_label_style(label, font_size, BoomPalette.TEXT_WHITE, BoomPalette.TEXT_DARK_OUTLINE, 3, HORIZONTAL_ALIGNMENT_CENTER)
		Variant.CYCLE_COLOR:
			_set_single_texture(preload("res://ui/assets_generated/buttons/btn_cycle.png"))
			if label != null:
				BoomTypography.apply_label_style(label, font_size, BoomPalette.TEXT_CYAN_LIGHT, BoomPalette.TEXT_DARK_OUTLINE, 2, HORIZONTAL_ALIGNMENT_CENTER)
		Variant.AUTO_READY:
			_set_single_texture(preload("res://ui/assets_generated/buttons/btn_auto_ready.png"))
			if label != null:
				BoomTypography.apply_label_style(label, font_size, BoomPalette.TEXT_CYAN_LIGHT, BoomPalette.TEXT_DARK_OUTLINE, 2, HORIZONTAL_ALIGNMENT_CENTER)

func _set_button_textures(n: Texture2D, h: Texture2D, p: Texture2D) -> void:
	texture_button.texture_normal = n
	texture_button.texture_hover = h
	texture_button.texture_pressed = p

func _set_single_texture(t: Texture2D) -> void:
	texture_button.texture_normal = t
	texture_button.texture_hover = t
	texture_button.texture_pressed = t
