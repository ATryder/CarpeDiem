extends TextureRect

onready var infoView = get_node("/root/Game").hud.infoView
onready var cameraCont = get_node("/root/Game/CameraControl")
onready var vp = get_node("MapViewport")
onready var map = get_node("MapViewport/MapScene")


func initialize_map():
	var arena = get_node("/root/Game/Arena")
	rect_size = Vector2(rect_size.x, round(rect_size.x * (arena.get_world_height() / arena.get_world_width())))
	vp.size = rect_size
	vp.get_texture().set_flags(0)
	texture = vp.get_texture()
	map.pix_width = (rect_size.x / arena.get_arena_tex_width(10, 0)) * 10.0
	map.pix_height = (rect_size.y / arena.get_arena_tex_height(10, 0)) * 10.0
	refresh()


func refresh():
	map.refresh = true
	vp.render_target_update_mode = Viewport.UPDATE_ONCE
	vp.render_target_clear_mode = Viewport.CLEAR_MODE_ONLY_NEXT_FRAME
	map.update()


func is_refreshing() -> bool:
	#render target always returns Viewport.UPDATE_ONCE
	return false
	#return vp.render_target_update_mode == Viewport.UPDATE_ONCE


func update_tile(tile : CDTile):
	if tile.updateMap:
		return
	
	if map.tilesToUpdate.empty():
		map.update()
		vp.render_target_update_mode = Viewport.UPDATE_ONCE
	
	tile.updateMap = true
	map.tilesToUpdate.push_back(tile)


func _gui_input(event):
	if (infoView.disabled
			|| infoView.hud.is_focused()
			|| !(event is InputEventMouseButton)
			|| event.button_index != BUTTON_LEFT
			|| event.pressed
			|| event.position.x < 0
			|| event.position.x > rect_size.x
			|| event.position.y < 0
			|| event.position.y > rect_size.y):
		return
	
	var worldLoc := Vector3(event.position.x / rect_size.x,
		0, event.position.y / rect_size.y)
	worldLoc.x *= infoView.hud.game.arena.get_world_width()
	worldLoc.z *= infoView.hud.game.arena.get_world_height()
	cameraCont.move_to(worldLoc)
