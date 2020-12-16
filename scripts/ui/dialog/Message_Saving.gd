extends PanelContainer_Themeable

var saveMenu
var saveFileName : String

onready var inAnim : ControlTrans_ContraBlinds = get_node("ControlTrans_ContraBlinds")
var outAnim : ControlTrans_ContraBlinds

var step := 0

var err := OK


func _ready():
	Audio.play_notify()
	outAnim = inAnim.duplicate()
	inAnim.callback = [self, "_on_display"]
	
	set_process(false)


func _on_display(anim):
	set_process(true)


func save(game, filename) -> int:
	if !filename.to_lower().ends_with("." + SavedGame.EXTENSION):
		filename = "%s.%s" % [filename, SavedGame.EXTENSION]
	
	return CDIO.save_file(game, filename)


func close():
	set_process(false)
	outAnim.reverse = true
	outAnim.reattach = false
	outAnim.set_control(self)
	outAnim.play()


func _process(delta):
	if step == 1:
		if saveFileName == null:
			saveMenu.menuControl.close_dialog(self)
			return
		err = save(get_node("/root/Game"), saveFileName)
	elif step == 2:
		saveMenu.menuControl.close_dialog(self)
		if err != OK:
			saveMenu.menuControl.error(tr("error_save") % [saveFileName, err])
		else:
			saveMenu.menuControl.close_dialog(self)
			saveMenu.close()
	
	step += 1
