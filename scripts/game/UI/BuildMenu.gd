extends Control
class_name BuildMenu

const MANYTURNS = 20

onready var queueButtons := [
		QueueButton.new(get_node("QueueButtons/QueueButton")),
		QueueButton.new(get_node("QueueButtons/QueueButton2")),
		QueueButton.new(get_node("QueueButtons/QueueButton3")),
		QueueButton.new(get_node("QueueButtons/QueueButton4"))
		]

onready var itemButtons := {
		CD.UNIT_MPA: ItemButton.new(get_node("ButtonScroll/ButtonBox/mpa"), CD.UNIT_MPA),
		CD.UNIT_CARGOSHIP: ItemButton.new(get_node("ButtonScroll/ButtonBox/cargoship"), CD.UNIT_CARGOSHIP),
		CD.UNIT_NIGHTHAWK: ItemButton.new(get_node("ButtonScroll/ButtonBox/nighthawk"), CD.UNIT_NIGHTHAWK),
		CD.UNIT_GAUMOND: ItemButton.new(get_node("ButtonScroll/ButtonBox/gaumond"), CD.UNIT_GAUMOND),
		CD.UNIT_THANANOS: ItemButton.new(get_node("ButtonScroll/ButtonBox/thananos"), CD.UNIT_THANANOS),
		CD.UNIT_AURORA: ItemButton.new(get_node("ButtonScroll/ButtonBox/aurora"), CD.UNIT_AURORA)
		}

onready var arrowUpButton = get_node("ButtonBox/ArrowUp")
onready var arrowDownButton = get_node("ButtonBox/ArrowDown")
onready var launchButton = get_node("ButtonBox/Launch")
onready var cancelButton = get_node("ButtonBox/Cancel")
onready var buildButton = get_node("ButtonBox/Build")
onready var helpButton = get_node("ButtonBox/Help")
onready var closeButton = get_node("ButtonBox/Close")

onready var hud = get_node("/root/Game/HUDLayer")

onready var statDisplay : Control = get_node("StatDisplay")
onready var statDisplayEmpty : Control = get_node("StatDisplay").duplicate()
var statTrans : ControlTrans_ColumnWipe

onready var titleIcon : TextureRect = get_node("StatDisplay/TitleBackground/HBoxContainer/ItemIconFrame/ItemIcon")
onready var title : Label = get_node("StatDisplay/TitleBackground/HBoxContainer/ItemName")

onready var energyCostLbl : Label = get_node("StatDisplay/ItemCost/VBoxContainer/EnergyDisplay/EnergyCost")
onready var oreCostLbl : Label = get_node("StatDisplay/ItemCost/VBoxContainer/OreDisplay/HBoxContainer/OreCost")
onready var oreDivisorLbl : Label = get_node("StatDisplay/ItemCost/VBoxContainer/OreDisplay/HBoxContainer/OreDivisor")
onready var turnsLbl : Label = get_node("StatDisplay/ItemCost/VBoxContainer/Turns/Turns")

onready var sensorLbl : Label = get_node("StatDisplay/ItemStats/VBoxContainer/SensorRange/SensorRange")
onready var attackLbl : Label = get_node("StatDisplay/ItemStats/VBoxContainer/AttackRange/AttackRange")
onready var moveLbl : Label = get_node("StatDisplay/ItemStats/VBoxContainer/MoveRange/MoveRange")

onready var descriptionLbl : Label = get_node("StatDisplay/DescriptionBackground/DescriptionScroll/Description")

var station setget set_station, get_station

var currentDossier
var queueIdx = -1
var nonQueueIdx = -1

var disabled := false setget set_disabled, is_disabled

func _ready():
	if Opts.theme != Opts.THEME_LIGHT:
		change_theme(Opts.THEME_LIGHT, Opts.theme)
	
	set_process(false)
	get_node("ButtonScroll/ButtonBox/mpa").connect("button_up",
			self, "_set_new_item", [CD.UNIT_MPA])
	get_node("ButtonScroll/ButtonBox/cargoship").connect("button_up",
			self, "_set_new_item", [CD.UNIT_CARGOSHIP])
	get_node("ButtonScroll/ButtonBox/nighthawk").connect("button_up",
			self, "_set_new_item", [CD.UNIT_NIGHTHAWK])
	get_node("ButtonScroll/ButtonBox/gaumond").connect("button_up",
			self, "_set_new_item", [CD.UNIT_GAUMOND])
	get_node("ButtonScroll/ButtonBox/thananos").connect("button_up",
			self, "_set_new_item", [CD.UNIT_THANANOS])
	get_node("ButtonScroll/ButtonBox/aurora").connect("button_up",
			self, "_set_new_item", [CD.UNIT_AURORA])


