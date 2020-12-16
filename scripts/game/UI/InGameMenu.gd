extends MarginContainer

const MSGDIALOG = preload("res://scenes/UI/dialog/MessageDialog.tscn")

onready var button_saveload = get_node("MarginContainer/VBoxContainer/Buttons/Button_SaveLoad")
onready var button_options = get_node("MarginContainer/VBoxContainer/Buttons/Button_Options")

onready var windowArea = get_node("MarginContainer/VBoxContainer/MarginContainer/WindowArea")
onready var dialogs = get_node("MarginContainer/VBoxContainer/MarginContainer/DialogArea")

onready var inAnim : ControlTrans_ColumnWipe = get_node("ControlTrans_ColorColumns")
var outAnim : ControlTrans_ColumnWipe

onready var curtain = get_node("/root/Game").hud.get_node("Curtain")

var menu

var animating := true

var disabled := false setget set_disabled, is_disabled


func _ready():
	Music.play_ingamemenu()
	outAnim = inAnim.duplicate()
	inAnim.callback = [self, "_on_display"]
	
	if !get_node("/root/Game").is_local_turn():
		button_saveload.set_disabled(true)


func set_disabled(disable : bool):
	if menu != null:
		menu.disabled = disable
	
	var buttons = get_node("MarginContainer/VBoxContainer/Buttons")
	for button in buttons.get_children():
		if button == button_saveload:
			if !disable:
				button.set_disabled(!get_node("/root/Game").is_local_turn())
			else:
				button.set_disabled(true)
		elif button.has_method("set_disabled"):
			button.set_disabled(disable)
	
	disabled = disable


func is_disabled() -> bool:
	return disabled


func _resume():
	Audio.play_click()
	Music.play_game()
	get_parent().get_parent().enable_hud()
	get_tree().set_pause(false)
	close()


func _saveload(pressed : bool):
	Audio.play_click()
	
	if menu != null:
		menu.close()
	
	if !pressed:
		return
	
	if button_options.pressed:
		button_options.pressed = false
	
	menu = preload("res://scenes/UI/menus/LoadSaveMenu.tscn").instance()
	menu.menuControl = self
	windowArea.add_child(menu)


func _options(pressed : bool):
	Audio.play_click()
	
	if menu != null:
		menu.close()
	
	if !pressed:
		return
	
	if button_saveload.pressed:
		button_saveload.pressed = false
	
	menu = preload("res://scenes/UI/menus/OptionsMenu.tscn").instance()
	menu.menuControl = self
	windowArea.add_child(menu)


func _mainmenu():
	Audio.play_click()
	var dialog = message(tr("message_return_mainmenu"), tr("label_mainmenu"))
	dialog.set_positive_button(MethodRef.new(self, "return_to_mainmenu", [dialog]), tr("label_yes"))
	dialog.set_negative_button(MethodRef.new(self, "close_dialog", [dialog]))


func return_to_mainmenu(dialog):
	Music.play_mainmenu()
	close_dialog(dialog)
	var curtain = instance_curtain()
	curtain.remove_child(curtain.get_node("VBoxContainer"))


func _quit():
	Audio.play_click()
	var dialog = message(tr("message_quit"), tr("label_quit"))
	dialog.set_positive_button(MethodRef.new(self, "quit_game"), tr("label_yes"))
	dialog.set_negative_button(MethodRef.new(self, "close_dialog", [dialog]))


func quit_game():
	var game = get_node("/root/Game")
	if game != null:
		game.finish_threads_and_block()
	print_debug("Saving settings: " + str(Opts.save_settings()))
	get_tree().quit()


func _on_display(anim):
	get_node("MarginContainer/VBoxContainer/Buttons/Button_Resume").grab_focus()
	animating = false


func close():
	for win in windowArea.get_children():
		if win is ControlTransition:
			win.pause()
			win.playOnStart = false
	for dialog in dialogs.get_children():
		if dialog is ControlTransition:
			dialog.pause()
			dialog.playOnStart = false
	
	animating = true
	outAnim.reverse = true
	outAnim.reattach = false
	outAnim.set_control(self)
	outAnim.play()


func add_dialog(dialog : Control):
	dialogs.mouse_filter = Control.MOUSE_FILTER_STOP
	set_disabled(true)
	dialogs.add_child(dialog)


func close_dialog(dialog : Control, enableMenu := true):
	if dialog.has_method("close"):
		if dialogs.get_child_count() == 1:
			dialogs.mouse_filter = Control.MOUSE_FILTER_IGNORE
			if enableMenu:
				set_disabled(false)
		dialog.close()
	elif dialogs.get_children().has(dialog):
		if dialogs.get_child_count() == 1:
			dialogs.mouse_filter = Control.MOUSE_FILTER_IGNORE
			if enableMenu:
				set_disabled(false)
		dialogs.remove_child(dialog)


func message(message : String, title = null) -> MessageDialog:
	var msgDisplay := MSGDIALOG.instance() as MessageDialog
	msgDisplay.set_content(message, title)
	msgDisplay.set_dismiss_only(MethodRef.new(self, "close_dialog", [msgDisplay]))
	add_dialog(msgDisplay)
	return msgDisplay


func error(message : String, title = tr("label_error")) -> MessageDialog:
	var msgDisplay := message(message, title)
	msgDisplay.set_alert_colors()
	return msgDisplay


func instance_curtain():
	set_disabled(true)
	
	var curtain = load("res://scenes/UI/CurtainControl.tscn").instance()
	curtain.menuControl = self
	get_node("/root/Game/HUDLayer/CurtainArea").add_child(curtain)
	
	return curtain


func _input(event : InputEvent):
	if disabled || animating:
		return
	
	if event.is_action_released("game_menu"):
		_resume()
		get_tree().set_input_as_handled()
		return
