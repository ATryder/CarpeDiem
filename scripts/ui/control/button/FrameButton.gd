extends Button
class_name FrameButton

const FRAME_BUTTON_PURPLE := [
	preload("res://styles/button/frame/framebutton_purple.stylebox"),
	preload("res://styles/button/frame/framebutton_purple_glow.stylebox"),
	preload("res://styles/button/frame/framebutton_cyan_glow.stylebox")
	]

const FRAME_BUTTON_BLUE := [
	preload("res://styles/button/frame/framebutton_blue.stylebox"),
	preload("res://styles/button/frame/framebutton_blue_glow.stylebox"),
	preload("res://styles/button/frame/framebutton_orange_glow.stylebox")
	]

const FRAME_BUTTON_GREEN := [
	preload("res://styles/button/frame/framebutton_green.stylebox"),
	preload("res://styles/button/frame/framebutton_green_glow.stylebox"),
	preload("res://styles/button/frame/framebutton_cyan_glow.stylebox")
	]

const FRAME_BUTTON_RED := [
	preload("res://styles/button/frame/framebutton_red.stylebox"),
	preload("res://styles/button/frame/framebutton_red_glow.stylebox"),
	preload("res://styles/button/frame/framebutton_orange_glow.stylebox")
	]

const FRAME_BUTTON_ORANGE := [
	preload("res://styles/button/frame/framebutton_orange.stylebox"),
	preload("res://styles/button/frame/framebutton_orange_glow.stylebox"),
	preload("res://styles/button/frame/framebutton_yellow_glow.stylebox")
	]

const FRAME_BUTTON_YELLOW := [
	preload("res://styles/button/frame/framebutton_yellow.stylebox"),
	preload("res://styles/button/frame/framebutton_yellow_glow.stylebox"),
	preload("res://styles/button/frame/framebutton_blue_glow.stylebox")
	]

const FRAME_BUTTON_GRAY := [
	preload("res://styles/button/frame/framebutton_gray.stylebox"),
	preload("res://styles/button/frame/framebutton_gray_glow.stylebox"),
	preload("res://styles/button/frame/framebutton_cyan_glow.stylebox")
	]

const FRAME_BUTTON_CYAN := [
	preload("res://styles/button/frame/framebutton_cyan.stylebox"),
	preload("res://styles/button/frame/framebutton_cyan_glow.stylebox"),
	preload("res://styles/button/frame/framebutton_yellow_glow.stylebox")
	]

onready var iconDisplay = get_node("Icon")
var display : Texture setget set_display, get_display

onready var selector = get_node("FrameSelector")
var selected := false setget set_selected, is_selected

export(PackedScene) var transitionEffect
var anim : ControlTransition


func set_display(texture : Texture):
	display = texture
	iconDisplay.visible = texture != null
	iconDisplay.texture = texture


func get_display() -> Texture:
	return display


func transition(parent = null, play := true):
	var oldFrame := duplicate()
	anim = transitionEffect.instance()
	if parent == null:
		parent = self.get_parent()
	anim.set_transition(oldFrame, self, parent)
	anim.play(play)


func set_selected(value : bool, animate : bool = true):
	if selected == value:
		return
		
	selected = value
	if animate:
		if value:
			selector.visible = true
			selector.animation = "Intro"
		else:
			selector.animation = "Outtro"
		selector.frame = 0
		selector.playing = true
	elif value:
		selector.stop()
		selector.visible = true
		selector.animation = "Intro"
		selector.frame = 7
	else:
		selector.stop()
		selector.visible = false


func is_selected() -> bool:
	return selected


func _on_animation_finished():
	selector.frame = 7
	if !selected:
		selector.visible = false


func set_frame_blue(frame : Button):
	frame.add_stylebox_override("normal",
			FRAME_BUTTON_BLUE[0])
	frame.add_stylebox_override("hover",
			FRAME_BUTTON_BLUE[1])
	frame.add_stylebox_override("pressed",
			FRAME_BUTTON_BLUE[2])


func set_frame_purple(frame : Button):
	frame.add_stylebox_override("normal",
			FRAME_BUTTON_PURPLE[0])
	frame.add_stylebox_override("hover",
			FRAME_BUTTON_PURPLE[1])
	frame.add_stylebox_override("pressed",
			FRAME_BUTTON_PURPLE[2])


func set_frame_yellow(frame : Button):
	frame.add_stylebox_override("normal",
			FRAME_BUTTON_YELLOW[0])
	frame.add_stylebox_override("hover",
			FRAME_BUTTON_YELLOW[1])
	frame.add_stylebox_override("pressed",
			FRAME_BUTTON_YELLOW[2])


func set_frame_green(frame : Button):
	frame.add_stylebox_override("normal",
			FRAME_BUTTON_GREEN[0])
	frame.add_stylebox_override("hover",
			FRAME_BUTTON_GREEN[1])
	frame.add_stylebox_override("pressed",
			FRAME_BUTTON_GREEN[2])


func set_frame_orange(frame : Button):
	frame.add_stylebox_override("normal",
			FRAME_BUTTON_ORANGE[0])
	frame.add_stylebox_override("hover",
			FRAME_BUTTON_ORANGE[1])
	frame.add_stylebox_override("pressed",
			FRAME_BUTTON_ORANGE[2])


func set_frame_red(frame : Button):
	frame.add_stylebox_override("normal",
			FRAME_BUTTON_RED[0])
	frame.add_stylebox_override("hover",
			FRAME_BUTTON_RED[1])
	frame.add_stylebox_override("pressed",
			FRAME_BUTTON_RED[2])


func set_frame_gray(frame : Button):
	frame.add_stylebox_override("normal",
			FRAME_BUTTON_GRAY[0])
	frame.add_stylebox_override("hover",
			FRAME_BUTTON_GRAY[1])
	frame.add_stylebox_override("pressed",
			FRAME_BUTTON_GRAY[2])


func set_frame_cyan(frame : Button):
	frame.add_stylebox_override("normal",
			FRAME_BUTTON_CYAN[0])
	frame.add_stylebox_override("hover",
			FRAME_BUTTON_CYAN[1])
	frame.add_stylebox_override("pressed",
			FRAME_BUTTON_CYAN[2])
