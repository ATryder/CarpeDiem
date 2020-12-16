extends Spatial

var tme = 0.0
var setMask = true
var maxLifetime = 0.0
var fin = false

func _ready():
	enable_oneshot(self)
	if setMask:
		particle_mask(self, get_node("/root/Game/Arena/FogControl"))


func _process(delta):
	if !fin:
		if is_fin(self):
			fin = true
			tme += delta
			if tme >= maxLifetime:
				queue_free()
	else:
		tme += delta
		if tme >= maxLifetime:
			queue_free()


func particle_mask(spatial, fc):
	if spatial is VisualInstance:
		var mat
		if spatial.material_override != null:
			mat = spatial.material_override.duplicate()
			mat.set_shader_param("mask_tex", fc.get_mask())
			mat.set_shader_param("mask_offset", fc.get_mask_offset())
			mat.set_shader_param("mask_scale", fc.get_mask_world_scale())
			spatial.material_override = mat
		elif spatial.get_surface_material(0) != null:
			mat = spatial.get_surface_material(0).duplicate()
			mat.set_shader_param("mask_tex", fc.get_mask())
			mat.set_shader_param("mask_offset", fc.get_mask_offset())
			mat.set_shader_param("mask_scale", fc.get_mask_world_scale())
			spatial.set_surface_material(0, mat)
	for s in spatial.get_children():
		particle_mask(s, fc)


func enable_oneshot(spatial):
	if spatial is Particles or spatial is CPUParticles:
		spatial.emitting = true
		if spatial.lifetime > maxLifetime:
			maxLifetime = spatial.lifetime
	for s in spatial.get_children():
		enable_oneshot(s)


func is_fin(spatial):
	if (spatial is Particles or spatial is CPUParticles) and spatial.emitting:
		return false
	for s in spatial.get_children():
		if !is_fin(s):
			return false
	return true
