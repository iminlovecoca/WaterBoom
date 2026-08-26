extends Node

const DATABASE_PATH := "user://boom_water_accounts"
const HASH_ROUNDS := 12000
const USERNAME_PATTERN := "^[A-Za-z0-9_]{3,20}$"

const SCHEMA_SQL := """
PRAGMA foreign_keys = ON;
PRAGMA journal_mode = WAL;

CREATE TABLE IF NOT EXISTS schema_migrations (
    version INTEGER PRIMARY KEY,
    applied_at INTEGER NOT NULL
);

CREATE TABLE IF NOT EXISTS users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    username TEXT NOT NULL COLLATE NOCASE UNIQUE,
    nickname TEXT NOT NULL,
    password_hash TEXT NOT NULL,
    password_salt TEXT NOT NULL,
    cokecy INTEGER NOT NULL DEFAULT 500 CHECK (cokecy >= 0),
    level INTEGER NOT NULL DEFAULT 1 CHECK (level >= 1),
    experience INTEGER NOT NULL DEFAULT 0 CHECK (experience >= 0),
    selected_character_id TEXT NOT NULL DEFAULT 'boom_mascot',
    selected_balloon_skin TEXT NOT NULL DEFAULT 'classic',
    created_at INTEGER NOT NULL,
    last_login_at INTEGER
);

CREATE INDEX IF NOT EXISTS idx_users_username ON users(username COLLATE NOCASE);

CREATE TABLE IF NOT EXISTS user_balloon_skins (
    user_id INTEGER NOT NULL,
    skin_id TEXT NOT NULL,
    unlocked_at INTEGER NOT NULL,
    PRIMARY KEY (user_id, skin_id),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS user_cosmetics (
    user_id INTEGER NOT NULL,
    cosmetic_id TEXT NOT NULL,
    unlocked_at INTEGER NOT NULL,
    PRIMARY KEY (user_id, cosmetic_id),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS user_equipment (
    user_id INTEGER PRIMARY KEY,
    head_accessory_id TEXT NOT NULL DEFAULT '',
    flag_id TEXT NOT NULL DEFAULT 'flag_default_water',
    player_frame_id TEXT NOT NULL DEFAULT 'frame_default_aqua',
    player_background_id TEXT NOT NULL DEFAULT 'background_default_aqua',
    updated_at INTEGER NOT NULL DEFAULT 0,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);
"""

var _db
var ready_ok := false
var last_error := ""
var current_user_id := 0
var peer_user_ids: Dictionary = {}
var last_logout_reason: String = ""

signal auth_result_received(result: Dictionary)
signal session_terminated(reason: String)
signal profile_saved_received(success: bool)
signal skin_bought_received(success: bool)
signal cokecy_fetched_received(cokecy: int)
signal equipment_saved_received(success: bool, equipment: Dictionary)
signal cosmetic_purchase_received(success: bool, cosmetic_id: StringName, balance: int, message: String)

func _ready() -> void:
	ready_ok = _open_and_migrate()
	if multiplayer:
		multiplayer.peer_disconnected.connect(_on_peer_disconnected)

func _on_peer_disconnected(id: int) -> void:
	if peer_user_ids.has(id):
		peer_user_ids.erase(id)

func _open_and_migrate() -> bool:
	if not ClassDB.class_exists(&"SQLite"):
		last_error = "SQLite GDExtension chưa được nạp."
		push_error(last_error)
		return false
	_db = ClassDB.instantiate(&"SQLite")
	_db.path = DATABASE_PATH
	_db.verbosity_level = 1
	if not _db.open_db():
		last_error = "Không thể mở cơ sở dữ liệu tài khoản."
		return false
	for statement in SCHEMA_SQL.split(";"):
		var cleaned := statement.strip_edges()
		if not cleaned.is_empty():
			_db.query(cleaned)
	_ensure_user_progression_columns()
	_normalize_character_selections()
	_seed_cosmetic_defaults_for_existing_users()
	_db.query("INSERT OR IGNORE INTO schema_migrations(version, applied_at) VALUES(1, %d);" % int(Time.get_unix_time_from_system()))
	_db.query("INSERT OR IGNORE INTO schema_migrations(version, applied_at) VALUES(2, %d);" % int(Time.get_unix_time_from_system()))
	_db.query("INSERT OR IGNORE INTO schema_migrations(version, applied_at) VALUES(3, %d);" % int(Time.get_unix_time_from_system()))
	_db.query("INSERT OR IGNORE INTO schema_migrations(version, applied_at) VALUES(4, %d);" % int(Time.get_unix_time_from_system()))
	ready_ok = true
	last_error = ""
	return true

