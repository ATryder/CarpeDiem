extends PanelContainer_Themeable

var menuControl

var animating := true
onready var inAnim : ControlTrans_CheckerWipe = get_node("ControlTrans_CheckerWipe")
var outAnim : ControlTrans_CheckerWipe

var disabled := false


func _ready():
	outAnim = inAnim.duplicate()
	inAnim.callback = [self, "_on_display"]


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
