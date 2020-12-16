extends Spatial
class_name Player

const MAX_HANDLE_LENGTH := 10

var game
var arena
var hud

var MAT_COMMAND_STATION
var MAT_NIGHTHAWK
var MAT_GAUMOND
var MAT_THANANOS
var MAT_AURORA
var MAT_CARGOSHIP

var MAT_GHOST_COMMAND_STATION
var MAT_GHOST_NIGHTHAWK
var MAT_GHOST_GAUMOND
var MAT_GHOST_THANANOS
var MAT_GHOST_AURORA
var MAT_GHOST_CARGOSHIP

var sparkMaterial

var turns := []
var snapshotThread : Thread
var snapshotMutex := Mutex.new()
var snapshotFinished := true
var startingTurn := -1

var num : int setget set_player_number, get_player_number
var color : int
var handle : String

var units : Spatial

var territoryMutex
var territoryMutexOnDeck
var territoryMutexCancelled = []
var territoryMesh = load("res://models/shape/cyclic curve/TerritoryBoundary.tscn").instance()

var incomeOre : int = 0
var incomeEnergy : int = 0

var loadout


func _init(game : Spatial, playerNum : int, playerColor : int, playerHandle = null):
	self.game = game
	arena = game.get_node("Arena")
	hud = game.get_node("HUDLayer")
	num = playerNum
	color = playerColor
	name = "Player_" + str(num)
	
	if CD.quality_mobile():
		MAT_COMMAND_STATION = load("res://models/units/CommandStation/CommandStationMat_Mobile.tres").duplicate()
		MAT_NIGHTHAWK = load("res://models/units/NightHawk/NightHawkMat_Mobile.tres").duplicate()
		MAT_GAUMOND = load("res://models/units/Gaumond/GaumondMat_Mobile.tres").duplicate()
		MAT_THANANOS = load("res://models/units/Thananos/ThananosMat_Mobile.tres").duplicate()
		MAT_AURORA = load("res://models/units/AuroraClassBattleship/AuroraClassBattleshipMat_Mobile.tres").duplicate()
		MAT_CARGOSHIP = load("res://models/units/CargoShip/CargoShipMat_Mobile.tres").duplicate()
	else:
		MAT_COMMAND_STATION = load("res://models/units/CommandStation/CommandStationMat.tres").duplicate()
		MAT_NIGHTHAWK = load("res://models/units/NightHawk/NightHawkMat.tres").duplicate()
		MAT_GAUMOND = load("res://models/units/Gaumond/GaumondMat.tres").duplicate()
		MAT_THANANOS = load("res://models/units/Thananos/ThananosMat.tres").duplicate()
		MAT_AURORA = load("res://models/units/AuroraClassBattleship/AuroraClassBattleshipMat.tres").duplicate()
		MAT_CARGOSHIP = load("res://models/units/CargoShip/CargoShipMat.tres").duplicate()
	
	sparkMaterial = CD.get_spark_material(color)
	
	units = Spatial.new()
	units.name = "Units"
	add_child(units)
	
	var fc = arena.get_node("FogControl")
	if !fc.initialized:
		add_to_group("fog_init_notify")
	else:
		fog_initialized(fc)
	
	if playerHandle != null && !playerHandle.empty():
		handle = playerHandle
	elif num == game.thisPlayer:
		handle = tr("label_player_handle") % (playerNum + 1)
	else:
		handle = tr("label_bot_handle") % [randi() % 3, (playerNum + 1)]
		var status = ""
		if randf() >= 0.6:
			var rand = randf()
			if rand >= 0.6:
				status = "B%s" % ((randi() % 8) + 1)
			elif rand >= 0.3:
				status = "A%s" % ((randi() % 8) + 1)
			else:
				status = "RC%s" % ((randi() % 8) + 1)
		
		if !status.empty() && handle.length() + status.length() <= 10:
			handle = handle + status
	
	if num == game.thisPlayer:
		loadout = PlayerLoadout.new()
	else:
		loadout = AILoadout.new(self)
	
	if handle.length() > MAX_HANDLE_LENGTH:
		handle.erase(MAX_HANDLE_LENGTH, handle.length() - MAX_HANDLE_LENGTH)


