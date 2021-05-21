extends Spatial
class_name Unit

var player

var strength = -1 setget set_strength, get_strength
export(int, 1, 100) var maxStrength = 10

export(float, 0, 100) var moveRange = 0
export(float, 0, 100) var attackRange = 0
export(float, 0, 100) var minAttackRange = 0
export(float, 0, 100) var visibilityRange = 0

export var isGhostable = false
export(int, "UNIT_COMMAND_STATION", "UNIT_NIGHTHAWK", "UNIT_GAUMOND", "UNIT_THANANOS", "UNIT_AURORA", "UNIT_CARGOSHIP") var type
export(NodePath) var geomPath
var geom
export(PackedScene) var actionButtonScene
export(PackedScene) var engineFX

var tile : CDTile setget ,get_tile
var qInfo : QuickInfo setget set_quick_info, get_quick_info

export(int) var max_attacks = 0
export(int) var max_moves = 0
var attacks = 1 setget set_attacks, get_attacks
var moves = 1 setget set_moves, get_moves

var mpa = 0 setget set_mpa, get_mpa

export(Script) var attackAnimation
export(PackedScene) var attackWeaponSpawn
export(bool) var randomWeaponSpawn = false
export(int) var numberOfAttackShots
export(Vector3) var attackFaceVector = Vector3(0, 0, 1)
export(Script) var counterAttackAnimation
export(PackedScene) var counterAttackWeaponSpawn
export(bool) var randomCounterAttackWeaponSpawn = false
export(int) var numberOfCounterAttackShots
export(Vector3) var counterAttackFaceVector = Vector3(0, 0, 1)

export(Script) var destroyAnimation
export(PackedScene) var destroyFX

var animation setget set_animation, get_animation

var initialized := false
var execAI_Task := false

func _ready():
	set_physics_process(false)
	set_process(false)
	if player == null:
		player = get_node("../../")
	
	if !initialized:
		init_from_dossier()
	
	var visTiles
	if tile != null:
		tile.unit = self
		transform.origin.x = tile.worldLoc.x
		transform.origin.z = tile.worldLoc.y
		visTiles = get_visible_range()
		add_vis_to_tiles(visTiles)
		if (type == CD.UNIT_COMMAND_STATION
				&& (player.is_local_player()
				|| tile.is_visible(player.num))):
			player.hud.update_map(tile)
		if qInfo != null:
			qInfo.set_visible(player.is_local_player() || tile.is_visible(player.game.thisPlayer))
	
	geom = get_node(geomPath)
	geom.set_surface_material(0, player.get_material(type))
	
	if player.game != null && !player.is_local_player():
		if type != CD.UNIT_COMMAND_STATION:
			if visTiles != null:
				for t in visTiles:
					player.factionManager.update_tile(t)
			if execAI_Task:
				player.exec_next_task()


func init_from_dossier():
	var dossier = Dossier.get(type)
	moveRange = dossier.moveRange
	attackRange = dossier.attackRange
	minAttackRange = dossier.minAttackRange
	visibilityRange = dossier.sensorRange
	max_attacks = dossier.maxAttacks
	max_moves = dossier.maxMoves
	maxStrength = dossier.maxStrength
	strength = maxStrength
	rotate_y(rand_range(0, PI * 2))
	initialized = true


func get_tile() -> CDTile:
	return tile


func set_quick_info(value : QuickInfo):
	qInfo = value
	if qInfo == null || tile == null || player == null:
		return
	
	qInfo.set_visible(player.is_local_player() || !tile.is_visible(player.num))

func get_quick_info() -> QuickInfo:
	return qInfo


func _process(delta):
	if animation == null:
		return
	
	var anim = animation
	if animation.update(delta):
		if anim == animation:
			self.animation = null
		update_button_state()

func _physics_process(delta):
	if (animation == null
			or !animation.has_method("phy_update")
			or !animation.phyUpdate
			or animation.phy_update(delta)):
		set_physics_process(false)


func set_animation(anim):
	animation = anim
	set_process(anim != null)


func get_animation():
	return animation


func is_alive():
	return strength > 0


