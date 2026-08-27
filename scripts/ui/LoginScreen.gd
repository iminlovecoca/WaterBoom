class_name LoginScreen
extends Control

@onready var login_panel: Panel = %LoginPanel
@onready var account_input: LineEdit = %AccountInput
@onready var password_input: LineEdit = %PasswordInput
@onready var status_dot: Label = %StatusDot
@onready var status_label: Label = %StatusLabel
@onready var login_button: Button = %LoginButton
@onready var create_button: Button = %CreateButton
@onready var forgot_button: Button = %ForgotButton

@onready var ip_input: LineEdit = %IPInput
@onready var port_input: LineEdit = %PortInput

const AUTH_RESPONSE_TIMEOUT_SECONDS := 8.0

var auth_pending := false
var auth_request_serial := 0

func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	# Headless mode is also used by visual and smoke tests. Dedicated-server
	# startup must stay opt-in so UI scenes can be instantiated without taking
	# ownership of port 7777.
	if "--server" in args:
		var port := 7777
		for arg in args:
			if arg.begins_with("--port="):
				port = int(arg.trim_prefix("--port="))
		print("[DEDICATED SERVER] Starting WebSocket server on port %d..." % port)
		if has_node("/root/NetworkManager"):
			get_node("/root/NetworkManager").start_host(port, 8)
		get_tree().call_deferred("change_scene_to_file", "res://scenes/match/MatchArena.tscn")
		return

	SoundManager.play_bgm("res://assets/audio/music/login.mp3", true)
	if ip_input:
		ip_input.text = NetworkManager.DEFAULT_HOST
	if port_input:
		port_input.text = str(NetworkManager.DEFAULT_PORT)
	_apply_connection_overrides()
	_apply_styles()
	_setup_focus_navigation()
	login_panel.pivot_offset = login_panel.size * 0.5
	login_button.pressed.connect(_login)
	create_button.pressed.connect(_create_account)
	forgot_button.pressed.connect(func(): _set_status("Hãy nhập tài khoản để khôi phục mật khẩu.", "info"))
	password_input.text_submitted.connect(func(_value): _login())
	if ip_input:
		ip_input.text_submitted.connect(func(_value): _login())
	if port_input:
		port_input.text_submitted.connect(func(_value): _login())
	AccountDatabase.auth_result_received.connect(_on_auth_result)
	NetworkManager.connection_status_changed.connect(_on_connection_status_changed)
	
	if AccountDatabase.last_logout_reason != "":
		_set_status(AccountDatabase.last_logout_reason, "error")
		AccountDatabase.last_logout_reason = ""
	else:
		_set_status("Sẵn sàng kết nối", "ready")
	account_input.grab_focus()


# --- KET NOI SERVER ---

func _ensure_connection() -> bool:
	if NetworkManager.is_connected_to_server():
		return true
	
	var target_ip = ip_input.text.strip_edges() if ip_input else NetworkManager.DEFAULT_HOST
	var target_port = int(port_input.text.strip_edges()) if port_input else NetworkManager.DEFAULT_PORT
	if target_ip.is_empty():
		target_ip = NetworkManager.DEFAULT_HOST
	if target_port <= 0:
		target_port = NetworkManager.DEFAULT_PORT
	
	# Thu ket noi den IP:Port do nguoi choi nhap
	_set_status("Đang kết nối máy chủ…", "pending")
	NetworkManager.disconnect_network()
	await get_tree().create_timer(0.1).timeout
	
	NetworkManager.join_server(target_ip, target_port)
	var timeout := 0.0
	while not NetworkManager.is_connected_to_server() and timeout < 6.0:
		if NetworkManager.peer == null:
			break
		if NetworkManager.peer.get_connection_status() == MultiplayerPeer.CONNECTION_DISCONNECTED:
			break
		await get_tree().create_timer(0.2).timeout
		timeout += 0.2
	
	if NetworkManager.is_connected_to_server():
		print("[LoginScreen] Connected to server successfully.")
		_set_status("Đã kết nối • đang chờ xác thực", "success")
		return true
	
	NetworkManager.disconnect_network()
	return false

# --- DANG NHAP ---

func _login() -> void:
	var username := account_input.text.strip_edges()
	var password := password_input.text
	if username.is_empty() or password.is_empty():
		_set_status("Vui lòng nhập tài khoản và mật khẩu.", "error")
		return
	
	_set_auth_buttons_disabled(true)
	
	if not await _ensure_connection():
		_set_status("Không thể kết nối đến máy chủ.", "error")
		_set_auth_buttons_disabled(false)
		return

	_set_status("Đang xác thực tài khoản…", "pending")
	AccountDatabase.current_user_id = 0
	AccountDatabase.rpc_id(1, "request_authenticate", username, password)
	_begin_auth_timeout()

# --- TAO TAI KHOAN ---

func _create_account() -> void:
	var username := account_input.text.strip_edges()
	var password := password_input.text
	if username.is_empty() or password.is_empty():
		_set_status("Vui lòng nhập tài khoản và mật khẩu.", "error")
		return
	
	_set_auth_buttons_disabled(true)
	
	if not await _ensure_connection():
		_set_status("Không thể kết nối đến máy chủ.", "error")
		_set_auth_buttons_disabled(false)
		return

	_set_status("Đang tạo tài khoản…", "pending")
	AccountDatabase.rpc_id(1, "request_register", username, password)
	_begin_auth_timeout()

