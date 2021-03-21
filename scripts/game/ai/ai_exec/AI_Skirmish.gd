extends Reference

const currentBuildWeight = 1.0

var player

var executableTasks := []

var rerunning = false


func _init(aiPlayer):
	player = aiPlayer


func exec(data):
	print_debug("Player " + str(player.num) + ": Begin AI")
	player.loadout.stationWeight = 0.0
	player.factionManager.update()
	
	var mai = data[0]
	var sem = data[1]
	var cancel = false
	
	var arr := []
	var stations : Array = player.get_command_stations()
	
	var mappedPerc := 0.0
	
	print_debug("Player " + str(player.num) + ": List units ready for launch")
	var relaunchStations := []
	var wait = false
	mai.lock()
	for station in stations:
		var buildItem = station.buildItem
		if buildItem == null || station.get_remaining_build_turns() > 0:
			continue
		
		if station.buildItem.get_type() == CD.UNIT_MPA:
			if station.mpa < CD.COMMAND_STATION_MAX_MPA:
				station.remove_build_item(station.buildItem)
				station.mpa += 1
				player.loadout.subtract_build(CD.UNIT_MPA)
				player.loadout.add_station_mpa()
			continue
		
		if is_surrounded(station.tile):
			relaunchStations.push_back(station)
			continue
			
		mai.launch.push_back(station)
	wait = !mai.launch.empty()
	mai.unlock()
	
	if wait:
		wait = false
		sem.wait()
	
	var units : Array = player.get_units()
	var cargoships := []
	var unassignedUnits := []
	for u in units:
		if u.type == CD.UNIT_CARGOSHIP:
			cargoships.push_back(u)
	for cs in cargoships:
		units.erase(cs)
	
	mai.lock()
	cancel = mai.cancel
	mai.unlock()
	
	var availableArena
	var destroyedStations := []
	var newDestroyedStations := []
	
	while(!cancel):
		print_debug("Player " + str(player.num) + ": Entering main AI loop")
		mai.lock()
		mai.rerun = false
		mai.unlock()
		
		player.loadout.requestedMPA = 0
		for i in player.loadout.nearStationEnemies:
			player.loadout.nearStationEnemies[i] = 0
		
		var tasks := []
		var damagedUnits := []
		
		#Create and assign cargoship repair, reload and build station tasks
		if !cancel && ((Opts.allVis && Opts.noFog) || player.turns.size() >= 5 || !stations.empty()):
			for unit in units:
				if unit.strength < unit.maxStrength:
					damagedUnits.push_back(unit)
			
			if (!(stations.empty() && player.loadout.get_total_type(CD.UNIT_MPA)
					< CD.CARGOSHIP_MAX_MPA) && !rerunning):
				print_debug("Player " + str(player.num) + ": Creating possible station areas")
				var stationAreas := []
				mappedPerc = search_for_station_areas(mai, stationAreas, arr)
				for psa in stationAreas:
					var task := AI_Task_BuildStation.new(psa, stations)
					tasks.push_back(task)
					player.loadout.add_prospective_station(task)
			
			print_debug("Player " + str(player.num) + ": Creating cargoship tasks")
			var possibleCargoTasks := []
			for cs in cargoships:
				mai.lock()
				cancel = mai.cancel
				mai.unlock()
				if cancel:
					break
				
				get_move_nodes(cs.tile, cs.moveRange, arr)
				if cs.mpa >= CD.CARGOSHIP_MAX_MPA:
					for task in tasks:
						possibleCargoTasks.push_back(AI_Task_PossibleAssignment.new(task, cs))
				
				var dUnits = damagedUnits.duplicate()
				for unit in dUnits:
					if ((stations.empty() && cs.mpa >= CD.CARGOSHIP_MAX_MPA)
							|| !arr.has(unit.tile)
							|| ((cs.moves <= 0 || is_surrounded(cs.tile))
							&& !cs.tile.get_surrounding().has(unit.tile))):
						continue
					
					if (Dossier.get(CD.UNIT_MPA).oreCost <= (Dossier.get(unit.type).oreCost
							/ unit.maxStrength) * CD.MPA_HEAL_AMOUNT
							|| player.loadout.get_total_type(CD.UNIT_MPA) > CD.CARGOSHIP_MAX_MPA * 3):
						var task = AI_Task_CargoRepair.new(unit)
						possibleCargoTasks.push_back(AI_Task_PossibleAssignment.new(task, cs, unit))
					damagedUnits.erase(unit)
				
				#reload
				if cs.mpa >= CD.CARGOSHIP_MAX_MPA:
					continue
				
				var reloadDest = get_relevant_reload_station(cs, stations)
				if (reloadDest != null
						&& (cs.moves >= 0 || cs.tile.get_surrounding().has(reloadDest.tile))):
					var task = AI_Task_Reload.new(reloadDest)
					possibleCargoTasks.push_back(AI_Task_PossibleAssignment.new(task, cs))
			
			tasks.clear()
			if !cancel && !possibleCargoTasks.empty():
				possibleCargoTasks.sort_custom(self, "sort_possible_tasks")
				var invalidTiles := []
				var reloadStations := {}
				availableArena = get_available_cargo_travel_tiles(mai, availableArena, newDestroyedStations)
				for pct in possibleCargoTasks:
					if pct.task is AI_Task_BuildStation:
						if invalidTiles.has(pct.task.objective):
							continue
						
						Math.get_resource_tiles(pct.task.objective, arr)
						var ore = pct.task.ore
						var energy = pct.task.energy
						for tile in arr:
							if invalidTiles.has(tile):
								if tile.has_asteroid():
									ore -= 1
								elif tile.has_star():
									energy -= 1
						
						if energy < 1 || ore < 2 || ore + min(8.0, energy * 2) < 4:
							continue
						
						pct.task.availableArena = availableArena
						if pct.assign():
							for tile in arr:
								if !invalidTiles.has(tile):
									invalidTiles.push_back(tile)
						pct.task.availableArena = null
						
					elif pct.task is AI_Task_Reload:
						pct.task.availableArena = availableArena
						if reloadStations.has(pct.task.objectiveUnit):
							var mpa = reloadStations[pct.task.objectiveUnit]
							if mpa > 0 && pct.assign():
								reloadStations[pct.task.objectiveUnit] -= min(CD.CARGOSHIP_MAX_MPA
										- pct.unit.mpa, mpa)
						elif pct.assign():
							reloadStations[pct.task.objectiveUnit] = (pct.task.objectiveUnit.mpa
									- min(CD.CARGOSHIP_MAX_MPA - pct.unit.mpa, pct.task.objectiveUnit.mpa))
						pct.task.availableArena = null
					else:
						pct.assign()
			possibleCargoTasks.clear()
		
		mai.lock()
		cancel = mai.cancel
		mai.unlock()
		
		print_debug("Player " + str(player.num) + ": Creating defend station tasks")
		var defendStationsAgainst := []
		if !cancel:
			for station in stations:
				Math.get_tile_range(station.tile, 7.0, arr)
				for tile in arr:
					if (!tile.is_visible(player.num)
							|| !tile.has_other_player(player.num)
							|| !player.factionManager.factions.has(tile.unit.player)
							|| tile.unit.type == CD.UNIT_CARGOSHIP
							|| defendStationsAgainst.has(tile.unit)):
						continue
					
					tasks.push_back(AI_Task_Defend.new(station, tile.unit))
					defendStationsAgainst.push_back(tile.unit)
					if tile.unit.type != CD.UNIT_COMMAND_STATION:
						player.loadout.nearStationEnemies[tile.unit.type] += 1
				
				mai.lock()
				cancel = mai.cancel
				mai.unlock()
				if cancel:
					break
			arr.clear()
		
		print_debug("Player " + str(player.num) + ": Creating attack unit tasks")
		if !cancel:
			var enemyShips = player.factionManager.get_visible_ships()
			for unit in enemyShips:
				if defendStationsAgainst.has(unit):
					continue
				tasks.push_back(AI_Task_AttackShip.new(unit, unit.tile))
		defendStationsAgainst.clear()
		
		mai.lock()
		cancel = mai.cancel
		mai.unlock()
		
		print_debug("Player " + str(player.num) + ": Creating attack station tasks")
		if !cancel:
			var enemyStations = player.factionManager.get_command_stations()
			for station in enemyStations:
				if station is CommandStation:
					var csTile = player.factionManager.get_command_station_tile(station)
					if csTile != null:
						tasks.push_back(AI_Task_AttackStation.new(station, csTile))
		
		mai.lock()
		cancel = mai.cancel
		mai.unlock()
		
		if !cancel && !(Opts.allVis && Opts.noFog):
			print_debug("Player " + str(player.num) + ": Creating explore tasks")
			availableArena = get_available_cargo_travel_tiles(mai, availableArena, newDestroyedStations)
			for x in range(player.arena.MAP_WIDTH):
				for y in range(player.arena.MAP_HEIGHT):
					var tile = player.arena.get_tile(x, y)
					if (tile.is_occupied() || !availableArena.has(tile)):
						continue
					
					var unmapped := 0.0
					var surrounding = tile.get_surrounding()
					var unsafe := false
					for t in surrounding:
						if !availableArena.has(t):
							unsafe = true
							break
						elif !tile.mapped[player.num]:
							unmapped += 1
						elif !tile.is_visible(player.num):
							unmapped += 0.25
					
					if !unsafe && unmapped > 0.5:
						tasks.push_back(AI_Task_Explore.new(tile, unmapped))
				
				mai.lock()
				cancel = mai.cancel
				mai.unlock()
				if cancel:
					break
		
		print_debug("Player " + str(player.num) + ": Creating unit repair tasks")
		if !cancel:
			for unit in damagedUnits:
				if (Dossier.get(CD.UNIT_MPA).oreCost <= (Dossier.get(unit.type).oreCost
						/ unit.maxStrength) * CD.MPA_HEAL_AMOUNT
						|| player.loadout.get_total_type(CD.UNIT_MPA) > CD.CARGOSHIP_MAX_MPA * 3):
					tasks.push_back(AI_Task_Repair.new(unit))
		damagedUnits.clear()
		
		print_debug("Player " + str(player.num) + ": Creating possible tasks")
		var possibleTasks := []
		if !cancel:
			for task in tasks:
				if task is AI_Task_Explore:
					for unit in units:
						if unit.moves > 0:
							possibleTasks.push_back(AI_Task_PossibleAssignment.new(task, unit))
					
				elif task is AI_Task_AttackShip || task is AI_Task_AttackStation || task is AI_Task_Defend:
					for unit in units:
						if (unit.attacks <= 0
								|| (!in_attack_range(unit, task.objective, arr)
								&& unit.moves <= 0)):
							continue
						
						if !CD.is_valid_unit(task.objectiveUnit, task.objective):
							if task.attackStation:
								var attackStrength = Dossier.get(unit.type).attackValues[CD.UNIT_COMMAND_STATION]
								if (attackStrength > 0
										&& !(unit.attackRange == 1 && is_surrounded(task.objective))):
									var pt = AI_Task_PossibleAssignment.new(task, unit)
									if pt.score >= 0:
										possibleTasks.push_back(pt)
						elif task.objectiveUnit.type == CD.UNIT_CARGOSHIP:
							var pt = AI_Task_PossibleAssignment.new(task, unit)
							if pt.score >= 0:
								possibleTasks.push_back(pt)
						else:
							var attackStrength = Math.calc_attack_amount(unit, task.objectiveUnit, true)
							if (attackStrength > 0 && attackStrength >= Math.calc_counter_attack_amount(task.objectiveUnit,
									unit, true, task.objectiveUnit.strength - attackStrength)
									&& !(unit.attackRange == 1 && is_surrounded(task.objective))):
								var pt = AI_Task_PossibleAssignment.new(task, unit)
								if pt.score >= 0:
									possibleTasks.push_back(pt)
						
					for station in stations:
						if (CD.is_valid_unit(task.objectiveUnit, task.objective)
								&& station.attacks > 0
								&& task.objective.is_visible(player.num)
								&& in_attack_range(station, task.objective, arr)):
							var pt = AI_Task_PossibleAssignment.new(task, station)
							if pt.score >= 0:
								possibleTasks.push_back(pt)
					
				elif task is AI_Task_Repair:
					if (Dossier.get(CD.UNIT_MPA).oreCost <= (Dossier.get(task.objectiveUnit.type).oreCost
							/ task.objectiveUnit.maxStrength) * CD.MPA_HEAL_AMOUNT
							|| player.loadout.get_total_type(CD.UNIT_MPA) > CD.CARGOSHIP_MAX_MPA * 3):
						var repairDest = get_relevant_repair_unit(task.objectiveUnit, stations, cargoships)
						if repairDest != null:
							if repairDest.type == CD.UNIT_CARGOSHIP:
								task.cargoRepair = AI_Task_CargoRepair.new(task.objectiveUnit)
								task.cargoRepair.unit = repairDest
								possibleTasks.push_back(AI_Task_PossibleAssignment.new(task, task.objectiveUnit, repairDest))
								task.objectiveUnit = repairDest
								task.objective = repairDest.tile
							elif (player.loadout.get_total_type(CD.UNIT_MPA) > CD.CARGOSHIP_MAX_MPA
									|| player.loadout.buildTypes[CD.UNIT_MPA] == 0):
								possibleTasks.push_back(AI_Task_PossibleAssignment.new(task, task.objectiveUnit, repairDest))
								task.objectiveUnit = repairDest
								task.objective = repairDest.tile
				
				mai.lock()
				cancel = mai.cancel
				mai.unlock()
				if cancel:
					break
		tasks.clear()
		
		print_debug("Player " + str(player.num) + ": Sorting tasks")
		if !cancel:
			possibleTasks.sort_custom(self, "sort_possible_tasks")
			mai.lock()
			cancel = mai.cancel
			mai.unlock()
		
		print_debug("Player " + str(player.num) + ": Assigning tasks")
		if !cancel:
			for pt in possibleTasks:
				pt.assign()
		else:
			break
		
		mai.lock()
		cancel = mai.cancel
		mai.unlock()
		
		if !cancel:
			for unit in units:
				if unit.moves > 0 && !mai.assignedUnits.has(unit):
					unassignedUnits.push_back(unit)
		
		mai.lock()
		cancel = mai.cancel
		if cancel:
			mai.unlock()
			break
		mai.execTasks = true
		mai.unlock()
		
		print_debug("Player " + str(player.num) + ": Waiting on tasks...")
		sem.wait()
		
		for station in player.game.turnStations:
			if !station.add:
				if destroyedStations.has(station):
					newDestroyedStations.erase(station)
				else:
					newDestroyedStations.push_back(station)
				destroyedStations.push_back(station)
		
		mai.lock()
		cancel = mai.cancel
		var brk = cancel || !mai.rerun
		if brk:
			mai.loopFin = true
			mai.unlock()
			break
		else:
			print_debug("Player " + str(player.num) + ": Reruning main AI loop")
			rerunning = true
			units = player.get_units()
			cargoships.clear()
			for u in units:
				if u.type == CD.UNIT_CARGOSHIP:
					cargoships.push_back(u)
			for cs in cargoships:
				units.erase(cs)
			stations = player.get_command_stations()
		mai.unlock()
		print_debug("Player " + str(player.num) + ": Exiting main AI loop")
	
	if !cancel:
		#Second attempt to launch built units from initially surrounded stations
		mai.lock()
		for station in relaunchStations:
			if is_surrounded(station.tile):
				continue
			mai.launch.push_back(station)
		cancel = mai.cancel
		var launch = !mai.launch.empty()
		mai.unlock()
		relaunchStations.clear()
		
		if !cancel && launch:
			sem.wait()
			mai.lock()
			cancel = mai.cancel
			mai.unlock()
	
	print_debug("Player " + str(player.num) + ": Withdrawing remaining units")
	if !cancel:
		stations = player.get_command_stations()
		if !unassignedUnits.empty():
			var territory := []
			for station in stations:
				var surrounding = station.tile.get_surrounding()
				for tile in station.collectedTiles:
					if !surrounding.has(tile) && !tile.is_occupied():
						territory.push_back(tile)
			
			for unit in unassignedUnits:
				if territory.empty():
					break
				
				if (!is_instance_valid(unit)
						|| !unit.has_method("is_alive")
						|| !unit.is_alive()
						|| unit.moves <= 0
						|| (unit.tile.is_collected()
						&& unit.tile.collectors[0].player.num == player.num)):
					continue
				
				var tile = Math.get_closest_tile_in_range(unit.tile, territory)
				if tile == null:
					tile = Math.get_random_array_item(territory)
				territory.erase(tile)
				AI_Task_Withdraw.new(tile).assign(unit, 1.0)
			unassignedUnits.clear()
	
	mai.lock()
	cancel = mai.cancel
	wait = !mai.tasks.empty()
	if !cancel:
		mai.execTasks = wait
	mai.unlock()
	
	if !cancel && wait:
		sem.wait()
	
	#assign remaining cargo ships to repair, reload or build stations
	print_debug("Player " + str(player.num) + ": Assigning tasks to remaining cargoships")
	if !cancel:
		cargoships.clear()
		units = player.get_units()
		stations = player.get_command_stations()
		for u in units:
			if u.type == CD.UNIT_CARGOSHIP:
				cargoships.push_back(u)
		
		if !cargoships.empty():
			var damagedUnits := []
			var tasks := []
			for cs in cargoships:
				units.erase(cs)
			
			for unit in units:
				if unit.strength < unit.maxStrength && unit.strength > 0:
					damagedUnits.push_back(unit)
			
			if !(stations.empty() && player.loadout.get_total_type(CD.UNIT_MPA) < CD.CARGOSHIP_MAX_MPA):
				var stationAreas := []
				player.loadout.stationWeight = 0.0
				mappedPerc = search_for_station_areas(mai, stationAreas, arr)
				for psa in stationAreas:
					if ((player.turns.size() >= 3 || !stations.empty())
							|| (Opts.asteroidAmount == Opts.QUANTITY_LOW && psa.ore + psa.energy > 7)
							|| psa.ore + psa.energy >= 11):
						var task := AI_Task_BuildStation.new(psa, stations)
						tasks.push_back(task)
						player.loadout.add_prospective_station(task)
		
			var possibleCargoTasks := []
			for cs in cargoships:
				mai.lock()
				cancel = mai.cancel
				mai.unlock()
				if cancel:
					break
				
				if cs.mpa >= CD.CARGOSHIP_MAX_MPA:
					for task in tasks:
						possibleCargoTasks.push_back(AI_Task_PossibleAssignment.new(task, cs))
				
				for unit in damagedUnits:
					if ((stations.empty() && cs.mpa >= CD.CARGOSHIP_MAX_MPA)
							|| ((cs.moves <= 0 || is_surrounded(cs.tile))
							&& !cs.tile.get_surrounding().has(unit.tile))):
						continue
					
					if (Dossier.get(CD.UNIT_MPA).oreCost <= (Dossier.get(unit.type).oreCost
							/ unit.maxStrength) * CD.MPA_HEAL_AMOUNT
							|| player.loadout.get_total_type(CD.UNIT_MPA) > CD.CARGOSHIP_MAX_MPA * 3):
						var task = AI_Task_CargoRepair.new(unit)
						possibleCargoTasks.push_back(AI_Task_PossibleAssignment.new(task, cs, unit))
				damagedUnits.clear()
				
				#reload
				if cs.mpa >= CD.CARGOSHIP_MAX_MPA:
					continue
				
				var reloadDest = get_relevant_reload_station(cs, stations)
				if (reloadDest != null
						&& ((cs.moves > 0 && !is_surrounded(cs.tile))
						|| cs.tile.get_surrounding().has(reloadDest.tile))):
					var task = AI_Task_Reload.new(reloadDest)
					possibleCargoTasks.push_back(AI_Task_PossibleAssignment.new(task, cs))
			
			tasks.clear()
			if !cancel && !possibleCargoTasks.empty():
				possibleCargoTasks.sort_custom(self, "sort_possible_tasks")
				var invalidTiles := []
				var reloadStations := {}
				availableArena = get_available_cargo_travel_tiles(mai, availableArena, newDestroyedStations)
				for pct in possibleCargoTasks:
					if pct.task is AI_Task_BuildStation:
						if invalidTiles.has(pct.task.objective):
							continue
						
						Math.get_resource_tiles(pct.task.objective, arr)
						var ore = pct.task.ore
						var energy = pct.task.energy
						for tile in arr:
							if invalidTiles.has(tile):
								if tile.has_asteroid():
									ore -= 1
								elif tile.has_star():
									energy -= 1
						if energy < 1 || ore < 2 || ore + min(8.0, energy * 2) < 4:
							continue
						
						pct.task.availableArena = availableArena
						if pct.assign():
							Math.get_resource_tiles(pct.task.objective, arr)
							for tile in arr:
								if !invalidTiles.has(tile):
									invalidTiles.push_back(tile)
						pct.task.availableArena = null
					elif pct.task is AI_Task_Reload:
						pct.task.availableArena = availableArena
						if reloadStations.has(pct.task.objectiveUnit):
							var mpa = reloadStations[pct.task.objectiveUnit]
							if mpa > 0 && pct.assign():
								reloadStations[pct.task.objectiveUnit] -= min(CD.CARGOSHIP_MAX_MPA
										- pct.unit.mpa, mpa)
						elif pct.assign():
							reloadStations[pct.task.objectiveUnit] = (pct.task.objectiveUnit.mpa
									- min(CD.CARGOSHIP_MAX_MPA - pct.unit.mpa, pct.task.objectiveUnit.mpa))
						pct.task.availableArena = null
					else:
						pct.assign()
			possibleCargoTasks.clear()
			
			#Retreat unassigned cargoships if enemies are nearby
			if !cancel:
				for cs in cargoships:
					if cs.moves <= 0 || mai.assignedUnits.has(cs):
						continue
					
					mai.lock()
					cancel = mai.cancel
					mai.unlock()
					if cancel:
						break
					
					Math.get_tile_range(cs.tile, 6.0, arr)
					var nearbyEnemies := []
					for t in arr:
						if (t.has_other_player(player.num)
								&& t.is_visible(player.num)
								&& t.unit.type != CD.UNIT_CARGOSHIP
								&& player.factionManager.factions.has(t.unit.player)):
							nearbyEnemies.push_back(t.unit)
					if !nearbyEnemies.empty():
						var tile
						var maxDist = 0.0
						var moveRange = cs.get_movement_range()
						for t in moveRange:
							var dist = 0.0
							for u in nearbyEnemies:
								dist += t.worldLoc.distance_to(u.tile.worldLoc)
							dist /= nearbyEnemies.size()
							if dist > maxDist:
								tile = t
								maxDist = dist
						if tile != null:
							AI_Task_Withdraw.new(tile).assign(cs, 1.0)
	
	mai.lock()
	cancel = mai.cancel
	wait = !mai.tasks.empty()
	if !cancel:
		mai.execTasks = wait
	mai.unlock()
	
	if !cancel && wait:
		sem.wait()
	
	print_debug("Player " + str(player.num) + ": Building Units")
	if !cancel && !stations.empty():
		player.loadout.requestedMPA = int(max(0, player.loadout.requestedMPA
				- player.loadout.get_total_type(CD.UNIT_MPA)))
		stations.sort_custom(self, "sort_stations")
		var buildItems := []
		for station in stations:
			player.loadout.get_items_by_priority(buildItems, station, mappedPerc)
			if buildItems == null || buildItems.empty():
				continue
			
			var newItem = buildItems[0]
			if newItem.get_type() == CD.UNIT_MPA && station.mpa == CD.COMMAND_STATION_MAX_MPA:
				if buildItems.size() > 1:
					newItem = buildItems[1]
				else:
					continue
			
			if station.is_building():
				var bi = station.buildItem
				if bi.get_type() == newItem.get_type():
					continue
				
				if bi.get_ore() <= 0:
					if bi.get_type() == CD.UNIT_MPA && station.mpa < CD.COMMAND_STATION_MAX_MPA:
						station.mpa += 1
						station.remove_build_item(station.buildItem)
						player.loadout.subtract_build(CD.UNIT_MPA)
						player.loadout.add_station_mpa()
						if station.is_building():
							bi = station.buildItem
							player.loadout.add_build(bi)
						else:
							station.buildItem = BuildItem.new(newItem.dossier.duplicate())
							player.loadout.add_build(newItem)
							print_debug("Player " + str(player.num) + ": Building " + newItem.get_name())
							continue
					else:
						continue
				
				for item in station.buildQueue:
					if item.get_type() == newItem.get_type():
						newItem = item
						break
				
				var buildWeight = currentBuildWeight / (float(bi.get_ore()) / Dossier.get(bi.get_type()).oreCost)
				buildWeight *= station.get_remaining_turns_for_item(newItem.dossier) / float(station.get_remaining_build_turns())
				if (player.loadout.build_item_priority(station.buildItem, station, mappedPerc) * buildWeight
						< player.loadout.build_item_priority(newItem, station, mappedPerc)):
					print_debug("Player " + str(player.num) + ": Replacing build item " + bi.get_name() + " with " + newItem.get_name())
					player.loadout.subtract_build(station.buildItem)
					if station.buildQueue.has(newItem):
						station.buildQueue.erase(newItem)
						station.buildItem = newItem
					else:
						station.buildItem = BuildItem.new(newItem.dossier.duplicate())
					player.loadout.add_build(newItem)
			else:
				station.buildItem = BuildItem.new(newItem.dossier.duplicate())
				player.loadout.add_build(newItem)
				print_debug("Player " + str(player.num) + ": Building " + newItem.get_name())
	
	print_debug("Player " + str(player.num) + ": End AI")
	mai.lock()
	mai.fin = true
	mai.unlock()


