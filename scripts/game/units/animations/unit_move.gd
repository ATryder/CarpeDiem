var ROTSPEED = 1.5
const SPEED = 57.0

var unit
var curve
var path

var length
var offset = 0.0

var initRot = true
var startAngle = Vector3()
var endAngle = Vector3()
var rotPerc = 0.0

var engineFX
var sfx

var waitFrame = true

func _init(unit, path, curve):
	self.unit = unit
	self.path = path
	self.curve = curve
	if curve.bake_interval != 2:
		curve.bake_interval = 2.0
	length = curve.get_baked_length()
	
	engineFX = unit.engineFX.instance()
	
	var toVec = (curve.get_point_position(1) - unit.transform.origin).normalized()
	var fromVec = (unit.transform.xform(Vector3(0, 0, 1)) - unit.transform.origin).normalized()
	var angle = fromVec.angle_to(toVec)
	if angle < 0.03490705995287546906361811676412:
		initRot = false
		unit.add_child(engineFX)
		if (unit.player.is_local_player()
				|| Math.is_near_visible(path[0], unit.player.game.thisPlayer)
				|| Math.is_near_visible(path[path.size() - 1], unit.player.game.thisPlayer)):
			sfx = preload("res://audio/SFX/UnitEngine.tscn").instance()
			unit.add_child(sfx)
			sfx.fade_in(0.3)
	else:
		ROTSPEED *= PI / angle
	startAngle = Vector3(0, unit.get_rotation().y, 0)
	if (unit.transform.xform(Vector3(1, 0, 0)) - unit.transform.origin).normalized().dot(toVec) >= 0:
		endAngle = startAngle + Vector3(0, angle, 0)
	else:
		endAngle = startAngle - Vector3(0, angle, 0)

func update(delta):
	if initRot:
		rotPerc += delta * ROTSPEED
		if rotPerc >= 1:
			initRot = false
			rotPerc = 1
			unit.add_child(engineFX)
			if (unit.player.is_local_player()
					|| Math.is_near_visible(path[0], unit.player.game.thisPlayer)
					|| Math.is_near_visible(path[path.size() - 1], unit.player.game.thisPlayer)):
				sfx = preload("res://audio/SFX/UnitEngine.tscn").instance()
				unit.add_child(sfx)
				sfx.fade_in(0.3)
		unit.set_rotation(Vector3(0, Math.fsmooth(startAngle.y, endAngle.y, rotPerc), 0))
		return false
	
	if waitFrame:
		waitFrame = false
		return false
	
	offset += SPEED * delta
	if offset >= length:
		var toPos = Vector3(path[path.size() - 1].worldLoc.x, 0, path[path.size() - 1].worldLoc.y)
		unit.transform.origin = toPos
		unit.end_move(path[0], path[path.size() - 1])
		engineFX.finish()
		if sfx != null:
			sfx.fade_out(0.35)
		if !unit.player.is_local_player():
			unit.qInfo.set_visible(unit.tile.is_visible(unit.player.game.thisPlayer))
		return false
	
	var toPos = curve.interpolate_baked(offset, true)
	var rotation = Vector3(unit.rotation.x, unit.rotation.y, unit.rotation.z)
	unit.look_at(toPos, Vector3(0, 1, 0))
	if unit.rotation != rotation:
		unit.rotate_y(PI)
	unit.transform.origin = toPos
	
	if !unit.player.is_local_player():
		unit.qInfo.set_visible(unit.player.arena.world_to_tile(toPos).is_visible(unit.player.game.thisPlayer))
	
	return false
