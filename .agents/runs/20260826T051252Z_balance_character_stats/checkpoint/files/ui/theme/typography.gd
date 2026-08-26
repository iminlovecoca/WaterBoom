class_name BoomTypography
extends RefCounted

# ==============================================================================
# BOOM ONLINE TYPOGRAPHY & TEXT STYLES
# ==============================================================================

const FONT_SIZE_TITLE_LARGE: int = 24
const FONT_SIZE_TITLE_MEDIUM: int = 18
const FONT_SIZE_HEADER: int = 14
const FONT_SIZE_BODY: int = 12
const FONT_SIZE_SMALL: int = 11
const FONT_SIZE_TINY: int = 9

const OUTLINE_SIZE_LARGE: int = 6
const OUTLINE_SIZE_MEDIUM: int = 4
const OUTLINE_SIZE_SMALL: int = 2

static func apply_label_style(
	label: Label,
	font_size: int = FONT_SIZE_BODY,
	text_color: Color = BoomPalette.TEXT_WHITE,
	outline_color: Color = BoomPalette.TEXT_DARK_OUTLINE,
	outline_size: int = OUTLINE_SIZE_SMALL,
	align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT
) -> void:
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", text_color)
	if outline_size > 0:
		label.add_theme_color_override("font_outline_color", outline_color)
		label.add_theme_constant_override("outline_size", outline_size)
	label.horizontal_alignment = align
