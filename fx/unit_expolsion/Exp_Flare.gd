extends Node2D

var animation
var camcont

var worldLoc


func explode():
	if animation != null and animation.has_method("spawn_exp"):
		animation.spawn_exp()


func _process(delta):
	var s = Math.fsmooth_stop(0.5, 4, camcont.zoom)
	set_scale(Vector2(s, s))
	var loc = camcont.cam.unproject_position(worldLoc)
	transform.origin = Vector2(round(loc.x), round(loc.y))


func finish_flare():
	queue_free()
