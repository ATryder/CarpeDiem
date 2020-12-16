extends Spatial

func _finish():
	get_parent().remove_child(self)
