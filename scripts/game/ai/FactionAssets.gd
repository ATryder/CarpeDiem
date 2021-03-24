extends Reference


const FORGET_AFTER := 14

var fManager

var playerNum : int
var factionNum : int
var units := {}


func _init(factionNumber: int, playerNumber : int, factionManager):
	fManager = factionManager
	for i in range(CD.TOTAL_TYPES):
		if i == CD.UNIT_MPA:
			continue
		units[i] = {}
	playerNum = playerNumber
	factionNum = factionNumber


func get_unit_amount(type : int) -> int:
	return units[type].size()


func get_units(type : int) -> Array:
	return units[type].keys()


func get_visible_units(type : int) -> Array:
	var uts := []
	for u in units[type]:
		if (u != null && !(u is int) && units[type][u] == 0
				&& is_instance_valid(u) && u.has_method("is_alive") && u.type == type):
			uts.push_back(u)
	return uts


func get_command_stations() -> Array:
	return units[CD.UNIT_COMMAND_STATION].values()


func get_command_station_tile(station) -> CDTile:
	var stations = units[CD.UNIT_COMMAND_STATION]
	for tile in stations:
		var s = stations[tile]
		if s is int:
			if station is int && s == station:
				return tile
		elif !(station is int) && s == station:
			return tile
	return null


func unit_sighted(unit) -> bool:
	if unit.player.num != factionNum:
		return false
	
	var typedUnits = units[unit.type]
	if unit.type == CD.UNIT_COMMAND_STATION:
		if !typedUnits.has(unit.tile) || typedUnits[unit.tile] != unit:
			typedUnits[unit.tile] = unit
			return true
		return false
	
	var sightingsUpdated = false
	if units[CD.UNIT_COMMAND_STATION].has(unit.tile):
		erase_command_station(unit.tile)
		sightingsUpdated = true
	
	if !typedUnits.has(unit):
		typedUnits[unit] = 0
		return true
	
	sightingsUpdated = typedUnits[unit] > 0 || sightingsUpdated
	typedUnits[unit] = 0
	return sightingsUpdated


func erase_unit(unit, keepCount := false):
	if keepCount:
		if !units[unit.type].has(unit):
			return
		
		var amount = units[unit.type][unit]
		units[unit.type].erase(unit)
		units[unit.type][fManager.new_freed_id()] = amount
	else:
		units[unit.type].erase(unit)


func erase_command_station(tile : CDTile, keep := false):
	if !units[CD.UNIT_COMMAND_STATION].has(tile):
		return
	
	if keep:
		units[CD.UNIT_COMMAND_STATION][tile] = fManager.new_freed_id()
	else:
		units[CD.UNIT_COMMAND_STATION].erase(tile)


func update_tile(tile : CDTile) -> bool:
	if tile.has_other_player(playerNum) && tile.get_player_num() == factionNum:
		return unit_sighted(tile.unit)
	
	if units[CD.UNIT_COMMAND_STATION].has(tile):
		erase_command_station(tile)
		return true
	return false


func update():
	for type in units:
		var typedUnits = units[type]
		var toKeep := {}
		if type == CD.UNIT_COMMAND_STATION:
			for tile in typedUnits:
				if typedUnits[tile] != null:
					toKeep[tile] = typedUnits[tile]
			
			units[type] = toKeep
			continue
		
		for unit in typedUnits:
			if unit != null:
				if (unit is int || !is_instance_valid(unit) || !unit.has_method("is_alive")
						|| !unit.tile.is_visible(playerNum) || unit.type != type):
					var val = typedUnits[unit] + 1
					if val <= FORGET_AFTER:
						toKeep[unit] = val
				else:
					toKeep[unit] = typedUnits[unit]
		units[type] = toKeep
