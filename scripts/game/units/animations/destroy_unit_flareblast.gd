extends "res://scripts/game/units/animations/destroy_unit_bigblast.gd"

const FLARE = preload("res://fx/unit_expolsion/Exp_Flare.tscn")

var finished = false
var flareSpawned = false
var flareSFX = preload("res://audio/SFX/ElectricalDamage.tscn").instance()


func _init(unit, fx, clearAnimOn = null).(unit, fx, clearAnimOn, preload("res://audio/SFX/MidFarExplosion.tscn")):
	fxOffset = Vector3(0, 0, -4)


func update(delta):
	if !flareSpawned:
		flareSpawned = true
		if (unit.player.num == unit.player.game.thisPlayer
				|| unit.tile.is_visible(unit.player.game.thisPlayer)):
			var flare = FLARE.instance()
			flare.animation = self
			flare.camcont = unit.player.game.get_node("CameraControl")
			flare.worldLoc = unit.global_transform.xform(fxOffset)
			unit.player.game.get_node("Flares").add_child(flare)
			
			flareSFX.transform.origin = flare.worldLoc
			unit.player.game.get_node("Effects").add_child(flareSFX)
		else:
			spawn_exp()
	
	return finished


func spawn_exp():
	flareSFX.fade_out(1.0)
	.update(1)
	unit.queue_free()
	finished = true
