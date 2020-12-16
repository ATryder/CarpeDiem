extends Reference
class_name SavedGame

const VERSION_INT := 2
const VERSION := "1.0.1"

const EXTENSION := "cdsav"

var file : File

var version := -1
var headerSize : int
var fileSize : int = 0

var preview : ImageTexture
var date : Dictionary
var numPlayers : int
var alliedAI : bool
var player : int
var playerColor : int
var mapWidth : int
var mapHeight : int
var mapColor1 : int
var mapColor2 : int
var musicStopped := false
var allVis := false
var noFog := false
var turn : int

var loadedGame

var error := OK


func _init(filepath, mode := File.READ):
	file = File.new()
	file.open(filepath, mode)


func get_error():
	if error == OK:
		return file.get_error()
	return error


func close():
	file.close()


func load_header() -> int:
	if get_error() != OK:
		return get_error()
	
	version = file.get_16()
	headerSize = file.get_32()
	
	var position = file.get_position()
	file.seek(headerSize)
	if file.eof_reached():
		error = ERR_FILE_EOF
		return error
	
	file.seek(position)
	
	fileSize = file.get_64()
	
	var imgWidth = file.get_16()
	var imgHeight = file.get_16()
	var imgSize = file.get_32()
	var imgData = file.get_buffer(imgSize)
	var img := Image.new()
	img.create_from_data(imgWidth, imgHeight, false, Image.FORMAT_RGB8, imgData)
	preview = ImageTexture.new()
	preview.create_from_image(img, 0)
	
	date = {"day": file.get_8(),
			"month": file.get_8(),
			"year": file.get_16(),
			"hour": file.get_8(),
			"minute": file.get_8(),
			"second": file.get_64()}
	
	numPlayers = file.get_8()
	alliedAI = file.get_8() > 0
	player = file.get_8()
	playerColor = file.get_8()
	mapWidth = file.get_8()
	mapHeight = file.get_8()
	mapColor1 = file.get_8()
	mapColor2 = file.get_8()
	if version > 1:
		musicStopped = file.get_8() > 0
	if file.get_8() > 0:
		allVis = true
	if file.get_8() > 0:
		noFog = true
	turn = file.get_16()
	
	return OK


