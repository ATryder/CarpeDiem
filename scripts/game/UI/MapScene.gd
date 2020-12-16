extends Node2D

export(Color) var fogColor := Color(0, 0, 0, 0.5)
export(Color) var unmappedColor := Color(0, 0, 0, 1)
export(Color) var fogColorDark := Color(0, 0, 0, 0.5)
export(Color) var unmappedColorDark := Color(0, 0, 0, 1)

var pix_width : float
var pix_height : float

var tilesToUpdate = []
var refresh := false

func _draw():
	var arena = get_parent().get_parent().infoView.hud.game.arena
	if !arena.LOADED:
		return
	
	if refresh:
		refresh = false
		for tile in arena.ARENA:
			draw_tile(tile)
		
		for tile in tilesToUpdate:
			tile.updateMap = false
		tilesToUpdate.clear()
		return
	
	if tilesToUpdate.empty():
		return
	
	for tile in tilesToUpdate:
		draw_tile(tile)
		tile.updateMap = false
	tilesToUpdate.clear()

func draw_tile(tile : CDTile):
	var fogColor
	var unmappedColor
	if Opts.theme == Opts.THEME_LIGHT:
		fogColor = self.fogColor
		unmappedColor = self.unmappedColor
	else:
		fogColor = fogColorDark
		unmappedColor = unmappedColorDark
	
	var hud = get_parent().get_parent().infoView.hud
	var points = PoolVector2Array()
	var color
	var alpha = 0
	if Opts.noFog:
		if !Opts.allVis && !tile.mapped[hud.game.thisPlayer]:
			color = unmappedColor
			alpha = 1
		elif !tile.collectors.empty():
			color = tile.collectors[0].player.get_color() * 0.7
			color.a = 1
			if tile.has_star():
				color = color + Color(0.7, 0.7, 0.7, 0)
			elif tile.has_asteroid():
				color = color + Color(0.2, 0.2, 0.2, 0)
		elif tile.has_star():
			color = Color(1, 1, 1, 1)
		elif tile.has_asteroid():
			color = Color(0.6, 0.6, 0.6, 1.0)
		else:
			color = Color(0, 0, 0, 1)
	elif Opts.allVis:
		if tile.is_visible(hud.game.thisPlayer):
			if !tile.collectors.empty():
				color = tile.collectors[0].player.get_color() * 0.7
				color.a = 1
				if tile.has_star():
					color = color + Color(0.7, 0.7, 0.7, 0)
				elif tile.has_asteroid():
					color = color + Color(0.2, 0.2, 0.2, 0)
			elif tile.has_star():
				color = Color(1, 1, 1, 1)
			elif tile.has_asteroid():
				color = Color(0.6, 0.6, 0.6, 1.0)
			else:
				color = Color(0, 0, 0, 1)
		else:
			if tile.lastSightedTerritory >= 0:
				color = hud.game.get_player(tile.lastSightedTerritory).get_color() * 0.7
				color.a = 1
				if tile.has_star():
					color = color + Color(0.7, 0.7, 0.7, 0)
				elif tile.has_asteroid():
					color = color + Color(0.2, 0.2, 0.2, 0)
			elif tile.has_star():
				color = Color(1, 1, 1, 1)
			elif tile.has_asteroid():
				color = Color(0.6, 0.6, 0.6, 1.0)
			else:
				color = Color(0, 0, 0, 1)
			color = color.blend(fogColor)
			alpha = 0.5
	elif tile.is_visible(hud.game.thisPlayer):
		if !tile.collectors.empty():
			color = tile.collectors[0].player.get_color() * 0.7
			color.a = 1
			if tile.has_star():
				color = color + Color(0.7, 0.7, 0.7, 0)
			elif tile.has_asteroid():
				color = color + Color(0.2, 0.2, 0.2, 0)
		elif tile.has_star():
			color = Color(1, 1, 1, 1)
		elif tile.has_asteroid():
			color = Color(0.6, 0.6, 0.6, 1.0)
		else:
			color = Color(0, 0, 0, 1)
	elif tile.mapped[hud.game.thisPlayer]:
		if tile.lastSightedTerritory >= 0:
			color = hud.game.get_player(tile.lastSightedTerritory).get_color() * 0.7
			color.a = 1
			if tile.has_star():
				color = color + Color(0.7, 0.7, 0.7, 0)
			elif tile.has_asteroid():
				color = color + Color(0.2, 0.2, 0.2, 0)
		elif tile.has_star():
			color = Color(1, 1, 1, 1)
		elif tile.has_asteroid():
			color = Color(0.6, 0.6, 0.6, 1.0)
		else:
			color = Color(0, 0, 0, 1)
		color = color.blend(fogColor)
		alpha = 0.5
	else:
		color = unmappedColor
	
	var half = pix_width / 2
	var quarter = pix_width / 4.0
	var halfHeight = pix_height / 2
	var loc = Vector2(tile.get_tex_x(pix_width, 0), tile.get_tex_y(pix_height, 0))
	draw_set_transform(loc, 0.0, Vector2(1, 1))

	points.push_back(Vector2(-half, 0))
	points.push_back(Vector2(-quarter, -halfHeight))
	points.push_back(Vector2(quarter, -halfHeight))
	points.push_back(Vector2(half, 0))
	points.push_back(Vector2(quarter, halfHeight))
	points.push_back(Vector2(-quarter, halfHeight))

	draw_colored_polygon(points, color)
	
	if (tile.ghostUnit != null
			|| (tile.is_occupied()
			&& tile.unit.type == CD.UNIT_COMMAND_STATION
			&& tile.is_visible(hud.game.thisPlayer))):
		draw_circle(Vector2(0, 0), half * 0.7, Color.white.blend(Color(fogColor.r, fogColor.g, fogColor.b, alpha)))