func _ensure_user_progression_columns() -> void:
	# CREATE TABLE IF NOT EXISTS cannot update databases created by older builds.
	# Inspect the live schema and add progression columns exactly once.
	var existing: Dictionary = {}
	if _db.query("PRAGMA table_info(users);"):
		for column in _db.query_result:
			existing[str(column.get("name", ""))] = true
	if not existing.has("level"):
		_db.query("ALTER TABLE users ADD COLUMN level INTEGER NOT NULL DEFAULT 1 CHECK (level >= 1);")
	if not existing.has("experience"):
		_db.query("ALTER TABLE users ADD COLUMN experience INTEGER NOT NULL DEFAULT 0 CHECK (experience >= 0);")

func _normalize_character_selections() -> void:
	# Existing profiles may still contain IDs from the retired roster. Keep the
	# rows and progress intact, but make the active character deterministic.
	_db.query("UPDATE users SET selected_character_id = 'boom_mascot' WHERE selected_character_id NOT IN ('boom_mascot', 'cloud_bunny', 'shadow_ninja', 'aqua_pacifier') OR selected_character_id IS NULL OR selected_character_id = '';")

func _seed_cosmetic_defaults_for_existing_users() -> void:
	var now := int(Time.get_unix_time_from_system())
	for cosmetic_id in ["flag_default_water", "frame_default_aqua", "background_default_aqua"]:
		_db.query("INSERT OR IGNORE INTO user_cosmetics(user_id, cosmetic_id, unlocked_at) SELECT id, '%s', %d FROM users;" % [cosmetic_id, now])
	_db.query("INSERT OR IGNORE INTO user_equipment(user_id, updated_at) SELECT id, %d FROM users;" % now)

# --- LOCAL DB OPERATIONS ---

func register_account(username: String, password: String) -> Dictionary:
	return _register_account_local(username, password)

func authenticate(username: String, password: String) -> Dictionary:
	var result := _authenticate_local(username, password)
	# Direct/local API calls own their local session. Server-side RPC validation
	# uses _authenticate_local() directly and must never mutate this global ID.
	if result.get("ok", false):
		current_user_id = int(result["user"]["id"])
	return result

func _register_account_local(username: String, password: String) -> Dictionary:
	var clean_username := username.strip_edges()
	var validation := _validate_credentials(clean_username, password)
	if not validation.is_empty():
		return {"ok": false, "message": validation}
	if not ready_ok:
		return {"ok": false, "message": last_error}
	if not _find_user(clean_username).is_empty():
		return {"ok": false, "message": "Tên tài khoản đã tồn tại."}
	var salt := Marshalls.raw_to_base64(Crypto.new().generate_random_bytes(16))
	var now := int(Time.get_unix_time_from_system())
	var row := {
		"username": clean_username,
		"nickname": clean_username,
		"password_hash": _hash_password(password, salt),
		"password_salt": salt,
		"cokecy": 500,
		"level": 1,
		"experience": 0,
		"selected_character_id": "boom_mascot",
		"selected_balloon_skin": "skin_066",
		"created_at": now,
	}
	if not _db.insert_row("users", row):
		return {"ok": false, "message": "Không thể tạo tài khoản."}
	var user := _find_user(clean_username)
	_db.insert_row("user_balloon_skins", {"user_id": int(user["id"]), "skin_id": "skin_066", "unlocked_at": now})
	_seed_default_cosmetics_for_user(int(user["id"]), now)
	return {"ok": true, "message": "Tạo tài khoản thành công.", "user": _decorate_user(user)}

