extends Node
class_name CDTile

var fogControl
var game

var x
var y
var shifted = false
var worldLoc

var movementCost = 1.0 setget ,get_movement_cost
var visibilityCost = 1.0 setget ,get_visibility_cost

var defense := 0.0 setget ,get_defense

var mapped := []
var unitVis := []

var unit
var ghostUnit

var collectors := []
var lastSightedTerritory := -1

var color = -1 setget set_color, get_color

var asteroid setget set_asteroid_props, get_asteroid_props
var star setget set_star_props, get_star_props

var updateFog := false
var updateMap := false


func _init(x, y, numPlayers, game = null, color = -1, allVis = Opts.allVis, noFog = Opts.noFog):
	if game != null:
		self.game = game
		fogControl = game.get_node("Arena/FogControl")
	self.x = x
	self.y = y
	worldLoc = Vector2(
			((x * CD.TILE_WIDTH) * 0.75) + (CD.TILE_HALF_WIDTH),
			(y * CD.TILE_HEIGHT) + CD.TILE_HALF_HEIGHT)
	if x % 2 != 0:
		shifted = true
		worldLoc.y += CD.TILE_HALF_HEIGHT
	
	for i in range(numPlayers):
		if allVis:
			mapped.append(true)
			if noFog:
				unitVis.append(1)
			else:
				unitVis.append(0)
		else:
			mapped.append(false)
			unitVis.append(0)
	
	self.color = color


func get_visibility_cost() -> float:
	var cost = visibilityCost
	if has_star():
		cost += 0.2
	if has_asteroid():
		cost += 0.4
	if color >= 0:
		cost += 0.25
	
	return cost


func get_defense() -> float:
	if color >= 0 && asteroid != null && randf() < 0.2:
		return 1.0
	if color < 0 && star == null && asteroid == null && randf() < 0.2:
		return get_raw_defense() - 0.5
	return get_raw_defense()


func get_raw_defense() -> float:
	if color < 0:
		if asteroid != null:
			return 0.4
		if star != null:
			return 0.2
		return 0.0
	if asteroid != null:
		return 0.6
	if star != null:
		return 0.4
	return 0.2


func get_movement_cost() -> float:
	if color < 0:
		if asteroid != null:
			return 1.8
		if star != null:
			return 1.3
		return 1.0
	if asteroid != null:
		return 2.0
	if star != null:
		return 1.5
	return 1.2


func set_color(col):
	color = col


func get_color():
	return color


func get_tex_x(tile_width, padding = CD.TEX_PADDING):
	var texx = x * (tile_width * 0.75)
	texx += tile_width * 0.5
	texx += padding * tile_width
	return texx


func get_tex_y(tile_height, padding = CD.TEX_PADDING):
	var texy = y * tile_height
	texy += tile_height * 0.5
	texy += padding * tile_height
	if shifted:
		texy += tile_height * 0.5
	
	return texy


func set_asteroid_props(propertyDict):
	asteroid = propertyDict


func get_asteroid_props():
	return asteroid


func has_asteroid():
	return asteroid != null


func set_star_props(propertyDict):
	star = propertyDict


func get_star_props():
	return star


func has_star():
	return star != null


func is_occupied():
	return unit != null


func is_collected():
	return !collectors.empty()


func get_collected_station():
	if is_collected():
		return collectors[0]
	return null


func get_player():
	if unit != null:
		return unit.player
	return null


func get_player_number():
	if unit != null:
		return unit.player.num
	return -1


func has_other_player(playerNumber):
	return is_occupied() && get_player_number() != playerNumber


func is_visible(playerNum):
	return unitVis[playerNum] > 0


func update_fog():
	if updateFog:
		return
	fogControl.update(self)


func set_vis_to_player(playerNum):
	if Opts.allVis && Opts.noFog:
		return
	
	if unitVis[playerNum] == 0:
		unitVis[playerNum] = 1
		mapped[playerNum] = true
		if playerNum == game.thisPlayer:
			update_fog()
			game.hud.update_map(self)
			if unit != null && unit.player.num != playerNum:
				unit.qInfo.set_visible(true)
			if ghostUnit != null:
				ghostUnit.queue_free()
				ghostUnit = null
				if unit != null:
					unit.show()
	elif !Opts.noFog:
		unitVis[playerNum] += 1