func set_disabled(value : bool):
	disabled = value
	for ib in itemButtons:
		itemButtons[ib].frame.set_disabled(value)
	for qb in queueButtons:
		qb.frame.set_disabled(value)
	
	if value:
		arrowUpButton.set_disabled(true)
		arrowDownButton.set_disabled(true)
		launchButton.set_disabled(true)
		cancelButton.set_disabled(true)
		buildButton.set_disabled(true)
		helpButton.set_disabled(true)
		closeButton.set_disabled(true)
	elif queueIdx >= 0:
		set_buttons_to_queue_item()
	else:
		set_buttons_to_non_queue()


func is_disabled() -> bool:
	return disabled


func update_station():
	var energy = get_node("AvailableResources/VBoxContainer/EnergyDisplay/AvailableEnergy")
	var ore = get_node("AvailableResources/VBoxContainer/OreDisplay/AvailableOre")
	ore.text = str(station.incomeOre)
	energy.text = str(station.incomeEnergy)
	refresh_queue(is_visible_in_tree())
	refresh_item_buttons()
	populate_dossier(currentDossier)


func populate_dossier(dossier : Dictionary, transition := false):
	if transition:
		transition_stat_display()
	
	currentDossier = dossier
	titleIcon.texture = CD.unit_icons[dossier.type]
	title.text = dossier.name
	
	energyCostLbl.text = "%0.d" % round(dossier.energyCost)
	if dossier.energyCost <= station.incomeEnergy:
		energyCostLbl.add_color_override("font_color", Color(0, 1, 0, 1))
		oreDivisorLbl.show()
	else:
		energyCostLbl.add_color_override("font_color", Color(1, 1, 1, 1))
		oreDivisorLbl.hide()
	
	oreCostLbl.text = "%0.d" % round(dossier.oreCost)
	if dossier.oreCost <= 0:
		turnsLbl.text = "0"
	elif station == null or station.incomeOre <= 0:
		turnsLbl.text = "---"
	elif station.incomeEnergy >= dossier.energyCost:
		var availableOre = station.incomeOre * 2
		if availableOre < dossier.oreCost:
			turnsLbl.text = "%0.d" % ceil(dossier.oreCost / float(availableOre))
		else:
			turnsLbl.text = "1"
	elif station.incomeOre < dossier.oreCost:
		turnsLbl.text = "%0.d" % ceil(dossier.oreCost / float(station.incomeOre))
	else:
		turnsLbl.text = "1"
	
	sensorLbl.text = "%0.d" % ceil(dossier.sensorRange)
	if dossier.minAttackRange > 0:
		attackLbl.text = "%0.d - %0.d" % [dossier.minAttackRange, dossier.attackRange]
	else:
		attackLbl.text = "%0.d" % dossier.attackRange
	moveLbl.text = "%0.d" % dossier.moveRange
	
	descriptionLbl.text = dossier.description


