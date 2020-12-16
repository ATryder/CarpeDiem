extends "res://scripts/game/units/animations/attack.gd"

const SHOT_DELAY = 0.3
const XROT_SPEED = 3.46

var MISSILE

var shotsHit = 0
var shotsFired = 0
var nextShot = 0.0

var xRot = true
var xRotPerc = 0.0

func _init(attackUnit, defendUnit, faceVector,
		numberOfShots, weaponSpawnInstance,
		isCounterAttack = false, damageReceived := 0).(attackUnit,
				defendUnit, faceVector, numberOfShots,
				weaponSpawnInstance, isCounterAttack, damageReceived):
	if CD.quality_mobile():
		MISSILE = preload("res://models/Missile/Missile_Mobile.tscn")
	else:
		MISSILE = preload("res://models/Missile/Missile.tscn")

func update(delta):
	if !.update(delta):
		if xRot and attacker.type == CD.UNIT_THANANOS:
			xRotPerc += delta * XROT_SPEED
			if xRotPerc >= 1:
				xRot = false
				xRotPerc = 1
			attacker.get_child(0).set_rotation(Vector3(Math.fsmooth(0, shotSpawn.get_rotation().x, xRotPerc), 0, 0))
		return false
	
	if xRot and attacker.type == CD.UNIT_THANANOS:
		xRotPerc += delta * XROT_SPEED
		if xRotPerc >= 1:
			xRot = false
			xRotPerc = 1
		attacker.geom.set_rotation(Vector3(Math.fsmooth(0, shotSpawn.get_rotation().x, xRotPerc), 0, 0))
		return false
	
	if shotInfo == null:
		return false
	
	if shotsHit == numShots:
		xRotPerc -= delta * XROT_SPEED
		if xRotPerc <= 0:
			xRotPerc = 0
			attacker.get_child(0).set_rotation(Vector3(0, 0, 0))
			return finish()
		attacker.get_child(0).set_rotation(Vector3(Math.fsmooth(0, shotSpawn.get_rotation().x, xRotPerc), 0, 0))
		return false
	
	if shotsFired == numShots:
		return false
	
	nextShot -= delta
	if nextShot > 0:
		return false
	
	nextShot = SHOT_DELAY
	var msl = MISSILE.instance()
	msl.unit = attacker
	msl.calc_curve(shotInfo[shotsFired], shotSpawn)
	if attacker.player.num != attacker.player.game.thisPlayer:
		msl.set_mask(fc)
	effectsParent.add_child(msl)
	
	if (Opts.vol_sfx - 0.0 > 0.0001
			&& (Math.is_near_visible(attacker.tile, attacker.player.game.thisPlayer)
			|| Math.is_near_visible(defender.tile, defender.player.game.thisPlayer))):
		msl.spawnAudio = true
		var sfx = preload("res://audio/SFX/MissileLaunch.tscn").instance()
		sfx.transform.origin = shotInfo[shotsFired].origin
		effectsParent.add_child(sfx)
	else:
		msl.spawnAudio = false
	
	shotsFired += 1
	
	return false
