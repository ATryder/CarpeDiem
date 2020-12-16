extends AI_Task
class_name AI_Task_AttackShip

var projectedStrength
var attackStation : bool


func _init(objectiveUnit, objectiveTile = null, objectiveStation := false):
	attackStation = objectiveStation
	priority = PRIORITY_ATTACKSHIP
	if !is_valid_unit(objectiveUnit, objectiveTile):
		if objectiveUnit is int:
			objectiveInt = objectiveUnit
		if objectiveTile != null:
			objective = objectiveTile
			projectedStrength = 10
			priorityMod = 0.0
		else:
			projectedStrength = 0
			priorityMod = 0.0
	elif objectiveUnit.type == CD.UNIT_CARGOSHIP:
		self.objectiveUnit = objectiveUnit
		objective = objectiveUnit.tile
		projectedStrength = 10
		priorityMod = 1.01
	else:
		self.objectiveUnit = objectiveUnit
		objective = objectiveUnit.tile
		projectedStrength = objectiveUnit.strength
		if attackStation:
			priorityMod = 1.0 - (objectiveUnit.strength / float(objectiveUnit.maxStrength))
		else:
			priorityMod = abs(1.0 - (objectiveUnit.strength / (objectiveUnit.maxStrength * 0.5)))


func assign(unit : Unit, score : float) -> bool:
	if unit.player.mai.assignedUnits.has(unit) || projectedStrength <= 0:
		return false
	
	if !is_assigned():
		self.unit = unit
		self.score = score
		if is_valid_unit(objectiveUnit, objective):
			projectedStrength = max(projectedStrength - Math.calc_attack_amount(unit, objectiveUnit, true), 0)
		else:
			projectedStrength = max(projectedStrength - Dossier.get(unit.type).attackValues[CD.UNIT_COMMAND_STATION], 0)
		unit.player.mai.tasks.push_back(self)
		unit.player.mai.assignedUnits.push_back(unit)
		return true
	
	var task
	if priority != PRIORITY_DEFEND:
		task = get_script().new(objectiveUnit, objective, attackStation)
	else:
		task = get_script().new(null, objectiveUnit)
		task.priorityMod = priorityMod
	
	task.projectedStrength = projectedStrength
	if (priority != PRIORITY_DEFEND && is_valid_unit(objectiveUnit, objective)
			&& objectiveUnit.type != CD.UNIT_CARGOSHIP):
		task.priorityMod = 1.0 - (projectedStrength / float(objectiveUnit.maxStrength))
	
	return task.assign(unit, score)


func exec():
	if (!is_valid_unit(objectiveUnit, objective)
			&& ((attackStation && objective.is_visible(unit.player.num))
			|| !attackStation)):
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
	
	var tiles = Math.get_attack_tiles(unit.tile, unit.attackRange, unit.minAttackRange)
	if !objective.is_visible(unit.player.num) || !tiles.has(objective):
		if unit.moves <= 0:
			attack_target_of_opportunity(tiles)
			return
		
		if tiles.has(objective):
			Math.get_visible_tiles(objective, unit.visibilityRange, tiles)
		else:
			Math.get_attack_tiles(objective, unit.attackRange, unit.minAttackRange, tiles)
		
		var mRange = unit.get_movement_range()
		var inRange := []
		for t in tiles:
			if mRange.has(t):
				inRange.push_back(t)
		
		var tile
		if !inRange.empty():
			tile = Math.get_closest_defensible_tile_in_range(objective, inRange)
		else:
			tile = Math.get_closest_tile_in_range(objective, tiles)
		
		var count = 0
		while tile != null && tile.is_occupied() && count < 10:
			count += 1
			tile = Math.get_closest_surrounding_tile(tile, unit.tile)
		if tile == null || tile.is_occupied():
			unit.player.exec_next_task()
			return
		
		if !mRange.has(tile):
			tile = Math.get_closest_tile_in_range(tile, mRange)
			if tile == null || tile.is_occupied():
				unit.player.exec_next_task()
				return
		
		var path = Math.path_to(unit.tile, tile, mRange)
		unit.player.executableTasks.push_front(self)
		unit.move_along_path(path)
		return
	
	if is_valid_unit(objectiveUnit, objective):
		unit.attack_tile(objective)
	else:
		unit.player.exec_next_task()
