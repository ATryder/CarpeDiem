extends Node

#Unsigned 8 bit int to signed 8 bit int
func u8_to_s8(value : int):
		return (value + (1 << 7)) % (1 << 8) - (1 << 7)


#Unsigned 16 bit int to signed 16 bit int
func u16_to_s16(value : int):
	return (value + (1 << 15)) % (1 << 16) - (1 << 15)


#Unsigned 32 bit int to signed 32 bit int
func u32_to_s32(value : int):
	return (value + (1 << 31)) % (1 << 32) - (1 << 31)


#
# Interpolates a float by t between startPoint and endPoint leaving startPoint towards
# startControl and entering endPoint from the direction of endControl.
# 
# @param t The percentage of interpolation, 0 returns startPoint and 1 returns
# endPoint.
# @param startPoint The starting point.
# @param startControl The value will leaving the starting point towards startControl.
# @param endControl The value will enter endPoint from the direction of endControl.
# @param endPoint The end point.
# @return The value interpolated along the curve.
#
static func fbezier(var startPoint, var startControl, var endControl, var endPoint, var t):
	t = clamp(t, 0.0, 1.0);
	return pow(1.0 - t, 3.0) * startPoint + 3.0 * pow(1.0 - t, 2.0) * t * startControl + 3.0 * (1.0 - t) * pow(t, 2) * endControl + pow(t, 3) * endPoint

#
# Interpolates a float using the bezier formula and smoothly transitions
# between start and end points. The interpolated value will change accelerate
# as it leaves startPoint and decelerate as it enters endPoint.
#
# @param t The percentage along the path.
# @param startPoint The starting point.
# @param endPoint The ending point.
# @return The interpolated value.
#
static func fsmooth(var startPoint, var endPoint, var t):
	return fbezier(startPoint, startPoint + ((endPoint - startPoint) * 0.05), startPoint + ((endPoint - startPoint) * 0.95), endPoint, t)


static func fsmooth_stop(var startPoint, var endPoint, var t):
	return fbezier(startPoint, endPoint, endPoint, endPoint, t)


static func fsmooth_start(var startPoint, var endPoint, var t):
	return fbezier(startPoint, startPoint, startPoint, endPoint, t)


static func fsmooth_curve(var startPoint, var endPoint, var t):
	return fbezier(startPoint, startPoint, endPoint - ((endPoint - startPoint) * 0.55213), endPoint, t)


static func get_random_point_on_mesh(mesh):
	var faces = mesh.get_faces()
	var faceIdx = (randi() % (faces.size() / 3)) * 3
	var pos = faces[faceIdx]
	pos += (faces[faceIdx + 1] - pos) * randf()
	pos += (faces[faceIdx + 2] - pos) * randf()
	return pos


static func vector_reflect(direction, normal):
	var dot = direction.dot(normal)
	return Vector3(direction.x - (2 * dot) * normal.x,
			direction.y - (2 * dot) * normal.y,
			direction.z - (2 * dot) * normal.z)


# Gets the previous power of 2 less than or equal to the given number. 
# For instance passing 1024 will return 1024, and 384 will return
# 256. Anything less than or equal to 1 will return 1.
# 
# @param num The number to find the previous power of two from.
# @return The previous power of two.
static func prev_pow2(num : int) -> int:
	if (num < 2):
		return 1

	num |= (num >> 1)
	num |= (num >> 2)
	num |= (num >> 4)
	num |= (num >> 8)
	num |= (num >> 16)
	return num - (num >> 1)



# Determines if a given number is a power of two.
# 
# @param num The number to check.
# @return True if the number is a power of two otherwise false.
static func is_pow2(num : int) -> bool:
	return (num & (num - 1)) == 0


static func is_pow8(num : int) -> bool:
	var i = log(num) / log(8)
	return i - floor(i) < 0.000001


static func get_random_array_item(var arr : Array):
	if arr.empty():
		return
	var r = randi() % arr.size()
	return arr[r]


