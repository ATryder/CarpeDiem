extends Node2D

onready var arena = get_node("../../../")
onready var fc = get_node("../../")

var tilesToUpdate = []


func _draw():
	if !arena.LOADED:
		return
	
	if tilesToUpdate.size() == 0:
		for x in range(arena.MAP_WIDTH):
			for y in range(arena.MAP_HEIGHT):
				var tile = arena.get_tile(x, y)
				draw_tile(tile)
		return
	
	for t in tilesToUpdate:
		draw_tile(t)
		t.updateFog = false
	tilesToUpdate.clear()


func draw_tile(tile):
	var points = PoolVector2Array()
	var color = Color(0, 0, 0, 1)
	if Opts.allVis == true:
		if Opts.noFog == true:
			color.r = 1
			color.g = 1
		else:
			color.r = 1
			if tile.unitVis[fc.game.thisPlayer] > 0:
				color.g = 1
	else:
		if tile.mapped[fc.game.thisPlayer] == true:
			color.r = 1
			if tile.unitVis[fc.game.thisPlayer] > 0:
				color.g = 1
	var half = fc.PIX_WIDTH / 2.0
	var quarter = fc.PIX_WIDTH/ 4.0
	var halfHeight = fc.PIX_HEIGHT / 2.0
	var loc = Vector2(tile.get_tex_x(fc.PIX_WIDTH), tile.get_tex_y(fc.PIX_HEIGHT))
	draw_set_transform(loc, 0.0, Vector2(1, 1))

	points.push_back(Vector2(-half, 0))
	points.push_back(Vector2(-quarter, -halfHeight))
	points.push_back(Vector2(quarter, -halfHeight))
	points.push_back(Vector2(half, 0))
	points.push_back(Vector2(quarter, halfHeight))
	points.push_back(Vector2(-quarter, halfHeight))

	draw_colored_polygon(points, color)
