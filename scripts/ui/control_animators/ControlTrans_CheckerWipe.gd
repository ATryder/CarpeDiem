extends ControlTrans_Wipe
class_name ControlTrans_CheckerWipe

export(bool) var random := true
export var grid := Vector2(3, 3) setget set_grid
export(float, 1.0) var squareLength := 0.8 setget set_square_length


func _init(loadShader := true).(false):
	if loadShader:
		material.shader = preload("res://shaders/UI/control_animation/control_checker_wipe.shader")
	material.set_shader_param("squareLength", squareLength)
	if material.get_shader_param("grid") == null:
		set_grid(grid)
	


func set_grid(value : Vector2):
	if !random:
		set_checker(value)
		return
	
	var columns = int(max(value.x, 1))
	var rows = int(max(value.y, 1))
	grid = Vector2(columns, rows)
	var values = []
	values.resize(columns * rows)
	var low = 100.0
	var high = 0.0
	for i in range(values.size()):
		var v = rand_range(0.0, 100.0)
		values[i] = v
		if v < low:
			low = v
		if v > high:
			high = v
	
	var vRange = high - low
	for i in range(values.size()):
		values[i] = ((values[i] - low) / vRange) * 255
	
	var pbr = PoolByteArray(values)
	var img = Image.new()
	img.create_from_data(columns, rows, false,
			Image.FORMAT_R8, pbr)
	var tex = ImageTexture.new()
	tex.create_from_image(img, 0)
	material.set_shader_param("grid", tex)
	material.set_shader_param("rows", grid.y)


func set_checker(value : Vector2):
	var columns = int(max(value.x, 1))
	var rows = int(max(value.y, 1))
	grid = Vector2(columns, rows)
	var values = []
	values.resize(columns * rows)
	
	var white = true
	for i in range(values.size()):
		if i % rows == 0:
			white = (i / rows) % 2
		else:
			white = !white
		
		if white:
			values[i] = 255
		else:
			values[i] = 0
	
	var pbr = PoolByteArray(values)
	var img = Image.new()
	img.create_from_data(columns, rows, false,
			Image.FORMAT_R8, pbr)
	var tex = ImageTexture.new()
	tex.create_from_image(img, 0)
	material.set_shader_param("grid", tex)
	material.set_shader_param("rows", grid.y)


func set_square_length(value : float):
	squareLength = clamp(value, 0, 1)
	material.set_shader_param("squareLength", squareLength)


func step(time, delta):
	material.set_shader_param("perc", time / length)
