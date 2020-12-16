extends MeshInstance

var colors
export(Array) var colors1
export(Array) var colors2
export(Array) var colors3
export(Array) var colors4
export(float) var totalParticles := 35
export(float) var minSpeed := 2.0
export(float) var maxSpeed := 4.0
export(float) var minSize := 8.0
export(float) var maxSize := 16.0
export(float) var minCourseLength := 0.8
export(float) var maxCourseLength := 1.6

var particles := []

onready var cam : Camera = get_node("../Camera")

var emitter : QuadEmitter

var mdt := MeshDataTool.new()


func _ready():
	randomize()
	
	colors = Math.get_random_array_item([colors1, colors2, colors3, colors4])
	
	var st = SurfaceTool.new()
	
	var p4 = global_transform.xform_inv(cam.project_position(Vector2(0, 0), cam.near + 1))
	var p2 = global_transform.xform_inv(cam.project_position(Vector2(0, 0), cam.far - 1))
	var p3 = global_transform.xform_inv(cam.project_position(Vector2(get_tree().get_root().size.x, 0), cam.far - 1))
	var p1 = global_transform.xform_inv(cam.project_position(Vector2(get_tree().get_root().size.x, 0), cam.near + 1))
	
	emitter = QuadEmitter.new(p1, p2, p3, p4, Vector3(0, maxSize * 0.5, 0))
	
	particles.resize(totalParticles)
	st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	for i in range(totalParticles):
		var loc = emitter.get_point()
		var bottom = -loc.y
		var xExtent = abs(global_transform.xform_inv(cam.project_position(Vector2(0, 0), abs(loc.z))).x) + (maxSize * 0.5)
		loc.y = rand_range(bottom, loc.y)
		particles[i] = Particle.new(Math.get_random_array_item(colors),
									loc,
									rand_range(minSize, maxSize),
									rand_range(minSpeed, maxSpeed),
									minCourseLength,
									maxCourseLength,
									bottom,
									xExtent,
									i,
									st)
	
	mesh = st.commit(null, ArrayMesh.ARRAY_FORMAT_VERTEX & ArrayMesh.ARRAY_FORMAT_NORMAL
			& ArrayMesh.ARRAY_FORMAT_TEX_UV & ArrayMesh.ARRAY_FORMAT_INDEX)
	mdt.create_from_surface(mesh, 0)
	get_tree().connect("screen_resized", self, "_resize", [], CONNECT_DEFERRED)


func _process(delta):
	get_parent().rotate_y(deg2rad(1.0) * -delta)
	
	var sort := false
	for particle in particles:
		if !particle.update(delta):
			sort = true
			var loc = emitter.get_point()
			var xExtent = abs(global_transform.xform_inv(cam.project_position(Vector2(0, 0), abs(loc.z))).x) + (maxSize * 0.5)
			particle.reset(Math.get_random_array_item(colors), loc, -loc.y, xExtent,
					rand_range(minSize, maxSize),
					rand_range(minSpeed, maxSpeed),
					minCourseLength,
					maxCourseLength)
			particle.update(delta)
	
	if sort:
		particles.sort_custom(self, "z_sort")
	
	for i in range(particles.size()):
		particles[i].update_mesh(mdt, cam, i)
	
	mesh.surface_remove(0)
	mdt.commit_to_surface(mesh)


func z_sort(a, b):
	return abs(a.trans.origin.z) > abs(b.trans.origin.z)


func _resize():
	emitter.p4 = global_transform.xform_inv(cam.project_position(Vector2(0, 0), cam.near + 1))
	emitter.p2 = global_transform.xform_inv(cam.project_position(Vector2(0, 0), cam.far - 1))
	emitter.p3 = global_transform.xform_inv(cam.project_position(Vector2(get_tree().get_root().size.x, 0), cam.far - 1))
	emitter.p1 = global_transform.xform_inv(cam.project_position(Vector2(get_tree().get_root().size.x, 0), cam.near + 1))
	
	for particle in particles:
		var pos = global_transform.xform_inv(cam.project_position(Vector2(0, 0), abs(particle.trans.origin.z)))
		particle.side = abs(pos.x) + (maxSize * 0.5)
		particle.bottom = -pos.y - (maxSize * 0.5)


