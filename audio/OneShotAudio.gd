extends AudioStreamPlayer3D

export(float, 0.0, 1.0) var volume := 1.0 setget set_volume

var fadeIn := true
var fadeVolume := volume
var fadeLength := 1.0
var fadeTme := 0.0


func _ready():
	unit_size = 150
	connect("finished", self, "_done")
	set_process(false)


func set_volume(value : float):
	volume = value
	unit_db = linear2db(volume)
	if !is_processing():
		fadeVolume = volume


func _process(delta):
	fadeTme += delta
	
	if fadeTme >= fadeLength:
		if fadeIn:
			set_process(false)
			unit_db = linear2db(volume)
			fadeVolume = volume
		else:
			queue_free()
		return
	
	if fadeIn:
		fadeVolume = lerp(0.0, volume, fadeTme / fadeLength)
	else:
		fadeVolume = volume - lerp(0.0, volume, fadeTme / fadeLength)
	unit_db = linear2db(fadeVolume)


func fade_in(var length):
	fadeIn = true
	fadeTme = 0.0
	fadeLength = length
	fadeVolume = 0.0
	unit_db = linear2db(0.0)
	set_process(true)


func fade_out(var length):
	fadeIn = false
	fadeTme = 0.0
	fadeLength = length
	volume = fadeVolume
	set_process(true)


func _done():
	queue_free()
