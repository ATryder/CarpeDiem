extends AI_Task
class_name AI_Task_CargoRepair


func _init(var objectiveUnit):
	self.objectiveUnit = objectiveUnit
	objective = objectiveUnit.tile
	priority = PRIORITY_CARGOREPAIR
	priorityMod = 1.0 - (objectiveUnit.strength / float(objectiveUnit.maxStrength))


func assign(unit : Unit, score : float) -> bool:
	if is_assigned() || unit.player.mai.assignedUnits.has(unit):
		return false
	
	var moveRange = unit.get_movement_range()
	if !unit.tile.get_surrounding().has(objective) && !moveRange.has(objective):
		var tile = Math.get_closest_tile_in_range(objective, moveRange)
		if tile == null || tile.is_occupied():
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
	if unit.tile.get_surrounding().has(objectiveUnit.tile):
		var requestedMPA = int(ceil((objectiveUnit.maxStrength - objectiveUnit.strength) / float(CD.MPA_HEAL_AMOUNT)))
		var mpaAmount = int(min(unit.mpa, requestedMPA))
		if mpaAmount <= 0:
			unit.player.exec_next_task()
			return
		
		var healAmount = mpaAmount * CD.MPA_HEAL_AMOUNT
		objectiveUnit.strength += healAmount
		unit.mpa -= mpaAmount
		unit.player.loadout.subtract_unit_type(CD.UNIT_MPA, mpaAmount)
		if Math.is_near_visible(objectiveUnit.tile, unit.player.game.thisPlayer):
			unit.player.game.spawn_mpa_strength_effects(objectiveUnit.tile)
		
		unit.player.exec_next_task()
		return
	
	move_next_to_objective(true, objectiveUnit.tile)
