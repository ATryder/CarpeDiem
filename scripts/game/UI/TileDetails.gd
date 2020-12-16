extends PanelContainer

export(bool) var isSelectionWindow

onready var game = get_node("/root/Game")

onready var defense = get_node("MarginContainer/HBoxContainer/VBoxContainer/Defense/DefenseIndicator")
onready var strength = get_node("MarginContainer/HBoxContainer/TileIconContainer/TileIcon/Strength/StrengthIndicator")
onready var iconDisplay = get_node("MarginContainer/HBoxContainer/TileIconContainer/TileIcon")
onready var envIcon = get_node("MarginContainer/HBoxContainer/TileIconContainer/TileIcon/EnvIcon")
onready var unitIcon = get_node("MarginContainer/HBoxContainer/TileIconContainer/TileIcon/UnitIcon")
onready var playerHandle = get_node("MarginContainer/HBoxContainer/VBoxContainer/PlayerHandle")
onready var mpa = get_node("MarginContainer/HBoxContainer/TileIconContainer/TileIcon/MPA/MPAIndicator")
onready var buildTime = get_node("MarginContainer/HBoxContainer/TileIconContainer/BuildIcon/Build/BuildIndicator")
onready var buildIcon = get_node("MarginContainer/HBoxContainer/TileIconContainer/BuildIcon")
onready var background = get_node("BackgroundMargin/Background")

onready var att_cloud = get_node("MarginContainer/HBoxContainer/VBoxContainer/Attributes/Icon_Cloud")
onready var att_star = get_node("MarginContainer/HBoxContainer/VBoxContainer/Attributes/Icon_Star")
onready var att_ast = get_node("MarginContainer/HBoxContainer/VBoxContainer/Attributes/Icon_Asteroid")
onready var att_move = get_node("MarginContainer/HBoxContainer/VBoxContainer/Attributes/Icon_Move")
onready var att_attack = get_node("MarginContainer/HBoxContainer/VBoxContainer/Attributes/Icon_Attack")

const ENV_DUSTCLOUD = preload("res://textures/UI/tile icons/tile_icon_dustcloud.atlastex")
const ENV_AST = preload("res://textures/UI/tile icons/tile_icon_asteroids.atlastex")
const ENV_AST_DUSTCLOUD = preload("res://textures/UI/tile icons/tile_icon_asteroids_dustcloud.atlastex")
const ENV_STAR = preload("res://textures/UI/tile icons/tile_icon_star.atlastex")
const ENV_STAR_DUSTCLOUD = preload("res://textures/UI/tile icons/tile_icon_star_dustcloud.atlastex")

const FRAME_GREEN = preload("res://textures/UI/frame_green48.atlastex")
const FRAME_YELLOW = preload("res://textures/UI/frame_yellow48.atlastex")
const FRAME_ORANGE = preload("res://textures/UI/frame_orange48.atlastex")
const FRAME_RED = preload("res://textures/UI/frame_red48.atlastex")

const ICON_SHIELD = preload("res://textures/UI/indicators/tile_attributes/indicator_shield.atlastex")
const ICON_ARROW = preload("res://textures/UI/indicators/tile_attributes/indicator_arrow.atlastex")
const ICON_ASTEROIDS = preload("res://textures/UI/indicators/tile_attributes/indicator_asteroids.atlastex")
const ICON_CLOUDS = preload("res://textures/UI/indicators/tile_attributes/indicator_clouds.atlastex")
const ICON_CROSSHAIR = preload("res://textures/UI/indicators/tile_attributes/indicator_crosshair.atlastex")
const ICON_STAR = preload("res://textures/UI/indicators/tile_attributes/indicator_star.atlastex")

const ICON_SHIELD_DARK = preload("res://textures/UI/indicators/tile_attributes/indicator_shield_dark.atlastex")
const ICON_ARROW_DARK = preload("res://textures/UI/indicators/tile_attributes/indicator_arrow_dark.atlastex")
const ICON_ASTEROIDS_DARK = preload("res://textures/UI/indicators/tile_attributes/indicator_asteroids_dark.atlastex")
const ICON_CLOUDS_DARK = preload("res://textures/UI/indicators/tile_attributes/indicator_clouds_dark.atlastex")
const ICON_CROSSHAIR_DARK = preload("res://textures/UI/indicators/tile_attributes/indicator_crosshair_dark.atlastex")
const ICON_STAR_DARK = preload("res://textures/UI/indicators/tile_attributes/indicator_star_dark.atlastex")