func sort_stations(a, b):
	var incomeA = min(a.incomeEnergy, 5) * a.incomeOre
	var incomeB = min(b.incomeEnergy, 5) * b.incomeOre 
	
	if abs(incomeA - incomeB) < 3:
		if b.buildItem == null:
			return false
		elif a.buildItem == null:
			return true
		else:
			return (player.loadout.build_item_priority(a.buildItem, a)
					> player.loadout.build_item_priority(b.buildItem, b))
	
	return incomeA > incomeB


func sort_possible_tasks(a, b):
	if a.task is AI_Task_Explore && b.task is AI_Task_Explore:
		if abs(a.task.priorityMod - b.task.priorityMod) < 0.001:
			if randf() >= 0.5:
				return true
			return false
		return a.task.priorityMod > b.task.priorityMod
	
	return a.score > b.score


func get_relevant_reload_station(cargoship : Unit, stations : Array) -> Unit:
	var requiredMPA = CD.CARGOSHIP_MAX_MPA - cargoship.mpa
	var reloadDest : Unit
	var score := 0.0001
	player.loadout.requestedMPA += requiredMPA
	
	for station in stations:
		if station.mpa > 0:
			var tmpScore := 0.0
			if station.mpa >= requiredMPA:
				tmpScore = requiredMPA / station.tile.worldLoc.distance_to(cargoship.tile.worldLoc)
			else:
				tmpScore = station.mpa / station.tile.worldLoc.distance_to(cargoship.tile.worldLoc)
			if tmpScore > score:
				reloadDest = station
				score = tmpScore
	
	return reloadDest


