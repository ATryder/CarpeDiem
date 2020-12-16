extends Reference
class_name SnapshotAnalyzer

var thread : Thread
var mutex := Mutex.new()
var cancel := false
var fin := false

var players := []
var dataPoints := {"incomeOre": {"maxLength": 0, "players": {}},
					"incomeEnergy": {"maxLength": 0, "players": {}},
					"totalShips": {"maxLength": 0, "players": {}},
					"totalStations": {"maxLength": 0, "players": {}}}
var lines := {"incomeOre": [],
			"incomeEnergy": [],
			"totalShips": [],
			"totalStations": []}
var replayFrames := []


func _init(players, thisPlayer : int, displayAreaSize : Vector2, displayPadding : int):
	thread = Thread.new()
	thread.start(self, "_exec", [players, thisPlayer, displayAreaSize, displayPadding])


func cancel_and_block():
	mutex.lock()
	cancel = true
	mutex.unlock()


func cancel() -> bool:
	if mutex.try_lock() == OK:
		cancel = true
		mutex.unlock()
		return true
	
	return false


func is_finished() -> bool:
	var finished := false
	if mutex.try_lock() == OK:
		finished = fin
		mutex.unlock()
	
	return finished

func _exec(data):
	var cancelled := false
	
	var displayArea = data[2]
	var displayPadding = data[3]
	
	var pIdx = data[1]
	for i in range(data[0].size()):
		players.push_front(data[0][pIdx])
		pIdx += 1
		if pIdx == data[0].size():
			pIdx = 0
	
	var maxValues := {"incomeOre": 1,
						"incomeEnergy": 1,
						"totalShips": 1,
						"totalStations": 1}
	
	var totalTurns := 0.0
	for player in players:
		dataPoints.incomeOre.players[player.num] = []
		dataPoints.incomeEnergy.players[player.num] = []
		dataPoints.totalShips.players[player.num] = []
		dataPoints.totalStations.players[player.num] = []
		
		if player.turns.size() > totalTurns:
			totalTurns = float(player.turns.size())
	
	for i in range(int(totalTurns)):
		mutex.lock()
		cancelled = cancel
		mutex.unlock()
		
		if cancelled:
			mutex.lock()
			fin = true
			mutex.unlock()
			return
		
		for player in players:
			if i >= player.turns.size():
				continue
			
			var snp = Turn_Snapshot.new(player.turns[i])
			if snp.incomeOre > maxValues.incomeOre:
				maxValues.incomeOre = snp.incomeOre
			dataPoints.incomeOre.players[player.num].push_back(snp.incomeOre)
			
			if snp.incomeEnergy > maxValues.incomeEnergy:
				maxValues.incomeEnergy = snp.incomeEnergy
			dataPoints.incomeEnergy.players[player.num].push_back(snp.incomeEnergy)
			
			if snp.totalShips > maxValues.totalShips:
				maxValues.totalShips = snp.totalShips
			dataPoints.totalShips.players[player.num].push_back(snp.totalShips)
			
			if snp.types[CD.UNIT_COMMAND_STATION] > maxValues.totalStations:
				maxValues.totalStations = snp.types[CD.UNIT_COMMAND_STATION]
			dataPoints.totalStations.players[player.num].push_back(snp.types[CD.UNIT_COMMAND_STATION])
		
		for idx in range(players.size()):
			var player = players[players.size() - (idx + 1)]
			if i >= player.turns.size():
				continue
			
			var snp = Turn_Snapshot.new(player.turns[i])
			var frame = {"stationsAdd": [], "stationsRem": []}
			for stn in snp.stationsToAdd:
				frame.stationsAdd.push_back({"player": stn.player, "color": stn.color, "tile": stn.tile})
			for stn in snp.stationsToRemove:
				frame.stationsRem.push_back({"player": stn.player, "tile": stn.tile})
			replayFrames.push_back(frame)
	
	for player in players:
		player.turns.clear()
	
	var maxHeight = displayArea.y - (displayPadding * 2)
	maxValues.incomeOre = maxHeight / maxValues.incomeOre
	maxValues.incomeEnergy = maxHeight / maxValues.incomeEnergy
	maxValues.totalShips = maxHeight / maxValues.totalShips
	maxValues.totalStations = maxHeight / maxValues.totalStations
	
	for player in players:
		mutex.lock()
		cancelled = cancel
		mutex.unlock()
		
		if cancelled:
			mutex.lock()
			fin = true
			mutex.unlock()
			return
		
		var incomeOreLength = 0.0
		var value = dataPoints.incomeOre.players[player.num][0]
		dataPoints.incomeOre.players[player.num][0] = Vector2(0,
				displayArea.y - (value * maxValues.incomeOre))
		
		var incomeEnergyLength = 0.0
		value = dataPoints.incomeEnergy.players[player.num][0]
		dataPoints.incomeEnergy.players[player.num][0] = Vector2(0
				* displayArea.x,
				displayArea.y - (value * maxValues.incomeEnergy))
		
		var totalShipsLength = 0.0
		value = dataPoints.totalShips.players[player.num][0]
		dataPoints.totalShips.players[player.num][0] = Vector2(0,
				displayArea.y - (value * maxValues.totalShips))
		
		var totalStationsLength = 0.0
		value = dataPoints.totalStations.players[player.num][0]
		dataPoints.totalStations.players[player.num][0] = Vector2(0,
				displayArea.y - (value * maxValues.totalStations))
		
		for i in range(1, dataPoints.incomeOre.players[player.num].size()):
			value = dataPoints.incomeOre.players[player.num][i]
			var vec = Vector2((i / (totalTurns - 1)) * displayArea.x,
					displayArea.y - (value * maxValues.incomeOre))
			dataPoints.incomeOre.players[player.num][i] = vec
			incomeOreLength += vec.distance_to(dataPoints.incomeOre.players[player.num][i - 1])
			
			value = dataPoints.incomeEnergy.players[player.num][i]
			vec = Vector2((i / (totalTurns - 1)) * displayArea.x,
					displayArea.y - (value * maxValues.incomeEnergy))
			dataPoints.incomeEnergy.players[player.num][i] = vec
			incomeEnergyLength += vec.distance_to(dataPoints.incomeEnergy.players[player.num][i - 1])
			
			value = dataPoints.totalShips.players[player.num][i]
			vec = Vector2((i / (totalTurns - 1)) * displayArea.x,
					displayArea.y - (value * maxValues.totalShips))
			dataPoints.totalShips.players[player.num][i] = vec
			totalShipsLength += vec.distance_to(dataPoints.totalShips.players[player.num][i - 1])
			
			value = dataPoints.totalStations.players[player.num][i]
			vec = Vector2((i / (totalTurns - 1)) * displayArea.x,
					displayArea.y - (value * maxValues.totalStations))
			dataPoints.totalStations.players[player.num][i] = vec
			totalStationsLength += vec.distance_to(dataPoints.totalStations.players[player.num][i - 1])
		
		if incomeOreLength > dataPoints.incomeOre.maxLength:
			dataPoints.incomeOre.maxLength = incomeOreLength
		if incomeEnergyLength > dataPoints.incomeEnergy.maxLength:
			dataPoints.incomeEnergy.maxLength = incomeEnergyLength
		if totalShipsLength > dataPoints.totalShips.maxLength:
			dataPoints.totalShips.maxLength = totalShipsLength
		if totalStationsLength > dataPoints.totalStations.maxLength:
			dataPoints.totalStations.maxLength = totalStationsLength
	
	var delay := {"incomeOre": 0.0,
				"incomeEnergy": 0.0,
				"totalShips": 0.0,
				"totalStations": 0.0}
	for player in players:
		mutex.lock()
		cancelled = cancel
		mutex.unlock()
		
		if cancelled:
			mutex.lock()
			fin = true
			mutex.unlock()
			return
		
		if dataPoints.incomeOre.players[player.num].size() >= 2:
			var line = GraphLine.new()
			if totalTurns - dataPoints.incomeOre.players[player.num].size() > 0.0001:
				line.create_mesh(dataPoints.incomeOre.players[player.num], 4.0,
						dataPoints.incomeOre.maxLength, player.get_color(), -5.0)
			else:
				line.create_mesh(dataPoints.incomeOre.players[player.num], 4.0,
						dataPoints.incomeOre.maxLength, player.get_color(), -5.0, 5.0)
			line.delay = delay.incomeOre
			line.transform.origin.y = -displayPadding
			lines.incomeOre.push_back(line)
			delay.incomeOre += 0.1
	
		if dataPoints.incomeEnergy.players[player.num].size() >= 2:
			var line = GraphLine.new()
			if totalTurns - dataPoints.incomeEnergy.players[player.num].size() > 0.0001:
				line.create_mesh(dataPoints.incomeEnergy.players[player.num], 4.0,
						dataPoints.incomeEnergy.maxLength, player.get_color(), -5.0)
			else:
				line.create_mesh(dataPoints.incomeEnergy.players[player.num], 4.0,
						dataPoints.incomeEnergy.maxLength, player.get_color(), -5.0, 5.0)
			line.delay = delay.incomeEnergy
			line.transform.origin.y = -displayPadding
			lines.incomeEnergy.push_back(line)
			delay.incomeEnergy += 0.1
		
		if dataPoints.totalShips.players[player.num].size() >= 2:
			var line = GraphLine.new()
			if totalTurns - dataPoints.totalShips.players[player.num].size() > 0.0001:
				line.create_mesh(dataPoints.totalShips.players[player.num], 4.0,
						dataPoints.totalShips.maxLength, player.get_color(), -5.0)
			else:
				line.create_mesh(dataPoints.totalShips.players[player.num], 4.0,
						dataPoints.totalShips.maxLength, player.get_color(), -5.0, 5.0)
			line.delay = delay.totalShips
			line.transform.origin.y = -displayPadding
			lines.totalShips.push_back(line)
			delay.totalShips += 0.1
		
		if dataPoints.totalStations.players[player.num].size() >= 2:
			var line = GraphLine.new()
			if totalTurns - dataPoints.totalStations.players[player.num].size() > 0.0001:
				line.create_mesh(dataPoints.totalStations.players[player.num], 4.0,
						dataPoints.totalStations.maxLength, player.get_color(), -5.0)
			else:
				line.create_mesh(dataPoints.totalStations.players[player.num], 4.0,
						dataPoints.totalStations.maxLength, player.get_color(), -5.0, 5.0)
			line.delay = delay.totalStations
			line.transform.origin.y = -displayPadding
			lines.totalStations.push_back(line)
			delay.totalStations += 0.1
	
	mutex.lock()
	fin = true
	mutex.unlock()
