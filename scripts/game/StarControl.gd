extends Spatial

onready var arena = get_parent()

export(PackedScene) var starScn

var starMat1
var starMat2
var glowMat1
var glowMat2

var star1noise1
var star1noise2
var star2noise1
var star2noise2


func _ready():
	set_process(false)

	
func map_initialized():
	init_star_materials()
	set_process(true)

	
func get_material(colorInt):
	if colorInt == arena.colorIntScheme1:
		return starMat1
	elif colorInt == arena.colorIntScheme2:
		return starMat2
	elif randi() % 2 == 0:
		return starMat1
	else:
		return starMat2


func get_glow_material(colorInt, starMaterial = null):
	if colorInt == arena.colorIntScheme1:
		return glowMat1
	elif colorInt == arena.colorIntScheme2:
		return glowMat2
	elif starMat1 == starMaterial:
		return glowMat1
	elif starMat2 == starMaterial:
		return glowMat2
	elif starMaterial != null:
		var gm = glowMat1.duplicate()
		gm.set_shader_param("lift", starMaterial.get_shader_param("lift"))
		gm.set_shader_param("gamma", starMaterial.get_shader_param("gamma"))
		gm.set_shader_param("gain", starMaterial.get_shader_param("gain"))
		return gm
	else:
		var gm = glowMat1.duplicate()
		var cb = CD.get_arena_cb(colorInt)
		gm.set_shader_param("lift", cb[0])
		gm.set_shader_param("gamma", cb[1])
		gm.set_shader_param("gain", cb[2])
		return gm


func new_star():
	var star = starScn.instance()
	
	return star


func new_star_to_tilexy(tile_x, tile_y):
	new_star_to_tile(arena.get_tile(tile_x, tile_y))


func new_star_to_tile(tile):
	var star = new_star()
	
	var scale = tile.star["scale"]
	var translation = Vector3(tile.worldLoc.x, 0, tile.worldLoc.y)
	translation += tile.star["translation"]
	star.translate(translation)
	star.set_scale(Vector3(scale, scale, scale))
	star.tile = tile
	
	return star


func init_star_materials():
	match Opts.starQuality:
		Opts.QUALITY_LOW:
			starMat1 = load("res://models/props/Star/materials/Star_Low.tres").duplicate()
		Opts.QUALITY_MED:
			starMat1 = load("res://models/props/Star/materials/Star_Med.tres").duplicate()
		Opts.QUALITY_HIGH:
			if !CD.highp_float():
				starMat1 = load("res://models/props/Star/materials/Star_High_Mobile.tres").duplicate()
			else:
				starMat1 = load("res://models/props/Star/materials/Star_High.tres").duplicate()
		Opts.QUALITY_XHIGH:
			starMat1 = load("res://models/props/Star/materials/Star_XHigh.tres").duplicate()
		_:
			starMat1 = load("res://models/props/Star/materials/Star_Low.tres").duplicate()
	
	var fc = get_node("../FogControl")
	starMat1.set_shader_param("mask_offset", fc.get_mask_offset())
	starMat1.set_shader_param("mask_scale", fc.get_mask_world_scale())
	starMat1.set_shader_param("mask_tex", fc.get_mask())
	starMat1.set_shader_param("fog", fc.fogMapped)
	var cb = CD.get_arena_cb(arena.colorIntScheme1)
	starMat1.set_shader_param("lift", cb[0])
	starMat1.set_shader_param("gamma", cb[1])
	starMat1.set_shader_param("gain", cb[2])
	glowMat1 = load("res://models/props/Star/materials/StarGlow.tres").duplicate()
	glowMat1.set_shader_param("mask_offset", fc.get_mask_offset())
	glowMat1.set_shader_param("mask_scale", fc.get_mask_world_scale())
	glowMat1.set_shader_param("mask_tex", fc.get_mask())
	glowMat1.set_shader_param("lift", cb[0])
	glowMat1.set_shader_param("gamma", cb[1])
	glowMat1.set_shader_param("gain", cb[2])
	glowMat1.set_shader_param("fog", fc.fogMapped)
	
	starMat2 = starMat1.duplicate()
	cb = CD.get_arena_cb(arena.colorIntScheme2)
	starMat2.set_shader_param("lift", cb[0])
	starMat2.set_shader_param("gamma", cb[1])
	starMat2.set_shader_param("gain", cb[2])
	glowMat2 = glowMat1.duplicate()
	glowMat2.set_shader_param("lift", cb[0])
	glowMat2.set_shader_param("gamma", cb[1])
	glowMat2.set_shader_param("gain", cb[2])
	glowMat2.set_shader_param("fog", fc.fogMapped)
	
	star1noise1 = StarAnimation.new("time", starMat1, 0.4, rand_range(28, 327))
	star1noise2 = StarAnimation.new("time2", starMat1, 0.15, rand_range(28, 327))
	star2noise1 = StarAnimation.new("time", starMat2, 0.4, rand_range(28, 327))
	star2noise2 = StarAnimation.new("time2", starMat2, 0.15, rand_range(28, 327))


