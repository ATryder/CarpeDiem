extends Reference
class_name Emitter

var location


func _init(location):
	self.location = location


func get_point():
	return Vector3(location.x, location.y, location.z)
