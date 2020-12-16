extends Reference
class_name TerritoryGenerator

var thread
var tasks = Tasks.new()


class Tasks extends Mutex:
	var tasks = []
	var fin = true


func add_task(task):
	var lockObtained = tasks.try_lock() == OK
	if lockObtained:
		tasks.tasks.push_back(task)
		var fin = tasks.fin
		tasks.fin = false
		tasks.unlock()
		
		if fin:
			if thread != null:
				thread.wait_to_finish()
			thread = Thread.new()
			thread.start(self, "update_territories", tasks)
	
	return lockObtained


func update_territories(tasks):
	while true:
		tasks.lock()
		var task = tasks.tasks.pop_front()
		if task == null:
			tasks.fin = true
			tasks.unlock()
			return
		tasks.unlock()
		
		task.lock()
		if !task.cancelled:
			task.unlock()
			generate_curves(task)
		else:
			task.unlock()
		
		tasks.lock()
		if tasks.tasks.empty():
			tasks.fin = true
			tasks.unlock()
			return
		tasks.unlock()


func generate_curves(mutex):
	mutex.lock()
	var tiles = mutex.territory
	mutex.territory = null
	mutex.unlock()
	var tmpTiles = tiles.duplicate()
	var boundaries = []
	
	var start = get_boundary_start(tiles, tmpTiles)
	while start != null:
		boundaries.push_back(create_boundary(tiles, tmpTiles, start))
		mutex.lock()
		if mutex.cancelled:
			mutex.unlock()
			break
		else:
			mutex.unlock()
		start = get_boundary_start(tiles, tmpTiles)
	
	var curves = create_boundary_curves(boundaries, mutex)
	mutex.lock()
	mutex.boundaryCurves = curves
	mutex.unlock()


func get_boundary_start(tiles, tmpTiles):
	for t in tmpTiles:
		if is_boundary_tile(t, tiles):
			return t
	return null


func create_boundary(tiles, tmpTiles, start):
	tmpTiles.erase(start)
	var bt = BoundaryTile.new(start)
	var boundary = [bt]
	bt.next = find_next_boundary_tile(start, null, tiles)
	if bt.next == null:
		return boundary
	
	while true:
		var previous = bt.origin
		var next = find_next_boundary_tile(bt.next, previous, tiles)
		bt = BoundaryTile.new(bt.next)
		bt.previous = previous
		bt.next = next
		tmpTiles.erase(bt.origin)
		boundary.push_back(bt)
		
		if bt.next == start:
			if !tmpTiles.has(find_next_boundary_tile(start, bt.origin, tiles)):
				break
	
	boundary[0].previous = bt.origin
	
	return boundary


func find_next_boundary_tile(current, previous, tiles):
	var surrounding
	var idx = 0
	if previous == null:
		surrounding = current.get_surrounding_full()
		# If previous is null we are dealing with the first tile
		# in the series. In this case we want to begin our search
		# for the next bounary tile after the first outside tile.
		# We are searching the surrounding tiles in clockwise
		# order. Doing this ensures that the interior of the
		# territory boundary is always to the right of travel.
		for i in range(surrounding.size()):
			if !tiles.has(surrounding[i]):
				idx = i
				break
	else:
		surrounding = current.get_surrounding()
		idx = surrounding.find(previous)
	if idx == surrounding.size() - 1:
		idx = 0
	else:
		idx += 1
	
	var count = 0
	while count < surrounding.size() - 1:
		var t = surrounding[idx]
		if tiles.has(t) and is_boundary_tile(t, tiles):
			return t
		
		count += 1
		if idx == surrounding.size() - 1:
			idx = 0
		else:
			idx += 1
	
	return previous


func is_boundary_tile(tile, tiles):
	for t in tile.get_surrounding_full():
		if t == null or !tiles.has(t):
			return true
	return false


func create_boundary_curves(boundaries, mutex):
	var curves = []
	for boundary in boundaries:
		if boundary.size() == 1:
			curves.push_back(create_boundary_circle(boundary[0].origin))
		else:
			curves.push_back(create_boundary_curve(boundary))
		mutex.lock()
		if mutex.cancelled:
			mutex.unlock()
			return null
		mutex.unlock()
	
	return curves


