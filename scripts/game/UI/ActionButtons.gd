extends HBoxContainer
class_name Actions

enum ACTION {
	MOVE,
	ATTACK,
	MPA,
	BUILD,
	LAUNCH
	}

var game
var mc
var indicators

var tile

var activeAction

var transition
var isClosing := false
var isOpening := false

func _ready():
	if game == null:
		game = get_node("/root/Game")
		mc = game.get_node("Arena/MouseControl")
		indicators = game.get_node("Arena/ActionIndicators")


func close():
	if isClosing:
		return
	
	isClosing = true
	if isOpening:
		transition.callback = null
		transition.stop()
		transition.queue_free()
		return
	
	clear_action(false)
	outtro()


func open(tile : CDTile, parent, game):
	if isOpening || isClosing:
		return
	
	self.tile = tile
	self.game = game
	mc = game.get_node("Arena/MouseControl")
	indicators = game.get_node("Arena/ActionIndicators")
	update_button_state()
	isOpening = true
	initiate_action_buttons()
	intro(parent)


func intro(parent):
	parent.add_child(self)
	transition = preload("res://scenes/UI/transition/ColumnWipe_ActionButton.tscn").instance()
	transition.callback = [self, "on_display"]
	transition.set_control(self)
	transition.play()


func on_display(transition = null):
	isOpening = false
	self.transition = null


func outtro():
	transition = preload("res://scenes/UI/transition/ColumnWipe_SimplexSwoosh.tscn").instance()
	transition.reverse = true
	transition.reattach = false
	transition.length = 0.5
	transition.set_control(self)
	
	transition.columns = 14
	transition.offset = 0.5
	transition.angle = PI/2.0
	transition.set_colors([
			Color.yellow.blend(Color(1, 1, 1, 0.8)),
			Color.white,
			Color.yellow.blend(Color(1, 1, 1, 0.8)),
			Color.yellow.blend(Color(1, 1, 1, 0.6)),
			Color.yellow.blend(Color(1, 1, 1, 0.3)),
			Color.yellow,
			Color.yellow.blend(Color(1, 1, 1, 0.3)),
			Color.yellow.blend(Color(1, 1, 1, 0.6))
			])
	transition.play()


func finish():
	queue_free()


func update_button_state():
	if isClosing or tile.unit == null:
		return
	set_disabled(tile.unit.is_animating())


func set_disabled(disable : bool):
	if disable:
		for button in get_children():
			if button.has_method("set_disabled"):
				button.disabled = true
		return
	elif tile.unit == null || tile.unit.is_animating() || game.hud.disabled:
		return 
	
	for button in get_children():
		match button.name:
			"Move":
				button.disabled = tile.unit.moves <= 0
			"Attack":
				button.disabled = tile.unit.attacks <= 0
			"Launch":
					button.disabled = (tile.unit.buildItem == null
							|| tile.unit.buildItem.get_type() == CD.UNIT_MPA
							|| tile.unit.buildItem.get_remaining_turns(tile.unit) > 0)
			"MPA":
				button.disabled = tile.unit.mpa <= 0
			"CommandStation":
				button.disabled = tile.unit.mpa < tile.unit.get_max_mpa()
			_:
				if button.has_method("set_disabled"):
					button.disabled = false


func set_focused():
	for b in get_children():
		if b.has_method("set_disabled") && !b.disabled:
			b.grab_focus()
			return


func initiate_action_buttons():
	if tile.unit.type == CD.UNIT_CARGOSHIP:
		var collectionRange = Math.get_tile_range(game.hud.hoveredTile, CD.COMMAND_STATION_RESOURCE_RANGE)
		var cr := []
		var crNo := []
		for t in collectionRange:
			if !t.is_visible(game.thisPlayer) || !t.is_collected():
				cr.push_back(t)
			else:
				crNo.push_back(t)
		if !cr.empty() || !crNo.empty():
			indicators.activate_range_indicator(game.hud.hoveredTile, cr,
					indicators.collectionColor1, indicators.collectionColor2, 0.65,
					crNo, indicators.collectionColor3, indicators.collectionColor4,
					true)
			indicators.rangeIndicator.rspeed *= 0.75