func get_ghost():
	var ghost := GhostUnit.new()
	ghost.playerNum = player.num
	ghost.mesh = geom.mesh
	ghost.set_surface_material(0, player.get_ghost_material(type))
	ghost.set_rotation(get_rotation())
	ghost.transform.origin = transform.origin
	return ghost


func set_strength(value):
	strength = clamp(value, 0, maxStrength)
	if player != null && qInfo != null:
		qInfo.update_strength()
	if is_alive():
		reset_tile_display()

func get_strength():
	return strength

func get_max_mpa():
	if type == CD.UNIT_COMMAND_STATION:
		return 10
	elif type == CD.UNIT_CARGOSHIP:
		return 4
	return 0

func remove_mpa(amount):
	set_mpa(mpa - amount)

func add_mpa(amount):
	set_mpa(mpa + amount)

func set_mpa(amount):
	mpa = clamp(amount, 0, get_max_mpa())
	update_button_state()
	if player != null and player.is_local_player():
		reset_tile_display()
		if qInfo != null:
			qInfo.update_icons()

func get_mpa():
	return mpa

func set_attacks(amount):
	if type == CD.UNIT_CARGOSHIP:
		return
	
	attacks = clamp(amount, 0, 1)
	if attacks == 0:
		moves = 0
	update_button_state()
	if player != null and player.is_local_player() and qInfo != null:
		qInfo.update_icons()

func get_attacks():
	return min(attacks, max_attacks)

func set_moves(amount):
	if type == CD.UNIT_COMMAND_STATION:
		return
	
	moves = clamp(amount, 0, 1)
	update_button_state()
	if player != null and player.is_local_player() and qInfo != null:
		qInfo.update_icons()

func get_moves():
	return min(moves, max_moves)

func reset_on_turn():
	self.attacks = max_attacks
	self.moves = max_moves

func is_animating():
	return animation != null

func update_button_state():
	if (player == null
			or player.hud.actionButtonDisplay == null
			or player.hud.actionButtonDisplay.tile != tile):
			return
	
	if is_alive():
		player.hud.actionButtonDisplay.update_button_state()
	else:
		player.hud.actionButtonDisplay.close()

func reset_tile_display():
	if player == null:
		return
	
	if player.hud.selectedTile == tile:
		player.hud.selectedTileDisplay.reset_tile()
	if player.hud.hoveredTile == tile:
		player.hud.hoveredTileDisplay.reset_tile()

func get_visible_range(origin = null):
	var tiles = [tile]
	if origin != null:
		tiles[0] = origin
	var costs = [0.0]
	var count = 0
	
	while count < tiles.size():
		var surrounding = tiles[count].get_surrounding()
		for t in surrounding:
			var totalCost = costs[count] + t.visibilityCost
			var idx = tiles.find_last(t)
			if idx >= 0:
				if totalCost < costs[idx]:
					costs[idx] = totalCost
			elif totalCost <= visibilityRange:
				tiles.push_back(t)
				costs.push_back(totalCost)
		count += 1
	
	return tiles


func get_movement_range(tiles = []):
	tiles.clear()
	tiles.push_front(tile)
	var costs := [0.0]
	var count := 0
	
	if player.is_local_player():
		while count < tiles.size():
			var surrounding = tiles[count].get_surrounding()
			for t in surrounding:
				if !t.is_occupied() || !t.is_visible(player.num):
					var totalCost = costs[count] + t.movementCost
					if totalCost <= moveRange:
						var idx = tiles.find_last(t)
						if idx >= 0:
							if totalCost < costs[idx]:
								tiles.remove(idx)
								costs.remove(idx)
								tiles.push_back(t)
								costs.push_back(totalCost)
								count -= 1
						else:
							tiles.push_back(t)
							costs.push_back(totalCost)
			count += 1
	else:
		while count < tiles.size():
			var surrounding = tiles[count].get_surrounding()
			for t in surrounding:
				if (t.is_occupied() && (t.is_visible(player.num)
						|| !player.factionManager.factions.has(t.unit.player)
						|| player.factionManager.has_station_tile(t))):
					continue
				
				var totalCost = costs[count] + t.movementCost
				if totalCost <= moveRange:
					var idx = tiles.find_last(t)
					if idx >= 0:
						if totalCost < costs[idx]:
							tiles.remove(idx)
							costs.remove(idx)
							tiles.push_back(t)
							costs.push_back(totalCost)
							count -= 1
					else:
						tiles.push_back(t)
						costs.push_back(totalCost)
			count += 1
	tiles.pop_front()
	return tiles