func set_invis_to_player(playerNum):
	if Opts.noFog:
		return
	
	unitVis[playerNum] = int(max(0, unitVis[playerNum] - 1))
	if unitVis[playerNum] == 0 && playerNum == game.thisPlayer:
		update_fog()
		game.hud.update_map(self)
		if collectors.empty():
			lastSightedTerritory = -1
		else:
			lastSightedTerritory = collectors[0].player.num
		if unit != null && unit.player.num != playerNum:
			unit.qInfo.set_visible(false)
			if unit.isGhostable:
				if ghostUnit != null:
					ghostUnit.queue_free()
				ghostUnit = unit.get_ghost()
				game.get_node("GhostUnits").add_child(ghostUnit)
				unit.hide()


# Returns an Array containing the surrounding tiles in clockwise
# order.
func get_surrounding():
	var surrounding = []
	var tx = x
	var ty = y
	if shifted:
		if x == 0:
			if y == 0:
				tx = x + 1
				surrounding.push_back(game.arena.get_tile(tx, ty))
				ty = y + 1
				surrounding.push_back(game.arena.get_tile(tx, ty))
				tx = x
				surrounding.push_back(game.arena.get_tile(tx, ty))
			elif y == game.arena.MAP_HEIGHT - 1:
				ty = y - 1
				surrounding.push_back(game.arena.get_tile(tx, ty))
				tx = x + 1
				ty = y
				surrounding.push_back(game.arena.get_tile(tx, ty))
			else:
				ty = y - 1
				surrounding.push_back(game.arena.get_tile(tx, ty))
				tx = x + 1
				ty = y
				surrounding.push_back(game.arena.get_tile(tx, ty))
				ty = y + 1
				surrounding.push_back(game.arena.get_tile(tx, ty))
				tx = x
				surrounding.push_back(game.arena.get_tile(tx, ty))
		elif x == game.arena.MAP_WIDTH - 1:
			if y == 0:
				ty = y + 1
				surrounding.push_back(game.arena.get_tile(tx, ty))
				tx = x - 1
				surrounding.push_back(game.arena.get_tile(tx, ty))
				ty = y
				surrounding.push_back(game.arena.get_tile(tx, ty))
			elif y == game.arena.MAP_HEIGHT - 1:
				ty = y - 1
				surrounding.push_back(game.arena.get_tile(tx, ty))
				tx = x - 1
				ty = y
				surrounding.push_back(game.arena.get_tile(tx, ty))
			else:
				ty = y - 1
				surrounding.push_back(game.arena.get_tile(tx, ty))
				ty = y + 1
				surrounding.push_back(game.arena.get_tile(tx, ty))
				tx = x - 1
				surrounding.push_back(game.arena.get_tile(tx, ty))
				ty = y
				surrounding.push_back(game.arena.get_tile(tx, ty))
		else:
			if y == 0:
				tx = x + 1
				surrounding.push_back(game.arena.get_tile(tx, ty))
				ty = y + 1
				surrounding.push_back(game.arena.get_tile(tx, ty))
				tx = x
				surrounding.push_back(game.arena.get_tile(tx, ty))
				tx = x - 1
				surrounding.push_back(game.arena.get_tile(tx, ty))
				ty = y
				surrounding.push_back(game.arena.get_tile(tx, ty))
			elif y == game.arena.MAP_HEIGHT - 1:
				ty = y - 1
				surrounding.push_back(game.arena.get_tile(tx, ty))
				tx = x + 1
				ty = y
				surrounding.push_back(game.arena.get_tile(tx, ty))
				tx = x - 1
				surrounding.push_back(game.arena.get_tile(tx, ty))
			else:
				ty = y - 1
				surrounding.push_back(game.arena.get_tile(tx, ty))
				tx = x + 1
				ty = y
				surrounding.push_back(game.arena.get_tile(tx, ty))
				ty = y + 1
				surrounding.push_back(game.arena.get_tile(tx, ty))
				tx = x
				surrounding.push_back(game.arena.get_tile(tx, ty))
				tx = x - 1
				surrounding.push_back(game.arena.get_tile(tx, ty))
				ty = y
				surrounding.push_back(game.arena.get_tile(tx, ty))
	else:
		if x == 0:
			if y == 0:
				tx = x + 1
				surrounding.push_back(game.arena.get_tile(tx, ty))
				tx = x
				ty = y + 1
				surrounding.push_back(game.arena.get_tile(tx, ty))
			elif y == game.arena.MAP_HEIGHT - 1:
				ty = y - 1
				surrounding.push_back(game.arena.get_tile(tx, ty))
				tx = x + 1
				surrounding.push_back(game.arena.get_tile(tx, ty))
				ty = y
				surrounding.push_back(game.arena.get_tile(tx, ty))
			else:
				ty = y - 1
				surrounding.push_back(game.arena.get_tile(tx, ty))
				tx = x + 1
				surrounding.push_back(game.arena.get_tile(tx, ty))
				ty = y
				surrounding.push_back(game.arena.get_tile(tx, ty))
				tx = x
				ty = y + 1
				surrounding.push_back(game.arena.get_tile(tx, ty))
		elif x == game.arena.MAP_WIDTH - 1:
			if y == 0:
				ty = y + 1
				surrounding.push_back(game.arena.get_tile(tx, ty))
				tx = x - 1
				ty = y
				surrounding.push_back(game.arena.get_tile(tx, ty))
			elif y == game.arena.MAP_HEIGHT - 1:
				ty = y - 1
				surrounding.push_back(game.arena.get_tile(tx, ty))
				tx = x - 1
				ty = y
				surrounding.push_back(game.arena.get_tile(tx, ty))
				ty = y - 1
				surrounding.push_back(game.arena.get_tile(tx, ty))
			else:
				ty = y - 1
				surrounding.push_back(game.arena.get_tile(tx, ty))
				ty = y + 1
				surrounding.push_back(game.arena.get_tile(tx, ty))
				tx = x - 1
				ty = y
				surrounding.push_back(game.arena.get_tile(tx, ty))
				ty = y - 1
				surrounding.push_back(game.arena.get_tile(tx, ty))
		else:
			if y == 0:
				tx = x + 1
				surrounding.push_back(game.arena.get_tile(tx, ty))
				tx = x
				ty = y + 1
				surrounding.push_back(game.arena.get_tile(tx, ty))
				tx = x - 1
				ty = y
				surrounding.push_back(game.arena.get_tile(tx, ty))
			elif y == game.arena.MAP_HEIGHT - 1:
				ty = y - 1
				surrounding.push_back(game.arena.get_tile(tx, ty))
				tx = x + 1
				surrounding.push_back(game.arena.get_tile(tx, ty))
				ty = y
				surrounding.push_back(game.arena.get_tile(tx, ty))
				tx = x - 1
				surrounding.push_back(game.arena.get_tile(tx, ty))
				ty = y - 1
				surrounding.push_back(game.arena.get_tile(tx, ty))
			else:
				ty = y - 1
				surrounding.push_back(game.arena.get_tile(tx, ty))
				tx = x + 1
				surrounding.push_back(game.arena.get_tile(tx, ty))
				ty = y
				surrounding.push_back(game.arena.get_tile(tx, ty))
				tx = x
				ty = y + 1
				surrounding.push_back(game.arena.get_tile(tx, ty))
				tx = x - 1
				ty = y
				surrounding.push_back(game.arena.get_tile(tx, ty))
				ty = y - 1
				surrounding.push_back(game.arena.get_tile(tx, ty))
	return surrounding


