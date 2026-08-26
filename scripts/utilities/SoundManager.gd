extends Node

var bgm_player: AudioStreamPlayer
var sfx_players: Array[AudioStreamPlayer] = []
var max_sfx_channels: int = 16
var current_sfx_index: int = 0
var sound_cache: Dictionary = {}
var current_bgm_path: String = ""

# ══════════════════════════════════════════════════════
# SFX Mapping — Chọn lọc từ assets/audio/SFX
# ══════════════════════════════════════════════════════
const SFX_MAP := {
	# Gameplay Core
	"water_balloon_place": "res://assets/audio/SFX/Cha_BombIgnite.ogg",
	"water_burst": "res://assets/audio/SFX/Cha_BombExplode.ogg",
	"water_burst_multi": "res://assets/audio/SFX/Cha_BombExplodeMulti.ogg",
	"block_break": "res://assets/audio/SFX/BombExplosion011.ogg",
	"kick_bomb": "res://assets/audio/SFX/Cha_KickBomb.ogg",
	
	# Item & Pickup
	"item_popup": "res://assets/audio/SFX/Itm_ItemPop.ogg",
	"item_pickup": "res://assets/audio/SFX/Itm_ItemEaten.ogg",
	
	# Character State
	"bubble": "res://assets/audio/SFX/Cha_LockedIn.ogg",
	"rescue": "res://assets/audio/SFX/Cha_Release.ogg",
	"die": "res://assets/audio/SFX/Cha_Die.ogg",
	"revive": "res://assets/audio/SFX/Cha_Revive.ogg",
	
	# Match Flow
	"match_start": "res://assets/audio/SFX/Ntc_GameStart.ogg",
	"match_countdown_3": "res://assets/audio/SFX/Ntc_Count3.ogg",
	"match_countdown_2": "res://assets/audio/SFX/Ntc_Count2.ogg",
	"match_countdown_1": "res://assets/audio/SFX/Ntc_Count1.ogg",
	"match_win": "res://assets/audio/music/Ntc_Win.ogg",
	"match_lose": "res://assets/audio/music/Ntc_Lose.ogg",
	"match_draw": "res://assets/audio/music/Ntc_Draw.ogg",
	"match_end": "res://assets/audio/music/Ntc_GameEnd.ogg",
	"hurry_up": "res://assets/audio/music/Ntc_Hurryup.ogg",
	
	# UI
	"btn_click": "res://assets/audio/SFX/Bt_p_Default.ogg",
	"btn_hover": "res://assets/audio/SFX/Bt_r_Default.ogg",
	"btn_cancel": "res://assets/audio/SFX/Bt_c_Cancle.ogg",
	"btn_confirm": "res://assets/audio/SFX/Bt_c_Success.ogg",
	"ready_on": "res://assets/audio/SFX/Bt_c_GameReadyOn.ogg",
	"ready_off": "res://assets/audio/SFX/Bt_c_GameReadyOff.ogg",
	"game_start_success": "res://assets/audio/SFX/Bt_c_GameStartSuccess.ogg",
	"exit_game": "res://assets/audio/SFX/Bt_r_Out.ogg",
	
	# Needle / Pin
	"needle": "res://assets/audio/SFX/Itm_Niddle.ogg",
}

# ══════════════════════════════════════════════════════
# BGM Mapping — Chọn lọc từ assets/audio/music
# ══════════════════════════════════════════════════════
const BGM_MAP := {
	# Lobby & Login
	"login": "res://assets/audio/music/login.mp3",
	"lobby": "res://assets/audio/music/lobby.mp3",
	"channel_select": "res://assets/audio/music/StageChannel.ogg",
	
	# In-match BGM — các map chính (chọn lọc phù hợp nhất)
	"match_village": "res://assets/audio/music/Village.ogg",
	"match_forest": "res://assets/audio/music/Forest.ogg",
	"match_factory": "res://assets/audio/music/Factory.ogg",
	"match_camp": "res://assets/audio/music/Camp.ogg",
	"match_ice": "res://assets/audio/music/Ice.ogg",
	"match_ocean": "res://assets/audio/music/Ocean.ogg",
	"match_desert": "res://assets/audio/music/Desert.ogg",
	"match_mine": "res://assets/audio/music/Mine.ogg",
	"match_cemetery": "res://assets/audio/music/Cemetery.ogg",
	
	# Special
	"prepare": "res://assets/audio/music/Prepare.ogg",
	"bonus": "res://assets/audio/music/Bonus.ogg",
	"showtime": "res://assets/audio/music/ShowTime.ogg",
}

