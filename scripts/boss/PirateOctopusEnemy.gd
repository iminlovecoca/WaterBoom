class_name PirateOctopusEnemy
extends CharacterBody2D

signal defeated(enemy: PirateOctopusEnemy)

const BOSS_TEXTURE: Texture2D = preload("res://assets/boss/pirate_octopus_boss.png")
const MINION_TEXTURE: Texture2D = preload("res://assets/boss/pirate_octopus_minion.png")
const BOSS_WALK_SHEET: Texture2D = preload("res://assets/boss/pirate_octopus_boss_walk_sheet.png")
const MINION_WALK_SHEET: Texture2D = preload("res://assets/boss/pirate_octopus_minion_walk_sheet.png")

var encounter: BossEncounterManager
var is_boss := false
var round_index := 1
var max_health := 1
var health := 1
var move_speed := 54.0
var phase := 1
var attack_cooldown := 1.5
var spiral_cooldown := 5.0
var touch_cooldown := 0.0
var casting := false
var visual: AnimatedSprite2D
var base_scale := Vector2.ONE
var trapped_in_bubble := false
var bubble_time_left := 0.0
var bubble_visual: Sprite2D
var path_refresh := 0.0
var cached_direction := Vector2.ZERO

func initialize(p_encounter: BossEncounterManager, p_is_boss: bool, p_round: int, spawn_cell: Vector2i) -> void:
	encounter = p_encounter
	is_boss = p_is_boss
	round_index = p_round
	max_health = 36 if is_boss else (1 if round_index == 1 else 2)
	health = max_health
	move_speed = 62.0 if is_boss else 42.0 + round_index * 7.0
	global_position = encounter.grid.grid_to_world(spawn_cell)
	z_index = 7
	_build_visual()
	if is_boss:
		encounter.boss_health_changed.emit(health, max_health, phase)

func _build_visual() -> void:
	var shadow := Polygon2D.new()
	shadow.polygon = PackedVector2Array([Vector2(-42, 21), Vector2(42, 21), Vector2(34, 29), Vector2(-34, 29)]) if is_boss else PackedVector2Array([Vector2(-16, 12), Vector2(16, 12), Vector2(12, 17), Vector2(-12, 17)])
	shadow.color = Color(0.01, 0.04, 0.1, 0.34)
	shadow.z_index = -1
	add_child(shadow)
	visual = AnimatedSprite2D.new()
	visual.sprite_frames = _build_walk_frames()
	visual.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	var target := 132.0 if is_boss else 58.0
	var source := Vector2.ONE * (160.0 if is_boss else 64.0)
	var fit := target / maxf(source.x, source.y)
	visual.scale = Vector2.ONE * fit
	visual.position.y = -24.0 if is_boss else -8.0
	add_child(visual)
	base_scale = visual.scale
	visual.play(&"walk_down")

func _build_walk_frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.remove_animation(&"default")
	var sheet := BOSS_WALK_SHEET if is_boss else MINION_WALK_SHEET
	var frame_size := 160 if is_boss else 64
	var names := [&"walk_down", &"walk_left", &"walk_right", &"walk_up"]
	for row in range(4):
		frames.add_animation(names[row])
		frames.set_animation_loop(names[row], true)
		frames.set_animation_speed(names[row], 8.0 if is_boss else 10.0)
		for column in range(6):
			var atlas := AtlasTexture.new()
			atlas.atlas = sheet
			atlas.region = Rect2(column * frame_size, row * frame_size, frame_size, frame_size)
			frames.add_frame(names[row], atlas)
	return frames

func _physics_process(delta: float) -> void:
	if encounter == null or encounter.match_manager.current_state != GameConstants.MatchState.PLAYING or health <= 0:
		return
	touch_cooldown = maxf(touch_cooldown - delta, 0.0)
	attack_cooldown = maxf(attack_cooldown - delta, 0.0)
	spiral_cooldown = maxf(spiral_cooldown - delta, 0.0)
	if trapped_in_bubble:
		bubble_time_left -= delta
		if is_instance_valid(bubble_visual):
			bubble_visual.rotation += delta * 0.35
			bubble_visual.scale = Vector2.ONE * (1.35 + sin(Time.get_ticks_msec() * 0.012) * 0.06)
		if bubble_time_left <= 0.0:
			_escape_bubble()
		return
	var target := encounter.pick_target(global_position)
	if target == null:
		return
	var distance := global_position.distance_to(target.global_position)
	if not casting:
		path_refresh -= delta
		if path_refresh <= 0.0:
			path_refresh = 0.18 if is_boss else 0.28
			cached_direction = encounter.next_grid_direction(global_position, target.global_position)
		var direction := cached_direction
		if direction == Vector2.ZERO:
			direction = global_position.direction_to(target.global_position)
		_update_walk_direction(direction)
		var speed_multiplier := 1.22 if is_boss and phase == 2 else 1.0
		global_position = encounter.grid.compute_movement_with_corner_sliding(global_position, direction * move_speed * speed_multiplier * delta)
		visual.rotation = sin(Time.get_ticks_msec() * 0.012) * (0.025 if is_boss else 0.07)
	if is_boss:
		if distance <= 92.0 and attack_cooldown <= 0.0 and not casting:
			_begin_close_burst()
		if phase == 2 and spiral_cooldown <= 0.0 and not casting:
			spiral_cooldown = 5.0
			encounter.start_spiral_skill(self)
	elif distance <= 30.0 and touch_cooldown <= 0.0:
		touch_cooldown = 2.2
		target.hit_by_water(encounter.grid.world_to_grid(global_position))