func _authenticate_local(username: String, password: String) -> Dictionary:
	var clean_username := username.strip_edges()
	if not ready_ok:
		return {"ok": false, "message": last_error}
	if not _valid_username(clean_username):
		return {"ok": false, "message": "Tài khoản hoặc mật khẩu không đúng."}
	var user := _find_user(clean_username)
	if user.is_empty():
		return {"ok": false, "message": "Tài khoản không tồn tại."}
	var actual := _hash_password(password, str(user["password_salt"]))
	if not _constant_time_equal(actual, str(user["password_hash"])):
		return {"ok": false, "message": "Mật khẩu không chính xác."}
	var uid = int(user["id"])
	_db.update_rows("users", "id = %d" % uid, {"last_login_at": int(Time.get_unix_time_from_system())})
	return {"ok": true, "message": "Đăng nhập thành công!", "user": _decorate_user(user)}

func _seed_default_cosmetics_for_user(user_id: int, now: int = 0) -> void:
	if now <= 0:
		now = int(Time.get_unix_time_from_system())
	for cosmetic_id in ["flag_default_water", "frame_default_aqua", "background_default_aqua"]:
		_db.query("INSERT OR IGNORE INTO user_cosmetics(user_id, cosmetic_id, unlocked_at) VALUES(%d, '%s', %d);" % [user_id, cosmetic_id, now])
	_db.query("INSERT OR IGNORE INTO user_equipment(user_id, updated_at) VALUES(%d, %d);" % [user_id, now])

func _decorate_user(user: Dictionary) -> Dictionary:
	if user.is_empty():
		return user
	var result := user.duplicate(true)
	var uid := int(result.get("id", 0))
	_seed_default_cosmetics_for_user(uid)
	result["owned_cosmetics"] = _unlocked_cosmetics_for_user(uid)
	result["equipment"] = _equipment_for_user(uid)
	return result

func _unlocked_cosmetics_for_user(user_id: int) -> Array[String]:
	var result: Array[String] = []
	for row in _db.select_rows("user_cosmetics", "user_id = %d" % user_id, ["cosmetic_id"]):
		result.append(str(row.get("cosmetic_id", "")))
	return result

func _equipment_for_user(user_id: int) -> Dictionary:
	var rows: Array = _db.select_rows("user_equipment", "user_id = %d" % user_id, ["*"])
	if rows.is_empty():
		return CosmeticRegistry.default_equipment()
	var row: Dictionary = rows[0]
	return CosmeticRegistry.sanitize_equipment({
		"head_accessory": str(row.get("head_accessory_id", "")),
		"flag": str(row.get("flag_id", "flag_default_water")),
		"player_frame": str(row.get("player_frame_id", "frame_default_aqua")),
		"player_background": str(row.get("player_background_id", "background_default_aqua")),
	}, _unlocked_cosmetics_for_user(user_id))

# --- CENTRALIZED AUTH RPCs ---

@rpc("any_peer", "call_local")
func request_authenticate(username: String, password: String) -> void:
	if not multiplayer.is_server(): return
	var sender = multiplayer.get_remote_sender_id()
	if sender == 0: sender = 1
	# An authentication attempt replaces any previous identity for this peer.
	# A failed attempt must not retain access to the old account.
	peer_user_ids.erase(sender)
	var result = _authenticate_local(username, password)
	if result["ok"]:
		var uid = int(result["user"]["id"])
		var old_peers: Array[int] = []
		for pid in peer_user_ids:
			if peer_user_ids[pid] == uid and pid != sender:
				old_peers.append(pid)
		
		for old_pid in old_peers:
			peer_user_ids.erase(old_pid)
			if has_node("/root/RoomManager"):
				RoomManager._remove_player_from_rooms(old_pid)
			if old_pid != 1 and _can_send_to_peer(old_pid):
				rpc_id(old_pid, "receive_force_logout", "Tài khoản của bạn đã được đăng nhập trên thiết bị khác.")
		
		peer_user_ids[sender] = uid
	if _can_send_to_peer(sender):
		rpc_id(sender, "receive_auth_result", result)

