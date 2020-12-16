extends PanelContainer_Themeable

var anim : ControlTrans_ContraBlinds
var outAnim : ControlTrans_ContraBlinds

var title : String
var message : String

var dismissCallback : MethodRef


func _ready():
	Audio.play_chime_in()
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


func _on_display(var animation = null):
	var dismissButton = get_node("VBoxContainer/VBoxContainer/HBoxContainer/Dismiss")
	dismissButton.grab_focus()


func set_content(message : String, title = "", parentMenu = null):
	set_title(title)
	set_message(message)
	
	if parentMenu != null && parentMenu.has_method("close_dialog"):
		dismissCallback = MethodRef.new(parentMenu, "close_dialog", [self])


func set_title(value):
	var titleLabel = get_node("VBoxContainer/Title")
	if value == null || value.empty():
		titleLabel.text = ""
		titleLabel.visible = false
		return
	
	titleLabel.visible = true
	title = value


func set_message(value : String):
	var messageLabel = get_node("VBoxContainer/VBoxContainer/Message")
	if messageLabel != null:
		messageLabel.bbcode_text = value
	message = value


func _dismiss():
	Audio.play_click()
	if dismissCallback == null:
		close()
		return
	dismissCallback.exec()


func close():
	outAnim.reverse = true
	outAnim.reattach = false
	outAnim.set_control(self)
	outAnim.play()
