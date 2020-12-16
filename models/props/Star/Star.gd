extends Spatial

var glowplane
var star
var tile setget set_tile, get_tile

func _ready():
	var sc = get_parent()
	if glowplane == null:
		glowplane = get_node("GlowPlane")
	if star == null:
		star = get_node("Star")
	if tile != null:
		set_material()
		set_glow_plane_material(sc.get_glow_material(tile.color, star.get_surface_material(0)))
	
func set_tile(t):
	tile = t
	if star != null:
		set_material()
		set_glow_plane_material(get_parent().get_glow_material(tile.color, star.get_surface_material(0)))

func get_tile():
	return tile

func set_glow_plane_material(newMaterial):
	glowplane.set_surface_material(0, newMaterial)

func set_material():
	if tile == null:
		return;
	
	if star == null:
		star = get_node("Star")
		glowplane = get_node("GlowPlane")
		
	var starMat = get_parent().get_material(tile.color)
		
	star.set_surface_material(0, starMat)

func get_material():
	return star.get_surface_material(0)

func get_glow_material():
	return glowplane.get_surface_material(0)