const ICON_SHIELD_GREY = preload("res://textures/UI/indicators/tile_attributes/indicator_shield_grey.atlastex")
const ICON_ARROW_GREY = preload("res://textures/UI/indicators/tile_attributes/indicator_arrow_grey.atlastex")
const ICON_ASTEROIDS_GREY = preload("res://textures/UI/indicators/tile_attributes/indicator_asteroids_grey.atlastex")
const ICON_CLOUDS_GREY = preload("res://textures/UI/indicators/tile_attributes/indicator_clouds_grey.atlastex")
const ICON_CROSSHAIR_GREY = preload("res://textures/UI/indicators/tile_attributes/indicator_crosshair_grey.atlastex")
const ICON_STAR_GREY = preload("res://textures/UI/indicators/tile_attributes/indicator_star_grey.atlastex")

var icon_shield = ICON_SHIELD
var icon_arrow = ICON_ARROW
var icon_asteroids = ICON_ASTEROIDS
var icon_clouds = ICON_CLOUDS
var icon_crosshair = ICON_CROSSHAIR
var icon_star = ICON_STAR

var current_tile

func _ready():
	if Opts.theme != Opts.THEME_LIGHT:
		change_theme(Opts.THEME_LIGHT, Opts.theme)

func set_tile(tile):
	if tile == current_tile:
		if tile == null:
			background.add_stylebox_override("panel", CD.get_window_background_style(false, Opts.theme))
		return
	
	if !tile.mapped[game.thisPlayer]:
		background.add_stylebox_override("panel", CD.get_window_background_style(false, Opts.theme))
		envIcon.hide()
		att_cloud.texture = ICON_CLOUDS_GREY
		att_star.texture = ICON_STAR_GREY
		att_ast.texture = ICON_ASTEROIDS_GREY
		att_move.texture = ICON_ARROW_GREY
		att_attack.texture = ICON_CROSSHAIR_GREY
	else:
		if tile.has_asteroid():
			envIcon.show()
			att_ast.texture = icon_asteroids
			att_star.texture = ICON_STAR_GREY
			if tile.color < 0:
				envIcon.texture = ENV_AST
				att_cloud.texture = ICON_CLOUDS_GREY
			else:
				envIcon.texture = ENV_AST_DUSTCLOUD
				att_cloud.texture = icon_clouds
		elif tile.has_star():
			envIcon.show()
			att_star.texture = icon_star
			att_ast.texture = ICON_ASTEROIDS_GREY
			if tile.color < 0:
				envIcon.texture = ENV_STAR
				att_cloud.texture = ICON_CLOUDS_GREY
			else:
				envIcon.texture = ENV_STAR_DUSTCLOUD
				att_cloud.texture = icon_clouds
		elif tile.color >= 0:
			envIcon.show()
			envIcon.texture = ENV_DUSTCLOUD
			att_cloud.texture = icon_clouds
			att_ast.texture = ICON_ASTEROIDS_GREY
			att_star.texture = ICON_STAR_GREY
		else:
			envIcon.hide()
			att_cloud.texture = ICON_CLOUDS_GREY
			att_ast.texture = ICON_ASTEROIDS_GREY
			att_star.texture = ICON_STAR_GREY
		
		if tile.get_player_number() == game.thisPlayer:
			background.add_stylebox_override("panel", CD.get_window_background_style(false, Opts.theme))
			if tile.unit.moves > 0:
				att_move.texture = icon_arrow
			else:
				att_move.texture = ICON_ARROW_GREY
			if tile.unit.attacks > 0:
				att_attack.texture = icon_crosshair
			else:
				att_attack.texture = ICON_CROSSHAIR_GREY
		else:
			att_move.texture = ICON_ARROW_GREY
			att_attack.texture = ICON_CROSSHAIR_GREY
			if tile.get_player_number() < 0 || !tile.is_visible(game.thisPlayer):
				background.add_stylebox_override("panel", CD.get_window_background_style(false, Opts.theme))
			else:
				background.add_stylebox_override("panel", CD.get_window_background_style(true, Opts.theme))
	
	if tile.is_occupied() && tile.is_visible(game.thisPlayer):
		var playerFrame = CD.get_player_frame(tile.get_player().color, true)
		iconDisplay.texture = playerFrame
		buildIcon.texture = playerFrame
	else:
		var emptyFrame = CD.get_player_frame(-1, true)
		iconDisplay.texture = emptyFrame
		buildIcon.texture = emptyFrame
	
	set_selection_display(tile)
	current_tile = tile


func showStrength(tile):
	strength.get_parent().show()
	strength.text = str(tile.unit.strength)
	var perc = tile.unit.strength / float(tile.unit.maxStrength)
	if (perc <= 0.2):
		strength.get_parent().texture = FRAME_RED
	elif (perc <= 0.5):
		strength.get_parent().texture = FRAME_ORANGE
	elif (perc <= 0.8):
		strength.get_parent().texture = FRAME_YELLOW
	else:
		strength.get_parent().texture = FRAME_GREEN


