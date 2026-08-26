extends Node

signal room_list_updated(rooms)
signal room_joined(room_data)
signal room_data_updated(room_data)
signal room_error(msg)
signal room_players_updated(players)
signal room_settings_updated(settings)
signal match_started()
signal chat_message_received(sender_name: String, message: String, is_system: bool)

var current_room_id: String = ""
var active_rooms: Dictionary = {}
var room_players: Dictionary = {} # client_id : identity, ready state, balloon and equipment IDs

func _ready() -> void:
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	if multiplayer.is_server():
		pass

@rpc("any_peer", "call_local")
func request_create_room(map_name: String, player_name: String = "Người chơi", char_id: String = "boom_mascot", balloon_skin: String = "skin_066", equipment: Dictionary = {}) -> void:
	if not multiplayer.is_server(): return
	var sender_id = multiplayer.get_remote_sender_id()
	if sender_id == 0: sender_id = 1
	
	var clean_name = player_name.strip_edges()
	if clean_name.is_empty(): clean_name = "Player " + str(sender_id)
	
	# Create a unique room ID
	var room_id = "ROOM_" + str(Time.get_ticks_msec())
	
	active_rooms[room_id] = {
		"id": room_id,
		"name": "Phòng của " + clean_name,
		"map": map_name,
		"mode": "solo",
		"bots": 0,
		"diff": 1,
		"host": sender_id,
		"players": [sender_id],
		"max_players": 8,
		"state": "WAITING"
	}
	
	room_players[sender_id] = {
		"name": clean_name,
		"char_id": str(ActiveCharacterRoster.normalize_id(StringName(char_id))),
		"char_idx": 0,
		"color_idx": 0,
		"is_ready": true,
		"balloon_skin": balloon_skin,
		"equipment": _validated_equipment_for_peer(sender_id, equipment),
	}
	
	# Send success back to creator
	if sender_id == 1:
		receive_join_room(active_rooms[room_id])
	else:
		rpc_id(sender_id, "receive_join_room", active_rooms[room_id])
	
	# Broadcast new room list to everyone in lobby
	broadcast_room_list()
	_broadcast_room_players(room_id)

@rpc("any_peer", "call_local")
func request_join_room(room_id: String, player_name: String = "Người chơi", char_id: String = "boom_mascot", balloon_skin: String = "skin_066", equipment: Dictionary = {}) -> void:
	if not multiplayer.is_server(): return
	var sender_id = multiplayer.get_remote_sender_id()
	if sender_id == 0: sender_id = 1
	
	if not active_rooms.has(room_id):
		if sender_id == 1:
			receive_room_error("Phòng không tồn tại!")
		else:
			rpc_id(sender_id, "receive_room_error", "Phòng không tồn tại!")
		return
		
	var room = active_rooms[room_id]
	if room.players.size() >= room.max_players:
		if sender_id == 1:
			receive_room_error("Phòng đã đầy!")
		else:
			rpc_id(sender_id, "receive_room_error", "Phòng đã đầy!")
		return
		
	if room.state != "WAITING":
		if sender_id == 1:
			receive_room_error("Phòng đang trong trận!")
		else:
			rpc_id(sender_id, "receive_room_error", "Phòng đang trong trận!")
		return
		
	if not (sender_id in room.players):
		room.players.append(sender_id)
		
	var clean_name = player_name.strip_edges()
	if clean_name.is_empty(): clean_name = "Player " + str(sender_id)

	room_players[sender_id] = {
		"name": clean_name,
		"char_id": str(ActiveCharacterRoster.normalize_id(StringName(char_id))),
		"char_idx": 0,
		"color_idx": 0,
		"is_ready": false,
		"balloon_skin": balloon_skin,
		"equipment": _validated_equipment_for_peer(sender_id, equipment),
	}
		
	var settings = {
		"map": room.get("map", "training_plaza"),
		"mode": room.get("mode", "solo"),
		"bots": room.get("bots", 0),
		"diff": room.get("diff", 1)
	}
	
	if sender_id == 1:
		receive_join_room(room)
		receive_room_settings(settings)
	else:
		rpc_id(sender_id, "receive_join_room", room)
		rpc_id(sender_id, "receive_room_settings", settings)
	
	broadcast_room_list()
	# Notify everyone in the room about the new player
	_broadcast_room_players(room_id)

