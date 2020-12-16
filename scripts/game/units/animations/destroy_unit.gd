extends Reference

var unit
var fx
var fxOffset
var clearAnim
var sfx

var phyUpdate = false


func _init(unit, fx = null, clearAnimOn = null, soundFX = null):
	self.unit = unit
	self.fx = fx
	clearAnim = clearAnimOn
	if soundFX == null:
		sfx = load("res://audio/SFX/Explosion.tscn")
	else:
		sfx = soundFX


func phy_update(delta):
	return true


func update(delta):
	if fx != null:
		var player = unit.player
		if fx.has_method("particle_mask"):
			fx.setMask = !player.is_local_player()
		fx.set_rotation(unit.get_rotation() + fx.get_rotation())
		if fxOffset != null:
			fx.transform.origin += unit.transform.xform(fxOffset)
		else:
			fx.transform.origin = unit.transform.origin
		
		var fxNode = player.game.get_node("Effects")
		fxNode.add_child(fx)
		
		if (Opts.vol_sfx - 0.0 > 0.0001 && (unit.player.is_local_player()
				|| Math.is_near_visible(unit.tile, unit.player.game.thisPlayer))):
			sfx = sfx.instance()
			sfx.transform.origin = unit.transform.origin
			fxNode.add_child(sfx)
		
		
		player.remove_unit(unit)
		if clearAnim != null && clearAnim.has_method("set_finished"):
			clearAnim.fin = true
		if (player.num != player.game.playerTurn
				&& !player.game.players[player.game.playerTurn].is_local_player()):
			player.game.players[player.game.playerTurn].exec_next_task()
		elif player.num == player.game.playerTurn && !player.is_local_player():
			player.exec_next_task()
	
	return true
