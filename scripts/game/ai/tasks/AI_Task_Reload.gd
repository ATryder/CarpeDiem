extends AI_Task
class_name AI_Task_Reload

var totalPath
var tmpObjective
var availableArena


func _init(var objectiveUnit):
	self.objectiveUnit = objectiveUnit
	objective = objectiveUnit.tile
	priority = PRIORITY_RELOAD
	priorityMod = 1.0 + (1.0 - (objectiveUnit.mpa / float(CD.CARGOSHIP_MAX_MPA)))


func assign(unit : Unit, score : float) -> bool:
	if is_assigned() || unit.player.mai.assignedUnits.has(unit):
		return false
	
	var tile = Math.get_closest_surrounding_tile(objective, unit.tile)
	var count = 0
	while tile != null && tile.is_occupied() && count < 10:
		count += 1
		tile = Math.get_closest_surrounding_tile(tile, unit.tile)
	
	if tile == null || tile.is_occupied():
		return false
	
	var mRange = unit.get_territory_safe_movement_range()
	if !mRange.has(tile):
		if availableArena != null:
			totalPath = Math.path_to(unit.tile, tile, availableArena, unit.player)
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
			tile = Math.get_closest_tile_in_range(tile, mRange)
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
	if unit.tile.get_surrounding().has(objective):
		var requestedMPA = CD.CARGOSHIP_MAX_MPA - unit.mpa
		var mpaAmount = int(min(requestedMPA, objectiveUnit.mpa))
		if mpaAmount <= 0:
			unit.player.exec_next_task()
			return
		
		unit.mpa += mpaAmount
		objectiveUnit.mpa -= mpaAmount
		objectiveUnit.player.loadout.subtract_station_mpa(mpaAmount)
		
		if objectiveUnit.type == CD.UNIT_COMMAND_STATION:
			while (objectiveUnit.buildItem != null
					&& objectiveUnit.buildItem.get_type() == CD.UNIT_MPA
					&& objectiveUnit.get_remaining_build_turns() <= 0
					&& objectiveUnit.mpa < CD.COMMAND_STATION_MAX_MPA):
				objectiveUnit.remove_build(objectiveUnit.buildItem)
				objectiveUnit.mpa += 1
				objectiveUnit.player.loadout.add_station_mpa()
				objectiveUnit.player.loadout.subtract_build(CD.UNIT_MPA)
		
		if Math.is_near_visible(unit.tile, unit.player.game.thisPlayer):
			unit.player.game.spawn_mpa_effects(unit.tile)
		unit.player.exec_next_task()
		return
	
	if tmpObjective != null:
		var tiles = unit.get_movement_range()
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
	
	move_next_to_objective()
