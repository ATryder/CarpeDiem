extends AI_Task
class_name AI_Task_Withdraw


func _init(var objectiveTile):
	objective = objectiveTile


func exec():
	if unit.moves <= 0:
		unit.player.exec_next_task()
		return
	
	var moveRange = unit.get_movement_range()
	if moveRange.has(objective) && !objective.is_occupied():
		var path = Math.path_to(unit.tile, objective, moveRange)
		unit.move_along_path(path)
		return
	
	var tile = Math.get_closest_tile_in_range(objective, moveRange)
	var count = 0
	while tile != null && tile.is_occupied() && count < 10:
		count += 1
		tile = Math.get_closest_surrounding_tile(tile, unit.tile)
	
	if tile != null && !tile.is_occupied():
		var path = Math.path_to(unit.tile, tile, moveRange)
		unit.move_along_path(path)
	else:
		unit.player.exec_next_task()
