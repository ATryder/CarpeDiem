extends Node

const OPTS_VERSION_INT := 1

const OREVALUE := 1
const STARVALUE := 1

const MAP_SIZES := [Vector2(32, 16),
					Vector2(32, 32),
					Vector2(64, 32),
					Vector2(64, 64)]

enum {
	THEME_LIGHT,
	THEME_DARK
}

enum {
	AI_EASY,
	AI_MEDIUM,
	AI_HARD
	}

enum {
	MAP_SMALL,
	MAP_MEDIUM,
	MAP_LARGE,
	MAP_XLARGE
	}

enum {
	QUALITY_LOW,
	QUALITY_MED,
	QUALITY_HIGH,
	QUALITY_XHIGH
	}

enum {
	GEN_RANDOM,
	GEN_DISTRIBUTED,
	GEN_BALANCED
	}

enum {
	QUANTITY_NONE,
	QUANTITY_LOW,
	QUANTITY_MED,
	QUANTITY_HIGH
	}

var vol_sfx := 1.0 setget set_sfx_volume
var vol_music := 0.3 setget set_music_volume

var fullscreen := false
var resolution : Vector2i
var resolution_opts := []

var starQuality := QUALITY_HIGH setget set_star_quality
var cloudQuality := QUALITY_MED setget set_cloud_quality

var particleDetail = QUALITY_MED

var mapSize := MAP_MEDIUM
var mapColor1 := CD.ARENA_BLUE
var mapColor2 := CD.ARENA_CYAN
var allVis := false
var noFog := false

var alliedAI := false
var aiDifficulty := AI_EASY

var starMethod := GEN_RANDOM

var starAmount := QUANTITY_MED
var asteroidAmount := QUANTITY_MED

var playerHandle := tr("label_player_handle") % 1
var playerNumber := 0
var playerColor := 0

var theme = THEME_LIGHT setget set_theme

var showTutorial := true


func _ready():
	load_options()


func set_sfx_volume(value : float):
	vol_sfx = clamp(value, 0, 1)
	Audio.set_fx_volume(get_sfx_db())


func set_music_volume(value : float):
	vol_music = clamp(value, 0, 1)
	Audio.set_ui_music_volume(get_music_db())


func get_sfx_db() -> float:
	return linear2db(vol_sfx)


func get_music_db() -> float:
	return linear2db(vol_music)


func set_star_quality(value):
	if value < QUALITY_LOW or value > QUALITY_XHIGH or value == starQuality:
		return
	
	starQuality = value
	var starcontrol = get_tree().root.find_node("StarControl", true, false)
	if starcontrol == null:
		return
	
	starcontrol.update_star_material_quality()


func set_cloud_quality(value):
	if value < QUALITY_LOW or value > QUALITY_XHIGH or value == cloudQuality:
		return
	
	cloudQuality = value
	var cloudcontrol = get_tree().root.find_node("CloudControl", true, false)
	if cloudcontrol == null:
		return
	
	cloudcontrol.update_cloud_material_quality()


func set_theme(value):
	var oldTheme = theme
	theme = clamp(value, THEME_LIGHT, THEME_DARK)
	if theme != oldTheme:
		get_tree().call_group("interface_themeable", "change_theme", oldTheme, theme)


func get_players_for_map_size(size : int) -> int:
	match size:
		MAP_SMALL:
			return 2
		MAP_MEDIUM:
			return 3
		MAP_LARGE:
			return 5
		MAP_XLARGE:
			return 7
		_:
			return 2


func _resized_screen():
	resolution_opts = get_resolution_options()
	var tmpRes = resolution
	if (get_tree().get_root().size.y > get_tree().get_root().size.x && tmpRes.y < tmpRes.x
			|| get_tree().get_root().size.y < get_tree().get_root().size.x && tmpRes.y > tmpRes.x):
		tmpRes = Vector2i.new(resolution.y, resolution.x)
	resolution = null
	
	for cr in resolution_opts:
		if cr.x == tmpRes.x && cr.y == tmpRes.y:
			resolution = cr
			break
		elif cr.x <= tmpRes.x && cr.y <= tmpRes.y:
			if resolution == null || (cr.x >= resolution.x && cr.y >= resolution.y):
				resolution = cr
	
	if resolution == null:
		resolution = resolution_opts[0]
	
	get_tree().get_root().size = Vector2(resolution.x, resolution.y)


func _apply_resolution():
	if resolution_opts[0] == resolution:
		return
	
	get_tree().get_root().size = Vector2(resolution.x, resolution.y)


func get_resolution_options() -> Array:
	var commonRes := [8640, 
					8192,
					4096,
					2880,
					2048,
					1920,
					1800,
					1700,
					1600,
					1536,
					1440,
					1280,
					1152,
					1080,
					1024,
					960,
					832,
					768,
					720,
					640,
					600,
					480,
					450]
	
	var screen_size = OS.get_screen_size()
	var aspectRatio = screen_size.x / screen_size.y
	var resOpts = [Vector2i.new(int(screen_size.x), int(screen_size.y))]
	
	for cr in commonRes:
		if cr < screen_size.y:
			resOpts.push_back(Vector2i.new(int(round(cr * aspectRatio)), cr))
	return resOpts


