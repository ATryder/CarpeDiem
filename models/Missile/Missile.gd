extends Spatial

const SPEED = 64

export(PackedScene) var explosionEffects

var unit
var curve
var length
var spawnAudio := true

var offset = 0.0


func _ready():
	if unit != null and unit.type == CD.UNIT_COMMAND_STATION:
		scale_object_local(Vector3(0.57, 0.57, 0.57))
	var pos = curve.interpolate_baked(SPEED * 0.02, true)
	look_at(transform.origin - (pos - transform.origin), Vector3(0, 1, 0))
	transform.origin = pos


func _process(delta):
	offset += SPEED * delta
	
	if offset >= length:
		var boom = explosionEffects.instance()
		boom.transform.origin = curve.get_point_position(curve.get_point_count() - 1)
		boom.setMask = unit == null or unit.player.num != unit.player.game.thisPlayer
		get_parent().add_child(boom)
		
		if spawnAudio:
			var sfx = preload("res://audio/SFX/ExplosionSmall.tscn").instance()
			sfx.transform.origin = boom.transform.origin
			get_parent().add_child(sfx)
		
		queue_free()
		if unit != null:
			unit.animation.shotsHit += 1
	
	var pos = curve.interpolate_baked(offset, true)
	look_at(transform.origin - (pos - transform.origin), Vector3(0, 1, 0))
	transform.origin = pos


func calc_curve(shotInfo, shotSpawn):
	curve = Curve3D.new()
	curve.bake_interval = 2.0
	
	var control = Vector3(0, 0,
			shotInfo.origin.distance_to(shotInfo.dest) * 0.62)
	var trans = Transform(Basis(Vector3(1, 0, 0),
						Vector3(0, 1, 0),
						Vector3(0, 0, 1)))
	var outCont = shotSpawn.global_transform.xform(control)
	outCont += shotInfo.origin - shotSpawn.global_transform.origin
	control.z = -control.z
	trans.origin = shotInfo.dest
	trans = trans.looking_at(outCont, Vector3(0, 1, 0))
	trans.origin = Vector3(0, 0, 0)
	var inCont = trans.xform(control)
	outCont -= shotInfo.origin
	
	curve.add_point(shotInfo.origin,
			-outCont, outCont)
	curve.add_point(shotInfo.dest,
			inCont, -inCont)
	
	length = curve.get_baked_length()
	
	transform.origin = shotInfo.origin


func set_mask(fogControl):
	var mat = get_node("Missile").get_surface_material(0)
	mat.set_shader_param("mask_tex", fogControl.get_mask())
	mat.set_shader_param("mask_offset", fogControl.get_mask_offset())
	mat.set_shader_param("mask_scale", fogControl.get_mask_world_scale())
	mat.set_shader_param("fog", fogControl.fogMapped)
	
	mat = get_node("Particles").material_override
	mat.set_shader_param("mask_tex", fogControl.get_mask())
	mat.set_shader_param("mask_offset", fogControl.get_mask_offset())
	mat.set_shader_param("mask_scale", fogControl.get_mask_world_scale())