static func calc_attack_amount(attacker : Unit, defender : Unit, raw := false) -> int:
	if defender.type == CD.UNIT_CARGOSHIP:
		return 10
	
	var amount = Dossier.get(attacker.type).attackValues[defender.type]
	if attacker.type != CD.UNIT_COMMAND_STATION:
		amount = amount * (float(attacker.strength) / attacker.maxStrength)
	
	if defender.type != CD.UNIT_COMMAND_STATION:
		if raw:
			amount = clamp(amount - (defender.tile.get_raw_defense() * amount), 0, defender.strength)
		else:
			amount = clamp(amount - (defender.tile.defense * amount), 0, defender.strength)
	return int(round(amount))


static func calc_counter_attack_amount(attacker : Unit, defender : Unit,
		raw := false, attackerStrength = null) -> int:
	if attacker.type == CD.UNIT_CARGOSHIP || attacker.type == CD.UNIT_COMMAND_STATION:
		return 0
	
	var dossier = Dossier.get(attacker.type)
	var amount
	if dossier.has("counterAttackValues") && dossier.counterAttackValues[defender.type] >= 0:
		amount = dossier.counterAttackValues[defender.type]
	else:
		amount = dossier.attackValues[defender.type]
	
	if attackerStrength != null:
		amount = amount * (float(attackerStrength) / attacker.maxStrength)
	else:
		amount = amount * (float(attacker.strength) / attacker.maxStrength)
	if defender.type != CD.UNIT_COMMAND_STATION:
		if raw:
			amount = clamp(amount - (defender.tile.get_raw_defense() * amount), 0, defender.strength)
		else:
			amount = clamp(amount - (defender.tile.defense * amount), 0, defender.strength)
	return int(round(amount))


#Returns an array containing all the tiles that would be collected if a
#Command Station were placed on the origin tile
func get_resource_tiles(origin : CDTile, collectedTiles := []) -> Array:
	collectedTiles.clear()
	collectedTiles.push_back(origin)
	var costs := [0]
	var count := 0
	
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
		count += 1
	
	return collectedTiles


#Returns an array containing the tiles within extent of origin
#@param origin: The origin of the range
#@param extent: The maximum extent of the range
#@param inRange: An array to store the range of tiles
static func get_tile_range(origin : CDTile, extent : float, inRange : Array = []) -> Array:
	inRange.clear()
	inRange.push_back(origin)
	var costs = [0.0]
	var count = 0
	
	while count < inRange.size():
		var surrounding = inRange[count].get_surrounding()
		for t in surrounding:
			var totalCost = costs[count] + 1
			var idx = inRange.find_last(t)
			if idx >= 0:
				if totalCost < costs[idx]:
					costs[idx] = totalCost
			elif totalCost <= extent:
				inRange.push_back(t)
				costs.push_back(totalCost)
		count += 1
	
	return inRange


#Returns an array containing the visible tiles within sightRange of unit
#@param origin: The origin of the range
#@param sightRange: The maximum extent of the visible range
#@param visibleRange: An array to store tiles within sightRange range of origin
static func get_visible_tiles(origin : CDTile, sightRange : float, visibleRange : Array = []) -> Array:
	visibleRange.clear()
	visibleRange.push_back(origin)
	if origin != null:
		visibleRange[0] = origin
	var costs = [0.0]
	var count = 0
	
	while count < visibleRange.size():
		var surrounding = visibleRange[count].get_surrounding()
		for t in surrounding:
			var totalCost = costs[count] + t.visibilityCost
			var idx = visibleRange.find_last(t)
			if idx >= 0:
				if totalCost < costs[idx]:
					costs[idx] = totalCost
			elif totalCost <= sightRange:
				visibleRange.push_back(t)
				costs.push_back(totalCost)
		count += 1
	
	return visibleRange


