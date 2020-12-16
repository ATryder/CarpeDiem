extends "res://scripts/game/units/animations/attack.gd"

const FLAME_TRAIL = preload("res://fx/FlameTrail/FlameTrail.tscn")
const EXP = preload("res://fx/attacks/Aurora/Explosion.tscn")
const RECOILSPEED = 1.3

var skeleton

var barrel1
var barrel2
var root1
var root2

var rootBone
var bone1
var bone2
var rootTrans
var trans1
var trans2

var rotSpeed1 = 1.5
var rotSpeed2 = 1.5
var rotPerc1 = 0.0
var rotPerc2 = 0.0

var gunRot = true
var muzzleFlash1
var muzzleFlash2
var flashFin = false

var recoilRot = false
var recoilReturn = false
var recoilAmount = deg2rad(-10)
var recoilPerc = 0.0

func _init(attackUnit, defendUnit, faceVector,
		numberOfShots, weaponSpawnInstance,
		isCounterAttack = false, damageReceived := 0).(attackUnit,
				defendUnit, faceVector, numberOfShots,
				weaponSpawnInstance, isCounterAttack, damageReceived):
	skeleton = attacker.geom.get_node(attacker.geom.skeleton)
	
	root1 = shotSpawn.get_child(0)
	root2 = shotSpawn.get_child(1)
	barrel1 = root1.get_child(0)
	barrel2 = root2.get_child(0)
	
	rootBone = skeleton.find_bone("Root")
	bone1 = skeleton.find_bone("Front_Gun")
	bone2 = skeleton.find_bone("Rear_Gun")
	rootTrans = skeleton.get_bone_pose(rootBone)
	trans1 = skeleton.get_bone_pose(bone1)
	trans2 = skeleton.get_bone_pose(bone2)
	
	muzzleFlash1 = FLAME_TRAIL.instance()
	muzzleFlash1.removeOnFinish = false
	muzzleFlash2 = FLAME_TRAIL.instance()
	muzzleFlash2.removeOnFinish = false
	root1.get_child(0).add_child(muzzleFlash1)
	root2.get_child(0).add_child(muzzleFlash2)

func phy_update(delta):
	.phy_update(delta)
	
	var shotLoc = Vector3(shotInfo[0].dest.x, shotInfo[0].dest.y, shotInfo[0].dest.z)
	var shotLoc2 = Vector3(shotInfo[1].dest.x, shotInfo[1].dest.y, shotInfo[1].dest.z)
	if abs(shotLoc.z - root1.global_transform.origin.z) >= abs(shotLoc2.z - root1.global_transform.origin.z):
		shotLoc.y = root1.global_transform.origin.y
		root1.look_at(shotLoc, Vector3(0, 1, 0))
		root1.rotate_y(PI)
	
		shotLoc2.y = root2.global_transform.origin.y
		root2.look_at(shotLoc2, Vector3(0, 1, 0))
		root2.rotate_y(PI)
	else:
		shotLoc.y = root2.global_transform.origin.y
		root2.look_at(shotLoc, Vector3(0, 1, 0))
		root2.rotate_y(PI)
	
		shotLoc2.y = root1.global_transform.origin.y
		root1.look_at(shotLoc2, Vector3(0, 1, 0))
		root1.rotate_y(PI)
	
	rotSpeed1 *= PI / abs(root1.get_rotation().y)
	rotSpeed2 *= PI / abs(root2.get_rotation().y)
	
	return true

