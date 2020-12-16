extends Player
class_name Player_AI

var ai = preload("res://scripts/game/ai/ai_exec/AI_Skirmish.gd")
var ai_thread
var mai : MAI
var sem : Semaphore

var executableTasks := []
var tasksFinished := false

var difficulty := Opts.AI_EASY

var factionManager


class MAI extends Mutex:
	var launch := []
	var rerun := false
	var cancel := false
	var execTasks := false
	var tasks := []
	var assignedUnits := []
	var loopFin := false
	var fin := false


func _init(game, playerNum, playerColor : int, playerHandle = null).(game, playerNum, playerColor, playerHandle):
	pass


func _ready():
	if factionManager == null:
		var enemyFactions = []
		if !Opts.alliedAI:
			for p in game.players:
				if p.num != num:
					enemyFactions.append(p)
		else:
			enemyFactions.append(game.players[game.thisPlayer])
			if difficulty < Opts.AI_HARD:
				var numAllied := int((game.players.size() - 1) / 2)
				if numAllied >= 2:
					var aiPlayers := []
					var thisPlayer
					var idx := 0
					for p in game.players:
						if !p.is_local_player():
							aiPlayers.push_back(p)
							if p.num == num:
								thisPlayer = idx
							idx += 1
					
					if thisPlayer < numAllied:
						for i in range(numAllied, aiPlayers.size()):
							enemyFactions.append(aiPlayers[i])
					else:
						for i in range(numAllied):
							enemyFactions.append(aiPlayers[i])
		
		factionManager = load("res://scripts/game/ai/FactionAssetManager.gd").new(enemyFactions, num)


func exec_ai():
	if ai_thread != null:
		mai.lock()
		var fin = mai.fin
		var loopFin = mai.loopFin
		if !loopFin:
			mai.rerun = true
			mai.execTasks = false
		mai.unlock()
		if fin:
			ai_thread.wait_to_finish()
		else:
			if !loopFin:
				sem.post()
			return
	mai = MAI.new()
	sem = Semaphore.new()
	ai_thread = Thread.new()
	ai_thread.start(self, "ai_loop", [mai, sem])


func ai_loop(data):
	ai.new(self).exec(data)


func exec_next_task():
	if executableTasks == null:
		return
	
	var nextTask = executableTasks.pop_front()
	if nextTask == null:
		sem.post()
		tasksFinished = true
		return
	nextTask.exec()


func cancel_ai() -> bool:
	if mai == null:
		return true
	
	var lock = mai.try_lock() == OK
	if lock:
		mai.cancel = true
		mai.unlock()
		sem.post()
	return lock


func cancel_ai_and_block():
	if mai == null:
		return
	
	mai.lock()
	mai.cancel = true
	mai.unlock()
	sem.post()
	ai_thread.wait_to_finish()


func join_ai_thread():
	if ai_thread != null:
		ai_thread.wait_to_finish()


func start_turn():
	.start_turn()
	if startingTurn >= 0:
		tasksFinished = false
	else:
		exec_ai()


func finish_turn():
	if ai_thread != null && ai_thread.is_active():
		mai.lock()
		if !mai.fin:
			mai.cancel = true
		mai.unlock()
		sem.post()
		ai_thread.wait_to_finish()
	ai_thread = null
	mai = null
	sem = null
	executableTasks.clear()
	.finish_turn()


func _process(delta):
	._process(delta)
	if mai != null && mai.try_lock() == OK:
		if !mai.launch.empty():
			var station = mai.launch.pop_front()
			var buildItem = station.buildItem
			var surrounding = station.tile.get_surrounding()
			var availableTiles = []
			for t in surrounding:
				if !t.is_occupied():
					availableTiles.push_back(t)
			
			var t = Math.get_random_array_item(availableTiles)
			var u = buildItem.launch(t, station, false)
			if u != null:
				if u.type == CD.UNIT_CARGOSHIP && station.mpa > 0:
					u.mpa = min(CD.CARGOSHIP_MAX_MPA, station.mpa)
					station.mpa -= u.mpa
					loadout.subtract_station_mpa(u.mpa)
				loadout.subtract_build(buildItem)
				add_unit(u)
				if Math.is_near_visible(u.tile, game.thisPlayer):
					game.spawn_launch_effects(t, station.player)
			
			if mai.launch.empty():
				sem.post()
			mai.unlock()
		else:
			var execTasks = mai.execTasks && (!mai.rerun || mai.loopFin) && !mai.cancel
			if execTasks:
				mai.execTasks = false
				executableTasks = mai.tasks.duplicate()
				mai.tasks.clear()
				mai.assignedUnits.clear()
				tasksFinished = false
				mai.unlock()
				exec_next_task()
			elif tasksFinished && mai.fin && !mai.cancel:
				mai.unlock()
				game.end_turn()
				if ai_thread != null && ai_thread.is_active():
					ai_thread.wait_to_finish()
					ai_thread = null
				mai = null
				sem = null
			else:
				mai.unlock()
