extends Spatial

onready var game = get_parent()
onready var curtainControl = get_node("/root/Game/HUDLayer/CurtainArea/CurtainControl")

var savedGame

var loaderClass = preload("res://scripts/game/generators/RandomSimplex.gd")
var loader
var loadStep := 0
var sectionPerc := 1.0

var dimensions = Vector2i.new(int(Opts.MAP_SIZES[Opts.mapSize].x),
							int(Opts.MAP_SIZES[Opts.mapSize].y))
var cloud1 := Opts.mapColor1
var cloud2 := Opts.mapColor2
var players := 4
var thisPlayer := Opts.playerNumber
var playerColor := Opts.playerColor


func _ready():
	players = Opts.get_players_for_map_size(Opts.mapSize)
	
	if savedGame != null:
		loader = SaveLoader.new(game.get_node("Arena"), savedGame)
		curtainControl.get_node("VBoxContainer/Label").text = tr("label_reading_save")
	else:
		loader = loaderClass.new(game.get_node("Arena"), dimensions.x, dimensions.y,
				cloud1, cloud2, players, thisPlayer, playerColor)
	game.rseed = loader.rseed
	
	loadStep = loader.loadStep
	sectionPerc = 1.0 / loader.totalSteps
	curtainControl.get_node("VBoxContainer/ProgressBar").value = sectionPerc * 100


func _process(delta):
	var fin = false
	var ldstp
	if loader.thread == null:
		fin = loader.load_step(delta)
		ldstp = loader.loadStep
		if loader.thread == null:
			if ldstp != loadStep:
				loadStep = ldstp
				curtainControl.label.text = loader.current_progress.section
			curtainControl.progress.value = ((loader.current_progress.progress * sectionPerc) + (loadStep * sectionPerc)) * 100
		elif loader.current_progress.try_lock() == OK:
			if ldstp != loadStep:
				loadStep = ldstp
				curtainControl.label.text = loader.current_progress.section
			curtainControl.progress.value = ((loader.current_progress.progress * sectionPerc) + (loadStep * sectionPerc)) * 100
			loader.current_progress.unlock()
	elif loader.current_progress.try_lock() == OK:
		if loader.current_progress.done == true:
			loader.current_progress.unlock()
			fin = loader.load_step(delta)
			ldstp = loader.loadStep
			if loader.thread == null:
				if ldstp != loadStep:
					loadStep = ldstp
					curtainControl.label.text = loader.current_progress.section
				curtainControl.progress.value = ((loader.current_progress.progress * sectionPerc) + (loadStep * sectionPerc)) * 100
			elif loader.current_progress.try_lock() == OK:
				if ldstp != loadStep:
					loadStep = ldstp
					curtainControl.label.text = loader.current_progress.section
				curtainControl.progress.value = ((loader.current_progress.progress * sectionPerc) + (loadStep * sectionPerc)) * 100
				loader.current_progress.unlock()
		else:
			curtainControl.progress.value = ((loader.current_progress.progress * sectionPerc) + (loadStep * sectionPerc)) * 100
			loader.current_progress.unlock()
	
	if fin:
		get_tree().call_group("load_wrap_up", "_load_wrap_up", loader)
		get_tree().call_group("notify_finish_load", "game_loaded", loader)
		set_process(false)
		curtainControl.call_deferred("close")
		game.emit_signal("game_loaded", game)
		call_deferred("launch_tutorial")
		queue_free()


func launch_tutorial():
	if !Opts.showTutorial || savedGame != null:
		return
	game.tutorial = Tutorial.new()
	game.tutorial.game = game
	game.tutorial.launch()
