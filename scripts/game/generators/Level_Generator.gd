extends Reference
class_name LevelGenerator

const DEBRIS_FIELD = preload("res://models/props/DebrisField/DebrisField.tscn")

var thread : Thread

var loadStep := 1
var totalSteps := 11.0
var loadX := 0;
var loadY := 0;

var rseed

var WIDTH
var HEIGHT
var game
var arena
var fogControl

var colorInt1 : int
var colorInt2 : int

var numPlayers : int
var playerColors := []
var startPos := []
var startDistance := 15

var totalStars := 56
var starsPerPlayer := 3
var starsRadius := 7
var starsMinRadius := 3

var added_asteroids := 0
var added_stars := 0

var current_progress = Progress.new()


func _init(arena, width : int, height : int, colorInt1 : int, colorInt2 : int,
		numPlayers : int, thisPlayer : int, playerColor : int, rseed = null):
	self.arena = arena
	game = arena.get_parent()
	game.thisPlayer = thisPlayer
	game.playerTurn = thisPlayer
	fogControl = arena.get_node("FogControl")
	WIDTH = width
	HEIGHT = height
	
	self.colorInt1 = colorInt1
	self.colorInt2 = colorInt2
	self.numPlayers = numPlayers
	if rseed != null:
		rand_seed(rseed)
		self.rseed = rseed
	else:
		randomize()
		self.rseed = randi() % 9652877
		rand_seed(self.rseed)
	
	var colInt = playerColor
	for i in range(7):
		playerColors.push_back(colInt)
		if colInt == 6:
			colInt = 0
		else:
			colInt += 1
	
	match Opts.starAmount:
		Opts.QUANTITY_LOW:
			totalStars = int(round((WIDTH * HEIGHT) * 0.014))
		Opts.QUANTITY_MED:
			totalStars = int(round((WIDTH * HEIGHT) * 0.028))
		Opts.QUANTITY_HIGH:
			totalStars = int(round((WIDTH * HEIGHT) * 0.042))
	
	if Opts.starMethod == Opts.GEN_BALANCED:
		totalStars = max(totalStars - (starsPerPlayer * numPlayers), 0)


func load_step(delta):
	var res
	if thread != null:
		res = thread.wait_to_finish()
	match loadStep:
		1:
			current_progress.section = tr("label_create_players")
			var playerClass = preload("res://scripts/game/Player.gd")
			var players = []
			for i in range(numPlayers):
				if i == game.thisPlayer:
					players.push_back(Player.new(game, i, playerColors[i], Opts.playerHandle))
				else:
					var player = Player_AI.new(game, i, playerColors[i])
					players.push_back(player)
					player.difficulty = Opts.aiDifficulty
			game.players = players
			loadStep += 1
			current_progress.progress = 0.0
		2:
			current_progress.progress = 0.0
			current_progress.section = tr("label_gen_dust")
			thread = Thread.new()
			thread.start(self, "gen_cloud")
			loadStep += 1
		3:
			arena.init_arena(res,
					WIDTH, HEIGHT,
					colorInt1, colorInt2)
			current_progress.progress = 0.0
			current_progress.section = tr("label_gen_hex")
			loadStep += 1
			thread = null
		4:
			if gen_hexgrid_step() == true:
				current_progress.progress = 0.0
				loadStep += 1
				current_progress.section = tr("label_gen_stars")
				thread = Thread.new()
				thread.start(self, "gen_stars_random")
		5:
			current_progress.progress = 0.0
			loadStep += 1
			current_progress.section = tr("label_pop_stars")
			thread = null
		6:
			if populate_stars_step() == true:
				game.get_tree().call_group("star_init_notify", "stars_initialized", arena.get_node("StarControl"))
				current_progress.progress = 0.0
				loadStep += 1
				current_progress.section = tr("label_gen_ast")
				thread = Thread.new()
				thread.start(self, "gen_asteroids")
		7:
			current_progress.progress = 0.0
			loadStep += 1
			current_progress.section = tr("label_pop_ast")
			thread = null
		8:
			if populate_asteroids_step() == true:
				current_progress.progress = 0.0
				current_progress.section = tr("label_place_start")
				loadStep += 1
				thread = Thread.new()
				match Opts.aiDifficulty:
					Opts.AI_MEDIUM:
						if numPlayers < 3:
							thread.start(self, "gen_start_pos_distributed_ai")
						else:
							thread.start(self, "gen_start_pos_distributed")
					Opts.AI_HARD:
						if Opts.alliedAI && numPlayers >= 5:
							thread.start(self, "gen_start_pos_random_ai")
						else:
							thread.start(self, "gen_start_pos_distributed_ai")
					_:
						thread.start(self, "gen_start_pos_random")
		9:
			current_progress.section = tr("label_pop_unit")
			loadStep +=1
			current_progress.progress = 0.0
			thread = null
		10:
			if populate_units_step() == true:
				current_progress.progress = 0.0
				loadStep += 1
				current_progress.section = tr("label_init_ai")
				thread = Thread.new()
				thread.start(self, "init_ai_manager")
		11:
			current_progress.progress = 1.0
			loadStep += 1
			current_progress.section = tr("label_fin")
			thread = null
		_:
			print_debug("Level Loaded")
			set_progress_done()
			thread = null
			return true
	
	return false


