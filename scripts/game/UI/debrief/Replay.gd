extends VBoxContainer

const playNormal = preload("res://textures/UI/buttons/playback/play.atlastex")
const playHover = preload("res://textures/UI/buttons/playback/play_hover.atlastex")
const playPressed = preload("res://textures/UI/buttons/playback/play_pressed.atlastex")
const playDisabled = preload("res://textures/UI/buttons/playback/play_disabled.atlastex")

const pauseNormal = preload("res://textures/UI/buttons/playback/pause.atlastex")
const pauseHover = preload("res://textures/UI/buttons/playback/pause_hover.atlastex")
const pausePressed = preload("res://textures/UI/buttons/playback/pause_pressed.atlastex")
const pauseDisabled = preload("res://textures/UI/buttons/playback/pause_disabled.atlastex")

var MAP_WIDTH : int
var MAP_HEIGHT : int

export(float) var fps := 5.0

onready var display = get_node("Display")
onready var vpFrame = display.get_node("vpFrame")
onready var scene = vpFrame.get_node("ReplayScene")
onready var firstFrame = vpFrame.get_node("FirstFrame")
onready var firstFrameVP = display.get_node("vpMap")
onready var replayProgress = get_node("MarginContainer/HBoxContainer/ReplayProgress")

var arena := []
var frames := []
var frame := 0

var tme := 0.0
var pause := false
var interval := 1.0 / fps


func _ready():
	set_process(false)
	
	var ffScene = firstFrameVP.get_node("ReplayScene")
	var arenasp = get_node("/root/Game").arena
	MAP_WIDTH = arenasp.MAP_WIDTH
	MAP_HEIGHT = arenasp.MAP_HEIGHT
	
	var texRes = Vector2()
	texRes.y = display.rect_size.y
	texRes.x = round(texRes.y * (arenasp.get_world_width() / arenasp.get_world_height()))
	
	firstFrameVP.size = texRes
	firstFrameVP.get_texture().set_flags(0)
	vpFrame.size = texRes
	vpFrame.get_texture().set_flags(0)
	
	firstFrame.texture = firstFrameVP.get_texture()
	display.texture = vpFrame.get_texture()
	
	scene.pix_width = (texRes.x / arenasp.get_arena_tex_width(10, 0)) * 10.0
	scene.pix_height = (texRes.y / arenasp.get_arena_tex_height(10, 0)) * 10.0
	ffScene.pix_width = scene.pix_width
	ffScene.pix_height = scene.pix_height
	
	arena.resize(MAP_WIDTH * MAP_HEIGHT)
	for x in range(MAP_WIDTH):
		var xCoord = x * MAP_HEIGHT
		for y in range(MAP_HEIGHT):
			var cdt = arenasp.get_tile(x, y)
			arena[xCoord + y] = {"coord": Vector2i.new(x, y),
								"color": -1,
								"collectors": [],
								"star": cdt.has_star(),
								"asteroid": cdt.has_asteroid(),
								"shifted": x % 2 != 0}
	
	set_process(false)


func _pause():
	if is_processing():
		var playButton = get_node("MarginContainer/HBoxContainer/button_play")
		playButton.disconnect("button_up", self, "_pause")
		playButton.connect("button_up", self, "_play")
		playButton.texture_normal = playNormal
		playButton.texture_hover = playHover
		playButton.texture_pressed = playPressed
		playButton.texture_disabled = playDisabled
	
	set_process(false)


func _play():
	var playButton = get_node("MarginContainer/HBoxContainer/button_play")
	playButton.disconnect("button_up", self, "_play")
	playButton.connect("button_up", self, "_pause")
	playButton.texture_normal = pauseNormal
	playButton.texture_hover = pauseHover
	playButton.texture_pressed = pausePressed
	playButton.texture_disabled = pauseDisabled
	
	if frame >= frames.size() - 1:
		tme = 0.0
		frame = 0
		replayProgress.value = 0.0
		firstFrame.show()
		vpFrame.render_target_update_mode = Viewport.UPDATE_ONCE
		vpFrame.render_target_clear_mode = Viewport.CLEAR_MODE_ONLY_NEXT_FRAME
		scene.tilesToUpdate.clear()
		scene.clear = true
		scene.update()
		for tile in arena:
			tile.color = -1
			tile.collectors.clear()
	
	set_process(true)


