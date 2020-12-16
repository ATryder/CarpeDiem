extends PanelContainer_Themeable

onready var counter = get_node("VBoxContainer/timer")

onready var inAnim : ControlTrans_ContraBlinds = get_node("ControlTrans_ContraBlinds")
var outAnim : ControlTrans_ContraBlinds

var setFullscreen := true
var setResolution : Vector2i

var optionsMenu

var limit := 10.0
var tme := 0.0

var cancel := false


func _ready():
	Audio.play_notify()
	set_process(false)
	counter.text = "10"
	outAnim = inAnim.duplicate()
	inAnim.callback = [self, "_on_display"]


func _on_display(anim):
	set_process(true)
	if setFullscreen:
		if setResolution != null:
			get_tree().connect("screen_resized", self, "_set_resolution", [], CONNECT_ONESHOT)
		OS.window_fullscreen = true
	elif setResolution != null:
		get_tree().get_root().size = Vector2(setResolution.x, setResolution.y)


func _set_resolution():
	get_tree().get_root().size = Vector2(setResolution.x, setResolution.y)


func _process(delta):
	if !cancel:
		tme += delta
		counter.text = str(int(ceil(max(limit - tme, 0))))
		if tme >= limit:
			_cancel()
	elif tme < 3.0:
		tme += 2.0
	else:
		optionsMenu.menuControl.close_dialog(self)


func close():
	set_process(false)
	outAnim.reverse = true
	outAnim.reattach = false
	outAnim.set_control(self)
	outAnim.play()


func _keep_settings():
	Audio.play_click()
	optionsMenu.menuControl.close_dialog(self)
	optionsMenu.save_and_close()


func _cancel():
	Audio.play_click()
	cancel = true
	tme = 0.0
	get_node("VBoxContainer/HBoxContainer/button_yes").disabled = true
	get_node("VBoxContainer/HBoxContainer/button_no").disabled = true
	optionsMenu.cancel_display_settings()
