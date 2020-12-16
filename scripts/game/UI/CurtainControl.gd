extends PanelContainer

var menuControl

var savedFilename : String

export(bool) var fadeIn := true
export(bool) var gameIntro := false
export(bool) var initialIntro := false
var giCount := 0

export var colors := [Color(1, 1, 0, 1)]

onready var label = get_node("VBoxContainer/Label")
onready var progress = get_node("VBoxContainer/ProgressBar")

onready var inAnim : ControlTrans_Blinds = preload("res://scenes/UI/transition/Curtain_Blinds.tscn").instance()
onready var outAnim : ControlTrans_Blinds
var giAnim : ControlTrans_Wipe

var error : String = ""


func _ready():
	outAnim = inAnim.duplicate()
	outAnim.mouse_filter = MOUSE_FILTER_STOP
	
	if fadeIn:
		inAnim.callback = [self, "_on_display"]
		inAnim.color = Math.get_random_array_item(colors)
		inAnim.mouse_filter = MOUSE_FILTER_STOP
		inAnim.playOnStart = true
		add_child(inAnim)
	
	if !gameIntro:
		set_process(false)


func _on_display(anim = null):
	call_deferred("set_process", true)


func error_out(err : String):
	error = err
	outAnim.callback = [self, "_display_error"]
	close()


func _display_error(anim = null):
	var msgDisplay = menuControl.error(error)
	msgDisplay.get_parent().fit_child_in_rect(msgDisplay,
			Rect2(msgDisplay.get_parent().rect_position, msgDisplay.get_parent().rect_size))
	msgDisplay.anim.set_control(msgDisplay)
	msgDisplay.anim.play()


func close():
	if get_node("/root/Game") != null:
		Music.play_game()
	set_process(false)
	outAnim.reverse = true
	outAnim.reattach = false
	outAnim.color = Math.get_random_array_item(colors)
	outAnim.set_control(self)
	outAnim.play()


func _process(delta):
	if fadeIn:
		var game = get_node("/root/Game")
		if game != null:
			if game.finish_threads():
				set_process(false)
				if savedFilename != null && !savedFilename.empty():
					SceneLoader.initiate_load_scene(game,
													"res://scenes/Arena.tscn",
													self,
													savedFilename)
				else:
					SceneLoader.initiate_load_scene(game,
													"res://scenes/UI/menus/MainMenu.tscn",
													self)
		else:
			set_process(false)
			if savedFilename != null && ! savedFilename.empty():
				SceneLoader.initiate_load_scene(get_node("/root/MainMenu"),
												"res://scenes/Arena.tscn",
												self,
												savedFilename)
			else:
				SceneLoader.initiate_load_scene(get_node("/root/MainMenu"),
												"res://scenes/Arena.tscn",
												self)
	elif gameIntro:
		giCount += 1
		if giCount == 1:
			if initialIntro:
				giAnim = load("res://scenes/UI/transition/Curtain_Wipe.tscn").instance()
			else:
				giAnim = outAnim
				if error != null && !error.empty():
					outAnim.callback = [self, "_display_error"]
		elif giCount == 2:
			randomize()
			set_process(false)
			giAnim.set_control(self)
			giAnim.reattach = false
			giAnim.reverse = true
			giAnim.color = Math.get_random_array_item(colors)
			giAnim.play()
