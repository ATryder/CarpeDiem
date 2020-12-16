extends Reference
class_name PlayerLoadout

var types := []


func _init():
	for i in range(CD.TOTAL_TYPES):
		types.append(0)


func get_total_combat_ships() -> int:
	var total := 0
	for x in range(CD.TOTAL_TYPES):
		if x != CD.UNIT_MPA && x != CD.UNIT_COMMAND_STATION && x != CD.UNIT_CARGOSHIP:
			total += types[x]
	return total


func get_total_ships() -> int:
	var total := 0
	for x in range(CD.TOTAL_TYPES):
		if x != CD.UNIT_MPA && x != CD.UNIT_COMMAND_STATION:
			total += types[x]
	return total


func get_total_type(type : int) -> int:
	return types[type]


func add_unit_type(type : int, amount := 1):
	types[type] += amount


func add_unit(unit : Unit, amount := 1):
	types[unit.type] += amount


func subtract_unit_type(type : int, amount := 1):
	types[type] = int(max(0, types[type] - amount))


func subtract_unit(unit : Unit, amount := 1):
	types[unit.type] = int(max(0, types[unit.type] - amount))
