extends CenterContainer

onready var cam = get_node("/root/Game/CameraControl").cam
var tile : CDTile

var anim
var outAnim

var opening := true
var closing := false


func _ready():
	if anim == null:
		anim = get_node("MarginContainer/ControlTrans_ContraWipe")
	outAnim = anim.duplicate()
	anim.callback = [self, "_on_display"]
	_process(1.0)


func set_attacker(player : Player, type : int, estimatedLoss : int):
	get_node("MarginContainer/VBoxContainer/AttackerPanel/IconFrame/Icon").texture = CD.unit_icons[type]
	if estimatedLoss > 0:
		get_node("MarginContainer/VBoxContainer/AttackerPanel/Value").text = "-" + str(estimatedLoss)
	else:
		get_node("MarginContainer/VBoxContainer/AttackerPanel/Value").text = "0"
	
	var c = player.get_color()
	if anim == null:
		anim = get_node("MarginContainer/ControlTrans_ContraWipe")
	anim.color = c
	var panel = get_node("MarginContainer/VBoxContainer/AttackerPanel")
	panel.get_stylebox("panel", "").border_color = c
	
	get_node("MarginContainer/VBoxContainer/AttackerPanel/IconFrame").texture = CD.get_player_frame(player.color)


func set_defender(player : Player, type : int, estimatedLoss : int):
	get_node("MarginContainer/VBoxContainer/DefenderPanel/IconFrame/Icon").texture = CD.unit_icons[type]
	if estimatedLoss > 0:
		get_node("MarginContainer/VBoxContainer/DefenderPanel/Value").text = "-" + str(estimatedLoss)
	else:
		get_node("MarginContainer/VBoxContainer/DefenderPanel/Value").text = "0"
	
	var c = player.get_color()
	if anim == null:
		anim = get_node("MarginContainer/ControlTrans_ContraWipe")
	anim.color2 = c
	var panel = get_node("MarginContainer/VBoxContainer/DefenderPanel")
	panel.get_stylebox("panel", "").border_color = c
	
	get_node("MarginContainer/VBoxContainer/DefenderPanel/IconFrame").texture = CD.get_player_frame(player.color)


func _on_display(animation = null):
	opening = false
	if closing:
		closing = false
		close()


func close():
	if closing:
		return
	
	closing = true
	
	if opening:
		anim.pause()
		_finish()
		return
	
	outAnim.reverse = true
	outAnim.reattach = false
	outAnim.set_control(get_node("MarginContainer"))
	outAnim.callback = [self, "_finish"]
	outAnim.play()


func _finish(animation = null):
	queue_free()


func _process(delta):
	if tile == null:
		return
	
	var loc = Vector3(tile.worldLoc.x + CD.TILE_HALF_WIDTH, 0.0, tile.worldLoc.y)
	loc = cam.unproject_position(loc)
	loc.x = round(loc.x - 24)
	loc.y = round(loc.y - (rect_size.y / 2))
	rect_position = loc
