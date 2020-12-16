extends Node2D

onready var arena = get_node("../../../")
onready var cc = get_node("../../")


func _draw():
	if (!arena.LOADED):
		return
	
	for x in range(arena.MAP_WIDTH):
		for y in range(arena.MAP_HEIGHT):
			var tile = arena.get_tile(x, y)
			if tile.color >= 0:
				draw_tile(tile)


func draw_tile(tile):
	var points = PoolVector2Array()
	var color = Color(CD.get_arena_color(tile.color))
	if tile.star == null:
		var mult = rand_range(0.15, 0.55)
		color *= mult
		color.a = 1.0
	else:
		color *= 1.3
		color.a = 1.0
	var half = cc.PIX_WIDTH / 2.0
	var quarter = cc.PIX_WIDTH/ 4.0
	var halfHeight = cc.PIX_HEIGHT / 2.0
	
	var loc = Vector2(tile.get_tex_x(cc.PIX_WIDTH), tile.get_tex_y(cc.PIX_HEIGHT))
	draw_set_transform(loc, 0.0, Vector2(1, 1))
	
	points.push_back(Vector2(-half, 0))
	points.push_back(Vector2(-quarter, -halfHeight))
	points.push_back(Vector2(quarter, -halfHeight))
	points.push_back(Vector2(half, 0))
	points.push_back(Vector2(quarter, halfHeight))
	points.push_back(Vector2(-quarter, halfHeight))
	
	draw_colored_polygon(points, color)
