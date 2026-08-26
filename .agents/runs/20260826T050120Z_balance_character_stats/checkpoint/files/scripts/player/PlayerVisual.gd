class_name PlayerVisual
extends Node2D

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var development_character: DevelopmentCharacter = $DevelopmentCharacter
@onready var shadow: Node2D = $Shadow
@onready var bubble: BubbleVisual = $Bubble
@onready var status_vfx: CharacterStatusVFX = $StatusVFX
@onready var name_label: Label = $NameLabel
@onready var head_accessory: Sprite2D = $HeadAccessory

var character_def: CharacterDefinition
var bubble_tween: Tween
var current_direction: GameConstants.Direction = GameConstants.Direction.DOWN
var one_shot_active := false
var terminal_animation := false
var pending_bubble := false
var sprite_base_position := Vector2.ZERO
var sprite_base_scale := Vector2.ONE
var sprite_character_scale := Vector2.ONE
var development_base_scale := Vector2.ONE
var locomotion_time := 0.0
var locomotion_blend := 0.0
var head_accessory_tween: Tween

func _process(_delta: float) -> void:
	pass

func _ready() -> void:
	sprite.animation_finished.connect(_on_animation_finished)
	sprite_base_position = sprite.position
	sprite_base_scale = sprite.scale
	sprite_character_scale = sprite_base_scale
	development_base_scale = development_character.scale

func setup(p_char_def: CharacterDefinition) -> void:
	character_def = p_char_def
	modulate.a = 1.0
	one_shot_active = false
	terminal_animation = false
	pending_bubble = false
	if character_def != null and character_def.sprite_frames != null:
		development_character.visible = false
		sprite.visible = true
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		sprite.sprite_frames = character_def.sprite_frames
		sprite_character_scale = sprite_base_scale * CharacterPresentation.runtime_scale_vector(character_def)
		sprite.scale = sprite_character_scale
		shadow.position.y = character_def.shadow_offset_y
		shadow.scale = CharacterPresentation.runtime_scale_vector(character_def)
		_play_directional(&"idle", current_direction)
	else:
		sprite.visible = false
		development_character.visible = true
	bubble.visible = false
	bubble.scale = Vector2.ONE
	bubble.modulate = Color.WHITE
	_restore_character_from_bubble()
	status_vfx.set_mode(&"idle")

func apply_equipment(_equipment: Dictionary) -> void:
	if head_accessory_tween != null:
		head_accessory_tween.kill()
		head_accessory_tween = null
	head_accessory.texture = null
	head_accessory.visible = false
	head_accessory.position = Vector2(0, -32)
	head_accessory.scale = Vector2.ONE
	head_accessory.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	# Intentionally ignore the legacy head_accessory field. Ownership remains in
	# account data for backward compatibility, but the visual is retired.

func set_player_name(nickname: String, player_color: Color = Color.WHITE) -> void:
	name_label.text = nickname
	name_label.modulate = player_color

func set_development_color(player_color: Color) -> void:
	development_character.set_body_color(player_color)

func update_state(state: GameConstants.PlayerState, direction: GameConstants.Direction) -> void:
	if direction != GameConstants.Direction.NONE:
		current_direction = direction
	status_vfx.set_direction(current_direction)
	development_character.set_character_state(state, current_direction)
	if not sprite.visible or terminal_animation or one_shot_active:
		return
	match state:
		GameConstants.PlayerState.NORMAL, GameConstants.PlayerState.RESCUED:
			_play_directional(&"idle", current_direction)
			status_vfx.set_mode(&"idle")
		GameConstants.PlayerState.WALKING:
			_play_directional(&"walk", current_direction)
			status_vfx.set_mode(&"walk")
		GameConstants.PlayerState.PLACING:
			_play_directional(&"idle", current_direction)
		GameConstants.PlayerState.WATER_HIT:
			play_hurt_then_bubble(current_direction)
		GameConstants.PlayerState.BUBBLED:
			_play_exact(&"bubble")
			status_vfx.set_mode(&"bubbled")

func play_place(direction: GameConstants.Direction = GameConstants.Direction.NONE) -> void:
	if direction != GameConstants.Direction.NONE:
		current_direction = direction
	_play_directional(&"idle", current_direction)
	status_vfx.burst(&"place", 0.45)

func play_pickup() -> void:
	status_vfx.burst(&"pickup", 0.55)

func play_pin_escape() -> void:
	status_vfx.burst(&"pin_escape", 0.65)
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2(1.16, 0.86), 0.08).set_trans(Tween.TRANS_BACK)
	tween.tween_property(self, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_ELASTIC)

func play_hurt_then_bubble(direction: GameConstants.Direction = GameConstants.Direction.NONE) -> void:
	if direction != GameConstants.Direction.NONE:
		current_direction = direction
	pending_bubble = true
	_play_one_shot(&"water_hit")
	status_vfx.burst(&"hurt", 0.5)

