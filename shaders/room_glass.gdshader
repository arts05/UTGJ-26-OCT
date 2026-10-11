shader_type spatial;
render_mode cull_disabled, blend_mix, depth_prepass_alpha;

#include "room_surface.gdshaderinc"

void fragment() {
	vec4 surface = surface_color * texture(surface_texture, UV);
	ALBEDO = surface.rgb;
	ALPHA = surface.a;
	ROUGHNESS = surface_roughness;
	SPECULAR = surface_specular;
}
