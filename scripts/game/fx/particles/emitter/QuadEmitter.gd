extends Emitter
class_name QuadEmitter

var p1 : Vector3
var p2 : Vector3
var p3 : Vector3
var p4 : Vector3


func _init(p1, p2, p3, p4,  offset := Vector3(0, 0, 0)).(offset):
	self.p1 = p1
	self.p2 = p2
	self.p3 = p3
	self.p4 = p4


func get_point():
	var point = Vector3(p1.x, p1.y, p1.z)
	point += (p2 - point) * randf()
	point += (p3 - point) * randf()
	point += (p4 - point) * randf()
	
	return point + location
