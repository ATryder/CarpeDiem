extends Node

const FADE_LENGTH := 1.0
const TRACK_MAINMENU := "res://audio/Music/Chris_Zabriskie_-_06_-_Chance_Luck_Errors_in_Nature_Fate_Destruction_As_a_Finale.ogg"
const TRACK_INGAMEMENU := "res://audio/Music/Herr_Doktor_-_05_-_Interlude.ogg"

const TRACKS := {
				"res://audio/Music/Game/Herr_Doktor/Herr_Doktor_-_06_-_Revenge.ogg": "Herr Doktor - Revenge",
				"res://audio/Music/Game/Herr_Doktor/Herr_Doktor_-_08_-_So_Close.ogg": "Herr Doktor - So Close",
				"res://audio/Music/Game/Herr_Doktor/Herr_Doktor_-_04_-_Can_You_Kiss_Me_First_Synthwave_Cover.ogg": "Herr Doktor - Can You Kiss Me First Synthwave Cover",
				"res://audio/Music/Game/Herr_Doktor/Herr_Doktor_-_07_-_Neon_Riding.ogg": "Herr Doktor - Neon Riding",
				"res://audio/Music/Game/Herr_Doktor/Herr_Doktor_-_02_-_Time_for_Love.ogg": "Herr Doktor - Time for Love",
				"res://audio/Music/Game/Herr_Doktor/Herr_Doktor_-_05_-_The_Night_Heat.ogg": "Herr Doktor - The Night Heat",
				"res://audio/Music/Game/Herr_Doktor/Herr_Doktor_-_09_-_Moon_Garden_feat_Cavaliers_of_Fun_Reprise.ogg": 
				"Herr Doktor - Moon Garden feat Cavaliers of Fun Reprise",
				"res://audio/Music/Game/Ezylohm_tek/Ezylohm_tek_-_04_-_Mankind.ogg": "Ezylohm Tek - Mankind",
				"res://audio/Music/Game/Ezylohm_tek/Ezylohm_tek_-_05_-_Oceanids.ogg": "Ezylohm Tek - Oceanids",
				"res://audio/Music/Game/Sci_Fi_Industries/Sci_Fi_Industries_-_12_-_MAMO.ogg": "Sci-Fi Industries - M.A.M.O.",
				"res://audio/Music/Game/Sci_Fi_Industries/Sci_Fi_Industries_-_05_-_Status_Hex.ogg": "Sci-Fi Industries - Status Hex",
				"res://audio/Music/Game/Sci_Fi_Industries/Sci_Fi_Industries_-_04_-_Bault.ogg": "Sci-Fi Industries - Bault",
				"res://audio/Music/Game/Sci_Fi_Industries/Sci_Fi_Industries_-_01_-_Mount_Rey.ogg": "Sci-Fi Industries - Mount Rey",
				"res://audio/Music/Game/Sci_Fi_Industries/Sci_Fi_Industries_-_03_-_Unico_Universo.ogg": "Sci-Fi Industries - Unico Universo",
				"res://audio/Music/Game/Sci_Fi_Industries/Sci_Fi_Industries_-_10_-_Jyib.ogg": "Sci-Fi Industries - Jyib"
				}

var track := ""
var gameTrack := "" setget set_game_track
var player : AudioStreamPlayer

var mainmenuPosition := 0.0
var ingamemenuPosition := 0.0
var gamePosition := 0.0

var gameTracks := TRACKS.keys()
var gameStopped := false
var randTrackSpacer := []
var prevTracks := []
var queuePos := 0


func _init():
	add_user_signal("GameTrackChanged")


func play_mainmenu():
	if track == TRACK_MAINMENU:
		if is_playing():
			player.set_process(false)
			player.volume_db = linear2db(1.0)
			return
		
		var asp := get_asp(TRACK_MAINMENU, "UIMusic", true)
		if mainmenuPosition - 0.0 >= 0.00001:
			asp.fade_in(FADE_LENGTH)
		
		add_child(asp)
		asp.play(mainmenuPosition)
		player = asp
		return
	
	track = TRACK_MAINMENU
	ingamemenuPosition = 0.0
	gamePosition = 0.0
	var asp := get_asp(TRACK_MAINMENU, "UIMusic", true)
	if is_playing():
		player.fade_out(FADE_LENGTH)
		asp.fade_in(FADE_LENGTH)
	elif mainmenuPosition - 0.0 >= 0.00001:
		asp.fade_in(FADE_LENGTH)
	
	add_child(asp)
	asp.play(mainmenuPosition)
	player = asp


func pause_mainmenu():
	if !is_playing():
		return
	
	player.fade_out(FADE_LENGTH)


