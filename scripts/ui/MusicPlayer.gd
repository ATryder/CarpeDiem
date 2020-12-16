extends Panel

const MARQUEE_DELAY := 0.7

onready var position = get_node("Position")
onready var track = get_node("Track")

onready var playButton = get_node("PlayButton")
onready var playOn = get_node("PlayOn")

var marqTme = 0.0
var marqForward := true
var trackNameOffset := 0
var trackName := "" setget set_track

var lastMins := 0
var lastSecs := 0

var inAnim : ControlTrans_CheckerWipe
var outAnim : ControlTrans_CheckerWipe
var opening := false
var closing := false


func _ready():
	if Music.gameStopped:
		playOn.hide()
		playButton.show()
	
	if Music.TRACKS.has(Music.gameTrack):
		set_track(Music.TRACKS[Music.gameTrack])
	Music.connect("GameTrackChanged", self, "set_track")
	
	inAnim = ControlTrans_CheckerWipe.new()
	inAnim.length = 0.5
	inAnim.grid = Vector2(8, 4)
	inAnim.squareLength = 0.12
	inAnim.trailingFade = 0.95
	inAnim.edgeSize = 0.05
	inAnim.color = Color(0, 1, 0, 1)
	inAnim.callback = [self, "_on_anim_finished"]
	inAnim.freeOnEnd = false
	
	outAnim = ControlTrans_CheckerWipe.new()
	outAnim.length = 0.5
	outAnim.grid = Vector2(8, 4)
	outAnim.squareLength = 0.12
	outAnim.trailingFade = 0.95
	outAnim.edgeSize = 0.05
	outAnim.color = Color(0, 1, 0, 1)
	outAnim.angle = PI
	outAnim.callback = [self, "_on_anim_finished"]
	outAnim.freeOnEnd = false
	outAnim.reverse = true
	outAnim.keepOutControl = true
	
	inAnim.set_control(self)
	outAnim.set_control(self)
	
	if Opts.theme != Opts.THEME_LIGHT:
		change_theme(Opts.THEME_LIGHT, Opts.theme)


func set_track(trkName : String):
	trackName = trkName
	trackNameOffset = 0
	marqTme = 0.0
	marqForward = true
	if trkName.length() > 11:
		track.text = trkName.substr(0, 11)
	else:
		track.text = trkName
	
	lastMins = 0
	lastSecs = 0
	position.text = "00:00"


func _process(delta):
	if Music.track != Music.gameTrack:
		return
	
	if trackName.length() > 11:
		marqTme += delta
		if marqTme >= MARQUEE_DELAY:
			var advance = int(floor(marqTme / MARQUEE_DELAY))
			marqTme -= advance * MARQUEE_DELAY
			if marqForward:
				if trackName.length() - (trackNameOffset + advance) < 11:
					marqForward = false
					advance = advance - (11 - (trackName.length() - trackNameOffset))
					trackNameOffset -= advance
				else:
					trackNameOffset += advance
			else:
				if trackNameOffset - advance < 0:
					marqForward = true
					advance = abs(trackNameOffset - advance)
					trackNameOffset += advance
				else:
					trackNameOffset -= advance
			track.text = trackName.substr(trackNameOffset, 11)
	
	if Music.is_playing():
		var pos = Music.player.get_playback_position()
		var minutes = int(floor(pos / 60))
		var seconds = int(floor(pos - (minutes * 60)))
		
		if lastMins != minutes || lastSecs != seconds:
			lastMins = minutes
			lastSecs = seconds
			position.text = "%02d:%02d" % [minutes, seconds]


func _on_Pause():
	Audio.play_click()
	Music.pause_game_track()
	playOn.hide()
	playButton.show()


func _on_Back():
	Audio.play_click()
	Music.play_previous_game_track()
	playOn.show()
	playButton.hide()


func _on_Stop():
	Audio.play_click()
	Music.stop_game_track()
	playOn.hide()
	playButton.show()
	position.text = "00:00"


func _on_Forward():
	Audio.play_click()
	Music.play_next_game_track()
	playOn.show()
	playButton.hide()


func _on_Play():
	Audio.play_click()
	Music.play_game_track()
	playOn.show()
	playButton.hide()


func open():
	if opening:
		return
	
	if closing:
		closing = false
		outAnim.stop()
		outAnim.parent.remove_child(outAnim)
	
	inAnim.grid = inAnim.grid
	opening = true
	show()
	inAnim.to_start()
	inAnim.play(true, true)


func close():
	if closing:
		return
	
	if opening:
		inAnim.stop()
		opening = false
		inAnim.parent.remove_child(inAnim)
	
	outAnim.grid = outAnim.grid
	closing = true
	outAnim.to_start()
	outAnim.play(true, true)


func _on_anim_finished(anim):
	if closing:
		hide()
		closing = false
	else:
		opening = false


func is_open():
	return visible && !closing


func change_theme(oldTheme, newTheme):
	if newTheme == Opts.THEME_LIGHT:
		add_stylebox_override("panel", load("res://styles/window/MusicPlayer.stylebox"))
		playOn.get_node("PlayOnHighlight").texture = load("res://textures/UI/music player/play_blue.atlastex")
	else:
		add_stylebox_override("panel", load("res://styles/window/MusicPlayer_Dark.stylebox"))
		playOn.get_node("PlayOnHighlight").texture = load("res://textures/UI/music player/play_green.atlastex")


func cleanup():
	Music.disconnect("GameTrackChanged", self, "set_track")
	if inAnim.get_parent() == null:
		inAnim.free()
	if outAnim.get_parent() == null:
		outAnim.free()
