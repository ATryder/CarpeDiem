extends Reference
class_name AI_Task_PossibleAssignment

const MIN_PRIORITY := 7

var task : AI_Task
var score : float
var unit : Unit


func _init(task : AI_Task, unit : Unit, altUnit = null):
	self.task = task
	self.unit = unit
	
	var basePriority = MIN_PRIORITY - task.priority
	
	if altUnit != null:
		var dist = unit.tile.worldLoc.distance_to(altUnit.tile.worldLoc) / CD.BASE_TILE_SIZE
		dist = dist + CD.BASE_TILE_SIZE
		score = (basePriority + task.priorityMod) / dist
		return
	
	var dist = task.objective.worldLoc.distance_to(unit.tile.worldLoc) / CD.BASE_TILE_SIZE
	dist = dist + CD.BASE_TILE_SIZE
	if (task is AI_Task_AttackShip 
			|| task is AI_Task_Defend
			|| task is AI_Task_AttackStation):
		if unit.type == CD.UNIT_COMMAND_STATION:
			if CD.is_valid_unit(task.objectiveUnit, task.objective):
				var scoreMod = Math.calc_attack_amount(task.objectiveUnit, unit, true) / 2.0
				score = basePriority + task.priorityMod + scoreMod
			else:
				score = -10000
		elif CD.is_valid_unit(task.objectiveUnit, task.objective):
			var scoreMod = Math.calc_attack_amount(unit, task.objectiveUnit, true)
			
			if scoreMod < task.objectiveUnit.strength:
				scoreMod -= float(Math.calc_counter_attack_amount(task.objectiveUnit, unit, true))
				scoreMod /= 5.0
			elif task.objectiveUnit.type == CD.UNIT_COMMAND_STATION && unit.get_attack_range().has(task.objective):
				scoreMod = 1000.0
			else:
				scoreMod /= 5.0
			
			score = (basePriority + (task.priorityMod + scoreMod)) / dist
		elif task.attackStation:
			var scoreMod = Dossier.get(unit.type).attackValues[CD.UNIT_COMMAND_STATION] / 5.0
			score = (basePriority + (task.priorityMod + scoreMod)) / dist
		else:
			score = -10000
	else:
		score = (basePriority + task.priorityMod) / dist
		if (task is AI_Task_BuildStation
				&& task.nearbyEnemy
				&& !task.objective == unit.tile
				&& !unit.get_movement_range().has(task.objective)):
			score = 0.0


func assign() -> bool:
	return task.assign(unit, score)
