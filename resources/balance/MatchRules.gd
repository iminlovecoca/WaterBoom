class_name MatchRules
extends Resource

enum Mode {
	FREE_FOR_ALL,
	TEAM
}

@export var mode: Mode = Mode.FREE_FOR_ALL
@export var bubble_timeout_eliminates: bool = true
@export var teammate_rescue_enabled: bool = true
@export var timeout_is_draw: bool = true

func resolve_bubble_timeout(player: PlayerController) -> void:
	if bubble_timeout_eliminates:
		player.die()
	else:
		player.rescue(0, 0.0)