func play_ingamemenu():
	if !is_playing() || (track == TRACK_INGAMEMENU && is_playing()):
		return
	
	track = TRACK_INGAMEMENU
	var asp := get_asp(TRACK_INGAMEMENU, "UIMusic", true)
	player.fade_out(FADE_LENGTH)
	asp.fade_in(FADE_LENGTH)
	
	add_child(asp)
	asp.play(ingamemenuPosition)
	player = asp


func play_game():
	if (!gameStopped && gamePosition - 0.0 < 0.00001) || gameTrack.empty():
		self.gameTrack = get_random_game_track()
	
	if gameStopped:
		if is_playing():
			if track == TRACK_INGAMEMENU || track == TRACK_MAINMENU:
				player.fade_out(FADE_LENGTH)
				player = null
		return
	
	var asp = get_asp(gameTrack, "Music")
	if is_playing():
		if track == TRACK_INGAMEMENU || track == TRACK_MAINMENU:
			player.fade_out(FADE_LENGTH)
			asp.fade_in(FADE_LENGTH)
		else:
			asp.queue_free()
			return
	elif gamePosition - 0.0 >= 0.00001:
		asp.fade_in(FADE_LENGTH)
	
	track = gameTrack
	add_child(asp)
	asp.play(gamePosition)
	player = asp


func play_next_random_game_track():
	if is_playing():
		player.queue_free()
	
	if prevTracks.empty() || prevTracks[prevTracks.size() - 1] != gameTrack:
		if queuePos < prevTracks.size():
			prevTracks.resize(queuePos)
		prevTracks.push_back(gameTrack)
		if prevTracks.size() > 100:
			prevTracks.pop_front()
		queuePos = prevTracks.size()
	
	gameStopped = false
	gamePosition = 0.0
	self.gameTrack = get_random_game_track()
	track = gameTrack
	
	player = get_asp(track, "Music")
	add_child(player)
	player.play()


func set_game_track(trackName : String):
	gameTrack = trackName
	emit_signal("GameTrackChanged", TRACKS[gameTrack])


func get_asp(stream : String, bus := "Music", loop := false) -> AudioStreamPlayer:
	var asp = MusicStreamPlayer.new(stream, bus, loop)
	asp.connect("finished", self, "_free_sound", [asp])
	return asp


func is_playing() -> bool:
	return player != null


func play_game_track():
	if player != null || !TRACKS.has(gameTrack):
		return
	
	gameStopped = false
	track = gameTrack
	player = get_asp(track, "Music")
	add_child(player)
	player.play(gamePosition)


func play_next_game_track():
	queuePos = min(queuePos + 1, prevTracks.size())
	if queuePos == prevTracks.size():
		play_next_random_game_track()
		return
	
	if is_playing():
		player.queue_free()
	
	gameStopped = false
	self.gameTrack = prevTracks[queuePos]
	gamePosition = 0.0
	track = gameTrack
	
	player = get_asp(track, "Music")
	add_child(player)
	player.play()


func play_previous_game_track():
	if is_playing():
		player.queue_free()
	
	if queuePos == prevTracks.size() && !prevTracks.empty():
		prevTracks.push_back(gameTrack)
		if prevTracks.size() > 100:
			prevTracks.pop_front()
			queuePos -= 2
		else:
			queuePos -= 1
	elif queuePos > 0:
		queuePos -= 1
	
	if !prevTracks.empty():
		self.gameTrack = prevTracks[queuePos]
	gamePosition = 0.0
	track = gameTrack
	
	player = get_asp(track, "Music")
	add_child(player)
	player.play()


func pause_game_track():
	if player == null || !TRACKS.has(track):
		return
	
	gameStopped = true
	gamePosition = player.get_playback_position()
	player.queue_free()
	player = null


func stop_game_track():
	if player == null || !TRACKS.has(track):
		return
	
	gameStopped = true
	gamePosition = 0.0
	player.queue_free()
	player = null


func get_random_game_track() -> String:
	if gameTracks.has(gameTrack):
		randTrackSpacer.push_back(gameTrack)
		gameTracks.erase(gameTrack)
	if randTrackSpacer.size() >= 3:
		gameTracks.push_back(randTrackSpacer.pop_front())
	
	return Math.get_random_array_item(gameTracks)


func _free_sound(audioStreamPlayer):
	if player == audioStreamPlayer:
		player = null
	
	if audioStreamPlayer.track == TRACK_MAINMENU:
		mainmenuPosition = 0.0
	elif audioStreamPlayer.track == TRACK_INGAMEMENU:
		ingamemenuPosition = 0.0
	elif audioStreamPlayer.track == gameTrack:
		gamePosition = 0.0
		if track == gameTrack:
			play_next_random_game_track()
	
	audioStreamPlayer.set_process(false)
	audioStreamPlayer.queue_free()
