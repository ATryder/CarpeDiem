extends PlayerLoadout
class_name AILoadout

const MPA_WEIGHT = 1.0

var player

var buildTypes := []
var buildItems := []

var nearStationEnemies := {}

var stationWeight := 0.0
var requestedMPA := 0
var stationMPA := 0


func _init(player):
	self.player = player
	for i in range(CD.TOTAL_TYPES):
		buildTypes.append(0)
		buildItems.append(BuildItem.new(Dossier.get(i)))
		nearStationEnemies[i] = 0
	nearStationEnemies.erase(CD.UNIT_MPA)


func get_items_by_priority(items : Array, station : Unit, mappedPerc := 1.0) -> Array:
	items.clear()
	var bItems := buildItems.duplicate()
	var checkedItems := 0
	var index := 0
	while checkedItems < bItems.size():
		var hiPriItem : BuildItem
		var hiPri := -INF
		for i in range(bItems.size()):
			if bItems[i] == null || bItems[i].get_type() == CD.UNIT_COMMAND_STATION:
				continue
			
			var currentItem = bItems[i]
			if hiPri == -INF:
				hiPri = build_item_priority(currentItem, station, mappedPerc)
				index = i
				if hiPri > 0.0001:
					hiPriItem = currentItem
			else:
				var pri = build_item_priority(currentItem, station, mappedPerc)
				if pri > hiPri:
					hiPri = pri
					index = i
					if hiPri > 0.0001:
						hiPriItem = currentItem
					else:
						hiPriItem = null
		
		if hiPriItem != null:
			items.append(hiPriItem)
		checkedItems += 1
		bItems[index] = null
	
	if items.empty():
		if get_total_type(CD.UNIT_NIGHTHAWK) <= 0:
			items.append(buildItems[CD.UNIT_NIGHTHAWK])
		elif get_total_combat_ships() < 5 && player.turns.size() > 20:
			if station != null:
				for bi in buildItems:
					if (bi.get_type() != CD.UNIT_COMMAND_STATION
							&& station.get_remaining_turns_for_item(bi.dossier) <= 10):
						items.push_back(bi)
				if !items.empty():
					items.sort_custom(self, "sort_misc_items")
				elif station.mpa < CD.CARGOSHIP_MAX_MPA:
					items.append(buildItems[CD.UNIT_MPA])
				else:
					items.append(buildItems[CD.UNIT_CARGOSHIP])
			elif randf() >= 0.5:
				items.append(buildItems[CD.UNIT_NIGHTHAWK])
			else:
				items.append(buildItems[CD.UNIT_GAUMOND])
		elif get_total_type(CD.UNIT_MPA) >= CD.CARGOSHIP_MAX_MPA && stationWeight >= 0.5:
			items.append(buildItems[CD.UNIT_CARGOSHIP])
		else:
			items.append(buildItems[CD.UNIT_MPA])
	
	return items


func sort_misc_items(a, b):
	return a.oreCost > b.oreCost


