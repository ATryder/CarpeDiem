extends Spatial

const rangeDisplay = preload("res://models/shape/range indicator/RangeIndicator.tscn")

export(Color) var moveColor1
export(Color) var moveColor2
export(Color) var attackColor1
export(Color) var attackColor2
export(Color) var mpaColor1
export(Color) var mpaColor2
export(Color) var launchColor1
export(Color) var launchColor2
export(Color) var collectionColor1
export(Color) var collectionColor2
export(Color) var collectionColor3
export(Color) var collectionColor4

var rangeIndicator
var rangeIndicator2
var moveIndicator


func clear():
	if rangeIndicator != null:
		rangeIndicator.close()
	if rangeIndicator2 != null:
		rangeIndicator2.close()
	if moveIndicator != null:
		moveIndicator.close()
	moveIndicator = null
	rangeIndicator = null
	rangeIndicator2 = null


func clear_now():
	for child in get_children():
		child.queue_free()


func activate_range_indicator(tile : CDTile, tiles : Array,
		color1 : Color, color2 : Color, size := 1.0, tiles2 := [], color3 = null, color4 = null, shareExtent := false):
	if rangeIndicator != null:
		rangeIndicator.close()
	
	rangeIndicator = rangeDisplay.instance()
	rangeIndicator.create_mesh(tile, tiles, color1,
			color2, tiles2, color3, color4, size, shareExtent)
	rangeIndicator.transform.origin = Vector3(tile.worldLoc.x, 0, tile.worldLoc.y)
	add_child(rangeIndicator)
	return rangeIndicator


func activate_range_indicator2(tile : CDTile, tiles : Array,
		color1 : Color, color2 : Color, size := 1.0, tiles2 := [], color3 = null, color4 = null, shareExtent := false):
	if rangeIndicator2 != null:
		rangeIndicator2.close()
	
	rangeIndicator2 = rangeDisplay.instance()
	rangeIndicator2.create_mesh(tile, tiles, color1,
			color2, tiles2, color3, color4, size, shareExtent)
	rangeIndicator2.transform.origin = Vector3(tile.worldLoc.x, 0, tile.worldLoc.y)
	add_child(rangeIndicator2)
	return rangeIndicator2


func update_move_indicator(originTile : CDTile, destTile : CDTile):
	if moveIndicator == null:
		moveIndicator = preload("res://models/shape/move indicator/MoveIndicator.tscn").instance()
		add_child(moveIndicator)
	
	if !rangeIndicator.tiles.has(destTile):
		moveIndicator.hide()
		return
	
	var path = Math.path_to(originTile, destTile, rangeIndicator.tiles)
	moveIndicator.update_geometry(path, Math.create_path_curve(path))
	moveIndicator.transform.origin.x = originTile.worldLoc.x
	moveIndicator.transform.origin.z = originTile.worldLoc.y
	moveIndicator.show()
