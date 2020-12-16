extends ControlTrans_Wipe
class_name ControlTrans_ContraWipe

export var color2 := Color(0, 0, 0, 0) setget set_color2


func _init().(false):
	material.shader = preload("res://shaders/UI/control_animation/control_contra_wipe.shader")
	material.set_shader_param("color2", color2)


func set_color2(value : Color):
	color2 = value
	material.set_shader_param("color2", color2)
