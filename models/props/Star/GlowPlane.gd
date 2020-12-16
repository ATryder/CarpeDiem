extends MeshInstance

export(float) var size

onready var camera = get_tree().root.find_node("GameCam", true, false)

func _ready():
	material_override = null
	draw_plane(size, size)

func draw_plane(var width, var height):
	width *= 0.5
	height *= 0.5
	
	var st = SurfaceTool.new()
	
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	#Lower Right
	st.add_normal(Vector3(0, 0, 1))
	st.add_uv(Vector2(0, 0))
	st.add_vertex(Vector3(-width, height, 0))
	
	#Lower Left
	st.add_normal(Vector3(0, 0, 1))
	st.add_uv(Vector2(1, 0))
	st.add_vertex(Vector3(width, height, 0))
	
	#Upper Right
	st.add_normal(Vector3(0, 0, 1))
	st.add_uv(Vector2(0, 1))
	st.add_vertex(Vector3(-width, -height, 0))
	
	#Upper Left
	st.add_normal(Vector3(0, 0, 1))
	st.add_uv(Vector2(1, 1))
	st.add_vertex(Vector3(width, -height, 0))
	
	#Clockwise ordering
	st.add_index(0)
	st.add_index(2)
	st.add_index(1)
	st.add_index(1)
	st.add_index(2)
	st.add_index(3)
	
	var aMesh = st.commit()
	mesh = aMesh

func _process(delta):
	if camera == null:
		return
	
	self.look_at(camera.get_global_transform().origin,
			Vector3(0, 0, 1))
