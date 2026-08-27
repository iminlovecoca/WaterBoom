class_name CosmeticDefinition
extends Resource

const HEAD_ACCESSORY: StringName = &"head_accessory"
const FLAG: StringName = &"flag"
const PLAYER_FRAME: StringName = &"player_frame"
const PLAYER_BACKGROUND: StringName = &"player_background"

@export var id: StringName
@export var display_name: String = ""
@export_enum("head_accessory", "flag", "player_frame", "player_background") var category: String = "flag"
@export_multiline var description: String = ""
@export var price: int = 0
@export var is_default: bool = false

# Each context has its own art slot.  Lobby cards are close to square while
# match-list rows are horizontal, so one texture must never be stretched into
# both places.
@export var icon: Texture2D
@export var lobby_asset: Texture2D
@export var lobby_frames: SpriteFrames
@export var match_list_asset: Texture2D
@export var world_asset: Texture2D

@export var lobby_offset: Vector2 = Vector2.ZERO
@export var lobby_scale: float = 1.0
@export var match_list_offset: Vector2 = Vector2.ZERO
@export var match_list_scale: float = 1.0
@export var world_offset: Vector2 = Vector2.ZERO
@export var world_scale: float = 1.0

# Shared placement family. Rings encircle the head, face items align to the
# eyes/nose area, and hats sit flush against the top of the head.
@export_enum("ring", "face", "hat") var placement_profile: String = "ring"

@export_enum("none", "bob", "orbit", "pulse") var animation: String = "none"
@export var animation_speed: float = 1.0
@export var animation_amplitude: float = 2.0
@export var primary_color: Color = Color("#0d5a93")
@export var accent_color: Color = Color("#44d7ff")

func category_id() -> StringName:
	return StringName(category)
