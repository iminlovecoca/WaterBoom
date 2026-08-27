extends Node

var passed := 0
var failed := 0

func check(value: bool, message: String) -> void:
	if value:
		passed += 1
		print("[ACCOUNT PASS] ", message)
	else:
		failed += 1
		push_error("[ACCOUNT FAIL] %s" % message)

func _ready() -> void:
	check(AccountDatabase.ready_ok, "SQLite database opens and schema migration runs")
	var username := "u%d_%d" % [randi() % 9000 + 1000, Time.get_ticks_msec() % 10000]
	var created: Dictionary = AccountDatabase.register_account(username, "bubble123")
	check(created["ok"], "registration inserts a new SQL user")
	var duplicate: Dictionary = AccountDatabase.register_account(username, "bubble123")
	check(not duplicate["ok"], "unique username rejects duplicate registration")
	var denied: Dictionary = AccountDatabase.authenticate(username, "wrong-password")
	check(not denied["ok"], "password hash rejects invalid credentials")
	var login: Dictionary = AccountDatabase.authenticate(username, "bubble123")
	check(login["ok"] and int(login["user"]["cokecy"]) == 500, "valid login restores SQL profile data")
	check(int(login["user"]["level"]) == 1 and int(login["user"]["experience"]) == 0, "new SQL account starts at level 1 with zero EXP")
	var user_with_stale_nickname: Dictionary = login["user"].duplicate(true)
	user_with_stale_nickname["nickname"] = "coca"
	GameSession.apply_authenticated_user(user_with_stale_nickname)
	check(GameSession.player_nickname == username, "username remains the lobby identity even when a stale nickname belongs to coca")
	var progress := GameSession.add_experience(125)
	check(progress["leveled_up"] and GameSession.level == 2 and GameSession.experience == 25, "EXP crosses its threshold and carries overflow into the next level")
	check(AccountDatabase.unlocked_skins_for_current_user().has(&"skin_066"), "new account owns its default inventory row")
	check(GameSession.owned_cosmetics.has(&"flag_default_water"), "new account owns the default water-balloon flag")
	check(str(GameSession.equipped_cosmetics.get("flag", "")) == "flag_default_water", "default flag ID is restored from SQL equipment")
	var flag_definition := CosmeticRegistry.get_definition(&"flag_default_water")
	check(flag_definition != null and flag_definition.lobby_asset != null, "default flag resolves to a real lobby texture")
	check(not PlayerEquipmentService.equip(CosmeticDefinition.HEAD_ACCESSORY, &"head_halo_aqua"), "equipment service rejects cosmetics the account does not own")
	var affordable_purchase := AccountDatabase.purchase_cosmetic_for_current_user(&"head_halo_aqua")
	check(bool(affordable_purchase.get("success", false)), "shop SQL transaction purchases an affordable cosmetic")
	check(AccountDatabase.unlocked_cosmetics_for_current_user().has(&"head_halo_aqua"), "purchased cosmetic is persisted in SQL ownership")
	check(int(affordable_purchase.get("balance", -1)) == 50, "cosmetic purchase deducts the exact server-side price")
	var duplicate_purchase := AccountDatabase.purchase_cosmetic_for_current_user(&"head_halo_aqua")
	check(bool(duplicate_purchase.get("success", false)) and int(duplicate_purchase.get("balance", -1)) == 50, "buying an owned cosmetic never charges twice")
	AccountDatabase._db.update_rows("users", "id = %d" % AccountDatabase.current_user_id, {"cokecy": 5000})
	var new_cosmetic_purchase := AccountDatabase.purchase_cosmetic_for_current_user(&"head_flower_wreath")
	check(bool(new_cosmetic_purchase.get("success", false)), "a newly added shop cosmetic can be purchased")
	check(AccountDatabase.unlocked_cosmetics_for_current_user().has(&"head_flower_wreath"), "new shop cosmetic ownership survives a database readback")
	AccountDatabase._db.update_rows("users", "id = %d" % AccountDatabase.current_user_id, {"cokecy": 110000})
	var balloon_purchase := AccountDatabase.purchase_balloon_skin_for_current_user(&"skin_070")
	check(bool(balloon_purchase.get("success", false)), "water-balloon purchases use the same server-authoritative SQL transaction")
	check(AccountDatabase.unlocked_skins_for_current_user().has(&"skin_070"), "purchased water-balloon ownership survives a database readback")
	check(int(balloon_purchase.get("balance", -1)) == 10000, "water-balloon purchase deducts exactly its catalog price")
	print("ACCOUNT_DATABASE_RESULT: %d passed | %d failed" % [passed, failed])
	get_tree().quit(1 if failed > 0 else 0)