func gen_cloud(userdata = null):
	pass


func gen_hexgrid_step():
	var gridControl = arena.get_node("GridControl")
	var numX = ceil(WIDTH / float(gridControl.block_width))
	var numY = ceil(HEIGHT / float(gridControl.block_height))
	gen_hexgrid(gridControl, loadX, loadY, numX, numY)
	loadY += 1
	if loadY == numY:
		if loadX == numX - 1:
			loadY = 0
			loadX = 0
			return true
		else:
			loadY = 0
			loadX += 1
	return false


func gen_hexgrid(gridControl, x, y, numX, numY):
	var hexMesh = gridControl.HEX_TILE.instance().get_child(0).mesh
	
	var block = gridControl.MESH_BLOCK.instance()
	var width = gridControl.block_width
	var height = gridControl.block_height
	if (x * gridControl.block_width) + width > WIDTH:
		width = WIDTH - (x * gridControl.block_width)
	if (y * gridControl.block_height) + height > HEIGHT:
		height = HEIGHT - (y * gridControl.block_height)
	
	var startx = x * gridControl.block_width
	var starty = y * gridControl.block_height
	block.create_mesh(arena, [hexMesh],
			startx, starty,
			width, height,
			(CD.TILE_WIDTH / CD.BASE_TILE_SIZE) * 0.9,
			Vector3(-startx * (CD.TILE_WIDTH * 0.75), 0, -starty * CD.TILE_HEIGHT))
	block.transform.origin.x = (x * gridControl.block_width) * (CD.TILE_WIDTH * 0.75)
	block.transform.origin.z = (y * gridControl.block_height) * CD.TILE_HEIGHT
	gridControl.add_child(block)
	block.set_surface_material(0, gridControl.GRID_MAT)
	set_progress(float(gridControl.get_child_count()) / (numX * numY))


func gen_start_pos_random(userdata = null):
	var map = arena.ARENA.duplicate()
	var area = []
	for player in game.players:
		var sp = Math.get_random_array_item(map)
		startPos.push_back(sp)
		if player.num < game.players.size() - 1:
			area = Math.get_tile_range(sp, startDistance, area)
			for t in area:
				map.erase(t)
		else:
			area = null
		set_progress(player.num / float(game.players.size() - 1))
	
	set_progress_done()


