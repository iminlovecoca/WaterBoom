extends Node

const TIMEOUT_SECONDS := 8.0

var auth_received := false
var auth_result: Dictionary = {}

func _ready() -> void:
	AccountDatabase.auth_result_received.connect(_on_auth_result)
	if not NetworkManager.join_server("127.0.0.1", 7777):
		_fail("Could not create local ENet client")
		return

	if not await _wait_until(func(): return NetworkManager.is_connected_to_server(), TIMEOUT_SECONDS):
		_fail("Timed out connecting to 127.0.0.1:7777")
		return

	var username := "net_smoke_%d" % Time.get_ticks_msec()
	AccountDatabase.rpc_id(1, "request_register", username, "SmokePass123!")
	if not await _wait_until(func(): return auth_received, TIMEOUT_SECONDS):
		_fail("Connected, but authentication RPC did not return")
		return
	if not bool(auth_result.get("ok", false)):
		_fail("Authentication RPC returned failure: %s" % auth_result.get("message", ""))
		return

	print("LOCAL AUTH NETWORK SMOKE: PASS")
	NetworkManager.disconnect_network()
	get_tree().quit(0)

func _on_auth_result(result: Dictionary) -> void:
	auth_result = result
	auth_received = true

func _wait_until(predicate: Callable, seconds: float) -> bool:
	var elapsed := 0.0
	while elapsed < seconds:
		if predicate.call():
			return true
		await get_tree().create_timer(0.05).timeout
		elapsed += 0.05
	return bool(predicate.call())

func _fail(message: String) -> void:
	push_error("LOCAL AUTH NETWORK SMOKE: FAIL — %s" % message)
	NetworkManager.disconnect_network()
	get_tree().quit(1)