# Random match BGM pool for variety
const MATCH_BGM_POOL := [
	"res://assets/audio/music/Village.ogg",
	"res://assets/audio/music/Forest.ogg",
	"res://assets/audio/music/Factory.ogg",
	"res://assets/audio/music/Camp.ogg",
	"res://assets/audio/music/Ice.ogg",
	"res://assets/audio/music/Ocean.ogg",
	"res://assets/audio/music/Desert.ogg",
	"res://assets/audio/music/Mine.ogg",
]

var _rng := RandomNumberGenerator.new()

func _ready() -> void:
	if DisplayServer.get_name() == "headless":
		return
	_rng.randomize()
	
	# Create BGM player
	bgm_player = AudioStreamPlayer.new()
	bgm_player.bus = "BGM"
	add_child(bgm_player)
	
	# Create SFX pool
	for i in range(max_sfx_channels):
		var player = AudioStreamPlayer.new()
		player.bus = "SFX"
		add_child(player)
		sfx_players.append(player)
	
	# Pre-load all SFX into cache
	_preload_sfx()
	
	# Connect to EventBus signals
	if has_node("/root/EventBus"):
		var bus = get_node("/root/EventBus")
		if bus.has_signal("water_balloon_placed"):
			bus.water_balloon_placed.connect(_on_water_balloon_placed)
		if bus.has_signal("water_balloon_popped"):
			bus.water_balloon_popped.connect(_on_water_balloon_popped)
		if bus.has_signal("block_destroyed"):
			bus.block_destroyed.connect(_on_block_destroyed)
		if bus.has_signal("item_collected"):
			bus.item_collected.connect(_on_item_collected)
		if bus.has_signal("item_spawned"):
			bus.item_spawned.connect(_on_item_spawned)
		if bus.has_signal("player_bubbled"):
			bus.player_bubbled.connect(_on_player_bubbled)
		if bus.has_signal("player_rescued"):
			bus.player_rescued.connect(_on_player_rescued)
		if bus.has_signal("player_died"):
			bus.player_died.connect(_on_player_died)
		if bus.has_signal("match_started"):
			bus.match_started.connect(_on_match_started)
		if bus.has_signal("match_ended"):
			bus.match_ended.connect(_on_match_ended)

func _exit_tree() -> void:
	if bgm_player != null:
		stop_bgm()
	for player in sfx_players:
		player.stop()
		player.stream = null
	sfx_players.clear()
	sound_cache.clear()

func _preload_sfx() -> void:
	for key in SFX_MAP:
		var path: String = SFX_MAP[key]
		if ResourceLoader.exists(path):
			var stream = load(path) as AudioStream
			if stream != null:
				sound_cache[key] = stream
			else:
				push_warning("[SoundManager] Failed to load SFX: %s" % path)
		else:
			push_warning("[SoundManager] SFX not found: %s" % path)

func play_sfx(sfx_name: String, pitch_scale: float = 1.0, volume_db: float = 0.0) -> void:
	if not sound_cache.has(sfx_name) or sfx_players.is_empty():
		return
	var player = sfx_players[current_sfx_index]
	current_sfx_index = (current_sfx_index + 1) % max_sfx_channels
	player.stream = sound_cache[sfx_name]
	player.pitch_scale = pitch_scale
	player.volume_db = volume_db
	player.play()