class Particle:
	const ACCEL := 0.04
	
	var color : Color
	
	var trans := Transform(Basis(Vector3(1, 0, 0),
							Vector3(0, 1, 0),
							Vector3(0, 0, 1)))
	
	var speed : float
	var velocity : Vector3
	var pVelocity := Vector3(0, 0, 0)
	var size : float
	
	var courseTme := 0.0
	var courseLength : float
	var minCourseLength : float
	var maxCourseLength : float
	
	var bottom : float
	var side : float
	
	var idx : int
	
	
	func _init(particleColor : Color, location : Vector3, pSize : float,
				speed : float, minLength : float, maxLength : float,
				var yBottom : float, var xExtent : float, arrayIdx : int, st : SurfaceTool):
		idx = arrayIdx
		color = particleColor
		trans.origin = location
		size = pSize * 0.5
		self.speed = speed
		minCourseLength = minLength
		maxCourseLength = maxLength
		courseLength = rand_range(minCourseLength, maxCourseLength)
		bottom = yBottom
		side = xExtent
		
		velocity = Vector3(0, -speed, 0)
		var basis = Basis(Vector3(0, 0, 1), rand_range(-0.3, 0.3))
		velocity = basis.xform(velocity)
		pVelocity = velocity
		
		#Lower Right
		var vert = trans.xform(Vector3(size, -size, 0))
		st.add_normal(Vector3(0, 0, 1))
		st.add_uv(Vector2(0, 0))
		st.add_color(color)
		st.add_vertex(vert)
		
		#Lower Left
		vert = trans.xform(Vector3(-size, -size, 0))
		st.add_normal(Vector3(0, 0, 1))
		st.add_uv(Vector2(1, 0))
		st.add_color(color)
		st.add_vertex(vert)
		
		#Upper Left
		vert = trans.xform(Vector3(-size, size, 0))
		st.add_normal(Vector3(0, 0, 1))
		st.add_uv(Vector2(1, 1))
		st.add_color(color)
		st.add_vertex(vert)
		
		#Upper Right
		vert = trans.xform(Vector3(size, size, 0))
		st.add_normal(Vector3(0, 0, 1))
		st.add_uv(Vector2(0, 1))
		st.add_color(color)
		st.add_vertex(vert)
		
		var offset = idx * 4
		st.add_index(offset)
		st.add_index(offset + 1)
		st.add_index(offset + 3)
		st.add_index(offset + 2)
		st.add_index(offset + 3)
		st.add_index(offset + 1)
	
	
	func reset(particleColor : Color, location : Vector3, yBottom : float, xExtent : float,
				pSize : float, speed : float, minLength : float, maxLength : float):
		color = particleColor
		trans.origin = location
		bottom = yBottom
		side = xExtent
		size = pSize * 0.5
		
		self.speed = speed
		velocity = Vector3(0, -speed, 0)
		var basis = Basis(Vector3(0, 0, 1), rand_range(-0.3, 0.3))
		velocity = basis.xform(velocity)
		
		pVelocity = velocity
		
		minCourseLength = minLength
		maxCourseLength = maxLength
		courseLength = rand_range(minCourseLength, maxCourseLength)
	
	
	func update(delta) -> bool:
		courseTme += delta
		if courseTme >= courseLength:
			courseTme -= floor(courseTme / courseLength) * courseLength
			courseLength = rand_range(minCourseLength, maxCourseLength)
			pVelocity = Vector3(velocity.x, velocity.y, velocity.z)
			var basis = Basis(Vector3(0, 0, 1), rand_range(-.9, .9))
			velocity = basis.xform(velocity)
		
		trans.origin += Math.fsmooth(pVelocity, velocity, courseTme / courseLength) * delta
		
		if trans.origin.y > -bottom + size || trans.origin.y < bottom || trans.origin.x > side || trans.origin.x < -side:
			return false
		
		return true
	
	
	func update_mesh(mdt : MeshDataTool, cam : Camera, index := idx):
		idx = index
		
		var ofs = idx * 4
		var vert = trans.xform(Vector3(size, -size, 0))
		mdt.set_vertex(ofs, vert)
		vert = trans.xform(Vector3(-size, -size, 0))
		mdt.set_vertex(ofs + 1, vert)
		vert = trans.xform(Vector3(-size, size, 0))
		mdt.set_vertex(ofs + 2, vert)
		vert = trans.xform(Vector3(size, size, 0))
		mdt.set_vertex(ofs + 3, vert)
		
		color.a = clamp((trans.origin.distance_to(cam.get_camera_transform().origin) - (cam.near + 1))
				/ ((cam.far - 1) - (cam.near + 1)), 0.0, 1.0)
		
		mdt.set_vertex_color(ofs, color)
		mdt.set_vertex_color(ofs + 1, color)
		mdt.set_vertex_color(ofs + 2, color)
		mdt.set_vertex_color(ofs + 3, color)
