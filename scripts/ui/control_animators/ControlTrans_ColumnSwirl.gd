extends ControlTrans_ColumnWipe
class_name ControlTrans_ColumnSwirl

export(float) var swirlAmount := 3.0 setget set_swirl_amount


func _init().(false):
	material.shader = preload("res://shaders/UI/control_animation/control_column_swirl.shader")
	material.set_shader_param("swirlAmount", swirlAmount)


func set_swirl_amount(value):
	swirlAmount = value
	material.set_shader_param("swirlAmount", value)
