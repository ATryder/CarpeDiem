extends Emitter
class_name MeshEmitter

var mesh : Mesh


func _init(mesh : Mesh, offset := Vector3(0, 0, 0)).(offset):
	self.mesh = mesh


func get_point():
	var faces = mesh.get_faces()
	var faceIdx = (randi() % (faces.size() / 3)) * 3
	var pos = faces[faceIdx]
	pos += (faces[faceIdx + 1] - pos) * randf()
	pos += (faces[faceIdx + 2] - pos) * randf()
	
	return pos + location
