class_name StatBarUI
extends PanelContainer

var character_name_label: Label
var boom_bar: HBoxContainer
var range_bar: HBoxContainer
var speed_bar: HBoxContainer

const MAX_BLOCKS = 10
const BLOCK_SIZE = Vector2(7, 9)
const BASE_COLOR = Color("#3ce22a") # Vibrant Lime Green
const MAX_COLOR = Color("#9ae838")  # Light Yellow-Green
const EMPTY_COLOR = Color("#08203c") # Dark Ocean Inset

func _init() -> void:
	custom_minimum_size = Vector2(166, 72)
	var s := StyleBoxFlat.new()
	s.bg_color = Color("#021228")
	s.border_color = Color("#0d355e")
	s.set_border_width_all(1)
	s.set_corner_radius_all(6)
	s.content_margin_left = 6
	s.content_margin_right = 6
	s.content_margin_top = 4
	s.content_margin_bottom = 4
	add_theme_stylebox_override("panel", s)
	
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)
	add_child(vbox)
	
	character_name_label = Label.new()
	character_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	character_name_label.add_theme_font_size_override("font_size", 11)
	character_name_label.add_theme_color_override("font_color", Color("#55ffff"))
	character_name_label.add_theme_color_override("font_outline_color", Color("#052044"))
	character_name_label.add_theme_constant_override("outline_size", 3)
	vbox.add_child(character_name_label)
	
	boom_bar = _create_stat_row("SỐ LƯỢNG")
	vbox.add_child(boom_bar)
	
	range_bar = _create_stat_row("ĐỘ DÀI")
	vbox.add_child(range_bar)
	
	speed_bar = _create_stat_row("TỐC ĐỘ")
	vbox.add_child(speed_bar)

func _create_stat_row(label_text: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	
	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size = Vector2(46, 0)
	label.add_theme_font_size_override("font_size", 9)
	label.add_theme_color_override("font_color", Color("#8ccfff"))
	label.add_theme_color_override("font_outline_color", Color("#092746"))
	label.add_theme_constant_override("outline_size", 2)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(label)
	
	var blocks_container := HBoxContainer.new()
	blocks_container.name = "Blocks"
	blocks_container.add_theme_constant_override("separation", 1)
	for i in range(MAX_BLOCKS):
		var block := ColorRect.new()
		block.custom_minimum_size = BLOCK_SIZE
		block.color = EMPTY_COLOR
		blocks_container.add_child(block)
	
	row.add_child(blocks_container)
	return row

func update_stats(char_name: String, base_boom: int, max_boom: int, base_range: int, max_range: int, base_spd: float, max_spd: float) -> void:
	character_name_label.text = char_name.to_upper()
	
	_update_blocks(boom_bar.get_node("Blocks"), base_boom, max_boom)
	_update_blocks(range_bar.get_node("Blocks"), base_range, max_range)
	
	var base_spd_blocks := clampi(roundi((base_spd - 100) / 20), 1, MAX_BLOCKS)
	var max_spd_blocks := clampi(roundi((max_spd - 100) / 20), base_spd_blocks, MAX_BLOCKS)
	_update_blocks(speed_bar.get_node("Blocks"), base_spd_blocks, max_spd_blocks)

func _update_blocks(container: Control, base_val: int, max_val: int) -> void:
	for i in range(MAX_BLOCKS):
		var block := container.get_child(i) as ColorRect
		if i < base_val:
			block.color = BASE_COLOR
		elif i < max_val:
			block.color = MAX_COLOR
		else:
			block.color = EMPTY_COLOR