func set_bubble(active: bool) -> void:
	if bubble_tween != null and bubble_tween.is_valid():
		bubble_tween.kill()
	bubble.visible = active
	if active:
		pending_bubble = true
		bubble.modulate = Color.WHITE
		bubble.scale = Vector2.ONE
		bubble.set_time_progress(1.0)
		shadow.visible = false
		sprite.position = Vector2(0.0, -20.0)
		sprite.scale = sprite_character_scale * 0.5
		development_character.scale = development_base_scale * 0.5
		if not one_shot_active:
			_play_exact(&"bubble")
		status_vfx.set_mode(&"bubbled")
		bubble_tween = create_tween().set_loops()
		bubble_tween.tween_property(bubble, "scale", Vector2(1.04, 0.98), 0.45)
		bubble_tween.tween_property(bubble, "scale", Vector2(0.98, 1.04), 0.45)
	else:
		pending_bubble = false
		bubble.scale = Vector2.ONE
		bubble.modulate = Color.WHITE
		bubble.set_time_progress(1.0)
		_restore_character_from_bubble()
		_play_exact(&"rescued", true)
		status_vfx.set_mode(&"idle")

func set_bubble_progress(progress: float) -> void:
	## Drive the visible countdown: the shell becomes denser/darker as time runs out.
	## PlayerController already computes this value every frame; keeping the
	## adapter here makes that contract real instead of silently no-oping.
	if bubble == null or not bubble.visible:
		return
	var clamped := clampf(progress, 0.0, 1.0)
	bubble.set_time_progress(clamped)
	var urgency := 1.0 - clamped
	bubble.modulate = Color(1.0 - urgency * 0.10, 1.0 - urgency * 0.16, 1.0 - urgency * 0.04, 1.0)

func play_rescued() -> void:
	pending_bubble = false
	_restore_character_from_bubble()
	if sprite.sprite_frames != null and sprite.sprite_frames.has_animation(StringName("escape_%s" % GameConstants.direction_to_string(current_direction))):
		one_shot_active = true
		_play_directional(&"escape", current_direction, true)
	else:
		_play_one_shot(&"rescued")
	status_vfx.burst(&"pickup", 0.65)

var shield_sprite: Sprite2D = null

func set_shield_active(active: bool) -> void:
	if active:
		if shield_sprite == null:
			shield_sprite = Sprite2D.new()
			shield_sprite.texture = preload("res://assets/vfx/shield_aura.png")
			shield_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
			shield_sprite.position.y = -8.0
			shield_sprite.z_index = 3
			add_child(shield_sprite)
		shield_sprite.visible = true
		shield_sprite.scale = Vector2.ONE * 0.95
		shield_sprite.modulate = Color(1.0, 1.0, 1.0, 0.85)
	else:
		if shield_sprite != null:
			shield_sprite.visible = false

func play_shield_break() -> void:
	if shield_sprite != null:
		var tween := create_tween()
		tween.tween_property(shield_sprite, "scale", Vector2.ONE * 1.5, 0.15).set_trans(Tween.TRANS_BACK)
		tween.parallel().tween_property(shield_sprite, "modulate:a", 0.0, 0.15)
		tween.tween_callback(func(): shield_sprite.visible = false)

func play_bubble_pop_and_death() -> void:
	if bubble_tween != null and bubble_tween.is_valid():
		bubble_tween.kill()
	pending_bubble = false
	shadow.visible = false
	bubble.visible = true
	bubble.play_pop_burst()
	var tween := create_tween()
	tween.tween_interval(0.28)
	tween.tween_callback(play_death)

func _restore_character_from_bubble() -> void:
	shadow.visible = true
	sprite.position = sprite_base_position
	sprite.scale = sprite_character_scale
	development_character.scale = development_base_scale

func play_death() -> void:
	bubble.visible = false
	pending_bubble = false
	terminal_animation = true
	one_shot_active = false
	_play_exact(&"die", true)
	status_vfx.set_mode(&"lose")
	var tween := create_tween()
	tween.tween_interval(0.75)
	tween.tween_property(self, "modulate:a", 0.0, 0.45)

func play_win() -> void:
	terminal_animation = true
	one_shot_active = false
	_play_exact(&"win", true)
	status_vfx.set_mode(&"win")

func play_lose() -> void:
	if terminal_animation:
		return
	terminal_animation = true
	one_shot_active = false
	_play_exact(&"lose", true)
	status_vfx.set_mode(&"lose")

func _play_one_shot(base: StringName) -> void:
	if not sprite.visible or terminal_animation:
		return
	one_shot_active = true
	_play_exact(base, true)

func _play_exact(animation_name: StringName, force_restart: bool = false) -> void:
	if not sprite.visible or sprite.sprite_frames == null:
		return
	if not sprite.sprite_frames.has_animation(animation_name):
		_play_directional(&"idle", current_direction, force_restart)
		return
	if force_restart or sprite.animation != animation_name or not sprite.is_playing():
		sprite.play(animation_name)

func _play_directional(base: StringName, direction: GameConstants.Direction, force_restart: bool = false) -> void:
	if not sprite.visible or sprite.sprite_frames == null:
		return
	var direction_name := GameConstants.direction_to_string(direction)
	if direction_name == "idle":
		direction_name = "down"
	var animation_name := StringName("%s_%s" % [base, direction_name])
	if not sprite.sprite_frames.has_animation(animation_name):
		animation_name = &"idle_down"
	if base == &"walk":
		sprite.speed_scale = 1.35
	else:
		sprite.speed_scale = 1.0
	if force_restart or sprite.animation != animation_name or not sprite.is_playing():
		sprite.play(animation_name)

func _on_animation_finished() -> void:
	if terminal_animation:
		return
	one_shot_active = false
	if pending_bubble:
		_play_exact(&"bubble")
		status_vfx.set_mode(&"bubbled")
	else:
		_play_directional(&"idle", current_direction)
		status_vfx.set_mode(&"idle")
