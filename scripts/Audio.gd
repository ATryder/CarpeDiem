extends Node

var bus := {}

var playClick := true setget set_play_click


func _ready():
	for idx in range(AudioServer.bus_count):
		bus[AudioServer.get_bus_name(idx)] = idx


func set_bus_volume(name : String, volume : float):
	AudioServer.set_bus_volume_db(bus[name], volume)


func set_global_fx_volume(volume : float):
	set_fx_volume(volume)
	set_ui_volume(volume)


func set_global_music_volume(volume : float):
	set_music_volume(volume)
	set_ui_music_volume(volume)


func set_fx_volume(volume : float):
	set_bus_volume("FX", volume)


func set_music_volume(volume : float):
	set_bus_volume("Music", volume)


func set_ui_volume(volume : float):
	set_bus_volume("UIFX", volume)


func set_ui_music_volume(volume : float):
	set_bus_volume("UIMusic", volume)


func play_click():
	if playClick:
		play_sound(preload("res://audio/UI/ButtonClick.wav"))
		playClick = false
		call_deferred("set_play_click", true)


func set_play_click(value):
	playClick = value


func play_notify():
	play_sound(preload("res://audio/UI/Notify.wav"))


func play_swish():
	play_sound(preload("res://audio/UI/ToolBox_Swish.wav"))


func play_chime_in():
	play_sound(preload("res://audio/UI/ChimeIn.wav"))


func play_sound(sound):
	var asp = AudioStreamPlayer.new()
	asp.stream = sound
	asp.bus = "UIFX"
	asp.connect("finished", self, "_free_sound", [asp])
	asp.autoplay = true
	asp.pause_mode = PAUSE_MODE_PROCESS
	add_child(asp)


func _free_sound(audioStreamPlayer):
	audioStreamPlayer.queue_free()
