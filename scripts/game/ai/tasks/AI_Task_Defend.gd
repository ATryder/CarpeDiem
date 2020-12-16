extends AI_Task_AttackShip
class_name AI_Task_Defend


func _init(var objectiveStation : Unit, var objectiveUnit : Unit).(objectiveUnit, objectiveUnit.tile):
	priority = PRIORITY_DEFEND
	if objectiveStation != null:
		priorityMod = float(objectiveStation.incomeOre + min(10.0, objectiveStation.incomeEnergy * 2)) / 7.0
		priorityMod *= Dossier.get(objectiveUnit.type).attackValues[CD.UNIT_COMMAND_STATION] / 2.0
