extends AudioStreamPlayer
class_name MusicStreamPlayer

var track : String

var fadeLength : = -1.0
var fadeTme := 0.0
var fadeIn := true


func _init(streamPath : String, audioBus : String, loopAudio := false):
	track = streamPath
	stream = load(streamPath)
	stream.loop = loopAudio
	bus = audioBus
	pause_mode = PAUSE_MODE_PROCESS


func _ready():
	set_process(fadeLength > 0)


func fade_out(length : float):
	fadeLength = length
	fadeIn = false
	fadeTme = 0.0
	set_process(true)


func fade_in(length : float):
	fadeLength = length
	fadeIn = true
	volume_db = linear2db(0.0)
	fadeTme = 0.0
	set_process(true)


func _process(delta):
	fadeTme += delta
	
	if fadeTme >= fadeLength:
		if fadeIn:
			set_process(false)
			volume_db = linear2db(1.0)
		else:
			if Music.player == self:
				Music.player = null
			
			if track == Music.TRACK_MAINMENU:
				Music.mainmenuPosition = get_playback_position()
			elif track == Music.TRACK_INGAMEMENU:
				if Music.track != Music.TRACK_MAINMENU:
					Music.ingamemenuPosition = get_playback_position()
			elif track == Music.gameTrack && Music.track != Music.TRACK_MAINMENU:
				Music.gamePosition = get_playback_position()
			
			queue_free()
		return
	
	if fadeIn:
		volume_db = linear2db(lerp(0.0, 1.0, fadeTme / fadeLength))
	else:
		volume_db = linear2db(1.0 - lerp(0.0, 1.0, fadeTme / fadeLength))
