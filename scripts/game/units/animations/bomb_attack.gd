extends "res://scripts/game/units/animations/attack.gd"

var EXP = preload("res://fx/attacks/Gaumond/GravityBomb.tscn").instance()
var blast := false
var fin := false

func _init(attackUnit, defendUnit, faceVector,
		numberOfShots,
		isCounterAttack = false, damageReceived := 0).(attackUnit,
				defendUnit, faceVector, numberOfShots,
				Spatial.new(), isCounterAttack, damageReceived):
	phyUpdate = false


func update(delta):
	if !.update(delta):
		return false
	
	if !blast:
		blast = true
		if defender.type == CD.UNIT_COMMAND_STATION:
			EXP.transform.origin = defender.transform.xform(Vector3(0, 0, -4))
		else:
			EXP.transform.origin = defender.transform.origin
		EXP.anim = self
		EXP.setMask = attacker.player.num != attacker.player.game.thisPlayer
		effectsParent.add_child(EXP)
		
		if (Opts.vol_sfx - 0.0 > 0.0001 && (Math.is_near_visible(attacker.tile, attacker.player.game.thisPlayer)
				|| Math.is_near_visible(defender.tile, defender.player.game.thisPlayer))):
			var sfx = preload("res://audio/SFX/SwooshBlast.tscn").instance()
			sfx.transform.origin = EXP.transform.origin
			effectsParent.add_child(sfx)
		
		return false
	
	if fin:
		return finish()
	
	return false
