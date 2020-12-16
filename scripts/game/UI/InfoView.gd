extends HBoxContainer

onready var hud = get_node("/root/Game/HUDLayer")

onready var mapDisplay = get_node("VPanel/PanelContainer/MarginContainer/VBoxContainer/MapDisplay")

const infoAnim : PackedScene = preload("res://scenes/UI/transition/Wipe_RTL.tscn")
var energyAnim : ControlTrans_Wipe
var oreAnim : ControlTrans_Wipe
onready var energy := get_node("VPanel/PanelContainer/MarginContainer/VBoxContainer/EnergyDisplay")
onready var ore := get_node("VPanel/PanelContainer/MarginContainer/VBoxContainer/OreDisplay")
var energyAmount := 0
var oreAmount := 0

var disabled := false setget set_disabled, is_disabled


func _ready():
	get_node("VPanel/HButtons_Margin/HButtons/GridToggle").toggled = hud.game.arena.get_node("GridControl").visible
	get_node("VPanel/HButtons_Margin/HButtons/InfoToggle").toggled = hud.game.get_node("QuickInfo").visible
	match(hud.game.get_node("CameraControl").zoomToAttacks):
		0:
			get_node("VPanel/HButtons_Margin/HButtons/CameraZoomToggle").toggled = false
		2:
			get_node("VPanel/HButtons_Margin/HButtons/CameraZoomToggle").triggled = true
		_:
			get_node("VPanel/HButtons_Margin/HButtons/CameraZoomToggle").toggled = true
	energy.set_visible(false)
	ore.set_visible(false)
	
	if Opts.theme != Opts.THEME_LIGHT:
		change_theme(Opts.THEME_LIGHT, Opts.theme, false)


func set_disabled(value : bool):
	if value == disabled:
		return
	
	disabled = value
	get_node("VButtons_Margin/VButtons/OptionsButton").set_disabled(disabled)
	get_node("VPanel/HButtons_Margin/HButtons/GridToggle").set_disabled(disabled)
	get_node("VPanel/HButtons_Margin/HButtons/InfoToggle").set_disabled(disabled)
	get_node("VPanel/HButtons_Margin/HButtons/CameraZoomToggle").set_disabled(disabled)
	
	var tb = get_node("VButtons_Margin/VButtons/TurnButton")
	if !disabled && !tb.toggled:
		tb.set_disabled(false)
	elif disabled:
		tb.set_disabled(true)


func is_disabled() -> bool:
	return disabled


func reset_turn_button():
	var button = get_node("VButtons_Margin/VButtons/TurnButton")
	button.toggled = false
	if disabled:
		button.set_disabled(true)


func disable_turn_button():
	get_node("VButtons_Margin/VButtons/TurnButton").toggled = true


func _launch_ingame_menu():
	Audio.play_click()
	hud.disable_hud()
	get_tree().set_pause(true)
	var inGameMenu = load("res://scenes/UI/menus/InGameMenu.tscn").instance()
	hud.get_node("GameMenu").add_child(inGameMenu)


func _toggle_music_player():
	if hud.musicPlayer.is_open():
		hud.musicPlayer.close()
	else:
		hud.musicPlayer.open()


func _toggle_grid():
	var grid = hud.game.arena.get_node("GridControl")
	grid.visible = !grid.visible


func _toggle_quickinfo():
	var qi = hud.game.get_node("QuickInfo")
	qi.visible = !qi.visible


func _toggle_camera_zoom():
	var camCont = hud.game.get_node("CameraControl")
	if camCont.zoomToAttacks == 2:
		camCont.zoomToAttacks = 0
	else:
		camCont.zoomToAttacks += 1


func set_energy(amount : int):
	pass
#	if amount == energyAmount:
#		return
#
#	if energyAnim != null:
#		energyAnim.vpTo.render_target_update_mode = Viewport.UPDATE_ONCE
#		energyAmount = amount
#		energy.text = "%0.d%%" % floor((float(amount) / hud.game.arena.total_stars) * 100)
#		return
#
#	var newLabel = energy.duplicate()
#	energyAmount = amount
#	newLabel.text = "%0.d%%" % floor((float(amount) / hud.game.arena.total_stars) * 100)
#
#	energyAnim = infoAnim.instance()
#	energyAnim.length = 1.5
#	energyAnim.set_transition(energy, newLabel)
#	energyAnim.set_callback([self, "_finish_energy_anim"])
#	energyAnim.play()
#	energy = newLabel


func _finish_energy_anim(anim : ControlTransition):
	energyAnim = null


func set_ore(amount : int):
	pass
#	if amount == oreAmount:
#		return
#
#	if oreAnim != null:
#		oreAnim.vpTo.render_target_update_mode = Viewport.UPDATE_ONCE
#		oreAmount = amount
#		ore.text = "%0.d%%" % floor((float(amount) / hud.game.arena.total_asteroids) * 100)
#		return
#
#	var newLabel = ore.duplicate()
#	oreAmount = amount
#	newLabel.text = "%0.d%%" % floor((float(amount) / hud.game.arena.total_asteroids) * 100)
#
#	oreAnim = infoAnim.instance()
#	oreAnim.length = 1.5
#	oreAnim.set_transition(ore, newLabel)
#	oreAnim.set_callback([self, "_finish_ore_anim"])
#	oreAnim.play()
#	ore = newLabel


func _finish_ore_anim(anim : ControlTransition):
	oreAnim = null


func set_resources(energy : int, ore : int):
	set_energy(energy)
	set_ore(ore)