func create_boundary_circle(tile):
	var curve = Curve3D.new()
	var loc = Vector3(tile.worldLoc.x, 0, tile.worldLoc.y)
	var handle = CD.TILE_HALF_HEIGHT * 0.5
	
	var point = loc - Vector3(0, 0, CD.TILE_HALF_HEIGHT)
	curve.add_point(point, Vector3(-handle, 0, 0),
			Vector3(handle, 0, 0))
	
	point = loc + Vector3(CD.TILE_HALF_HEIGHT, 0, 0)
	curve.add_point(point, Vector3(0, 0, -handle),
			Vector3(0, 0, handle))
	
	point = loc + Vector3(0, 0, CD.TILE_HALF_HEIGHT)
	curve.add_point(point, Vector3(handle, 0, 0),
			Vector3(-handle, 0, 0))
	
	point = loc - Vector3(CD.TILE_HALF_HEIGHT, 0, 0)
	curve.add_point(point, Vector3(0, 0, handle),
			Vector3(0, 0, -handle))
	
	point = loc - Vector3(0, 0, CD.TILE_HALF_HEIGHT)
	curve.add_point(point, Vector3(-handle, 0, 0),
			Vector3(handle, 0, 0))
	
	return curve


func create_boundary_curve(boundary):
	var curve = Curve3D.new()
	var trans = Transform(Basis(Vector3(1, 0, 0),
			Vector3(0, 1, 0), Vector3(0, 0, 1)))
	var handle = Vector3(0, 0, CD.TILE_HALF_HEIGHT * 0.8)
	
	var bt = boundary[0]
	var prevPoint
	var currentPoint = get_curve_point(boundary[boundary.size() - 1])
	if currentPoint.size() > 1:
		prevPoint = currentPoint[1]
		currentPoint = currentPoint[0]
	else:
		currentPoint = currentPoint[0]
		prevPoint = get_curve_point(boundary[boundary.size() - 2])[0]
	var nextPoint = get_curve_point(bt)
	
	var ba
	var bc
	var dot
	var ang
	var tr
	for idx in range(1, boundary.size()):
		trans.origin.x = prevPoint.x
		trans.origin.z = prevPoint.z
		trans = trans.looking_at(currentPoint, Vector3(0, 1, 0))
		
		var nPoint = nextPoint[0]
		if nextPoint.size() > 1:
			nPoint = nextPoint[1]
		ba = (prevPoint - currentPoint).normalized()
		bc = (nPoint - currentPoint).normalized()
		
		trans.origin.x = 0
		trans.origin.z = 0
		dot = bc.dot(trans.xform(Vector3(1, 0, 0)))
		ang = (PI - ba.angle_to(bc)) * 0.5
		if dot > 0:
			ang = -ang
		tr = trans.rotated(Vector3(0, 1, 0), ang)
		var h = handle * (currentPoint.distance_to(nPoint) / CD.TILE_WIDTH)
		curve.add_point(currentPoint, tr.xform(h), tr.xform(-h))
		
		if nextPoint.size() > 1:
			var intPoint = nextPoint[1]
			trans.origin.x = currentPoint.x
			trans.origin.z = currentPoint.z
			trans = trans.looking_at(intPoint, Vector3(0, 1, 0))
			
			ba = (currentPoint - intPoint).normalized()
			bc = (nextPoint[0] - intPoint).normalized()
			
			trans.origin.x = 0
			trans.origin.z = 0
			dot = bc.dot(trans.xform(Vector3(1, 0, 0)))
			ang = (PI - ba.angle_to(bc)) * 0.5
			if dot > 0:
				ang = -ang
			tr = trans.rotated(Vector3(0, 1, 0), ang)
			curve.add_point(intPoint, tr.xform(handle), tr.xform(-handle))
			currentPoint = intPoint
		
		bt = boundary[idx]
		prevPoint = currentPoint
		currentPoint = nextPoint[0]
		nextPoint = get_curve_point(bt)
	
	trans.origin.x = prevPoint.x
	trans.origin.z = prevPoint.z
	trans = trans.looking_at(currentPoint, Vector3(0, 1, 0))
	
	var nPoint = nextPoint[0]
	if nextPoint.size() > 1:
		nPoint = nextPoint[1]
	ba = (prevPoint - currentPoint).normalized()
	bc = (nPoint - currentPoint).normalized()
	
	trans.origin.x = 0
	trans.origin.z = 0
	dot = bc.dot(trans.xform(Vector3(1, 0, 0)))
	ang = (PI - ba.angle_to(bc)) * 0.5
	if dot > 0:
		ang = -ang
	tr = trans.rotated(Vector3(0, 1, 0), ang)
	var h = handle * (currentPoint.distance_to(nPoint) / CD.TILE_WIDTH)
	curve.add_point(currentPoint, tr.xform(h), tr.xform(-h))
	
	if nextPoint.size() > 1:
		var intPoint = nextPoint[1]
		trans.origin.x = currentPoint.x
		trans.origin.z = currentPoint.z
		trans = trans.looking_at(intPoint, Vector3(0, 1, 0))
		
		ba = (currentPoint - intPoint).normalized()
		bc = (nextPoint[0] - intPoint).normalized()
		
		trans.origin.x = 0
		trans.origin.z = 0
		dot = bc.dot(trans.xform(Vector3(1, 0, 0)))
		ang = (PI - ba.angle_to(bc)) * 0.5
		if dot > 0:
			ang = -ang
		tr = trans.rotated(Vector3(0, 1, 0), ang)
		curve.add_point(intPoint, tr.xform(handle), tr.xform(-handle))
		currentPoint = intPoint
	
	bt = boundary[0]
	prevPoint = currentPoint
	currentPoint = nextPoint[0]
	nextPoint = get_curve_point(bt)
	
	trans.origin.x = prevPoint.x
	trans.origin.z = prevPoint.z
	trans = trans.looking_at(currentPoint, Vector3(0, 1, 0))
	
	if nextPoint.size() > 1:
		nPoint = nextPoint[1]
	else:
		nPoint = nextPoint[0]
	ba = (prevPoint - currentPoint).normalized()
	bc = (nPoint - currentPoint).normalized()
	
	trans.origin.x = 0
	trans.origin.z = 0
	dot = bc.dot(trans.xform(Vector3(1, 0, 0)))
	ang = (PI - ba.angle_to(bc)) * 0.5
	if dot > 0:
		ang = -ang
	tr = trans.rotated(Vector3(0, 1, 0), ang)
	h = handle * (currentPoint.distance_to(nPoint) / CD.TILE_WIDTH)
	curve.add_point(currentPoint, tr.xform(h), tr.xform(-h))
	
	return curve


func get_curve_point(bt):
	var points = []
	if bt.next.worldLoc.x > bt.origin.worldLoc.x:
		if bt.next.worldLoc.y > bt.origin.worldLoc.y:
			points.push_back(bt.origin.get_right())
		else:
			points.push_back(bt.origin.get_top_right())
		if bt.next == bt.previous:
			points.push_back(bt.origin.get_left())
	elif bt.next.worldLoc.x < bt.origin.worldLoc.x:
		if bt.next.worldLoc.y > bt.origin.worldLoc.y:
			points.push_back(bt.origin.get_bottom_left())
		else:
			points.push_back(bt.origin.get_left())
		if bt.next == bt.previous:
			points.push_back(bt.origin.get_right())
	else:
		if bt.next.worldLoc.y > bt.origin.worldLoc.y:
			points.push_back(bt.origin.get_bottom_right())
			if bt.next == bt.previous:
				points.push_back(bt.origin.get_top())
		else:
			points.push_back(bt.origin.get_top_left())
			if bt.next == bt.previous:
				points.push_back(bt.origin.get_bottom())
	
	return points


class BoundaryTile:
	var previous
	var origin
	var next
	
	func _init(tile):
		origin = tile
