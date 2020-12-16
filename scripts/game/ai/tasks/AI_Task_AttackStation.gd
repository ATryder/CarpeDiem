extends AI_Task_AttackShip
class_name AI_Task_AttackStation


func _init(objectiveUnit, tile = null, objectiveStation := true).(objectiveUnit, tile, objectiveStation):
	priority = PRIORITY_ATTACKSTATION
