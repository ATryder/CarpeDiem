extends Node

const VERSION_INT := 3
const VERSION := "1.0.7"

const BASE_TILE_SIZE = 16.0
const TILE_WIDTH = 16.0
const TILE_HEIGHT = 13.8564
const TILE_HALF_WIDTH = 8.0
const TILE_HALF_HEIGHT = 6.9282
const TEX_PADDING = 2 # Amount of tile padding to add on the edges of map textures such as fog and cloud textures

const ASTEROID_ORE = 1 # Amount of ore generated per asteroid per turn
const STAR_ENERGY = 1 # Amount of energy generated per star per turn
const MPA_HEAL_AMOUNT = 2
const TOTAL_TYPES = 7
const CARGOSHIP_MAX_MPA = 4
const COMMAND_STATION_MAX_MPA = 10
const COMMAND_STATION_RESOURCE_RANGE = 3
const COMMAND_STATION_MAX_QUEUE = 4
const COMMAND_STATION_MIN_ENERGY = 1
const COMMAND_STATION_MIN_ORE = 1

enum {
	ARENA_BLUE,
	ARENA_CYAN,
	ARENA_PURPLE,
	ARENA_GREEN,
	ARENA_RED,
	ARENA_YELLOW,
	ARENA_BROWN,
	ARENA_ORANGE
	}

enum {
	PLAYER_BLUE,
	PLAYER_RED,
	PLAYER_PURPLE,
	PLAYER_CYAN,
	PLAYER_ORANGE,
	PLAYER_YELLOW,
	PLAYER_GREEN
	}

enum {
	UNIT_COMMAND_STATION,
	UNIT_NIGHTHAWK,
	UNIT_GAUMOND,
	UNIT_THANANOS,
	UNIT_AURORA,
	UNIT_CARGOSHIP,
	UNIT_MPA
	}

const unit_icons = [
	preload("res://textures/UI/tile icons/tile_icon_commandstation.atlastex"),
	preload("res://textures/UI/tile icons/tile_icon_nighthawk.atlastex"),
	preload("res://textures/UI/tile icons/tile_icon_gaumond.atlastex"),
	preload("res://textures/UI/tile icons/tile_icon_thananos.atlastex"),
	preload("res://textures/UI/tile icons/tile_icon_aurora.atlastex"),
	preload("res://textures/UI/tile icons/tile_icon_cargoship.atlastex"),
	preload("res://textures/UI/tile icons/tile_icon_mpa.atlastex")
	]

const unit_sphere = [
	preload("res://fx/Heal_Sphere/heal_sphere_commandstation.tscn"),
	preload("res://fx/Heal_Sphere/heal_sphere_nighthawk.tscn"),
	preload("res://fx/Heal_Sphere/heal_sphere_gaumond.tscn"),
	preload("res://fx/Heal_Sphere/heal_sphere_thananos.tscn"),
	preload("res://fx/Heal_Sphere/heal_sphere_aurora.tscn"),
	preload("res://fx/Heal_Sphere/heal_sphere_cargoship.tscn")
	]

const ARENA_PATH = "/root/Game/Arena"
const STAR_CONTROL_PATH = "/root/Game/Arena/StarControl"

const DEFAULT_DISMISS_TEXT = "Dismiss"


func _ready():
	CDIO.init_directories()


static func quality_mobile() -> bool:
	return (OS.get_name() == "Android" || OS.get_name() == "iOS"
			|| OS.get_name() == "HTML5" || OS.get_name() == "UWP")


static func highp_float() -> bool:
	if !quality_mobile():
		return true
	#TODO Check if high precision float is supported
	return true


