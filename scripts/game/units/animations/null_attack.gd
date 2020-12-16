extends Reference

var fin = false setget set_finished, is_finished

func update(delta):
	return fin


func set_finished(finished : bool):
	fin = finished


func is_finished() -> bool:
	return fin
