extends PanelContainer_Themeable

onready var button_theme = get_node("VBoxContainer/HBoxContainer/VBoxContainer/DisplayOptions/PanelContainer/MarginContainer/VBoxContainer/GridContainer/theme")
onready var button_fullscreen = get_node("VBoxContainer/HBoxContainer/VBoxContainer/DisplayOptions/PanelContainer/MarginContainer/VBoxContainer/GridContainer/fullscreen")
onready var button_resolution = get_node("VBoxContainer/HBoxContainer/VBoxContainer/DisplayOptions/PanelContainer/MarginContainer/VBoxContainer/GridContainer/Resolution")

onready var slider_sfx = get_node("VBoxContainer/HBoxContainer/VBoxContainer/AudioOptions/PanelContainer/MarginContainer/VBoxContainer/GridContainer/SFX_Slider")
onready var slider_music = get_node("VBoxContainer/HBoxContainer/VBoxContainer/AudioOptions/PanelContainer/MarginContainer/VBoxContainer/GridContainer/Music_Slider")

onready var button_particledetail = get_node("VBoxContainer/HBoxContainer/PerformanceOptions/PanelContainer/MarginContainer/VBoxContainer/GridContainer/particle_detail")
onready var button_starquality = get_node("VBoxContainer/HBoxContainer/PerformanceOptions/PanelContainer/MarginContainer/VBoxContainer/GridContainer/star_quality")
onready var button_cloudquality = get_node("VBoxContainer/HBoxContainer/PerformanceOptions/PanelContainer/MarginContainer/VBoxContainer/GridContainer/cloud_quality")

var menuControl

var resolutions := []

var animating := true
onready var inAnim : ControlTrans_ColumnWipe = get_node("ControlTrans_ColumnWipe")
var outAnim : ControlTrans_ColumnWipe

var disabled := false setget set_disabled, is_disabled

var oldVolMusic : float


func _ready():
	outAnim = inAnim.duplicate()
	inAnim.callback = [self, "_on_display"]
	
	oldVolMusic = Opts.vol_music
	
	button_theme.add_item(tr("label_light"), Opts.THEME_LIGHT)
	button_theme.add_item(tr("label_dark"), Opts.THEME_DARK)
	button_theme.select(button_theme.get_item_index(Opts.theme))
	
	if CD.quality_mobile():
		get_node("VBoxContainer/HBoxContainer/VBoxContainer/DisplayOptions/PanelContainer/MarginContainer/VBoxContainer/GridContainer/Label").hide()
		button_fullscreen.pressed = true
		button_fullscreen.hide()
	else:
		button_fullscreen.pressed = OS.window_fullscreen
		button_resolution.disabled = !OS.window_fullscreen
	
	var count := 0
	var selection := 0
	for cr in Opts.resolution_opts:
		button_resolution.add_item("%d x %d" % [cr.x, cr.y], count)
		if Opts.resolution == cr:
			selection = count
		count += 1
	button_resolution.select(button_resolution.get_item_index(selection))
	
	slider_sfx.value = Opts.vol_sfx
	slider_music.value = Opts.vol_music
	
	button_particledetail.add_item(tr("label_low"), Opts.QUALITY_LOW)
	button_particledetail.add_item(tr("label_med"), Opts.QUALITY_MED)
	button_particledetail.add_item(tr("label_high"), Opts.QUALITY_HIGH)
	button_particledetail.add_item(tr("label_xhigh"), Opts.QUALITY_XHIGH)
	button_particledetail.select(button_particledetail.get_item_index(Opts.particleDetail))
	
	button_cloudquality.add_item(tr("label_low"), Opts.QUALITY_LOW)
	button_cloudquality.add_item(tr("label_med"), Opts.QUALITY_MED)
	button_cloudquality.add_item(tr("label_high"), Opts.QUALITY_HIGH)
	button_cloudquality.add_item(tr("label_xhigh"), Opts.QUALITY_XHIGH)
	
	if !CD.highp_float():
		button_cloudquality.select(button_cloudquality.get_item_index(Opts.QUALITY_LOW))
		button_cloudquality.hide()
		button_cloudquality.get_parent().get_node("cloudQualityLabel").hide()
		
		button_starquality.add_item(tr("label_low"), Opts.QUALITY_LOW)
		button_starquality.add_item(tr("label_high"), Opts.QUALITY_HIGH)
	else:
		button_cloudquality.select(button_cloudquality.get_item_index(Opts.cloudQuality))
		
		button_starquality.add_item(tr("label_low"), Opts.QUALITY_LOW)
		button_starquality.add_item(tr("label_med"), Opts.QUALITY_MED)
		button_starquality.add_item(tr("label_high"), Opts.QUALITY_HIGH)
		button_starquality.add_item(tr("label_xhigh"), Opts.QUALITY_XHIGH)
		
	button_starquality.select(button_starquality.get_item_index(Opts.starQuality))