func _stop():
	if (self.is_processing()):
		var playButton = get_node("MarginContainer/HBoxContainer/button_play")
		playButton.disconnect("button_up", self, "_pause")
		playButton.connect("button_up", self, "_play")
		playButton.texture_normal = playNormal
		playButton.texture_hover = playHover
		playButton.texture_pressed = playPressed
		playButton.texture_disabled = playDisabled
	
	set_process(false)
	
	tme = 0.0
	if frame == 0:
		return
	
	frame = 0
	replayProgress.value = 0.0
	firstFrame.show()
	vpFrame.render_target_update_mode = Viewport.UPDATE_ONCE
	vpFrame.render_target_clear_mode = Viewport.CLEAR_MODE_ONLY_NEXT_FRAME
	scene.tilesToUpdate.clear()
	scene.clear = true
	scene.update()
	for tile in arena:
		tile.color = -1
		tile.collectors.clear()


func _process(delta):
	tme += delta
	if tme < interval:
		return
	
	var advance = int(floor(tme / interval))
	tme = tme - (interval * advance)
	if advance == 0:
		return
	
	var tilesToUpdate = advance_frames(advance)
	replayProgress.value = float(frame) / (frames.size() - 1)
	
	if !tilesToUpdate.empty():
		firstFrame.hide()
		vpFrame.render_target_update_mode = Viewport.UPDATE_ONCE
		scene.tilesToUpdate = tilesToUpdate
		scene.update()
	
	if frame >= frames.size() - 1:
		_pause()


func advance_frames(advance) -> Array:
	var tilesToUpdate := []
	
	if advance + frame >= frames.size():
		advance = frames.size() - 1 - frame
	
	var collectionRange := []
	for i in range(advance):
		frame += 1
		var f = frames[frame]
		for station in f.stationsRem:
			var origin = get_tile(station.tile.x, station.tile.y)
			get_resource_tiles(origin, collectionRange)
			if !tilesToUpdate.has(origin):
				tilesToUpdate.push_back(origin)
			
			for tile in collectionRange:
				tile.collectors.erase(origin)
				if tile.collectors.empty():
					tile.color = -1
					if !tilesToUpdate.has(tile):
						tilesToUpdate.push_back(tile)
				elif tile.color != tile.collectors[0].color:
					tile.color = tile.collectors[0].color
					if !tilesToUpdate.has(tile):
						tilesToUpdate.push_back(tile)
		
		for station in f.stationsAdd:
			var origin = get_tile(station.tile.x, station.tile.y)
			get_resource_tiles(origin, collectionRange)
			if !tilesToUpdate.has(origin):
				tilesToUpdate.push_back(origin)
			
			for tile in collectionRange:
				tile.collectors.push_back(origin)
				if tile.color < 0:
					tile.color = station.color
					if !tilesToUpdate.has(tile):
						tilesToUpdate.push_back(tile)
	
	return tilesToUpdate


func get_tile(x : int, y : int):
	return arena[(x * MAP_HEIGHT) + y]