func update_star_material_quality():
	var lift = starMat1.get_shader_param("lift")
	var gamma = starMat1.get_shader_param("gamma")
	var gain = starMat1.get_shader_param("gain")
	
	match Opts.starQuality:
		Opts.QUALITY_LOW:
			starMat1 = load("res://models/props/Star/materials/Star_Low.tres").duplicate()
		Opts.QUALITY_MED:
			starMat1 = load("res://models/props/Star/materials/Star_Med.tres").duplicate()
			starMat1.set_shader_param("time2", star1noise2.tme)
		Opts.QUALITY_HIGH:
			if !CD.highp_float():
				starMat1 = load("res://models/props/Star/materials/Star_High_Mobile.tres").duplicate()
			else:
				starMat1 = load("res://models/props/Star/materials/Star_High.tres").duplicate()
			starMat1.set_shader_param("time2", star1noise2.tme)
		Opts.QUALITY_XHIGH:
			starMat1 = load("res://models/props/Star/materials/Star_XHigh.tres").duplicate()
			starMat1.set_shader_param("time2", star1noise2.tme)
		_:
			starMat1 = load("res://models/props/Star/materials/Star_Low.tres").duplicate()
			starMat1.set_shader_param("time2", star1noise2.tme)
	
	var fc = get_node("../FogControl")
	starMat1.set_shader_param("mask_offset", fc.get_mask_offset())
	starMat1.set_shader_param("mask_scale", fc.get_mask_world_scale())
	starMat1.set_shader_param("mask_tex", fc.get_mask())
	starMat1.set_shader_param("fog", fc.fogMapped)
	starMat1.set_shader_param("lift", lift)
	starMat1.set_shader_param("gamma", gamma)
	starMat1.set_shader_param("gain", gain)
	starMat1.set_shader_param("time", star1noise1.tme)
	
	lift = starMat2.get_shader_param("lift")
	gamma = starMat2.get_shader_param("gamma")
	gain = starMat2.get_shader_param("gain")
	
	starMat2 = starMat1.duplicate()
	starMat2.set_shader_param("lift", lift)
	starMat2.set_shader_param("gamma", gamma)
	starMat2.set_shader_param("gain", gain)
	starMat2.set_shader_param("time", star2noise1.tme)
	
	star1noise1.mat = starMat1
	star2noise1.mat = starMat2
	
	if Opts.starQuality > Opts.QUALITY_LOW:
		starMat2.set_shader_param("time2", star2noise2.tme)
		star1noise2.mat = starMat1
		star2noise2.mat = starMat2
	
	get_tree().call_group("Stars", "set_material")


func _process(delta):
	star1noise1.animate(delta)
	star2noise1.animate(delta)
	if Opts.starQuality > Opts.QUALITY_LOW:
		star1noise2.animate(delta)
		star2noise2.animate(delta)


class StarAnimation:
	var mat
	var tme
	var tmeScale
	var maxTme
	var reverse
	var param
	
	var perc
	
	func _init(var param,
			var mat,
			var tmeScale = 0.5,
			var maxTme = 5,
			var reverse = false):
		self.tme = rand_range(0.0, maxTme)
		self.param = param
		self.mat = mat
		self.tmeScale = tmeScale
		self.maxTme = maxTme
		self.param = param
	
	
	func animate(var delta):
		tme += delta * tmeScale
		
		if tme >= maxTme:
			tme = tme - (floor(tme / maxTme) * maxTme)
			reverse = !reverse
			
		perc = tme / maxTme
		if !reverse:
			mat.set_shader_param(param, lerp(0.0, maxTme, perc))
		else:
			mat.set_shader_param(param, lerp(maxTme, 0.0, perc))