func play_bgm(stream_path: String, loop: bool = true) -> void:
	if DisplayServer.get_name() == "headless" or bgm_player == null:
		return
	if current_bgm_path == stream_path and bgm_player.playing:
		return
	if not ResourceLoader.exists(stream_path):
		push_warning("[SoundManager] BGM not found: %s" % stream_path)
		return
	var source := load(stream_path) as AudioStream
	if source == null:
		push_warning("[SoundManager] Unable to load BGM: %s" % stream_path)
		return
	var playable := source.duplicate() as AudioStream
	if playable is AudioStreamMP3:
		(playable as AudioStreamMP3).loop = loop
	if playable is AudioStreamOggVorbis:
		(playable as AudioStreamOggVorbis).loop = loop
	bgm_player.stop()
	bgm_player.bus = "BGM"
	bgm_player.stream = playable
	current_bgm_path = stream_path
	bgm_player.play()

func play_bgm_by_key(key: String, loop: bool = true) -> void:
	if BGM_MAP.has(key):
		play_bgm(BGM_MAP[key], loop)

func play_random_match_bgm() -> void:
	if MATCH_BGM_POOL.is_empty():
		return
	var idx = _rng.randi_range(0, MATCH_BGM_POOL.size() - 1)
	play_bgm(MATCH_BGM_POOL[idx], true)

func stop_bgm() -> void:
	current_bgm_path = ""
	if bgm_player != null:
		bgm_player.stop()
		bgm_player.stream = null

func fade_out_bgm(duration: float = 1.0) -> void:
	if bgm_player == null or not bgm_player.playing:
		return
	var tween := create_tween()
	tween.tween_property(bgm_player, "volume_db", -40.0, duration)
	tween.tween_callback(func():
		stop_bgm()
		bgm_player.volume_db = 0.0
	)

func crossfade_bgm(new_path: String, duration: float = 1.0, loop: bool = true) -> void:
	if bgm_player == null:
		play_bgm(new_path, loop)
		return
	if current_bgm_path == new_path and bgm_player.playing:
		return
	var tween := create_tween()
	tween.tween_property(bgm_player, "volume_db", -40.0, duration * 0.5)
	tween.tween_callback(func():
		play_bgm(new_path, loop)
		bgm_player.volume_db = -40.0
	)
	tween.tween_property(bgm_player, "volume_db", 0.0, duration * 0.5)

# ══════════════════════════════════════════════════════
# Signal Handlers
# ══════════════════════════════════════════════════════
func _on_water_balloon_placed(_id: int, _owner: int, _cell: Vector2i, _timer: float, _rng_val: int) -> void:
	play_sfx("water_balloon_place")

func _on_water_balloon_popped(_id: int, _cell: Vector2i, _affected: Array) -> void:
	play_sfx("water_burst")

func _on_block_destroyed(_cell: Vector2i) -> void:
	play_sfx("block_break", randf_range(0.9, 1.1))

func _on_item_spawned(_id: int, _type: int, _cell: Vector2i) -> void:
	play_sfx("item_popup")

func _on_item_collected(_id: int, _p: int, _t: int, _c: Vector2i) -> void:
	play_sfx("item_pickup")

func _on_player_bubbled(_id: int) -> void:
	play_sfx("bubble")

func _on_player_rescued(_id: int, _res: int) -> void:
	play_sfx("rescue")

func _on_player_died(_id: int) -> void:
	play_sfx("die")

func _on_match_started() -> void:
	play_sfx("match_start")
	# Start random match BGM
	play_random_match_bgm()

func _on_match_ended(winner_id: int, is_draw: bool) -> void:
	fade_out_bgm(0.5)
	if is_draw:
		play_sfx("match_draw")
	else:
		# Local player perspective: check if local player (id=1 or matching team) won
		var local_player_id := 1
		var local_won := false
		var tree = get_tree()
		if tree != null and tree.current_scene != null:
			var match_mgr = tree.current_scene
			if "players" in match_mgr and match_mgr.players is Dictionary:
				var players_dict: Dictionary = match_mgr.players
				if players_dict.has(local_player_id) and players_dict.has(winner_id):
					var local_p = players_dict[local_player_id]
					var win_p = players_dict[winner_id]
					local_won = (winner_id == local_player_id) or (local_p.team_id != 0 and local_p.team_id == win_p.team_id)
				elif winner_id == local_player_id:
					local_won = true
			elif winner_id == local_player_id:
				local_won = true
		elif winner_id == local_player_id:
			local_won = true
			
		if local_won:
			play_sfx("match_win")
		else:
			play_sfx("match_lose")
