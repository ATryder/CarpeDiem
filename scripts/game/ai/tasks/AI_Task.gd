extends Reference
class_name AI_Task

enum {
	PRIORITY_DEFEND,
	PRIORITY_BUILDSTATION,
	PRIORITY_ATTACKSTATION,
	PRIORITY_ATTACKSHIP,
	PRIORITY_REPAIR,
	PRIORITY_CARGOREPAIR,
	PRIORITY_RELOAD,
	PRIORITY_EXPLORE
	}

var priority : int
var priorityMod : float

var score := 0.0

var unit : Unit
var objective : CDTile
var objectiveUnit : Unit
var objectiveInt : int


func is_assigned() -> bool:
	return unit != null


func assign(unit : Unit, score : float) -> bool:
	if !is_assigned() && !unit.player.mai.assignedUnits.has(unit):
		self.unit = unit
		self.score = score
		unit.player.mai.tasks.push_back(self)
		unit.player.mai.assignedUnits.push_back(unit)
		return true
	return false


func unassign():
	if !is_assigned():
		return
	unit.player.mai.tasks.erase(self)
	unit = null
	score = 0.0


func exec():
	pass


#Workaround for dangling variant bug with is_instance_valid
func is_valid_unit(unit, tile):
	if unit == null || !(unit is Unit) || !is_instance_valid(unit):
		return false
	
	return unit.has_method("get_strength") && unit.tile == tile && unit.is_alive()


func move_next_to_objective(reExecOnArrival := true, objectiveTile = objective):
	if unit.moves <= 0:
		unit.player.exec_next_task()
		return
	
	var tile = Math.get_closest_surrounding_tile(objectiveTile, unit.tile)
	var count = 0
	while tile != null && tile.is_occupied() && count < 10:
		count += 1
		tile = Math.get_closest_surrounding_tile(tile, unit.tile)
	
	if tile == null || tile.is_occupied():
		unit.player.exec_next_task()
		return
	
	var tileRange = unit.get_movement_range()
	if tileRange.has(tile):
		var path = Math.path_to(unit.tile, tile, tileRange)
		if reExecOnArrival && objectiveTile.get_surrounding().has(tile):
			unit.player.executableTasks.push_front(self)
		unit.move_along_path(path)
		return
	
	tile = Math.get_closest_tile_in_range(tile, tileRange)
	if tile != null && !tile.is_occupied():
		var path = Math.path_to(unit.tile, tile, tileRange)
		if reExecOnArrival && objectiveTile.get_surrounding().has(tile):
			unit.player.executableTasks.push_front(self)
		unit.move_along_path(path)
	else:
		unit.player.exec_next_task()


func attack_target_of_opportunity(attackTiles = []):
	if unit.attacks > 0:
		if attackTiles.empty():
			attackTiles = unit.get_attack_range()
		
		var targetTile
		var bestAttack = 0
		for tile in attackTiles:
			if (tile.is_visible(unit.player.num) && tile.has_other_player(unit.player.num)
					&& is_valid_unit(tile.unit, tile)
					&& tile.unit.is_alive()
					&& unit.player.factionManager.factions.has(tile.unit.player)):
				var atk = Math.calc_attack_amount(unit, tile.unit, true)
				if tile.unit.type != CD.UNIT_CARGOSHIP && tile.unit.get_attack_range().has(unit.tile):
					atk = max(0, atk - Math.calc_counter_attack_amount(tile.unit, unit, true))
				if atk > bestAttack:
					bestAttack = atk
					targetTile = tile
		
		if targetTile != null:
			unit.attack_tile(targetTile)
		else:
			unit.player.exec_next_task()
	else:
		unit.player.exec_next_task()
