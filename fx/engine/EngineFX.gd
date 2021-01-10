extends Spatial
class_name EngineFX

var engineSparks = []
var enginePlumes = []

var finishing := false


func _ready():
	set_process(false)
	
	var plumes = get_node("plumes")
	var arena = get_node("/root/Game/Arena")
	if plumes != null:
		var coneTex
		match get_parent().player.color:
			CD.PLAYER_BLUE:
				coneTex = load("res://fx/engine/color gradients/EnginePlume_blue.tres")
			CD.PLAYER_CYAN:
				coneTex = load("res://fx/engine/color gradients/EnginePlume_cyan.tres")
			CD.PLAYER_GREEN:
				coneTex = load("res://fx/engine/color gradients/EnginePlume_green.tres")
			CD.PLAYER_ORANGE:
				coneTex = load("res://fx/engine/color gradients/EnginePlume_orange.tres")
			CD.PLAYER_PURPLE:
				coneTex = load("res://fx/engine/color gradients/EnginePlume_purple.tres")
			CD.PLAYER_RED:
				coneTex = load("res://fx/engine/color gradients/EnginePlume_red.tres")
			CD.PLAYER_YELLOW:
				coneTex = load("res://fx/engine/color gradients/EnginePlume_yellow.tres")
			_:
				coneTex = load("res://fx/engine/color gradients/EnginePlume_blue.tres")
		for plume in plumes.get_children():
			enginePlumes.push_back(plume.get_node("AnimationPlayer"))
			var cone = plume.get_node("Cone")
			cone.material_override = cone.material_override.duplicate()
			cone.material_override.set_shader_param("tex", coneTex)
			if !get_parent().player.is_local_player():
				cone.material_override.set_shader_param("mask_tex", arena.fogControl.get_mask())
				cone.material_override.set_shader_param("mask_offset", arena.fogControl.get_mask_offset())
				cone.material_override.set_shader_param("mask_scale", arena.fogControl.get_mask_world_scale())
		for plume in enginePlumes:
			plume.play("start")
	
	findSparks(self, get_node("/root/Game/Effects"))
	if Opts.particleDetail == Opts.QUALITY_LOW:
		for sparks in engineSparks:
			sparks.emit = false
			sparks.queue_free()
		engineSparks.clear()
	else:
		for sparks in engineSparks:
			sparks.init()


func _process(delta):
	for plume in enginePlumes:
		if plume.is_playing():
			return
	
	queue_free()


func findSparks(node : Node, gameFXNode : Node):
	if node is EngineSparks:
		engineSparks.push_back(node)
		node.material_override = get_parent().player.sparkMaterial
		node.material_override.shader = preload("res://shaders/unshaded/gradient/Masked_CircleGrad.shader")
		node.get_parent().remove_child(node)
		gameFXNode.add_child(node)
	else:
		for n in node.get_children():
			findSparks(n, gameFXNode)


func finish():
	if finishing:
		return
	finishing = true
	set_process(true)
	for plume in enginePlumes:
		plume.play("stop")
	for sparks in engineSparks:
		sparks.emit = false
