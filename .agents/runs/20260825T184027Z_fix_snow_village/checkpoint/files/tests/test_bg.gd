extends SceneTree

func _init() -> void:
	for map_id in ['aqua_park', 'training_plaza', 'pirate_harbor', 'snow_village']:
		var path = 'res://assets/maps/backgrounds/bg_' + map_id + '.png'
		var exists = ResourceLoader.exists(path)
		var res = load(path) if exists else null
		print(map_id, ': exists=', exists, ' loaded=', res)
	quit()