func fog_initialized(fogControl):
	MAT_COMMAND_STATION.set_shader_param("albedo_paint", get_color())
	MAT_COMMAND_STATION.set_shader_param("mask_tex", fogControl.get_mask())
	MAT_COMMAND_STATION.set_shader_param("mask_offset", fogControl.get_mask_offset())
	MAT_COMMAND_STATION.set_shader_param("mask_scale", fogControl.get_mask_world_scale())
	MAT_COMMAND_STATION.set_shader_param("fog", fogControl.fogMapped)
	
	MAT_NIGHTHAWK.set_shader_param("albedo_paint", get_color())
	MAT_NIGHTHAWK.set_shader_param("mask_tex", fogControl.get_mask())
	MAT_NIGHTHAWK.set_shader_param("mask_offset", fogControl.get_mask_offset())
	MAT_NIGHTHAWK.set_shader_param("mask_scale", fogControl.get_mask_world_scale())
	MAT_NIGHTHAWK.set_shader_param("fog", fogControl.fogMapped)
	
	MAT_GAUMOND.set_shader_param("albedo_paint", get_color())
	MAT_GAUMOND.set_shader_param("mask_tex", fogControl.get_mask())
	MAT_GAUMOND.set_shader_param("mask_offset", fogControl.get_mask_offset())
	MAT_GAUMOND.set_shader_param("mask_scale", fogControl.get_mask_world_scale())
	MAT_GAUMOND.set_shader_param("fog", fogControl.fogMapped)
	
	MAT_THANANOS.set_shader_param("albedo_paint", get_color())
	MAT_THANANOS.set_shader_param("mask_tex", fogControl.get_mask())
	MAT_THANANOS.set_shader_param("mask_offset", fogControl.get_mask_offset())
	MAT_THANANOS.set_shader_param("mask_scale", fogControl.get_mask_world_scale())
	MAT_THANANOS.set_shader_param("fog", fogControl.fogMapped)
	
	MAT_AURORA.set_shader_param("albedo_paint", get_color())
	MAT_AURORA.set_shader_param("mask_tex", fogControl.get_mask())
	MAT_AURORA.set_shader_param("mask_offset", fogControl.get_mask_offset())
	MAT_AURORA.set_shader_param("mask_scale", fogControl.get_mask_world_scale())
	MAT_AURORA.set_shader_param("fog", fogControl.fogMapped)
	
	MAT_CARGOSHIP.set_shader_param("albedo_paint", get_color())
	MAT_CARGOSHIP.set_shader_param("mask_tex", fogControl.get_mask())
	MAT_CARGOSHIP.set_shader_param("mask_offset", fogControl.get_mask_offset())
	MAT_CARGOSHIP.set_shader_param("mask_scale", fogControl.get_mask_world_scale())
	MAT_CARGOSHIP.set_shader_param("fog", fogControl.fogMapped)
	
	if num == game.thisPlayer:
		MAT_COMMAND_STATION.set_shader_param("alpha_mod", 1.0)
		MAT_NIGHTHAWK.set_shader_param("alpha_mod", 1.0)
		MAT_GAUMOND.set_shader_param("alpha_mod", 1.0)
		MAT_THANANOS.set_shader_param("alpha_mod", 1.0)
		MAT_AURORA.set_shader_param("alpha_mod", 1.0)
		MAT_CARGOSHIP.set_shader_param("alpha_mod", 1.0)
	
	MAT_GHOST_COMMAND_STATION = MAT_COMMAND_STATION.duplicate()
	MAT_GHOST_NIGHTHAWK = MAT_NIGHTHAWK.duplicate()
	MAT_GHOST_GAUMOND = MAT_GAUMOND.duplicate()
	MAT_GHOST_THANANOS = MAT_THANANOS.duplicate()
	MAT_GHOST_AURORA = MAT_AURORA.duplicate()
	MAT_GHOST_CARGOSHIP = MAT_CARGOSHIP.duplicate()
	
	MAT_GHOST_COMMAND_STATION.set_shader_param("is_ghost", 1.0)
	MAT_GHOST_COMMAND_STATION.set_shader_param("fog", fogControl.fogMapped)
	
	MAT_GHOST_NIGHTHAWK.set_shader_param("is_ghost", 1.0)
	MAT_GHOST_NIGHTHAWK.set_shader_param("fog", fogControl.fogMapped)
	
	MAT_GHOST_GAUMOND.set_shader_param("is_ghost", 1.0)
	MAT_GHOST_GAUMOND.set_shader_param("fog", fogControl.fogMapped)
	
	MAT_GHOST_THANANOS.set_shader_param("is_ghost", 1.0)
	MAT_GHOST_THANANOS.set_shader_param("fog", fogControl.fogMapped)
	
	MAT_GHOST_AURORA.set_shader_param("is_ghost", 1.0)
	MAT_GHOST_AURORA.set_shader_param("fog", fogControl.fogMapped)
	
	MAT_GHOST_CARGOSHIP.set_shader_param("is_ghost", 1.0)
	MAT_GHOST_CARGOSHIP.set_shader_param("fog", fogControl.fogMapped)
	
	
	if num != game.thisPlayer:
		sparkMaterial.set_shader_param("mask_tex", fogControl.get_mask())
		sparkMaterial.set_shader_param("mask_offset", fogControl.get_mask_offset())
		sparkMaterial.set_shader_param("mask_scale", fogControl.get_mask_world_scale())
	else:
		sparkMaterial.set_shader_param("mask_tex", null)
	
	var territoryMat = territoryMesh.material_override.duplicate()
	territoryMat.set_shader_param("mask_tex", fogControl.get_mask())
	territoryMat.set_shader_param("mask_offset", fogControl.get_mask_offset())
	territoryMat.set_shader_param("mask_scale", fogControl.get_mask_world_scale())
	if num == game.thisPlayer:
		territoryMat.set_shader_param("alpha_mod", 1.0)
	territoryMesh.material_override = territoryMat
	
	match color:
		CD.PLAYER_BLUE:
			territoryMat.set_shader_param("tex", load("res://textures/fx/gradients/territory/territory_blue.png"))
		CD.PLAYER_RED:
			territoryMat.set_shader_param("tex", load("res://textures/fx/gradients/territory/territory_red.png"))
		CD.PLAYER_PURPLE:
			territoryMat.set_shader_param("tex", load("res://textures/fx/gradients/territory/territory_purple.png"))
		CD.PLAYER_GREEN:
			territoryMat.set_shader_param("tex", load("res://textures/fx/gradients/territory/territory_green.png"))
		CD.PLAYER_CYAN:
			territoryMat.set_shader_param("tex", load("res://textures/fx/gradients/territory/territory_cyan.png"))
		CD.PLAYER_YELLOW:
			territoryMat.set_shader_param("tex", load("res://textures/fx/gradients/territory/territory_yellow.png"))
		CD.PLAYER_ORANGE:
			territoryMat.set_shader_param("tex", load("res://textures/fx/gradients/territory/territory_orange.png"))


