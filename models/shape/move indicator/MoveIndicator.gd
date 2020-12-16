extends MeshInstance

export(float) var width = 5.0
export(int, 0, 256) var segments = 64
export(float) var uvYsize = 0.04
export(float) var scrollSpeed = 0.25
export(float) var fadeLength := 3.0
export(Color) var color := Color(1,1,1,1)

var curve
var path

var offset = Vector2(0.0, 0.0)

var closing := false
var texSwap := true
var fade := 0.0;

var trans = Transform(Basis(Vector3(1, 0, 0),
					Vector3(0, 1, 0), Vector3(0, 0, 1)))
var uvy = 0.0

func _ready():
	material_override = material_override.duplicate()
	material_override.set_shader_param("tex", preload("res://textures/MovementIndicator.png"))
	material_override.set_shader_param("color", color)
	material_override.set_shader_param("offset", 0.0)

func _process(delta):
	if closing:
		if texSwap:
			texSwap = false
			material_override.set_shader_param("tex", preload("res://textures/MovementIndicator_blurry.png"))
		fade = min(fade + delta, fadeLength)
		if fade >= fadeLength:
			if get_parent() == null:
				return
			get_parent().remove_child(self)
			return
		var col = Color(color.r, color.g, color.b,
				Math.fsmooth_start(color.a, 0.0, fade / fadeLength))
		material_override.set_shader_param("color", col)
		return
	
	offset.y += delta * scrollSpeed
	if offset.y > 1:
		offset.y -= floor(offset.y)
	
	material_override.set_shader_param("offset", offset)

func get_curve():
	return curve

func update_geometry(newPath, newCurve):
	if newCurve == curve or newCurve.get_point_count() < 2:
		return
	
	curve = newCurve
	path = newPath
	
	trans = Transform(Basis(Vector3(1, 0, 0),
					Vector3(0, 1, 0), Vector3(0, 0, 1)))
	uvy = 0.0
	var origin = path[0]
	var originLoc = Vector3(origin.worldLoc.x, 0, origin.worldLoc.y)
	var st = SurfaceTool.new()
	var px = Vector3(width * 0.5, 0, 0)
	var nx = Vector3(-width * 0.5, 0, 0)
	
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	trans.origin = curve.get_point_position(0) - originLoc
	var pos = curve.interpolate(0, 1.0 / segments) - originLoc
	trans = trans.looking_at(pos, Vector3(0, 1, 0))
	
	st.add_normal(Vector3(0, 1, 0))
	st.add_uv(Vector2(0, 0))
	st.add_uv2(Vector2(0, 0))
	st.add_vertex(trans.xform(px))
	
	st.add_normal(Vector3(0, 1, 0))
	st.add_uv(Vector2(1, 0))
	st.add_uv2(Vector2(1, 0))
	st.add_vertex(trans.xform(nx))
	create_segments(0, px, nx, curve, st, originLoc)
	for i in range(1, curve.get_point_count() - 1):
		pos = curve.get_point_position(i) - originLoc
		trans = trans.looking_at(pos, Vector3(0, 1, 0))
		
		uvy += pos.distance_to(trans.origin) * uvYsize
		trans.origin.x = pos.x
		trans.origin.z = pos.z
		st.add_normal(Vector3(0, 1, 0))
		st.add_uv(Vector2(0, uvy))
		st.add_uv2(Vector2(0, 1))
		st.add_vertex(trans.xform(px))
		
		st.add_normal(Vector3(0, 1, 0))
		st.add_uv(Vector2(1, uvy))
		st.add_uv2(Vector2(1, 1))
		st.add_vertex(trans.xform(nx))
		
		create_segments(i, px, nx, curve, st, originLoc)
	
	pos = curve.get_point_position(curve.get_point_count() - 1) - originLoc
	trans = trans.looking_at(pos, Vector3(0, 1, 0))
	
	uvy += pos.distance_to(trans.origin) * uvYsize
	trans.origin.x = pos.x
	trans.origin.z = pos.z
	st.add_normal(Vector3(0, 1, 0))
	st.add_uv(Vector2(0, uvy))
	st.add_uv2(Vector2(0, 0))
	st.add_vertex(trans.xform(px * 0.5))
	
	st.add_normal(Vector3(0, 1, 0))
	st.add_uv(Vector2(1, uvy))
	st.add_uv2(Vector2(1, 0))
	st.add_vertex(trans.xform(nx * 0.5))
	
	for i in range(0, (curve.get_point_count() - 1) * segments):
		var tri = i * 2
		st.add_index(tri)
		st.add_index(tri + 1)
		st.add_index(tri + 2)
		st.add_index(tri + 1)
		st.add_index(tri + 3)
		st.add_index(tri + 2)
	trans = null
	
	# I've found that the default value for the flags argument to
	# SurfaceTool.commit() results in extremely inaccurate
	# vertex positions farther out from the origin.
	mesh = st.commit(null, ArrayMesh.ARRAY_VERTEX & ArrayMesh.ARRAY_TEX_UV & ArrayMesh.ARRAY_TEX_UV2 & ArrayMesh.ARRAY_NORMAL & ArrayMesh.ARRAY_INDEX)

func create_segments(idx, px, nx, curve, st, originLoc):
	for i in range(1, segments):
		var pos = curve.interpolate(idx, float(i) / segments) - originLoc
		trans = trans.looking_at(pos, Vector3(0, 1, 0))
		
		var uv2 = 1.0
		var wmod = 1.0
		if idx == 0:
			if curve.get_point_count() == 2:
				var perc = float(i) / segments
				if perc <= 0.5:
					uv2 = Math.fsmooth_curve(0.0, 1.0, perc / 0.5)
				else:
					perc = (perc - 0.5) / 0.5
					uv2 = Math.fsmooth_curve(1.0, 0.0, perc)
					wmod = Math.fsmooth_curve(1.0, 0.5, perc)
			else:
				uv2 = Math.fsmooth_curve(0.0, 1.0, float(i) / segments)
		elif idx == curve.get_point_count() - 2:
			var perc = float(i) / segments
			uv2 = Math.fsmooth_curve(1.0, 0.0, perc)
			wmod = Math.fsmooth_curve(1.0, 0.5, perc)
		
		uvy += pos.distance_to(trans.origin) * uvYsize
		trans.origin.x = pos.x
		trans.origin.z = pos.z
		st.add_normal(Vector3(0, 1, 0))
		st.add_uv(Vector2(0, uvy))
		st.add_uv2(Vector2(0, uv2))
		st.add_vertex(trans.xform(px * wmod))
		
		st.add_normal(Vector3(0, 1, 0))
		st.add_uv(Vector2(1, uvy))
		st.add_uv2(Vector2(1, uv2))
		st.add_vertex(trans.xform(nx * wmod))

func close():
	closing = true
