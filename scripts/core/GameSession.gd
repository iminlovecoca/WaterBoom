extends Node

signal cokecy_changed(new_value: int)
signal progression_changed(level: int, experience: int, required: int)

const PROFILE_PATH := "user://player_profile.cfg"
const COKECY_POLL_INTERVAL := 1.0
const DEFAULT_CHARACTER_ID: StringName = &"boom_mascot"

var play_mode: StringName = &"solo"
var bot_count: int = 1
var bot_difficulty: GameConstants.BotDifficulty = GameConstants.BotDifficulty.NORMAL
var selected_map_id: StringName = &"training_plaza"
var selected_character_id: StringName = DEFAULT_CHARACTER_ID
var player_nickname: String = "Người chơi"
var selected_balloon_skin: StringName = &"skin_066"
var cokecy: int = 500
var level: int = 1
var experience: int = 0
var owned_balloon_skins: Array[StringName] = [&"skin_066", &"skin_069"]
var owned_cosmetics: Array[StringName] = [
	&"flag_default_water",
	&"frame_default_aqua",
	&"background_default_aqua",
]
var equipped_cosmetics: Dictionary = {
	"head_accessory": "",
	"flag": "flag_default_water",
	"player_frame": "frame_default_aqua",
	"player_background": "background_default_aqua",
}
var player_count: int = 2
var team_mode: bool = false

func _ready() -> void:
	var profile := ConfigFile.new()
	if profile.load(PROFILE_PATH) == OK:
		player_nickname = _clean_nickname(str(profile.get_value("player", "nickname", player_nickname)))
	_start_cokecy_polling()

func _start_cokecy_polling() -> void:
	if has_node("/root/AccountDatabase"):
		AccountDatabase.cokecy_fetched_received.connect(func(c):
			if c >= 0 and c != cokecy:
				cokecy = c
				cokecy_changed.emit(cokecy)
		)
	var timer := Timer.new()
	timer.name = "CokecyPollTimer"
	timer.wait_time = COKECY_POLL_INTERVAL
	timer.timeout.connect(_poll_cokecy)
	add_child(timer)
	timer.start()

func _poll_cokecy() -> void:
	if not NetworkManager.is_connected_to_server(): return
	# Chi poll khi da dang nhap thanh cong (co user_id hop le)
	if AccountDatabase.current_user_id <= 0: return
	AccountDatabase.rpc_id(1, "request_fetch_cokecy")

func set_player_nickname(value: String) -> void:
	player_nickname = _clean_nickname(value)
	var profile := ConfigFile.new()
	profile.set_value("player", "nickname", player_nickname)
	profile.save(PROFILE_PATH)
	_save_sql_profile()

func apply_authenticated_user(user: Dictionary) -> void:
	# The account name is immutable and uniquely identifies the signed-in user.
	# Never inherit another account's locally cached/mutable nickname.
	player_nickname = _clean_nickname(str(user.get("username", "Người chơi")))
	cokecy = maxi(int(user.get("cokecy", 500)), 0)
	level = maxi(int(user.get("level", 1)), 1)
	experience = maxi(int(user.get("experience", 0)), 0)
	_normalize_experience()
	selected_character_id = ActiveCharacterRoster.normalize_id(StringName(user.get("selected_character_id", DEFAULT_CHARACTER_ID)))
	selected_balloon_skin = StringName(user.get("selected_balloon_skin", "skin_066"))
	# Migrate profiles created by the old catalog.  Old files may remain on disk,
	# but they must never be shown or selected by the current runtime catalog.
	if not WaterBalloonSkinRegistry.get_all_skin_ids().has(selected_balloon_skin):
		selected_balloon_skin = &"skin_066"
	var database_skins = AccountDatabase.unlocked_skins_for_current_user()
	owned_balloon_skins.clear()
	for s in database_skins:
		var runtime_id := StringName(str(s))
		if WaterBalloonSkinRegistry.get_all_skin_ids().has(runtime_id):
			owned_balloon_skins.append(runtime_id)
	if owned_balloon_skins.is_empty():
		owned_balloon_skins.append(&"skin_066")
	if not owned_balloon_skins.has(&"skin_066"):
		owned_balloon_skins.append(&"skin_066")
	owned_cosmetics.clear()
	for cosmetic_id in user.get("owned_cosmetics", []):
		owned_cosmetics.append(StringName(str(cosmetic_id)))
	for default_id in CosmeticRegistry.all_default_owned_ids():
		if not owned_cosmetics.has(default_id):
			owned_cosmetics.append(default_id)
	equipped_cosmetics = CosmeticRegistry.sanitize_equipment(
		user.get("equipment", CosmeticRegistry.default_equipment()),
		owned_cosmetics
	)

func _clean_nickname(value: String) -> String:
	var cleaned := value.strip_edges().substr(0, 16)
	return cleaned if not cleaned.is_empty() else "Người chơi"

func add_cokecy(amount: int) -> void:
	cokecy = maxi(cokecy + amount, 0)
	cokecy_changed.emit(cokecy)
	_save_sql_profile()

func experience_required_for_level(for_level: int = level) -> int:
	return 100 + maxi(for_level - 1, 0) * 50