func set_player_number(number):
	pass


func get_player_number() -> int:
	return num


func is_local_player() -> bool:
	return num == game.thisPlayer


func get_color() -> Color:
	return CD.get_player_color(color)


func get_all_units():
	return units.get_children()


func get_units():
	var units = []
	for u in self.units.get_children():
		if !u.type == CD.UNIT_COMMAND_STATION:
			units.push_back(u)
	
	return units


func get_command_stations():
	var stations = []
	for u in units.get_children():
		if u.type == CD.UNIT_COMMAND_STATION:
			stations.push_back(u)
	
	return stations


func add_unit(unit):
	var qInfo
	if is_local_player():
		if unit.type == CD.UNIT_COMMAND_STATION:
			qInfo = preload("res://scenes/QuickInfo/QuickInfo_Station.tscn").instance()
		else:
			qInfo = preload("res://scenes/QuickInfo/QuickInfo_Player.tscn").instance()
	else:
		qInfo = preload("res://scenes/QuickInfo/QuickInfo.tscn").instance()
	qInfo.unit = unit
	units.add_child(unit)
	game.get_node("QuickInfo").add_child(qInfo)
	
	loadout.add_unit(unit)
	
	if unit.type == CD.UNIT_COMMAND_STATION:
		if game.LOADED:
			game.turnStations.push_back({"add": true,
										"tile": unit.tile,
										"player": num,
										"color": color})
		if !is_local_player():
			for buildItem in unit.buildQueue:
				loadout.add_build(buildItem)
	
	for player in game.players:
		if player != self && !player.is_local_player() && unit.tile.is_visible(player.num):
			player.factionManager.unit_sighted(unit)