func get_territory_safe_movement_range(tiles = []):
	var checkedStations := []
	var aRange := []
	
	tiles = get_movement_range(tiles)
	var td = tiles.duplicate()
	for t in td:
		if (t.is_collected() && !checkedStations.has(t.collectors[0])
				&& player.factionManager.factions.has(t.collectors[0].player)
				&& (t.is_visible(player.num)
				|| player.factionManager.factions[t.collectors[0].player].units[CD.UNIT_COMMAND_STATION].has(t.collectors[0].tile))):
			var stn = t.collectors[0]
			checkedStations.push_back(stn)
			aRange = Math.get_attack_tiles(stn.tile, stn.attackRange, stn.minAttackRange, aRange)
			for tile in aRange:
				tiles.erase(tile)
	
	return tiles


func get_attack_range():
	var tiles = []
	if attackRange == 1:
		var s = tile.get_surrounding()
		for t in s:
			if t.get_player_number() != player.num:
				tiles.push_back(t)
		return tiles
	
	tiles.push_back(tile)
	var costs := [0.0]
	var count := 0
	
	while count < tiles.size():
		var surrounding = tiles[count].get_surrounding()
		for t in surrounding:
			if t.is_visible(player.num):
				var totalCost = costs[count] + 1.0
				if totalCost <= attackRange:
					var idx = tiles.find_last(t)
					if idx >= 0:
						if totalCost < costs[idx]:
							costs[idx] = totalCost
					else:
						tiles.push_back(t)
						costs.push_back(totalCost)
		count += 1
	
	if minAttackRange <= 0:
		tiles.pop_front()
	else:
		count = 0
		var minTiles = [tile]
		costs = [0.0]
		while count < minTiles.size():
			var surrounding = minTiles[count].get_surrounding()
			for t in surrounding:
				var totalCost = costs[count] + 1.0
				var idx = minTiles.find_last(t)
				if idx >= 0:
					if totalCost < costs[idx]:
						costs[idx] = totalCost
				elif totalCost <= minAttackRange:
					minTiles.push_back(t)
					costs.push_back(totalCost)
			count += 1
		
		for t in minTiles:
			tiles.erase(t)
	
	var rem = []
	for t in tiles:
		if t.get_player_number() == player.num:
			rem.push_back(t)
	for t in rem:
		tiles.erase(t)
	return tiles


func get_total_attack_range():
	var tiles = [tile]
	var costs = [0.0]
	var mTiles = []
	var aTiles = []
	var acosts = [0.0]
	var count = 0
	
	while count < tiles.size():
		var surrounding = tiles[count].get_surrounding()
		for t in surrounding:
			var totalCost = costs[count] + t.movementCost
			if totalCost - moveRange <= 0.00000000001 && (!t.is_occupied() || !t.is_visible(player.game.thisPlayer)):
				var idx = tiles.find_last(t)
				if idx >= 0:
					if totalCost < costs[idx]:
						acosts.remove(idx)
						acosts.push_back(0.0)
						costs.remove(idx)
						costs.push_back(totalCost)
						tiles.remove(idx)
						tiles.push_back(t)
						if aTiles.has(t):
							aTiles.erase(t)
						if mTiles.has(t):
							mTiles.erase(t)
						mTiles.push_back(t)
						count -= 1
				else:
					tiles.push_back(t)
					mTiles.push_back(t)
					costs.push_back(totalCost)
					acosts.push_back(0.0)
			elif !mTiles.has(t):
				totalCost = acosts[count] + 1.0
				if totalCost - attackRange <= 0.00000000001:
					var idx = tiles.find_last(t)
					if idx >= 0:
						if totalCost < acosts[idx]:
							acosts.remove(idx)
							acosts.push_back(totalCost)
							if !t.is_occupied() && costs[count] + t.movementCost < costs[idx]:
								costs.remove(idx)
								costs.push_back(costs[count] + t.movementCost)
							else:
								costs.remove(idx)
								costs.push_back(10000000.0)
							tiles.remove(idx)
							tiles.push_back(t)
							aTiles.erase(t)
							aTiles.push_back(t)
							count -= 1
					else:
						tiles.push_back(t)
						aTiles.push_back(t)
						if !t.is_occupied():
							costs.push_back(costs[count] + t.movementCost)
						else:
							costs.push_back(10000000.0)
						acosts.push_back(totalCost)
		count += 1
	tiles.pop_front()
	
	return {"tiles": tiles, "moveTiles": mTiles, "attackTiles": aTiles}


