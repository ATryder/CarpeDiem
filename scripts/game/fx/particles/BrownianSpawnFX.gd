extends MeshInstance
class_name BrownianSpawnFX

var particles = []

var cam

var numParticles = 120
var minLife = 1.2
var maxLife = 2.0
var minSize = 0.4
var maxSize = 1.0
var minSpeed = 20
var maxSpeed = 32
var minCourseLength = 0.18
var maxCourseLength = 0.36
var fadeInPerc = 0.3
var fadeOutPerc = 0.3

var emitter : Emitter

var initialized := false

var mdt : MeshDataTool


func _ready():
	if cam == null:
		cam = get_node("/root/Game/CameraControl").cam
	if emitter == null:
		emitter = SphereEmitter.new(CD.TILE_HEIGHT * 0.5)
	if !initialized:
		init()


func init():
	if initialized:
		return
	
	initialized = true
	
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(numParticles):
		particles.push_back(Particle.new(emitter.get_point(),
				rand_range(minSize, maxSize),
				rand_range(minLife, maxLife),
				rand_range(minSpeed, maxSpeed),
				minCourseLength, maxCourseLength,
				i, st))
	
	mesh = st.commit(null, Mesh.ARRAY_FORMAT_VERTEX & Mesh.ARRAY_FORMAT_NORMAL
			& Mesh.ARRAY_FORMAT_COLOR & Mesh.ARRAY_FORMAT_TEX_UV & Mesh.ARRAY_FORMAT_INDEX)
	mdt = MeshDataTool.new()
	mdt.create_from_surface(mesh, 0)
	set_process(true)


func _process(delta):
	var numAlive = 0
	var camLoc = global_transform.xform_inv(cam.get_global_transform().origin)
	for p in particles:
		if p.update(delta, mdt, camLoc,
				fadeInPerc, fadeOutPerc):
			numAlive += 1
	
	mesh.surface_remove(0)
	mdt.commit_to_surface(mesh)
	
	if numAlive == 0:
		queue_free()


class Particle:
	var trans = Transform(Basis(Vector3(1, 0, 0),
						Vector3(0, 1, 0),
						Vector3(0, 0, 1)))
	var speed
	var velocity
	var pVelocity = Vector3(0, 0, 0)
	var size
	
	var lifespan
	var tmeAlive = 0.0
	
	var courseTme = 0.0
	var courseLength
	var minCourseLength
	var maxCourseLength
	
	var idx
	
	
	func _init(location, pSize, lifespan, speed, 
			minLength, maxLength, arrayIdx, st):
		idx = arrayIdx
		trans.origin = location
		size = pSize * 0.5
		self.lifespan = lifespan
		self.speed = speed
		minCourseLength = minLength
		maxCourseLength = maxLength
		courseLength = rand_range(minCourseLength, maxCourseLength)
		
		velocity = Vector3(0, 0, speed)
		var basis = Basis(Vector3(0, 1, 0), rand_range(-PI, PI))
		basis = basis.rotated(Vector3(1, 0, 0), rand_range(-PI, PI))
		basis = basis.rotated(Vector3(0, 0, 1), rand_range(-PI, PI))
		velocity = basis.xform(velocity)
		
		#Lower Right
		var vert = trans.xform(Vector3(size, -size, 0))
		st.add_normal(Vector3(0, 0, -1))
		st.add_uv(Vector2(0, 0))
		st.add_color(Color(1, 1, 1, 0))
		st.add_vertex(vert)
		
		#Lower Left
		vert = trans.xform(Vector3(-size, -size, 0))
		st.add_normal(Vector3(0, 0, -1))
		st.add_uv(Vector2(1, 0))
		st.add_color(Color(1, 1, 1, 0))
		st.add_vertex(vert)
		
		#Upper Left
		vert = trans.xform(Vector3(-size, size, 0))
		st.add_normal(Vector3(0, 0, -1))
		st.add_uv(Vector2(1, 1))
		st.add_color(Color(1, 1, 1, 0))
		st.add_vertex(vert)
		
		#Upper Right
		vert = trans.xform(Vector3(size, size, 0))
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
	
	
	func update(delta, mdt, camLoc,
			fadeInPerc, fadeOutPerc):
		if tmeAlive >= lifespan:
			return false
		
		tmeAlive += delta
		var perc = min(tmeAlive / lifespan, 1.0)
		
		var alpha = 1.0
		if perc < fadeInPerc:
			alpha = Math.fsmooth(0.0, 1.0, perc / fadeInPerc)
		elif perc >= (1.0 - fadeOutPerc):
			alpha = Math.fsmooth(1.0, 0.0, (perc - (1.0 - fadeOutPerc)) / fadeOutPerc)
		
		courseTme += delta
		if courseTme >= courseLength:
			courseTme -= floor(courseTme / courseLength) * courseLength
			courseLength = rand_range(minCourseLength, maxCourseLength)
			pVelocity = Vector3(velocity.x, velocity.y, velocity.z)
			var basis = Basis(Vector3(0, 1, 0), rand_range(-PI, PI))
			basis = basis.rotated(Vector3(1, 0, 0), rand_range(-PI, PI))
			basis = basis.rotated(Vector3(0, 0, 1), rand_range(-PI, PI))
			velocity = basis.xform(velocity)
		
		perc = courseTme / courseLength
		trans.origin += Math.fsmooth(pVelocity, velocity, perc) * delta
		trans = trans.looking_at(camLoc, Vector3(0, 0, 1))
		
		var ofs = idx * 4
		var vert = trans.xform(Vector3(size, -size, 0))
		mdt.set_vertex(ofs, vert)
		vert = trans.xform(Vector3(-size, -size, 0))
		mdt.set_vertex(ofs + 1, vert)
		vert = trans.xform(Vector3(-size, size, 0))
		mdt.set_vertex(ofs + 2, vert)
		vert = trans.xform(Vector3(size, size, 0))
		mdt.set_vertex(ofs + 3, vert)
		
		mdt.set_vertex_color(ofs, Color(1, 1, 1, alpha))
		mdt.set_vertex_color(ofs + 1, Color(1, 1, 1, alpha))
		mdt.set_vertex_color(ofs + 2, Color(1, 1, 1, alpha))
		mdt.set_vertex_color(ofs + 3, Color(1, 1, 1, alpha))
		
		return tmeAlive < lifespan
