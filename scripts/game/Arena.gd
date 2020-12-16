extends Spatial

var LOADED = false setget set_loaded, get_loaded

export(int, 8, 64) var MAP_WIDTH setget set_map_width, get_map_width
export(int, 8, 64) var MAP_HEIGHT setget set_map_height, get_map_height

onready var fogControl = get_node("FogControl")

var ARENA : Array setget set_arena, get_arena

var total_stars := 0
var total_asteroids := 0

export(int, "Blue", "Cyan", "Purple", "Green", "Red", "Yellow", "Brown", "Orange") var colorIntScheme1 = 1
export(int, "Blue", "Cyan", "Purple", "Green", "Red", "Yellow", "Brown", "Orange") var colorIntScheme2 = 2


func _ready():
	set_process(false)


func _load_wrap_up(mapGen):
	total_stars = mapGen.added_stars
	total_asteroids = mapGen.added_asteroids


func set_loaded(loaded):
	pass


func get_loaded():
	return LOADED


func set_map_width(width):
	if !LOADED:
		MAP_WIDTH = width


func get_map_width():
	return MAP_WIDTH


func set_map_height(height):
	if !LOADED:
		MAP_HEIGHT = height


func get_map_height():
	return MAP_HEIGHT


func get_world_width():
	var width = MAP_WIDTH * CD.TILE_WIDTH * 0.75
	width += CD.TILE_WIDTH  * 0.25
	return width


func get_world_height():
	return (MAP_HEIGHT * CD.TILE_HEIGHT) + (CD.TILE_HEIGHT * 0.5)


func get_arena_tex_width(tile_width, padding):
	var width = MAP_WIDTH * tile_width * 0.75
	width += tile_width * 0.25
	width += padding * tile_width
	return width


func get_arena_tex_height(tile_height, padding):
	var height = MAP_HEIGHT + padding
	height *= tile_height
	height += tile_height * 0.5
	return height


func init_arena(arena, width, height, colorInt1, colorInt2):
	if LOADED:
		return
	
	MAP_WIDTH = width
	MAP_HEIGHT = height
	colorIntScheme1 = colorInt1
	colorIntScheme2 = colorInt2
	ARENA = arena
	LOADED = true
	get_tree().call_group("map_init_notify", "map_initialized")


func set_arena(arena):
	pass


func get_arena():
	return ARENA


func get_tile(x, y) -> CDTile:
	return ARENA[(x * MAP_HEIGHT) + y]


func world_to_tile(loc) -> CDTile:
	var x := int(floor((loc.x / 0.75) / CD.TILE_WIDTH))
	var y : int
	if x % 2 != 0:
		y = int(floor((loc.z - (CD.TILE_HEIGHT * 0.5)) / CD.TILE_HEIGHT))
	else:
		y = int(floor(loc.z / CD.TILE_HEIGHT))
	
	if (x < 0 or x >= MAP_WIDTH
			or y < 0
			or y >= MAP_HEIGHT):
		return null
	
	return get_tile(x, y)


func cleanup():
	for x in range(MAP_WIDTH):
		for y in range(MAP_HEIGHT):
			get_tile(x, y).free()
