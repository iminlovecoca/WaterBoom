class_name UITheme
extends RefCounted

static func _create_flat(bg: Color, border: Color, border_w: int, radius: int, shadow_y: int = 4) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(border_w)
	style.set_corner_radius_all(radius)
	style.anti_aliasing = true
	if shadow_y > 0:
		style.shadow_color = Color(0, 0.08, 0.25, 0.55)
		style.shadow_size = shadow_y + 2
		style.shadow_offset = Vector2(0, shadow_y)
	
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	return style

static func _create_3d_button(bg: Color, bottom_border: Color, top_border: Color, radius: int) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = bottom_border
	style.set_border_width_all(2)
	style.border_width_bottom = 5 # 3D bevel
	style.border_width_top = 2
	style.set_corner_radius_all(radius)
	style.anti_aliasing = true
	style.shadow_color = Color(0, 0.05, 0.2, 0.45)
	style.shadow_size = 2
	style.shadow_offset = Vector2(0, 3)
	
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 8
	style.content_margin_bottom = 12
	return style

static func panel_main() -> StyleBoxFlat:
	var s := _create_flat(Color("#087fc7"), Color("#5ee3ff"), 3, 12, 5)
	s.border_width_bottom = 4
	return s

static func panel_inset() -> StyleBoxFlat:
	var s := _create_flat(Color("#063c7d"), Color("#14aee8"), 2, 8, 0)
	s.shadow_color = Color(0, 0.05, 0.15, 0.4)
	s.shadow_size = 2
	return s

static func panel_modal() -> StyleBoxFlat:
	var s := _create_flat(Color("#087fc7"), Color("#5ee3ff"), 3, 14, 7)
	s.border_width_bottom = 5
	return s

static func hud_box() -> StyleBoxFlat:
	return _create_flat(Color(0.02, 0.22, 0.48, 0.96), Color("#43d5ff"), 2, 8, 2)

static func slot_empty() -> StyleBoxFlat:
	return _create_flat(Color("#12b5ea"), Color("#075f9f"), 2, 8, 0)

static func slot_active() -> StyleBoxFlat:
	return _create_flat(Color("#20c5ef"), Color("#7de8ff"), 3, 8, 0)

static func slot_master() -> StyleBoxFlat:
	return _create_flat(Color("#00bfff"), Color("#ffd84a"), 3, 8, 0)

static func slot_character_normal() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color("#064d9f")
	s.border_color = Color("#0084dc")
	s.set_border_width_all(2)
	s.border_width_bottom = 4
	s.set_corner_radius_all(6)
	s.content_margin_left = 2
	s.content_margin_right = 2
	s.content_margin_top = 2
	s.content_margin_bottom = 2
	return s

static func slot_character_selected() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color("#0e68d0")
	s.border_color = Color("#ffd84a")
	s.set_border_width_all(3)
	s.border_width_bottom = 4
	s.set_corner_radius_all(6)
	s.shadow_color = Color(1.0, 0.85, 0.3, 0.45)
	s.shadow_size = 5
	s.content_margin_left = 2
	s.content_margin_right = 2
	s.content_margin_top = 2
	s.content_margin_bottom = 2
	return s

static func slot_character_empty() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color("#053a78")
	s.border_color = Color("#0a4c9c")
	s.set_border_width_all(2)
	s.set_corner_radius_all(6)
	s.content_margin_left = 2
	s.content_margin_right = 2
	s.content_margin_top = 2
	s.content_margin_bottom = 2
	return s

# Buttons
static func button_primary_normal() -> StyleBoxFlat:
	return _create_3d_button(Color("#ff9f0a"), Color("#b95a00"), Color("#ffe36e"), 9)

static func button_primary_hover() -> StyleBoxFlat:
	return _create_3d_button(Color("#ffb226"), Color("#c66300"), Color("#fff09a"), 9)

static func button_primary_pressed() -> StyleBoxFlat:
	var s = _create_3d_button(Color("#e67d00"), Color("#8f3e00"), Color("#ff9f0a"), 9)
	s.border_width_bottom = 2 # Depress the button
	s.content_margin_top = 12
	s.content_margin_bottom = 8
	s.shadow_offset = Vector2(0, 1)
	return s