func transition_stat_display():
	var newDisplay = statDisplayEmpty.duplicate()
	titleIcon = newDisplay.get_node("TitleBackground/HBoxContainer/ItemIconFrame/ItemIcon")
	title = newDisplay.get_node("TitleBackground/HBoxContainer/ItemName")
	energyCostLbl = newDisplay.get_node("ItemCost/VBoxContainer/EnergyDisplay/EnergyCost")
	oreCostLbl = newDisplay.get_node("ItemCost/VBoxContainer/OreDisplay/HBoxContainer/OreCost")
	oreDivisorLbl = newDisplay.get_node("ItemCost/VBoxContainer/OreDisplay/HBoxContainer/OreDivisor")
	turnsLbl = newDisplay.get_node("ItemCost/VBoxContainer/Turns/Turns")
	sensorLbl = newDisplay.get_node("ItemStats/VBoxContainer/SensorRange/SensorRange")
	attackLbl = newDisplay.get_node("ItemStats/VBoxContainer/AttackRange/AttackRange")
	moveLbl = newDisplay.get_node("ItemStats/VBoxContainer/MoveRange/MoveRange")	
	descriptionLbl = newDisplay.get_node("DescriptionBackground/DescriptionScroll/Description")
	
	if statDisplay.get_parent() != self:
		if (statTrans != null && statTrans.is_playing()):
			newDisplay.rect_position = statTrans.contPos
			statDisplay.rect_position = statTrans.contPos
			statTrans.set_control(newDisplay)
			statDisplay = newDisplay
			return
		if statDisplay.get_parent() != null:
			statDisplay.get_parent().remove_child(statDisplay)
		add_child(statDisplay)
		move_child(statDisplay, 4)
	
	statTrans = preload("res://scenes/UI/transition/ColumnWipe_Matrix.tscn").instance()
	statTrans.set_transition(statDisplay, newDisplay)
	statTrans.set_colors([Color.purple.blend(Color(0, 0, 1, 0.15)),
			Color.purple.blend(Color(1, 1, 1, 0.1)),
			Color.purple,
			Color.purple.blend(Color(1, 1, 1, 0.1)),
			Color.purple.blend(Color(1, 1, 1, 0.45)),
			Color.purple.blend(Color(1, 1, 1, 0.8)),
			Color.white,
			Color.purple.blend(Color(1, 1, 1, 0.8)),
			Color.purple.blend(Color(1, 1, 1, 0.45)),
			Color.purple.blend(Color(1, 1, 1, 0.1)),
			Color.purple.blend(Color(0, 0, 1, 0.05)),
			Color.purple.blend(Color(0, 0, 1, 0.1)),
			Color.purple.blend(Color(0, 0, 1, 0.2))
			])
	
	statTrans.play()
	statDisplay = newDisplay


func refresh_item_buttons():
	for ib in itemButtons:
		var button = itemButtons[ib]
		button.update_state(Dossier.get(button.type), station)
		if nonQueueIdx == button.type:
			button.set_selected(true, false)
		elif button.is_selected():
			button.set_selected(false, false)


func refresh_queue(transition = true):
	for qb in queueButtons:
		qb.set_item(station, transition)
		if queueIdx == qb.id:
			qb.set_selected(true, false)


func set_station(newStation):
	station = newStation
	currentDossier = station.buildItem
	if currentDossier == null:
		queueIdx = -1
		nonQueueIdx = CD.UNIT_MPA
		currentDossier = Dossier.get(CD.UNIT_MPA)
		set_buttons_to_non_queue()
	else:
		nonQueueIdx = -1
		queueIdx = 0
		currentDossier = currentDossier.dossier
		set_buttons_to_queue_item()
	update_station()


func get_station():
	return station


func _add_to_queue():
	Audio.play_click()
	
	if station.buildQueue.size() == 4:
		return
	
	if station.buildQueue.empty():
		station.buildItem = BuildItem.new(currentDossier.duplicate())
		queueButtons[0].set_item(station)
		station.reset_tile_display()
		station.update_indicators()
		return
	
	station.buildQueue.push_back(BuildItem.new(currentDossier.duplicate()))
	queueButtons[station.buildQueue.size() - 1].set_item(station)


func _remove_from_queue():
	Audio.play_click()
	
	if (queueIdx < 0
			|| queueIdx >= station.buildQueue.size()):
		return
	
	station.remove_build_item(station.buildQueue[queueIdx])
	if queueIdx == 0:
		station.reset_tile_display()
		station.update_indicators()
	for i in range(queueIdx, station.buildQueue.size() + 1):
		queueButtons[i].set_item(station)
	
	var nextItem : BuildItem
	if station.buildQueue.size() == 0:
		queueIdx = -1
		nonQueueIdx = CD.UNIT_MPA
		itemButtons[CD.UNIT_MPA].set_selected(true)
		populate_dossier(Dossier.get(CD.UNIT_MPA), true)
		set_buttons_to_non_queue()
	else:
		if queueIdx == station.buildQueue.size():
			queueIdx -= 1
			queueButtons[queueIdx].set_selected(true)
		else:
			queueButtons[queueIdx].set_selected(true, false)
		populate_dossier(station.buildQueue[queueIdx].dossier, true)
		set_buttons_to_queue_item()


