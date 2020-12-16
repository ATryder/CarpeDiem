extends Reference


var playerNum : int
var factions := {}

var freedID := 1


func _init(enemyFactions : Array, playerNumber : int):
	playerNum = playerNumber
	var factionAssets = preload("res://scripts/game/ai/FactionAssets.gd")
	for player in enemyFactions:
		factions[player] = factionAssets.new(player.num, playerNum, self)


func new_freed_id() -> int:
	var id = freedID
	freedID += 1
	if freedID >= 32767:
		freedID = 1
	
	return id


func get_total_unit_amount(type : int) -> int:
	var total := 0
	for player in factions:
		total += factions[player].get_unit_amount(type)
	return total


func get_units(type : int) -> Array:
	var units := []
	for player in factions:
		var factionUnits = factions[player].get_units(type)
		for unit in factionUnits:
			units.append(unit)
	return units


func get_visible_units(type: int) -> Array:
	var units := []
	for player in factions:
		var factionUnits = factions[player].get_visible_units(type)
		for unit in factionUnits:
			units.append(unit)
	return units


func has_station(station) -> bool:
	for player in factions:
		if factions[player].get_command_stations().has(station):
			return true
	
	
	return false


func has_station_tile(tile) -> bool:
	for player in factions:
		if factions[player].units[CD.UNIT_COMMAND_STATION].has(tile):
			return true
	
	return false


func get_command_stations() -> Array:
	var stations := []
	for player in factions:
		var factionStations = factions[player].get_command_stations()
		for station in factionStations:
			if station != null:
				stations.push_back(station)
	return stations


func get_command_station_tile(station) -> CDTile:
	for player in factions:
		if factions[player].get_command_stations().has(station):
			return factions[player].get_command_station_tile(station)
	return null


func get_all_ships() -> Array:
	var ships := []
	for x in range(CD.TOTAL_TYPES):
		if x == CD.UNIT_COMMAND_STATION || x == CD.UNIT_MPA:
			continue
		for player in factions:
			var factionUnits = factions[player].get_units(x)
			for unit in factionUnits:
				if unit != null && !(unit is int):
					ships.push_back(unit)
	return ships


func get_visible_ships() -> Array:
	var ships := []
	for x in range(CD.TOTAL_TYPES):
		if x == CD.UNIT_COMMAND_STATION || x == CD.UNIT_MPA:
			continue
		for player in factions:
			var factionUnits = factions[player].get_visible_units(x)
			for unit in factionUnits:
				ships.push_back(unit)
	return ships


func unit_sighted(unit) -> bool:
	if !factions.has(unit.player):
		return false
	
	var faction = factions[unit.player]
	return faction.unit_sighted(unit)


func erase_unit(unit, checkVisibility := false):
	if !factions.has(unit.player):
		return
	
	var faction = factions[unit.player]
	faction.erase_unit(unit, checkVisibility && !unit.tile.is_visible(playerNum))


func erase_command_station(tile : CDTile, checkVisibility := false):
	for faction in factions:
		factions[faction].erase_command_station(tile, checkVisibility && !tile.is_visible(playerNum))


func erase_faction(player):
	factions.erase(player)


func update_tile(tile : CDTile) -> bool:
	if tile.has_other_player(playerNum) && factions.has(tile.get_player()):
		if tile.is_collected() && factions.has(tile.collectors[0].player):
			if tile.unit.type == CD.UNIT_COMMAND_STATION:
				return factions[tile.get_player()].unit_sighted(tile.unit)
			var updateSightings = factions[tile.collectors[0].player].unit_sighted(tile.collectors[0])
			return factions[tile.get_player()].unit_sighted(tile.unit) || updateSightings
		else:
			return factions[tile.get_player()].unit_sighted(tile.unit)
	
	if tile.is_collected() && factions.has(tile.collectors[0].player):
		var updateSightings = false
		for player in factions:
			if factions[player].units[CD.UNIT_COMMAND_STATION].has(tile):
				factions[player].erase_command_station(tile)
				updateSightings = true
		return factions[tile.collectors[0].player].unit_sighted(tile.collectors[0]) || updateSightings
	
	for player in factions:
		if factions[player].units[CD.UNIT_COMMAND_STATION].has(tile):
			factions[player].erase_command_station(tile)
			return true
	
	return false


func update():
	for player in factions:
		factions[player].update()