func set_disabled(disable : bool):
	button_fullscreen.disabled = disable
	if button_fullscreen.pressed && button_resolution.visible:
		button_resolution.disabled = disable
	
	slider_sfx.editable = !disable
	slider_music.editable = !disable
	
	button_particledetail.disabled = disable
	button_starquality.disabled = disable
	button_cloudquality.disabled = disable
	
	get_node("VBoxContainer/HBoxContainer2/okay_button").disabled = disable
	get_node("VBoxContainer/HBoxContainer2/cancel_button").disabled = disable
	
	disabled = disable


func is_disabled() -> bool:
	return disabled


func _cancel():
	Audio.play_click()
	Opts.vol_music = oldVolMusic
	close()


func close():
	if menuControl != null:
		menuControl.menu = null
		menuControl.button_options.pressed = false
	
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


func _fullscreen_pressed(pressed : bool):
	if pressed && !disabled && button_fullscreen.visible:
		button_resolution.disabled = false
	else:
		button_resolution.disabled = true


func _confirm():
	if button_fullscreen.pressed:
		var resolution = Opts.resolution_opts[button_resolution.get_item_id(button_resolution.selected)]
		var vpSize = Vector2i.new(int(round(get_tree().get_root().size.x)),
				int(round(get_tree().get_root().size.y)))
		if ((!Opts.fullscreen && button_fullscreen.visible) || resolution.x != vpSize.x
				|| resolution.y != vpSize.y):
			Audio.play_click()
			var dialog = preload("res://scenes/UI/dialog/Message_DisplayChange.tscn").instance()
			dialog.optionsMenu = self
			dialog.setFullscreen = !Opts.fullscreen && button_fullscreen.visible
			dialog.setResolution = resolution
			menuControl.add_dialog(dialog)
		else:
			Opts.vol_sfx = slider_sfx.value
			Audio.play_click()
			save_and_close()
	else:
		Opts.vol_sfx = slider_sfx.value
		Audio.play_click()
		save_and_close()


func cancel_display_settings():
	if !Opts.fullscreen && button_fullscreen.pressed && button_fullscreen.visible:
		get_tree().connect("screen_resized", self, "_reset_resolution", [], CONNECT_ONESHOT)
		OS.window_fullscreen = false
	else:
		get_tree().get_root().size = Vector2(Opts.resolution.x, Opts.resolution.y)


func save_and_close():
	Opts.theme = button_theme.get_item_id(button_theme.selected)
	
	Opts.fullscreen = button_fullscreen.pressed && button_fullscreen.visible
	if OS.window_fullscreen && !Opts.fullscreen:
		OS.window_fullscreen = false
	
	var resolution = Opts.resolution_opts[button_resolution.get_item_id(button_resolution.selected)]
	Opts.resolution = resolution
	var vpSize = Vector2i.new(int(round(get_tree().get_root().size.x)),
			int(round(get_tree().get_root().size.y)))
	if OS.window_fullscreen && (resolution.x != vpSize.x
			|| resolution.y != vpSize.y):
		get_tree().get_root().size = Vector2(resolution.x, resolution.y)
	
	Opts.particleDetail = button_particledetail.get_item_id(button_particledetail.selected)
	Opts.starQuality = button_starquality.get_item_id(button_starquality.selected)
	Opts.cloudQuality = button_cloudquality.get_item_id(button_cloudquality.selected)
	
	Opts.vol_sfx = slider_sfx.value
	Opts.vol_music = slider_music.value
	
	print("Saving Carpe Diem settings: %d" % Opts.save_settings())
	
	close()


func _reset_resolution():
	get_tree().get_root().size = Vector2(OS.window_size.x, OS.window_size.y)


func _click(value = 0):
	Audio.play_click()


func _on_Music_Slider_value_changed(value):
	Opts.vol_music = value


func _on_help_button_button_up():
	Audio.play_click()
	var help = load("res://scenes/UI/dialog/HelpDialog.tscn").instance()
	help.set_content(tr("help_options"), tr("label_options"), menuControl)
	menuControl.add_dialog(help)