func update(delta):
	if !.update(delta):
		return false
	
	if shotInfo == null:
		return false
	
	if gunRot:
		rotPerc1 += delta * rotSpeed1
		rotPerc2 += delta * rotSpeed2
		if rotPerc1 >= 1 and rotPerc2 >= 1:
			var fc
			if attacker.player.num != attacker.player.game.thisPlayer:
				fc = attacker.player.arena.get_node("FogControl")
			rotPerc1 = 1
			rotPerc2 = 1
			muzzleFlash1.init(22, 0.1, 6.0, 0.2, 1.0, 5, 6.8, 0.86, 3.3, deg2rad(-16), deg2rad(16), 0.3, fc)
			muzzleFlash2.init(22, 0.1, 6.0, 0.2, 1.0, 5, 6.8, 0.86, 3.3, deg2rad(-16), deg2rad(16), 0.3, fc)
			recoilRot = true
			gunRot = false
			var blast = EXP.instance()
			blast.transform.origin = shotInfo[0].dest + Vector3(0, 1, 0)
			blast.setMask = attacker.player.num != attacker.player.game.thisPlayer
			effectsParent.add_child(blast)
			blast = EXP.instance()
			blast.transform.origin = shotInfo[1].dest + Vector3(0, 1, 0)
			blast.setMask = attacker.player.num != attacker.player.game.thisPlayer
			effectsParent.add_child(blast)
			
			if (Opts.vol_sfx - 0.0 > 0.0001
					&& (Math.is_near_visible(attacker.tile, attacker.player.game.thisPlayer)
					|| Math.is_near_visible(defender.tile, defender.player.game.thisPlayer))):
				var sfx = preload("res://audio/SFX/ExplosionSmall.tscn").instance()
				sfx.transform.origin = defender.transform.origin
				effectsParent.add_child(sfx)
				
				sfx = preload("res://audio/SFX/CannonExplosion.tscn").instance()
				sfx.transform.origin = attacker.transform.origin
				effectsParent.add_child(sfx)
		else:
			if rotPerc1 > 1:
				rotPerc1 = 1
			if rotPerc2 > 1:
				rotPerc2 = 1
		
		var rot = Math.fsmooth(0, root1.get_rotation().y, rotPerc1)
		var t = trans1.rotated(Vector3(0, 1, 0), rot)
		t.origin = trans1.origin
		skeleton.set_bone_pose(bone1, t)
		
		rot = Math.fsmooth(0, root2.get_rotation().y, rotPerc2)
		t = trans2.rotated(Vector3(0, 1, 0), rot)
		t.origin = trans2.origin
		skeleton.set_bone_pose(bone2, t)
		return false
	
	if recoilRot:
		recoilPerc += delta * RECOILSPEED
		if recoilPerc >= 1:
			recoilPerc -= recoilPerc - floor(recoilPerc)
			recoilPerc += delta * (RECOILSPEED * 0.6)
			recoilReturn = true
			recoilRot = false
		else:
			var t = rootTrans.rotated(Vector3(0, 0, 1), Math.fsmooth_stop(0, recoilAmount, recoilPerc))
			skeleton.set_bone_pose(rootBone, t)
	if recoilReturn:
		recoilPerc -= delta * (RECOILSPEED * 0.6)
		if recoilPerc <= 0:
			recoilPerc = 0
			recoilReturn = false
			skeleton.set_bone_pose(rootBone, rootTrans)
		else:
			var t = rootTrans.rotated(Vector3(0, 0, 1), Math.fsmooth(0, recoilAmount, recoilPerc))
			skeleton.set_bone_pose(rootBone, t)
	
	if !flashFin:
		if !muzzleFlash1.fin or !muzzleFlash2.fin:
			return false
		else:
			flashFin = true
			muzzleFlash1.queue_free()
			muzzleFlash2.queue_free()
	
	rotPerc1 -= delta * rotSpeed1
	rotPerc2 -= delta * rotSpeed2
	if rotPerc1 <= 0 and rotPerc2 <= 0 and !recoilReturn:
		rotPerc1 = 0
		rotPerc2 = 0
		skeleton.set_bone_pose(rootBone, rootTrans)
		skeleton.set_bone_pose(bone1, trans1)
		skeleton.set_bone_pose(bone2, trans2)
		return finish()
	else:
		if rotPerc1 < 0:
			rotPerc1 = 0
		if rotPerc2 < 0:
			rotPerc2 = 0
	
	var rot = Math.fsmooth(0, root1.get_rotation().y, rotPerc1)
	var t = trans1.rotated(Vector3(0, 1, 0), rot)
	t.origin = trans1.origin
	skeleton.set_bone_pose(bone1, t)
	
	rot = Math.fsmooth(0, root2.get_rotation().y, rotPerc2)
	t = trans2.rotated(Vector3(0, 1, 0), rot)
	t.origin = trans2.origin
	skeleton.set_bone_pose(bone2, t)
	return false
