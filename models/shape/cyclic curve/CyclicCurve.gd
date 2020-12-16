extends MeshInstance

export(float) var width = 5.0
export(float) var offset = 0.0
export(int, 0, 256) var segments = 12
export(float) var uvYsize = 0.04

var trans


func update_geometries(curves):
	mesh = null
	for curve in curves:
		update_geometry(curve)


func update_geometry(curve):
	if curve.get_point_count() < 2:
		return
	
	trans = Transform(Basis(Vector3(1, 0, 0),
					Vector3(0, 1, 0), Vector3(0, 0, 1)))
	var st = SurfaceTool.new()
	var px = Vector3((width * 0.5) + offset, 0, 0)
	var nx = Vector3(-(width * 0.5) + offset, 0, 0)
	
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	trans.origin = curve.get_point_position(0)
	var pos = curve.interpolate(0, 1.0 / segments)
	trans = trans.looking_at(pos, Vector3(0, 1, 0))
	
	pos = trans.xform(px)
	st.add_normal(Vector3(0, 1, 0))
	st.add_uv(Vector2(0, 0.5))
	st.add_vertex(trans.xform(px))
	
	st.add_normal(Vector3(0, 1, 0))
	st.add_uv(Vector2(1, 0.5))
	st.add_vertex(trans.xform(nx))
	create_segments(0, px, nx, curve, st)
	for i in range(1, curve.get_point_count() - 1):
		pos = curve.get_point_position(i)
		trans = trans.looking_at(pos, Vector3(0, 1, 0))
		
		trans.origin.x = pos.x
		trans.origin.z = pos.z
		st.add_normal(Vector3(0, 1, 0))
		st.add_uv(Vector2(0, 0.5))
		st.add_vertex(trans.xform(px))
		
		st.add_normal(Vector3(0, 1, 0))
		st.add_uv(Vector2(1, 0.5))
		st.add_vertex(trans.xform(nx))
		
		create_segments(i, px, nx, curve, st)
	
	var tri
	for i in range(0, ((curve.get_point_count() - 1) * segments) - 1):
		tri = i * 2
		st.add_index(tri)
		st.add_index(tri + 1)
		st.add_index(tri + 2)
		st.add_index(tri + 1)
		st.add_index(tri + 3)
		st.add_index(tri + 2)
	
	tri = (((curve.get_point_count() - 1) * segments) - 1) * 2
	st.add_index(tri)
	st.add_index(tri + 1)
	st.add_index(0)
	st.add_index(tri + 1)
	st.add_index(1)
	st.add_index(0)
	trans = null
	
	# I've found that the default value for the flags argument to
	# SurfaceTool.commit() results in extremely inaccurate
	# vertex positions farther out from the origin.
	mesh = st.commit(mesh, ArrayMesh.ARRAY_VERTEX & ArrayMesh.ARRAY_TEX_UV & ArrayMesh.ARRAY_NORMAL & ArrayMesh.ARRAY_INDEX)


func create_segments(idx, px, nx, curve, st):
	for i in range(1, segments):
		var pos = curve.interpolate(idx, float(i) / segments)
		trans = trans.looking_at(pos, Vector3(0, 1, 0))
		
		trans.origin.x = pos.x
		trans.origin.z = pos.z
		st.add_normal(Vector3(0, 1, 0))
		st.add_uv(Vector2(0, 0.5))
		st.add_vertex(trans.xform(px))
		
		st.add_normal(Vector3(0, 1, 0))
		st.add_uv(Vector2(1, 0.5))
		st.add_vertex(trans.xform(nx))