func save(game : Spatial) -> int:
	if get_error() != OK:
		return get_error()
	
	var playerUnits := []
	playerUnits.resize(game.players.size())
	for player in game.players:
		playerUnits[player.num] = []
		for unit in player.get_all_units():
			if unit.is_alive():
				playerUnits[player.num].push_back(unit)
	
	var preview = game.hud.infoView.mapDisplay.texture
	var imgData = preview.get_data().get_data()
	
	file.store_16(VERSION_INT)
	
	var hSize = 49 + imgData.size()
	file.store_32(hSize)
	file.store_64(0)
	
	file.store_16(preview.get_width())
	file.store_16(preview.get_height())
	file.store_32(imgData.size())
	file.store_buffer(imgData)
	
	var dte = OS.get_datetime()
	file.store_8(dte.day)
	file.store_8(dte.month)
	file.store_16(dte.year)
	file.store_8(dte.hour)
	file.store_8(dte.minute)
	file.store_64(dte.second)
	
	var gamePlayer = game.get_player(game.thisPlayer)
	file.store_8(game.players.size())
	if Opts.alliedAI:
		file.store_8(1)
	else:
		file.store_8(0)
	file.store_8(gamePlayer.num)
	file.store_8(gamePlayer.color)
	file.store_8(game.arena.MAP_WIDTH)
	file.store_8(game.arena.MAP_HEIGHT)
	file.store_8(game.arena.colorIntScheme1)
	file.store_8(game.arena.colorIntScheme2)
	if Music.gameStopped:
		file.store_8(1)
	else:
		file.store_8(0)
	if Opts.allVis:
		file.store_8(1)
	else:
		file.store_8(0)
	if Opts.noFog:
		file.store_8(1)
	else:
		file.store_8(0)
	file.store_16(gamePlayer.turns.size())
	
	var offsetsSize = (game.players.size() * 8) + 8 + 1 + 1 + 1 + 8 + 8 + 8 + 8
	file.store_64(offsetsSize + hSize) #Offset to first tile in arena
	
	file.store_64(game.rseed)
	
	if game.arena.get_node("GridControl").visible:
		file.store_8(1)
	else:
		file.store_8(0)
	
	if game.get_node("QuickInfo").visible:
		file.store_8(1)
	else:
		file.store_8(0)
	
	var camCont = game.get_node("CameraControl")
	file.store_8(camCont.zoomToAttacks)
	file.store_double(camCont.transform.origin.x)
	file.store_double(camCont.transform.origin.z)
	file.store_double(camCont.zoom)
	
	var playerOffsets = file.get_position()
	#Offset to each player
	for i in range(game.players.size()):
		file.store_64(0)
	
	for tile in game.arena.get_arena():
		file.store_8(tile.x)
		file.store_8(tile.y)
		file.store_8(tile.color)
		file.store_8(tile.lastSightedTerritory)
		
		for mapped in tile.mapped:
			if mapped:
				file.store_8(1)
			else:
				file.store_8(0)
		
		if tile.has_star():
			file.store_8(1)
			file.store_double(tile.star.translation.x)
			file.store_double(tile.star.translation.y)
			file.store_double(tile.star.translation.z)
			file.store_double(tile.star.scale)
		else:
			file.store_8(0)
		
		if tile.has_asteroid():
			file.store_8(1)
			file.store_8(tile.asteroid.meshIndex)
			file.store_double(tile.asteroid.translation.x)
			file.store_double(tile.asteroid.translation.y)
			file.store_double(tile.asteroid.translation.z)
			file.store_double(tile.asteroid.rotation.x)
			file.store_double(tile.asteroid.rotation.y)
			file.store_double(tile.asteroid.rotation.z)
			file.store_double(tile.asteroid.scale)
		else:
			file.store_8(0)
		
		if tile.is_occupied() && playerUnits[tile.unit.player.num].has(tile.unit):
			file.store_8(1)
			file.store_8(tile.unit.player.num)
			file.store_16(playerUnits[tile.unit.player.num].find(tile.unit))
		else:
			file.store_8(0)
			
		if tile.ghostUnit != null:
			file.store_8(1)
			file.store_8(tile.ghostUnit.playerNum)
			file.store_double(tile.ghostUnit.transform.origin.x)
			file.store_double(tile.ghostUnit.transform.origin.z)
			file.store_double(tile.ghostUnit.rotation.x)
			file.store_double(tile.ghostUnit.rotation.y)
			file.store_double(tile.ghostUnit.rotation.z)
		else:
			file.store_8(0)
		
		var tmpCollectors = []
		for station in tile.collectors:
			if playerUnits[station.player.num].has(station):
				tmpCollectors.push_back(station)
		file.store_8(tmpCollectors.size())
		for station in tmpCollectors:
			file.store_8(station.player.num)
			file.store_16(playerUnits[station.player.num].find(station))
	
	file.store_8(game.turnStations.size())
	for stn in game.turnStations:
		if stn.add:
			file.store_8(1)
		else:
			file.store_8(0)
		file.store_8(stn.tile.x)
		file.store_8(stn.tile.y)
		file.store_8(stn.player)
		file.store_8(stn.color)
	
	var pIdx := 0
	for player in game.players:
		var playerOffset = file.get_position()
		file.seek(playerOffsets + (pIdx * 8))
		file.store_64(playerOffset)
		file.seek_end(0)
		
		file.store_64(0) #unit index offset
		
		if player.is_local_player():
			file.store_8(1)
		else:
			file.store_8(0)
		
		file.store_16(playerUnits[player.num].size())
		
		var handle = player.handle.to_utf8()
		file.store_16(handle.size())
		file.store_buffer(handle)
		
		if !player.is_local_player():
			file.store_8(player.difficulty)
		else:
			file.store_8(-1)
		
		file.store_16(player.incomeOre)
		file.store_16(player.incomeEnergy)
		
		file.store_64(0) #snapshot offset
		file.store_64(0) #AI memory offset
		
		var unitIdxOffset = file.get_position()
		file.seek(playerOffset)
		file.store_64(unitIdxOffset)
		file.seek_end(0)
		
		#Offset to each unit
		for u in playerUnits[player.num]:
			file.store_64(0)
		
		var idx := 0
		for unit in playerUnits[player.num]:
			var unitOffset = file.get_position()
			file.seek(unitIdxOffset + (idx * 8))
			file.store_64(unitOffset)
			file.seek_end(0)
			
			file.store_8(unit.type)
			
			file.store_double(unit.transform.origin.x)
			file.store_double(unit.transform.origin.z)
			
			file.store_double(unit.rotation.x)
			file.store_double(unit.rotation.y)
			file.store_double(unit.rotation.z)
			
			file.store_8(unit.strength)
			file.store_8(unit.moves)
			file.store_8(unit.attacks)
			
			if unit.type == CD.UNIT_CARGOSHIP:
				file.store_8(unit.mpa)
			elif unit.type == CD.UNIT_COMMAND_STATION:
				file.store_8(unit.incomeOre)
				file.store_8(unit.incomeEnergy)
				file.store_8(unit.mpa)
				file.store_8(unit.buildQueue.size())
				for buildItem in unit.buildQueue:
					file.store_8(buildItem.get_type())
					file.store_8(buildItem.get_ore())
			
			idx += 1
		
		var snapshotOffset = file.get_position()
		file.seek(playerOffset + 8 + 1 + 2 + 2 + handle.size() + 1 + 2 + 2)
		file.store_64(snapshotOffset)
		file.seek_end(0)
		
		#Turn snapshots
		file.store_16(player.turns.size())
		for snapshot in player.turns:
			file.store_16(snapshot.size)
			file.store_buffer(snapshot.data)
		
		var aiMemoryOffset = file.get_position()
		file.seek(playerOffset + 8 + 8 + 1 + 2 + 2 + handle.size() + 1 + 2 + 2)
		file.store_64(aiMemoryOffset)
		file.seek_end(0)
		
		#AI FactionManager
		if !player.is_local_player():
			file.store_8(player.factionManager.factions.size())
			for faction in player.factionManager.factions:
				var assets = player.factionManager.factions[faction]
				file.store_8(assets.factionNum)
				file.store_8(assets.units.size())
				for type in assets.units:
					var units = assets.units[type]
					file.store_8(type)
					var memUnitSizePos = file.get_position()
					var memUnitSize = units.size()
					file.store_16(memUnitSize)
					if type != CD.UNIT_COMMAND_STATION:
						for unit in units:
							if unit is int:
								file.store_16(-unit)
								file.store_8(units[unit])
							else:
								var loc = playerUnits[faction.num].find(unit)
								if loc >= 0:
									file.store_16(loc)
									file.store_8(units[unit])
								else:
									memUnitSize -= 1
									file.seek(memUnitSizePos)
									file.store_16(memUnitSize)
									file.seek_end()
					else:
						for tile in units:
							var station = units[tile]
							if station is int:
								file.store_8(tile.x)
								file.store_8(tile.y)
								file.store_16(-station)
							else:
								var loc = playerUnits[faction.num].find(station)
								if loc < 0:
									if !tile.is_visible(player.num):
										file.store_8(tile.x)
										file.store_8(tile.y)
										file.store_16(-player.factionManager.new_freed_id())
									else:
										memUnitSize -= 1
										file.seek(memUnitSizePos)
										file.store_16(memUnitSize)
										file.seek_end()
								else:
									file.store_8(tile.x)
									file.store_8(tile.y)
									file.store_16(loc)
		
		pIdx += 1
	
	var size = file.get_position()
	file.seek(2 + 4)
	file.store_64(size)
	file.seek_end(0)
	
	return OK


