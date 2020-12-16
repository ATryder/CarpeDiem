extends ControlTrans_Wipe
class_name ControlTrans_ColumnWipe

export(bool) var randomStart := false
export(float) var period := 0.5
export(int) var octaves := 0
export(float) var lacunarity := 2.0
export(float) var persistence := 0.5
export var columns := 1 setget set_columns, get_columns
export(float, 1.0) var columnLength := 0.8 setget set_column_length, get_column_length
export(Texture) var colors setget set_color_texture, get_color_texture
var num_colors := 1 setget set_number_of_colors, get_number_of_colors


func _init(loadShader := true).(false):
	if loadShader:
		material.shader = preload("res://shaders/UI/control_animation/control_column_wipe.shader")
	material.set_shader_param("columnLength", columnLength)


func play(play := true,
		renderControl := !initialized,
		attachToParent := true):
	.play(play,
			renderControl,
			attachToParent)
	if material.get_shader_param("colors") == null:
		if colors != null:
			material.set_shader_param("colors", colors)
		else:
			material.set_shader_param("colors", CD.get_blank_texture())
	if columns > 1 && material.get_shader_param("noise") == null:
		set_columns(columns)


func set_columns(value : int,
		randomStart := self.randomStart,
		period := self.period, octaves := self.octaves,
		lacunarity := self.lacunarity,
		persistence := self.persistence):
	columns = max(value, 1)
	var values = []
	var low = 100.0
	var high = 0.0
	if !randomStart:
		var noise = OpenSimplexNoise.new()
		noise.seed = randi()
		noise.period = columns * period
		noise.lacunarity = lacunarity
		noise.persistence = persistence
		noise.octaves = octaves
		for i in range(columns):
			var v = (noise.get_noise_2d(i, 0) + 1.0) / 2.0
			values.push_back(v)
			if v < low:
				low = v
			if v > high:
				high = v
	else:
		for i in range(columns):
			var v = rand_range(0.0, 100.0)
			values.push_back(v)
			if v < low:
				low = v
			if v > high:
				high = v
	
	var vRange = high - low
	for i in range(columns):
		values[i] = ((values[i] - low) / vRange) * 255
	
	var pbr = PoolByteArray(values)
	var img = Image.new()
	img.create_from_data(columns, 1, false,
			Image.FORMAT_R8, pbr)
	var tex = ImageTexture.new()
	tex.create_from_image(img, Texture.FLAG_MIRRORED_REPEAT)
	material.set_shader_param("noise", tex)
	material.set_shader_param("colorScale", float(columns) / num_colors)


func get_columns() -> int:
	return columns


func set_colors(colors : Array):
	if colors == null || colors.empty():
		set_color_texture(null)
		return
	
	var pbr = PoolByteArray()
	for color in colors:
		pbr.append(round(255 * color.r))
		pbr.append(round(255 * color.g))
		pbr.append(round(255 * color.b))
		pbr.append(round(255 * color.a))
	var img = Image.new()
	img.create_from_data(colors.size(), 1, false,
			Image.FORMAT_RGBA8, pbr)
	var tex = ImageTexture.new()
	tex.create_from_image(img, Texture.FLAG_REPEAT)
	set_color_texture(tex)


func set_color_texture(value : Texture):
	colors = value
	if value == null:
		material.set_shader_param("colors", CD.get_blank_texture())
		material.set_shader_param("colorScale", 1.0)
		num_colors = 1
		return
	num_colors = value.get_width()
	material.set_shader_param("colors", colors)
	material.set_shader_param("colorScale", float(columns) / num_colors)


func get_color_texture() -> Texture:
	return colors


func set_column_length(value : float):
	columnLength = clamp(value, 0, 1)
	material.set_shader_param("columnLength", columnLength)


func get_column_length() -> float:
	return columnLength


func set_number_of_colors(value : int):
	num_colors = max(1, value)


func get_number_of_colors() -> int:
	return num_colors


func step(time, delta):
	material.set_shader_param("perc", time / length)
