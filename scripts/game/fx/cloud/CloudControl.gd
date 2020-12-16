extends Spatial

const padding = 2

onready var arena = get_parent()
onready var cp = get_node("CloudPlane")

const PIX_WIDTH = 12.0
const PIX_HEIGHT = 10.3923

var frame = 0


func _ready():
	set_process(false)


func stars_initialized(starControl):
	var vp = get_node("CloudView")
	var cb = get_node("CloudView/CloudBlocks")
	var vpb = get_node("CloudBlur")
	
	var texPadding = CD.TEX_PADDING * 2
	var width = arena.get_arena_tex_width(PIX_WIDTH, texPadding)
	var height = arena.get_arena_tex_height(PIX_HEIGHT, texPadding)
	vp.size = Vector2(width, height)
	vp.render_target_update_mode = Viewport.UPDATE_ONCE
	vp.get_texture().set_flags(0)
	
	vpb.size = Vector2(width, height)
	vpb.render_target_update_mode = Viewport.UPDATE_ONCE
	vpb.get_texture().set_flags(Texture.FLAG_FILTER|Texture.FLAG_CONVERT_TO_LINEAR)
	vpb.get_node("CloudTexture").texture = vp.get_texture()
	vpb.get_node("HaloAdd").texture = vp.get_texture()
	
	for mesh in vpb.get_children():
		if mesh is MeshInstance2D:
			mesh.scale = Vector2(width, height)
			mesh.transform.origin = Vector2(width * 0.5, height * 0.5)
	
	cb.update()
	
	width = arena.get_world_width() + (texPadding * CD.TILE_WIDTH)
	height = arena.get_world_height() + (texPadding * CD.TILE_HEIGHT)
	cp.create_plane(width, height)
	cp.transform.origin = Vector3(-CD.TILE_WIDTH * padding,
			0, -CD.TILE_HEIGHT * padding)
	
	set_process(true)


func update_cloud_material_quality():
	var cloudMat : Material
	match Opts.cloudQuality:
		Opts.QUALITY_LOW:
			cloudMat = load("res://materials/fx/cloud/Cloud_Low.tres")
		Opts.QUALITY_MED:
			cloudMat = load("res://materials/fx/cloud/Cloud_Med.tres")
		Opts.QUALITY_HIGH:
			cloudMat = load("res://materials/fx/cloud/Cloud_High.tres")
		Opts.QUALITY_XHIGH:
			cloudMat = load("res://materials/fx/cloud/Cloud_XHigh.tres")
		_:
			cloudMat = load("res://materials/fx/cloud/Cloud_Low.tres")
	cloudMat.set_shader_param("uv_scale", Vector2(arena.MAP_WIDTH / 8.0, arena.MAP_HEIGHT / 8.0))
	
	var texture : Texture
	if cp.texture == null:
		texture = ImageTexture.new()
		var img = get_node("CloudBlur").get_texture().get_data()
		texture.create_from_image(img)
	else:
		texture = cp.texture
	
	var fc = arena.get_node("FogControl")
	cloudMat.set_shader_param("fogUnmapped", fc.fogUnmapped)
	cloudMat.set_shader_param("fogMapped", fc.fogMapped)
	cloudMat.set_shader_param("mask_tex", arena.get_node("FogControl").get_mask())
	var texel = Vector2(1.0 / texture.get_width(), 1.0 / texture.get_height())
	cloudMat.set_shader_param("texelSize", texel)
	cloudMat.set_shader_param("paddingWidth", texel.x * PIX_WIDTH * padding)
	cloudMat.set_shader_param("paddingHeight", texel.y * PIX_HEIGHT * padding)
	cp.mat = cloudMat
	cp.texture = texture
	cp.set_process(true)


func _process(delta):
	frame += 1
	if frame == 2:
		update_cloud_material_quality()
		get_node("CloudView").queue_free()
		get_node("CloudBlur").queue_free()
		set_process(false)