func get_relevant_repair_unit(damagedUnit : Unit, stations : Array, cargoships : Array) -> Unit:
	var requiredMPA := int(ceil((damagedUnit.maxStrength - damagedUnit.strength) / CD.MPA_HEAL_AMOUNT))
	var repairDest : Unit
	var score := 0.0001
	var repairStation : CommandStation
	player.loadout.requestedMPA += requiredMPA
	
	for station in stations:
		if station.mpa > 0:
			var tmpScore := 0.0
			if station.mpa >= requiredMPA:
				tmpScore = requiredMPA / (station.tile.worldLoc.distance_to(damagedUnit.tile.worldLoc) / CD.BASE_TILE_SIZE)
			else:
				tmpScore = station.mpa / (station.tile.worldLoc.distance_to(damagedUnit.tile.worldLoc) / CD.BASE_TILE_SIZE)
			if tmpScore > score:
				repairStation = station
				score = tmpScore
	
	var cScore := 0.0001
	for unit in cargoships:
		if (unit.mpa <= 0 || player.mai.assignedUnits.has(unit)):
			continue
		
		var tmpScore := 0.0
		if unit.mpa >= requiredMPA:
			tmpScore = requiredMPA / (unit.tile.worldLoc.distance_to(damagedUnit.tile.worldLoc) / CD.BASE_TILE_SIZE)
		else:
			tmpScore = unit.mpa / (unit.tile.worldLoc.distance_to(damagedUnit.tile.worldLoc) / CD.BASE_TILE_SIZE)
		if tmpScore > cScore:
			repairDest = unit
			cScore = tmpScore
	
	if repairDest != null && repairStation != null:
		if score >= cScore:
			return repairStation
		else:
			return repairDest
	elif repairStation != null:
		return repairStation
	
	return repairDest