static func get_arena_color(colorInt : int) -> Color:
	match colorInt:
		ARENA_BLUE:
			return Color(0.196, 0.537, 1, 1)
		ARENA_CYAN:
			return Color(0.237, 0.892, 1, 1)
		ARENA_PURPLE:
			return Color(0.712, 0.337, 1, 1)
		ARENA_GREEN:
			return Color(0.238, 0.674, 0.278, 1)
		ARENA_RED:
			return Color(1, 0.073, 0.025, 1)
		ARENA_YELLOW:
			return Color(1, 0.753, 0.057, 1)
		ARENA_BROWN:
			return Color(0.378, 0.264, 0.1, 1)
		ARENA_ORANGE:
			return Color(1, 0.54, 0.12, 1)
		_:
			return Color(0, 0, 0, 1)


static func get_player_color(colorInt : int) -> Color:
	match colorInt:
		PLAYER_BLUE:
			return Color(0.021, 0.021, 1, 1.0)
		PLAYER_CYAN:
			return Color(0.021, 1, 1, 1.0)
		PLAYER_PURPLE:
			return Color(0.521, 0.014, 1, 1.0)
		PLAYER_RED:
			return Color(1, 0.014, 0.021, 1.0)
		PLAYER_ORANGE:
			return Color(1, 0.4, 0, 1.0)
		PLAYER_YELLOW:
			return Color(1, 1, 0, 1.0)
		PLAYER_GREEN:
			return Color(0.021, 1, 0.021, 1.0)
		_:
			return Color(0, 0, 0, 1)


static func get_player_frame(colorInt : int, big := false) -> Texture:
	if big:
		match colorInt:
			PLAYER_BLUE:
				return preload("res://textures/UI/buttons/frame/framebutton_blue.atlastex")
			PLAYER_CYAN:
				return preload("res://textures/UI/buttons/frame/framebutton_cyan.atlastex")
			PLAYER_PURPLE:
				return preload("res://textures/UI/buttons/frame/framebutton_purple.atlastex")
			PLAYER_RED:
				return preload("res://textures/UI/buttons/frame/framebutton_red.atlastex")
			PLAYER_ORANGE:
				return preload("res://textures/UI/buttons/frame/framebutton_orange.atlastex")
			PLAYER_YELLOW:
				return preload("res://textures/UI/buttons/frame/framebutton_yellow.atlastex")
			PLAYER_GREEN:
				return preload("res://textures/UI/buttons/frame/framebutton_green.atlastex")
			_:
				return preload("res://textures/UI/buttons/frame/framebutton_gray.atlastex")
	else:
		match colorInt:
			PLAYER_BLUE:
				return preload("res://textures/UI/buttons/frame/framebutton_blue.atlastex")
			PLAYER_CYAN:
				return preload("res://textures/UI/buttons/frame/framebutton_cyan.atlastex")
			PLAYER_PURPLE:
				return preload("res://textures/UI/buttons/frame/framebutton_purple.atlastex")
			PLAYER_RED:
				return preload("res://textures/UI/buttons/frame/framebutton_red.atlastex")
			PLAYER_ORANGE:
				return preload("res://textures/UI/buttons/frame/framebutton_orange.atlastex")
			PLAYER_YELLOW:
				return preload("res://textures/UI/buttons/frame/framebutton_yellow.atlastex")
			PLAYER_GREEN:
				return preload("res://textures/UI/buttons/frame/framebutton_green.atlastex")
			_:
				return preload("res://textures/UI/buttons/frame/framebutton_gray.atlastex")


static func get_spark_material(playerNum):
	match playerNum:
		PLAYER_BLUE:
			return load("res://materials/fx/particles/Sparks_Blue.material")
		PLAYER_CYAN:
			return load("res://materials/fx/particles/Sparks_Cyan.material")
		PLAYER_PURPLE:
			return load("res://materials/fx/particles/Sparks_Purple.material")
		PLAYER_RED:
			return load("res://materials/fx/particles/Sparks_Red.material")
		PLAYER_ORANGE:
			return load("res://materials/fx/particles/Sparks_Orange.material")
		PLAYER_YELLOW:
			return load("res://materials/fx/particles/Sparks_Yellow.material")
		PLAYER_GREEN:
			return load("res://materials/fx/particles/Sparks_Green.material")
		_:
			return preload("res://materials/fx/particles/Sparks_Orange.material")


