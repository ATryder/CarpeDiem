extends MeshInstance


func create_mesh(arena, meshArray, startX, startY,
		block_width, block_height, scale = 1.0,
		offset = Vector3(), tileFunc = null, rot = null) -> int:
	
	var mesh = meshArray[0]
	var st = SurfaceTool.new()
	var uv
	var uv2
	var colors
	var norms
	var tans
	var verts
	var indices
	if meshArray.size() == 1:
		uv = mesh.surface_get_arrays(0)[ArrayMesh.ARRAY_TEX_UV]
		uv2 = mesh.surface_get_arrays(0)[ArrayMesh.ARRAY_TEX_UV2]
		colors = mesh.surface_get_arrays(0)[ArrayMesh.ARRAY_COLOR]
		norms = mesh.surface_get_arrays(0)[ArrayMesh.ARRAY_NORMAL]
		tans = mesh.surface_get_arrays(0)[ArrayMesh.ARRAY_TANGENT]
		verts = mesh.surface_get_arrays(0)[ArrayMesh.ARRAY_VERTEX]
		indices = mesh.surface_get_arrays(0)[ArrayMesh.ARRAY_INDEX]
	
	var idxCount = 0
	var numAdded := 0
	
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	for x in range(startX, startX + block_width):
		if x >= arena.MAP_WIDTH:
			break
		for y in range(startY, startY + block_height):
			if y >= arena.MAP_HEIGHT:
				break
			var tile = arena.get_tile(x, y)
			var meshProps
			if tileFunc != null:
				meshProps = tile.call(tileFunc)
				if meshProps == null:
					continue
			numAdded += 1
			
			if meshArray.size() > 1:
				mesh = meshArray[meshProps["meshIndex"]]
				uv = mesh.surface_get_arrays(0)[ArrayMesh.ARRAY_TEX_UV]
				uv2 = mesh.surface_get_arrays(0)[ArrayMesh.ARRAY_TEX_UV2]
				colors = mesh.surface_get_arrays(0)[ArrayMesh.ARRAY_COLOR]
				norms = mesh.surface_get_arrays(0)[ArrayMesh.ARRAY_NORMAL]
				tans = mesh.surface_get_arrays(0)[ArrayMesh.ARRAY_TANGENT]
				verts = mesh.surface_get_arrays(0)[ArrayMesh.ARRAY_VERTEX]
				indices = mesh.surface_get_arrays(0)[ArrayMesh.ARRAY_INDEX]
			
			var trans = Transform(Basis(Vector3(1, 0, 0),
				Vector3(0, 1, 0), Vector3(0, 0, 1)))
			if meshProps != null:
				var prot = meshProps["rotation"]
				trans = trans.rotated(Vector3(1, 0, 0),
						deg2rad(prot.x))
				trans = trans.rotated(Vector3(0, 1, 0),
						deg2rad(prot.y))
				trans = trans.rotated(Vector3(0, 0, 1),
						deg2rad(prot.z))
			if rot != null:
				trans = trans.rotated(Vector3(1, 0, 0),
						deg2rad(rot.x))
				trans = trans.rotated(Vector3(0, 1, 0),
						deg2rad(rot.y))
				trans = trans.rotated(Vector3(0, 0, 1),
						deg2rad(rot.z))
			var baseTrans = trans.basis
			if meshProps != null:
				trans = trans.scaled(Vector3(scale, scale, scale) * meshProps["scale"])
				trans.origin.x = tile.worldLoc.x
				trans.origin.z = tile.worldLoc.y
				trans.origin += meshProps["translation"]
			else:
				trans = trans.scaled(Vector3(scale, scale, scale))
				trans.origin.x = tile.worldLoc.x
				trans.origin.z = tile.worldLoc.y
			trans.origin += offset
			
			for i in range(verts.size()):
				if (uv != null and uv.size() > 0):
					st.add_uv(uv[i])
				if (uv2 != null and uv2.size() > 0):
					st.add_uv2(uv2[i])
				if (colors != null and colors.size() > 0):
					st.add_color(colors[i])
				if (norms != null and norms.size() > 0):
					st.add_normal(baseTrans.xform(norms[i]).normalized())
				if (tans != null and tans.size() >= verts.size() * 4):
					var tidx = i * 4
					var tnorm = baseTrans.xform(
							Vector3(tans[tidx],
							tans[tidx + 1], tans[tidx + 2]))
					var plane = Plane(tnorm.normalized(),
							tans[tidx + 3])
					st.add_tangent(plane)
				st.add_vertex(trans.xform(verts[i]))
			
			for idx in range(indices.size()):
				st.add_index(indices[idx] + idxCount)
			
			idxCount += verts.size()
	
	if numAdded > 0:
		# I've found that the default value for the flags argument to
		# SurfaceTool.commit() results in extremely inaccurate
		# vertex positions farther out from the origin.
		var flags = Mesh.ARRAY_FORMAT_VERTEX & Mesh.ARRAY_FORMAT_INDEX & Mesh.ARRAY_COMPRESS_DEFAULT
		if uv != null and uv.size() > 0:
			flags &= Mesh.ARRAY_FORMAT_TEX_UV
		if uv2 != null and uv2.size() > 0:
			flags &= Mesh.ARRAY_FORMAT_TEX_UV2
		if colors != null and colors.size() > 0:
			flags &= Mesh.ARRAY_FORMAT_COLOR
		if norms != null and norms.size() > 0:
			flags &= Mesh.ARRAY_FORMAT_NORMAL
		if tans != null and tans.size() > 0:
			flags &= Mesh.ARRAY_FORMAT_TANGENT
		self.mesh = st.commit(null, flags)
	
	return numAdded