func _update_walk_direction(direction: Vector2) -> void:
	var animation := &"walk_down"
	if absf(direction.x) > absf(direction.y):
		animation = &"walk_right" if direction.x > 0.0 else &"walk_left"
	elif direction.y < 0.0:
		animation = &"walk_up"
	if visual.animation != animation:
		visual.play(animation)

func take_water_damage(amount: int, owner_id: int) -> void:
	if health <= 0 and not trapped_in_bubble:
		return
	if not is_boss:
		trap_in_water(owner_id)
		return
	if trapped_in_bubble:
		pop_trapped_by_player()
		return
	health = maxi(health - amount, 0)
	encounter.register_threat(owner_id, amount)
	var flash := create_tween()
	flash.tween_property(visual, "modulate", Color(1.7, 0.55, 0.55), 0.08)
	flash.tween_property(visual, "modulate", Color.WHITE, 0.14)
	if is_boss and phase == 1 and health <= int(max_health * 0.4):
		phase = 2
		move_speed += 12.0
		attack_cooldown = minf(attack_cooldown, 0.8)
		var rage := create_tween()
		rage.tween_property(visual, "modulate", Color(1.45, 0.42, 0.45), 0.18)
		rage.tween_property(visual, "modulate", Color(1.12, 0.78, 0.9), 0.18)
	if is_boss:
		encounter.boss_health_changed.emit(health, max_health, phase)
	if health <= 0:
		trap_boss_in_giant_bubble()

func trap_boss_in_giant_bubble() -> void:
	if trapped_in_bubble:
		return
	trapped_in_bubble = true
	bubble_time_left = 8.0
	visual.pause()
	visual.scale = base_scale * 0.82
	visual.position.y -= 8.0
	bubble_visual = Sprite2D.new()
	bubble_visual.texture = preload("res://assets/vfx/giant_boss_bubble.png")
	bubble_visual.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	bubble_visual.scale = Vector2.ONE * 1.05
	bubble_visual.position.y = -20.0
	bubble_visual.z_index = 3
	add_child(bubble_visual)

func trap_in_water(owner_id: int) -> void:
	if trapped_in_bubble or health <= 0:
		return
	trapped_in_bubble = true
	bubble_time_left = 5.0
	encounter.register_threat(owner_id, 1)
	visual.pause()
	visual.scale = base_scale * 0.72
	visual.position.y -= 5.0
	bubble_visual = Sprite2D.new()
	bubble_visual.texture = preload("res://assets/water_balloons/skins/skin_066/idle_0.png")
	bubble_visual.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	bubble_visual.modulate = Color(0.78, 0.95, 1.0, 0.82)
	bubble_visual.scale = Vector2.ONE * 0.7
	bubble_visual.position.y = -8.0
	bubble_visual.z_index = 2
	add_child(bubble_visual)

func pop_trapped_by_player() -> void:
	if not trapped_in_bubble:
		return
	trapped_in_bubble = false
	health = 0
	if is_instance_valid(bubble_visual):
		var pop_sheet_tex: Texture2D = preload("res://assets/vfx/bubble_pop_burst.png")
		var pop_sprite := Sprite2D.new()
		pop_sprite.texture = pop_sheet_tex
		pop_sprite.hframes = 8
		pop_sprite.scale = Vector2.ONE * (2.4 if is_boss else 0.7)
		pop_sprite.position = bubble_visual.position
		pop_sprite.z_index = 4
		add_child(pop_sprite)
		bubble_visual.queue_free()
		var ptween := create_tween()
		for f in range(8):
			ptween.tween_callback(func(): pop_sprite.frame = f)
			ptween.tween_interval(0.03)
		ptween.tween_callback(pop_sprite.queue_free)
	defeated.emit(self)
	var vanish := create_tween()
	vanish.tween_property(self, "scale", Vector2(1.3, 0.45), 0.16)
	vanish.parallel().tween_property(self, "modulate:a", 0.0, 0.18)
	vanish.tween_callback(queue_free)

func _escape_bubble() -> void:
	if not trapped_in_bubble:
		return
	if is_boss:
		# If boss timer runs out in giant bubble, it dies automatically
		pop_trapped_by_player()
		return
	trapped_in_bubble = false
	if is_instance_valid(bubble_visual):
		bubble_visual.queue_free()
	visual.position.y += 5.0
	visual.scale = base_scale
	visual.play()

func _begin_close_burst() -> void:
	casting = true
	visual.pause()
	attack_cooldown = 4.0 if phase == 1 else 3.2
	encounter.warn_cross(encounter.grid.world_to_grid(global_position), 2, 1.5)
	var charge := create_tween()
	# The boss visibly strains/crouches for the requested 1.5 second tell.
	charge.tween_property(visual, "scale", base_scale * Vector2(1.16, 0.68), 0.75).set_trans(Tween.TRANS_QUAD)
	charge.tween_property(visual, "scale", base_scale * Vector2(0.92, 1.12), 0.75).set_trans(Tween.TRANS_BACK)
	charge.tween_callback(func():
		if is_instance_valid(self) and health > 0:
			encounter.boss_cross_burst(encounter.grid.world_to_grid(global_position), 2 if phase == 1 else 3)
			casting = false
			visual.play()
	)
