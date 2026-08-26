class_name WaterBalloonSkinDefinition
extends Resource

@export var id: StringName = &""
@export var display_name: String = ""
@export var theme: String = ""
@export var primary_color: Color = Color.WHITE
@export var secondary_color: Color = Color.WHITE
@export var outline_color: Color = Color.BLACK
@export var motif: String = "basic"
@export var description: String = ""
@export var rarity: String = "common"
@export var price: int = 0
@export var vfx_profile: String = "water_default"
@export var burst_accent: String = "blue_splash"
@export var icon: Texture2D
@export var sprite_frames: SpriteFrames
@export var unlocked: bool = false

func get_vfx_tint() -> Color:
	match vfx_profile:
		"water_dark": return Color(0.62, 0.5, 1.4)
		"water_sparkle": return Color(1.32, 1.12, 1.42)
		"water_heart": return Color(1.25, 1.1, 1.3)
		"water_galaxy": return Color(0.8, 0.7, 1.3)
		"water_glow": return Color(1.15, 1.35, 1.25)
		"water_ice": return Color(1.1, 1.3, 1.45)
		"water_star": return Color(1.3, 1.28, 1.1)
		"water_fire_accent": return Color.WHITE
		_: return Color.WHITE
