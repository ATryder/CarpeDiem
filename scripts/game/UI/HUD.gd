extends CanvasLayer

const TRANS_SWOOSH_BLUE = preload("res://scenes/UI/transition/ColumnWipe_SimplexSwoosh.tscn")
const MSGDIALOG = preload("res://scenes/UI/dialog/MessageDialog.tscn")

onready var game = get_node("/root/Game")
onready var mouseControl = game.get_node("Arena/MouseControl")
onready var hud = get_node("HUD")
onready var popupsGame = get_node("Popup_Game")
onready var dialogGame = get_node("Dialog_Game")
var infoView

var selectedTile : CDTile setget set_selected_tile, get_selected_tile
var hoveredTile : CDTile setget set_hovered_tile, get_hovered_tile

const ANIM_BUILDMENU := "BuildMenuAnimator"
onready var buildMenu = get_node("Popup_Game/BuildMenu")

onready var musicPlayer = hud.get_node("MusicPlayer")

var debrief

var turnIndicator

var actionButtonDisplay
onready var selectedTileDisplay = hud.get_node("SelectedTileWindow")
onready var hoveredTileDisplay = hud.get_node("HoveredTileWindow")

var disabled := false setget set_disabled, is_disabled


func _ready():
	popupsGame.remove_child(buildMenu)


func game_loaded(mapGen):
	infoView = load("res://scenes/UI/InfoView.tscn").instance()
	if mapGen is SaveLoader:
		game.get_node("CameraControl").zoomToAttacks = clamp(mapGen.sg.loadedGame.zoomToAttacks, 0, 2)
		game.arena.get_node("GridControl").set_visible(mapGen.sg.loadedGame.gridVisible)
		game.get_node("QuickInfo").set_visible(mapGen.sg.loadedGame.quickInfoVisible)
		hud.add_child(infoView)
		infoView.mapDisplay.initialize_map()
	else:
		hud.add_child(infoView)
		infoView.mapDisplay.initialize_map()


func is_focused() -> bool:
	return popupsGame.get_child_count() > 0 || is_dialog_focused()


func is_dialog_focused() -> bool:
	return dialogGame.get_child_count() > 0


func refresh_map():
	if (infoView != null
			&& !infoView.mapDisplay.is_refreshing()):
		infoView.mapDisplay.refresh()

func update_map(tile : CDTile):
	if infoView != null:
		infoView.mapDisplay.update_tile(tile)


func set_selected_tile(tile : CDTile):
	mouseControl.selectedTile = tile


func get_selected_tile() -> CDTile:
	return mouseControl.selectedTile


func set_hovered_tile(tile : CDTile):
	mouseControl.hoveredTile = tile


func get_hovered_tile() -> CDTile:
	return mouseControl.hoveredTile


func set_disabled(value : bool):
	if value:
		disable_hud()
	else:
		enable_hud()


func is_disabled() -> bool:
	return disabled


func disable_hud(disableBuildMenu := true, disableActionButtons := true):
	disabled = true
	infoView.set_disabled(true)
	
	if actionButtonDisplay != null && disableActionButtons:
		actionButtonDisplay.set_disabled(true)
	
	if disableBuildMenu:
		buildMenu.set_disabled(true)


func enable_hud():
	disabled = false
	infoView.set_disabled(false)
	buildMenu.set_disabled(false)
	if actionButtonDisplay != null:
		actionButtonDisplay.set_disabled(false)


func launch_turn_indicator(player):
	turnIndicator = preload("res://scenes/UI/TurnIndicator.tscn").instance()
	hud.add_child(turnIndicator)
	turnIndicator.label.text = player.handle
	turnIndicator.label.add_color_override("font_color", player.get_color())
	turnIndicator.anim.color = player.get_color()
	turnIndicator.anim.play()


func launch_build_menu(station = null):
	if station != null:
		buildMenu.station = station
	if buildMenu.is_open():
		return
	
	if popupsGame.has_node(ANIM_BUILDMENU):
		var anim = popupsGame.get_node(ANIM_BUILDMENU)
		if anim.reverse:
			anim.stop()
			anim._end()
		else:
			anim.play(true, true, false)
			return
	
	buildMenu.open(null)
	
	var anim = TRANS_SWOOSH_BLUE.instance()
	anim.mouse_filter = Control.MOUSE_FILTER_STOP
	anim.callback = [buildMenu, "display"]
	anim.name = ANIM_BUILDMENU
	anim.set_control(buildMenu, popupsGame)
	anim.angle = rand_range(0, 2*PI)
	anim.set_colors([Color.cyan,
			Color.cyan.blend(Color(1, 1, 1, 0.8)),
			Color.white,
			Color.cyan.blend(Color(1, 1, 1, 0.8)),
			Color.cyan,
			Color.cyan.blend(Color(0, 0, 1, 0.3)),
			Color.cyan.blend(Color(0, 0, 1, 0.75)),
			Color.blue,
			Color.cyan.blend(Color(0, 0, 1, 0.75)),
			Color.cyan.blend(Color(0, 0, 1, 0.3))
			])
	anim.play()
	
	disable_hud(false, false)


