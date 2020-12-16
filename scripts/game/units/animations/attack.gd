extends Reference

const PLACEHOLDER = preload("res://scripts/game/units/animations/null_attack.gd")

var fc

var ROTSPEED = 1.5

var initRot = true
var startAngle = Vector3()
var endAngle = Vector3()
var rotPerc = 0.0

var attacker
var defender

var numShots
var shots
var shotInfo
var shotSpawn

var isCounterAttack : bool
var damageReceived : int

var phyUpdate = true
var randomSpawn = false

var effectsParent


func _init(attackUnit, defendUnit, faceVector,
		numberOfShots, weaponSpawnInstance,
		isCounterAttack = false, damageReceived := 0):
	attacker = attackUnit
	defender = defendUnit
	defender.animation = PLACEHOLDER.new()
	
	if !attacker.player.is_local_player() && !isCounterAttack:
		attacker.player.game.get_node("CameraControl").zoom_to_attack(attacker, defender)
	
	shotSpawn = weaponSpawnInstance
	numShots = numberOfShots
	self.isCounterAttack = isCounterAttack
	self.damageReceived = damageReceived
	if isCounterAttack:
		randomSpawn = attacker.randomCounterAttackWeaponSpawn
	else:
		randomSpawn = attacker.randomWeaponSpawn
	effectsParent = attacker.player.game.get_node("Effects")
	
	if attacker.type == CD.UNIT_COMMAND_STATION:
		initRot = false
		shotSpawn.set_rotation(attacker.get_rotation() + shotSpawn.get_rotation())
		shotSpawn.transform.origin = attacker.transform.origin
		effectsParent.add_child(shotSpawn)
	else:
		var toVec = (defender.transform.origin - attacker.transform.origin).normalized()
		var fromVec = (attacker.transform.xform(faceVector) - attacker.transform.origin).normalized()
		var angle = fromVec.angle_to(toVec)
		if angle < 0.03490705995287546906361811676412:
			startAngle = Vector3(0, attacker.get_rotation().y, 0)
			endAngle = startAngle
			initRot = false
		else:
			ROTSPEED *= PI / angle
			startAngle = Vector3(0, attacker.get_rotation().y, 0)
			var dot
			if faceVector.z > 0:
				dot = (attacker.transform.xform(Vector3(1, 0, 0)) - attacker.transform.origin).normalized().dot(toVec)
			else:
				dot = (attacker.transform.xform(Vector3(0, 0, -1)) - attacker.transform.origin).normalized().dot(toVec)
			if dot >= 0:
				endAngle = startAngle + Vector3(0, angle, 0) 
			else:
				endAngle = startAngle - Vector3(0, angle, 0)
		
		shotSpawn.set_rotation(endAngle + shotSpawn.get_rotation())
		shotSpawn.transform.origin = attacker.transform.origin
		effectsParent.add_child(shotSpawn)
	
	fc = attacker.player.game.get_node("Arena/FogControl")


func phy_update(delta):
	var pob = StaticBody.new()
	pob.input_ray_pickable = false
	var shape = defender.geom.mesh.create_trimesh_shape()
	var ownerIdx = pob.create_shape_owner(defender)
	pob.shape_owner_add_shape(ownerIdx, shape)
	pob.collision_layer = 0
	pob.collision_mask = 0
	pob.set_collision_layer_bit(18, true)
	defender.add_child(pob)
	
	var space_state = defender.get_world().direct_space_state
	var spawnIdx = 0
	if randomSpawn:
		spawnIdx = randi() % shotSpawn.get_child_count()
	shotInfo = []
	var i = 0
	while i < numShots:
		var origin = shotSpawn.global_transform.xform(shotSpawn.get_child(spawnIdx).transform.origin)
		var dest = Math.get_random_point_on_mesh(defender.geom.mesh)
		dest = defender.global_transform.xform(dest)
		var result = space_state.intersect_ray(origin, dest + (dest - origin), [], pob.collision_layer)
		if result.empty():
			continue
		
		dest = result.position
		var norm = result.normal
		result = space_state.intersect_ray(dest + Vector3(0, 50, 0), dest - Vector3(0, 50, 0), [], pob.collision_layer)
		if !result.empty():
			dest = result.position
			norm = result.normal
		shotInfo.push_back(Shot.new(origin, dest, norm))
		
		if randomSpawn:
			spawnIdx = randi() % shotSpawn.get_child_count()
		elif spawnIdx == shotSpawn.get_child_count() - 1:
			spawnIdx = 0
		else:
			spawnIdx += 1
		i += 1
	
	pob.shape_owner_clear_shapes(ownerIdx)
	pob.queue_free()
	
	return true


func update(delta):
	if initRot:
		rotPerc += delta * ROTSPEED
		if rotPerc >= 1:
			initRot = false
			rotPerc = 1
		attacker.set_rotation(Vector3(0, Math.fsmooth(startAngle.y, endAngle.y, rotPerc), 0))
		return false
	else:
		return true


func finish():
	shotSpawn.queue_free()
	if !isCounterAttack:
		defender.animation.fin = true
		var damage = Math.calc_attack_amount(attacker, defender)
		if damage < defender.strength:
			if attacker.type != CD.UNIT_COMMAND_STATION && defender.counter_attack(attacker.tile, damage):
				attacker.animation = PLACEHOLDER.new()
				return false
			
			attacker.attacks = 0
			defender.damage_unit(damage)
			if !attacker.player.is_local_player():
				attacker.player.exec_next_task()
			return true
		else:
			attacker.attacks = 0
			attacker.animation = PLACEHOLDER.new()
			defender.damage_unit(damage, attacker.animation)
			return true
	
	defender.attacks = 0
	if attacker.damage_unit(damageReceived, defender.animation):
		defender.animation.fin = true
	if !defender.player.is_local_player():
		if defender.damage_unit(Math.calc_counter_attack_amount(attacker, defender)):
			defender.player.exec_next_task()
	else:
		defender.damage_unit(Math.calc_counter_attack_amount(attacker, defender))
	return true


class Shot:
	var origin
	var dest
	var norm
	
	func _init(origin, destination, normal):
		self.origin = origin
		dest = destination
		norm = normal