func load_options():
	print("Starting Carpe Diem %s..." % CD.VERSION)
	
	resolution_opts = get_resolution_options()
	resolution = resolution_opts[0]
	
	if OS.get_name() == "Android" || OS.get_name() == "iOS":
		get_tree().connect("screen_resized", self, "_resized_screen")
	
	var config = CDIO.get_config_file()
	if config == null || !config.is_open():
		print("Carpe Diem config not found, loading default options...")
		if CD.quality_mobile():
			load_reduced_default()
		else:
			load_default()
		Audio.set_ui_music_volume(get_music_db())
		Audio.set_fx_volume(get_sfx_db())
		return
	
	print("Carpe Diem config found.")
	var opts_version = config.get_8()
	var cd_version = config.get_8()
	print("Loading Carpe Diem config file version %d..." % opts_version)
	
	self.theme = config.get_8()
	
	self.vol_sfx = clamp(config.get_double(), 0, 1)
	self.vol_music = clamp(config.get_double(), 0, 1)
	
	fullscreen = config.get_8() > 0 || OS.get_name() == "Android" || OS.get_name() == "iOS"
	var tmpRes = Vector2i.new(config.get_16(), config.get_16())
	for cr in resolution_opts:
		if cr.x == tmpRes.x && cr.y == tmpRes.y:
			resolution = cr
			break
	
	if CD.quality_mobile():
		_apply_resolution()
		starQuality = min(config.get_8(), QUALITY_HIGH)
	else:
		starQuality = min(config.get_8(), QUALITY_XHIGH)
		if fullscreen:
			get_tree().connect("screen_resized", self, "_apply_resolution", [], CONNECT_ONESHOT)
			OS.window_fullscreen = true
	cloudQuality = min(config.get_8(), QUALITY_XHIGH)
	particleDetail = min(config.get_8(), QUALITY_XHIGH)
	
	mapSize = min(config.get_8(), MAP_XLARGE)
	mapColor1 = min(config.get_8(), CD.ARENA_ORANGE)
	mapColor2 = min(config.get_8(), CD.ARENA_ORANGE)
	
	allVis = config.get_8() > 0
	noFog = config.get_8() > 0
	
	alliedAI = config.get_8() > 0
	
	aiDifficulty = min(config.get_8(), AI_HARD)
	starAmount = min(config.get_8(), QUANTITY_HIGH)
	asteroidAmount = min(config.get_8(), QUANTITY_HIGH)
	
	playerHandle = config.get_buffer(config.get_16()).get_string_from_utf8()
	playerNumber = min(config.get_8(), 6)
	playerColor = min(config.get_8(), CD.PLAYER_GREEN)
	
	showTutorial = config.get_8() > 0


func load_default():
	fullscreen = false
	
	starQuality = QUALITY_HIGH
	cloudQuality = QUALITY_HIGH
	particleDetail = QUALITY_MED


func load_reduced_default():
	fullscreen = true
	
	starQuality = QUALITY_LOW
	cloudQuality = QUALITY_LOW
	particleDetail = QUALITY_MED


func save_settings() -> int:
	var config = CDIO.get_config_file(File.WRITE)
	if config == null || !config.is_open():
		return ERR_FILE_CANT_WRITE
	
	if config.get_error() != OK:
		return config.get_error()
	
	config.store_8(OPTS_VERSION_INT)
	config.store_8(CD.VERSION_INT)
	
	config.store_8(theme)
	
	config.store_double(vol_sfx)
	config.store_double(vol_music)
	
	if fullscreen:
		config.store_8(1)
	else:
		config.store_8(0)
	config.store_16(resolution.x)
	config.store_16(resolution.y)
	
	config.store_8(starQuality)
	config.store_8(cloudQuality)
	config.store_8(particleDetail)
	
	config.store_8(mapSize)
	config.store_8(mapColor1)
	config.store_8(mapColor2)
	
	if allVis:
		config.store_8(1)
	else:
		config.store_8(0)
	if noFog:
		config.store_8(1)
	else:
		config.store_8(0)
	
	if alliedAI:
		config.store_8(1)
	else:
		config.store_8(0)
	
	config.store_8(aiDifficulty)
	config.store_8(starAmount)
	config.store_8(asteroidAmount)
	
	var handle
	if playerHandle == null || playerHandle.empty():
		handle = tr("label_player_handle") % 1
		handle = handle.to_utf8()
	else:
		handle = playerHandle.to_utf8()
	config.store_16(handle.size())
	config.store_buffer(handle)
	config.store_8(playerNumber)
	config.store_8(playerColor)
	
	if showTutorial:
		config.store_8(1)
	else:
		config.store_8(0)
	
	return OK