@rpc("any_peer", "call_local")
func request_register(username: String, password: String) -> void:
	if not multiplayer.is_server(): return
	var sender = multiplayer.get_remote_sender_id()
	if sender == 0: sender = 1
	var result = _register_account_local(username, password)
	if result["ok"]:
		peer_user_ids[sender] = int(result["user"]["id"])
	if _can_send_to_peer(sender):
		rpc_id(sender, "receive_auth_result", result)

func _can_send_to_peer(peer_id: int) -> bool:
	if has_node("/root/NetworkManager"):
		return NetworkManager.is_peer_connected(peer_id)
	# AccountDatabase smoke scenes can run without NetworkManager's autoload.
	return multiplayer.is_server() and (peer_id == 1 or Array(multiplayer.get_peers()).has(peer_id))

@rpc("authority", "call_local")
func receive_auth_result(result: Dictionary) -> void:
	if result["ok"]:
		current_user_id = int(result["user"]["id"])
	auth_result_received.emit(result)

@rpc("authority", "call_local")
func receive_force_logout(reason: String) -> void:
	current_user_id = 0
	last_logout_reason = reason
	session_terminated.emit(reason)
	if has_node("/root/NetworkManager"):
		NetworkManager.disconnect_network()
	get_tree().change_scene_to_file("res://scenes/login/Login.tscn")

@rpc("any_peer", "call_local")
func request_save_profile(_nickname: String, cokecy: int, level: int, experience: int, character_id: StringName, balloon_skin: StringName) -> void:
	if not multiplayer.is_server(): return
	var sender = multiplayer.get_remote_sender_id()
	if sender == 0: sender = 1
	var uid = peer_user_ids.get(sender, 0)
	if uid <= 0: return
	var active_character_id := ActiveCharacterRoster.normalize_id(character_id)
	var success = _db.update_rows("users", "id = %d" % uid, {
		"cokecy": maxi(cokecy, 0),
		"level": maxi(level, 1),
		"experience": maxi(experience, 0),
		"selected_character_id": str(active_character_id), "selected_balloon_skin": str(balloon_skin),
	})
	if _can_send_to_peer(sender):
		rpc_id(sender, "receive_profile_saved", success)

@rpc("authority", "call_local")
func receive_profile_saved(success: bool) -> void:
	profile_saved_received.emit(success)

@rpc("any_peer", "call_local")
func request_unlock_skin(skin_id: StringName) -> void:
	if not multiplayer.is_server(): return
	var sender = multiplayer.get_remote_sender_id()
	if sender == 0: sender = 1
	var uid = peer_user_ids.get(sender, 0)
	if uid <= 0: return
	var success = _db.insert_row("user_balloon_skins", {
		"user_id": uid,
		"skin_id": str(skin_id),
		"unlocked_at": int(Time.get_unix_time_from_system()),
	})
	if _can_send_to_peer(sender):
		rpc_id(sender, "receive_skin_unlocked", success)

@rpc("authority", "call_local")
func receive_skin_unlocked(success: bool) -> void:
	skin_bought_received.emit(success)

@rpc("any_peer", "call_local")
func request_equip_cosmetic(category: String, cosmetic_id: String) -> void:
	if not multiplayer.is_server(): return
	var sender := multiplayer.get_remote_sender_id()
	if sender == 0: sender = 1
	var uid := int(peer_user_ids.get(sender, 0))
	if uid <= 0: return
	var category_to_column := {
		"head_accessory": "head_accessory_id",
		"flag": "flag_id",
		"player_frame": "player_frame_id",
		"player_background": "player_background_id",
	}
	var success := false
	if category_to_column.has(category):
		var definition := CosmeticRegistry.get_definition(cosmetic_id)
		var is_clear_head := category == "head_accessory" and cosmetic_id.is_empty()
		var owns_item := is_clear_head or _unlocked_cosmetics_for_user(uid).has(cosmetic_id)
		var category_matches := is_clear_head or (definition != null and str(definition.category_id()) == category)
		if owns_item and category_matches:
			_seed_default_cosmetics_for_user(uid)
			success = _db.update_rows("user_equipment", "user_id = %d" % uid, {
				category_to_column[category]: cosmetic_id,
				"updated_at": int(Time.get_unix_time_from_system()),
			})
	var equipment := _equipment_for_user(uid)
	if sender == 1:
		receive_equipment_saved(success, equipment)
	else:
		if _can_send_to_peer(sender):
			rpc_id(sender, "receive_equipment_saved", success, equipment)