func remove_vis_from_tiles(tiles = null):
	if tiles == null:
		tiles = get_visible_range()
	
	for t in tiles:
		t.set_invis_to_player(player.num)


func add_vis_to_tiles(tiles = null):
	if tiles == null:
		tiles = get_visible_range()
	
	for t in tiles:
		t.set_vis_to_player(player.num)


func move_along_path(path, curve = null):
	var newPath = []
	for t in path:
		if t.is_occupied() and t.get_player_number() != player.num:
			break
		newPath.push_back(t)
	
	if newPath.empty():
		self.attacks = 0
		self.moves = 0
		if !player.is_local_player():
			player.exec_next_task()
		return
	
	if newPath.size() != path.size():
		self.attacks = 0
		curve = Math.create_path_curve(newPath)
	elif curve == null:
		curve = Math.create_path_curve(newPath)
	
	self.animation = preload("res://scripts/game/units/animations/unit_move.gd").new(self, newPath, curve)
	
	self.moves = 0
	
	tile.unit = null
	if (!tile.collectors.empty() && tile.collectors[0].player.num != player.num
			&& (player.is_local_player() || player.factionManager.factions.has(tile.collectors[0].player))):
			tile.collectors[0].set_income()
			if tile.collectors[0].player.num == player.game.thisPlayer:
				tile.collectors[0].reset_tile_display()
	reset_tile_display()
	tile = newPath[newPath.size() - 1]
	var dest = newPath[newPath.size() - 1]
	tile.unit = self
	var newVisTiles = get_visible_range(dest)
	add_vis_to_tiles(newVisTiles)


func end_move(origin : CDTile, dest = null):
	var visTiles
	if dest == null:
		dest = tile
		visTiles = get_visible_range(tile)
	elif dest != tile && tile.unit == self:
		tile.unit = null
		if (!tile.collectors.empty() && tile.collectors[0].player.num != player.num
				&& (player.is_local_player()
				|| player.factionManager.factions.has(tile.collectors[0].player))):
			tile.collectors[0].set_income()
			if tile.collectors[0].player.num == player.game.thisPlayer:
				tile.collectors[0].reset_tile_display()
		tile = dest
		tile.unit = self
		visTiles = get_visible_range(tile)
		add_vis_to_tiles(visTiles)
	else:
		visTiles = get_visible_range(tile)
	
	var oldVisTiles = get_visible_range(origin)
	remove_vis_from_tiles(oldVisTiles)
	if (!dest.collectors.empty() && dest.collectors[0].player.num != player.num
			&& (player.is_local_player() || player.factionManager.factions.has(dest.collectors[0].player))):
			dest.collectors[0].set_income()
			if dest.collectors[0].player.num == player.game.thisPlayer:
				dest.collectors[0].reset_tile_display()
	
	transform.origin.x = dest.worldLoc.x
	transform.origin.z = dest.worldLoc.y
	
	self.animation = null
	
	reset_tile_display()
	
	for p in player.game.players:
		if p != player && !p.is_local_player() && tile.is_visible(p.num):
			p.factionManager.unit_sighted(self)
	
	if player.is_local_player():
		if player.hud.selectedTile == origin:
			player.hud.selectedTile = dest
		update_button_state()
	elif player.mai != null:
		player.mai.lock()
		var loopFin = player.mai.loopFin
		player.mai.unlock()
		if !loopFin && !(Opts.allVis && Opts.noFog):
			var rerun = false
			for t in visTiles:
				if player.factionManager.update_tile(t):
					rerun = true
			if !rerun:
				player.exec_next_task()
			else:
				player.exec_ai()
		else:
			for t in visTiles:
				player.factionManager.update_tile(t)
			player.exec_next_task()
	else:
		for t in visTiles:
			player.factionManager.update_tile(t)
		player.exec_next_task()


