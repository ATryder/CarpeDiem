extends Reference
class_name BuildItem

var dossier : Dictionary


func _init(dossier : Dictionary):
	self.dossier = dossier


func get_type() -> int:
	return dossier.type


func get_name() -> String:
	return dossier.name


func get_icon():
	return CD.unit_icons[dossier.type]


func get_description() -> String:
	return dossier.description


func get_ore() -> float:
	return dossier.oreCost


func get_energy() -> float:
	return dossier.energyCost


func get_remaining_turns(station):
	return station.get_remaining_turns_for_item(dossier)


func build(station):
	if station.incomeOre <= 0:
		return
	
	if station.incomeEnergy >= dossier.energyCost:
		dossier.oreCost -= int(min(dossier.oreCost, station.incomeOre * 2))
	else:
		dossier.oreCost -= int(min(dossier.oreCost, station.incomeOre))


func launch(tile : CDTile, station, addToPlayer := true) :
	var unit = CD.get_unit(dossier.type).instance()
	unit.tile = tile
	if addToPlayer:
		station.player.add_unit(unit)
	station.remove_build_item(self)
	station.reset_tile_display()
	station.update_indicators()
	return unit
