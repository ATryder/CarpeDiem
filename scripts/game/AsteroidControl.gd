extends Spatial

export(int, 16) var block_width = 8
export(int, 16) var block_height = 8

const MESH_BLOCK = preload("res://models/shape/MeshBlock.tscn")
const ASTEROIDS = [
	preload("res://models/props/Asteroids/Asteroid_01.tscn"),
	preload("res://models/props/Asteroids/Asteroid_02.tscn"),
	preload("res://models/props/Asteroids/Asteroid_03.tscn"),
	preload("res://models/props/Asteroids/Asteroid_04.tscn"),
	preload("res://models/props/Asteroids/Asteroid_05.tscn"),
	preload("res://models/props/Asteroids/Asteroid_06.tscn"),
	preload("res://models/props/Asteroids/Asteroid_07.tscn"),
	preload("res://models/props/Asteroids/Asteroid_08.tscn"),
	preload("res://models/props/Asteroids/Asteroid_09.tscn")
	]

var AST_MAT

func _init():
	if CD.quality_mobile():
		AST_MAT = load("res://models/props/Asteroids/AsteroidMat_Mobile.tres")
	else:
		AST_MAT = load("res://models/props/Asteroids/AsteroidMat.tres")


func fog_initialized(fogControl):
	AST_MAT.set_shader_param("mask_tex", fogControl.get_mask())
	AST_MAT.set_shader_param("mask_offset", fogControl.get_mask_offset())
	AST_MAT.set_shader_param("mask_scale", fogControl.get_mask_world_scale())
	AST_MAT.set_shader_param("fog", fogControl.fogMapped)
