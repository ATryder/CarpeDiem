extends LevelGenerator
class_name SaveLoader

var sg : SavedGame

var totalUnits : int
var unitsLoaded := 0.0


func _init(arena, savedGame : SavedGame).(arena,
										savedGame.mapWidth,
										savedGame.mapHeight,
										savedGame.mapColor1,
										savedGame.mapColor2,
										savedGame.numPlayers,
										savedGame.player,
										savedGame.playerColor,
										savedGame.loadedGame.rseed):
	sg = savedGame
	Opts.allVis = sg.allVis
	Opts.noFog = sg.noFog
	Opts.alliedAI = sg.alliedAI
	Music.gameStopped = sg.musicStopped
	game.turnStations = sg.loadedGame.turnStations
	
	totalSteps = 9.0
	
	for units in sg.loadedGame.playerUnits:
		totalUnits += units.size()


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
				var player
				if i == game.thisPlayer:
					player = Player.new(game, i, playerColors[i], sg.loadedGame.playerHandles[i])
					players.push_back(player)
				else:
					player = Player_AI.new(game, i, playerColors[i], sg.loadedGame.playerHandles[i])
					player.difficulty = clamp(sg.loadedGame.playerDifficulty[i], Opts.AI_EASY, Opts.AI_HARD)
					players.push_back(player)
				
				player.incomeOre = sg.loadedGame.playerOre[i]
				player.incomeEnergy = sg.loadedGame.playerEnergy[i]
				player.turns = sg.loadedGame.playerSnapshots[i]
			game.players = players
			loadStep += 1
			current_progress.progress = 0.0
		2:
			for tile in sg.loadedGame.arena:
				tile.game = game
				tile.fogControl = game.get_node("Arena/FogControl")
			arena.init_arena(sg.loadedGame.arena, WIDTH, HEIGHT, colorInt1, colorInt2)
			current_progress.section = tr("label_gen_hex")
			loadStep += 1
			current_progress.progress = 0.0
		3:
			if gen_hexgrid_step() == true:
				current_progress.section = tr("label_pop_stars")
				current_progress.progress = 0.0
				loadStep += 1
		4:
			if populate_stars_step() == true:
				game.get_tree().call_group("star_init_notify", "stars_initialized", arena.get_node("StarControl"))
				current_progress.progress = 0.0
				loadStep += 1
				current_progress.section = tr("label_pop_ast")
		5:
			if populate_asteroids_step() == true:
				current_progress.section = tr("label_pop_unit")
				current_progress.progress = 0.0
				loadStep +=1
		6:
			if populate_units_step() == true:
				current_progress.progress = 0.0
				loadStep += 1
				current_progress.section = tr("label_pop_ghost")
		7:
			if populate_ghosts_step() == true:
				current_progress.progress = 0.0
				loadStep += 1
				current_progress.section = tr("label_init_ai")
		8:
			init_ai_manager()
			loadStep += 1
		9:
			current_progress.progress = 1.0
			loadStep += 1
			current_progress.section = tr("label_fin")
		_:
			print_debug("Level Loaded")
			set_progress_done()
			thread = null
			return true
		
	return false


func populate_units_step():
	var units = sg.loadedGame.playerUnits[loadX]
	while units.empty() && loadX < sg.loadedGame.playerUnits.size():
		loadX += 1
		if loadX == sg.loadedGame.playerUnits.size():
			loadX = 0
			loadY = 0
			unitsLoaded = 0.0
			set_progress_done()
			return true
		units = sg.loadedGame.playerUnits[loadX]
	
	var lastStop = loadY
	while loadY - lastStop < 3:
		var unit = units[loadY]
		if unit != null:
			game.players[loadX].add_unit(unit)
			if unit.mpa > 0:
				if unit.type == CD.UNIT_COMMAND_STATION && !game.players[loadX].is_local_player():
					game.players[loadX].loadout.add_station_mpa(unit.mpa)
				else:
					game.players[loadX].loadout.add_unit_type(CD.UNIT_MPA, unit.mpa)
		
		loadY += 1
		unitsLoaded += 1.0
		set_progress(unitsLoaded / totalUnits)
		if loadY == units.size():
			game.players[loadX].calc_boundaries()
			if loadX == sg.loadedGame.playerUnits.size() - 1:
				loadX = 0
				loadY = 0
				unitsLoaded = 0.0
				set_progress_done()
				return true
			else:
				loadX += 1
			loadY = 0
			break
	
	return false


func populate_ghosts_step():
	var lastStep = loadX
	while loadX - lastStep < 3 && loadX < sg.loadedGame.ghostUnits.size():
		var gd = sg.loadedGame.ghostUnits[loadX]
		var gu = game.players[gd.player].get_ghost(gd.type)
		gu.transform.origin = gd.translation
		gu.set_rotation(gd.rotation)
		gd.tile.ghostUnit = gu
		game.get_node("GhostUnits").add_child(gu)
		loadX += 1
		set_progress(loadX / float(sg.loadedGame.ghostUnits.size()))
	
	if loadX == sg.loadedGame.ghostUnits.size():
		set_progress_done()
		return true
	
	return false


func init_ai_manager(userdata = null):
	for player in game.players:
		if player.num == game.thisPlayer:
			continue
		
		var enemyFactions := []
		for i in sg.loadedGame.playerMemory[player.num]:
			enemyFactions.push_back(game.players[i])
		
		var factionManager = load("res://scripts/game/ai/FactionAssetManager.gd").new(enemyFactions, player.num)
		factionManager.freedID = sg.loadedGame.playerMemoryFreedIDs[player.num]
		
		for faction in factionManager.factions:
			factionManager.factions[faction].units = sg.loadedGame.playerMemory[player.num][faction.num]
		
		player.factionManager = factionManager
		set_progress_done()