func remove_unit(unit, checkAlive := true):
	for player in game.players:
		if player != self && !player.is_local_player():
			if unit.type == CD.UNIT_COMMAND_STATION:
				player.factionManager.erase_command_station(unit.tile, true)
			else:
				player.factionManager.erase_unit(unit, true)
	
	units.remove_child(unit)
	
	if unit.type == CD.UNIT_COMMAND_STATION:
		game.turnStations.push_back({"add": false,
									"tile": unit.tile,
									"player": num,
									"color": color})
	
	if unit.mpa > 0:
		if unit.type == CD.UNIT_COMMAND_STATION && !is_local_player():
			loadout.subtract_station_mpa(unit.mpa)
		else:
			loadout.subtract_unit_type(CD.UNIT_MPA, unit.mpa)
	
	if !is_local_player() && unit.type == CD.UNIT_COMMAND_STATION:
		for buildItem in unit.buildQueue:
			loadout.subtract_build(buildItem)
	
	loadout.subtract_unit(unit)
	unit.delete()
	
	if !is_alive() && checkAlive:
		if game.playerTurn != num:
			turns.push_back(turn_snapshot(self))
		elif game.is_local_turn():
			game.end_turn()


func get_material(unitType):
	match unitType:
		CD.UNIT_COMMAND_STATION:
			return MAT_COMMAND_STATION
		CD.UNIT_NIGHTHAWK:
			return MAT_NIGHTHAWK
		CD.UNIT_GAUMOND:
			return MAT_GAUMOND
		CD.UNIT_THANANOS:
			return MAT_THANANOS
		CD.UNIT_AURORA:
			return MAT_AURORA
		CD.UNIT_CARGOSHIP:
			return MAT_CARGOSHIP
		_:
			return MAT_NIGHTHAWK


func get_ghost_material(unitType):
	match unitType:
		CD.UNIT_COMMAND_STATION:
			return MAT_GHOST_COMMAND_STATION
		CD.UNIT_NIGHTHAWK:
			return MAT_GHOST_NIGHTHAWK
		CD.UNIT_GAUMOND:
			return MAT_GHOST_GAUMOND
		CD.UNIT_THANANOS:
			return MAT_GHOST_THANANOS
		CD.UNIT_AURORA:
			return MAT_GHOST_AURORA
		CD.UNIT_CARGOSHIP:
			return MAT_GHOST_CARGOSHIP
		_:
			return MAT_GHOST_NIGHTHAWK


func get_ghost(unitType):
	var unit = CD.get_unit(unitType).instance()
	var ghost := GhostUnit.new()
	ghost.playerNum = num
	ghost.mesh = unit.get_node(unit.geomPath).mesh
	ghost.set_surface_material(0, get_ghost_material(unitType))
	return ghost