func clear_action(returnToDefaultState := true):
	if mc.hoverCallback != null && mc.hoverCallback.cls == self:
		mc.hoverCallback = null
	if mc.selectionCallback != null && mc.selectionCallback.cls == self:
		mc.selectionCallback = null
	
	indicators.clear()
	
	if activeAction == ACTION.BUILD:
		game.hud.close_build_menu()
	elif activeAction == ACTION.ATTACK:
		var attackDisplay = game.hud.get_node("AttackPredictionDisplay")
		for display in attackDisplay.get_children():
			display.close()
	
	activeAction = null
	mc.hoverCallback = null
	mc.selectionCallback = null
	
	if isClosing || !returnToDefaultState:
		return
	
	initiate_action_buttons()


func is_action_active() -> bool:
	return activeAction != null


func clear_indicators():
	for child in indicators.get_children():
		child.queue_free()


func move():
	Audio.play_click()
	if activeAction == ACTION.MOVE:
		clear_action()
		return
	
	clear_action(false)
	
	activeAction = ACTION.MOVE
	var tiles = tile.unit.get_movement_range()
	if tiles.size() == 0:
		return
	
	indicators.activate_range_indicator(tile, tiles,
			indicators.moveColor1, indicators.moveColor2)
	
	mc.hoverCallback = MethodRef.new(indicators, "update_move_indicator", [tile])
	mc.selectionCallback = MethodRef.new(self, "select_move_tile")
	
	if tiles.has(game.hud.hoveredTile):
		indicators.update_move_indicator(tile, game.hud.hoveredTile)
	
	game.emit_signal("action_initiated", activeAction)


func attack():
	Audio.play_click()
	if activeAction == ACTION.ATTACK:
		clear_action()
		return
	
	clear_action(false)
	
	activeAction = ACTION.ATTACK
	var tiles = tile.unit.get_attack_range()
	if tiles.size() == 0:
		return
	
	indicators.activate_range_indicator(tile, tiles,
			indicators.attackColor1, indicators.attackColor2)
	
	mc.hoverCallback = MethodRef.new(self, "hover_attack_tile")
	mc.selectionCallback = MethodRef.new(self, "select_attack_tile")
	
	if tiles.has(game.hud.hoveredTile):
		hover_attack_tile(game.hud.hoveredTile)
	
	game.emit_signal("action_initiated", activeAction)


func mpa():
	Audio.play_click()
	if activeAction == ACTION.MPA:
		clear_action()
		return
	
	clear_action(false)
	
	activeAction = ACTION.MPA
	var tiles = []
	var tmptiles = tile.get_surrounding()
	for t in tmptiles:
		if t.get_player_number() == tile.get_player_number() or !t.is_occupied():
			tiles.push_back(t)
	indicators.activate_range_indicator(tile, tiles,
			indicators.mpaColor1, indicators.mpaColor2)
	
	mc.hoverCallback = MethodRef.new(self, "hover_mpa_tile")
	mc.selectionCallback = MethodRef.new(self, "select_mpa_tile")
	
	game.emit_signal("action_initiated", activeAction)


func command_station():
	Audio.play_click()
	if !tile.collectors.empty():
		game.hud.message(tr("message_station_in_territory"))
		clear_action()
		return
	
	if tile.unit.mpa < tile.unit.get_max_mpa():
		game.hud.message(tr("message_insufficient_mpa") % CD.CARGOSHIP_MAX_MPA)
		clear_action()
		return
	
	clear_action(false)
	
	var collectionTiles = Math.get_resource_tiles(tile)
	var stars = 0
	var asteroids = 0
	for t in collectionTiles:
		if t.has_star():
			stars += 1
		if t.has_asteroid():
			asteroids += 1
	if stars == 0:
		game.hud.message(tr("message_insufficient_station_resources") % [CD.COMMAND_STATION_MIN_ENERGY, CD.COMMAND_STATION_MIN_ORE])
		return
	
	var player = tile.unit.player
	player.remove_unit(tile.unit, false)
	var commandStation = CD.get_unit(CD.UNIT_COMMAND_STATION).instance()
	commandStation.tile = tile
	commandStation.calcBoundaries = true
	player.add_unit(commandStation)
	commandStation.attacks = 0
	game.spawn_launch_effects(tile, player)
	
	mc.selectedTile = null
	mc.selectedTile = tile
	
	game.emit_signal("action_initiated", activeAction)


func build_queue():
	Audio.play_click()
	if activeAction == ACTION.BUILD:
		clear_action()
		return
	
	clear_action(false)
	activeAction = ACTION.BUILD
	game.hud.launch_build_menu(tile.unit)
	
	game.emit_signal("action_initiated", activeAction)


