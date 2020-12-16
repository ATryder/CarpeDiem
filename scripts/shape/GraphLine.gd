extends MeshInstance2D
class_name GraphLine

var length := 0.5
var delay := 0.0
var tme := 0.0


func _process(delta):
	tme += delta
	if tme < delay:
		return
	
	material.set_shader_param("perc", min((tme - delay) / length, 1.0))
	if tme - delay >= length:
		set_process(false)


func play():
	tme = 0.0
	material.set_shader_param("perc", 0.0)
	set_process(true)


func create_mesh(points : Array, width : float, maxLength : float,
		color : Color, leftExtension := -1.0, rightExtension := 0.0):
	var w = width * 0.5
	var trans = Transform(Basis(Vector3(1, 0, 0),
								Vector3(0, 1, 0), Vector3(0, 0, 1)))
	trans.origin = Vector3(points[0].x, points[0].y, 0)
	var rotAxis = Vector3(0, 0, 1)
	trans.basis = trans.basis.rotated(rotAxis, (points[1] - points[0]).angle())
	
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var length = leftExtension
	var uv = length / maxLength
	
	var vert = Vector3(leftExtension, w, 0)
	st.add_uv(Vector2(uv, uv))
	st.add_vertex(trans.xform(vert))
	
	vert.y = -w
	st.add_uv(Vector2(uv, uv))
	st.add_vertex(trans.xform(vert))
	
	vert.x = 0
	for i in range(1, points.size() - 1):
		var lastPoint = points[i - 1]
		var point = points[i]
		var nextPoint = points[i + 1]
		trans.origin = Vector3(point.x, point.y, 0)
		
		length += point.distance_to(lastPoint)
		uv = length / maxLength
		
		var xNextPoint = trans.xform_inv(Vector3(nextPoint.x, nextPoint.y, 0))
		var angle = Vector3(1, 0, 0).angle_to(xNextPoint)
		var dot = Vector3(0, 1, 0).dot(xNextPoint)
		if dot <= 0:
			angle = -angle
		var t2 = Transform(trans.basis.rotated(rotAxis, angle * 0.5))
		t2.origin = trans.origin
		
		var angA = abs(angle) * 0.5
		var angC = (PI * 0.5) - angA
		var sideB = (width / sin(angC)) * sin(PI * 0.5)
		
		vert.y = sideB * 0.5
		st.add_uv(Vector2(uv, uv))
		st.add_vertex(t2.xform(vert))
		
		vert.y = -vert.y
		st.add_uv(Vector2(uv, uv))
		st.add_vertex(t2.xform(vert))
		
		var count = i * 2
		st.add_index(count - 2)
		st.add_index(count - 1)
		st.add_index(count)
		
		st.add_index(count)
		st.add_index(count - 1)
		st.add_index(count + 1)
		
		trans.basis = trans.basis.rotated(rotAxis, angle)
	
	var point = points[points.size() - 1]
	trans.origin = Vector3(point.x, point.y, 0)
	length += point.distance_to(points[points.size() - 2]) + rightExtension
	uv = length / maxLength
	
	vert.y = w
	vert.x = rightExtension
	st.add_uv(Vector2(uv, uv))
	st.add_vertex(trans.xform(vert))
	
	vert.y = -w
	st.add_uv(Vector2(uv, uv))
	st.add_vertex(trans.xform(vert))
	
	var count = points.size() * 2
	st.add_index(count - 4)
	st.add_index(count - 3)
	st.add_index(count - 2)

	st.add_index(count - 2)
	st.add_index(count - 3)
	st.add_index(count - 1)
	
	mesh = st.commit(null, Mesh.ARRAY_FORMAT_VERTEX
			& Mesh.ARRAY_FORMAT_TEX_UV & Mesh.ARRAY_FORMAT_INDEX & Mesh.ARRAY_COMPRESS_DEFAULT)
	material = ShaderMaterial.new()
	material.shader = preload("res://shaders/unshaded/gradient/GraphLine.shader")
	material.set_shader_param("color", color)
	material.set_shader_param("perc", 0.0)