func build_item_priority(item : BuildItem, station = null, mappedPerc := 1.0) -> float:
	var thisBuild := 0
	var r
	var oreCost := float(item.get_ore())
	if station != null:
		oreCost = float(station.get_remaining_turns_for_item(item.dossier))
	
	if item.get_type() == CD.UNIT_MPA:
		if station != null && station.buildItem != null && station.buildItem.get_type() == CD.UNIT_MPA:
			thisBuild = -1
		
		if stationMPA + buildTypes[CD.UNIT_MPA] + thisBuild < CD.CARGOSHIP_MAX_MPA:
			if station != null && station.buildItem != null && station.buildItem.get_type() != CD.UNIT_CARGOSHIP:
				if stationWeight >= 1:
					r = (stationWeight + max(min(get_total_type(CD.UNIT_COMMAND_STATION) / 2.0, 2) - get_total_type(CD.UNIT_CARGOSHIP), 0.0)) + ((requestedMPA - (buildTypes[CD.UNIT_MPA] + thisBuild)) * MPA_WEIGHT)
				else:
					r = max(stationWeight - get_total_type(CD.UNIT_CARGOSHIP), 0.0) + ((requestedMPA - (buildTypes[CD.UNIT_MPA] + thisBuild)) * MPA_WEIGHT)
			elif stationWeight >= 1:
				r = (stationWeight + max(min(get_total_type(CD.UNIT_COMMAND_STATION) / 2.0, 2) - (get_total_type(CD.UNIT_CARGOSHIP) - 1), 0.0)) + ((requestedMPA - (buildTypes[CD.UNIT_MPA] + thisBuild)) * MPA_WEIGHT)
			else:
				r = max(stationWeight - get_total_type(CD.UNIT_CARGOSHIP) - 1, 0.0) + ((requestedMPA - (buildTypes[CD.UNIT_MPA] + thisBuild)) * MPA_WEIGHT)
		else:
			r = (requestedMPA - (buildTypes[CD.UNIT_MPA] + thisBuild)) * MPA_WEIGHT
		return (r * 0.5) + (r / oreCost)
	
	if item.get_type() == CD.UNIT_CARGOSHIP:
		if station != null && station.buildItem != null:
			if station.buildItem.get_type() == CD.UNIT_MPA:
				if ((stationMPA + buildTypes[CD.UNIT_MPA] - 1)
						- (get_total_type(CD.UNIT_CARGOSHIP) * CD.CARGOSHIP_MAX_MPA) < CD.CARGOSHIP_MAX_MPA):
					return 0.0
				else:
					if stationWeight >= 1:
						r = max(0.0, (stationWeight + min(get_total_type(CD.UNIT_COMMAND_STATION) / 2.0, 2)) - get_total_type(CD.UNIT_CARGOSHIP))
					else:
						r = max(0.0, stationWeight - get_total_type(CD.UNIT_CARGOSHIP))
					return (r * 0.5) + (r / oreCost)
			else:
				thisBuild = -1
			
		if ((stationMPA + buildTypes[CD.UNIT_MPA])
				- (get_total_type(CD.UNIT_CARGOSHIP) * CD.CARGOSHIP_MAX_MPA) < CD.CARGOSHIP_MAX_MPA):
			return 0.0
		if stationWeight >= 1:
			r = max(0.0, (stationWeight + min(get_total_type(CD.UNIT_COMMAND_STATION) / 2.0, 2)) - (get_total_type(CD.UNIT_CARGOSHIP) + thisBuild))
		else:
			r = max(0.0, stationWeight - (get_total_type(CD.UNIT_CARGOSHIP) + thisBuild))
		return (r * 0.5) + (r / oreCost)
	
	var unitPriority = 0.0
	for i in item.dossier.attackValues:
		var unitWeight = player.factionManager.get_total_unit_amount(i)
		if nearStationEnemies[i] > 0:
			unitWeight += (nearStationEnemies[i]
					* (Dossier.get(i).attackValues[CD.UNIT_COMMAND_STATION] + 1))
		var attackValue = item.dossier.attackValues[i]
		if i == CD.UNIT_CARGOSHIP:
			if item.get_type() == CD.UNIT_NIGHTHAWK:
				unitPriority += min(unitWeight, 2)
		else:
			var highAttack = i
			for idx in item.dossier.attackValues:
				if idx != CD.UNIT_CARGOSHIP && item.dossier.attackValues[idx] > attackValue:
					highAttack = idx
					break
			if highAttack == i:
				unitPriority += unitWeight
			else:
				unitPriority += unitWeight * max(0, attackValue / 7.0)
	
	if item.get_type() == CD.UNIT_NIGHTHAWK && mappedPerc < 1:
		unitPriority += max(0, 2 - get_total_type(CD.UNIT_NIGHTHAWK)) * ((1.0 - mappedPerc) / 0.5)
	
	if station.buildItem != null && station.buildItem.get_type() == item.get_type():
		thisBuild = -1
	var numShips = get_total_type(item.get_type()) + thisBuild
	r = max(0.0, float(unitPriority - numShips))
	return (r * 0.5) + (r / oreCost)


func get_total_combat_ships_with_build() -> int:
	var total := 0
	for x in range(CD.TOTAL_TYPES):
		if x != CD.UNIT_MPA && x != CD.UNIT_COMMAND_STATION && x != CD.UNIT_CARGOSHIP:
			total += types[x]
			total += buildTypes[x]
	return total


func get_total_ships_with_build() -> int:
	var total := 0
	for x in range(CD.TOTAL_TYPES):
		if x != CD.UNIT_MPA && x != CD.UNIT_COMMAND_STATION:
			total += types[x]
			total += buildTypes[x]
	return total


func get_total_type(type : int) -> int:
	return types[type] + buildTypes[type]


func add_prospective_station(task : AI_Task_BuildStation):
	stationWeight = max(task.prospectiveWeight, stationWeight)


func add_station_mpa(amount = 1):
	stationMPA += amount
	add_unit_type(CD.UNIT_MPA, amount)


func subtract_station_mpa(amount = 1):
	amount = min(amount, stationMPA)
	stationMPA -= amount
	subtract_unit_type(CD.UNIT_MPA, amount)


func add_build(buildItem : BuildItem):
	buildTypes[buildItem.get_type()] += 1


func subtract_build(buildItem : BuildItem):
	buildTypes[buildItem.get_type()] = int(max(0, buildTypes[buildItem.get_type()] - 1))


func subtract_build_unit(unit : Unit):
	buildTypes[unit.type] = int(max(0, buildTypes[unit.type] - 1))