func launch_ship(buildItem = tile.unit.buildItem):
	if activeAction == ACTION.LAUNCH:
		clear_action()
		return
	Audio.play_click()
	clear_action(false)
	
	activeAction = ACTION.LAUNCH
	var tiles = []
	var tmptiles = tile.get_surrounding()
	for t in tmptiles:
		if !t.is_occupied():
			tiles.push_back(t)
	indicators.activate_range_indicator(tile, tiles,
			indicators.launchColor1, indicators.launchColor2)
	mc.selectionCallback = MethodRef.new(self, "select_launch_tile", [buildItem])
	
	game.emit_signal("action_initiated", activeAction)


func delete(dialogToClose = null):
	Audio.play_click()
	if dialogToClose == null:
		game.emit_signal("action_initiated", activeAction)
		var dialog = game.hud.message(tr("message_delete_unit"), tr("label_delete"))
		dialog.set_positive_button(MethodRef.new(self, "delete", [dialog]), tr("label_yes"))
		dialog.set_negative_button(MethodRef.new(game.hud, "close_dialog", [dialog]))
	else:
		game.hud.close_dialog(dialogToClose)
		clear_action(false)
		tile.unit.damage_unit(20)


func select_move_tile(destTile : CDTile):
	if !indicators.rangeIndicator.tiles.has(destTile):
		if destTile.is_occupied() && destTile.is_visible(game.thisPlayer):
			clear_action(false)
			game.hud.selectedTile = destTile
		return
	
	if indicators.moveIndicator == null:
		return
	
	game.emit_signal("action_activated", ACTION.MOVE)
	
	var path = indicators.moveIndicator.path
	var curve = indicators.moveIndicator.curve
	clear_action()
	tile.unit.move_along_path(path, curve)


func hover_attack_tile(attackTile : CDTile):
	var attackDisplay = game.hud.get_node("AttackPredictionDisplay")
	var instantiateDisplay = (attackTile != null
			&& indicators.rangeIndicator.tiles.has(attackTile)
			&& attackTile.has_other_player(game.thisPlayer)
			&& attackTile.is_visible(game.thisPlayer))
	
	for display in attackDisplay.get_children():
		if display.tile != attackTile:
			display.close()
		elif !display.closing:
			instantiateDisplay = false
	
	if !instantiateDisplay:
		return
	
	var attack = Math.calc_attack_amount(game.hud.selectedTile.unit, attackTile.unit, true)
	
	var counterAttack = 0
	if attackTile.unit.get_attack_range().has(game.hud.selectedTile):
		counterAttack = Math.calc_counter_attack_amount(attackTile.unit,
				game.hud.selectedTile.unit, true, max(attackTile.unit.strength - attack, 0))
	
	var attackPrediction = load("res://scenes/UI/AttackPrediction.tscn").instance()
	attackPrediction.tile = attackTile
	attackPrediction.set_attacker(game.players[game.thisPlayer], game.hud.selectedTile.unit.type, counterAttack)
	attackPrediction.set_defender(attackTile.unit.player, attackTile.unit.type, attack)
	attackDisplay.add_child(attackPrediction)


func select_attack_tile(attackTile : CDTile):
	if attackTile.is_occupied():
		if (attackTile.get_player_number() == game.thisPlayer
				|| !indicators.rangeIndicator.tiles.has(attackTile)):
			if attackTile.is_visible(game.thisPlayer):
				clear_action(false)
				game.hud.selectedTile = attackTile
			return
		
		if !attackTile.unit.is_animating() && attackTile.unit.is_alive():
			game.emit_signal("action_activated", ACTION.ATTACK)
			clear_action()
			
			var attackDisplay = game.hud.get_node("AttackPredictionDisplay")
			for display in attackDisplay.get_children():
				display.close()
			
			tile.unit.attack_tile(attackTile)


func select_launch_tile(buildItem, launchTile : CDTile):
	if !indicators.rangeIndicator.tiles.has(launchTile):
		if launchTile.is_occupied() && launchTile.is_visible(game.thisPlayer):
			clear_action(false)
			game.hud.selectedTile = launchTile
		return
	
	clear_action()
	if buildItem == null:
		return
	
	if buildItem.launch(launchTile, tile.unit) != null:
		game.emit_signal("action_activated", ACTION.LAUNCH)
		game.spawn_launch_effects(launchTile, tile.unit.player)
		update_button_state()