func get_surrounding(tile : Dictionary):
	var surrounding = []
	var x = tile.coord.x
	var y = tile.coord.y
	var tx = x
	var ty = y
	if tile.shifted:
		if x == 0:
			if y == 0:
				tx = x + 1
				surrounding.push_back(get_tile(tx, ty))
				ty = y + 1
				surrounding.push_back(get_tile(tx, ty))
				tx = x
				surrounding.push_back(get_tile(tx, ty))
			elif y == MAP_HEIGHT - 1:
				ty = y - 1
				surrounding.push_back(get_tile(tx, ty))
				tx = x + 1
				ty = y
				surrounding.push_back(get_tile(tx, ty))
			else:
				ty = y - 1
				surrounding.push_back(get_tile(tx, ty))
				tx = x + 1
				ty = y
				surrounding.push_back(get_tile(tx, ty))
				ty = y + 1
				surrounding.push_back(get_tile(tx, ty))
				tx = x
				surrounding.push_back(get_tile(tx, ty))
		elif x == MAP_WIDTH - 1:
			if y == 0:
				ty = y + 1
				surrounding.push_back(get_tile(tx, ty))
				tx = x - 1
				surrounding.push_back(get_tile(tx, ty))
				ty = y
				surrounding.push_back(get_tile(tx, ty))
			elif y == MAP_HEIGHT - 1:
				ty = y - 1
				surrounding.push_back(get_tile(tx, ty))
				tx = x - 1
				ty = y
				surrounding.push_back(get_tile(tx, ty))
			else:
				ty = y - 1
				surrounding.push_back(get_tile(tx, ty))
				ty = y + 1
				surrounding.push_back(get_tile(tx, ty))
				tx = x - 1
				surrounding.push_back(get_tile(tx, ty))
				ty = y
				surrounding.push_back(get_tile(tx, ty))
		else:
			if y == 0:
				tx = x + 1
				surrounding.push_back(get_tile(tx, ty))
				ty = y + 1
				surrounding.push_back(get_tile(tx, ty))
				tx = x
				surrounding.push_back(get_tile(tx, ty))
				tx = x - 1
				surrounding.push_back(get_tile(tx, ty))
				ty = y
				surrounding.push_back(get_tile(tx, ty))
			elif y == MAP_HEIGHT - 1:
				ty = y - 1
				surrounding.push_back(get_tile(tx, ty))
				tx = x + 1
				ty = y
				surrounding.push_back(get_tile(tx, ty))
				tx = x - 1
				surrounding.push_back(get_tile(tx, ty))
			else:
				ty = y - 1
				surrounding.push_back(get_tile(tx, ty))
				tx = x + 1
				ty = y
				surrounding.push_back(get_tile(tx, ty))
				ty = y + 1
				surrounding.push_back(get_tile(tx, ty))
				tx = x
				surrounding.push_back(get_tile(tx, ty))
				tx = x - 1
				surrounding.push_back(get_tile(tx, ty))
				ty = y
				surrounding.push_back(get_tile(tx, ty))
	else:
		if x == 0:
			if y == 0:
				tx = x + 1
				surrounding.push_back(get_tile(tx, ty))
				tx = x
				ty = y + 1
				surrounding.push_back(get_tile(tx, ty))
			elif y == MAP_HEIGHT - 1:
				ty = y - 1
				surrounding.push_back(get_tile(tx, ty))
				tx = x + 1
				surrounding.push_back(get_tile(tx, ty))
				ty = y
				surrounding.push_back(get_tile(tx, ty))
			else:
				ty = y - 1
				surrounding.push_back(get_tile(tx, ty))
				tx = x + 1
				surrounding.push_back(get_tile(tx, ty))
				ty = y
				surrounding.push_back(get_tile(tx, ty))
				tx = x
				ty = y + 1
				surrounding.push_back(get_tile(tx, ty))
		elif x == MAP_WIDTH - 1:
			if y == 0:
				ty = y + 1
				surrounding.push_back(get_tile(tx, ty))
				tx = x - 1
				ty = y
				surrounding.push_back(get_tile(tx, ty))
			elif y == MAP_HEIGHT - 1:
				ty = y - 1
				surrounding.push_back(get_tile(tx, ty))
				tx = x - 1
				ty = y
				surrounding.push_back(get_tile(tx, ty))
				ty = y - 1
				surrounding.push_back(get_tile(tx, ty))
			else:
				ty = y - 1
				surrounding.push_back(get_tile(tx, ty))
				ty = y + 1
				surrounding.push_back(get_tile(tx, ty))
				tx = x - 1
				ty = y
				surrounding.push_back(get_tile(tx, ty))
				ty = y - 1
				surrounding.push_back(get_tile(tx, ty))
		else:
			if y == 0:
				tx = x + 1
				surrounding.push_back(get_tile(tx, ty))
				tx = x
				ty = y + 1
				surrounding.push_back(get_tile(tx, ty))
				tx = x - 1
				ty = y
				surrounding.push_back(get_tile(tx, ty))
			elif y == MAP_HEIGHT - 1:
				ty = y - 1
				surrounding.push_back(get_tile(tx, ty))
				tx = x + 1
				surrounding.push_back(get_tile(tx, ty))
				ty = y
				surrounding.push_back(get_tile(tx, ty))
				tx = x - 1
				surrounding.push_back(get_tile(tx, ty))
				ty = y - 1
				surrounding.push_back(get_tile(tx, ty))
			else:
				ty = y - 1
				surrounding.push_back(get_tile(tx, ty))
				tx = x + 1
				surrounding.push_back(get_tile(tx, ty))
				ty = y
				surrounding.push_back(get_tile(tx, ty))
				tx = x
				ty = y + 1
				surrounding.push_back(get_tile(tx, ty))
				tx = x - 1
				ty = y
				surrounding.push_back(get_tile(tx, ty))
				ty = y - 1
				surrounding.push_back(get_tile(tx, ty))
	return surrounding


func get_resource_tiles(origin : Dictionary, collectedTiles := []) -> Array:
	collectedTiles.clear()
	collectedTiles.push_back(origin)
	var costs := [0]
	var count := 0
	
	while count < collectedTiles.size():
		var surrounding = get_surrounding(collectedTiles[count])
		for t in surrounding:
			var totalCost = costs[count] + 1
			var idx = collectedTiles.find_last(t)
			if idx >= 0:
				if totalCost < costs[idx]:
					costs[idx] = totalCost
			elif totalCost <= CD.COMMAND_STATION_RESOURCE_RANGE:
				collectedTiles.push_back(t)
				costs.push_back(totalCost)
		count += 1
	
	return collectedTiles
