extends ControlTransition
class_name ControlTrans_Wipe

export(float, 1.0) var offset := 0.0 setget set_offset, get_offset
export var color := Color(1, 1, 1, 1) setget set_edge_color, get_edge_color
export var edgeSize := 0.0 setget set_edge_size, get_edge_size
export var leadingFade := 0.0 setget set_leading_fade, get_leading_fade
export var trailingFade := 0.0 setget set_trailing_fade, get_trailing_fade
export var angle := 0.0 setget set_angle, get_angle


func _init(loadShader := true):
	material = ShaderMaterial.new()
	if loadShader:
		material.shader = preload("res://shaders/UI/control_animation/control_simple_wipe.shader")
	material.set_shader_param("offset", offset)
	material.set_shader_param("color", color)
	material.set_shader_param("colorSize", edgeSize)
	material.set_shader_param("leadingFade", leadingFade)
	material.set_shader_param("trailingFade", trailingFade)
	material.set_shader_param("angle", angle)


func set_edge_color(value : Color):
	color = value
	material.set_shader_param("color", color)


func get_edge_color() -> Color:
	return color


func set_edge_size(value : float):
	edgeSize = value
	material.set_shader_param("colorSize", edgeSize)


func get_edge_size() -> float:
	return edgeSize


func set_leading_fade(value : float):
	leadingFade = value
	material.set_shader_param("leadingFade", leadingFade)


func get_leading_fade() -> float:
	return leadingFade


func set_trailing_fade(value : float):
	trailingFade = value
	material.set_shader_param("trailingFade", trailingFade)


func get_trailing_fade() -> float:
	return trailingFade


func set_offset(value : float):
	offset = clamp(value, 0.0, 1.0)
	material.set_shader_param("offset", offset)


func get_offset() -> float:
	return offset


func set_angle(value : float):
	angle = value
	material.set_shader_param("angle", value)


func get_angle() -> float:
	return angle
