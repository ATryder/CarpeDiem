extends Reference
class_name Turn_Snapshot

var incomeOre : int
var incomeEnergy : int
var totalShips : int
var types := {}

var stationsToRemove := []
var stationsToAdd := []


func _init(snapshot : Dictionary, decompress := false):
	var spb = StreamPeerBuffer.new()
	if decompress:
		spb.set_data_array(snapshot.data.decompress(snapshot.size, File.COMPRESSION_FASTLZ))
	else:
		spb.set_data_array(snapshot.data)
	
	incomeOre = spb.get_u16()
	incomeEnergy = spb.get_u16()
	totalShips = spb.get_u16()
	
	var totalTypes = spb.get_u8()
	for i in range(totalTypes):
		var type = spb.get_u8()
		types[type] = spb.get_u16()
	
	var numStations = spb.get_u8()
	for i in range(numStations):
		var add = spb.get_u8() > 0
		var stn = {"tile": Vector2i.new(spb.get_u8(), spb.get_u8()),
					"player": spb.get_u8(),
					"color": spb.get_u8()}
		
		if add:
			stationsToAdd.push_back(stn)
		else:
			var remIdx = -1
			for idx in range(stationsToAdd.size()):
				var addStn = stationsToAdd[idx]
				if addStn.tile.x == stn.tile.x && addStn.tile.y == stn.tile.y:
					remIdx = idx
					break
			
			if remIdx >= 0:
				stationsToAdd.remove(remIdx)
			else:
				stationsToRemove.push_back(stn)


static func take_snapshot(player, turnStations := [], compress := false) -> Dictionary:
	var spb = StreamPeerBuffer.new()
	spb.put_u16(player.incomeOre)
	spb.put_u16(player.incomeEnergy)
	spb.put_u16(player.loadout.get_total_ships())
	spb.put_u8(CD.TOTAL_TYPES)
	for i in range(CD.TOTAL_TYPES):
		var amount = player.loadout.types[i]
		spb.put_u8(i)
		spb.put_u16(amount)
	
	spb.put_u8(turnStations.size())
	for stn in turnStations:
		if stn.add:
			spb.put_u8(1)
		else:
			spb.put_u8(0)
		spb.put_u8(stn.tile.x)
		spb.put_u8(stn.tile.y)
		spb.put_u8(stn.player)
		spb.put_u8(stn.color)
	
	if compress:
		return {"size": spb.get_data_array().size(),
				"data": spb.get_data_array().compress(File.COMPRESSION_FASTLZ)}
	else:
		return {"size": spb.get_data_array().size(),
				"data": spb.get_data_array()}