func experience_percent() -> float:
	return clampf(float(experience) / float(experience_required_for_level()) * 100.0, 0.0, 100.0)

func add_experience(amount: int) -> Dictionary:
	var old_level := level
	var old_experience := experience
	var old_required := experience_required_for_level()
	experience += maxi(amount, 0)
	_normalize_experience()
	var result := {
		"gained": maxi(amount, 0),
		"old_level": old_level,
		"old_experience": old_experience,
		"old_required": old_required,
		"new_level": level,
		"new_experience": experience,
		"new_required": experience_required_for_level(),
		"percent": experience_percent(),
		"leveled_up": level > old_level,
	}
	progression_changed.emit(level, experience, experience_required_for_level())
	_save_sql_profile()
	return result

func _normalize_experience() -> void:
	while experience >= experience_required_for_level():
		experience -= experience_required_for_level()
		level += 1

func owns_balloon_skin(skin_id: StringName) -> bool:
	if skin_id == &"skin_066":
		return true
	if owned_balloon_skins.has(skin_id):
		return true
	return false

func owns_cosmetic(cosmetic_id: StringName) -> bool:
	var definition := CosmeticRegistry.get_definition(cosmetic_id)
	return definition != null and (definition.is_default or owned_cosmetics.has(cosmetic_id))

func buy_balloon_skin(skin_id: StringName, price: int) -> bool:
	if owns_balloon_skin(skin_id):
		return true
	if cokecy < price:
		return false
	# Networked clients never mutate their own currency before the server has
	# atomically charged and unlocked the skin.  The shop receives the result
	# through AccountDatabase.skin_purchase_received.
	var online := has_node("/root/NetworkManager") and NetworkManager.is_connected_to_server()
	if online:
		if has_node("/root/AccountDatabase") and AccountDatabase.current_user_id > 0:
			AccountDatabase.rpc_id(1, "request_unlock_skin", skin_id)
		return false

	# Offline/editor sessions use the same transactional SQL path when an
	# authenticated local account exists, keeping the balance and ownership in
	# sync with the account database.
	if has_node("/root/AccountDatabase") and AccountDatabase.current_user_id > 0:
		var result := AccountDatabase.purchase_balloon_skin_for_current_user(skin_id)
		if not bool(result.get("success", false)):
			return false
		if not owned_balloon_skins.has(skin_id):
			owned_balloon_skins.append(skin_id)
		var authoritative_balance := int(result.get("balance", -1))
		if authoritative_balance >= 0 and authoritative_balance != cokecy:
			cokecy = authoritative_balance
			cokecy_changed.emit(cokecy)
		return true

	# Keep the legacy headless/editor harness deterministic for old catalog IDs;
	# production shop entries are all catalog-backed and take the path above.
	if skin_id in [&"classic", &"watermelon", &"dark"]:
		cokecy -= price
		owned_balloon_skins.append(skin_id)
		cokecy_changed.emit(cokecy)
		return true
	return false

func save_profile() -> void:
	_save_sql_profile()

func _save_sql_profile() -> void:
	if NetworkManager.is_connected_to_server():
		AccountDatabase.rpc_id(1, "request_save_profile", player_nickname, cokecy, level, experience, selected_character_id, selected_balloon_skin)

func configure_solo(p_bot_count: int, p_difficulty: int, p_map_id: StringName, p_character_id: StringName = DEFAULT_CHARACTER_ID) -> void:
	play_mode = &"solo"
	bot_count = clampi(p_bot_count, 1, 3)
	player_count = bot_count + 1
	team_mode = false
	bot_difficulty = clampi(p_difficulty, GameConstants.BotDifficulty.EASY, GameConstants.BotDifficulty.EXTREME) as GameConstants.BotDifficulty
	selected_map_id = p_map_id
	selected_character_id = ActiveCharacterRoster.normalize_id(p_character_id)

func configure_team(p_player_count: int, p_difficulty: int, p_map_id: StringName, p_character_id: StringName = DEFAULT_CHARACTER_ID) -> void:
	play_mode = &"team"
	player_count = clampi(p_player_count, 2, 8)
	bot_count = player_count - 1
	team_mode = true
	bot_difficulty = clampi(p_difficulty, GameConstants.BotDifficulty.EASY, GameConstants.BotDifficulty.EXTREME) as GameConstants.BotDifficulty
	selected_map_id = p_map_id
	selected_character_id = ActiveCharacterRoster.normalize_id(p_character_id)

func configure_local(p_map_id: StringName, p_character_id: StringName = DEFAULT_CHARACTER_ID) -> void:
	play_mode = &"local"
	bot_count = 0
	player_count = 2
	team_mode = false
	selected_map_id = p_map_id
	selected_character_id = ActiveCharacterRoster.normalize_id(p_character_id)

func configure_boss(_p_map_id: StringName, p_character_id: StringName = DEFAULT_CHARACTER_ID) -> void:
	play_mode = &"boss"
	bot_count = 0
	player_count = 1
	team_mode = true
	selected_map_id = &"pirate_harbor"
	selected_character_id = ActiveCharacterRoster.normalize_id(p_character_id)
