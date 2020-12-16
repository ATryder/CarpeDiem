extends MessageDialog

var tutorial : Tutorial


func _ready():
	add_user_signal("segment_finished")


func set_message(value : String):
	var messageLabel = get_node("VBoxContainer/VBoxContainer/Message")
	if messageLabel != null:
		messageLabel.bbcode_text = value
	message = value


func _on_Negative_button_up():
	Audio.play_click()
	if negativeCallback == null:
		if tutorial != null:
			tutorial.game.hud.close_dialog(self)
		
		emit_signal("segment_finished", self)
		return
	negativeCallback.exec()


func _on_show_tutorial_toggled(button_pressed):
	Opts.showTutorial = button_pressed