#Creates an array of possible new staion locations
func search_for_station_areas(mai, stationAreas := [], store := []) -> float:
	stationAreas.clear()
	var numMapped := 0.0
	for x in range(player.arena.MAP_WIDTH):
		mai.lock()
		if mai.cancel:
			mai.unlock()
			break
		mai.unlock()
		for y in range(player.arena.MAP_HEIGHT):
			var tile = player.arena.get_tile(x, y)
			if tile.mapped[player.num]:
				numMapped += 1.0
				if !tile.is_collected():
					add_sighted_possible_station_area(tile, stationAreas, store)
	
	return numMapped / (player.arena.MAP_WIDTH * player.arena.MAP_HEIGHT)


func add_sighted_possible_station_area(tile : CDTile, stationAreas : Array, store := []):
	var psa := PossibleStationArea.new(tile, player, Math.get_resource_tiles(tile, store))
	if !psa.nearbyStation && psa.energy >= 1 && psa.ore >= 2 && psa.ore + min(8.0, psa.energy * 2) >= 4:
		stationAreas.push_back(psa)


func get_available_cargo_travel_tiles(mai, availableArena, destroyedStations := []) -> Array:
	if availableArena != null && destroyedStations.empty():
		return availableArena
	
	availableArena = player.game.arena.ARENA.duplicate()
	var stations = []
	
	for x in range(player.arena.MAP_WIDTH):
		mai.lock()
		if mai.cancel:
			mai.unlock()
			return availableArena
		mai.unlock()
		for y in range(player.arena.MAP_HEIGHT):
			var tile = player.arena.get_tile(x, y)
			if (tile.is_collected() && tile.collectors[0].player != player
					&& !stations.has(tile.collectors[0])):
				stations.push_back(tile.collectors[0])
	
	for stn in stations:
		mai.lock()
		if mai.cancel:
			mai.unlock()
			return availableArena
		mai.unlock()
		if player.factionManager.has_station(stn):
			availableArena.erase(stn.tile)
			var attackRange = Math.get_attack_tiles(stn.tile, stn.attackRange, stn.minAttackRange)
			for aTile in attackRange:
				availableArena.erase(aTile)
	
	return availableArena


