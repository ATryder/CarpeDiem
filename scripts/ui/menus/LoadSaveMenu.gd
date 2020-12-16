extends PanelContainer_Themeable


onready var previewImg : TextureRect = get_node("MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer2/PanelContainer/Preview")
onready var label_date : Label = get_node("MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer2/GridContainer/Date")
onready var label_time : Label = get_node("MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer2/GridContainer/Time")
onready var label_players : Label = get_node("MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer2/GridContainer/Players")
onready var label_alliedai : Label = get_node("MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer2/GridContainer/AlliedAI")
onready var label_mapsize : Label = get_node("MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer2/GridContainer/MapSize")
onready var color_player : ColorRect = get_node("MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer2/GridContainer/Player")
onready var label_turn : Label = get_node("MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer2/GridContainer/Turn")

onready var edit_filename : LineEdit = get_node("MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/HFilename/Filename")
onready var list_files : ItemList = get_node("MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/FileList")

var selected_file_index := -1

onready var inAnim : ControlTrans_ColumnWipe = get_node("ControlTrans_ColumnWipe")
var outAnim : ControlTrans_ColumnWipe

var animating := true

var disabled := false setget set_disabled, is_disabled

var menuControl


func _ready():
	outAnim = inAnim.duplicate()
	inAnim.callback = [self, "_on_display"]
	populate_files()


func populate_files():
	_on_filelist_nothing_selected()
	list_files.clear()
	
	var filenames := []
	var dir = Directory.new()
	if dir.open(CDIO.PATH_SAVE) == OK:
		dir.list_dir_begin()
		var filename = dir.get_next()
		while filename != "":
			if dir.current_is_dir():
				filename = dir.get_next()
				continue
			
			if filename.to_lower().ends_with(".%s" % SavedGame.EXTENSION):
				filenames.push_back(filename)
			
			filename = dir.get_next()
		dir.list_dir_end()
	
	if !filenames.empty():
		filenames.sort_custom(self, "sort_filenames")
		
		for filename in filenames:
			filename.erase(filename.length() - SavedGame.EXTENSION.length() - 1, SavedGame.EXTENSION.length() + 1)
			list_files.add_item(filename)


func sort_filenames(a, b):
	var f = File.new()
	return (f.get_modified_time("%s/%s" % [CDIO.PATH_SAVE, a])
			> f.get_modified_time("%s/%s" % [CDIO.PATH_SAVE, b]))


func set_load_only():
	get_node("MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/HFilename").hide()
	get_node("MarginContainer/VBoxContainer/HBoxContainer2/button_save").hide()


func set_disabled(disable : bool):
	edit_filename.editable = !disable
	
	for i in list_files.get_item_count():
		list_files.set_item_disabled(i, disable)
	
	get_node("MarginContainer/VBoxContainer/HBoxContainer2/button_save").disabled = disable
	get_node("MarginContainer/VBoxContainer/HBoxContainer2/button_load").disabled = disable
	get_node("MarginContainer/VBoxContainer/HBoxContainer2/button_delete").disabled = disable
	get_node("MarginContainer/VBoxContainer/HBoxContainer2/button_cancel").disabled = disable
	
	disabled = disable


func is_disabled() -> bool:
	return disabled


func close():
	if menuControl != null:
		menuControl.menu = null
		if get_node("/root/Game") != null:
			menuControl.button_saveload.pressed = false
		else:
			menuControl.button_load.pressed = false
	
	if animating && inAnim != null:
		inAnim.playOnStart = false
		inAnim.pause()
		inAnim.queue_free()
		return

	animating = true
	outAnim.reverse = true
	outAnim.reattach = false
	outAnim.set_control(self)
	outAnim.play()


func _on_display(anim):
	animating = false
	inAnim = null


func _input(event : InputEvent):
	if disabled || animating:
		return
	
	if event.is_action_released("ui_cancel"):
		close()
		get_tree().set_input_as_handled()
		return


func _preview_resized():
	if previewImg.rect_size.y > 128:
		previewImg.rect_size = Vector2(previewImg.rect_size.x, 128)


