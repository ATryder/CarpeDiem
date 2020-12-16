extends AI_Task
class_name AI_Task_Explore


func _init(objective : CDTile, numSurroundingUnmapped : int):
	self.objective = objective
	priority = PRIORITY_EXPLORE
	priorityMod = numSurroundingUnmapped / 7.0


func assign(unit : Unit, score : float) -> bool:
	if is_assigned() || unit.player.mai.assignedUnits.has(unit):
		return false
	
	var mRange = unit.get_territory_safe_movement_range()
	if !mRange.has(objective):
		var tile = Math.get_closest_tile_in_range(objective, mRange)
		if (tile == null || tile.is_occupied()
				|| tile.worldLoc.distance_to(objective.worldLoc) - unit.tile.worldLoc.distance_to(objective.worldLoc) >= 0.001):
			return false

	self.unit = unit
	self.score = score
	unit.player.mai.tasks.push_back(self)
	unit.player.mai.assignedUnits.push_back(unit)
	return true


func exec():
	if unit.moves <= 0:
		unit.player.exec_next_task()
		return
	
	var mRange = unit.get_territory_safe_movement_range()
	if mRange.empty():
		mRange = unit.get_movement_range()
		if mRange.empty():
			unit.player.exec_next_task()
			return
		
		if mRange.has(objective):
			var path = Math.path_to(unit.tile, objective, mRange)
			unit.move_along_path(path)
			return
		
		var tile = Math.get_closest_tile_in_range(objective, mRange)
		if tile == null || tile.is_occupied():
			unit.player.exec_next_task()
			return
		
		var path = Math.path_to(unit.tile, tile, mRange)
		if path.empty():
			unit.player.exec_next_task()
			return
		unit.move_along_path(path)
		return
	
	if mRange.has(objective):
		var path = Math.path_to(unit.tile, objective, unit.get_movement_range())
		if !path.empty():
			unit.move_along_path(path)
			return
		else:
			unit.player.exec_next_task()
			return
	
	var tile = Math.get_closest_tile_in_range(objective, mRange)
	if tile == null || tile.is_occupied():
		unit.player.exec_next_task()
		return
	
	var path = Math.path_to(unit.tile, tile, unit.get_movement_range())
	if path.empty():
		unit.player.exec_next_task()
		return
	unit.move_along_path(path)
