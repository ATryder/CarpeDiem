extends AI_Task
class_name AI_Task_Repair

var cargoRepair : AI_Task_CargoRepair


func _init(var objectiveUnit):
	self.objectiveUnit = objectiveUnit
	objective = objectiveUnit.tile
	priority = PRIORITY_REPAIR
	priorityMod =  1.0 - (objectiveUnit.strength / float(objectiveUnit.maxStrength))


func exec():
	if unit.strength == unit.maxStrength || objectiveUnit.mpa <= 0:
		unit.player.exec_next_task()
		return
	
	if objectiveUnit.tile.get_surrounding().has(unit.tile):
		var requestedMPA = int(ceil((unit.maxStrength - unit.strength) / float(CD.MPA_HEAL_AMOUNT)))
		var mpaAmount = int(min(objectiveUnit.mpa, requestedMPA))
		if mpaAmount <= 0:
			unit.player.exec_next_task()
			return
		
		var healAmount = mpaAmount * CD.MPA_HEAL_AMOUNT
		unit.strength += healAmount
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
			unit.player.game.spawn_mpa_strength_effects(unit.tile)
		
		if unit.moves <= 0:
			attack_target_of_opportunity()
		else:
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
	
	if cargoRepair != null && objectiveUnit.moves > 0:
		unit.player.executableTasks.push_front(self)
		var cr = cargoRepair
		cargoRepair = null
		cr.exec()
		cr = null
		return
	
	move_next_to_objective()