@rpc("any_peer", "call_local")
func request_room_sync(room_id: String = "") -> void:
	if not multiplayer.is_server(): return
	var sender_id = multiplayer.get_remote_sender_id()
	if sender_id == 0: sender_id = 1
	
	var target_room_id = room_id
	if target_room_id == "":
		for rid in active_rooms:
			if sender_id in active_rooms[rid].players:
				target_room_id = rid
				break
				
	if target_room_id == "" or not active_rooms.has(target_room_id): return
	
	var room = active_rooms[target_room_id]
	if room.host == sender_id and room.state == "PLAYING":
		room.state = "WAITING"
		broadcast_room_list()
		
	var settings = {
		"map": room.get("map", "training_plaza"),
		"mode": room.get("mode", "solo"),
		"bots": room.get("bots", 0),
		"diff": room.get("diff", 1)
	}
	
	if sender_id == 1:
		receive_room_data(room)
		receive_room_settings(settings)
	else:
		rpc_id(sender_id, "receive_room_data", room)
		rpc_id(sender_id, "receive_room_settings", settings)
		
	_broadcast_room_players(target_room_id)

@rpc("any_peer", "call_local")
func request_room_list() -> void:
	if not multiplayer.is_server(): return
	var sender_id = multiplayer.get_remote_sender_id()
	if sender_id == 0: sender_id = 1
	if sender_id == 1:
		receive_room_list(active_rooms)
	else:
		rpc_id(sender_id, "receive_room_list", active_rooms)

@rpc("authority", "call_local")
func receive_room_list(rooms: Dictionary) -> void:
	active_rooms = rooms
	room_list_updated.emit(active_rooms)

@rpc("authority", "call_local")
func receive_join_room(room_data: Dictionary) -> void:
	current_room_id = room_data.id
	active_rooms[room_data.id] = room_data
	room_joined.emit(room_data)

@rpc("authority", "call_local")
func receive_room_data(room_data: Dictionary) -> void:
	current_room_id = room_data.get("id", current_room_id)
	active_rooms[current_room_id] = room_data
	room_data_updated.emit(room_data)

@rpc("authority", "call_local")
func receive_room_error(msg: String) -> void:
	room_error.emit(msg)

func broadcast_room_list() -> void:
	if not multiplayer.is_server(): return
	rpc("receive_room_list", active_rooms)

func _on_peer_disconnected(id: int) -> void:
	if not multiplayer.is_server(): return
	_remove_player_from_rooms(id)

@rpc("any_peer", "call_local")
func request_leave_room() -> void:
	if not multiplayer.is_server(): return
	var sender_id = multiplayer.get_remote_sender_id()
	if sender_id == 0: sender_id = 1
	_remove_player_from_rooms(sender_id)

func _remove_player_from_rooms(player_id: int) -> void:
	var rooms_changed = false
	var empty_rooms = []
	
	for room_id in active_rooms:
		var room = active_rooms[room_id]
		if player_id in room.players:
			room.players.erase(player_id)
			if room_players.has(player_id):
				room_players.erase(player_id)
			
			if room.players.is_empty():
				empty_rooms.append(room_id)
			else:
				if room.host == player_id:
					room.host = room.players[0]
				_broadcast_room_players(room_id)
			rooms_changed = true
			
	for room_id in empty_rooms:
		active_rooms.erase(room_id)
		
	if rooms_changed:
		broadcast_room_list()

# ---- ROOM SYNC LOGIC ----

@rpc("any_peer", "call_local")
func update_player_status(player_name: String, char_identifier: Variant, color_idx: int, is_ready: bool, balloon_skin: String = "skin_066", equipment: Dictionary = {}) -> void:
	if not multiplayer.is_server(): return
	var sender_id = multiplayer.get_remote_sender_id()
	if sender_id == 0: sender_id = 1
	
	# Find which room this player is in
	var room_id = ""
	for rid in active_rooms:
		if sender_id in active_rooms[rid].players:
			room_id = rid
			break
			
	if room_id == "": return
	
	var char_id = ""
	var char_idx = 0
	if char_identifier is String:
		char_id = str(ActiveCharacterRoster.normalize_id(StringName(char_identifier)))
	elif char_identifier is int:
		char_idx = char_identifier
		char_id = str(ActiveCharacterRoster.id_for_index(char_idx))
	
	var is_host = (active_rooms[room_id].host == sender_id)
	
	# Store player status
	room_players[sender_id] = {
		"name": player_name,
		"char_id": char_id,
		"char_idx": char_idx,
		"color_idx": color_idx,
		"is_ready": is_ready if not is_host else true,
		"balloon_skin": balloon_skin,
		"equipment": _validated_equipment_for_peer(sender_id, equipment),
	}
	
	_broadcast_room_players(room_id)

func _broadcast_room_players(room_id: String) -> void:
	if not multiplayer.is_server(): return
	if not active_rooms.has(room_id): return
	var room = active_rooms[room_id]
	var players_data = {}
	for pid in room.players:
		if room_players.has(pid):
			players_data[pid] = room_players[pid]
		else:
			players_data[pid] = { "name": "Player " + str(pid), "char_id": "boom_mascot", "char_idx": 0, "color_idx": 0, "is_ready": (pid == room.host), "equipment": CosmeticRegistry.default_equipment() }
			
	for pid in room.players:
		if pid == 1:
			receive_room_players(players_data)
			receive_room_data(room)
		else:
			rpc_id(pid, "receive_room_players", players_data)
			rpc_id(pid, "receive_room_data", room)

