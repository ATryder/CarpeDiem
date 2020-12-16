extends ControlTrans_Blinds
class_name ControlTrans_ContraBlinds

export var color2 := Color(0, 0, 0, 0) setget set_color2


func _init().(false):
	material.shader = preload("res://shaders/UI/control_animation/control_contra_blinds.shader")
	material.set_shader_param("color2", color2)


func set_color2(value : Color):
	color2 = value
	material.set_shader_param("color2", color2)