#Returns an Array containing tiles within attack range of origin
#@param origin: The origin of the movement range
#@param attackRange: The maximum range of the attack area
#@param minAttackRange: The minimum range of the attack area
#@param inRange: An array that will contain the tiles in range
static func get_attack_tiles(origin : CDTile, attackRange : float, minAttackRange : float, inRange : Array = []) -> Array:
	inRange.clear()
	if attackRange == 1:
		var s = origin.get_surrounding()
		for t in s:
			inRange.push_back(t)
		return inRange
	
	inRange.push_back(origin)
	var costs := [0.0]
	var count := 0
	
	while count < inRange.size():
		var surrounding = inRange[count].get_surrounding()
		for t in surrounding:
			var totalCost = costs[count] + 1.0
			if totalCost <= attackRange:
				var idx = inRange.find_last(t)
				if idx >= 0:
					if totalCost < costs[idx]:
						costs[idx] = totalCost
				else:
					inRange.push_back(t)
					costs.push_back(totalCost)
		count += 1
	
	if minAttackRange <= 0:
		inRange.pop_front()
	else:
		count = 0
		var minTiles := [origin]
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
			inRange.erase(t)
	
	return inRange


#Returns the closest most defensible available tile from origin within a range of tiles.
#The most defensible unoccupied tile will be returned if found otherwise the most defensible
#occupied tile will be returned
static func get_closest_defensible_tile_in_range(origin : CDTile, tiles : Array) -> CDTile:
	var currentTile : CDTile
	var minDist = -INF
	var maxDef = -INF
	var occTile : CDTile
	var occDist = -INF
	var occDef = -INF
	for t in tiles:
		var def = t.get_raw_defense()
		var tmp = origin.worldLoc.distance_to(t.worldLoc)
		if !t.is_occupied():
			if def > maxDef:
				maxDef = def
				currentTile = t
				minDist = tmp
			elif def == maxDef && tmp < minDist:
				minDist = tmp
				currentTile = t
		elif def > occDef:
			occDef = def
			occTile = t
			occDist = tmp
		elif def == occDef && tmp < occDist:
			occTile = t
			occDist = tmp
	
	if currentTile != null:
		return currentTile
	else:
		return occTile


#Returns the closest available tile surrounding origin. The closest unoccupied
#tile will be returned if found otherwise the closest occupied tile will be returned
static func get_closest_surrounding_tile(origin : CDTile, from : CDTile) -> CDTile:
	var currentTile : CDTile
	var minDist := INF
	var occTile : CDTile
	var occDist := INF
	var tiles = origin.get_surrounding()
	for t in tiles:
		var tmp = from.worldLoc.distance_to(t.worldLoc)
		if !t.is_occupied():
			if tmp <= minDist:
				minDist = tmp
				currentTile = t
		elif tmp <= occDist:
			occDist = tmp
			occTile = t
	
	if currentTile != null:
		return currentTile
	else:
		return occTile


#Returns the closest available tile within a range of tiles. The closest unoccupied
#tile will be returned if found otherwise the closest occupied tile will be returned
static func get_closest_tile_in_range(origin : CDTile, tileRange : Array):
	var dist = INF
	var closeTile
	var distOcc = INF
	var closeOcc
	for tile in tileRange:
		var tmpDist = origin.worldLoc.distance_to(tile.worldLoc)
		if tile.is_occupied():
			if tmpDist < distOcc:
				distOcc = tmpDist
				closeOcc = tile
		elif tmpDist < dist:
			dist = tmpDist
			closeTile = tile
	
	if closeTile != null:
		return closeTile
	else:
		return closeOcc


#Returns the closest available tile to origin in or around a range may return null or
#an occupied tile if none are available
static func get_closest_available_tile_to_range(origin, tileRange, maxAttempts = 10):
	var tile = get_closest_tile_in_range(origin, tileRange)
	var count = 0
	while tile != null && tile.is_occupied() && count < maxAttempts:
		count += 1
		tile = get_closest_surrounding_tile(tile, origin)
	return tile


#Returns true if origin is visible or near a tile visible to playerNum
static func is_near_visible(origin : CDTile, playerNum):
	var nearVis = origin.is_visible(playerNum)
	if !nearVis:
		var surrounding = origin.get_surrounding()
		for tile in surrounding:
			if tile.is_visible(playerNum):
				nearVis = true
	return nearVis


