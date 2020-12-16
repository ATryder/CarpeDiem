extends Area

onready var sel_hover = get_node("tile_hover")
onready var sel = get_node("tile_select")
onready var cc = get_node("/root/Game/CameraControl")
onready var arena = get_node("/root/Game/Arena")
onready var game = get_node("/root/Game")
onready var indicators = arena.get_node("ActionIndicators")

onready var hud = game.get_node("HUDLayer")

var clickedAt = Vector2()
var pressedWorld = Vector3()
var last = Vector2()

const DRAG_THRESHOLD = 10
const DRAG_THRESHOLD_INCH = 0.065
var isDragging = false
var isPressed = false

var multiTouch := []
var multiTouchDist = null
var isZooming = false

var hoveredTile setget set_hovered_tile, get_hovered_tile
var selectedTile setget set_selected_tile, get_selected_tile

var selectionCallback : MethodRef
var hoverCallback : MethodRef


func _ready():
	multiTouch.resize(2)
	set_process_input(false)


func game_loaded(mapGen):
	var width = mapGen.WIDTH * CD.TILE_WIDTH * 0.75
	width += CD.TILE_WIDTH  * 0.25
	var height = (mapGen.HEIGHT * CD.TILE_HEIGHT) + (CD.TILE_HEIGHT * 0.5)
	
	var shape : CollisionShape = get_node("CollisionShape")
	shape.global_transform.origin.x = width / 2
	shape.global_transform.origin.y = -0.0015 * CD.TILE_WIDTH
	shape.global_transform.origin.z = height / 2
	width += CD.TILE_WIDTH * 50
	height += CD.TILE_HEIGHT * 50
	shape.shape.extents = Vector3(width / 2, 0.003 * CD.TILE_WIDTH, height / 2)
	
	if mapGen is SaveLoader:
		var tile = arena.world_to_tile(mapGen.sg.loadedGame.camLoc)
		if tile == null:
			set_hovered_tile(arena.ARENA[0])
			set_selected_tile(arena.ARENA[0])
			set_selected_tile(null)
		else:
			set_hovered_tile(tile)
			set_selected_tile(tile)
			set_selected_tile(null)
	else:
		set_hovered_tile(mapGen.startPos[game.thisPlayer])
		set_selected_tile(mapGen.startPos[game.thisPlayer])
	set_process_input(true)


func _process(delta):
	if isZooming && multiTouch[0] == null && multiTouch[1] == null:
		isZooming = false
		return
	
	if hud.is_focused() || multiTouch[0] == null || multiTouch[1] == null:
		return
	
	if multiTouchDist == null:
		multiTouchDist = multiTouch[0].distance_to(multiTouch[1])
		return
	
	var newDist = multiTouch[0].distance_to(multiTouch[1])
	var amount = (multiTouchDist - newDist) / OS.get_screen_dpi()
	multiTouchDist = newDist
	cc.zoom = clamp(cc.zoom - amount, 0, 1)


func _input_event(camera, event, position, normal, shape_idx):
	if !game.LOADED || hud.is_focused():
		return
	
	if event is InputEventScreenDrag:
		if event.index == 0:
			if (multiTouch[1] == null
					&& (isDragging
					|| (isPressed
					&& event.position.distance_to(clickedAt) > DRAG_THRESHOLD_INCH * OS.get_screen_dpi()))):
				isDragging = true
				cc.move_by(Math.fsmooth_stop(last - event.position, (last - event.position) * 3, cc.zoom))
			last.x = event.position.x
			last.y = event.position.y
			multiTouch[0] = event.position
		elif event.index == 1:
			isDragging = false
			multiTouch[1] = event.position
		get_tree().set_input_as_handled()
	elif event is InputEventScreenTouch:
		if event.index > 1:
			return
		
		if event.is_pressed():
			if event.index == 0:
				clickedAt.x = event.position.x
				clickedAt.y = event.position.y
				pressedWorld = null
				isPressed = true
				last.x = event.position.x
				last.y = event.position.y
				isZooming = false
			else:
				isZooming = true
			multiTouch[event.index] = event.position
		else:
			multiTouch[event.index] = null
			multiTouchDist = null
			
			if event.index == 0:
				if isDragging:
					cc.move_by(Math.fsmooth_stop(last - event.position, (last - event.position) * 3, cc.zoom))
					isDragging = false
				elif game.is_local_turn() && !game.FIN && !isZooming:
					var tile = arena.world_to_tile(position)
					if hoveredTile != null && hoveredTile == tile:
						set_selected_tile(tile)
					else:
						set_hovered_tile(tile)
					Audio.play_click()
				isPressed = false
				last.x = event.position.x
				last.y = event.position.y
		get_tree().set_input_as_handled()
	
	if isZooming || (multiTouch[0] != null || multiTouch[1] != null):
		return
	
	if event is InputEventMouseMotion:
		if isDragging or (isPressed and event.position.distance_to(clickedAt) > DRAG_THRESHOLD):
			isDragging = true
			cc.move_by(Math.fsmooth_stop(last - event.position, (last - event.position) * 3, cc.zoom))
		last.x = event.position.x
		last.y = event.position.y
		get_tree().set_input_as_handled()
	elif event is InputEventMouseButton:
		if event.button_index == BUTTON_LEFT:
			if event.is_pressed():
				clickedAt.x = event.position.x
				clickedAt.y = event.position.y
				if pressedWorld == null:
					pressedWorld = Vector3(position.x, 0, position.z)
				else:
					pressedWorld.x = position.x
					pressedWorld.z = position.z
				isPressed = true
				last.x = event.position.x
				last.y = event.position.y
			elif pressedWorld != null:
				if isDragging:
					cc.move_by(Math.fsmooth_stop(last - event.position, (last - event.position) * 3, cc.zoom))
					isDragging = false
				elif game.is_local_turn() && !game.FIN:
					var tile = arena.world_to_tile(pressedWorld)
					if hoveredTile != null && hoveredTile == tile:
						set_selected_tile(tile)
					else:
						set_hovered_tile(tile)
					Audio.play_click()
				isPressed = false
				last.x = event.position.x
				last.y = event.position.y
		elif event.button_index == BUTTON_RIGHT:
			if !event.is_pressed():
				if game.hud.action_buttons_active() && game.hud.actionButtonDisplay.is_action_active():
					game.hud.actionButtonDisplay.clear_action()
					Audio.play_click()
				elif selectedTile != null:
					set_selected_tile(null)
					Audio.play_click()
		get_tree().set_input_as_handled()