func is_alive():
	return !units.get_children().empty()


func start_turn():
	if startingTurn < 0:
		startingTurn = 0
	else:
		startingTurn = -1
		if num == game.thisPlayer:
			hud.infoView.reset_turn_button()


func finish_turn():
	snapshotFinished = false
	snapshotThread = Thread.new()
	snapshotThread.start(self, "turn_snapshot", [self, game.turnStations])


func turn_snapshot(data) -> Dictionary:
	var snpsht
	if data is Array:
		snpsht = Turn_Snapshot.take_snapshot(data[0], data[1])
		data[1].clear()
	else:
		snpsht = Turn_Snapshot.take_snapshot(data)
	snapshotMutex.lock()
	snapshotFinished = true
	snapshotMutex.unlock()
	return snpsht


func set_income():
	for unit in units:
		if unit.type == CD.UNIT_COMMAND_STATION:
			incomeOre += unit.incomeOre
			incomeEnergy += unit.incomeEnergy


func get_territory():
	var collectedTiles = []
	for u in get_all_units():
		if u.type == CD.UNIT_COMMAND_STATION:
			var uTiles = u.get_actual_collected_tiles()
			for t in uTiles:
				collectedTiles.push_back(t)
	
	return collectedTiles


func calc_boundaries():
	if territoryMutex != null:
		if territoryMutex.try_lock() == OK:
			territoryMutex.cancelled = true
			territoryMutex.unlock()
		else:
			territoryMutexCancelled.push_back(territoryMutex)
		territoryMutex = null
	
	var territory = get_territory()
	if territory.empty():
		if territoryMesh.is_inside_tree():
			game.arena.get_node("Boundaries").remove_child(territoryMesh)
		return
	
	territoryMutexOnDeck = TerritoryCurveTrac.new(territory)


func _process(delta):
	if startingTurn >= 0:
		var units = get_all_units()
		var start = startingTurn
		var stop = min(start + 5, units.size())
		if stop > start:
			for i in range(start, stop):
				units[i].reset_on_turn()
			startingTurn = stop
		else:
			start_turn()
	elif snapshotThread != null && snapshotMutex.try_lock() == OK:
		if snapshotFinished:
			snapshotMutex.unlock()
			turns.push_back(snapshotThread.wait_to_finish())
			snapshotThread = null
			game.next_turn()
		else:
			snapshotMutex.unlock()
	
	if !territoryMutexCancelled.empty():
		var idx = 0
		while !territoryMutexCancelled.empty():
			var mutex = territoryMutexCancelled[idx]
			if mutex.try_lock() == OK:
				mutex.cancelled = true
				mutex.unlock()
				territoryMutexCancelled.remove(idx)
			else:
				idx += 1
	
	var newTerritoryGen = false
	if territoryMutexOnDeck != null:
		newTerritoryGen = game.TERRITORY_GEN.add_task(territoryMutexOnDeck)
		if newTerritoryGen:
			territoryMutex = territoryMutexOnDeck
			territoryMutexOnDeck = null
	
	if (territoryMutex != null and !newTerritoryGen
			and territoryMutex.try_lock() == OK):
		if territoryMutex.cancelled:
			territoryMutex.unlock()
			territoryMutex = null
		elif territoryMutex.boundaryCurves == null:
			territoryMutex.unlock()
		else:
			territoryMesh.update_geometries(territoryMutex.boundaryCurves)
			if !territoryMesh.is_inside_tree():
				game.arena.get_node("Boundaries").add_child(territoryMesh)
			territoryMutex.unlock()
			territoryMutex = null


func cleanup():
	if !territoryMesh.get_parent() == null:
		territoryMesh.free()


class TerritoryCurveTrac extends Mutex:
	var territory
	var boundaryCurves
	var cancelled = false
	
	func _init(territoryTiles):
		territory = territoryTiles
