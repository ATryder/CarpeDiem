extends Spatial
class_name Game

var TERRITORY_GEN = TerritoryGenerator.new()
var snapshotAnalyzer : SnapshotAnalyzer

onready var arena = get_node("Arena")
onready var hud = get_node("HUDLayer")

var LOADED := false
var FIN := false

var rseed

var tutorial

var thisPlayer := 0
var players setget set_players, get_players

var playerTurn := 0
var finishingTurn := -1

var turnStations := []

func _ready():
	if CD.quality_mobile():
		get_node("DirectionalLight").light_specular = 0.5
	
	add_user_signal("start_turn")
	add_user_signal("end_turn")
	add_user_signal("end_game")
	add_user_signal("tile_selected")
	add_user_signal("tile_hovered")
	add_user_signal("action_initiated")
	add_user_signal("action_activated")

func game_loaded(mapGen):
	LOADED = true

func set_players(playerArray):
	if players != null:
		return
	players = playerArray
	for p in players:
		add_child(p)

func get_players():
	return players

func get_player(playerNum) -> Player:
	return players[playerNum]

func is_local_turn() -> bool:
	return playerTurn == thisPlayer && finishingTurn < 0 && !FIN

func spawn_launch_effects(tile : CDTile, player):
	var particles = preload("res://fx/BrownianSpawnFX.tscn").instance()
	particles.transform.origin.x = tile.worldLoc.x
	particles.transform.origin.z = tile.worldLoc.y
	particles.material_override = player.sparkMaterial.duplicate()
	particles.material_override.shader = preload("res://shaders/unshaded/gradient/Masked_CircleGrad.shader")
	match Opts.particleDetail:
		Opts.QUALITY_LOW:
			particles.numParticles = 60
		Opts.QUALITY_MED:
			particles.numParticles = 120
		Opts.QUALITY_HIGH:
			particles.numParticles = 350
		Opts.QUALITY_XHIGH:
			particles.numParticles = 1000
		_:
			particles.numParticles = 60
	add_effects(particles)

func spawn_mpa_effects(tile : CDTile):
	var dustEffect = preload("res://fx/DustRing.tscn").instance()
	dustEffect.transform.origin.x = tile.worldLoc.x
	dustEffect.transform.origin.z = tile.worldLoc.y
	match(Opts.particleDetail):
		Opts.QUALITY_LOW:
			dustEffect.amount = 20
		Opts.QUALITY_MED:
			dustEffect.amount = 50
		Opts.QUALITY_HIGH:
			dustEffect.amount = 102
		Opts.QUALITY_XHIGH:
			dustEffect.amount = 302
	add_effects(dustEffect)

func spawn_mpa_strength_effects(tile : CDTile):
	if tile.unit == null:
		return
	
	var effect : Spatial = CD.unit_sphere[tile.unit.type].instance()
	var mat = effect.get_child(0).get_surface_material(0).duplicate()
	mat.set_shader_param("mask_tex", arena.fogControl.get_mask())
	mat.set_shader_param("mask_offset", arena.fogControl.get_mask_offset())
	mat.set_shader_param("mask_scale", arena.fogControl.get_mask_world_scale())
	effect.get_child(0).set_surface_material(0, mat)
	tile.unit.add_child(effect)

func add_effects(effect):
	get_node("Effects").add_child(effect)

func end_turn():
	hud.infoView.disable_turn_button()
	
	if hud.actionButtonDisplay != null:
		hud.actionButtonDisplay.close()
	hud.selectedTile = null
	
	if (finishingTurn < 0
	&& ((hud.turnIndicator != null && hud.turnIndicator.animating)
	|| playerTurn == thisPlayer && players[thisPlayer].is_alive())):
		finishingTurn = 0
		return
	else:
		finishingTurn = -1
	emit_signal("end_turn", playerTurn, self)
	players[playerTurn].finish_turn()


