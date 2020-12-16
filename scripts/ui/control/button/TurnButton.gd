extends ToggleButton
class_name TurnButton


onready var game = get_node("/root/Game")


func set_toggled(value : bool):
	if value:
		set_disabled(true)
		toggled = true
	else:
		toggled = false
		set_disabled(false)


func set_disabled(value):
	if toggled:
		return
	.set_disabled(value)


func _pressed():
	Audio.play_click()
	if game.playerTurn == game.thisPlayer:
		game.end_turn()