func gen_start_pos_distributed(userdata = null):
	startPos.resize(game.players.size())
	var map = arena.ARENA.duplicate()
	var resourceLocales = []
	var area = []
	var localPlayer
	var tRange = CD.COMMAND_STATION_RESOURCE_RANGE
	
	var count := 0
	for tile in map:
		area = Math.get_tile_range(tile, tRange, area)
		var ore := 0
		var energy := 0
		for t in area:
			if t.has_asteroid():
				ore += CD.ASTEROID_ORE
			if t.has_star():
				energy += CD.STAR_ENERGY
		if energy >= CD.COMMAND_STATION_MIN_ENERGY && ore >= CD.COMMAND_STATION_MIN_ORE:
			resourceLocales.push_back({"tile": tile,
										"ore": ore,
										"energy": energy})
		count += 1
		if count % HEIGHT == 0:
			set_progress((count / float(WIDTH * HEIGHT)) * 0.5)
	resourceLocales.sort_custom(self, "sort_resource_locales")
	set_progress(0.5)
	
	area = Math.get_tile_range(resourceLocales.pop_front().tile,
			CD.COMMAND_STATION_RESOURCE_RANGE, area)
	map.erase(area[0])
	area.remove(0)
	for tile in area:
		map.erase(tile)
		for locale in resourceLocales:
			if locale.tile == tile:
				resourceLocales.erase(locale)
	
	var players := []
	for player in game.players:
		if player.num != game.thisPlayer:
			players.push_back(player)
	
	set_progress(((1.0 / game.players.size()) * 0.5) + 0.5)
	
	count = 0
	while !players.empty():
		var player
		if count == game.players.size() - 2 && numPlayers > 3:
			player = game.players[game.thisPlayer]
		elif players.size() > 1:
			player = Math.get_random_array_item(players)
			players.erase(player)
		else:
			player = players.pop_front()
		
		var sp
		if resourceLocales.empty():
			sp = Math.get_random_array_item(map)
		else:
			sp = resourceLocales.pop_front().tile
		startPos[player.num] = sp
		area = Math.get_tile_range(sp, startDistance, area)
		area.remove(0)
		map.erase(sp)
		for tile in area:
			map.erase(tile)
			for locale in resourceLocales:
				if locale.tile == tile:
					resourceLocales.erase(locale)
					break
		
		count += 1
		set_progress((((count + 1) / float(game.players.size())) * 0.5) + 0.5)
	
	if numPlayers == 3:
		if !resourceLocales.empty():
			startPos[game.thisPlayer] = resourceLocales[0].tile
		else:
			startPos[game.thisPlayer] = Math.get_random_array_item(map)
	
	set_progress_done()


func gen_start_pos_distributed_ai(userdata = null):
	startPos.resize(game.players.size())
	var map = arena.ARENA.duplicate()
	var resourceLocales = []
	var area = []
	var localPlayer
	var tRange = CD.COMMAND_STATION_RESOURCE_RANGE
	
	var count := 0
	for tile in map:
		area = Math.get_tile_range(tile, tRange, area)
		var ore := 0
		var energy := 0
		for t in area:
			if t.has_asteroid():
				ore += CD.ASTEROID_ORE
			if t.has_star():
				energy += CD.STAR_ENERGY
		if energy >= CD.COMMAND_STATION_MIN_ENERGY && ore >= CD.COMMAND_STATION_MIN_ORE:
			resourceLocales.push_back({"tile": tile,
										"ore": ore,
										"energy": energy})
		count += 1
		if count % HEIGHT == 0:
			set_progress((count / float(WIDTH * HEIGHT)) * 0.5)
	resourceLocales.sort_custom(self, "sort_resource_locales")
	set_progress(0.5)
	
	var players := []
	for player in game.players:
		if player.num != game.thisPlayer:
			players.push_back(player)
	
	count = 0
	while !players.empty():
		var player
		if players.size() > 1:
			player = Math.get_random_array_item(players)
			players.erase(player)
		else:
			player = players.pop_front()
		
		var sp
		if resourceLocales.empty():
			sp = Math.get_random_array_item(map)
		else:
			sp = resourceLocales.pop_front().tile
		startPos[player.num] = sp
		area = Math.get_tile_range(sp, startDistance, area)
		area.remove(0)
		map.erase(sp)
		for tile in area:
			map.erase(tile)
			for locale in resourceLocales:
				if locale.tile == tile:
					resourceLocales.erase(locale)
					break
		
		count += 1
		set_progress(((count / float(game.players.size() - 1)) * 0.5) + 0.5)
	
	startPos[game.thisPlayer] = Math.get_random_array_item(map)
	set_progress_done()


