extends Spatial

const MSGDIALOG = preload("res://scenes/UI/dialog/MessageDialog.tscn")

const TITLE_DELAY := 2.5

onready var button_new = get_node("MarginContainer/VBoxContainer/PanelContainer/Buttons/Button_New")
onready var button_prologue = get_node("MarginContainer/VBoxContainer/PanelContainer/Buttons/Button__Prologue")
onready var button_load = get_node("MarginContainer/VBoxContainer/PanelContainer/Buttons/Button_Load")
onready var button_options = get_node("MarginContainer/VBoxContainer/PanelContainer/Buttons/Button_Options")
onready var button_credits = get_node("MarginContainer/VBoxContainer/PanelContainer/Buttons/Button_Credits")

onready var windowArea = get_node("MarginContainer/VBoxContainer/MarginContainer/WindowArea")
onready var dialogs = get_node("MarginContainer/VBoxContainer/MarginContainer/DialogArea")

var titleTme := 0.0

var colorCombos := [Vector2i.new(CD.ARENA_BLUE, CD.ARENA_CYAN),
					Vector2i.new(CD.ARENA_CYAN, CD.ARENA_GREEN),
					Vector2i.new(CD.ARENA_PURPLE, CD.ARENA_GREEN),
					Vector2i.new(CD.ARENA_PURPLE, CD.ARENA_BLUE),
					Vector2i.new(CD.ARENA_BLUE, CD.ARENA_GREEN),
					Vector2i.new(CD.ARENA_PURPLE, CD.ARENA_RED),
					Vector2i.new(CD.ARENA_ORANGE, CD.ARENA_CYAN),
					Vector2i.new(CD.ARENA_RED, CD.ARENA_YELLOW),
					Vector2i.new(CD.ARENA_ORANGE, CD.ARENA_RED),
					Vector2i.new(CD.ARENA_ORANGE, CD.ARENA_YELLOW),
					Vector2i.new(CD.ARENA_BROWN, CD.ARENA_ORANGE)]

var cloudGrads := []
var playerColors := []

var menu

var disabled := false setget set_disabled, is_disabled


func _ready():
	Music.play_mainmenu()
	
	get_node("MarginContainer/MarginContainer/Version_Label").text = "v%s" % CD.VERSION
	
	var curtainControl = get_node("CurtainArea/CurtainControl")
	curtainControl.menuControl = self
	if curtainControl.error == null || curtainControl.error.empty():
		curtainControl.remove_child(curtainControl.get_node("VBoxContainer"))
	else:
		curtainControl.get_node("VBoxContainer/Label").text = tr("label_error")
	
	for combo in colorCombos:
		var gradient := Gradient.new()
		gradient.set_color(0, CD.get_arena_color(combo.x))
		gradient.set_color(1, CD.get_arena_color(combo.y))
		
		var img = Image.new()
		img.create(148, 16, false, Image.FORMAT_RGB8)
		img.lock()
		for y in range(img.get_height()):
			for x in range(img.get_width()):
				img.set_pixel(x, y, gradient.interpolate(float(x) / (img.get_width() - 1)))
		img.unlock()
		var imgTex = ImageTexture.new()
		imgTex.create_from_image(img, 0)
		cloudGrads.push_back(imgTex)
	
	for i in range(7):
		var color = CD.get_player_color(i)
		var img = Image.new()
		img.create(148, 16, false, Image.FORMAT_RGB8)
		img.fill(color)
		var imgTex = ImageTexture.new()
		imgTex.create_from_image(img, 0)
		playerColors.push_back(imgTex)


func set_disabled(disable : bool):
	if menu != null:
		menu.disabled = disable
	
	var buttons = get_node("MarginContainer/VBoxContainer/PanelContainer/Buttons")
	for button in buttons.get_children():
		if button.has_method("set_disabled"):
			button.set_disabled(disable)
	
	disabled = disable


func is_disabled() -> bool:
	return disabled


func _new(pressed : bool):
	Audio.play_click()
	
	if menu != null:
		menu.close()
	
	if !pressed:
		return
	
	if button_prologue.pressed:
		button_prologue.pressed = false
	if button_load.pressed:
		button_load.pressed = false
	if button_options.pressed:
		button_options.pressed = false
	if button_credits.pressed:
		button_credits.pressed = false
	
	menu = preload("res://scenes/UI/menus/NewGameMenu.tscn").instance()
	menu.menuControl = self
	windowArea.add_child(menu)


func _prologue(pressed):
	Audio.play_click()
	
	if menu != null:
		menu.close()
	
	if !pressed:
		return
	
	if button_new.pressed:
		button_new.pressed = false
	if button_load.pressed:
		button_load.pressed = false
	if button_options.pressed:
		button_options.pressed = false
	if button_credits.pressed:
		button_credits.pressed = false
	
	menu = preload("res://scenes/UI/menus/Prologue.tscn").instance()
	menu.menuControl = self
	windowArea.add_child(menu)


func _load(pressed : bool):
	Audio.play_click()
	
	if menu != null:
		menu.close()
	
	if !pressed:
		return
	
	if button_new.pressed:
		button_new.pressed = false
	if button_prologue.pressed:
		button_prologue.pressed = false
	if button_options.pressed:
		button_options.pressed = false
	if button_credits.pressed:
		button_credits.pressed = false
	
	menu = preload("res://scenes/UI/menus/LoadSaveMenu.tscn").instance()
	menu.menuControl = self
	menu.set_load_only()
	windowArea.add_child(menu)


func _options(pressed : bool):
	Audio.play_click()
	
	if menu != null:
		menu.close()
	
	if !pressed:
		return
	
	if button_new.pressed:
		button_new.pressed = false
	if button_prologue.pressed:
		button_prologue.pressed = false
	if button_load.pressed:
		button_load.pressed = false
	if button_credits.pressed:
		button_credits.pressed = false
	
	menu = preload("res://scenes/UI/menus/OptionsMenu.tscn").instance()
	menu.menuControl = self
	windowArea.add_child(menu)


func _credits(pressed : bool):
	Audio.play_click()
	
	if menu != null:
		menu.close()
	
	if !pressed:
		return
	
	if button_new.pressed:
		button_new.pressed = false
	if button_load.pressed:
		button_load.pressed = false
	if button_options.pressed:
		button_options.pressed = false
	if button_prologue.pressed:
		button_prologue.pressed = false
	
	Music.pause_mainmenu()
	menu = preload("res://scenes/UI/credits/Credits.tscn").instance()
	menu.menuControl = self
	windowArea.add_child(menu)


func _quit():
	Audio.play_click()
	var dialog = message(tr("message_quit"), tr("label_quit"))
	dialog.set_positive_button(MethodRef.new(self, "quit_game"))
	dialog.set_negative_button(MethodRef.new(self, "close_dialog", [dialog]))


func quit_game():
	print_debug("Saving settings: " + str(Opts.save_settings()))
	get_tree().quit()


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
	get_node("CurtainArea").add_child(curtain)
	
	return curtain


func _process(delta):
	titleTme += delta
	if titleTme >= TITLE_DELAY:
		var title = get_node("TitleArea/Title")
		title.show()
		var anim = get_node("TitleArea/Title/ControlTrans_Blinds")
		anim.set_control(title)
		anim.play()
		set_process(false)


func _input(event):
	if event is InputEventAction && event.action.begins_with("error_"):
		var msg = error(event.action.substr(6))
		msg.anim._process(0.001)
		get_tree().set_input_as_handled()
