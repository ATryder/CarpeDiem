extends PanelContainer_Themeable

onready var creditsAnim : AnimationPlayer = get_node("CreditsDisplay/AnimationPlayer")

var menuControl

var animating := true
onready var inAnim : ControlTrans_CheckerWipe = get_node("ControlTrans_CheckerWipe")
var outAnim : ControlTrans_CheckerWipe

var disabled := false


func _ready():
	outAnim = inAnim.duplicate()
	inAnim.callback = [self, "_on_display"]


func _on_display(anim):
	animating = false
	inAnim = null
	
	yield(get_tree().create_timer(1.0), "timeout")
	if !animating:
		creditsAnim.play("Credits")


func close():
	if menuControl != null:
		menuControl.menu = null
		menuControl.button_credits.pressed = false
	
	if animating && inAnim != null:
		inAnim.playOnStart = false
		inAnim.pause()
		inAnim.queue_free()
		Music.play_mainmenu()
		return
	
	Music.play_mainmenu()
	creditsAnim.stop()
	animating = true
	outAnim.reverse = true
	outAnim.reattach = false
	outAnim.set_control(self)
	outAnim.play()


func _input(event : InputEvent):
	if animating:
		return
	
	if event.is_action_released("ui_cancel"):
		close()
		get_tree().set_input_as_handled()
		return
