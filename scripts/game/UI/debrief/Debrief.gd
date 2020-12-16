extends PanelContainer_Themeable

enum {
	DISPLAY_ORE,
	DISPLAY_ENERGY,
	DISPLAY_SHIPS,
	DISPLAY_STATIONS,
	DISPLAY_REPLAY
}

var hudButton

var players

onready var displayArea = get_node("VBoxContainer/DisplayArea")
onready var replay = displayArea.get_node("Replay")

var displayPadding := 5
var display = DISPLAY_ORE

var lines : Dictionary
var activeLines : Array
var replayFrames

var opening := false
var closing := false
onready var inAnim : ControlTransition = get_node("inAnim")
onready var outAnim : ControlTransition = get_node("outAnim")


func _ready():
	if inAnim.get_parent() != self:
		return
	
	replay.frames = replayFrames
	replayFrames = null
	
	var game = get_node("/root/Game")
	if !game.players[game.thisPlayer].is_alive():
		add_stylebox_override("panel", CD.get_window_background_style(true, Opts.theme))
	
	inAnim.callback = [self, "_on_anim_finished"]
	inAnim.set_control(self)
	remove_child(inAnim)
	outAnim.callback = [self, "_on_anim_finished"]
	outAnim.set_control(self)
	remove_child(outAnim)
	
	if lines != null:
		for k in lines:
			for line in lines[k]:
				displayArea.add_child(line)
				line.hide()


func _on_anim_finished(anim):
	if opening:
		opening = false
		match display:
			DISPLAY_ORE:
				_toggle_ore(true, false)
			DISPLAY_ENERGY:
				_toggle_energy(true, false)
			DISPLAY_SHIPS:
				_toggle_ships(true, false)
			DISPLAY_STATIONS:
				_toggle_stations(true, false)
			DISPLAY_REPLAY:
				_toggle_replay(true, false)
	else:
		closing = false


func open(playClick = true):
	if playClick:
		Audio.play_click()
	
	if opening:
		return
	
	if closing:
		closing = false
		outAnim.stop()
		outAnim.parent.remove_child(outAnim)
	
	if display != DISPLAY_REPLAY:
		for line in activeLines:
			line.hide()
		activeLines.clear()
	
	hudButton.disconnect("button_up", self, "open")
	hudButton.connect("button_up", self, "close")
	opening = true
	inAnim.to_start()
	inAnim.play(true, true)


func close(playClick = true):
	if playClick:
		Audio.play_click()
	
	if closing:
		return
	
	if opening:
		opening = false
		inAnim.stop()
		inAnim.parent.remove_child(inAnim)
	
	if display == DISPLAY_REPLAY:
		replay._pause()
	
	hudButton.disconnect("button_up", self, "close")
	hudButton.connect("button_up", self, "open")
	closing = true
	outAnim.to_start()
	outAnim.play(true, true)


func _toggle_ore(button_pressed, playClick := true):
	if playClick:
		Audio.play_click()
	
	if !button_pressed:
		return
	
	if display == DISPLAY_REPLAY:
		replay._pause()
		replay.hide()
	for line in activeLines:
		line.hide()
	
	activeLines.clear()
	for line in lines.incomeOre:
		line.show()
		line.play()
		activeLines.push_back(line)
	
	display = DISPLAY_ORE


func _toggle_energy(button_pressed, playClick := true):
	if playClick:
		Audio.play_click()
	
	if !button_pressed:
		return
	
	if display == DISPLAY_REPLAY:
		replay._pause()
		replay.hide()
	for line in activeLines:
		line.hide()
	
	activeLines.clear()
	for line in lines.incomeEnergy:
		line.show()
		line.play()
		activeLines.push_back(line)
	
	display = DISPLAY_ENERGY


func _toggle_ships(button_pressed, playClick := true):
	if playClick:
		Audio.play_click()
	
	if !button_pressed:
		return
	
	if display == DISPLAY_REPLAY:
		replay._pause()
		replay.hide()
	for line in activeLines:
		line.hide()
	
	activeLines.clear()
	for line in lines.totalShips:
		line.show()
		line.play()
		activeLines.push_back(line)
	
	display = DISPLAY_SHIPS


func _toggle_stations(button_pressed, playClick := true):
	if playClick:
		Audio.play_click()
	
	if !button_pressed:
		return
	
	if display == DISPLAY_REPLAY:
		replay._pause()
		replay.hide()
	for line in activeLines:
		line.hide()
	
	activeLines.clear()
	for line in lines.totalStations:
		line.show()
		line.play()
		activeLines.push_back(line)
	
	display = DISPLAY_STATIONS


func _toggle_replay(button_pressed, playClick := true):
	if playClick:
		Audio.play_click()
	
	if !button_pressed || replay.is_visible():
		return
	
	display = DISPLAY_REPLAY
	
	for line in activeLines:
		line.hide()
	activeLines.clear()
	
	replay.show()
	
	if replay.firstFrameVP != null:
		replay.firstFrameVP.render_target_update_mode = Viewport.UPDATE_ONCE
		replay.vpFrame.render_target_update_mode = Viewport.UPDATE_ONCE
		replay.vpFrame.render_target_clear_mode = Viewport.CLEAR_MODE_ONLY_NEXT_FRAME
		replay.firstFrameVP.get_child(0).refresh = true
		replay.firstFrameVP.get_child(0).update()
		replay.firstFrameVP = null


func _main_menu():
	Audio.play_click()
	Music.play_mainmenu()
	var curtain = load("res://scenes/UI/CurtainControl.tscn").instance()
	curtain.remove_child(curtain.get_node("VBoxContainer"))
	curtain.menuControl = self
	get_node("/root/Game/HUDLayer/CurtainArea").add_child(curtain)


func cleanup():
	if inAnim.get_parent() == null:
		inAnim.free()
	
	if outAnim.get_parent() == null:
		outAnim.free()