func next_turn():
	var gameOver = false
	if !players[thisPlayer].is_alive():
		gameOver = true
	
	var player
	if !gameOver:
		var lastPlayer = players[playerTurn]
		if playerTurn == players.size() - 1:
			playerTurn = 0
		else:
			playerTurn += 1
		
		player = players[playerTurn]
		while !player.is_alive():
			if playerTurn == players.size() - 1:
				playerTurn = 0
			else:
				playerTurn += 1
			player = players[playerTurn]
			if player == lastPlayer:
				gameOver = true
				break
	
	if gameOver:
		end_game()
		if hud.turnIndicator != null:
			hud.turnIndicator.finish()
		return
	
	if hud.turnIndicator == null:
		hud.launch_turn_indicator(player)
	else:
		hud.turnIndicator.next_player(player)
	emit_signal("start_turn", player.num, self)
	player.start_turn()


func end_game():
	if !FIN:
		FIN = true
		hud.selectedTile = null
		hud.close_build_menu()
		hud.disable_hud()
		emit_signal("end_game", self)
	
	if snapshotAnalyzer == null:
		var debrief = load("res://scenes/UI/menus/Debrief.tscn").instance()
		snapshotAnalyzer = SnapshotAnalyzer.new(players, thisPlayer,
				debrief.get_node("VBoxContainer/DisplayArea").rect_size,
				debrief.displayPadding)
	elif snapshotAnalyzer.is_finished():
		if snapshotAnalyzer.thread.is_active():
			snapshotAnalyzer.thread.wait_to_finish()
		hud.launch_debrief(snapshotAnalyzer)
		snapshotAnalyzer = null


func _process(delta):
	if finishingTurn >= 0:
		if hud.turnIndicator != null && hud.turnIndicator.animating:
			return
		elif playerTurn == thisPlayer && players[thisPlayer].is_alive():
			var units = players[playerTurn].get_all_units()
			var start = finishingTurn
			var stop = min(start + 10, units.size())
			if stop > start:
				for i in range(start, stop):
					var unit = units[i]
					if (unit == null || !unit.has_method("is_alive")
							|| !unit.is_alive() || unit.is_animating()):
						break
					finishingTurn += 1
			else:
				end_turn()
		else:
			end_turn()
	elif snapshotAnalyzer != null:
		end_game()


func finish_threads_and_block():
	for player in players:
		if !player.is_local_player():
			player.cancel_ai_and_block()
		player.territoryMutexOnDeck = null
		
	if TERRITORY_GEN.thread != null && TERRITORY_GEN.thread.is_active():
		TERRITORY_GEN.tasks.lock()
		for task in TERRITORY_GEN.tasks.tasks:
			task.lock()
			task.cancelled = true
			task.unlock()
		TERRITORY_GEN.tasks.unlock()
		TERRITORY_GEN.thread.wait_to_finish()
	
	if snapshotAnalyzer != null && snapshotAnalyzer.thread.is_active():
		snapshotAnalyzer.cancel_and_block()
		snapshotAnalyzer.thread.wait_to_finish()


func finish_threads() -> bool:
	var finished := true
	
	for player in players:
		if !player.is_local_player():
			if player.mai != null:
				if player.mai.try_lock() == OK:
					player.mai.cancel = true
					var fin = player.mai.fin
					player.mai.unlock()
					player.sem.post()
					if fin:
						if player.ai_thread != null && player.ai_thread.is_active():
							player.ai_thread.wait_to_finish()
					else:
						finished = false
				else:
					finished = false
		player.territoryMutexOnDeck = null
	
	if TERRITORY_GEN.thread != null && TERRITORY_GEN.thread.is_active():
		if TERRITORY_GEN.tasks.try_lock() == OK:
			var fin = TERRITORY_GEN.tasks.fin
			if !fin:
				finished = false
				for task in TERRITORY_GEN.tasks:
					if task.try_lock() == OK:
						task.cancelled = true
						task.unlock()
			else:
				TERRITORY_GEN.thread.wait_to_finish()
			TERRITORY_GEN.tasks.unlock()
		else:
			finished = false
	
	if snapshotAnalyzer != null && snapshotAnalyzer.thread.is_active():
		if snapshotAnalyzer.cancel():
			if snapshotAnalyzer.is_finished():
				snapshotAnalyzer.thread.wait_to_finish()
				finished = true
			else:
				finished = false
		else:
			finished = false
	
	return finished


func _notification(what):
	if (what == MainLoop.NOTIFICATION_WM_QUIT_REQUEST
			|| what == MainLoop.NOTIFICATION_WM_GO_BACK_REQUEST):
		finish_threads_and_block()
