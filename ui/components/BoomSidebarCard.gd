class_name BoomSidebarCard
extends Control

@onready var avatar: TextureRect = get_node_or_null('AvatarFrame/Avatar')
@onready var name_lbl: Label = get_node_or_null('NameLabel')
@onready var badge_lbl: Label = get_node_or_null('BadgeLabel')

func set_player(name_str: String, avatar_tex: Texture2D, is_alive: bool) -> void:
	if name_lbl != null: name_lbl.text = name_str
	if avatar != null: avatar.texture = avatar_tex
	if badge_lbl != null:
		badge_lbl.text = 'SỐNG' if is_alive else 'THUA'
		badge_lbl.add_theme_color_override('font_color', BoomPalette.TEXT_GREEN_READY if is_alive else Color(1, 0.3, 0.3))