func hover_mpa_tile(mpaTile : CDTile):
	return


func select_mpa_tile(mpaTile : CDTile):
	if !indicators.rangeIndicator.tiles.has(mpaTile):
		if mpaTile.is_occupied() && mpaTile.is_visible(game.thisPlayer):
			clear_action(false)
			game.hud.selectedTile = mpaTile
		return
	
	if mpaTile.unit == null:
		return
	
	if !mpaTile.get_player().is_local_player():
		game.hud.message(tr("message_mpa_enemy_unit"), tr("message_title_mpa_delivery"))
		return
	
	game.emit_signal("action_activated", ACTION.MPA)
	
	if mpaTile.unit.get_max_mpa() > 0:
		if mpaTile.unit.type == CD.UNIT_COMMAND_STATION:
			if mpaTile.unit.mpa >= mpaTile.unit.get_max_mpa():
				game.hud.message(tr("message_mpa_full"), tr("message_title_mpa_delivery"))
			else:
				add_mpa_cargo_to_unit(mpaTile.unit, null)
		elif mpaTile.unit.mpa >= mpaTile.unit.get_max_mpa():
			if mpaTile.unit.strength >= mpaTile.unit.maxStrength:
				game.hud.message(tr("message_mpa_full"), tr("message_title_mpa_delivery"))
			else:
				add_strength_to_unit(mpaTile.unit, null)
		elif mpaTile.unit.strength >= mpaTile.unit.maxStrength:
			add_mpa_cargo_to_unit(mpaTile.unit, null)
		else:
			#Ask add strength or cargo
			var md : MessageDialog = game.hud.message(tr("message_mpa_strength_cargo"), tr("message_title_mpa_delivery"))
			var mRef : MethodRef = MethodRef.new(self, "add_strength_to_unit", [mpaTile.unit, md])
			md.set_positive_button(mRef, tr("label_strength"))
			mRef = MethodRef.new(self, "add_mpa_cargo_to_unit", mRef.args)
			md.set_negative_button(mRef, tr("label_cargo"))
			md.set_neutral_button(MethodRef.new(game.hud, "close_dialog", [md]), tr("label_cancel"))
		
		if tile.unit.mpa <= 0:
			clear_action()
		return
	
	if mpaTile.unit.strength < mpaTile.unit.maxStrength:
		add_strength_to_unit(mpaTile.unit, null)
	else:
		game.hud.message(tr("message_mpa_full_strength"), tr("message_title_mpa_delivery"))
	
	if tile.unit.mpa <= 0:
		clear_action()


func add_strength_to_unit(unit, messageDialog : MessageDialog):
	if messageDialog != null:
		game.hud.close_dialog(messageDialog)
	
	unit.strength += CD.MPA_HEAL_AMOUNT
	game.spawn_mpa_strength_effects(unit.tile)
	
	if !tile.unit is CommandStation:
		tile.unit.set_mpa(tile.unit.mpa - 1)
		return
	
	var buildItem = tile.unit.buildItem
	if buildItem == null || buildItem.get_ore() > 0 || buildItem.get_type() != CD.UNIT_MPA:
		tile.unit.set_mpa(tile.unit.mpa - 1)
		return
	tile.unit.remove_build_item(buildItem)
	tile.unit.reset_tile_display()
	tile.unit.update_indicators()


func add_mpa_cargo_to_unit(unit, messageDialog : MessageDialog):
	if messageDialog != null:
		game.hud.close_dialog(messageDialog)
	
	if tile == null || tile.unit == null || tile.unit.get_max_mpa() <= 0:
		clear_action()
		game.hud.error(tr("error_originating_unit"))
		return
	
	game.spawn_mpa_effects(unit.tile)
	unit.mpa += 1
	
	if !tile.unit is CommandStation:
		tile.unit.set_mpa(tile.unit.mpa - 1)
		return
	
	var buildItem = tile.unit.buildItem
	if buildItem == null || buildItem.get_ore() > 0 || buildItem.get_type() != CD.UNIT_MPA:
		tile.unit.set_mpa(tile.unit.mpa - 1)
		return
	tile.unit.remove_build_item(buildItem)
	tile.unit.reset_tile_display()
	tile.unit.update_indicators()