static func button_secondary_normal() -> StyleBoxFlat:
	return _create_3d_button(Color("#0aa7e8"), Color("#075f9f"), Color("#76e5ff"), 9)

static func button_secondary_hover() -> StyleBoxFlat:
	return _create_3d_button(Color("#29b9f0"), Color("#0870b3"), Color("#a0efff"), 9)

static func button_secondary_pressed() -> StyleBoxFlat:
	var s = _create_3d_button(Color("#0788c2"), Color("#054c82"), Color("#2bbfea"), 9)
	s.border_width_bottom = 2
	s.content_margin_top = 12
	s.content_margin_bottom = 8
	s.shadow_offset = Vector2(0, 1)
	return s

static func button_disabled() -> StyleBoxFlat:
	var s := _create_3d_button(Color("#315a78"), Color("#18364f"), Color("#547d96"), 9)
	s.shadow_color = Color(0, 0, 0, 0.18)
	s.shadow_size = 1
	s.shadow_offset = Vector2(0, 1)
	return s

static func button_focus(base: StyleBoxFlat) -> StyleBoxFlat:
	var s := base.duplicate() as StyleBoxFlat
	s.border_color = Color("#fff08a")
	s.set_border_width_all(3)
	s.border_width_bottom = max(5, s.border_width_bottom)
	s.shadow_color = Color(1.0, 0.85, 0.25, 0.38)
	s.shadow_size = 5
	return s

static func button_danger_normal() -> StyleBoxFlat:
	return _create_3d_button(Color("#e63946"), Color("#a81d27"), Color("#ff7d88"), 9)

static func button_danger_hover() -> StyleBoxFlat:
	return _create_3d_button(Color("#f04d5a"), Color("#b8242f"), Color("#ff9aa3"), 9)

static func button_danger_pressed() -> StyleBoxFlat:
	var s = _create_3d_button(Color("#cc2936"), Color("#88141d"), Color("#ee4452"), 9)
	s.border_width_bottom = 2
	s.content_margin_top = 12
	s.content_margin_bottom = 8
	s.shadow_offset = Vector2(0, 1)
	return s

static func apply_button_theme(btn: Button, type: String = "primary") -> void:
	match type:
		"primary":
			btn.add_theme_stylebox_override("normal", button_primary_normal())
			btn.add_theme_stylebox_override("hover", button_primary_hover())
			btn.add_theme_stylebox_override("pressed", button_primary_pressed())
			btn.add_theme_stylebox_override("focus", button_focus(button_primary_normal()))
		"secondary":
			btn.add_theme_stylebox_override("normal", button_secondary_normal())
			btn.add_theme_stylebox_override("hover", button_secondary_hover())
			btn.add_theme_stylebox_override("pressed", button_secondary_pressed())
			btn.add_theme_stylebox_override("focus", button_focus(button_secondary_normal()))
		"danger":
			btn.add_theme_stylebox_override("normal", button_danger_normal())
			btn.add_theme_stylebox_override("hover", button_danger_hover())
			btn.add_theme_stylebox_override("pressed", button_danger_pressed())
			btn.add_theme_stylebox_override("focus", button_focus(button_danger_normal()))
	btn.add_theme_stylebox_override("disabled", button_disabled())
			
	btn.add_theme_color_override("font_color", Color.WHITE)
	btn.add_theme_color_override("font_disabled_color", Color("#a9bfd0"))
	btn.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.5))
	btn.add_theme_constant_override("outline_size", 4)

static func apply_icon_button_theme(btn: Button, type: String = "secondary") -> void:
	apply_button_theme(btn, type)
	for state in ["normal", "hover", "pressed", "focus"]:
		var sb: StyleBox = btn.get_theme_stylebox(state)
		if sb is StyleBoxFlat:
			var s: StyleBoxFlat = sb.duplicate()
			s.content_margin_left = 4
			s.content_margin_right = 4
			s.content_margin_top = 4
			s.content_margin_bottom = 6
			btn.add_theme_stylebox_override(state, s)
