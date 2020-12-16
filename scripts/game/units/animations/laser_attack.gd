extends "res://scripts/game/units/animations/attack.gd"

const SPARKS = preload("res://fx/Sparks.tscn")


func _init(attackUnit, defendUnit, faceVector,
		numberOfShots, weaponSpawnInstance,
		isCounterAttack = false, damageReceived := 0).(attackUnit,
				defendUnit, faceVector, numberOfShots,
				weaponSpawnInstance, isCounterAttack, damageReceived):
	pass


func phy_update(delta):
	.phy_update(delta)
	
	shots = []
	var spawnAudio = (Opts.vol_sfx - 0.0 > 0.0001
					&& (Math.is_near_visible(attacker.tile, attacker.player.game.thisPlayer)
					|| Math.is_near_visible(defender.tile, defender.player.game.thisPlayer)))
	for si in shotInfo:
		shots.push_back(Beam.new(si, 0.09 * shots.size(),
				effectsParent,
				attacker.player.num != attacker.player.game.thisPlayer,
				fc, spawnAudio))
	shotInfo = null
	
	return true


func update(delta):
	if !.update(delta):
		return false
	
	if shots == null:
		return false
	
	var toRem = []
	for beam in shots:
		if beam.update(delta):
			toRem.push_back(beam)
	for beam in toRem:
		shots.erase(beam)
	
	if shots.empty():
		return finish()
	
	return false


class Beam:
	const LASER_BEAM = preload("res://fx/attacks/LaserBeam.tscn")
	const SPEED = 32.0
	
	var effectsParent
	
	var beam
	var origin
	var dest
	var norm
	
	var tripLength
	var eta
	
	var delay
	var started := false
	
	var setMask
	
	var spawnAudio : bool
	
	
	func _init(shotInfo, delayTime, effectsParent,
			setMask, fc, spawnAudio):
		self.spawnAudio = spawnAudio
		origin = shotInfo.origin
		dest = shotInfo.dest
		norm = shotInfo.norm
		eta = origin.distance_to(dest) / SPEED
		tripLength = eta
		eta -= 0.67 / SPEED
		delay = delayTime
		self.effectsParent = effectsParent
		
		beam = LASER_BEAM.instance()
		self.setMask = setMask
		if setMask:
			var beamMat = beam.get_surface_material(0).duplicate()
			beamMat.set_shader_param("mask_tex", fc.get_mask())
			beamMat.set_shader_param("mask_offset", fc.get_mask_offset())
			beamMat.set_shader_param("mask_scale", fc.get_mask_world_scale())
			beam.set_surface_material(0, beamMat)
			beam.get_child(0).set_surface_material(0, beamMat)
		beam.transform.origin = origin
		effectsParent.add_child(beam)
		beam.look_at(dest, Vector3(0, 1, 0))
		beam.hide()
	
	
	func update(delta):
		delay -= delta
		if !started && delay <= 0:
			beam.show()
			started = true
			if spawnAudio:
				var sfx = preload("res://audio/SFX/Laser.tscn").instance()
				sfx.transform.origin = origin
				effectsParent.add_child(sfx)
		elif !started:
			return false
		
		eta = eta - delta
		beam.transform.origin = origin.linear_interpolate(dest, 1.0 - (max(eta, 0.0) / tripLength))
		if eta <= 0.0:
			beam.queue_free()
			var sparkDir = (dest - origin).normalized().reflect(norm).normalized()
			var sparks = SPARKS.instance()
			sparks.setMask = setMask
			sparks.transform.origin = dest
			effectsParent.add_child(sparks)
			sparks.look_at(sparkDir + dest, Vector3(0, 1, 0))
			sparks.rotate_y(PI)
			return true