func change_theme(oldTheme, newTheme, refreshMap := true):
	mapDisplay.refresh()
	
	get_node("VPanel/PanelContainer").add_stylebox_override("panel", CD.get_window_background_style(false, newTheme))
	
	var blue = load("res://textures/UI/frame_blue48.atlastex")
	var orangeGlow = load("res://textures/UI/frame_glow_orange48.atlastex")
	var blueGlow = load("res://textures/UI/frame_glow_blue48.atlastex")
	
	var green = load("res://textures/UI/frame_green48.atlastex")
	var greenGlow = load("res://textures/UI/frame_glow_green48.atlastex")
	var yellowGlow = load("res://textures/UI/frame_glow_yellow48.atlastex")
	
	var optButton = get_node("VButtons_Margin/VButtons/OptionsButton")
	if newTheme == Opts.THEME_DARK:
		optButton.texture_normal = load("res://textures/UI/frame_orange48.atlastex")
		optButton.texture_pressed = blueGlow
		optButton.texture_hover = orangeGlow
		optButton.get_node("Icon").texture = load("res://textures/UI/buttons/operation/button_gear_dark.atlastex")
		
		var musicButton = get_node("VButtons_Margin/VButtons/MusicButton")
		musicButton.get_node("Icon").texture = load("res://textures/UI/buttons/operation/button_music_dark.atlastex")
		var gridButton = get_node("VPanel/HButtons_Margin/HButtons/GridToggle")
		gridButton.get_node("Icon").texture = load("res://textures/UI/buttons/operation/button_grid_dark.atlastex")
		var infoButton = get_node("VPanel/HButtons_Margin/HButtons/InfoToggle")
		infoButton.get_node("Icon").texture = load("res://textures/UI/buttons/operation/button_info_dark.atlastex")
		var camButton = get_node("VPanel/HButtons_Margin/HButtons/CameraZoomToggle")
		
		musicButton.toggled_normal = green
		musicButton.toggled_pressed = yellowGlow
		musicButton.toggled_hover = greenGlow
		if musicButton.toggled:
			musicButton.texture_normal = musicButton.toggled_normal
			musicButton.texture_pressed = musicButton.toggled_pressed
			musicButton.texture_hover = musicButton.toggled_hover
		
		gridButton.toggled_normal = green
		gridButton.toggled_pressed = yellowGlow
		gridButton.toggled_hover = greenGlow
		if gridButton.toggled:
			gridButton.texture_normal = gridButton.toggled_normal
			gridButton.texture_pressed = gridButton.toggled_pressed
			gridButton.texture_hover = gridButton.toggled_hover
		
		infoButton.toggled_normal = green
		infoButton.toggled_pressed = yellowGlow
		infoButton.toggled_hover = greenGlow
		if infoButton.toggled:
			infoButton.texture_normal = infoButton.toggled_normal
			infoButton.texture_pressed = infoButton.toggled_pressed
			infoButton.texture_hover = infoButton.toggled_hover
		
		camButton.toggled_normal = green
		camButton.toggled_pressed = yellowGlow
		camButton.toggled_hover = greenGlow
		if camButton.toggled && !camButton.triggled:
			camButton.texture_normal = camButton.toggled_normal
			camButton.texture_pressed = camButton.toggled_pressed
			camButton.texture_hover = camButton.toggled_hover
	else:
		var purple = load("res://textures/UI/frame_purple48.atlastex")
		var purpleGlow = load("res://textures/UI/frame_glow_purple48.atlastex")
		
		optButton.texture_normal = blue
		optButton.texture_pressed = orangeGlow
		optButton.texture_hover = blueGlow
		optButton.get_node("Icon").texture = load("res://textures/UI/buttons/operation/button_gear.atlastex")
		
		var musicButton = get_node("VButtons_Margin/VButtons/MusicButton")
		musicButton.get_node("Icon").texture = load("res://textures/UI/buttons/operation/button_music.atlastex")
		var gridButton = get_node("VPanel/HButtons_Margin/HButtons/GridToggle")
		gridButton.get_node("Icon").texture = load("res://textures/UI/buttons/operation/button_grid.atlastex")
		var infoButton = get_node("VPanel/HButtons_Margin/HButtons/InfoToggle")
		infoButton.get_node("Icon").texture = load("res://textures/UI/buttons/operation/button_info.atlastex")
		var camButton = get_node("VPanel/HButtons_Margin/HButtons/CameraZoomToggle")
		
		musicButton.toggled_normal = purple
		musicButton.toggled_pressed = greenGlow
		musicButton.toggled_hover = purpleGlow
		if musicButton.toggled:
			musicButton.texture_normal = musicButton.toggled_normal
			musicButton.texture_pressed = musicButton.toggled_pressed
			musicButton.texture_hover = musicButton.toggled_hover
		
		gridButton.toggled_normal = purple
		gridButton.toggled_pressed = greenGlow
		gridButton.toggled_hover = purpleGlow
		if gridButton.toggled:
			gridButton.texture_normal = gridButton.toggled_normal
			gridButton.texture_pressed = gridButton.toggled_pressed
			gridButton.texture_hover = gridButton.toggled_hover
		
		infoButton.toggled_normal = purple
		infoButton.toggled_pressed = greenGlow
		infoButton.toggled_hover = purpleGlow
		if infoButton.toggled:
			infoButton.texture_normal = infoButton.toggled_normal
			infoButton.texture_pressed = infoButton.toggled_pressed
			infoButton.texture_hover = infoButton.toggled_hover
		
		camButton.toggled_normal = purple
		camButton.toggled_pressed = greenGlow
		camButton.toggled_hover = purpleGlow
		if camButton.toggled && !camButton.triggled:
			camButton.texture_normal = camButton.toggled_normal
			camButton.texture_pressed = camButton.toggled_pressed
			camButton.texture_hover = camButton.toggled_hover