@rpc("authority", "call_local")
func receive_room_players(players_data: Dictionary) -> void:
	room_players = players_data
	room_players_updated.emit(players_data)

@rpc("any_peer", "call_local")
func request_update_equipment(equipment: Dictionary) -> void:
	if not multiplayer.is_server(): return
	var sender_id := multiplayer.get_remote_sender_id()
	if sender_id == 0: sender_id = 1
	var room_id := _room_id_for_player(sender_id)
	if room_id.is_empty() or active_rooms[room_id].get("state", "WAITING") != "WAITING":
		return
	if not room_players.has(sender_id):
		return
	room_players[sender_id]["equipment"] = _validated_equipment_for_peer(sender_id, equipment)
	_broadcast_room_players(room_id)

func _room_id_for_player(player_id: int) -> String:
	for room_id in active_rooms:
		if player_id in active_rooms[room_id].get("players", []):
			return str(room_id)
	return ""

func _validated_equipment_for_peer(peer_id: int, proposed: Dictionary) -> Dictionary:
	if has_node("/root/AccountDatabase"):
		var user_id := int(AccountDatabase.peer_user_ids.get(peer_id, 0))
		if user_id > 0:
			return AccountDatabase._equipment_for_user(user_id)
	if peer_id == 1 and has_node("/root/GameSession"):
		return CosmeticRegistry.sanitize_equipment(proposed, GameSession.owned_cosmetics)
	return CosmeticRegistry.sanitize_equipment(proposed, CosmeticRegistry.all_default_owned_ids())

func reset_match_state_to_lobby() -> void:
	if current_room_id != "" and active_rooms.has(current_room_id):
		var room = active_rooms[current_room_id]
		room.state = "WAITING"
		for pid in room.players:
			if room_players.has(pid):
				room_players[pid]["is_ready"] = (pid == room.host)
		if multiplayer.is_server():
			broadcast_room_list()
			_broadcast_room_players(current_room_id)
		else:
			rpc_id(1, "request_reset_room_state", current_room_id)

@rpc("any_peer", "call_local")
func request_reset_room_state(room_id: String) -> void:
	if not multiplayer.is_server(): return
	if active_rooms.has(room_id):
		var room = active_rooms[room_id]
		room.state = "WAITING"
		for pid in room.players:
			if room_players.has(pid):
				room_players[pid]["is_ready"] = (pid == room.host)
		broadcast_room_list()
		_broadcast_room_players(room_id)

@rpc("any_peer", "call_local")
func request_start_match() -> void:
	if not multiplayer.is_server(): return
	var sender_id = multiplayer.get_remote_sender_id()
	if sender_id == 0: sender_id = 1
	
	var room_id = ""
	for rid in active_rooms:
		if active_rooms[rid].host == sender_id:
			room_id = rid
			break
			
	if room_id == "": return
	
	var room = active_rooms[room_id]
	# Server check: Ensure all non-host real connected human peers in the room are ready
	var peers := multiplayer.get_peers()
	for pid in room.players:
		if pid != room.host and pid in peers:
			var p_data = room_players.get(pid, {})
			if not p_data.get("is_ready", false):
				return # Cannot start match until all real connected peers are ready
				
	# Freeze an immutable equipment/player snapshot before any ready-state reset.
	# Match scenes consume this copy so a late lobby edit cannot alter an active match.
	var match_snapshot: Dictionary = {}
	for pid in room.players:
		if room_players.has(pid):
			match_snapshot[pid] = room_players[pid].duplicate(true)
	room["match_player_snapshot"] = match_snapshot

	# Reset ready states for next match
	for pid in room.players:
		if pid != room.host and room_players.has(pid):
			room_players[pid]["is_ready"] = false
			
	room.state = "PLAYING"
	broadcast_room_list()
	_broadcast_room_players(room_id)
	
	for pid in room.players:
		if pid == 1:
			receive_start_match()
		else:
			rpc_id(pid, "receive_start_match")

@rpc("authority", "call_local")
func receive_start_match() -> void:
	match_started.emit()


