class_name RescueSystem
extends RefCounted

static func process_team_rescues(players: Dictionary, team_mode: bool, invulnerability_seconds: float) -> int:
	if not team_mode:
		return 0
	var rescue_count := 0
	for rescuer in players.values():
		if rescuer == null or not rescuer.is_alive or rescuer.is_in_bubble:
			continue
		for trapped in players.values():
			if trapped == null or trapped == rescuer or not trapped.is_alive or not trapped.is_in_bubble:
				continue
			if rescuer.team_id == trapped.team_id and rescuer.grid_cell == trapped.grid_cell:
				trapped.rescue(rescuer.player_id, invulnerability_seconds)
				rescue_count += 1
	return rescue_count

static func process_bubble_contacts(players: Dictionary, team_mode: bool, invulnerability_seconds: float) -> Dictionary:
	var result := {"rescued": 0, "enemy_bursts": 0}
	for trapped in players.values():
		if trapped == null or not trapped.is_alive or not trapped.is_in_bubble:
			continue
		for toucher in players.values():
			if toucher == null or toucher == trapped or not toucher.is_alive or toucher.is_in_bubble:
				continue
			if toucher.grid_cell != trapped.grid_cell:
				continue
			if team_mode and toucher.team_id == trapped.team_id:
				trapped.rescue(toucher.player_id, invulnerability_seconds)
				result["rescued"] += 1
			else:
				trapped.die()
				result["enemy_bursts"] += 1
			break
	return result