func gen_start_pos_random_ai(userdata = null):
	startPos.resize(game.players.size())
	var map = arena.ARENA.duplicate()
	var resourceLocales = []
	var area = []
	var localPlayer
	var tRange = CD.COMMAND_STATION_RESOURCE_RANGE
	
	var count := 0
	for tile in map:
		area = Math.get_tile_range(tile, tRange, area)
		var ore := 0
		var energy := 0
		for t in area:
			if t.has_asteroid():
				ore += CD.ASTEROID_ORE
			if t.has_star():
				energy += CD.STAR_ENERGY
		if energy >= CD.COMMAND_STATION_MIN_ENERGY && ore >= CD.COMMAND_STATION_MIN_ORE:
			resourceLocales.push_back({"tile": tile,
										"ore": ore,
										"energy": energy})
		count += 1
		if count % HEIGHT == 0:
			set_progress((count / float(WIDTH * HEIGHT)) * 0.5)
	resourceLocales.sort_custom(self, "sort_resource_locales")
	set_progress(0.5)
	
	var tIdx = int(round(rand_range(0, min(50, resourceLocales.size() - 1))))
	startPos[game.thisPlayer] = resourceLocales[tIdx].tile
	area = Math.get_tile_range(startPos[game.thisPlayer], startDistance, area)
	for tile in area:
		map.erase(tile)
		for locale in resourceLocales:
			if locale.tile == tile:
				resourceLocales.erase(locale)
	
	set_progress(((1.0 / game.players.size()) * 0.5) + 0.5)
	
	for player in game.players:
		if player.num == game.thisPlayer:
			continue
		
		var sp = Math.get_random_array_item(map)
		startPos[player.num] = sp
		if player.num < game.players.size() - 1:
			area = Math.get_tile_range(sp, startDistance, area)
			for t in area:
				map.erase(t)
		else:
			area = null
		set_progress((((player.num + 1) / float(game.players.size())) * 0.5) + 0.5)
	
	set_progress_done()


func sort_resource_locales(a, b):
	return a.ore + min(a.energy * 2, 8) > b.ore + min(b.energy * 2, 8)


func gen_stars_random(userdata = null):
	var tile
	for i in range(totalStars):
		var redo = true
		var count = 0
		while redo and count < 100:
			count += 1
			var x = randi() % WIDTH
			var y = randi() % HEIGHT
			tile = arena.get_tile(x, y)
			if Opts.starMethod == Opts.GEN_BALANCED:
				redo = false
				for pos in startPos:
					redo = Vector2(x, y).distance_to(Vector2(pos.x, pos.y)) < starsRadius or redo
				redo = tile.has_star() or tile.color < 0 or redo
			else:
				redo = tile.has_star() or tile.color < 0
		
		if Opts.starMethod == Opts.GEN_BALANCED:
			set_progress(float(i + (starsPerPlayer * numPlayers)) / (totalStars + (starsPerPlayer * numPlayers)))
		else:
			set_progress(float(i) / totalStars)
		if redo:
			continue
		
		tile.star = {"translation": Vector3(), "scale": rand_range(0.29, 0.42)}
	set_progress_done()


func populate_stars_step():
	populate_stars(loadX)
	loadX += 1
	if loadX == WIDTH:
		loadX = 0
		set_progress_done()
		return true
	return false


func populate_stars(x):
	var starControl = arena.get_node("StarControl")
	for y in range(HEIGHT):
		var tile = arena.get_tile(x, y)
		if tile.has_star():
			added_stars += 1
			starControl.add_child(starControl.new_star_to_tile(tile))
	set_progress(((x * HEIGHT) + HEIGHT) / float(WIDTH * HEIGHT))


func gen_asteroids(userdata = null):
	set_progress_done()


func populate_asteroids_step():
	var astControl = arena.get_node("AsteroidControl")
	var numX = ceil(WIDTH / float(astControl.block_width))
	var numY = ceil(HEIGHT / float(astControl.block_height))
	populate_asteroids(astControl, loadX, loadY, numX, numY)
	loadY += 1
	if loadY == numY:
		if loadX == numX - 1:
			loadY = 0
			loadX = 0
			set_progress_done()
			return true
		else:
			loadY = 0
			loadX += 1
	return false


