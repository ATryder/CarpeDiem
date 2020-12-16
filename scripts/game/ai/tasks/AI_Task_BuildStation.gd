extends AI_Task
class_name AI_Task_BuildStation

var prospectiveWeight : float
var nearbyEnemy : bool
var ore : int
var energy : int

var totalPath
var tmpObjective
var availableArena


func _init(psa : PossibleStationArea, stations := []):
	ore = psa.ore
	energy = psa.energy
	objective = psa.origin
	priority = PRIORITY_BUILDSTATION
	nearbyEnemy = psa.nearbyEnemy
	priorityMod = psa.ore + min(8.0, psa.energy * 2)
	prospectiveWeight = priorityMod / 4.5
	priorityMod *= 0.5
	
	if stations.empty():
		return
	
	var minDist = INF
	for station in stations:
		var dist = station.tile.worldLoc.distance_to(objective.worldLoc)
		if dist < minDist:
			minDist = dist
	
	if minDist / CD.BASE_TILE_SIZE <= CD.COMMAND_STATION_RESOURCE_RANGE * 3:
		prospectiveWeight *= 2


func assign(unit : Unit, score : float) -> bool:
	if (is_assigned() || unit.player.mai.assignedUnits.has(unit)
			|| (unit.tile.is_collected()
			&& unit.player.factionManager.factions.has(unit.tile.collectors[0].player))):
		return false
	
	var mRange = unit.get_movement_range()
	if objective != unit.tile && !mRange.has(objective):
		if availableArena != null:
			totalPath = Math.path_to(unit.tile, objective, availableArena, unit.player)
			if totalPath.empty():
				return false
			
			for i in range(1, totalPath.size() + 1):
				var t = totalPath[totalPath.size() - i]
				if mRange.has(t):
					tmpObjective = t
					break
			
			if tmpObjective == null:
				return false
			
			var inRange = Math.get_tile_range(tmpObjective, 6.0)
			for t in inRange:
				if (t.is_visible(unit.player.num) && t.has_other_player(unit.player.num)
						&& unit.player.factionManager.factions.has(t.unit.player)):
					return false
		else:
			mRange = unit.get_territory_safe_movement_range()
			if mRange.empty():
				return false
			
			var tile = Math.get_closest_tile_in_range(objective, mRange)
			if (tile == null || tile.is_occupied()
					|| tile.worldLoc.distance_to(objective.worldLoc) - unit.tile.worldLoc.distance_to(objective.worldLoc) >= 0.001):
				return false
			
			var inRange = Math.get_tile_range(tile, 6.0)
			for t in inRange:
				if (t.is_visible(unit.player.num) && t.has_other_player(unit.player.num)
						&& unit.player.factionManager.factions.has(t.unit.player)):
					return false
	
	self.unit = unit
	self.score = score
	unit.player.mai.tasks.push_back(self)
	unit.player.mai.assignedUnits.push_back(unit)
	return true


func exec():
	if objective.is_collected():
		if unit.player.mai != null:
			unit.player.mai.lock()
			var loopFin = unit.player.mai.loopFin
			unit.player.mai.unlock()
			if loopFin:
				unit.player.exec_next_task()
			else:
				unit.player.exec_ai()
		else:
			unit.player.exec_next_task()
		return
	
	if objective == unit.tile:
		var player = unit.player
		player.remove_unit(unit, false)
		var commandStation = CD.get_unit(CD.UNIT_COMMAND_STATION).instance()
		commandStation.tile = objective
		commandStation.attacks = 0
		commandStation.execAI_Task = true
		commandStation.calcBoundaries = true
		player.add_unit(commandStation)
		
		if Math.is_near_visible(unit.tile, player.game.thisPlayer):
			player.game.spawn_launch_effects(objective, player)
		return
	
	if unit.moves <= 0:
		unit.player.exec_next_task()
		return
	
	var tiles = unit.get_movement_range()
	if tiles.has(objective):
		var path = Math.path_to(unit.tile, objective, tiles)
		unit.player.executableTasks.push_front(self)
		unit.move_along_path(path)
		return
	
	if tmpObjective != null:
		if !tiles.has(tmpObjective):
			if totalPath != null && !totalPath.empty():
				for i in range(1, totalPath.size() + 1):
					var t = totalPath[totalPath.size() - i]
					if tiles.has(t):
						tmpObjective = t
						break
			
			if tiles.has(tmpObjective):
				var path = Math.path_to(unit.tile, tmpObjective, tiles)
				unit.move_along_path(path)
			else:
				var tile = Math.get_closest_tile_in_range(tmpObjective, tiles)
				if tile == null || tile.is_occupied():
					unit.player.exec_next_task()
					return
			
				var path = Math.path_to(unit.tile, tile, tiles)
				unit.move_along_path(path)
			return
		else:
			var path = Math.path_to(unit.tile, tmpObjective, tiles)
			unit.move_along_path(path)
			return
	
	var sTiles = unit.get_territory_safe_movement_range()
	if sTiles.empty():
		unit.player.exec_next_task()
		return
	
	var tile = Math.get_closest_tile_in_range(objective, sTiles)
	if tile == null || tile.is_occupied():
		unit.player.exec_next_task()
		return
	
	var path = Math.path_to(unit.tile, tile, tiles)
	if path.empty():
		unit.player.exec_next_task()
		return
	unit.move_along_path(path)
