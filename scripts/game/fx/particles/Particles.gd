extends Spatial

var finTimer = 0.0
var setMask = true

func _ready():
	set_process(false)
	if get_parent().has_method("set_moves"):
		spark_mat(self, get_parent().player.sparkMaterial)
	elif setMask:
		set_mask()

func set_mask(fc = get_node("/root/Game/Arena/FogControl")):
	particle_mask(self, fc)

func _process(delta):
	finTimer -= delta
	if finTimer <= 0 and not is_queued_for_deletion():
		queue_free()

func finish():
	set_process(true)
	particle_fin(self)

func particle_fin(spatial):
	if spatial is Particles or spatial is CPUParticles:
		spatial.emitting = false
		if spatial.lifetime > finTimer:
			finTimer = spatial.lifetime
	for s in spatial.get_children():
		particle_fin(s)

func spark_mat(spatial, material):
	if spatial.name.begins_with("Sparks"):
		spatial.material_override = material
	for s in spatial.get_children():
		spark_mat(s, material)

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