func _launch_ship():
	Audio.play_click()
	
	if currentDossier.type == CD.UNIT_MPA:
		if station.mpa < station.get_max_mpa():
			station.remove_build_item(station.buildItem)
			station.mpa += 1
			station.reset_tile_display()
			station.update_indicators()
			
			for i in range(queueIdx, station.buildQueue.size() + 1):
				queueButtons[i].set_item(station)
			
			if station.buildQueue.size() == 0:
				queueIdx = -1
				nonQueueIdx = CD.UNIT_MPA
				itemButtons[CD.UNIT_MPA].set_selected(true)
				populate_dossier(Dossier.get(CD.UNIT_MPA), true)
				set_buttons_to_non_queue()
			else:
				if queueIdx == station.buildQueue.size():
					queueIdx -= 1
					queueButtons[queueIdx].set_selected(true)
				else:
					queueButtons[queueIdx].set_selected(true, false)
				populate_dossier(station.buildQueue[queueIdx].dossier, true)
				set_buttons_to_queue_item()
		return
	
	if (hud.actionButtonDisplay == null
			or hud.actionButtonDisplay.tile != station.tile):
		close()
		return
	
	hud.actionButtonDisplay.launch_ship(station.buildQueue[queueIdx])


func _move_queue_item_up():
	Audio.play_click()
	
	if queueIdx == 0:
		return
	
	var bi = station.buildQueue[queueIdx]
	station.remove_build_item(bi)
	queueIdx -= 1
	station.buildQueue.insert(queueIdx, bi)
	queueButtons[queueIdx].set_item(station)
	queueButtons[queueIdx + 1].set_item(station)
	queueButtons[queueIdx].set_selected(true, false)
	arrowUpButton.set_disabled(queueIdx == 0)
	arrowDownButton.set_disabled(false)
	if queueIdx == 0:
		station.reset_tile_display()
		station.update_indicators()


func _move_queue_item_down():
	Audio.play_click()
	
	if queueIdx == queueButtons.size() - 1:
		return
	
	var bi = station.buildQueue[queueIdx]
	station.remove_build_item(bi)
	queueIdx += 1
	station.buildQueue.insert(queueIdx, bi)
	queueButtons[queueIdx].set_item(station)
	queueButtons[queueIdx - 1].set_item(station)
	queueButtons[queueIdx].set_selected(true, false)
	arrowUpButton.set_disabled(false)
	arrowDownButton.set_disabled(queueIdx == station.buildQueue.size() - 1)
	if queueIdx == 1:
		station.reset_tile_display()
		station.update_indicators()


func set_buttons_to_non_queue():
	if disabled:
		return
	
	arrowUpButton.set_disabled(true)
	arrowDownButton.set_disabled(true)
	launchButton.set_disabled(true)
	cancelButton.set_disabled(true)
	buildButton.set_disabled(false)
	helpButton.set_disabled(false)
	closeButton.set_disabled(false)


func set_buttons_to_queue_item():
	if disabled:
		return
	
	arrowUpButton.set_disabled(queueIdx == 0)
	arrowDownButton.set_disabled(queueIdx == station.buildQueue.size() - 1)
	launchButton.set_disabled(currentDossier.oreCost > 0
			|| (currentDossier.type == CD.UNIT_MPA && station.mpa >= station.get_max_mpa()))
	cancelButton.set_disabled(false)
	buildButton.set_disabled(true)
	helpButton.set_disabled(false)
	closeButton.set_disabled(false)


func _set_from_queue(queueItem : int):
	Audio.play_click()
	
	if queueItem >= station.buildQueue.size():
		return
	
	if queueIdx >= 0:
		queueButtons[queueIdx].set_selected(false)
	elif nonQueueIdx >= 0:
		itemButtons[nonQueueIdx].set_selected(false)
		nonQueueIdx = -1
	
	queueIdx = queueItem
	populate_dossier(station.buildQueue[queueItem].dossier, true)
	queueButtons[queueIdx].set_selected(true)
	set_buttons_to_queue_item()


func _set_new_item(itemType : int):
	Audio.play_click()
	
	if queueIdx >= 0:
		queueButtons[queueIdx].set_selected(false)
		queueIdx = -1
	elif nonQueueIdx >= 0:
		itemButtons[nonQueueIdx].set_selected(false)
	
	nonQueueIdx = itemType
	itemButtons[nonQueueIdx].set_selected(true)
	populate_dossier(Dossier.get(itemType), true)
	set_buttons_to_non_queue()


func open(parent : Control = hud.popupsGame):
	if is_open():
		return
	
	Audio.play_swish()
	
	get_node("ButtonScroll").scroll_vertical = 0
	
	if statDisplay != null && statDisplay.get_parent() != self:
		if statTrans != null:
			statTrans.stop()
			statTrans._end()
		elif statDisplay.get_parent() != self:
			if statDisplay.get_parent() != null:
				statDisplay.get_parent().remove_child(statDisplay)
			add_child(statDisplay)
			move_child(statDisplay, 4)
	statTrans = null
	
	for qb in queueButtons:
		if qb.frame.anim != null && qb.frame.get_parent() != qb.parent:
			qb.frame.anim.stop()
			qb.frame.anim._end()
	for ib in itemButtons:
		var button = itemButtons[ib]
		if button.frame.anim != null && button.frame.get_parent() != button.parent:
			button.frame.anim.stop()
			button.frame.anim._end()
	
	if parent != null:
		parent.add_child(self)


