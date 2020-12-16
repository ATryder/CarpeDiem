extends Spatial

func _ready():
	var fc = get_node("/root").find_node("FogControl", true, false)
	if fc.initialized == true:
		fog_initialized(fc)
	else:
		add_to_group("fog_init_notify")

func fog_initialized(fogControl):
	var mat = get_child(0).get_surface_material(0)
	mat.set_shader_param("mask_tex", fogControl.get_mask())
	mat.set_shader_param("mask_scale", fogControl.get_mask_world_scale())
	mat.set_shader_param("mask_offset", fogControl.get_mask_offset())
	mat.set_shader_param("fog", fogControl.fogMapped)

func activate(player):
	pass

func reveal_map_area(playerNum):
	var revealMapRange = (randi() % 8) + 6
	var game = get_node("/root/Game")
	var arena = game.get_node("Arena")
	var fc = arena.get_node("FogControl")
	var tiles = [arena.world_to_tile(transform.origin)]
	var costs = [0.0]
	
	var count = 0
	while count < tiles.size():
		var surrounding = tiles[count].get_surrounding()
		for tile in surrounding:
			var totalCost = 1.0 + costs[count]
			var idx = tiles.find_last(tile)
			if idx >= 0:
				if costs[idx] > totalCost:
					costs[idx] = totalCost
			elif totalCost <= revealMapRange:
				tiles.push_back(tile)
				costs.push_back(totalCost)
				if !tile.mapped[game.thisPlayer] and randf() <= 0.8:
					tile.mapped[playerNum] = true
					fc.update(tile)
		count += 1
