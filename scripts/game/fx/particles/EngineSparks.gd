extends MeshInstance
class_name EngineSparks

export(int) var particlesPerSecond = 5
export(float) var emitterRadius = 0.1
export(float) var minLife = 0.5
export(float) var maxLife = 2.0
export(float) var minSpeed = 2.0
export(float) var maxSpeed = 5.0
export(float) var minSize = 0.12
export(float) var maxSize = 0.4
export(float) var minCourseLength = 0.18
export(float) var maxCourseLength = 0.36
export(float) var fadeOutPercent = 0.3

onready var emitterNode = get_node("../Emitter")

var particles = []
var emitter : Emitter
var cam : Camera

var particlesToSpawn := 1
var emitTme := 0.0
var emit := true

var mdt : MeshDataTool


func _ready():
	if cam == null:
		cam = get_node("/root/Game/CameraControl").cam
	emitter = CircleEmitter.new(emitterRadius,
			CircleEmitter.AXIS_XY)


func init():
	if Opts.particleDetail == Opts.QUALITY_HIGH:
		particlesPerSecond *= 2
	elif Opts.particleDetail == Opts.QUALITY_XHIGH:
		particlesPerSecond *= 3
	
	var arrayLength = ceil(maxLife * particlesPerSecond)
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(arrayLength):
		var particle = Particle.new(Vector3(0, 0, 0),
				rand_range(minSize, maxSize),
				rand_range(minLife, maxLife),
				rand_range(minSpeed, maxSpeed),
				minCourseLength, maxCourseLength,
				i, st)
		particles.push_back(particle)
	mesh = st.commit(null, Mesh.ARRAY_FORMAT_VERTEX & Mesh.ARRAY_FORMAT_NORMAL
			& Mesh.ARRAY_FORMAT_TEX_UV & Mesh.ARRAY_FORMAT_COLOR
			& Mesh.ARRAY_FORMAT_INDEX)
	mdt = MeshDataTool.new()
	mdt.create_from_surface(mesh, 0)


func _process(delta):
	var camLoc = cam.get_global_transform().origin
	
	if emit:
		emitTme += delta
		var rate = 1.0 / particlesPerSecond
		if emitTme >= rate:
			particlesToSpawn = floor(emitTme / rate)
			emitTme = emitTme - (particlesToSpawn * rate)
	else:
		particlesToSpawn = 0
	
	var numAlive = 0
	for p in particles:
		if p.update(delta, mdt, camLoc,
				fadeOutPercent):
			numAlive += 1
		elif particlesToSpawn > 0:
			p.reset(emitterNode.global_transform.xform(emitter.get_point()),
					rand_range(minSize, maxSize),
					rand_range(minLife, maxLife),
					rand_range(minSpeed, maxSpeed))
			particlesToSpawn -= 1
		else:
			p.alive = false
	
	mesh.surface_remove(0)
	mdt.commit_to_surface(mesh)
	if numAlive == 0 and !emit:
		queue_free()


class Particle:
	var trans := Transform(Basis(Vector3(1, 0, 0),
						Vector3(0, 1, 0),
						Vector3(0, 0, 1)))
	var speed : float
	var velocity : Vector3
	var pVelocity := Vector3(0, 0, 0)
	var size : float
	
	var lifespan : float
	var tmeAlive := 0.0
	
	var courseTme := 0.0
	var courseLength : float
	var minCourseLength : float
	var maxCourseLength : float
	
	var idx : int
	
	var alive := false
	
	
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
	
	func reset(location, pSize, lifespan, speed):
		tmeAlive = 0.0
		trans.origin = location
		size = pSize * 0.5
		self.lifespan = lifespan
		self.speed = speed
		alive = true
	
	func update(delta, mdt, camLoc,
			fadeOutPerc):
		if !alive or tmeAlive >= lifespan:
			return false
		
		tmeAlive += delta
		var perc = min(tmeAlive / lifespan, 1.0)
		
		var alpha = 1.0
		if perc >= (1.0 - fadeOutPerc):
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