func showBuild(tile):
	buildIcon.show()
	var icon = buildIcon.get_node("Icon")
	var buildItem = tile.unit.buildItem
	if buildItem != null:
		icon.texture = CD.unit_icons[buildItem.get_type()]
		icon.show()
		var turns = buildItem.get_remaining_turns(tile.unit)		
		if turns == 0:
			buildTime.text = "0"
			buildTime.get_parent().texture = FRAME_GREEN
		elif turns == INF:
			buildTime.text = "-"
			buildTime.get_parent().texture = FRAME_RED
		elif turns >= 50:
			if turns > 99:
				buildTime.text = "99"
			else:
				buildTime.text = str(turns)
			buildTime.get_parent().texture = FRAME_ORANGE
		else:
			buildTime.text = str(turns)
			buildTime.get_parent().texture = FRAME_YELLOW
		return
	
	icon.hide()
	buildTime.text = "-"
	buildTime.get_parent().texture = FRAME_ORANGE


func set_selection_display(tile):
	if !tile.mapped[game.thisPlayer]:
		clear_selection_display()
		return
	
	defense.value = tile.get_raw_defense()
	if tile.unit != null and tile.is_visible(game.thisPlayer):
		unitIcon.texture = CD.unit_icons[tile.unit.type]
		unitIcon.show()
		showStrength(tile)
		playerHandle.text = tile.get_player().handle
		playerHandle.add_color_override("font_color", tile.get_player().get_color())
		if tile.get_player_number() == game.thisPlayer and tile.unit.get_max_mpa() > 0:
			mpa.get_parent().show()
			mpa.text = str(tile.unit.mpa)
			if tile.unit.type == CD.UNIT_COMMAND_STATION:
				showBuild(tile)
			else:
				buildIcon.hide()
		else:
			mpa.text = "0"
			mpa.get_parent().hide()
			buildIcon.hide()
	else:
		playerHandle.text = "---"
		playerHandle.add_color_override("font_color", Color(0, 0, 0))
		unitIcon.hide()
		strength.get_parent().hide()
		mpa.get_parent().hide()
		buildIcon.hide()


func clear_selection_display():
	background.add_stylebox_override("panel", CD.get_window_background_style(false, Opts.theme))
	
	iconDisplay.texture = CD.get_player_frame(-1, true)
	envIcon.hide()
	unitIcon.hide()
	playerHandle.text = "---"
	playerHandle.add_color_override("font_color", Color(0, 0, 0))
	strength.get_parent().hide()
	defense.value = 0
	strength.text = "10"
	buildIcon.hide()
	mpa.get_parent().hide()
	att_cloud.texture = ICON_CLOUDS_GREY
	att_star.texture = ICON_STAR_GREY
	att_ast.texture = ICON_ASTEROIDS_GREY
	att_move.texture = ICON_ARROW_GREY
	att_attack.texture = ICON_CROSSHAIR_GREY
	if isSelectionWindow:
		current_tile = null


func reset_tile():
	var tile = current_tile
	current_tile = null
	set_tile(tile)


func change_theme(oldTheme, newTheme):
	if newTheme == Opts.THEME_DARK:
		defense.add_stylebox_override("fg", load("res://styles/progress/progress_fg_dark.stylebox"))
		defense.add_stylebox_override("bg", load("res://styles/progress/progress_bg_dark.stylebox"))
		playerHandle.add_color_override("font_outline_modulate", Color(0.7, 0.7, 0.7, 1))
		
		icon_shield = ICON_SHIELD_DARK
		icon_arrow = ICON_ARROW_DARK
		icon_asteroids = ICON_ASTEROIDS_DARK
		icon_clouds = ICON_CLOUDS_DARK
		icon_crosshair = ICON_CROSSHAIR_DARK
		icon_star = ICON_STAR_DARK
	else:
		defense.add_stylebox_override("fg", null)
		defense.add_stylebox_override("bg", null)
		playerHandle.add_color_override("font_outline_modulate", Color(1, 1, 1, 1))
		
		icon_shield = ICON_SHIELD
		icon_arrow = ICON_ARROW
		icon_asteroids = ICON_ASTEROIDS
		icon_clouds = ICON_CLOUDS
		icon_crosshair = ICON_CROSSHAIR
		icon_star = ICON_STAR
	
	get_node("MarginContainer/HBoxContainer/VBoxContainer/Defense/DefenseIcon").texture = icon_shield
	reset_tile()


func _zoom_to_selection(event):
	if (event is InputEventMouseButton
			&& !event.pressed
			&& event.button_index == BUTTON_LEFT
			&& current_tile != null):
		game.get_node("CameraControl").transition_to(Vector3(current_tile.worldLoc.x, 0.0, current_tile.worldLoc.y))
	return true
