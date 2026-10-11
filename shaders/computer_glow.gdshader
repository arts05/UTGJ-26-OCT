shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled;

uniform vec3 glow_color : source_color = vec3(1.0, 0.16, 0.025);
uniform float glow_strength : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec2 centered_uv = (UV - vec2(0.5)) * 2.0;
	float radius = length(centered_uv);
	float soft_edge = 1.0 - smoothstep(0.12, 1.0, radius);
	float halo = exp(-radius * radius * 2.4) * soft_edge;
	ALBEDO = glow_color;
	EMISSION = glow_color * 1.8;
	ALPHA = halo * glow_strength * 0.65;
}