func _on_filelist_item_selected(index):
	Audio.play_click()
	
	selected_file_index = index
	
	var filename = list_files.get_item_text(index)
	edit_filename.text = filename
	
	var selectedFile = CDIO.load_header("%s.%s" % [filename, SavedGame.EXTENSION])
	if selectedFile.get_error() != OK:
		menuControl.error(tr("error_file_noread") % [filename, selectedFile.get_error()])
		selectedFile.close()
		return
	selectedFile.close()
	
	previewImg.texture = selectedFile.preview
	
	label_date.text = tr("label_formatted_date") % [selectedFile.date.month,
			selectedFile.date.day,
			selectedFile.date.year]
	
	label_time.text = "%02d:%02d" % [selectedFile.date.hour, selectedFile.date.minute]
	
	label_players.text = str(selectedFile.numPlayers)
	if selectedFile.alliedAI:
		label_alliedai.text = tr("label_yes")
	else:
		label_alliedai.text = tr("label_no")
	label_mapsize.text = "%dx%d" % [selectedFile.mapWidth, selectedFile.mapHeight]
	color_player.color = CD.get_player_color(selectedFile.playerColor)
	label_turn.text = str(selectedFile.turn)


func _on_filelist_nothing_selected():
	if edit_filename.text == list_files.get_item_text(selected_file_index):
		edit_filename.clear()
	selected_file_index = -1
	
	previewImg.texture = preload("res://textures/UI/nighthawk_silhouette.atlastex")
	
	label_date.text = "-"
	label_time.text = "-"
	label_players.text = "-"
	label_alliedai.text = "-"
	label_mapsize.text = "-x-"
	color_player.color = Color.transparent
	label_turn.text = "-"
	
	list_files.unselect_all()


func _on_save(checkOverwrite := true, dialogToClose = null):
	Audio.play_click()
	
	if dialogToClose != null:
		menuControl.close_dialog(dialogToClose)
	
	if edit_filename.text.empty():
		menuControl.error(tr("error_save_noname"))
		return
	
	if !edit_filename.text.is_valid_filename():
		menuControl.error(tr("error_save_invalidchar"))
		return
	
	var fn = edit_filename.text
	if !fn.to_lower().ends_with("." + SavedGame.EXTENSION):
		fn = "%s.%s" % [fn, SavedGame.EXTENSION]
	
	if checkOverwrite:
		var dir = Directory.new()
		var err = dir.open(CDIO.PATH_SAVE)
		if err != OK:
			menuControl.error(tr("error_dir_noopen") % [CDIO.PATH_SAVE, err])
			return
		
		elif dir.file_exists("%s/%s" % [CDIO.PATH_SAVE, fn]):
			var dialog = menuControl.message(tr("message_overwrite") % fn, tr("label_overwrite"))
			dialog.set_positive_button(MethodRef.new(self, "_on_save", [false, dialog]), tr("label_yes"))
			dialog.set_negative_button(MethodRef.new(menuControl, "close_dialog", [dialog]), tr("label_no"))
			dialog.set_transition_colors(Color(1, 0, 0.83, 0.79), Color(1, 0, 0, 0.79))
			return
	
	var dialog = preload("res://scenes/UI/dialog/Message_Saving.tscn").instance()
	dialog.saveFileName = fn
	dialog.saveMenu = self
	menuControl.add_dialog(dialog)


func _on_load():
	Audio.play_click()
	
	if selected_file_index < 0:
		return
	
	var fn = "%s.%s" % [list_files.get_item_text(selected_file_index), SavedGame.EXTENSION]
	
	var dir = Directory.new()
	var err = dir.open(CDIO.PATH_SAVE)
	if err != OK:
		menuControl.error(tr("error_dir_noopen") % [CDIO.PATH_SAVE, err])
		return
	
	if !dir.file_exists("%s/%s" % [CDIO.PATH_SAVE, fn]):
		return
	
	var curtain = menuControl.instance_curtain()
	curtain.savedFilename = fn
	curtain.label.text = tr("label_reading_save")


func _on_delete():
	Audio.play_click()
	
	if selected_file_index < 0:
		return
	
	var filename = list_files.get_item_text(selected_file_index)
	var dialog = menuControl.message(tr("message_delete_file") % filename, tr("label_delete"))
	dialog.set_positive_button(MethodRef.new(self, "delete_file", [filename + "." + SavedGame.EXTENSION, dialog]), tr("label_yes"))
	dialog.set_negative_button(MethodRef.new(menuControl, "close_dialog", [dialog]), tr("label_no"))
	dialog.set_transition_colors(Color(1, 0, 0.83, 0.79), Color(1, 0, 0, 0.79))

func delete_file(filename, dialog):
	var error = CDIO.delete_save(filename)
	populate_files()
	menuControl.close_dialog(dialog)


func _cancel():
	Audio.play_click()
	close()