static func get_arena_cb(colorInt):
	match colorInt:
		ARENA_BLUE:
			return [Vector3(1, 1, 1),
					Vector3(0.519, 0.590, 1.361),
					Vector3(0.769, 0.844, 1.363)]
		ARENA_CYAN:
			return [Vector3(1, 1, 1),
					Vector3(0.562, 1, 0.903),
					Vector3(0.741, 1.179, 1.106)]
		ARENA_PURPLE:
			return [Vector3(1, 1, 1),
					Vector3(0.978, 0.3952, 1.25),
					Vector3(0.764, 0.763, 1.413)]
		ARENA_GREEN:
			return [Vector3(1, 1, 1),
					Vector3(0.535, 1, 0.43),
					Vector3(0.939, 1.113, 1.021)]
		ARENA_RED:
			return [Vector3(1, 1, 1),
					Vector3(0.5952, 0.2144, 0.2028),
					Vector3(1.290, 1.098, 0.541)]
		ARENA_YELLOW:
			return [Vector3(1, 0.873, 0.507),
					Vector3(1.584, 0.501, 0),
					Vector3(1.215, 1.098, 0.694)]
		ARENA_BROWN:
			return [Vector3(1, 1, 1),
					Vector3(0.5556, 0.3328, 0.1472),
					Vector3(1.285, 1.013, 0.696)]
		ARENA_ORANGE:
			return [Vector3(1, 1, 1),
					Vector3(0.5556, 0.3328, 0.1472),
					Vector3(1.285, 1.013, 0.696)]
		_:
			return [Vector3(0.919, 0.990, 1),
					Vector3(0.4, 0.492, 1.361),
					Vector3(0.769, 0.844, 1.363)]


static func get_unit(type) -> PackedScene:
	match type:
		UNIT_NIGHTHAWK:
			return load("res://models/units/NightHawk/NightHawk.tscn") as PackedScene
		UNIT_GAUMOND:
			return load("res://models/units/Gaumond/Gaumond.tscn") as PackedScene
		UNIT_CARGOSHIP:
			return load("res://models/units/CargoShip/CargoShip.tscn") as PackedScene
		UNIT_THANANOS:
			return load("res://models/units/Thananos/Thananos.tscn") as PackedScene
		UNIT_AURORA:
			return load("res://models/units/AuroraClassBattleship/AuroraClassBattleship.tscn") as PackedScene
		UNIT_COMMAND_STATION:
			return load("res://models/units/CommandStation/Command_Station.tscn") as PackedScene
	return null


static func get_window_background(highlight := false, theme := Opts.THEME_LIGHT):
	if theme == Opts.THEME_LIGHT:
		if !highlight:
			return preload("res://textures/UI/windows/window_blue.atlastex")
		return preload("res://textures/UI/windows/window_orange.atlastex")
	
	if !highlight:
		return preload("res://textures/UI/windows/window_dark_green.atlastex")
	return preload("res://textures/UI/windows/window_dark_yellow.atlastex")


static func get_window_background_style(highlight := false, theme := Opts.THEME_LIGHT):
	if theme == Opts.THEME_LIGHT:
		if !highlight:
			return preload("res://styles/window/window_blue.stylebox")
		return preload("res://styles/window/window_yellow.stylebox")
	
	if !highlight:
		return preload("res://styles/window/window_dark_green.stylebox")
	return preload("res://styles/window/window_dark_yellow.stylebox")


#Workaround for dangling variant bug with is_instance_valid
static func is_valid_unit(unit, tile):
	if unit == null || !(unit is Unit) || !is_instance_valid(unit):
		return false
	
	return unit.has_method("get_strength") && unit.tile == tile && unit.is_alive()


static func get_blank_texture() -> ImageTexture:
	var pbr = PoolByteArray([0])
	var img = Image.new()
	img.create_from_data(1, 1, false,
			Image.FORMAT_R8, pbr)
	var tex = ImageTexture.new()
	tex.create_from_image(img, 0)
	return tex;