# Returns an Array containing the surrounding tiles in clockwise
# order. The returned array is always the same size, 6, beginning
# with the top tile. Tiles that fall outside the map, such as
# (-1, -1), are null.
func get_surrounding_full():
	var surrounding = []
	var tx = x
	var ty = y
	if shifted:
		if x == 0:
			if y == 0:
				surrounding.push_back(null)
				tx = x + 1
				surrounding.push_back(game.arena.get_tile(tx, ty))
				ty = y + 1
				surrounding.push_back(game.arena.get_tile(tx, ty))
				tx = x
				surrounding.push_back(game.arena.get_tile(tx, ty))
				surrounding.push_back(null)
				surrounding.push_back(null)
			elif y == game.arena.MAP_HEIGHT - 1:
				surrounding.push_back(null)
				surrounding.push_back(null)
				surrounding.push_back(null)
				surrounding.push_back(null)
				ty = y - 1
				surrounding.push_back(game.arena.get_tile(tx, ty))
				tx = x + 1
				ty = y
				surrounding.push_back(game.arena.get_tile(tx, ty))
			else:
				ty = y - 1
				surrounding.push_back(game.arena.get_tile(tx, ty))
				tx = x + 1
				ty = y
				surrounding.push_back(game.arena.get_tile(tx, ty))
				ty = y + 1
				surrounding.push_back(game.arena.get_tile(tx, ty))
				tx = x
				surrounding.push_back(game.arena.get_tile(tx, ty))
				surrounding.push_back(null)
				surrounding.push_back(null)
		elif x == game.arena.MAP_WIDTH - 1:
			if y == 0:
				surrounding.push_back(null)
				surrounding.push_back(null)
				surrounding.push_back(null)
				ty = y + 1
				surrounding.push_back(game.arena.get_tile(tx, ty))
				tx = x - 1
				surrounding.push_back(game.arena.get_tile(tx, ty))
				ty = y
				surrounding.push_back(game.arena.get_tile(tx, ty))
			elif y == game.arena.MAP_HEIGHT - 1:
				ty = y - 1
				surrounding.push_back(game.arena.get_tile(tx, ty))
				surrounding.push_back(null)
				surrounding.push_back(null)
				surrounding.push_back(null)
				surrounding.push_back(null)
				tx = x - 1
				ty = y
				surrounding.push_back(game.arena.get_tile(tx, ty))
			else:
				ty = y - 1
				surrounding.push_back(game.arena.get_tile(tx, ty))
				surrounding.push_back(null)
				surrounding.push_back(null)
				ty = y + 1
				surrounding.push_back(game.arena.get_tile(tx, ty))
				tx = x - 1
				surrounding.push_back(game.arena.get_tile(tx, ty))
				ty = y
				surrounding.push_back(game.arena.get_tile(tx, ty))
		else:
			if y == 0:
				surrounding.push_back(null)
				tx = x + 1
				surrounding.push_back(game.arena.get_tile(tx, ty))
				ty = y + 1
				surrounding.push_back(game.arena.get_tile(tx, ty))
				tx = x
				surrounding.push_back(game.arena.get_tile(tx, ty))
				tx = x - 1
				surrounding.push_back(game.arena.get_tile(tx, ty))
				ty = y
				surrounding.push_back(game.arena.get_tile(tx, ty))
			elif y == game.arena.MAP_HEIGHT - 1:
				ty = y - 1
				surrounding.push_back(game.arena.get_tile(tx, ty))
				tx = x + 1
				ty = y
				surrounding.push_back(game.arena.get_tile(tx, ty))
				surrounding.push_back(null)
				surrounding.push_back(null)
				surrounding.push_back(null)
				tx = x - 1
				surrounding.push_back(game.arena.get_tile(tx, ty))
			else:
				ty = y - 1
				surrounding.push_back(game.arena.get_tile(tx, ty))
				tx = x + 1
				ty = y
				surrounding.push_back(game.arena.get_tile(tx, ty))
				ty = y + 1
				surrounding.push_back(game.arena.get_tile(tx, ty))
				tx = x
				surrounding.push_back(game.arena.get_tile(tx, ty))
				tx = x - 1
				surrounding.push_back(game.arena.get_tile(tx, ty))
				ty = y
				surrounding.push_back(game.arena.get_tile(tx, ty))
	else:
		if x == 0:
			if y == 0:
				surrounding.push_back(null)
				surrounding.push_back(null)
				tx = x + 1
				surrounding.push_back(game.arena.get_tile(tx, ty))
				tx = x
				ty = y + 1
				surrounding.push_back(game.arena.get_tile(tx, ty))
				surrounding.push_back(null)
				surrounding.push_back(null)
			elif y == game.arena.MAP_HEIGHT - 1:
				ty = y - 1
				surrounding.push_back(game.arena.get_tile(tx, ty))
				tx = x + 1
				surrounding.push_back(game.arena.get_tile(tx, ty))
				ty = y
				surrounding.push_back(game.arena.get_tile(tx, ty))
				surrounding.push_back(null)
				surrounding.push_back(null)
				surrounding.push_back(null)
			else:
				ty = y - 1
				surrounding.push_back(game.arena.get_tile(tx, ty))
				tx = x + 1
				surrounding.push_back(game.arena.get_tile(tx, ty))
				ty = y
				surrounding.push_back(game.arena.get_tile(tx, ty))
				tx = x
				ty = y + 1
				surrounding.push_back(game.arena.get_tile(tx, ty))
				surrounding.push_back(null)
				surrounding.push_back(null)
		elif x == game.arena.MAP_WIDTH - 1:
			if y == 0:
				surrounding.push_back(null)
				surrounding.push_back(null)
				surrounding.push_back(null)
				ty = y + 1
				surrounding.push_back(game.arena.get_tile(tx, ty))
				tx = x - 1
				ty = y
				surrounding.push_back(game.arena.get_tile(tx, ty))
				surrounding.push_back(null)
			elif y == game.arena.MAP_HEIGHT - 1:
				ty = y - 1
				surrounding.push_back(game.arena.get_tile(tx, ty))
				surrounding.push_back(null)
				surrounding.push_back(null)
				surrounding.push_back(null)
				tx = x - 1
				ty = y
				surrounding.push_back(game.arena.get_tile(tx, ty))
				ty = y - 1
				surrounding.push_back(game.arena.get_tile(tx, ty))
			else:
				ty = y - 1
				surrounding.push_back(game.arena.get_tile(tx, ty))
				surrounding.push_back(null)
				surrounding.push_back(null)
				ty = y + 1
				surrounding.push_back(game.arena.get_tile(tx, ty))
				tx = x - 1
				ty = y
				surrounding.push_back(game.arena.get_tile(tx, ty))
				ty = y - 1
				surrounding.push_back(game.arena.get_tile(tx, ty))
		else:
			if y == 0:
				surrounding.push_back(null)
				surrounding.push_back(null)
				tx = x + 1
				surrounding.push_back(game.arena.get_tile(tx, ty))
				tx = x
				ty = y + 1
				surrounding.push_back(game.arena.get_tile(tx, ty))
				tx = x - 1
				ty = y
				surrounding.push_back(game.arena.get_tile(tx, ty))
				surrounding.push_back(null)
			elif y == game.arena.MAP_HEIGHT - 1:
				ty = y - 1
				surrounding.push_back(game.arena.get_tile(tx, ty))
				tx = x + 1
				surrounding.push_back(game.arena.get_tile(tx, ty))
				ty = y
				surrounding.push_back(game.arena.get_tile(tx, ty))
				surrounding.push_back(null)
				tx = x - 1
				surrounding.push_back(game.arena.get_tile(tx, ty))
				ty = y - 1
				surrounding.push_back(game.arena.get_tile(tx, ty))
			else:
				ty = y - 1
				surrounding.push_back(game.arena.get_tile(tx, ty))
				tx = x + 1
				surrounding.push_back(game.arena.get_tile(tx, ty))
				ty = y
				surrounding.push_back(game.arena.get_tile(tx, ty))
				tx = x
				ty = y + 1
				surrounding.push_back(game.arena.get_tile(tx, ty))
				tx = x - 1
				ty = y
				surrounding.push_back(game.arena.get_tile(tx, ty))
				ty = y - 1
				surrounding.push_back(game.arena.get_tile(tx, ty))
	return surrounding


