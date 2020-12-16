extends MeshInstance

var mat : Material setget set_material, get_material

var offset := Vector2(randf() * 512.0, randf() * 512.0)

var timeScale := Vector2(1 + (randf() * 6), 1 + (randf() * 6))
var tme := Vector2(0.0, 0.0)
var maxTme := Vector2(562, 562)
var xReverse := false
var yReverse := false
var perc := Vector2(0.0, 0.0)

var highTimeScale := 7.0
var highTme := 205.0
var highMaxTme := 762.0
var highReverse := false

var texture : Texture setget set_texture, get_texture


func _ready():
	set_process(false)


func set_material(cloudMaterial : Material):
	mat = cloudMaterial
	set_surface_material(0, mat)
	
	offset = Vector2(randf() * 512.0, randf() * 512.0)
	if randi() < 0.5:
		timeScale = Vector2(3 + (randf() * 4), 1 + (randf() * 6))
	else:
		timeScale = Vector2(1 + (randf() * 6), 3 + (randf() * 4))
	tme = Vector2(100 + (randf() * 200), 100 + (randf() * 200))
	mat.set_shader_param("offset", offset)


func get_material() -> Material:
	return mat


func set_texture(tex : Texture):
	texture = tex
	if mat != null:
		mat.set_shader_param("tex", texture)


func get_texture() -> Texture:
	return texture


func create_plane(size_x, size_y):
	var st = SurfaceTool.new()
	
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	#Lower Right
	st.add_normal(Vector3(0, 1, 0))
	st.add_uv(Vector2(0, 0))
	st.add_vertex(Vector3(0, 0, size_y))
	
	#Lower Left
	st.add_normal(Vector3(0, 1, 0))
	st.add_uv(Vector2(1, 0))
	st.add_vertex(Vector3(size_x, 0, size_y))
	
	#Upper Right
	st.add_normal(Vector3(0, 1, 0))
	st.add_uv(Vector2(0, 1))
	st.add_vertex(Vector3(0, 0, 0))
	
	#Upper Left
	st.add_normal(Vector3(0, 1, 0))
	st.add_uv(Vector2(1, 1))
	st.add_vertex(Vector3(size_x, 0, 0))
	
	#Clockwise ordering
	st.add_index(0)
	st.add_index(2)
	st.add_index(1)
	st.add_index(1)
	st.add_index(2)
	st.add_index(3)
	
	var aMesh = st.commit()
	mesh = aMesh


func _process(delta):
	tme.x += delta * timeScale.x
	tme.y += delta * timeScale.y
		
	if tme.x >= maxTme.x:
		tme.x = tme.x - (floor(tme.x / maxTme.x) * maxTme.x)
		xReverse = !xReverse
		if timeScale.y < 2:
			timeScale.x = 3 + (randf() * 3)
		else:
			timeScale.x = 1 + (randf() * 6)
	if tme.y >= maxTme.y:
		tme.y = tme.y - (floor(tme.y / maxTme.y) * maxTme.y)
		yReverse = !yReverse
		if timeScale.x < 2:
			timeScale.y = 3 + (randf() * 3)
		else:
			timeScale.y = 1 + (randf() * 6)
	
	perc.x = tme.x / maxTme.x
	perc.y = tme.y / maxTme.y
	var ofs = Vector2(offset.x, offset.y)
	if !xReverse:
		ofs.x += Math.fsmooth(0.0, maxTme.x, perc.x)
	else:
		ofs.x += Math.fsmooth(maxTme.x, 0.0, perc.x)
	if !yReverse:
		ofs.y += Math.fsmooth(0.0, maxTme.y, perc.y)
	else:
		ofs.y += Math.fsmooth(maxTme.y, 0.0, perc.y)
	mat.set_shader_param("offset", ofs)
	
	if Opts.cloudQuality < Opts.QUALITY_HIGH:
		return
	
	highTme += highTimeScale * delta
	if highTme >= highMaxTme:
		highTme = highTme - (floor(highTme / highMaxTme) * highMaxTme)
		highReverse = !highReverse
	
	if !highReverse:
		mat.set_shader_param("time", Math.fsmooth(0.0, highMaxTme, highTme / highMaxTme))
	else:
		mat.set_shader_param("time", Math.fsmooth(highMaxTme, 0.0, highTme / highMaxTme))