func dismiss():
	Audio.play_click()
	
	if (hud.actionButtonDisplay == null
			or hud.actionButtonDisplay.tile != station.tile):
		hud.close_build_menu()
		return
	hud.actionButtonDisplay.clear_action()


func close(textureAnim = null):
	for button in queueButtons:
		button.set_selected(false, false)
	
	if hud.actionButtonDisplay != null:
		hud.actionButtonDisplay.set_focused()
	
	if get_parent() != null:
		get_parent().remove_child(self)
	
	if textureAnim != null:
		if (textureAnim.reverse
				|| textureAnim.is_queued_for_deletion()):
			return
		textureAnim.stop()
		textureAnim.queue_free()
		return
	
	Audio.play_swish()


func is_open() -> bool:
	return hud.popupsGame.has_node(self.name)


func display(textureAnim = null):
	if get_parent() != hud.popupsGame:
		if textureAnim != null:
			textureAnim._end()
		if get_parent() != hud.popupsGame:
			if get_parent() != null:
				get_parent().remove_child(self)
			hud.popupsGame.add_child(self)
	
	queueButtons[0].frame.grab_focus()


class ItemButton:
	var frame : FrameButton
	var type : int
	
	func _init(button : Node, unitType : int):
		frame = button as FrameButton
		type = unitType
	
	
	func set_selected(selected : bool, animate : bool = true):
		frame.set_selected(selected, animate)
	
	
	func is_selected() -> bool:
		return frame.is_selected()
	
	
	func update_state(dossier : Dictionary, station):
		var turns = station.get_remaining_turns_for_item(dossier)
		if turns == INF:
			frame.set_frame_red(frame)
		elif turns >= MANYTURNS:
			frame.set_frame_orange(frame)
		else:
			frame.set_frame_blue(frame)


class QueueButton:
	const TRANS_BLINDS = preload("res://scenes/UI/transition/Blinds_DiagonalOffset.tscn")
	
	var parent : Control
	var frame : FrameButton
	var id : int
	
	func _init(button : Node):
		frame = button as FrameButton
		parent = frame.get_parent()
		id = frame.get_index()
	
	
	func set_selected(selected : bool, animate : bool = true):
		frame.set_selected(selected, animate)
	
	
	func is_selected() -> bool:
		return frame.is_selected()
	
	
	func set_item(station, transition = true):
		if station.buildQueue.size() <= id:
			if (frame.get_parent() != parent && frame.anim != null
					&& frame.anim.is_playing()):
				frame.anim.vpTo.render_target_update_mode = Viewport.UPDATE_ONCE
			elif transition && frame.display != null:
				frame.transition()
			frame.display = null
			frame.set_frame_gray(frame)
			frame.set_selected(false, false)
			return
		
		if (frame.get_parent() != parent && frame.anim != null
				&& frame.anim.is_playing()):
			frame.anim.vpTo.render_target_update_mode = Viewport.UPDATE_ONCE
		elif transition:
			frame.transition()
		
		frame.set_selected(false, false)
		var buildItem : BuildItem = station.buildQueue[id]
		frame.display = buildItem.get_icon()
		var turns = buildItem.get_remaining_turns(station)
		if id > 0:
			if turns > 0:
				frame.set_frame_blue(frame)
			else:
				frame.set_frame_green(frame)
			return
		
		if turns == INF:
			frame.set_frame_red(frame)
		elif turns >= MANYTURNS:
			frame.set_frame_orange(frame)
		elif turns > 0:
			frame.set_frame_yellow(frame)
		else:
			frame.set_frame_green(frame)


func change_theme(oldTheme, newTheme):
	var background = get_node("Background")
	match Opts.theme:
		Opts.THEME_DARK:
			background.region_rect = Rect2(1054, 180, 92, 92)
		_:
			background.region_rect = Rect2(0, 0, 92, 92)


func _on_Help():
	Audio.play_click()
	var help = load("res://scenes/UI/dialog/HelpDialog.tscn").instance()
	help.set_content(tr("tutorial_build"), tr("label_build_window"), hud)
	hud.add_dialog(help)
