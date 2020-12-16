extends Node


func get(type) -> Dictionary:
	var d := {}
	match type:
		CD.UNIT_CARGOSHIP:
			d.type = CD.UNIT_CARGOSHIP
			d.name = tr("unit_name_cargoship")
			d.description = tr("unit_description_cargoship") % CD.CARGOSHIP_MAX_MPA
			d.oreCost = 20
			d.energyCost = 2
			d.sensorRange = 6.0
			d.moveRange = 8.0
			d.attackRange = 0.0
			d.minAttackRange = 0.0
			d.maxAttacks = 0
			d.maxMoves = 1
			d.maxStrength = 10
			d.maxMPA = 4
			d.attackValues = {
					CD.UNIT_NIGHTHAWK: 0,
					CD.UNIT_GAUMOND: 0,
					CD.UNIT_THANANOS: 0,
					CD.UNIT_AURORA: 0,
					CD.UNIT_COMMAND_STATION: 0,
					CD.UNIT_CARGOSHIP: 0
					}
			d.counterAttackValues = {
					CD.UNIT_NIGHTHAWK: 0,
					CD.UNIT_GAUMOND: 0,
					CD.UNIT_THANANOS: 0,
					CD.UNIT_AURORA: 0,
					CD.UNIT_COMMAND_STATION: 0,
					CD.UNIT_CARGOSHIP: 0
					}
		CD.UNIT_NIGHTHAWK:
			d.type = CD.UNIT_NIGHTHAWK
			d.name = tr("unit_name_nighthawk")
			d.description = tr("unit_description_nighthawk")
			d.oreCost = 36
			d.energyCost = 2
			d.sensorRange = 4.0
			d.moveRange = 6.0
			d.attackRange = 1.0
			d.minAttackRange = 0.0
			d.maxAttacks = 1
			d.maxMoves = 1
			d.maxStrength = 10
			d.maxMPA = 0
			d.attackValues = {
					CD.UNIT_NIGHTHAWK: 5,
					CD.UNIT_GAUMOND: 8,
					CD.UNIT_THANANOS: 2,
					CD.UNIT_AURORA: 1,
					CD.UNIT_COMMAND_STATION: 0,
					CD.UNIT_CARGOSHIP: 10
					}
			d.counterAttackValues = {
					CD.UNIT_NIGHTHAWK: -1,
					CD.UNIT_GAUMOND: -1,
					CD.UNIT_THANANOS: 0,
					CD.UNIT_AURORA: 0,
					CD.UNIT_COMMAND_STATION: 0,
					CD.UNIT_CARGOSHIP: 0
					}
		CD.UNIT_GAUMOND:
			d.type = CD.UNIT_GAUMOND
			d.name = tr("unit_name_gaumond")
			d.description = tr("unit_description_gaumond")
			d.oreCost = 80
			d.energyCost = 2
			d.sensorRange = 4.0
			d.moveRange = 6.0
			d.attackRange = 1.0
			d.minAttackRange = 0.0
			d.maxAttacks = 1
			d.maxMoves = 1
			d.maxStrength = 10
			d.maxMPA = 0
			d.attackValues = {
					CD.UNIT_NIGHTHAWK: 1,
					CD.UNIT_GAUMOND: 2,
					CD.UNIT_THANANOS: 5,
					CD.UNIT_AURORA: 5,
					CD.UNIT_COMMAND_STATION: 1,
					CD.UNIT_CARGOSHIP: 10
					}
			d.counterAttackValues = {
					CD.UNIT_NIGHTHAWK: -1,
					CD.UNIT_GAUMOND: -1,
					CD.UNIT_THANANOS: 0,
					CD.UNIT_AURORA: 0,
					CD.UNIT_COMMAND_STATION: 0,
					CD.UNIT_CARGOSHIP: 0
					}
		CD.UNIT_THANANOS:
			d.type = CD.UNIT_THANANOS
			d.name = tr("unit_name_thananos")
			d.description = tr("unit_description_thananos")
			d.oreCost = 120
			d.energyCost = 3
			d.sensorRange = 8.0
			d.moveRange = 4.0
			d.attackRange = 5.0
			d.minAttackRange = 2.0
			d.maxAttacks = 1
			d.maxMoves = 1
			d.maxStrength = 10
			d.maxMPA = 0
			d.attackValues = {
					CD.UNIT_NIGHTHAWK: 8,
					CD.UNIT_GAUMOND: 2,
					CD.UNIT_THANANOS: 4,
					CD.UNIT_AURORA: 2,
					CD.UNIT_COMMAND_STATION: 2,
					CD.UNIT_CARGOSHIP: 10
					}
			d.counterAttackValues = {
					CD.UNIT_NIGHTHAWK: 0,
					CD.UNIT_GAUMOND: 0,
					CD.UNIT_THANANOS: 0,
					CD.UNIT_AURORA: 0,
					CD.UNIT_COMMAND_STATION: 0,
					CD.UNIT_CARGOSHIP: 0
					}
		CD.UNIT_AURORA:
			d.type = CD.UNIT_AURORA
			d.name = tr("unit_name_aurora")
			d.description = tr("unit_description_aurora")
			d.oreCost = 200
			d.energyCost = 4
			d.sensorRange = 6.0
			d.moveRange = 5.0
			d.attackRange = 4.0
			d.minAttackRange = 1.0
			d.maxAttacks = 1
			d.maxMoves = 1
			d.maxStrength = 10
			d.maxMPA = 0
			d.attackValues = {
					CD.UNIT_NIGHTHAWK: 1,
					CD.UNIT_GAUMOND: 1,
					CD.UNIT_THANANOS: 4,
					CD.UNIT_AURORA: 3,
					CD.UNIT_COMMAND_STATION: 4,
					CD.UNIT_CARGOSHIP: 10
					}
			d.counterAttackValues = {
					CD.UNIT_NIGHTHAWK: 9,
					CD.UNIT_GAUMOND: 3,
					CD.UNIT_THANANOS: -1,
					CD.UNIT_AURORA: -1,
					CD.UNIT_COMMAND_STATION: 0,
					CD.UNIT_CARGOSHIP: -1
					}
		CD.UNIT_COMMAND_STATION:
			d.type = CD.UNIT_COMMAND_STATION
			d.name = tr("unit_name_commandstation")
			d.description = ""
			d.oreCost = 0
			d.energyCost = 0
			d.sensorRange = 7.0
			d.moveRange = 0.0
			d.attackRange = 5.0
			d.minAttackRange = 0.0
			d.maxAttacks = 1
			d.maxMoves = 0
			d.maxStrength = 10
			d.maxMPA = 10
			d.attackValues = {
					CD.UNIT_NIGHTHAWK: 8,
					CD.UNIT_GAUMOND: 3,
					CD.UNIT_THANANOS: 4,
					CD.UNIT_AURORA: 3,
					CD.UNIT_COMMAND_STATION: 4,
					CD.UNIT_CARGOSHIP: 10
					}
			d.counterAttackValues = {
					CD.UNIT_NIGHTHAWK: 0,
					CD.UNIT_GAUMOND: 0,
					CD.UNIT_THANANOS: 0,
					CD.UNIT_AURORA: 0,
					CD.UNIT_COMMAND_STATION: 0,
					CD.UNIT_CARGOSHIP: 0
					}
		CD.UNIT_MPA:
			d.type = CD.UNIT_MPA
			d.name = tr("unit_name_mpa")
			d.description = tr("unit_description_mpa") % [CD.CARGOSHIP_MAX_MPA, CD.MPA_HEAL_AMOUNT]
			d.oreCost = 24
			d.energyCost = 3
			d.sensorRange = 0.0
			d.moveRange = 0.0
			d.attackRange = 0.0
			d.minAttackRange = 0.0
			d.maxAttacks = 0
			d.maxMoves = 0
			d.maxStrength = 10
			d.maxMPA = 0
			d.attackValues = {
					CD.UNIT_NIGHTHAWK: 0,
					CD.UNIT_GAUMOND: 0,
					CD.UNIT_THANANOS: 0,
					CD.UNIT_AURORA: 0,
					CD.UNIT_COMMAND_STATION: 0,
					CD.UNIT_CARGOSHIP: 0
					}
			d.counterAttackValues = {
					CD.UNIT_NIGHTHAWK: 0,
					CD.UNIT_GAUMOND: 0,
					CD.UNIT_THANANOS: 0,
					CD.UNIT_AURORA: 0,
					CD.UNIT_COMMAND_STATION: 0,
					CD.UNIT_CARGOSHIP: 0
					}
	
	return d
