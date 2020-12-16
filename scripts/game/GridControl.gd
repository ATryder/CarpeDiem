extends Spatial

export(int, 16) var block_width = 8
export(int, 16) var block_height = 8

const MESH_BLOCK = preload("res://models/shape/MeshBlock.tscn")
const HEX_TILE = preload("res://models/HexTile/HexTile.tscn")
const GRID_MAT = preload("res://models/HexTile/HexTile.material")