@rpc("authority", "call_local")
func receive_equipment_saved(success: bool, equipment: Dictionary) -> void:
	if success and has_node("/root/PlayerEquipmentService"):
		PlayerEquipmentService.apply_server_equipment(equipment)
	equipment_saved_received.emit(success, equipment)

@rpc("any_peer", "call_local")
func request_purchase_cosmetic(cosmetic_id: String) -> void:
	if not multiplayer.is_server(): return
	var sender := multiplayer.get_remote_sender_id()
	if sender == 0: sender = 1
	var uid := int(peer_user_ids.get(sender, 0))
	var result := _purchase_cosmetic_for_user(uid, cosmetic_id)
	var success := bool(result.get("success", false))
	var message := str(result.get("message", "Không thể mua vật phẩm."))
	var balance := int(result.get("balance", -1))
	if sender == 1:
		receive_cosmetic_purchase(success, StringName(cosmetic_id), balance, message)
	else:
		if _can_send_to_peer(sender):
			rpc_id(sender, "receive_cosmetic_purchase", success, StringName(cosmetic_id), balance, message)

func purchase_cosmetic_for_current_user(cosmetic_id: StringName) -> Dictionary:
	# Used by local/offline sessions and deterministic smoke tests. Networked
	# clients must keep using request_purchase_cosmetic() so the server remains
	# authoritative over currency and ownership.
	return _purchase_cosmetic_for_user(current_user_id, str(cosmetic_id))

func _purchase_cosmetic_for_user(uid: int, cosmetic_id: String) -> Dictionary:
	var result := {
		"success": false,
		"balance": -1,
		"message": "Phiên đăng nhập không hợp lệ.",
	}
	if not ready_ok or uid <= 0:
		return result

	var definition := CosmeticRegistry.get_definition(cosmetic_id)
	if definition == null:
		result.message = "Vật phẩm không tồn tại trên máy chủ."
		return result

	var rows: Array = _db.select_rows("users", "id = %d" % uid, ["cokecy"])
	if rows.is_empty():
		return result
	result.balance = int(rows[0].get("cokecy", 0))

	if _unlocked_cosmetics_for_user(uid).has(cosmetic_id) or definition.is_default:
		result.success = true
		result.message = "Đã sở hữu."
		return result
	if definition.price <= 0:
		result.message = "Vật phẩm không bán."
		return result
	if int(result.balance) < definition.price:
		result.message = "Không đủ Cokecy (thiếu %d)." % (definition.price - int(result.balance))
		return result

	# Keep the currency deduction and ownership insert atomic. Previously a
	# failed INSERT could still consume Cokecy, leaving a paid item locked.
	if not _db.query("BEGIN IMMEDIATE TRANSACTION;"):
		result.message = "Cửa hàng đang bận, vui lòng thử lại."
		return result
	var committed := false
	var latest_rows: Array = _db.select_rows("users", "id = %d" % uid, ["cokecy"])
	var latest_balance := int(latest_rows[0].get("cokecy", 0)) if not latest_rows.is_empty() else 0
	if latest_balance >= definition.price:
		var paid := bool(_db.query("UPDATE users SET cokecy = cokecy - %d WHERE id = %d AND cokecy >= %d;" % [definition.price, uid, definition.price]))
		if paid:
			var unlocked: bool = bool(_db.insert_row("user_cosmetics", {
				"user_id": uid,
				"cosmetic_id": cosmetic_id,
				"unlocked_at": int(Time.get_unix_time_from_system()),
			}))
			if unlocked:
				committed = bool(_db.query("COMMIT;"))
	if not committed:
		_db.query("ROLLBACK;")

	var after_rows: Array = _db.select_rows("users", "id = %d" % uid, ["cokecy"])
	result.balance = int(after_rows[0].get("cokecy", latest_balance)) if not after_rows.is_empty() else latest_balance
	result.success = committed
	result.message = "Mua thành công." if committed else "Không thể mở khóa vật phẩm."
	return result

