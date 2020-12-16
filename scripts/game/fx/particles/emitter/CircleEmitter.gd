extends Emitter
class_name CircleEmitter

enum {
	AXIS_XZ,
	AXIS_XY,
	AXIS_YZ
	}

var radius
var axis
var circumference


func _init(radius = 1.0, axis = AXIS_XZ,
		onCircumference = false,
		location = Vector3(0, 0, 0)).(location):
	self.radius = radius
	self.axis = axis
	circumference = onCircumference


func get_point():
	var loc
	var basis
	match axis:
		AXIS_XZ:
			if !circumference:
				loc = Vector3(0, 0, rand_range(0, radius))
			else:
				loc = Vector3(0, 0, radius)
			basis = Basis(Vector3(0, 1, 0), rand_range(-PI, PI))
		AXIS_XY:
			if !circumference:
				loc = Vector3(0, rand_range(0, radius), 0)
			else:
				loc = Vector3(0, radius, 0)
			basis = Basis(Vector3(0, 0, 1), rand_range(-PI, PI))
		AXIS_YZ:
			if !circumference:
				loc = Vector3(0, 0, rand_range(0, radius))
			else:
				loc = Vector3(0, 0, radius)
			basis = Basis(Vector3(1, 0, 0), rand_range(-PI, PI))
		_:
			if !circumference:
				loc = Vector3(0, 0, rand_range(0, radius))
			else:
				loc = Vector3(0, 0, radius)
			basis = Basis(Vector3(0, 1, 0), rand_range(-PI, PI))
	
	return basis.xform(loc) + location
