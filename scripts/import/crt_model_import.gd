@tool
extends EditorScenePostImport
## Prepares arvuti.glb in the editor. This does not build geometry during gameplay.

# This export puts the glass in the black corner of the texture atlas.
# Its front faces +X, and the monitor leans back by 8 degrees.
const GLASS_UV_REGION := Rect2(0.0, 0.0, 0.2, 0.27)
const SCREEN_TILT_DEGREES: float = 8.0
const ROOM_MATERIAL_IMPORT = preload("res://scripts/import/room_material_import.gd")


func _post_import(scene: Node) -> Object:
	var monitor := scene.get_node("Monitor") as MeshInstance3D
	assert(monitor.mesh.get_surface_count() == 1, "The CRT importer expects the original single-material Monitor mesh.")
	var plastic := monitor.mesh.surface_get_material(0) as BaseMaterial3D
	# The project-wide filter only applies to 2D; imported 3D materials set their own.
	plastic.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	var arrays := monitor.mesh.surface_get_arrays(0)
	var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	var uvs: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
	var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	var body_indices := PackedInt32Array()
	var screen_indices := PackedInt32Array()

	for face_start in range(0, indices.size(), 3):
		var face := indices.slice(face_start, face_start + 3)
		var is_glass_front := true
		for index in face:
			if normals[index].x < 0.9 or not GLASS_UV_REGION.has_point(uvs[index]):
				is_glass_front = false
				break
		if is_glass_front:
			screen_indices.append_array(face)
		else:
			body_indices.append_array(face)

	assert(not screen_indices.is_empty(), "No CRT glass found. Update the importer if the model or its UV atlas changed.")
	monitor.name = "Body"
	monitor.mesh = _build_mesh(arrays, body_indices)
	monitor.mesh.surface_set_material(0, ROOM_MATERIAL_IMPORT.make_room_material(plastic))

	var screen_arrays := arrays.duplicate()
	screen_arrays[Mesh.ARRAY_TEX_UV] = _make_screen_uvs(arrays[Mesh.ARRAY_VERTEX], screen_indices)
	var screen := MeshInstance3D.new()
	screen.name = "Screen"
	screen.transform = monitor.transform
	screen.mesh = _build_mesh(screen_arrays, screen_indices)
	var glass := StandardMaterial3D.new()
	glass.albedo_color = Color.BLACK
	glass.roughness = 0.15
	glass.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	screen.mesh.surface_set_material(0, ROOM_MATERIAL_IMPORT.make_room_material(glass))
	scene.add_child(screen)
	screen.owner = scene
	return scene


func _make_screen_uvs(vertices: PackedVector3Array, screen_indices: PackedInt32Array) -> PackedVector2Array:
	# Project along the tilted screen's right/up axes, then fill the whole texture.
	var screen_up := Vector3.UP.rotated(Vector3.BACK, deg_to_rad(SCREEN_TILT_DEGREES))
	var uvs := PackedVector2Array()
	for vertex in vertices:
		uvs.append(Vector2(-vertex.z, -vertex.dot(screen_up)))
	var minimum := Vector2(INF, INF)
	var maximum := Vector2(-INF, -INF)
	for index in screen_indices:
		minimum = minimum.min(uvs[index])
		maximum = maximum.max(uvs[index])
	for index in range(uvs.size()):
		uvs[index] = (uvs[index] - minimum) / (maximum - minimum)
	return uvs


func _build_mesh(arrays: Array, indices: PackedInt32Array) -> ArrayMesh:
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	var uvs: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for index in indices:
		surface.set_normal(normals[index])
		surface.set_uv(uvs[index])
		surface.add_vertex(vertices[index])
	surface.index()
	surface.generate_tangents()
	return surface.commit()