func attack_tile(tileToAttack):
	if tileToAttack.unit == null || !tileToAttack.unit.is_alive():
		if !player.is_local_player():
			player.exec_next_task()
		return
	
	if tileToAttack.unit.is_animating() && player.is_local_player():
		return
	
	if attackWeaponSpawn != null:
		self.animation = attackAnimation.new(self, tileToAttack.unit, attackFaceVector, numberOfAttackShots, attackWeaponSpawn.instance())
	else:
		self.animation = attackAnimation.new(self, tileToAttack.unit, attackFaceVector, numberOfAttackShots)
	
	update_button_state()
	if animation.phyUpdate:
		set_physics_process(true)


func counter_attack(tileToAttack, damage := 0):
	if damage >= strength || type == CD.UNIT_COMMAND_STATION:
		return false
	
	if type == CD.UNIT_AURORA:
		if tile.get_surrounding().has(tileToAttack):
			self.animation = counterAttackAnimation.new(self, tileToAttack.unit, counterAttackFaceVector, numberOfCounterAttackShots, counterAttackWeaponSpawn.instance(), true, damage)
		elif get_attack_range().has(tileToAttack):
			self.animation = attackAnimation.new(self, tileToAttack.unit, counterAttackFaceVector, numberOfCounterAttackShots, attackWeaponSpawn.instance(), true, damage)
		else:
			return false
	else:
		if (counterAttackAnimation == null
				or !get_attack_range().has(tileToAttack)):
			return false
		
		if counterAttackWeaponSpawn != null:
			self.animation = counterAttackAnimation.new(self, tileToAttack.unit, counterAttackFaceVector, numberOfCounterAttackShots, counterAttackWeaponSpawn.instance(), true, damage)
		elif attackWeaponSpawn != null:
			self.animation = counterAttackAnimation.new(self, tileToAttack.unit, counterAttackFaceVector, numberOfCounterAttackShots, attackWeaponSpawn.instance(), true, damage)
		else:
			self.animation = counterAttackAnimation.new(self, tileToAttack.unit, counterAttackFaceVector, numberOfCounterAttackShots, true, damage)
	
	update_button_state()
	if animation.phyUpdate:
		set_physics_process(true)
	
	return true


func subtract_hp(amount):
	self.strength -= amount
	return is_alive()


func damage_unit(amount, clearAnim = null):
	if subtract_hp(amount):
		if tile != null && tile.is_visible(player.game.thisPlayer):
			var pl = load("res://fx/PointLoss.tscn").instance()
			pl.tile = tile
			pl.set_points(amount)
			player.game.get_node("PointLoss").add_child(pl)
		return true
	
	if destroyFX != null:
		self.animation = destroyAnimation.new(self, destroyFX.instance(), clearAnim)
	else:
		self.animation = destroyAnimation.new(self, null, clearAnim)
	set_physics_process(animation.phyUpdate)
	
	return false


func delete():
	if tile != null:
		if player.game.hud.selectedTile == tile:
			player.game.hud.mouseControl.indicators.clear()
			if player.is_local_player() && player.game.is_local_turn():
				player.game.hud.close_action_button_display()
			
		tile.unit = null
		if type == CD.UNIT_COMMAND_STATION:
			player.hud.update_map(tile)
		else:
			if !tile.collectors.empty() && tile.collectors[0].player.num != player.num:
				tile.collectors[0].set_income()
				if tile.collectors[0].player.num == player.game.thisPlayer:
					tile.collectors[0].reset_tile_display()
		remove_vis_from_tiles()
		update_button_state()
		reset_tile_display()
	if qInfo != null:
		qInfo.queue_free()
	queue_free()
