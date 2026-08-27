extends Node

signal connection_status_changed(is_connected: bool)

const CONFIG_PATH: String = "res://server_config.json"
const FALLBACK_HOST: String = "127.0.0.1"
const FALLBACK_PORT: int = 7777
const MAX_CLIENTS: int = 8

var DEFAULT_HOST: String = "127.0.0.1"
var DEFAULT_PORT: int = 7777
var SERVER_REGION: String = "vn"
var USE_TLS: bool = false

var peer: WebSocketMultiplayerPeer
var is_server_active: bool = false
var is_client_active: bool = false
var connected_peers: Array[int] = []
var active_server_port: int = -1

func _ready() -> void:
	_load_config()
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)

func _load_config() -> void:
	if not FileAccess.file_exists(CONFIG_PATH):
		push_warning("[NetworkManager] server_config.json not found, using defaults.")
		return
	var file := FileAccess.open(CONFIG_PATH, FileAccess.READ)
	if file == null:
		return
	var text := file.get_as_text()
	file.close()
	var json := JSON.new()
	var error := json.parse(text)
	if error != OK:
		push_error("[NetworkManager] Failed to parse server_config.json: %s" % json.get_error_message())
		return
	var data: Dictionary = json.data
	if data.has("client"):
		var client_cfg: Dictionary = data["client"]
		DEFAULT_HOST = str(client_cfg.get("default_host", FALLBACK_HOST))
		DEFAULT_PORT = int(client_cfg.get("default_port", FALLBACK_PORT))
		USE_TLS = bool(client_cfg.get("use_tls", false))
	if data.has("server"):
		var server_cfg: Dictionary = data["server"]
		SERVER_REGION = str(server_cfg.get("region", "vn"))
	print("[NetworkManager] Config loaded: server=%s:%d region=%s" % [DEFAULT_HOST, DEFAULT_PORT, SERVER_REGION])

func is_connected_to_server() -> bool:
	if is_server_active:
		return true
	if is_client_active and peer != null:
		return peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED
	return false

func start_host(port: int = DEFAULT_PORT, max_clients: int = MAX_CLIENTS) -> bool:
	if is_server_active and peer != null and multiplayer.has_multiplayer_peer() and active_server_port == port:
		var status := peer.get_connection_status()
		if status != MultiplayerPeer.CONNECTION_DISCONNECTED:
			return true

	if peer != null:
		peer.close()
		multiplayer.multiplayer_peer = null
		peer = null
		is_server_active = false
		is_client_active = false

	peer = WebSocketMultiplayerPeer.new()
	var error = peer.create_server(port, "*", null)
	if error != OK:
		push_error("[NetworkManager] Failed to create WebSocket server on port %d: %s" % [port, str(error)])
		peer = null
		is_server_active = false
		active_server_port = -1
		connection_status_changed.emit(false)
		return false

	multiplayer.multiplayer_peer = peer
	is_server_active = true
	is_client_active = false
	active_server_port = port
	connected_peers.clear()
	connected_peers.append(1)
	print("[NetworkManager] WebSocket server started on port %d" % port)
	connection_status_changed.emit(true)
	return true

func join_server(ip: String = DEFAULT_HOST, port: int = DEFAULT_PORT) -> bool:
	if peer != null:
		peer.close()
		multiplayer.multiplayer_peer = null
		peer = null
		is_client_active = false
		active_server_port = -1

	peer = WebSocketMultiplayerPeer.new()
	var protocol := "wss" if USE_TLS else "ws"
	var url := "%s://%s:%d" % [protocol, ip, port]
	var tls_options: TLSOptions = null
	if USE_TLS:
		tls_options = TLSOptions.client()
	var error = peer.create_client(url, tls_options)
	if error != OK:
		push_error("[NetworkManager] Failed to connect to %s: %s" % [url, str(error)])
		peer = null
		connection_status_changed.emit(false)
		return false

	multiplayer.multiplayer_peer = peer
	is_server_active = false
	is_client_active = true
	print("[NetworkManager] Connecting to %s..." % url)
	return true

func connect_to_default_server() -> bool:
	return join_server(DEFAULT_HOST, DEFAULT_PORT)

func disconnect_network() -> void:
	if peer != null:
		peer.close()
		multiplayer.multiplayer_peer = null
	is_server_active = false
	is_client_active = false
	active_server_port = -1
	connected_peers.clear()
	connection_status_changed.emit(false)

func is_peer_connected(peer_id: int) -> bool:
	if not multiplayer.has_multiplayer_peer() or peer == null:
		return false
	if peer_id == 1:
		if is_server_active:
			return true
		if is_client_active:
			return peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED
		return false
	if not is_server_active:
		return false
	return Array(multiplayer.get_peers()).has(peer_id)

func _on_peer_connected(id: int) -> void:
	print("[NetworkManager] Peer connected: %d" % id)
	if not connected_peers.has(id):
		connected_peers.append(id)
	if has_node("/root/EventBus"):
		get_node("/root/EventBus").network_connected.emit(id)

func _on_peer_disconnected(id: int) -> void:
	print("[NetworkManager] Peer disconnected: %d" % id)
	connected_peers.erase(id)
	if has_node("/root/EventBus"):
		get_node("/root/EventBus").network_disconnected.emit(id)

func _on_connected_to_server() -> void:
	var local_id = multiplayer.get_unique_id()
	print("[NetworkManager] Successfully connected to server. Local peer ID: %d" % local_id)
	connection_status_changed.emit(true)
	if has_node("/root/EventBus"):
		get_node("/root/EventBus").network_connected.emit(local_id)

func _on_connection_failed() -> void:
	if peer != null and peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
		print("[NetworkManager] Ignoring stale connection_failed signal (already connected).")
		return
	push_error("[NetworkManager] Connection to server failed.")
	disconnect_network()

func _on_server_disconnected() -> void:
	push_warning("[NetworkManager] Server disconnected.")
	disconnect_network()
