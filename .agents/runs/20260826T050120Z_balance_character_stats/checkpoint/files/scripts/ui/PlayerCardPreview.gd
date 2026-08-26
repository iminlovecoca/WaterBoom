class_name PlayerCardPreview
extends Control

const ROUNDED_CLIP_SHADER := preload("res://assets/shaders/rounded_clip.gdshader")

const CARD_W := 144
const CARD_H := 100
const GROUND_Y := 88.0

var visual_panel: Panel
var background_view: TextureRect
var portrait: AnimatedSprite2D
var head_view: TextureRect
var flag_group: Control
var flag_pole: TextureRect
var flag_leaf: TextureRect

var head_base_position := Vector2.ZERO
var head_animation := "none"
var head_animation_speed := 1.0
var head_animation_amplitude := 0.0
var animation_time := 0.0

func _ready() -> void:
	custom_minimum_size = Vector2(CARD_W, CARD_H)
	size = Vector2(CARD_W, CARD_H)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_layers()

func _process(_delta: float) -> void:
	# Retained for API compatibility; head rings/accessories are no longer shown.
	pass

func _build_layers() -> void:
	visual_panel = Panel.new()
	visual_panel.position = Vector2.ZERO
	visual_panel.size = Vector2(CARD_W, CARD_H)
	# The full 112x112 V13 canvas is already scaled to the card's safe interior.
	# Do not clip the child layer: bubble/death/win/lose frames have authored
	# lower VFX that must remain visible instead of being cut by the card rail.
	visual_panel.clip_contents = false
	visual_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	visual_panel.add_theme_stylebox_override("panel", _panel_style(Color("#053a78"), Color("#00d2ff"), 2, 10))
	add_child(visual_panel)

	background_view = TextureRect.new()
	background_view.position = Vector2.ZERO
	background_view.size = Vector2(CARD_W, CARD_H)
	background_view.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background_view.stretch_mode = TextureRect.STRETCH_SCALE
	background_view.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	background_view.material = _rounded_clip_material(Vector2(CARD_W, CARD_H), 10.0)
	background_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	visual_panel.add_child(background_view)

	portrait = AnimatedSprite2D.new()
	# V13 uses one shared 112x112 canvas and feet anchor. UI cards use one
	# deterministic scale for every character so none is cropped or missing.
	portrait.position = Vector2(48, 49)
	portrait.scale = Vector2.ONE * CharacterPresentation.CARD_SCALE
	portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	portrait.z_index = 3
	visual_panel.add_child(portrait)

	# Flag mast - Pole height is 46, positioned so pole base is exactly at GROUND_Y (80 - 46 = 34)
	flag_group = Control.new()
	flag_group.name = "FlagMast"
	flag_group.position = Vector2(92, 34)
	flag_group.size = Vector2(39, 46)
	flag_group.mouse_filter = Control.MOUSE_FILTER_IGNORE
	visual_panel.add_child(flag_group)
	
	flag_pole = TextureRect.new()
	flag_pole.position = Vector2(0, 0)
	flag_pole.size = Vector2(14, 46)
	flag_pole.texture = preload("res://assets/ui/flagpole_gold.png")
	flag_pole.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	flag_pole.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	flag_pole.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	flag_pole.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flag_group.add_child(flag_pole)
	
	flag_leaf = TextureRect.new()
	flag_leaf.position = Vector2(9, 7)
	flag_leaf.size = Vector2(29, 19)
	flag_leaf.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	flag_leaf.stretch_mode = TextureRect.STRETCH_SCALE
	flag_leaf.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	flag_leaf.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flag_group.add_child(flag_leaf)

	head_view = TextureRect.new()
	head_view.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	head_view.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	head_view.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	head_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	visual_panel.add_child(head_view)

func configure(character: CharacterDefinition, equipment: Dictionary, _player_name: String = "") -> void:
	if not is_node_ready():
		await ready
	if character != null and character.sprite_frames != null:
		portrait.sprite_frames = character.sprite_frames
		portrait.position = Vector2(48, 49)
		portrait.scale = CharacterPresentation.card_scale_vector_for(character)
		portrait.play(&"idle_down")

	var sanitized := CosmeticRegistry.sanitize_equipment(equipment)
	var flag := CosmeticRegistry.get_definition(sanitized.get("flag", "flag_default_water"))
	flag_leaf.texture = flag.lobby_asset if flag != null else null
	flag_group.visible = flag_leaf.texture != null

	var background := CosmeticRegistry.get_definition(sanitized.get("player_background", "background_default_aqua"))
	
	background_view.position = Vector2.ZERO
	background_view.size = Vector2(CARD_W, CARD_H)
	background_view.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	background_view.material.set_shader_parameter("rect_size", Vector2(CARD_W, CARD_H))
	background_view.material.set_shader_parameter("radius_px", 10.0)
	
	background_view.texture = background.lobby_asset if background != null else null
	background_view.visible = background_view.texture != null

	var slot_style := _panel_style(Color("#053a78") if background_view.texture == null else Color.TRANSPARENT, Color("#00d2ff"), 2, 10)
	visual_panel.add_theme_stylebox_override("panel", slot_style)

	head_view.texture = null
	head_view.visible = false
	head_view.scale = Vector2.ONE
	animation_time = 0.0
	head_animation = "none"

func _rounded_clip_material(rect_size: Vector2, radius: float) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = ROUNDED_CLIP_SHADER
	material.set_shader_parameter("rect_size", rect_size)
	material.set_shader_parameter("radius_px", radius)
	return material

func _panel_style(fill: Color, border: Color, width: int, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(radius)
	return style
