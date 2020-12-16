extends Node2D
class_name QuickInfo

var unit setget set_unit, get_unit

onready var leftind = get_node("leftind")
onready var circleind = get_node("circle")
onready var strength = get_node("StrengthIndicator")

onready var cam = get_node("/root/Game/CameraControl").cam
onready var arena = get_node("/root/Game/Arena")

var arrowind
var attackind
var mpaind
var rightind

var mpaind_full
var mpaind_reg

func _ready():
	if has_node("mpaind"):
		mpaind_full = load("res://textures/QuickInfo/quickinfo_icon_crates_active.atlastex")
		
		if has_node("buildind"):
			leftind = get_node("buildind")
		mpaind = get_node("mpaind")
		mpaind_reg = mpaind.texture
		arrowind = get_node("arrowind")
		attackind = get_node("attackind")
		if unit != null:
			init_display_for_player()
			update_display()
	else:
		rightind = get_node("rightind")
		if unit != null:
			rightind.self_modulate = unit.player.get_color()
			leftind.self_modulate = unit.player.get_color()
			update_display()
	_process(1.0)


func set_unit(value):
	if unit == null:
		unit = value
		if mpaind != null:
			init_display_for_player()
			update_display()
		elif rightind != null:
			rightind.self_modulate = unit.player.get_color()
			leftind.self_modulate = unit.player.get_color()
			update_display()
		unit.qInfo = self


func get_unit():
	return unit


func init_display_for_player():
	var background = get_node("background")
	if unit.get_max_mpa() <= 0:
		mpaind.queue_free()
		mpaind = null
		background.rect_size = Vector2(background.rect_size.x - 12,
										background.rect_size.y)
	if unit.max_attacks <= 0:
		attackind.queue_free()
		attackind = null
		if mpaind != null:
			mpaind.position = Vector2(mpaind.position.x - 12, mpaind.position.y)
		background.rect_size = Vector2(background.rect_size.x - 12,
										background.rect_size.y)
	if unit.max_moves <= 0:
		arrowind.queue_free()
		arrowind = null
		if mpaind != null:
			mpaind.position = Vector2(mpaind.position.x - 12, mpaind.position.y)
		if attackind != null:
			attackind.position = Vector2(attackind.position.x - 12, attackind.position.y)
		background.rect_size = Vector2(background.rect_size.x - 12,
										background.rect_size.y)
	
	if unit.type != CD.UNIT_COMMAND_STATION:
		leftind.queue_free()
		leftind = null
		#leftind.self_modulate = unit.player.get_color()


func update_display():
	if unit == null:
		return
	
	update_strength()
	
	if !unit.player.is_local_player():
		return
	
	update_icons()
	
	if unit.type != CD.UNIT_COMMAND_STATION:
		return
	
	update_build()


func update_strength():
	strength.text = str(unit.strength)
	var perc = unit.strength / float(unit.maxStrength)
	if (perc <= 0.2):
		circleind.self_modulate = Color(1, 0, 0)
	elif (perc <= 0.5):
		circleind.self_modulate = Color(1, 0.6, 0)
	elif (perc <= 0.8):
		circleind.self_modulate = Color(1, 1, 0)
	else:
		circleind.self_modulate = Color(0, 1, 0)


func update_icons():
	if arrowind != null:
		if unit.moves > 0:
			arrowind.show()
		else:
			arrowind.hide()
	if attackind != null:
		if unit.attacks > 0:
			attackind.show()
		else:
			attackind.hide()
	if mpaind != null:
		if unit.mpa > 0:
			if unit.type == CD.UNIT_CARGOSHIP && unit.mpa >= CD.CARGOSHIP_MAX_MPA:
				mpaind.texture = mpaind_full
			else:
				mpaind.texture = mpaind_reg
			mpaind.show()
		else:
			mpaind.hide()


func update_build():
	if leftind == null:
		return
	
	var buildItem = unit.buildItem
	if buildItem == null:
		leftind.set_display(null)
		leftind.set_frame_gray()
		return
	
	leftind.set_display(buildItem.get_icon())
	var turns = buildItem.get_remaining_turns(unit)
	if turns == INF:
		leftind.set_frame_red()
	elif turns == 0:
		if (buildItem.get_type() == CD.UNIT_MPA
				&& unit.mpa >= unit.get_max_mpa()):
			leftind.set_frame_red()
		else:
			leftind.set_frame_green()
	elif turns >= BuildMenu.MANYTURNS:
		leftind.set_frame_orange()
	else:
		leftind.set_frame_yellow()


func _process(delta):
	var loc = cam.unproject_position(unit.global_transform.origin
			+ Vector3(-CD.TILE_WIDTH * 0.25, 0, -CD.TILE_HEIGHT * 0.45))
	loc = Vector2(round(loc.x), round(loc.y))
	transform.origin = loc
	z_index = (arena.MAP_HEIGHT - unit.tile.y) + unit.tile.x
