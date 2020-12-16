extends PanelContainer_Themeable

onready var map_dimensions = get_node("VBoxContainer/HBoxContainer/GridContainer/map_dimensions")
onready var players = get_node("VBoxContainer/HBoxContainer/GridContainer/players")
onready var cloud_colors = get_node("VBoxContainer/HBoxContainer/GridContainer/cloud_colors")
onready var allvis = get_node("VBoxContainer/HBoxContainer/GridContainer/allvis")
onready var nofog = get_node("VBoxContainer/HBoxContainer/GridContainer/nofog")
onready var alliedai = get_node("VBoxContainer/HBoxContainer/GridContainer/alliedai")
onready var difficulty = get_node("VBoxContainer/HBoxContainer/GridContainer2/difficulty")
onready var asteroid_amount = get_node("VBoxContainer/HBoxContainer/GridContainer2/asteroid_amount")
onready var star_amount = get_node("VBoxContainer/HBoxContainer/GridContainer2/star_amount")
onready var player = get_node("VBoxContainer/HBoxContainer/GridContainer2/player")
onready var playerHandle = get_node("VBoxContainer/HBoxContainer/GridContainer2/playerHandle")
onready var showTutorial = get_node("VBoxContainer/HBoxContainer/GridContainer2/showtutorial")

var menuControl

var animating := true
onready var inAnim : ControlTrans_ColumnWipe = get_node("ControlTrans_ColumnWipe")
var outAnim : ControlTrans_ColumnWipe

var disabled := false setget set_disabled, is_disabled


func _ready():
	outAnim = inAnim.duplicate()
	inAnim.callback = [self, "_on_display"]
	
	for dimension in Opts.MAP_SIZES:
		map_dimensions.add_item("%0.d x %0.d" % [dimension.x, dimension.y])
	map_dimensions.select(Opts.mapSize)
	
	players.text = str(Opts.get_players_for_map_size(Opts.mapSize))
	
	var selected := 0
	for i in range(menuControl.colorCombos.size()):
		cloud_colors.add_icon_item(menuControl.cloudGrads[i], "")
		var combo = menuControl.colorCombos[i]
		if combo.x == Opts.mapColor1 && combo.y == Opts.mapColor2:
			selected = i
	cloud_colors.select(selected)
	
	allvis.pressed = Opts.allVis
	nofog.pressed = !Opts.noFog
	alliedai.pressed = Opts.alliedAI
	
	difficulty.add_item(tr("label_easy"), Opts.AI_EASY)
	difficulty.add_item(tr("label_challenging"), Opts.AI_MEDIUM)
	difficulty.add_item(tr("label_hard"), Opts.AI_HARD)
	difficulty.select(difficulty.get_item_index(Opts.aiDifficulty))
	
	asteroid_amount.add_item(tr("label_low"), Opts.QUANTITY_LOW)
	asteroid_amount.add_item(tr("label_med"), Opts.QUANTITY_MED)
	asteroid_amount.add_item(tr("label_high"), Opts.QUANTITY_HIGH)
	asteroid_amount.select(asteroid_amount.get_item_index(Opts.asteroidAmount))
	
	star_amount.add_item(tr("label_low"), Opts.QUANTITY_LOW)
	star_amount.add_item(tr("label_med"), Opts.QUANTITY_MED)
	star_amount.add_item(tr("label_high"), Opts.QUANTITY_HIGH)
	star_amount.select(star_amount.get_item_index(Opts.starAmount))
	
	for tex in menuControl.playerColors:
		player.add_icon_item(tex, "")
	player.select(Opts.playerColor)
	
	playerHandle.text = Opts.playerHandle
	
	showTutorial.pressed = Opts.showTutorial


func set_disabled(disable : bool):
	map_dimensions.disabled = disable
	cloud_colors.disabled = disable
	allvis.disabled = disable
	nofog.disabled = disable
	alliedai.disabled = disable
	difficulty.disabled = disable
	asteroid_amount.disabled = disable
	star_amount.disabled = disable
	player.disabled = disable
	playerHandle.editable = !disable
	showTutorial.disabled = disable
	
	for item in get_node("VBoxContainer/HBoxContainer2").get_children():
		if item.has_method("set_disabled"):
			item.set_disabled(disable)
	
	disabled = disable


func is_disabled() -> bool:
	return disabled


func _on_dimension_selected(index):
	Audio.play_click()
	players.text = str(Opts.get_players_for_map_size(map_dimensions.get_item_id(index)))


func _randomize():
	Audio.play_click()
	
	map_dimensions.select(randi() % map_dimensions.get_item_count())
	players.text = str(Opts.get_players_for_map_size(map_dimensions.get_selected_id()))
	
	cloud_colors.select(randi() % cloud_colors.get_item_count())
	
	allvis.pressed = randf() >= 0.5
	nofog.pressed = randf() >= 0.5
	alliedai.pressed = randf() >= 0.5
	
	difficulty.select(randi() % difficulty.get_item_count())
	asteroid_amount.select(randi() % asteroid_amount.get_item_count())
	star_amount.select(randi() % star_amount.get_item_count())
	player.select(randi() % player.get_item_count())


func _cancel():
	Audio.play_click()
	close()


func close():
	if menuControl != null:
		menuControl.menu = null
		menuControl.button_new.pressed = false
	
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


func _start():
	Audio.play_click()
	
	Opts.mapSize = map_dimensions.get_selected_id()
	Opts.mapColor1 = menuControl.colorCombos[cloud_colors.get_selected_id()].x
	Opts.mapColor2 = menuControl.colorCombos[cloud_colors.get_selected_id()].y
	Opts.allVis = allvis.pressed
	Opts.noFog = !nofog.pressed
	Opts.alliedAI = alliedai.pressed
	Opts.aiDifficulty = difficulty.get_selected_id()
	Opts.asteroidAmount = asteroid_amount.get_selected_id()
	Opts.starAmount = star_amount.get_selected_id()
	Opts.playerColor = player.get_selected_id()
	Opts.playerHandle = playerHandle.text
	Opts.showTutorial = showTutorial.pressed
	
	print("Saving Carpe Diem settings: %d" % Opts.save_settings())
	
	menuControl.instance_curtain()


func _click(value = 0):
	Audio.play_click()


func _on_help_button_button_up():
	Audio.play_click()
	var help = load("res://scenes/UI/dialog/HelpDialog.tscn").instance()
	help.set_content(tr("help_new_game"), tr("label_create_game"), menuControl)
	menuControl.add_dialog(help)