@rpc("authority", "call_local")
func receive_cosmetic_purchase(success: bool, cosmetic_id: StringName, balance: int, message: String) -> void:
	if success and has_node("/root/GameSession"):
		if not GameSession.owned_cosmetics.has(cosmetic_id):
			GameSession.owned_cosmetics.append(cosmetic_id)
		if balance >= 0:
			GameSession.cokecy = balance
			GameSession.cokecy_changed.emit(balance)
	cosmetic_purchase_received.emit(success, cosmetic_id, balance, message)

@rpc("any_peer", "call_local")
func request_fetch_cokecy() -> void:
	if not multiplayer.is_server(): return
	var sender = multiplayer.get_remote_sender_id()
	if sender == 0: sender = 1
	var uid = peer_user_ids.get(sender, 0)
	var cokecy = -1
	if uid > 0:
		var rows: Array = _db.select_rows("users", "id = %d" % uid, ["cokecy"])
		if not rows.is_empty(): cokecy = int(rows[0]["cokecy"])
	if _can_send_to_peer(sender):
		rpc_id(sender, "receive_fetched_cokecy", cokecy)

@rpc("authority", "call_local")
func receive_fetched_cokecy(cokecy: int) -> void:
	cokecy_fetched_received.emit(cokecy)

# --- BACKWARD COMPATIBILITY & UTILS ---

func fetch_current_user_cokecy() -> int:
	if not ready_ok or current_user_id <= 0: return -1
	var rows: Array = _db.select_rows("users", "id = %d" % current_user_id, ["cokecy"])
	if rows.is_empty(): return -1
	return int(rows[0]["cokecy"])

func unlocked_skins_for_current_user() -> Array[StringName]:
	var result: Array[StringName] = []
	if not ready_ok or current_user_id <= 0: return result
	for row in _db.select_rows("user_balloon_skins", "user_id = %d" % current_user_id, ["skin_id"]):
		result.append(StringName(row["skin_id"]))
	return result

func unlocked_cosmetics_for_current_user() -> Array[StringName]:
	var result: Array[StringName] = []
	if not ready_ok or current_user_id <= 0: return result
	for cosmetic_id in _unlocked_cosmetics_for_user(current_user_id):
		result.append(StringName(cosmetic_id))
	return result

func equipment_for_current_user() -> Dictionary:
	if not ready_ok or current_user_id <= 0:
		return CosmeticRegistry.default_equipment()
	return _equipment_for_user(current_user_id)

func _find_user(username: String) -> Dictionary:
	var escaped := username.replace("'", "''")
	var rows: Array = _db.select_rows("users", "username = '%s' COLLATE NOCASE" % escaped, ["*"])
	return rows[0] if not rows.is_empty() else {}

func _validate_credentials(username: String, password: String) -> String:
	if not _valid_username(username):
		return "Tài khoản cần 3-20 ký tự, chỉ chữ, số hoặc dấu gạch dưới."
	if password.length() < 6:
		return "Mật khẩu cần ít nhất 6 ký tự."
	return ""

func _valid_username(username: String) -> bool:
	var regex := RegEx.new()
	regex.compile(USERNAME_PATTERN)
	return regex.search(username) != null

func _hash_password(password: String, salt: String) -> String:
	var value := (salt + ":" + password).sha256_text()
	for index in range(HASH_ROUNDS):
		value = (value + salt + str(index)).sha256_text()
	return value

func _constant_time_equal(left: String, right: String) -> bool:
	if left.length() != right.length():
		return false
	var difference := 0
	for index in range(left.length()):
		difference |= left.unicode_at(index) ^ right.unicode_at(index)
	return difference == 0
