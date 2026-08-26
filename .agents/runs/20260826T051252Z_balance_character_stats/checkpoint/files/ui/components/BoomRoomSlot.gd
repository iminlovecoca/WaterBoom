class_name BoomRoomSlot
extends Control

signal clicked(slot_index: int)

const BoomPalette = preload("res://ui/theme/palette.gd")

@export var slot_index: int = 0
@export var is_empty: bool = true:
	set(val):
		is_empty = val
		_update_display()

@export var player_name: String = '':
	set(val):
		player_name = val
		if name_label != null:
			name_label.text = player_name

@export var status_text: String = '':
	set(val):
		status_text = val
		if status_label != null:
			status_label.text = status_text

@export var is_master: bool = false:
	set(val):
		is_master = val
		if crown_icon != null:
			crown_icon.visible = is_master

@onready var card_panel: NinePatchRect = get_node_or_null('CardPanel')
@onready var portrait: AnimatedSprite2D = get_node_or_null('CardPanel/Portrait')
@onready var head_view: TextureRect = get_node_or_null('CardPanel/HeadView')
@onready var flag_view: TextureRect = get_node_or_null('CardPanel/FlagView')
@onready var crown_icon: TextureRect = get_node_or_null('CardPanel/CrownIcon')
@onready var name_panel: NinePatchRect = get_node_or_null('NamePanel')
@onready var name_label: Label = get_node_or_null('NamePanel/NameLabel')
@onready var status_panel: NinePatchRect = get_node_or_null('StatusPanel')
@onready var status_label: Label = get_node_or_null('StatusPanel/StatusLabel')
@onready var click_button: Button = get_node_or_null('ClickButton')

func _ready() -> void:
	_ensure_nodes()
	if click_button != null:
		click_button.pressed.connect(func(): clicked.emit(slot_index))
	_update_display()

func _ensure_nodes() -> void:
	if card_panel == null: card_panel = get_node_or_null('CardPanel')
	if portrait == null: portrait = get_node_or_null('CardPanel/Portrait')
	if head_view == null: head_view = get_node_or_null('CardPanel/HeadView')
	if flag_view == null: flag_view = get_node_or_null('CardPanel/FlagView')
	if crown_icon == null: crown_icon = get_node_or_null('CardPanel/CrownIcon')
	if name_panel == null: name_panel = get_node_or_null('NamePanel')
	if name_label == null: name_label = get_node_or_null('NamePanel/NameLabel')
	if status_panel == null: status_panel = get_node_or_null('StatusPanel')
	if status_label == null: status_label = get_node_or_null('StatusPanel/StatusLabel')
	if click_button == null: click_button = get_node_or_null('ClickButton')

func _update_display() -> void:
	_ensure_nodes()
	if card_panel == null:
		return
	if is_empty:
		if portrait != null: portrait.visible = false
		if head_view != null: head_view.visible = false
		if flag_view != null: flag_view.visible = false
		if crown_icon != null: crown_icon.visible = false
		if name_label != null: name_label.text = ''
		if status_label != null:
			status_label.text = '+ THÊM BOT' if slot_index >= 4 else 'TRỐNG'
			status_label.add_theme_color_override('font_color', Color(0.6, 0.8, 1.0, 0.6))
	else:
		if portrait != null: portrait.visible = true
		if crown_icon != null: crown_icon.visible = is_master
		if name_label != null: name_label.text = player_name
		if status_label != null:
			status_label.text = status_text
			status_label.add_theme_color_override('font_color', BoomPalette.TEXT_CYAN_VIBRANT if is_master else BoomPalette.TEXT_GREEN_READY)

func set_character(char_frames: SpriteFrames, character_def: CharacterDefinition = null) -> void:
	if portrait != null:
		portrait.sprite_frames = char_frames
		# Keep every V13 character on the same safe canvas scale. The SpriteFrames
		# already contain the shared 112x112 feet anchor; never scale per skin.
		portrait.position = Vector2(48, 48)
	if character_def != null:
		portrait.scale = CharacterPresentation.slot_scale_vector_for(character_def)
	else:
		portrait.scale = Vector2.ONE * CharacterPresentation.SLOT_SCALE
		portrait.z_index = 3
		portrait.play(&'idle_down')
	is_empty = false

func set_head_accessory(tex: Texture2D) -> void:
	if head_view != null:
		head_view.texture = null
		head_view.visible = false

func set_flag(tex: Texture2D) -> void:
	if flag_view != null:
		flag_view.texture = tex
		flag_view.visible = tex != null