# --- XU LY KET QUA ---

func _on_auth_result(result: Dictionary) -> void:
	auth_pending = false
	auth_request_serial += 1
	_set_status(str(result.get("message", "")), "success" if result.get("ok", false) else "error")
	if not result.get("ok", false):
		_set_auth_buttons_disabled(false)
		password_input.grab_focus()
		return
	
	GameSession.apply_authenticated_user(result["user"])
	# Luu nickname cuc bo
	var profile := ConfigFile.new()
	profile.set_value("player", "nickname", GameSession.player_nickname)
	profile.save(GameSession.PROFILE_PATH)
	
	var tween := create_tween()
	tween.tween_property(login_panel, "scale", Vector2(1.06, 1.06), 0.12).set_trans(Tween.TRANS_BACK)
	tween.tween_property(login_panel, "scale", Vector2.ZERO, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.tween_callback(func(): get_tree().change_scene_to_file("res://scenes/lobby/Lobby.tscn"))

func _apply_connection_overrides() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--connect-host="):
			ip_input.text = arg.trim_prefix("--connect-host=").strip_edges()
		elif arg.begins_with("--connect-port="):
			var parsed_port := int(arg.trim_prefix("--connect-port="))
			if parsed_port > 0:
				port_input.text = str(parsed_port)

func _set_auth_buttons_disabled(disabled: bool) -> void:
	for button in [login_button, create_button, forgot_button]:
		button.disabled = disabled
	account_input.editable = not disabled
	password_input.editable = not disabled

func _begin_auth_timeout() -> void:
	auth_pending = true
	auth_request_serial += 1
	_watch_auth_timeout(auth_request_serial)

func _watch_auth_timeout(serial: int) -> void:
	await get_tree().create_timer(AUTH_RESPONSE_TIMEOUT_SECONDS).timeout
	if not auth_pending or serial != auth_request_serial:
		return
	auth_pending = false
	_set_status("Máy chủ không phản hồi. Vui lòng thử lại.", "error")
	_set_auth_buttons_disabled(false)
	NetworkManager.disconnect_network()

func _on_connection_status_changed(is_connected: bool) -> void:
	if is_connected or not auth_pending:
		return
	auth_pending = false
	auth_request_serial += 1
	_set_status("Mất kết nối trong khi xác thực.", "error")
	_set_auth_buttons_disabled(false)

# --- GIAO DIEN ---

func _style(fill: Color, border: Color, radius: int = 12, width: int = 3) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = border
	box.set_border_width_all(width)
	box.set_corner_radius_all(radius)
	box.shadow_color = Color(0.02, 0.08, 0.18, 0.55)
	box.shadow_size = 8
	box.shadow_offset = Vector2(0, 5)
	box.content_margin_left = 14
	box.content_margin_right = 14
	return box

func _apply_styles() -> void:
	login_panel.add_theme_stylebox_override("panel", UITheme.panel_modal())
	var fields: Array = [account_input, password_input]
	if ip_input: fields.append(ip_input)
	if port_input: fields.append(port_input)
	for field in fields:
		field.add_theme_stylebox_override("normal", UITheme.panel_inset())
		field.add_theme_stylebox_override("focus", UITheme.panel_inset())
		field.add_theme_color_override("font_color", Color.WHITE)
		field.add_theme_color_override("font_placeholder_color", Color(0.8, 0.8, 0.8))
	for label in [login_panel.get_node("VBox/AccountLabel"), login_panel.get_node("VBox/PasswordLabel"), login_panel.get_node_or_null("VBox/ServerLabel")]:
		if label:
			label.add_theme_color_override("font_color", Color(0.7, 0.85, 1.0))
	UITheme.apply_button_theme(login_button, "primary")
	UITheme.apply_button_theme(create_button, "secondary")
	UITheme.apply_button_theme(forgot_button, "secondary")

func _setup_focus_navigation() -> void:
	account_input.focus_neighbor_bottom = password_input.get_path()
	password_input.focus_neighbor_top = account_input.get_path()
	if ip_input:
		password_input.focus_neighbor_bottom = ip_input.get_path()
		ip_input.focus_neighbor_top = password_input.get_path()
		if port_input:
			ip_input.focus_neighbor_right = port_input.get_path()
			port_input.focus_neighbor_left = ip_input.get_path()
			port_input.focus_neighbor_bottom = login_button.get_path()
			login_button.focus_neighbor_top = port_input.get_path()
		else:
			ip_input.focus_neighbor_bottom = login_button.get_path()
			login_button.focus_neighbor_top = ip_input.get_path()
	else:
		password_input.focus_neighbor_bottom = login_button.get_path()
		login_button.focus_neighbor_top = password_input.get_path()
	login_button.focus_neighbor_right = create_button.get_path()
	create_button.focus_neighbor_left = login_button.get_path()
	create_button.focus_neighbor_right = forgot_button.get_path()
	forgot_button.focus_neighbor_left = create_button.get_path()

func _set_status(message: String, tone: String = "info") -> void:
	status_label.text = message
	var color := Color("#69dcff")
	match tone:
		"ready":
			color = Color("#61f59a")
		"pending":
			color = Color("#ffd45c")
		"success":
			color = Color("#72f5b0")
		"error":
			color = Color("#ff7c8b")
	status_dot.add_theme_color_override("font_color", color)
	status_label.add_theme_color_override("font_color", color.lightened(0.16))
