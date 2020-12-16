extends "res://scripts/game/units/animations/destroy_unit.gd"

const FLAME_TRAIL = preload("res://fx/FlameTrail/FlameTrail.tscn")

var num_trails = 5


func _init(unit, fx, clearAnimOn = null, soundFX = load("res://audio/SFX/ExplosionBig.tscn")).(unit, fx, clearAnimOn, soundFX):
	if Opts.particleDetail == Opts.QUALITY_LOW:
		num_trails = 0
	elif Opts.particleDetail == Opts.QUALITY_MED:
		num_trails = 2
	elif unit.type == CD.UNIT_THANANOS:
		num_trails = 3
	elif unit.type == CD.UNIT_COMMAND_STATION:
		num_trails = 5
	else:
		num_trails = (randi() % 3) + 3


func update(delta):
	.update(delta)
	
	for t in range(num_trails):
		setup_trail(t)
	
	return true


func setup_trail(index):
	var radRange = (PI * 2.0) / num_trails
	var radSect = index * radRange
	var rot = rand_range(radSect, (radRange * 0.82) + radSect)
	var quat = Quat(Vector3(0, 1, 0), rot)
	var trail = FLAME_TRAIL.instance()
	trail.set_rotation(Vector3(0, rot, 0))
	trail.transform.origin = fx.transform.origin + quat.xform(Vector3(0, 0, 3.4))
	var numParticles = (randi() % 8) + 12
	
	var fc
	if !unit.player.is_local_player():
		fc = unit.player.arena.get_node("FogControl")
	trail.init(numParticles, rand_range(0.2, 0.3),
			10.2 + (((numParticles - 12) / 7.0) * 0.85), 0.2, 1.0,
			6.34, 8.0, 1.7, 3.0, deg2rad(-16), deg2rad(16), 0.2, fc)
	
	fx.get_parent().add_child(trail)
