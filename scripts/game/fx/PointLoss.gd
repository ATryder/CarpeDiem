extends Label

const SPEED = 64
const LENGTH = 2.0

var tile
var tme := 0.0
onready var cam = get_node("/root/Game/CameraControl").cam
var y = 0.0

var origPos = rect_position


func _ready():
	modulate.a = 0
	if tile != null:
		var loc = cam.unproject_position(Vector3(tile.worldLoc.x, 0, tile.worldLoc.y))
		loc = Vector2(round(loc.x), round(loc.y))
		rect_position += loc


func set_points(value : int):
	text = str(value)
	if value <= 0:
		add_color_override("font_color", Color(0, 1, 0, 1))


func _process(delta):
	tme += delta
	if tme >= LENGTH:
		queue_free()
		return
	
	if tile == null:
		return
	
	var loc = cam.unproject_position(Vector3(tile.worldLoc.x, 0, tile.worldLoc.y))
	y -= SPEED * delta
	loc.y += y
	rect_position = loc + origPos
	
	if tme >= LENGTH * 0.8:
		modulate.a = Math.fsmooth(1.0, 0.0, (tme - (LENGTH * 0.8)) / (LENGTH * 0.2))
	else:
		modulate.a = Math.fsmooth(0.0, 1.0, min(1.0, tme / (LENGTH * 0.2)))