func load_game() -> LoadedGame:
	if get_error() != OK:
		return null
	
	if (preview == null && load_header() != OK):
		return null
	
	file.seek(fileSize)
	if file.eof_reached():
		error = ERR_FILE_EOF
		return null
	
	file.seek(0)
	
	var lg := LoadedGame.new(numPlayers)
	
	file.seek(headerSize)
	var arenaOffset = file.get_64()
	
	lg.rseed = file.get_64()
	
	if file.get_8() > 0:
		lg.gridVisible = true
	else:
		lg.gridVisible = false
	
	if file.get_8() > 0:
		lg.quickInfoVisible = true
	else:
		lg.quickInfoVisible = false
	
	lg.zoomToAttacks = file.get_8()
	lg.camLoc.x = file.get_double()
	lg.camLoc.z = file.get_double()
	lg.camZoom = file.get_double()
	
	var playerOffsets := []
	for i in range(numPlayers):
		var offset = file.get_64()
		
		playerOffsets.push_back(offset)
		var pos = file.get_position()
		file.seek(playerOffsets[i] + 1 + 8)
		lg.playerUnits[i].resize(file.get_16())
		file.seek(pos)
	
	for i in range(numPlayers):
		file.seek(playerOffsets[i] + 8)
		
		if file.get_8() > 0:
			lg.playerTypes[i] = true
		else:
			lg.playerTypes[i] = false
		
		file.seek(file.get_position() + 2)
		lg.playerHandles[i] = file.get_buffer(file.get_16()).get_string_from_utf8()
		
		lg.playerDifficulty[i] = Math.u8_to_s8(file.get_8())
		
		lg.playerOre[i] = file.get_16()
		lg.playerEnergy[i] = file.get_16()
		
		var snapshotOffset = file.get_64()
		var memoryOffset = file.get_64()
		
		file.seek(snapshotOffset)
		var numSnapshots = file.get_16()
		for _snp in range(numSnapshots):
			var bufferSize = file.get_16()
			lg.playerSnapshots[i].push_back({"size": bufferSize, "data": file.get_buffer(bufferSize)})
		
		if lg.playerTypes[i]:
			continue;
		
		file.seek(memoryOffset)
		var numFactions = file.get_8()
		if numFactions >= numPlayers:
			error = ERR_FILE_CORRUPT
			print_debug("CARPE DIEM LOAD GAME: Unable to load player memory, too many factions: Index: %d Range: %d" % [numFactions, numPlayers])
			return null
		
		var maxFreedID = 1
		for f in range(numFactions):
			var factionNum = file.get_8()
			var numTypes = file.get_8()
			lg.playerMemory[i][factionNum] = {}
			
			for t in range(numTypes):
				var type = file.get_8()
				var numUnits = file.get_16()
				var units = {}
				lg.playerMemory[i][factionNum][type] = units
				
				if type != CD.UNIT_COMMAND_STATION:
					for aIdx in range(numUnits):
						var uIdx = Math.u16_to_s16(file.get_16())
						var sinceSighted = file.get_8()
						var unit
						if uIdx < 0:
							units[-uIdx] = sinceSighted
							if -uIdx >= maxFreedID:
								maxFreedID = -uIdx + 1
						elif uIdx < lg.playerUnits[factionNum].size():
							unit = lg.playerUnits[factionNum][uIdx]
							if unit == null:
								var pos = file.get_position()
								unit = load_unit(playerOffsets[factionNum], uIdx)
								if unit != null:
									lg.playerUnits[factionNum][uIdx] = unit
									units[unit] = sinceSighted
								file.seek(pos)
							else:
								units[unit] = sinceSighted
						elif uIdx <= 32767:
							units[unit] = uIdx
							if uIdx >= maxFreedID:
								maxFreedID = uIdx + 1
						else:
							error = ERR_FILE_CORRUPT
							print_debug("CARPE DIEM LOAD GAME: Unable to load player memory. Unit index out of range: Faction: %d Index: %d" % [factionNum, uIdx])
							return null
				else:
					for aIdx in range(numUnits):
						var tIdx = Vector2i.new(file.get_8(), file.get_8())
						var uIdx = Math.u16_to_s16(file.get_16())
						
						var unit
						if uIdx < 0:
							units[tIdx] = -uIdx
							if -uIdx >= maxFreedID:
								maxFreedID = -uIdx + 1
						elif uIdx < lg.playerUnits[factionNum].size():
							unit = lg.playerUnits[factionNum][uIdx]
							if unit == null:
								var pos = file.get_position()
								unit = load_unit(playerOffsets[factionNum], uIdx)
								if unit != null:
									lg.playerUnits[factionNum][uIdx] = unit
									units[tIdx] = unit
								file.seek(pos)
							else:
								units[tIdx] = unit
						elif uIdx <= 32767:
							units[tIdx] = uIdx
							if uIdx >= maxFreedID:
								maxFreedID = uIdx + 1
						else:
							error = ERR_FILE_CORRUPT
							print_debug("CARPE DIEM LOAD GAME: Unable to load player memory. Station index out of range: Faction: %d Index: %d" % [factionNum, uIdx])
							return null
		lg.playerMemoryFreedIDs[i] = maxFreedID
	
	file.seek(arenaOffset)
	for tIdx in range(mapWidth * mapHeight):
		var x = file.get_8()
		var y = file.get_8()
		var cloudColor = Math.u8_to_s8(file.get_8())
		var tile = CDTile.new(x, y, numPlayers, null, cloudColor, allVis, noFog)
		tile.lastSightedTerritory = Math.u8_to_s8(file.get_8())
		
		for i in range(numPlayers):
			if file.get_8():
				tile.mapped[i] = true
			else:
				tile.mapped[i] = false
		
		#has star
		if file.get_8() > 0:
			var loc = Vector3()
			loc.x = file.get_double()
			loc.y = file.get_double()
			loc.z = file.get_double()
			
			tile.star = {"translation": loc, "scale": file.get_double()}
		
		#has asteroid
		if file.get_8() > 0:
			var meshIndex = file.get_8()
			
			var loc = Vector3()
			loc.x = file.get_double()
			loc.y = file.get_double()
			loc.z = file.get_double()
			
			var rot = Vector3()
			rot.x = file.get_double()
			rot.y = file.get_double()
			rot.z = file.get_double()
			
			tile.asteroid = {"meshIndex": meshIndex,
							"translation": loc,
							"rotation": rot,
							"scale": file.get_double()}
		
		#Occupied
		if file.get_8() > 0:
			var pNum = file.get_8()
			var uIdx = file.get_16()
			
			if uIdx >= lg.playerUnits[pNum].size():
				error = ERR_FILE_CORRUPT
				print_debug("CARPE DIEM LOAD GAME: Unable to load tile unit. Unit index out of range: PLAYER: %d Index: %d" % [pNum, uIdx])
				return null
			
			var unit = lg.playerUnits[pNum][uIdx]
			if unit == null:
				var pos = file.get_position()
				unit = load_unit(playerOffsets[pNum], uIdx)
				if unit != null:
					lg.playerUnits[pNum][uIdx] = unit
					unit.tile = tile
				file.seek(pos)
			else:
				unit.tile = tile
		
		#ghostUnit
		if file.get_8() > 0:
			var ghost = {"type": CD.UNIT_COMMAND_STATION,
						"player": file.get_8(),
						"tile": tile}
			
			if ghost.player >= numPlayers:
				error = ERR_FILE_CORRUPT
				print_debug("CARPE DIEM LOAD GAME: Unable to load ghost unit player. Player index out of range: %d" % ghost.player)
				return null
			
			var loc = Vector3()
			loc.x = file.get_double()
			loc.z = file.get_double()
			ghost["translation"] = loc
			
			var rot = Vector3()
			rot.x = file.get_double()
			rot.y = file.get_double()
			rot.z = file.get_double()
			ghost["rotation"] = rot
			
			lg.ghostUnits.push_back(ghost)
		
		var numCollectedStations = file.get_8()
		for cs in range(numCollectedStations):
			var pNum = file.get_8()
			var uIdx = file.get_16()
			
			if uIdx >= lg.playerUnits[pNum].size():
				error = ERR_FILE_CORRUPT
				print_debug("CARPE DIEM LOAD GAME: Unable to load tile collection station. Unit index out of range: Player: %d Index: %d" % [pNum, uIdx])
				return null
			
			var unit = lg.playerUnits[pNum][uIdx]
			if unit == null:
				var pos = file.get_position()
				unit = load_unit(playerOffsets[pNum], uIdx)
				if unit != null:
					lg.playerUnits[pNum][uIdx] = unit
					tile.collectors.push_back(unit)
				file.seek(pos)
			else:
				tile.collectors.push_back(unit)
			if unit.collectedTiles == null:
				unit.collectedTiles = []
			unit.collectedTiles.push_back(tile)
		
		lg.arena.push_back(tile)
	
	var numTurnStations = file.get_8()
	for i in range(numTurnStations):
		var stn = {"add": file.get_8() > 0,
					"tile": lg.arena[(file.get_8() * mapHeight) + file.get_8()],
					"player": file.get_8(),
					"color": file.get_8()}
		lg.turnStations.push_back(stn)
	
	for factions in lg.playerMemory:
		if factions.empty():
			continue
		
		for faction in factions:
			var stations = {}
			for tIdx in factions[faction][CD.UNIT_COMMAND_STATION]:
				if factions[faction][CD.UNIT_COMMAND_STATION][tIdx] == null:
					continue
				
				var tile = lg.arena[(tIdx.x * mapHeight) + tIdx.y]
				stations[tile] = factions[faction][CD.UNIT_COMMAND_STATION][tIdx]
			factions[faction][CD.UNIT_COMMAND_STATION] = stations
	
	loadedGame = lg
	
	return lg


