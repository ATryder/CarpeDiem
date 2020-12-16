extends CenterContainer

export(StyleBox) var lightBackground
export(StyleBox) var darkBackground

onready var game = get_node("/root/Game")


onready var label = get_node("Panel/Label")
onready var anim = get_node("ControlTrans_Blinds")

var animating := true
var finishing := false


func _ready():
	anim.callback = [self, "_on_display"]
	
	if Opts.theme != Opts.THEME_LIGHT:
		change_theme(Opts.THEME_LIGHT, Opts.theme)


func _on_display(anim = null):
	animating = false
	if finishing:
		game.hud.turnIndicator = null
	elif anim.controlFrom != null:
		anim.controlFrom.free()
		anim.controlFrom = null


func next_player(player : Player):
	if player.num == game.thisPlayer:
		anim.color = player.get_color()
		finish()
		return
	
	var dup = duplicate(0)
	
	anim.color = player.get_color()
	label.text = player.handle
	label.add_color_override("font_color", player.get_color())
	animating = true
	anim.to_start()
	anim.set_transition(dup, self)
	anim.play(true, true)
	anim._process(0.00001)


func finish():
	anim.reattach = false
	anim.freeOnEnd = true
	anim.reverse = true
	animating = true
	finishing = true
	anim.to_start()
	anim.set_control(self)
	anim.play(true, true)
	anim._process(0.00001)


func change_theme(oldTheme, newTheme):
	if newTheme == Opts.THEME_DARK:
		get_node("Panel").add_stylebox_override("panel", darkBackground)
		label.add_color_override("font_outline_modulate", Color(0.7, 0.7, 0.7, 1))
	else:
		get_node("Panel").add_stylebox_override("panel", lightBackground)
		label.add_color_override("font_outline_modulate", Color(1, 1, 1, 1))


func cleanup():
	if anim != null && anim.get_parent() == null:
		anim.queue_free()