func set_hovered_tile(tile):
	if tile == null || tile == hoveredTile:
		return
	
	hoveredTile = tile
	sel_hover.global_transform.origin.x = tile.worldLoc.x
	sel_hover.global_transform.origin.z = tile.worldLoc.y
	hud.hoveredTileDisplay.set_tile(hoveredTile)
	
	if hoverCallback != null:
		if hoverCallback.args.empty():
			hoverCallback.cls.call(hoverCallback.method, tile)
		else:
			hoverCallback.args.append(tile)
			hoverCallback.exec()
			if hoverCallback != null:
				hoverCallback.args.pop_back()
		return
	
	if (selectedTile != null && selectedTile.is_occupied()
			&& selectedTile.get_player().is_local_player()
			&& selectedTile.unit.type == CD.UNIT_CARGOSHIP):
		indicators.clear()
		
		var collectionRange = Math.get_tile_range(hoveredTile,
				CD.COMMAND_STATION_RESOURCE_RANGE)
		var cr := []
		var crNo := []
		for t in collectionRange:
			if !t.is_visible(game.thisPlayer) || !t.is_collected():
				cr.push_back(t)
			else:
				crNo.push_back(t)
		
		if !cr.empty() || !crNo.empty():
			indicators.activate_range_indicator(hoveredTile, cr,
					indicators.collectionColor1, indicators.collectionColor2, 0.65,
					crNo, indicators.collectionColor3, indicators.collectionColor4,
					true)
			indicators.rangeIndicator.rspeed *= 0.75
	
	game.emit_signal("tile_hovered", hoveredTile)


func get_hovered_tile():
	return hoveredTile


func set_selected_tile(tile):
	if selectionCallback != null:
		if selectionCallback.args.empty():
			selectionCallback.cls.call(selectionCallback.method, tile)
		else:
			selectionCallback.args.append(tile)
			selectionCallback.exec()
			if selectionCallback != null:
				selectionCallback.args.pop_back()
		return
	
	if hud.actionButtonDisplay != null:
		hud.close_action_button_display()
	
	indicators.clear()
	
	if tile == null or tile == selectedTile:
		sel.hide()
		selectedTile = null
		hud.selectedTileDisplay.clear_selection_display()
		return
	
	selectedTile = tile
	sel.global_transform.origin.x = tile.worldLoc.x
	sel.global_transform.origin.z = tile.worldLoc.y
	sel.show()
	hud.selectedTileDisplay.set_tile(selectedTile)
	
	game.emit_signal("tile_selected", selectedTile)
	
	if tile.get_player_number() == game.thisPlayer:
		hud.display_action_buttons(selectedTile)
	elif tile.is_occupied() && tile.is_visible(game.thisPlayer):
		var riscn = preload("res://models/shape/range indicator/RangeIndicator.tscn")
		var totalTiles = tile.unit.get_total_attack_range()
		
		if totalTiles.attackTiles.empty():
			if !totalTiles.moveTiles.empty():
				indicators.activate_range_indicator(tile,
					totalTiles.moveTiles,
					indicators.moveColor1,
					indicators.moveColor2)
			return
		
		if totalTiles.moveTiles.empty():
			indicators.activate_range_indicator(tile,
				totalTiles.attackTiles,
				indicators.attackColor1,
				indicators.attackColor2)
		else:
			indicators.activate_range_indicator(tile,
				totalTiles.moveTiles,
				indicators.moveColor1,
				indicators.moveColor2,
				1.0,
				totalTiles.attackTiles,
				indicators.attackColor1,
				indicators.attackColor2)


func get_selected_tile():
	return selectedTile