# Create a path between two CDTiles.
#
# @param origin The starting CDTile.
# @param dest The ending CDTile.
# @param availableTilse An array of tiles that the path can traverse.
# @return An array with all nodes along the path.
static func path_to(origin, dest, availableTiles = null, player = null) -> Array:
	var openList = []
	var openTiles = []
	var closedList = []
	
	var current = PathNode.new(origin, 0.0, path_euclidean_distance(origin, dest))
	openList.push_back(current)
	openTiles.push_back(origin)
	var fin = false
	
	while !fin:
		openList.erase(current)
		openTiles.erase(current.tile)
		closedList.push_back(current.tile)
		
		var surrounding = current.tile.get_surrounding()
		for st in surrounding:
			if (closedList.has(st)
					|| (availableTiles != null && !availableTiles.has(st))
					|| (player != null && st.is_occupied() && st.is_visible(player.num))):
				continue
			if st == dest:
				fin = true
				current = PathNode.new(st, st.movementCost + current.gCost, 0.0, current)
				break
			var idx = openTiles.find_last(st)
			if idx >= 0:
				var gCost = st.movementCost + current.gCost
				var pn = openList[idx]
				if gCost < pn.gCost:
					pn.gCost = gCost
					pn.parentPathNode = current
			else:
				var pn = PathNode.new(st,
						st.movementCost + current.gCost, path_euclidean_distance(st, dest),
						current)
				openList.push_back(pn)
				openTiles.push_back(st)
		
		if fin:
			break
		
		if openList.empty():
			return []
		
		current = openList[0]
		var lowF = current.get_f()
		for pn in openList:
			var tmpF = pn.get_f()
			if tmpF < lowF:
				lowF = tmpF
				current = pn
	
	var path = []
	while current != null:
		path.push_front(current.tile)
		current = current.parentPathNode
	
	return path

static func path_euclidean_distance(origin, dest):
	var ov = origin.worldLoc
	var dv = dest.worldLoc
	
	return sqrt(pow(ov.x - dv.x, 2.0) + pow(ov.y - dv.y, 2.0))

# Create a Curve3D from an array of CDTiles
# 
# @param path An array of CDTiles
# @return A Curve3D representing a path along the CDTiles
static func create_path_curve(path):
	var trans = Transform(Basis(Vector3(1, 0, 0),
			Vector3(0, 1, 0), Vector3(0, 0, 1)))
	var curve = Curve3D.new()
	var lastPoint = Vector3(path[0].worldLoc.x, 0, path[0].worldLoc.y)
	var point = Vector3(path[1].worldLoc.x, 0, path[1].worldLoc.y)
	var handleLong = Vector3(0, 0, CD.TILE_HALF_HEIGHT * 0.75)
	var handleShort = Vector3(0, 0, CD.TILE_HALF_HEIGHT * 0.25)
	
	trans.origin.x = lastPoint.x
	trans.origin.z = lastPoint.z
	trans = trans.looking_at(point, Vector3(0, 1, 0))
	trans.origin.x = 0
	trans.origin.z = 0
	curve.add_point(lastPoint, trans.xform(handleShort), trans.xform(-handleShort))
	
	for i in range(1, path.size() - 1):
		trans.origin.x = lastPoint.x
		trans.origin.z = lastPoint.z
		trans = trans.looking_at(point, Vector3(0, 1, 0))
		
		var t = path[i]
		var t2 = path[i + 1]
		var ba = (lastPoint - point).normalized()
		var bc = Vector3(t2.worldLoc.x - point.x,
				0, t2.worldLoc.y - point.z).normalized()
		
		trans.origin.x = 0
		trans.origin.z = 0
		var dot = bc.dot(trans.xform(Vector3(1, 0, 0)))
		var ang = (PI - ba.angle_to(bc)) * 0.5
		if dot > 0:
			ang = -ang
		var tr = trans.rotated(Vector3(0, 1, 0), ang)
		curve.add_point(point, tr.xform(handleLong), tr.xform(-handleLong))
		
		lastPoint = Vector3(t.worldLoc.x, 0, t.worldLoc.y)
		point.x = t2.worldLoc.x
		point.z = t2.worldLoc.y
	
	trans.origin.x = lastPoint.x
	trans.origin.z = lastPoint.z
	trans = trans.looking_at(point, Vector3(0, 1, 0))
	trans.origin.x = 0
	trans.origin.z = 0
	curve.add_point(point, trans.xform(handleShort), trans.xform(-handleShort))
	
	return curve

