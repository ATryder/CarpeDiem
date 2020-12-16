extends Spatial

onready var game = get_node("/root//Game")
onready var arena = game.get_node("Arena")
onready var vp = get_node("FogView")
onready var fb = get_node("FogView/FogBlocks")
onready var vbvp = get_node("FogBlurView")

const PIX_WIDTH = 6
const PIX_HEIGHT = 5.19615

export(Color) var fogUnmapped := Color(0.05, 0.05, 0.1, 1.0)
export(Color) var fogMapped := Color(0.221, 0.953, 1.0, 1.0)

var initialized = false


func map_initialized():
	var padding = CD.TEX_PADDING * 2
	var width = arena.get_arena_tex_width(PIX_WIDTH, padding)
	var height = arena.get_arena_tex_height(PIX_HEIGHT, padding)
	vp.size = Vector2(width, height)
	vp.render_target_update_mode = Viewport.UPDATE_ONCE
	vp.render_target_clear_mode = Viewport.CLEAR_MODE_ONLY_NEXT_FRAME
	vp.get_texture().set_flags(0)
	
	fb.update()
	
	vbvp.size = Vector2(width, height)
	vbvp.render_target_update_mode = Viewport.UPDATE_ONCE
	vbvp.render_target_clear_mode = Viewport.CLEAR_MODE_ONLY_NEXT_FRAME
	vbvp.get_texture().set_flags(Texture.FLAG_FILTER|Texture.FLAG_CONVERT_TO_LINEAR)
	vbvp.get_node("FogTexture").texture = vp.get_texture()
	vbvp.get_node("FogBlurV").transform.origin = Vector2(width * 0.5, height * 0.5)
	vbvp.get_node("FogBlurV").scale = Vector2(width, height)
	vbvp.get_node("FogBlurH").transform.origin = Vector2(width * 0.5, height * 0.5)
	vbvp.get_node("FogBlurH").scale = Vector2(width, height)
	
	initialized = true
	get_tree().call_group("fog_init_notify", "fog_initialized", self)


func get_mask_offset():
	var maskOffset = Vector2(arena.get_arena_tex_width(PIX_WIDTH, CD.TEX_PADDING * 2),
							arena.get_arena_tex_height(PIX_HEIGHT, CD.TEX_PADDING * 2))
	maskOffset = Vector2(1.0, 1.0) / maskOffset
	maskOffset *= CD.TEX_PADDING * Vector2(PIX_WIDTH, PIX_HEIGHT)
	return maskOffset


func get_mask_world_scale():
	var width = arena.get_world_width() + (CD.TEX_PADDING * 2 * CD.TILE_WIDTH)
	var height = arena.get_world_height() + (CD.TEX_PADDING * 2 * CD.TILE_HEIGHT)
	var scale = Vector2(1.0 / width, 1.0 / height)
	return scale


func get_mask():
	return vbvp.get_texture()


func update(tile):
	if tile.updateFog == true:
		return
	
	if fb.tilesToUpdate.size() == 0:
		fb.update()
		vp.render_target_update_mode = Viewport.UPDATE_ONCE
		vbvp.render_target_update_mode = Viewport.UPDATE_ONCE
	
	fb.tilesToUpdate.push_back(tile)
	tile.updateFog = true