func close_build_menu():
	if popupsGame.has_node(ANIM_BUILDMENU):
		if popupsGame.get_child_count() == 1 && dialogGame.get_child_count() == 0:
			enable_hud()
		buildMenu.close(popupsGame.get_node(ANIM_BUILDMENU))
		return
	if !buildMenu.is_open():
		return
	buildMenu.close()
	
	var anim = TRANS_SWOOSH_BLUE.instance()
	anim.name = ANIM_BUILDMENU
	anim.reverse = true
	anim.reattach = false
	anim.keepOutControl = true
	anim.set_control(buildMenu, popupsGame)
	anim.angle = rand_range(0, 2*PI)
	anim.set_colors([Color.cyan,
			Color.cyan.blend(Color(1, 1, 1, 0.8)),
			Color.white,
			Color.cyan.blend(Color(1, 1, 1, 0.8)),
			Color.cyan,
			Color.cyan.blend(Color(0, 0, 1, 0.3)),
			Color.cyan.blend(Color(0, 0, 1, 0.75)),
			Color.blue,
			Color.cyan.blend(Color(0, 0, 1, 0.75)),
			Color.cyan.blend(Color(0, 0, 1, 0.3))
			])
	anim.play()
	
	if popupsGame.get_child_count() == 1 && dialogGame.get_child_count() == 0:
		enable_hud()


func launch_debrief(analyzer : SnapshotAnalyzer):
	close_build_menu()
	if debrief == null:
		debrief = load("res://scenes/UI/menus/Debrief.tscn").instance()
		debrief.players = analyzer.players
		debrief.lines = analyzer.lines
		debrief.replayFrames = analyzer.replayFrames
		
		popupsGame.add_child(debrief)
	
		var debriefButton = load("res://scenes/UI/buttons/EndGameButton.tscn").instance()
		debrief.hudButton = debriefButton.get_node("Button")
		hud.add_child(debriefButton)
		
		var transition = load("res://scenes/UI/transition/ColumnWipe_ActionButton.tscn").instance()
		transition.set_control(debriefButton)
		transition.play()
	
	debrief.open(false)


func display_action_buttons(tile : CDTile):
	if actionButtonDisplay != null:
		actionButtonDisplay.close()
	
	if tile == null || tile.unit == null:
		return
	
	actionButtonDisplay = tile.unit.actionButtonScene.instance()
	actionButtonDisplay.open(tile, hud, game)


func action_buttons_active():
	return actionButtonDisplay != null


func close_action_button_display():
	if actionButtonDisplay == null:
		return
	
	actionButtonDisplay.close()
	actionButtonDisplay = null


func add_dialog(dialog : Control):
	dialogGame.add_child(dialog)
	dialogGame.mouse_filter = Control.MOUSE_FILTER_STOP
	disable_hud()


func close_dialog(dialog : Control, enableHud := true):
	if dialog.has_method("close"):
		if dialogGame.get_child_count() == 1:
			dialogGame.mouse_filter = Control.MOUSE_FILTER_IGNORE
			if enableHud:
				enable_hud()
		dialog.close()
	elif dialogGame.get_children().has(dialog):
		if dialogGame.get_child_count() == 1:
			dialogGame.mouse_filter = Control.MOUSE_FILTER_IGNORE
			if enableHud:
				enable_hud()
		dialogGame.remove_child(dialog)


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


func _input(event : InputEvent):
	if (event.is_action_released("game_menu") && !game.FIN
			&& !disabled && get_node("GameMenu").get_child_count() == 0):
		infoView._launch_ingame_menu()
		get_tree().set_input_as_handled()
		return
	
	if event.is_action_released("end_turn") && game.is_local_turn() && !disabled:
		game.end_turn()


func change_theme(oldTheme, newTheme):
	buildMenu.change_theme(oldTheme, newTheme)


func cleanup():
	if buildMenu.get_parent() == null:
		buildMenu.free()
	
	if debrief != null && debrief.get_parent() == null:
		debrief.cleanup()
		debrief.free()
