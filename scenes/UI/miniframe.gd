extends Sprite

const FRAME_PURPLE : AtlasTexture = preload("res://textures/UI/frame_purple48.atlastex")

const FRAME_BLUE : AtlasTexture = preload("res://textures/UI/frame_blue48.atlastex")

const FRAME_GREEN : AtlasTexture = preload("res://textures/UI/frame_green48.atlastex")

const FRAME_RED : AtlasTexture = preload("res://textures/UI/frame_red48.atlastex")

const FRAME_ORANGE : AtlasTexture = preload("res://textures/UI/frame_orange48.atlastex")

const FRAME_YELLOW : AtlasTexture = preload("res://textures/UI/frame_yellow48.atlastex")

const FRAME_GRAY : AtlasTexture = preload("res://textures/UI/frame_gray48.atlastex")

onready var iconDisplay = get_node("Icon")
var display : Texture setget set_display, get_display

func set_display(texture : Texture):
	display = texture
	iconDisplay.visible = texture != null
	iconDisplay.texture = texture

func get_display() -> Texture:
	return display

func set_frame_blue():
	texture = FRAME_BLUE

func set_frame_purple():
	texture = FRAME_PURPLE

func set_frame_yellow():
	texture = FRAME_YELLOW

func set_frame_green():
	texture = FRAME_GREEN

func set_frame_orange():
	texture = FRAME_ORANGE

func set_frame_red():
	texture = FRAME_RED

func set_frame_gray():
	texture = FRAME_GRAY
