extends CPUParticles

var implodeLength := 0.15
var explode := false

var tme := 0.0

var setMask = true

onready var debris = get_node("Debris")
onready var s1 = get_node("MeshInstance")
onready var s2 = get_node("MeshInstance2")

var sCols := []

var anim

onready var length = debris.lifetime * 1.773427

func _ready():
	implodeLength = lifetime
	emitting = true
	
	s1.material_override = s1.material_override.duplicate()
	s2.material_override = s2.material_override.duplicate()
	s1.rotate_y(deg2rad(rand_range(20, 90)))
	s2.rotate_y(deg2rad(rand_range(20, 90)))
	
	sCols.push_back(s1.material_override.get_shader_param("col1"))
	sCols.push_back(s1.material_override.get_shader_param("col2"))
	sCols.push_back(s1.material_override.get_shader_param("col3"))
	sCols.push_back(s2.material_override.get_shader_param("col1"))
	sCols.push_back(s2.material_override.get_shader_param("col2"))
	sCols.push_back(s2.material_override.get_shader_param("col3"))
	
	if setMask:
		var fc = get_node("/root/Game/Arena/FogControl")
		material_override.set_shader_param("mask_tex", fc.get_mask())
		material_override.set_shader_param("mask_offset", fc.get_mask_offset())
		material_override.set_shader_param("mask_scale", fc.get_mask_world_scale())
		
		debris.material_override.set_shader_param("mask_tex", fc.get_mask())
		debris.material_override.set_shader_param("mask_offset", fc.get_mask_offset())
		debris.material_override.set_shader_param("mask_scale", fc.get_mask_world_scale())
		
		s1.material_override.set_shader_param("mask_tex", fc.get_mask())
		s1.material_override.set_shader_param("mask_offset", fc.get_mask_offset())
		s1.material_override.set_shader_param("mask_scale", fc.get_mask_world_scale())
		
		s2.material_override.set_shader_param("mask_tex", fc.get_mask())
		s2.material_override.set_shader_param("mask_offset", fc.get_mask_offset())
		s2.material_override.set_shader_param("mask_scale", fc.get_mask_world_scale())


func _process(delta):
	tme += delta
	
	if !explode:
		if tme >= implodeLength:
			explode = true
			tme = 0.0
			debris.emitting = true
			s1.show()
			s2.show()
		return
	
	s1.rotate_y(deg2rad(180.0) * -delta)
	s2.rotate_y(deg2rad(180.0) * delta)
	s1.scale = Math.fsmooth_stop(Vector3(1, 1, 1), Vector3(8, 8, 8), min(tme / length, 1.0))
	s2.scale = Math.fsmooth_stop(Vector3(1, 1, 1), Vector3(8, 8, 8), min(tme / length, 1.0))
	
	var idx := 1
	for col in sCols:
		col.a = Math.fsmooth_start(1.0, 0.0, min(tme / length, 1.0))
		if idx > 3:
			s2.material_override.set_shader_param("col%d" % (idx - 3), col)
		else:
			s1.material_override.set_shader_param("col%d" % idx, col)
		idx += 1
	
	if tme >= length:
		if anim != null:
			anim.fin = true
		queue_free()
