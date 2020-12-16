extends LevelGenerator
class_name SimplexGenerator

var baseFrequency
var asteroidThreshold


func _init(arena, width, height,
		colorInt1, colorInt2,
		numPlayers, thisPlayer : int, playerColor : int, rseed = null).(arena, width, height,
					colorInt1, colorInt2,
					numPlayers, thisPlayer, playerColor, rseed):
	
	if WIDTH > HEIGHT:
		baseFrequency = WIDTH / 12.0
		baseFrequency *= 64.0 / WIDTH
	else:
		baseFrequency = HEIGHT / 12.0
		baseFrequency *= 64.0 / HEIGHT
	
	match Opts.asteroidAmount:
		Opts.QUANTITY_LOW:
			asteroidThreshold = 0.40
		Opts.QUANTITY_MED:
			asteroidThreshold = 0.45
		Opts.QUANTITY_HIGH:
			asteroidThreshold = 0.50


func gen_cloud(userdata = null):
	var ARENA := []
	var terrain_noise = Simplex3D.new(baseFrequency, 2,
			Vector3(rand_range(0, 84317), rand_range(0, 84317), rand_range(0, 84317)))
	var cloud_noise = Simplex3D.new(baseFrequency * 3, 1,
			Vector3(rand_range(0, 84317), rand_range(0, 84317), rand_range(0, 84317)))
	
	var vec = Vector3()
	for x in range(WIDTH):
		if WIDTH > HEIGHT:
			vec.x = x / float(WIDTH)
		else:
			vec.x = x / float(HEIGHT)
		for y in range(HEIGHT):
			if WIDTH > HEIGHT:
				vec.y = y / float(WIDTH)
			else:
				vec.y = y / float(HEIGHT)
			var terrain_value = terrain_noise.get_noise(vec)
			
			var tile = CDTile.new(x, y, numPlayers, game)
			if terrain_value >= 0.485:
				var cloud_value = cloud_noise.get_noise(vec)
				if cloud_value >= 0.5:
					tile.color = colorInt1
				else:
					tile.color = colorInt2
			ARENA.push_back(tile)
		set_progress(x / float(WIDTH))
	
	set_progress_done()
	
	return ARENA


func gen_asteroids(userdata = null):
	var noise = Simplex3D.new(baseFrequency * 3, 2,
			Vector3(rand_range(0, 84317),
			rand_range(0, 84317), rand_range(0, 84317)))
	
	var vec = Vector3()
	for x in range(WIDTH):
		if WIDTH > HEIGHT:
			vec.x = x / float(WIDTH)
		else:
			vec.x = x / float(HEIGHT)
		for y in range(HEIGHT):
			if WIDTH > HEIGHT:
				vec.y = y / float(WIDTH)
			else:
				vec.y = y / float(HEIGHT)
			var value = noise.get_noise(vec)
			var tile = arena.get_tile(x, y)
			if value <= asteroidThreshold and tile.star == null and tile.color >= 0:
				tile.asteroid = {}
				tile.asteroid["meshIndex"] = randi() % arena.get_node("AsteroidControl").ASTEROIDS.size()
				var minv = Vector3(-CD.TILE_WIDTH * 0.9 * 0.15, 0, -CD.TILE_HEIGHT * 0.9 * 0.15)
				var maxv = Vector3(CD.TILE_WIDTH * 0.9 * 0.15, 0, CD.TILE_HEIGHT * 0.9 * 0.15)
				tile.asteroid["translation"] = Vector3(rand_range(minv.x, maxv.x),
						rand_range(minv.y, maxv.y),
						rand_range(minv.z, maxv.z))
				minv = Vector3()
				maxv = Vector3(359.9, 359.9, 359.9)
				tile.asteroid["rotation"] = Vector3(rand_range(minv.x, maxv.x),
						rand_range(minv.y, maxv.y),
						rand_range(minv.z, maxv.z))
				tile.asteroid["scale"] = rand_range(0.19, 0.4)
		set_progress(x / float(WIDTH))
	
	set_progress_done()
