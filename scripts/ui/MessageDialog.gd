extends PanelContainer_Themeable
class_name MessageDialog

export var alertColor1 := Color(1, 1, 0, 0.8)
export var alertColor2 := Color(1, 0, 0, 0.8)

export(AudioStream) var introSound 

var anim : ControlTrans_ContraBlinds
var outAnim : ControlTrans_ContraBlinds

var title : String
var message : String

var positiveCallback : MethodRef
var negativeCallback : MethodRef
var neutralCallback : MethodRef

export(bool) var grabFocus := true


func _ready():
	if introSound != null:
		Audio.play_sound(introSound)
	
	if anim == null:
		anim = get_node("ControlTrans_ContraBlinds")
	if outAnim == null:
		outAnim = anim.duplicate()
	anim.callback = [self, "_on_display"]
	var titleLabel = get_node("VBoxContainer/Title")
	if title == null || title.empty():
		titleLabel.visible = false
	else:
		titleLabel.visible = true
		titleLabel.text = title
	var messageLabel = get_node("VBoxContainer/VBoxContainer/Message")
	messageLabel.text = message


func set_alert_colors():
	add_stylebox_override("panel", CD.get_window_background_style(true, Opts.theme))
	set_transition_colors(alertColor1, alertColor2)


func set_transition_colors(color1 : Color, color2 : Color):
	if anim == null:
		anim = get_node("ControlTrans_ContraBlinds")
	if outAnim == null:
		outAnim = anim.duplicate()
	
	anim.color = color1
	anim.color2 = color2
	outAnim.color = color1
	outAnim.color2 = color2


func set_content(message : String, title = ""):
	set_title(title)
	set_message(message)


func set_title(value):
	var titleLabel = get_node("VBoxContainer/Title")
	if titleLabel == null:
		title = value
		return
	
	if value == null || value.empty():
		titleLabel.text = ""
		titleLabel.visible = false
		return
	
	titleLabel.visible = true
	title = value


func set_message(value : String):
	var messageLabel = get_node("VBoxContainer/VBoxContainer/Message")
	if messageLabel != null:
		messageLabel.text = value
	message = value


func set_dismiss_only(callBack = null):
	set_negative_button(callBack, CD.DEFAULT_DISMISS_TEXT)


func set_positive_button(methodRef : MethodRef, text := "Okay"):
	positiveCallback = methodRef
	var button : Button = get_node("VBoxContainer/VBoxContainer/HBoxContainer/HBoxContainer/Positive")
	button.text = text
	button.visible = methodRef != null && !text.empty()


func set_negative_button(methodRef : MethodRef, text := "Cancel"):
	negativeCallback = methodRef
	var button : Button = get_node("VBoxContainer/VBoxContainer/HBoxContainer/HBoxContainer/Negative")
	button.text = text
	button.visible = methodRef != null || !text.empty()

func set_neutral_button(methodRef : MethodRef, text := ""):
	neutralCallback = methodRef
	var button : Button = get_node("VBoxContainer/VBoxContainer/HBoxContainer/Neutral")
	button.text = text
	button.visible = methodRef != null && !text.empty()


func _on_Neutral_button_up():
	Audio.play_click()
	if neutralCallback == null:
		return
	neutralCallback.exec()


func _on_Positive_button_up():
	Audio.play_click()
	if positiveCallback == null:
		return
	positiveCallback.exec()


func _on_Negative_button_up():
	Audio.play_click()
	if negativeCallback == null:
		close()
		return
	negativeCallback.exec()


func _on_display(var animation = null):
	if grabFocus:
		var negativeButton = get_node("VBoxContainer/VBoxContainer/HBoxContainer/HBoxContainer/Positive")
		var positiveButton = get_node("VBoxContainer/VBoxContainer/HBoxContainer/HBoxContainer/Negative")
		var neutralButton = get_node("VBoxContainer/VBoxContainer/HBoxContainer/Neutral")
		if negativeButton.visible:
			negativeButton.grab_focus()
			if !positiveButton.visible:
				if neutralButton.visible:
					negativeButton.focus_neighbour_left = neutralButton.get_path()
					negativeButton.focus_previous = neutralButton.get_path()
				else:
					negativeButton.focus_neighbour_left = NodePath("")
					negativeButton.focus_previous = NodePath("")
			elif !neutralButton.visible:
				negativeButton.focus_neighbour_right = positiveButton.get_path()
				negativeButton.focus_previous = positiveButton.get_path()
		elif positiveButton.visible:
			positiveButton.grab_focus()
			if !negativeButton.visible:
				if neutralButton.visible:
					positiveButton.focus_neighbour_right = neutralButton.get_path()
					positiveButton.focus_next = neutralButton.get_path()
				else:
					positiveButton.focus_neighbour_right = NodePath("")
					positiveButton.focus_next = NodePath("")
			elif !neutralButton.visible:
				positiveButton.focus_neighbour_left = negativeButton.get_path()
				positiveButton.focus_previous = negativeButton.get_path()
		elif neutralButton.visible:
			neutralButton.grab_focus()
			neutralButton.focus_neighbour_left = NodePath("")
			neutralButton.focus_neighbour_right = NodePath("")
			neutralButton.focus_next = NodePath("")
			neutralButton.focus_previous = NodePath("")


func close():
	outAnim.reverse = true
	outAnim.reattach = false
	outAnim.set_control(self)
	outAnim.play()