func load_unit(playerOffset : int, unitIndex : int) -> Unit:
	file.seek(playerOffset)
	file.seek(file.get_64() + (8 * unitIndex))
	file.seek(file.get_64())
	
	var unit = CD.get_unit(file.get_8()).instance()
	if unit == null:
		print("LOAD GAME: Attempt to load invalid unit")
		return null
	
	unit.init_from_dossier()
	
	unit.transform.origin.x = file.get_double()
	unit.transform.origin.z = file.get_double()
	
	var rot = Vector3()
	rot.x = file.get_double()
	rot.y = file.get_double()
	rot.z = file.get_double()
	unit.set_rotation(rot)
	
	unit.strength = int(min(file.get_8(), 10))
	unit.moves = int(min(file.get_8(), 1))
	unit.attacks = int(min(file.get_8(), 1))
	
	if unit.type == CD.UNIT_CARGOSHIP:
		unit.mpa = min(file.get_8(), CD.CARGOSHIP_MAX_MPA)
	elif unit.type == CD.UNIT_COMMAND_STATION:
		unit.incomeOre = file.get_8()
		unit.incomeEnergy = file.get_8()
		unit.mpa = min(file.get_8(), CD.COMMAND_STATION_MAX_MPA)
		unit.calcBoundaries = false
		
		var queueSize = file.get_8()
		for q in range(queueSize):
			var bi = BuildItem.new(Dossier.get(file.get_8()))
			bi.dossier.oreCost = file.get_8()
			unit.buildQueue.push_back(bi)
	
	return unit


class LoadedGame extends Reference:
	
	var arena := []
	
	var rseed : int
	
	var playerTypes := []
	var playerHandles := []
	var playerDifficulty := []
	var playerOre := []
	var playerEnergy := []
	var playerUnits := []
	var ghostUnits := []
	var playerSnapshots := []
	var turnStations := []
	var playerMemory := []
	var playerMemoryFreedIDs := []
	
	var gridVisible := false
	var quickInfoVisible := true
	
	var zoomToAttacks := 1
	var camLoc := Vector3()
	var camZoom := 1.0
	
	
	func _init(numPlayers):
		playerHandles.resize(numPlayers)
		playerTypes.resize(numPlayers)
		playerDifficulty.resize(numPlayers)
		playerOre.resize(numPlayers)
		playerEnergy.resize(numPlayers)
		playerMemoryFreedIDs.resize(numPlayers)
		for i in range(numPlayers):
			playerUnits.push_back([])
			playerSnapshots.push_back([])
			playerMemory.push_back({})
