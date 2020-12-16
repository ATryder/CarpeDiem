extends MeshInstance

var particles = []

var cam

var margin
var interval
var tme

var startedFlames = 0

var initialized = false

var removeOnFinish = true
var fin = false


func _ready():
	if cam == null:
		cam = get_node("/root/Game/CameraControl").cam
	set_process(initialized)


func init(numFlames, timeLength, armLength, 
		startPScale, endPScale, minPSize, maxPSize,
		minPLife, maxPLife, minRotSpeed, maxRotSpeed,
		tipScale, fogControl = null):
	if initialized:
		particles.clear()
		fin = false
		startedFlames = 0
	
	tipScale = 1.0 - clamp(tipScale, 0.0, 1.0)
	margin = armLength / float(numFlames)
	interval = timeLength / float(numFlames)
	
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(numFlames):
		var perc = (i / float(numFlames)) * tipScale
		particles.push_back(
				FlameParticle.new(Vector3(0, 0, margin * i),
						rand_range(0, PI * 2),
						rand_range(minRotSpeed, maxRotSpeed),
						rand_range(minPSize * (1.0 - perc),
						maxPSize * (1.0 - perc)),
						startPScale, endPScale,
						rand_range(minPLife, maxPLife),
						i, st))
	
	mesh = st.commit(null, ArrayMesh.ARRAY_VERTEX & ArrayMesh.ARRAY_NORMAL
			& ArrayMesh.ARRAY_COLOR & ArrayMesh.ARRAY_TEX_UV & ArrayMesh.ARRAY_INDEX)
	tme = interval
	initialized = true
	if is_inside_tree():
		set_process(true)
	
	if fogControl != null:
		material_override.set_shader_param("mask_tex", fogControl.get_mask())
		material_override.set_shader_param("mask_offset", fogControl.get_mask_offset())
		material_override.set_shader_param("mask_scale", fogControl.get_mask_world_scale())


func _process(delta):
	tme += delta
	if tme >= interval and startedFlames < particles.size():
		var numToSpawn = int(min(floor(tme / interval), particles.size() - startedFlames))
		for i in range(numToSpawn):
			particles[startedFlames].start(tme - (interval * (i + 1)))
			startedFlames += 1
		tme -= numToSpawn * interval
	
	var mdt = MeshDataTool.new()
	mdt.create_from_surface(mesh, 0)
	var numAlive = particles.size()
	var camLoc = global_transform.xform_inv(cam.get_global_transform().origin)
	for p in particles:
		if !p.update(delta, mdt, camLoc):
			numAlive -= 1
	
	mesh.surface_remove(0)
	mdt.commit_to_surface(mesh)
	
	if numAlive == 0:
		fin = true
		set_process(false)
		if removeOnFinish:
			queue_free()


class FlameParticle:
	var started = false
	
	var idx
	
	var lifeTme
	var tmeAlive
	
	var trans
	var size
	var startScale
	var endScale
	
	var rotSpeed
	var rot
	
	var perc
	
	func _init(location, initRotation, radPerSec,
			size, startScale, endScale, timeLength,
			arrayIdx, st):
		trans = Transform(Basis(Vector3(1, 0, 0),
						Vector3(0, 1, 0),
						Vector3(0, 0, 1)))
		trans.origin = location
		self.size = size
		self.startScale = startScale
		self.endScale = endScale
		lifeTme = timeLength
		idx = arrayIdx
		rot = initRotation
		rotSpeed = radPerSec
		
		var di = startScale * size * 0.5
		var quat = Quat(Vector3(0, 1, 0), rot)
		
		#Lower Right
		var vert = quat.xform(Vector3(di, -di, 0))
		vert = trans.xform(vert)
		st.add_normal(Vector3(0, 0, -1))
		st.add_uv(Vector2(0, 0))
		st.add_color(Color(1, 1, 1, 0))
		st.add_vertex(vert)
		
		#Lower Left
		vert = quat.xform(Vector3(-di, -di, 0))
		vert = trans.xform(vert)
		st.add_normal(Vector3(0, 0, -1))
		st.add_uv(Vector2(1, 0))
		st.add_color(Color(1, 1, 1, 0))
		st.add_vertex(vert)
		
		#Upper Left
		vert = quat.xform(Vector3(-di, di, 0))
		vert = trans.xform(vert)
		st.add_normal(Vector3(0, 0, -1))
		st.add_uv(Vector2(1, 1))
		st.add_color(Color(1, 1, 1, 0))
		st.add_vertex(vert)
		
		#Upper Right
		vert = quat.xform(Vector3(di, di, 0))
		vert = trans.xform(vert)
		st.add_normal(Vector3(0, 0, -1))
		st.add_uv(Vector2(0, 1))
		st.add_color(Color(1, 1, 1, 0))
		st.add_vertex(vert)
		
		var offset = idx * 4
		st.add_index(offset + 3)
		st.add_index(offset + 1)
		st.add_index(offset)
		st.add_index(offset + 2)
		st.add_index(offset + 1)
		st.add_index(offset + 3)
	
	
	func start(elapsedTme):
		started = true
		tmeAlive = elapsedTme
	
	
	func update(delta, mdt, camLoc):
		if !started:
			return true
		elif tmeAlive >= lifeTme:
			return false
		
		tmeAlive += delta
		rot += rotSpeed * delta
		perc = min(tmeAlive / lifeTme, 1.0)
		
		var alpha = Math.fsmooth_start(1.0, 0.0, perc)
		var di = Math.fsmooth_stop(startScale, endScale, perc) * size * 0.5
		
		trans = trans.looking_at(camLoc, Vector3(0, 0, 1))
		var quat = Quat(Vector3(0, 0, 1), rot)
		var ofs = idx * 4
		
		var vert = quat.xform(Vector3(di, -di, 0))
		vert = trans.xform(vert)
		mdt.set_vertex(ofs, vert)
		vert = quat.xform(Vector3(-di, -di, 0))
		vert = trans.xform(vert)
		mdt.set_vertex(ofs + 1, vert)
		vert = quat.xform(Vector3(-di, di, 0))
		vert = trans.xform(vert)
		mdt.set_vertex(ofs + 2, vert)
		vert = quat.xform(Vector3(di, di, 0))
		vert = trans.xform(vert)
		mdt.set_vertex(ofs + 3, vert)
		
		mdt.set_vertex_color(ofs, Color(1, 1, 1, alpha))
		mdt.set_vertex_color(ofs + 1, Color(1, 1, 1, alpha))
		mdt.set_vertex_color(ofs + 2, Color(1, 1, 1, alpha))
		mdt.set_vertex_color(ofs + 3, Color(1, 1, 1, alpha))
		
		return tmeAlive < lifeTme
