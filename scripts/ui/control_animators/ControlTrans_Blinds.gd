extends ControlTrans_Wipe
class_name ControlTrans_Blinds

export(int) var num_blades := 4 setget set_num_blades, get_num_blades
export(float, 1.0) var blade_length := 1.0 setget set_blade_length, get_blade_length


func _init(loadShader := true).(false):
	if loadShader:
		material.shader = preload("res://shaders/UI/control_animation/control_blinds.shader")
	material.set_shader_param("numBlades", num_blades)
	material.set_shader_param("bladeLength", blade_length)


func set_num_blades(value : int):
	num_blades = max(value, 1)
	material.set_shader_param("numBlades", num_blades)


func get_num_blades() -> int:
	return num_blades


func set_blade_length(value : float):
	blade_length = clamp(value, 0.0, 1.0)
	material.set_shader_param("bladeLength", blade_length)


func get_blade_length() -> float:
	return blade_length
