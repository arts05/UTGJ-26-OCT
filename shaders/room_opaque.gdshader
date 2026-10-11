shader_type spatial;
// World coordinates keep shadow passes on this material. Godot 4.7 otherwise
// compiles a costly extra default shader on Web, even for our static room.
render_mode cull_disabled, world_vertex_coords;

#include "room_surface.gdshaderinc"

void fragment() {
	ALBEDO = surface_color.rgb * texture(surface_texture, UV).rgb;
	ROUGHNESS = surface_roughness;
	SPECULAR = surface_specular;
	EMISSION = glow_color.rgb * glow_strength;
}