# Create a cyclic Curve3D from an array of CDTiles
# 
# @param path An array of CDTiles
# @return A Curve3D representing a path along the CDTiles
static func create_cyclic_path_curve(path):
	var trans = Transform(Basis(Vector3(1, 0, 0),
			Vector3(0, 1, 0), Vector3(0, 0, 1)))
	var curve = Curve3D.new()
	var lastPoint = Vector3(path[path.size() - 1].worldLoc.x, 0,
			path[path.size() - 1].worldLoc.y)
	var point = Vector3(path[0].worldLoc.x, 0, path[0].worldLoc.y)
	var handleLong = Vector3(0, 0, CD.TILE_HALF_HEIGHT * 0.75)
	
	for i in range(path.size() - 1):
		trans.origin.x = lastPoint.x
		trans.origin.z = lastPoint.z
		trans = trans.looking_at(point, Vector3(0, 1, 0))
		
		var t = path[i]
		var t2 = path[i + 1]
		var ba = (lastPoint - point).normalized()
		var bc = Vector3(t2.worldLoc.x - point.x,
				0, t2.worldLoc.y - point.z).normalized()
		
		trans.origin.x = 0
		trans.origin.z = 0
		var dot = bc.dot(trans.xform(Vector3(1, 0, 0)))
		var ang = (PI - ba.angle_to(bc)) * 0.5
		if dot > 0:
			ang = -ang
		var tr = trans.rotated(Vector3(0, 1, 0), ang)
		curve.add_point(point, tr.xform(handleLong), tr.xform(-handleLong))
		
		lastPoint = Vector3(t.worldLoc.x, 0, t.worldLoc.y)
		point.x = t2.worldLoc.x
		point.z = t2.worldLoc.y
	
	trans.origin.x = lastPoint.x
	trans.origin.z = lastPoint.z
	trans = trans.looking_at(point, Vector3(0, 1, 0))
	
	var t = path[path.size() - 1]
	var t2 = path[0]
	var ba = (lastPoint - point).normalized()
	var bc = Vector3(t2.worldLoc.x - point.x,
			0, t2.worldLoc.y - point.z).normalized()
	
	trans.origin.x = 0
	trans.origin.z = 0
	var dot = bc.dot(trans.xform(Vector3(1, 0, 0)))
	var ang = (PI - ba.angle_to(bc)) * 0.5
	if dot > 0:
		ang = -ang
	var tr = trans.rotated(Vector3(0, 1, 0), ang)
	curve.add_point(point, trans.xform(handleLong), trans.xform(-handleLong))
	
	lastPoint = Vector3(t.worldLoc.x, 0, t.worldLoc.y)
	point.x = t2.worldLoc.x
	point.z = t2.worldLoc.y
	
	trans.origin.x = lastPoint.x
	trans.origin.z = lastPoint.y
	trans = trans.looking_at(point, Vector3(0, 1, 0))
	
	t2 = path[1]
	ba = (lastPoint - point).normalized()
	bc = Vector3(t2.worldLoc.x - point.x,
			0, t2.worldLoc.y - point.z).normalized()
	
	trans.origin.x = 0
	trans.origin.z = 0
	dot = bc.dot(trans.xform(Vector3(1, 0, 0)))
	ang = (PI - ba.angle_to(bc)) * 0.5
	if dot > 0:
		ang = -ang
	tr = trans.rotated(Vector3(0, 1, 0), ang)
	curve.add_point(point, trans.xform(handleLong), trans.xform(-handleLong))
	
	return curve

class PathNode:
	var tile
	var parentPathNode
	var gCost
	var hCost
	
	func _init(tile, gCost, hCost, parentPathNode = null):
		self.tile = tile
		self.parentPathNode = parentPathNode
		self.gCost = gCost
		self.hCost = hCost
	
	func get_f():
		return gCost + hCost
