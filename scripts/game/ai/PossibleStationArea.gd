extends Reference
class_name PossibleStationArea


var ore := 0
var energy := 0
var origin : CDTile
var nearbyEnemy := false
var nearbyStation := false


func _init(origin : CDTile, player, collectionNodes : Array):
	self.origin = origin
	var checkedStation
	for n in collectionNodes:
		if n.is_collected():
			var cStation = n.collectors[0]
			if (cStation != null && cStation != checkedStation
					&& player.factionManager.factions.has(cStation.player)
					&& Math.get_tile_range(cStation.tile, Dossier.get(CD.UNIT_COMMAND_STATION).attackRange).has(origin)):
				nearbyStation = true
				return
			checkedStation = cStation
			continue
		
		if !n.mapped[player.num]:
			continue
		
		if n.has_star():
			energy += CD.STAR_ENERGY
		elif n.has_asteroid():
			ore += CD.ASTEROID_ORE
		if (n.has_other_player(player.num) && n.unit.type != CD.UNIT_CARGOSHIP
				&& (n.is_visible(player.num) || (n.unit.type == CD.UNIT_COMMAND_STATION && player.factionManager.has_station_tile(n))) && player.factionManager.factions.has(player)):
			nearbyEnemy = true
