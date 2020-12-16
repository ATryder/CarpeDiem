extends Node2D

onready var replay = get_node("../../../")

var pix_width : float
var pix_height : float

var tilesToUpdate = []
var refresh := false
var clear := false

func _draw():
	if clear:
		clear = false
		return
	
	if refresh:
		for tile in replay.arena:
			if tile.asteroid || tile.star || !tile.collectors.empty():
				draw_tile(tile)
		refresh = false
		return
	
	if tilesToUpdate.empty():
		return
	
	for tile in tilesToUpdate:
		draw_tile(tile)
	tilesToUpdate.clear()

func draw_tile(tile : Dictionary):
	var points = PoolVector2Array()
	var color
	
	if !tile.collectors.empty():
		color = CD.get_player_color(tile.collectors[0].color) * 0.7
		color.a = 1
		if tile.star:
			color = color + Color(0.7, 0.7, 0.7, 0)
		elif tile.asteroid:
			color = color + Color(0.2, 0.2, 0.2, 0)
	elif tile.star:
		color = Color(1, 1, 1, 1)
	elif tile.asteroid:
		color = Color(0.6, 0.6, 0.6, 1.0)
	else:
		color = Color(0, 0, 0, 1)
	
	var half = pix_width / 2
	var quarter = pix_width / 4.0
	var halfHeight = pix_height / 2
	var loc = Vector2(get_tex_x(tile), get_tex_y(tile))
	draw_set_transform(loc, 0.0, Vector2(1, 1))

	points.push_back(Vector2(-half, 0))
	points.push_back(Vector2(-quarter, -halfHeight))
	points.push_back(Vector2(quarter, -halfHeight))
	points.push_back(Vector2(half, 0))
	points.push_back(Vector2(quarter, halfHeight))
	points.push_back(Vector2(-quarter, halfHeight))

	draw_colored_polygon(points, color)
	
	if (!tile.collectors.empty() && tile.collectors[0] == tile):
		draw_circle(Vector2(0, 0), half * 0.7, Color.white)


func get_tex_x(tile):
	var texx = tile.coord.x * (pix_width * 0.75)
	texx += pix_width * 0.5
	return texx


func get_tex_y(tile):
	var texy = tile.coord.y * pix_height
	texy += pix_height * 0.5
	if tile.shifted:
		texy += pix_height * 0.5
	return texy
