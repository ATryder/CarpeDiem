extends Reference
class_name MethodRef

var cls : Object
var method : String
var args := []


func _init(object : Object, function : String,
		arguments := []):
	cls = object
	method = function
	args = arguments


func exec():
	match(args.size()):
		0:
			cls.call(method)
		1:
			cls.call(method, args[0])
		2:
			cls.call(method, args[0], args[1])
		3:
			cls.call(method, args[0], args[1], args[2])
		_:
			cls.call(method, args)