func get_top():
	return Vector3(worldLoc.x, 0,
			worldLoc.y - CD.TILE_HALF_HEIGHT)


func get_bottom():
	return Vector3(worldLoc.x, 0,
			worldLoc.y + CD.TILE_HALF_HEIGHT )


func get_right():
	return Vector3(worldLoc.x + CD.TILE_HALF_WIDTH,
			0, worldLoc.y)


func get_left():
	return Vector3(worldLoc.x - CD.TILE_HALF_WIDTH,
			0, worldLoc.y)


func get_bottom_right():
	return Vector3(worldLoc.x + (CD.TILE_HALF_WIDTH * 0.5),
			0, worldLoc.y + CD.TILE_HALF_HEIGHT)


func get_bottom_left():
	return Vector3(worldLoc.x - (CD.TILE_HALF_WIDTH * 0.5),
			0, worldLoc.y + CD.TILE_HALF_HEIGHT)


func get_top_right():
	return Vector3(worldLoc.x + (CD.TILE_HALF_WIDTH * 0.5),
			0, worldLoc.y - CD.TILE_HALF_HEIGHT)


func get_top_left():
	return Vector3(worldLoc.x - (CD.TILE_HALF_WIDTH * 0.5),
			0, worldLoc.y - CD.TILE_HALF_HEIGHT)
