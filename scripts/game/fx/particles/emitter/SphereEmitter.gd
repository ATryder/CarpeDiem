extends Emitter
class_name SphereEmitter

var radius
var circumference

func _init(radius = 1.0,
		onCircumference = false,
		location = Vector3(0, 0, 0)).(location):
	self.radius = radius
	circumference = onCircumference

func get_point():
	var loc
	if !circumference:
		loc = Vector3(0, 0, rand_range(0, radius))
	else:
		loc = Vector3(0, 0, radius)
	var basis = Basis(Vector3(0, 1, 0), rand_range(-PI, PI))
	basis = basis.rotated(Vector3(1, 0, 0), rand_range(-PI, PI))
	return basis.xform(loc) + location