@rpc("any_peer", "call_local")
func request_update_settings(map_id: String, mode: String, bots: int, diff: int) -> void:
	if not multiplayer.is_server(): return
	var sender_id = multiplayer.get_remote_sender_id()
	if sender_id == 0: sender_id = 1
	
	var room_id = ""
	for rid in active_rooms:
		if sender_id in active_rooms[rid].players:
			room_id = rid
			break
			
	if room_id == "" or active_rooms[room_id].host != sender_id: return
	
	active_rooms[room_id]["map"] = map_id
	active_rooms[room_id]["mode"] = mode
	active_rooms[room_id]["bots"] = bots
	active_rooms[room_id]["diff"] = diff
	
	var settings = {
		"map": map_id,
		"mode": mode,
		"bots": bots,
		"diff": diff
	}
	
	for pid in active_rooms[room_id].players:
		if pid == 1:
			receive_room_settings(settings)
		else:
			rpc_id(pid, "receive_room_settings", settings)

@rpc("authority", "call_local")
func receive_room_settings(settings: Dictionary) -> void:
	if current_room_id != "":
		if not active_rooms.has(current_room_id):
			active_rooms[current_room_id] = {}
		active_rooms[current_room_id]["map"] = settings.map
		active_rooms[current_room_id]["mode"] = settings.mode
		active_rooms[current_room_id]["bots"] = settings.bots
		active_rooms[current_room_id]["diff"] = settings.diff
		room_settings_updated.emit(settings)


signal match_player_state_received(player_id: int, pos: Vector2, state: int, dir: int, is_alive: bool, is_in_bubble: bool)

@rpc("any_peer", "call_remote", "unreliable")
func relay_player_state(room_id: String, player_id: int, pos: Vector2, state: int, dir: int, is_alive: bool, is_in_bubble: bool) -> void:
	if not multiplayer.is_server(): return
	var sender = multiplayer.get_remote_sender_id()
	if sender == 0: sender = 1
	
	var room = active_rooms.get(room_id)
	if room != null:
		for p in room.players:
			if p != sender and p != 1:
				rpc_id(p, "receive_player_state", player_id, pos, state, dir, is_alive, is_in_bubble)
				
	if multiplayer.get_unique_id() == 1 and DisplayServer.get_name() != "headless":
		if sender != 1:
			receive_player_state(player_id, pos, state, dir, is_alive, is_in_bubble)

@rpc("authority", "call_remote", "unreliable")
func receive_player_state(player_id: int, pos: Vector2, state: int, dir: int, is_alive: bool, is_in_bubble: bool) -> void:
	match_player_state_received.emit(player_id, pos, state, dir, is_alive, is_in_bubble)


@rpc("any_peer", "call_remote")
func relay_place_balloon(room_id: String, player_id: int, cell: Vector2i, skin_id: String = "skin_066") -> void:
	if not multiplayer.is_server(): return
	var sender = multiplayer.get_remote_sender_id()
	if sender == 0: sender = 1
	
	var room = active_rooms.get(room_id)
	if room != null:
		for p in room.players:
			if p != sender and p != 1:
				rpc_id(p, "receive_place_balloon", player_id, cell, skin_id)
				
	if multiplayer.get_unique_id() == 1 and DisplayServer.get_name() != "headless":
		if sender != 1:
			receive_place_balloon(player_id, cell, skin_id)

@rpc("authority", "call_remote")
func receive_place_balloon(player_id: int, cell: Vector2i, skin_id: String = "skin_066") -> void:
	var match_arena = get_node_or_null("/root/MatchArena")
	if match_arena != null and match_arena.has_method("get_player"):
		var p = match_arena.get_player(player_id)
		if p != null:
			p.balloon_skin_id = StringName(skin_id)
			if p.has_method("_do_place_balloon_at"):
				p._do_place_balloon_at(cell)
			elif p.has_method("_do_place_balloon"):
				p._do_place_balloon()

@rpc("any_peer", "call_local", "reliable")
func send_chat_message(message: String) -> void:
	if not multiplayer.is_server():
		return
	var sender_id = multiplayer.get_remote_sender_id()
	if sender_id == 0: sender_id = 1
	var p_data = room_players.get(sender_id, {})
	var sender_name: String = p_data.get("name", "Người chơi")
	var clean_msg = message.strip_edges()
	if clean_msg.is_empty(): return
	
	# Find target room of this sender
	var target_room_id := ""
	for rid in active_rooms:
		if sender_id in active_rooms[rid].players:
			target_room_id = rid
			break
	if target_room_id == "" and current_room_id != "" and active_rooms.has(current_room_id):
		target_room_id = current_room_id
		
	var room_data: Dictionary = active_rooms.get(target_room_id, {})
	var players: Array = room_data.get("players", [1])
	for pid in players:
		if pid == 1:
			receive_chat_message(sender_name, clean_msg, false)
		else:
			rpc_id(pid, "receive_chat_message", sender_name, clean_msg, false)

@rpc("authority", "call_local", "reliable")
func receive_chat_message(sender_name: String, message: String, is_system: bool = false) -> void:
	chat_message_received.emit(sender_name, message, is_system)