#Returns true if tile is totally surrounded by other units
func is_surrounded(tile : CDTile) -> bool:
	var surrounding = tile.get_surrounding()
	for t in surrounding:
		if !t.is_occupied():
			return false
	return true


#Returns true if tile is totally surrounded by enemy units
func is_surrounded_by_enemies(tile : CDTile) -> bool:
	var surrounding = tile.get_surrounding()
	for t in surrounding:
		if !t.has_other_player(player.num):
			return false
	return true


#Returns the closest available tile surrounding origin or null if none are available
func get_closest_available_surrounding_node(origin : CDTile, from : CDTile) -> CDTile:
	var currentTile : CDTile
	var minDist = INF
	var tiles = origin.get_surrounding()
	for t in tiles:
		if !t.is_occupied():
			var tmp = from.worldLoc.distance_to(t.worldLoc)
			if tmp <= minDist:
				minDist = tmp
				currentTile = t
	return currentTile


#Adds available surrounding nodes to a list
func get_available_surrounding_nodes(origin : CDTile, tileList : Array = []) -> Array:
	tileList.clear()
	var surrounding = origin.get_surrounding()
	for t in surrounding:
		if !t.is_occupied():
			tileList.push_back(t)
	return tileList


#Returns true if check is next to origin
func in_surrounding(origin : CDTile, check : CDTile) -> bool:
	return origin.get_surrounding().has(check)


