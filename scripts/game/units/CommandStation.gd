extends Unit
class_name CommandStation

var buildQueue := []

var buildItem : BuildItem setget set_build, get_build

var collectedTiles

var incomeOre := -1
var incomeEnergy := -1

var calcBoundaries := false


func _ready():
	set_income()
	
	if player.game == null:
		return
	
	if calcBoundaries:
		player.calc_boundaries()
	
	if !player.is_local_player() && player.mai != null:
		player.mai.lock()
		var loopFin = player.mai.loopFin
		player.mai.unlock()
		var rerun = false
		if !loopFin && !(Opts.allVis && Opts.noFog):
			var visTiles = get_visible_range(tile)
			for t in visTiles:
				player.factionManager.update_tile(t)
		if execAI_Task && !rerun:
			player.exec_next_task()
		elif rerun:
			player.exec_ai()


func reset_on_turn():
	.reset_on_turn()
	if strength < maxStrength:
		self.strength += 1
	var bi : BuildItem = get_build()
	if bi != null:
		bi.build(self)
		if (bi.get_type() == CD.UNIT_MPA
				&& bi.get_ore() <= 0
				&& get_mpa() < get_max_mpa()):
			add_mpa(1)
			if !player.is_local_player():
				player.loadout.add_station_mpa()
				player.loadout.subtract_build(bi)
			remove_build_item(bi)
		update_indicators()
		reset_tile_display()


func set_income():
	if incomeOre > 0:
		player.incomeOre -= incomeOre
	if incomeEnergy > 0:
		player.incomeEnergy -= incomeEnergy
	incomeOre = 0
	incomeEnergy = 0
	
	if collectedTiles == null:
		if set_collected_in_range().empty():
			return
	
	for t in collectedTiles:
		if !t.collectors.empty() && t.collectors[0] == self:
			if t.has_star():
				incomeEnergy += Opts.STARVALUE
			if (t.has_asteroid()
					&& (!t.is_occupied() || t.get_player_number() == player.num
					|| (!player.is_local_player() && !player.factionManager.factions.has(t.get_player())))):
				incomeOre += Opts.OREVALUE
	
	player.incomeOre += incomeOre
	player.incomeEnergy += incomeEnergy
	update_indicators()


func get_actual_collected_tiles():
	if collectedTiles == null:
		if set_collected_in_range().empty():
			return []
	
	var tiles = []
	for t in collectedTiles:
		if !t.collectors.empty() && t.collectors[0] == self:
			tiles.push_back(t)
	
	return tiles


func set_collected_in_range():
	if tile == null:
		return []
	
	tile.collectors.push_back(self)
	collectedTiles = [tile]
	var costs = [0]
	var count = 0
	
	while count < collectedTiles.size():
		var surrounding = collectedTiles[count].get_surrounding()
		for t in surrounding:
			var totalCost = costs[count] + 1
			var idx = collectedTiles.find_last(t)
			if idx >= 0:
				if totalCost < costs[idx]:
					costs[idx] = totalCost
			elif totalCost <= CD.COMMAND_STATION_RESOURCE_RANGE:
				collectedTiles.push_back(t)
				costs.push_back(totalCost)
				if (t.collectors.empty()):
					player.hud.update_map(t)
					t.collectors.push_back(self)
				elif !t.collectors.has(self):
					t.collectors.push_back(self)
		count += 1
	
	return collectedTiles


func remove_collected_tiles():
	if incomeOre > 0:
		player.incomeOre -= incomeOre
	if incomeEnergy > 0:
		player.incomeEnergy -=incomeEnergy
	incomeEnergy = 0
	incomeOre = 0
	
	if collectedTiles == null:
		return
	
	var reCalc = [player]
	var setIncome = []
	for t in collectedTiles:
		var idx = t.collectors.find(self)
		if idx == 0:
			t.collectors.pop_front()
			player.hud.update_map(t)
			if !t.collectors.empty():
				if !reCalc.has(t.collectors[0].player):
					reCalc.push_back(t.collectors[0].player)
				if !setIncome.has(t.collectors[0]):
					setIncome.push_back(t.collectors[0])
		elif idx >= 1:
			t.collectors.remove(idx)
	collectedTiles = null
	
	for p in reCalc:
		p.calc_boundaries()
	for s in setIncome:
		s.set_income()


func update_indicators():
	if player == null || !player.is_local_player():
		return
	
	if player.hud.buildMenu.is_visible_in_tree():
		player.hud.buildMenu.update_station()
	if qInfo != null:
		qInfo.update_build()


func damage_unit(amount, clearAnim = null):
	if .damage_unit(amount, clearAnim):
		return true
	
	player.incomeOre -= incomeOre
	player.incomeEnergy -= incomeEnergy
	incomeEnergy = 0
	incomeOre = 0
	player.game.turnStations.push_back({"add": false,
								"tile": tile,
								"player": player.num,
								"color": player.color})
	
	return false


func delete():
	remove_collected_tiles()
	player.calc_boundaries()
	.delete()


func set_build(item : BuildItem):
	if item == null:
		buildQueue.clear()
		return
	
	buildQueue.push_front(item)
	if buildQueue.size() > 4:
		buildQueue.pop_back()


func get_build() -> BuildItem:
	if buildQueue.empty():
		return null
	return buildQueue.front()


func is_building():
	return !buildQueue.empty()


func remove_build_item(item : BuildItem):
	buildQueue.erase(item)


func get_remaining_build_turns():
	var bi = self.buildItem
	if bi == null:
		return INF
	
	return get_remaining_turns_for_item(bi.dossier)


func get_remaining_turns_for_item(dossier : Dictionary):
	if dossier.oreCost <= 0:
		return 0
	
	if self.incomeOre <= 0:
		return INF
	
	var availableOre = self.incomeOre
	if self.incomeEnergy >= dossier.energyCost:
		availableOre *= 2
	
	if availableOre >= dossier.oreCost:
		return 1
	
	return ceil(dossier.oreCost / float(availableOre))
