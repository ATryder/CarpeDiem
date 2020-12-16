extends Spatial

onready var game = get_node("/root/Game")
onready var arena = get_node("../Arena")
onready var hud = get_node("../HUDLayer")

const MAX_SPEED = 12.0
const MIN_SPEED = 2.5
const ACCEL = 10.5

const MAX_DRAG = 0.5
const MIN_DRAG = 0.05

const ZOOM_MAX = 200.0
const ZOOM_MIN = 40.0
const ZOOM_INCREMENT = 0.05

const AUTO_MOVE_LENGTH = 0.3

var zoomToAttacks := 1

var autoMove := false setget set_auto_move
var autoMoveTme := 0.0
var moveFrom : Vector3
var moveTo : Vector3

var lastNotify : Vector3

var vel = Vector2()

onready var camNode = get_node("CameraNode")
onready var cam = get_node("CameraNode/GameCam")

var zoom = 0.25


func _ready():
	set_process(false)


func map_initialized():
	transform.origin.x = arena.get_world_width() / 2
	transform.origin.z = arena.get_world_height() / 2


func game_loaded(mapGen):
	if mapGen is SaveLoader:
		transform.origin.x = mapGen.sg.loadedGame.camLoc.x
		transform.origin.z = mapGen.sg.loadedGame.camLoc.z
		zoom = clamp(mapGen.sg.loadedGame.camZoom, 0.0, 1.0)
		handle_zoom(1)
	else:
		var tile = mapGen.startPos[arena.get_parent().thisPlayer]
		transform.origin.x = tile.worldLoc.x
		transform.origin.z = tile.worldLoc.y
		handle_zoom(1)
		cam.far = 350
	set_process(true)


func _process(delta):
	var dir = Vector3()
	
	if !hud.is_focused() && (!hud.disabled || hud.debrief != null):
		if Input.is_action_pressed("camera_left"):
			dir += -transform.basis.x.normalized()
			autoMove = false
		if Input.is_action_pressed("camera_right"):
			dir += transform.basis.x.normalized()
			autoMove = false
		if Input.is_action_pressed("camera_up"):
			dir += -transform.basis.z.normalized()
			autoMove = false
		if Input.is_action_pressed("camera_down"):
			dir += transform.basis.z.normalized()
			autoMove = false
		if Input.is_action_pressed("zoom_to_area_of_interest"):
			if (!autoMove && lastNotify != null
					&& (moveFrom == null || moveFrom.distance_to(lastNotify) > CD.BASE_TILE_SIZE)):
				moveTo = lastNotify
				self.autoMove = true
		
		if dir.length() > 0:
			dir = dir.normalized()
	
	if autoMove:
		autoMoveTme += delta
		
		if autoMoveTme >= AUTO_MOVE_LENGTH:
			transform.origin = Vector3(moveTo.x, moveTo.y, moveTo.z)
			autoMove = false
			autoMoveTme = 0.0
		else:
			transform.origin = Math.fsmooth(moveFrom, moveTo, autoMoveTme / AUTO_MOVE_LENGTH)
	else:
		var maxSpeed = Math.fsmooth_stop(MAX_SPEED, MIN_SPEED, zoom)
		var target = Vector2(dir.x * maxSpeed, dir.z * maxSpeed)
		vel = vel.linear_interpolate(target, delta * ACCEL)
		transform.origin.x += vel.x
		transform.origin.z += vel.y
		transform.origin.x = clamp(transform.origin.x, 0, arena.get_world_width())
		transform.origin.z = clamp(transform.origin.z, 0, arena.get_world_height())
	
	handle_zoom(delta)


func handle_zoom(delta):
	if !hud.is_focused() && !hud.disabled:
		if Input.is_action_just_released("camera_zoom_out"):
			zoom = max(zoom - ZOOM_INCREMENT, 0)
		elif Input.is_action_just_released("camera_zoom_in"):
			zoom = min(zoom + ZOOM_INCREMENT, 1)
	
	cam.transform.origin.y = Math.fsmooth_stop(ZOOM_MAX, ZOOM_MIN, zoom)


func move_to(worldLoc : Vector3):
	transform.origin.x = clamp(worldLoc.x, 0, arena.get_world_width())
	transform.origin.z = clamp(worldLoc.z, 0, arena.get_world_height())


func move_by(pixAmount : Vector2):
	var speed = Math.fsmooth_stop(MAX_DRAG, MIN_DRAG, zoom)
	transform.origin.x += pixAmount.x * speed
	transform.origin.z += pixAmount.y * speed
	transform.origin.x = clamp(transform.origin.x, 0, arena.get_world_width())
	transform.origin.z = clamp(transform.origin.z, 0, arena.get_world_height())


func set_auto_move(value):
	if value && moveTo != null:
		moveFrom = Vector3(transform.origin.x, transform.origin.y, transform.origin.z)
		autoMove = true
		autoMoveTme = 0.0
	else:
		autoMove = false


func zoom_to_attack(attacker : Unit, defender : Unit):
	var defenderLoc = Vector3(defender.tile.worldLoc.x,
					0, defender.tile.worldLoc.y)
	if (zoomToAttacks == 0
			|| attacker.player.is_local_player()
			|| (zoomToAttacks > 1 && !defender.tile.is_visible(game.thisPlayer))
			|| (zoomToAttacks == 1 && !defender.player.is_local_player())
			|| transform.origin.distance_to(defenderLoc) <= CD.BASE_TILE_SIZE * 2):
		return
	
	set_area_of_interest(defenderLoc)


func set_area_of_interest(areaOfInterest : Vector3, move := true):
	lastNotify = areaOfInterest
	if move:
		transition_to(areaOfInterest)


func transition_to(location : Vector3):
	moveTo = location
	self.autoMove = true
