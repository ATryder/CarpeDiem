extends MeshInstance

var offset := 0.0
var radius := 0.0
var radius2 := 0.0
var fadeLength := 3.0
var speed := 0.45
var rspeed := CD.TILE_WIDTH * 30
var firstFrame := true
var closing := false
var alpha := Vector2(0.7, 0.85)

var mat = preload("res://models/shape/range indicator/range_indicator.material")

var tiles := []
var maximum : Vector2
var minimum : Vector2
var extent : float

func _init():
	mat = mat.duplicate()
	mat.set_shader_param("offset", 0.0)
	mat.set_shader_param("radius", 0.0)
	mat.set_shader_param("radius2", 0.0)
	mat.set_shader_param("fadeLength", fadeLength)
	mat.set_shader_param("alphaRange", alpha)

func _process(delta):
	if closing && radius2 >= extent + fadeLength && get_parent() != null:
		get_parent().remove_child(self)
		return
	
	if firstFrame:
		firstFrame = false
		return
	
	offset += delta * speed
	if offset > 1:
		offset = offset - floor(offset)
	mat.set_shader_param("offset", offset)
	
	radius = min(radius + (delta * rspeed), extent + fadeLength)
	mat.set_shader_param("radius", radius)
	
	if !closing:
		return
	
	radius2 = min(radius2 + (delta * rspeed), extent + fadeLength)
	mat.set_shader_param("radius2", radius2)

func create_mesh(origTile : CDTile, tiles1 : Array, color1,
		color2 = null, tiles2 := [], color3 = null, color4 = null, scale = 1.0,
		shareExtent := false):
	if color2 == null:
		color2 = color1
	if color4 == null:
		color4 = color3
	
	for t in tiles1:
		tiles.push_back(t)
	for t in tiles2:
		tiles.push_back(t)
	var hexVerts = [Vector3(-8, 0, 0),
				Vector3(-4, 0, 6.9282),
				Vector3(4, 0, 6.9282),
				Vector3(8, 0, 0),
				Vector3(4, 0, -6.9282),
				Vector3(-4, 0, -6.9282)]
	var hexIdx = [5, 1, 0,
			5, 2, 1,
			5, 4, 2,
			4, 3, 2]
	
	var st = SurfaceTool.new()
	var trans = Transform(Basis(Vector3(1, 0, 0),
				Vector3(0, 1, 0), Vector3(0, 0, 1)))
	scale *= CD.TILE_WIDTH / CD.BASE_TILE_SIZE
	trans = trans.scaled(Vector3(scale, scale, scale))
	
	maximum = Vector2(-INF, -INF)
	minimum = Vector2(INF, INF)
	var maximum2 = Vector2(-INF, -INF)
	var minimum2 = Vector2(INF, INF)
	var count = 0
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for tile in tiles:
		trans.origin.x = tile.worldLoc.x - origTile.worldLoc.x
		trans.origin.z = tile.worldLoc.y - origTile.worldLoc.y
		var ruv = Vector2(rand_range(0, 1), rand_range(0, 1))
		var col
		if tiles1.has(tile):
			col = Color(0, 0, 0)
		else:
			col = Color(1, 1, 1)
		for i in range(hexVerts.size()):
			var v = trans.xform(hexVerts[i])
			var v2 = Vector2(v.x, v.z)
			
			if col.r < 0.5 || shareExtent:
				if v2.x > maximum.x:
					maximum.x = v2.x
				elif v2.x < minimum.x:
					minimum.x = v2.x
				if v2.y > maximum.y:
					maximum.y = v2.y
				elif v2.y < minimum.y:
					minimum.y = v2.y
			else:
				if v2.x > maximum2.x:
					maximum2.x = v2.x
				elif v2.x < minimum2.x:
					minimum2.x = v2.x
				if v2.y > maximum2.y:
					maximum2.y = v2.y
				elif v2.y < minimum2.y:
					minimum2.y = v2.y
			
			st.add_uv(v2)
			st.add_uv2(ruv)
			st.add_normal(Vector3(0, 1, 0))
			st.add_color(col)
			st.add_vertex(v)
		for idx in hexIdx:
			st.add_index(idx + (count * hexVerts.size()))
		count += 1
	
	
	
	# I've found that the default value for the flags argument to
	# SurfaceTool.commit() results in extremely inaccurate
	# vertex positions farther out from the origin.
	mesh = st.commit(null, ArrayMesh.ARRAY_VERTEX & ArrayMesh.ARRAY_TEX_UV & ArrayMesh.ARRAY_TEX_UV2 & ArrayMesh.ARRAY_NORMAL & ArrayMesh.ARRAY_INDEX)
	if !tiles1.empty():
		mat.set_shader_param("minimum", minimum);
		mat.set_shader_param("extent", maximum - minimum);
		mat.set_shader_param("col1", color1)
		mat.set_shader_param("col2", color2)
	if !tiles2.empty():
		if shareExtent:
			mat.set_shader_param("minimum2", minimum);
			mat.set_shader_param("extent2", maximum - minimum)
		else:
			mat.set_shader_param("minimum2", minimum2);
			mat.set_shader_param("extent2", maximum2 - minimum2)
		mat.set_shader_param("col3", color3)
		mat.set_shader_param("col4", color4)
		maximum.x = max(maximum.x, maximum2.x)
		maximum.y = max(maximum.y, maximum2.y)
		minimum.x = min(minimum.x, minimum2.x)
		minimum.y = min(minimum.y, minimum2.y)
	set_surface_material(0, mat)
	
	extent = Vector2(max(abs(maximum.x), abs(minimum.x)),
			max(abs(maximum.y), abs(minimum.y))).length()
	
	rspeed = (extent / (8 * CD.TILE_WIDTH)) * rspeed

func close():
	closing = true