#Returns true if target is within the attack range of unit
#@param unit: The attacking unit
#@param target: The defending unit
#@param storeArray: An array to store tiles within attack range of unit
func in_attack_range(unit : Unit, target : CDTile, storeArray := []) -> bool:
	Math.get_attack_tiles(unit.tile, unit.attackRange, unit.minAttackRange, storeArray)
	
	if storeArray.has(target):
		storeArray.clear()
		return true
	
	storeArray.clear()
	return false


#Returns an Array containing tiles within movement range of origin
#@param origin: The origin of the movement range
#@param moveRange: The maximum range of the movement area
#@param inRange: An array that will contain the tiles in range
func get_move_nodes(origin : CDTile, moveRange : float, inRange : Array = []) -> Array:
	inRange.clear()
	inRange.push_back(origin)
	var costs := [0.0]
	var count := 0
	
	while count < inRange.size():
		var surrounding = inRange[count].get_surrounding()
		for t in surrounding:
			if !t.is_occupied() or !t.is_visible(player.num):
				var totalCost = costs[count] + t.movementCost
				if totalCost <= moveRange:
					var idx = inRange.find_last(t)
					if idx >= 0:
						if totalCost < costs[idx]:
							costs[idx] = totalCost
					else:
						inRange.push_back(t)
						costs.push_back(totalCost)
		count += 1
	inRange.pop_front()
	return inRange


#Alters a movement path in the event it is blocked by another unit or extends
#beyond the unit's movement range
func alter_move_path(origin : CDTile, movePath : Array, moveRange : Array = []) -> bool:
	var altPath := []
	for tile in movePath:
		if tile == origin:
			altPath.append(origin)
			continue
		if !tile.is_occupied() && moveRange.has(tile):
			altPath.append(tile)
	if altPath.size() != movePath.size():
		movePath.clear()
		for tile in altPath:
			movePath.append(tile)
		return true
	return false


#Returns true if a station can afford the supplied item cost
func can_build_item(oreCost : int, station : CommandStation) -> bool:
	return station.incomeOre >= oreCost && station.incomeEnergy > 0


#Returns true if the station can build anything
func station_can_build(station : CommandStation) -> bool:
	return station.incomeEnergy > 0 && station.incomeOre > 0