func populate_asteroids(astControl, x, y, numX, numY):
	var meshes = []
	for m in astControl.ASTEROIDS:
		meshes.push_back(m.instance().get_child(0).mesh)
	
	var block = astControl.MESH_BLOCK.instance()
	var width = astControl.block_width
	var height = astControl.block_height
	if (x * astControl.block_width) + width > WIDTH:
		width = WIDTH - (x * astControl.block_width)
	if (y * astControl.block_height) + height > HEIGHT:
		height = HEIGHT - (y * astControl.block_height)
	
	var startx = x * astControl.block_width
	var starty = y * astControl.block_height
	var offset = Vector3(-startx * (CD.TILE_WIDTH * 0.75), 0, -starty * CD.TILE_HEIGHT)
	added_asteroids += block.create_mesh(arena, meshes,
										startx, starty,
										width, height,
										CD.TILE_HALF_HEIGHT,
										offset, "get_asteroid_props")
	
	if block.mesh != null:
		block.transform.origin.x = (x * astControl.block_width) * (CD.TILE_WIDTH * 0.75)
		block.transform.origin.z = (y * astControl.block_height) * CD.TILE_HEIGHT
		astControl.add_child(block)
		block.set_surface_material(0, astControl.AST_MAT)
	set_progress(float(astControl.get_child_count()) / (numX * numY))


func populate_units_step():
	populate_unit()
	loadX += 1
	if loadX == 3:
		var player = game.players[loadY]
		player.turns.push_back(player.turn_snapshot(player))
		loadX = 0
		loadY += 1
		if loadY == game.players.size():
			loadY = 0
			set_progress_done()
			return true
	set_progress(float(loadY) / game.players.size())
	return false


func populate_unit():
	var player = game.players[loadY]
	var unit
	if loadX == 0:
		if (!(Opts.aiDifficulty == Opts.AI_HARD && numPlayers < 3)
				|| player.is_local_player()):
			unit = CD.get_unit(CD.UNIT_CARGOSHIP).instance()
			unit.mpa = unit.get_max_mpa()
			player.loadout.add_unit_type(CD.UNIT_MPA, CD.CARGOSHIP_MAX_MPA)
		else:
			var area = Math.get_tile_range(startPos[loadY], CD.COMMAND_STATION_RESOURCE_RANGE)
			var ore := 0
			var energy := 0
			for tile in area:
				if tile.has_asteroid():
					ore += CD.ASTEROID_ORE
				if tile.has_star():
					energy += CD.STAR_ENERGY
			if ore >= CD.COMMAND_STATION_MIN_ORE && energy >= CD.COMMAND_STATION_MIN_ENERGY:
				unit = CD.get_unit(CD.UNIT_COMMAND_STATION).instance()
				unit.calcBoundaries = true
				unit.mpa = 2
				player.loadout.add_station_mpa(2)
				game.turnStations.push_back({"add": true,
											"tile": startPos[loadY],
											"player": player.num,
											"color": player.color})
			else:
				unit = CD.get_unit(CD.UNIT_CARGOSHIP).instance()
				unit.mpa = unit.get_max_mpa()
				player.loadout.add_unit_type(CD.UNIT_MPA, CD.CARGOSHIP_MAX_MPA)
		unit.tile = startPos[loadY]
		startPos[loadY].unit = unit
	else:
		unit = CD.get_unit(CD.UNIT_NIGHTHAWK).instance()
		var stiles = startPos[loadY].get_surrounding()
		var tile = stiles[randi() % stiles.size()]
		while tile.unit != null:
			stiles.erase(tile)
			tile = stiles[randi() % stiles.size()]
		unit.tile = tile
	player.add_unit(unit)


func init_ai_manager(userdata = null):
	var totalUnits = 0.0
	for player in game.players:
		totalUnits += player.get_all_units().size()
	if totalUnits == 0.0:
		set_progress_done()
		return
	var currentCount = 0
	for player in game.players:
		for unit in player.get_all_units():
			for p in game.players:
				if p.num != game.thisPlayer && p.num != player.num && unit.tile.is_visible(p.num):
					p.factionManager.unit_sighted(unit)
			currentCount += 1
			set_progress(currentCount / totalUnits)
	set_progress_done()


func set_progress(value):
	current_progress.lock()
	current_progress.progress = value
	current_progress.unlock()


func set_progress_done():
	set_progress(1.1)


class Progress extends Mutex:
	var progress = 0.0 setget set_progress, get_progress
	var section = ""
	var done = false
	
	func set_progress(value):
		if value < 1.0:
			done = false
		else:
			done = true
		value = clamp(value, 0.0, 1.0)
		progress = value
	
	func get_progress():
		return progress
