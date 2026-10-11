@tool
extends EditorScenePostImport
## Gives imported room props the same small set of shaders as the room scenes.

const OPAQUE_SHADER: Shader = preload("res://shaders/room_opaque.gdshader")
const GLASS_SHADER: Shader = preload("res://shaders/room_glass.gdshader")


func _post_import(scene: Node) -> Object:
	for mesh: MeshInstance3D in scene.find_children("*", "MeshInstance3D", true, false):
		for surface in mesh.mesh.get_surface_count():
			var original := mesh.mesh.surface_get_material(surface) as BaseMaterial3D
			if original != null:
				mesh.mesh.surface_set_material(surface, make_room_material(original))
	return scene


static func make_room_material(original: BaseMaterial3D) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.resource_name = original.resource_name
	material.shader = OPAQUE_SHADER
	if original.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED:
		material.shader = GLASS_SHADER
	material.set_shader_parameter("surface_color", original.albedo_color)
	material.set_shader_parameter("surface_texture", original.albedo_texture)
	material.set_shader_parameter("surface_roughness", original.roughness)
	material.set_shader_parameter("surface_specular", original.metallic_specular)
	return material
