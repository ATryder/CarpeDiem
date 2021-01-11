extends Reference
class_name Tutorial

enum {
	COMBAT_UNIT,
	CARGO_UNIT,
	COMMAND_UNIT,
	ENEMY_UNIT,
	HUD,
	ACTION_ATTACK,
	ACTION_MOVE,
	ACTION_LAUNCH,
	ACTION_MPA,
	ACTION_BUILD
}

var game

var tutorialSegments := [COMBAT_UNIT,
						CARGO_UNIT,
						COMMAND_UNIT,
						HUD,
						ENEMY_UNIT,
						ACTION_ATTACK,
						ACTION_MOVE,
						ACTION_BUILD,
						ACTION_LAUNCH,
						ACTION_MPA]


func launch():
	var dialog = get_dialog(tr("tutorial_welcome"), tr("label_welcome"))
	dialog.introSound = null
	game.hud.add_dialog(dialog)
	
	game.connect("tile_selected", self, "tile_selected", [], CONNECT_ONESHOT)
	game.connect("tile_hovered", self, "tile_hovered", [], CONNECT_ONESHOT)
	game.connect("action_initiated", self, "action_initiated", [], CONNECT_ONESHOT)


func tile_hovered(tile):
	if !Opts.showTutorial || !tutorialSegments.has(HUD):
		return
	
	tutorialSegments.erase(HUD)
	game.hud.add_dialog(get_dialog(tr("tutorial_hud"), tr("label_hud")))


func tile_selected(tile):
	if !Opts.showTutorial:
		return
	
	var dialog
	if tile.unit != null:
		if tile.unit.player.is_local_player():
			match tile.unit.type:
				CD.UNIT_CARGOSHIP:
					if tutorialSegments.has(CARGO_UNIT):
						tutorialSegments.erase(CARGO_UNIT)
						dialog = get_dialog(tr("tutorial_cargo_units") % [CD.CARGOSHIP_MAX_MPA,
																		CD.COMMAND_STATION_MIN_ENERGY,
																		CD.COMMAND_STATION_MIN_ORE,
																		CD.CARGOSHIP_MAX_MPA], 
								tr("label_cargoships"))
				CD.UNIT_COMMAND_STATION:
					if tutorialSegments.has(COMMAND_UNIT):
						tutorialSegments.erase(COMMAND_UNIT)
						dialog = get_dialog(tr("tutorial_command_units") % [CD.COMMAND_STATION_MAX_MPA, 4, 1], tr("label_command_stations"))
				_:
					if tutorialSegments.has(COMBAT_UNIT):
						tutorialSegments.erase(COMBAT_UNIT)
						dialog = get_dialog(tr("tutorial_combat_units"), tr("label_combat_units"))
		else:
			if tutorialSegments.has(ENEMY_UNIT):
				tutorialSegments.erase(ENEMY_UNIT)
				dialog = get_dialog(tr("tutorial_opposing_units"), tr("label_opposing_units"))
	
	if dialog != null:
		game.hud.add_dialog(dialog)
	
	if (tutorialSegments.has(CARGO_UNIT)
			|| tutorialSegments.has(COMMAND_UNIT)
			|| tutorialSegments.has(COMBAT_UNIT)
			|| tutorialSegments.has(ENEMY_UNIT)):
		game.call_deferred("connect", "tile_selected", self, "tile_selected", [], CONNECT_ONESHOT)


func action_initiated(action):
	if !Opts.showTutorial:
		return
	
	var dialog
	match action:
		Actions.ACTION.ATTACK:
			if tutorialSegments.has(ACTION_ATTACK):
				tutorialSegments.erase(ACTION_ATTACK)
				dialog = get_dialog(tr("tutorial_attack"), tr("label_attacking_units"))
		Actions.ACTION.MOVE:
			if tutorialSegments.has(ACTION_MOVE):
				tutorialSegments.erase(ACTION_MOVE)
				dialog = get_dialog(tr("tutorial_move"), tr("label_moving_units"))
		Actions.ACTION.BUILD:
			if tutorialSegments.has(ACTION_BUILD):
				tutorialSegments.erase(ACTION_BUILD)
				dialog = get_dialog(tr("tutorial_build"), tr("label_build_window"))
		Actions.ACTION.MPA:
			if tutorialSegments.has(ACTION_MPA):
				tutorialSegments.erase(ACTION_MPA)
				dialog = get_dialog(tr("tutorial_mpa") % [CD.MPA_HEAL_AMOUNT,
															CD.CARGOSHIP_MAX_MPA,
															CD.COMMAND_STATION_MIN_ENERGY,
															CD.COMMAND_STATION_MIN_ORE],
						tr("label_mpa_transferring"))
	
	if dialog != null:
		game.hud.add_dialog(dialog)
	
	if (tutorialSegments.has(ACTION_ATTACK)
			|| tutorialSegments.has(ACTION_MOVE)
			|| tutorialSegments.has(ACTION_BUILD)
			|| tutorialSegments.has(ACTION_LAUNCH)
			|| tutorialSegments.has(ACTION_MPA)):
		game.call_deferred("connect", "action_initiated", self, "action_initiated", [], CONNECT_ONESHOT)


func get_dialog(message : String, title = null) -> MessageDialog:
	var dialog = load("res://scenes/UI/Tutorial/TutorialDialog.tscn").instance()
	if title != null:
		dialog.set_content(message, title)
	else:
		dialog.set_message(message)
	dialog.tutorial = self
	
	return dialog
