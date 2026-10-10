shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, fog_disabled;

uniform sampler2D fog_noise : repeat_enable, filter_linear;
uniform vec4 fog_color : source_color = vec4(0.15, 0.2, 0.28, 1.0);
uniform float opacity : hint_range(0.0, 1.0) = 0.6;
uniform vec2 noise_scale = vec2(2.0, 1.0);
uniform vec2 drift = vec2(0.008, -0.002);
uniform float lightning : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec2 movement = drift * TIME;
	float broad_noise = texture(fog_noise, UV * noise_scale + movement).r;
	float fine_noise = texture(fog_noise, UV * noise_scale * 2.3 - movement * 0.5).r;
	float density = smoothstep(0.1, 0.85, mix(broad_noise, fine_noise, 0.25));

	// Fade the edges of each sheet so the fog has no visible rectangular border.
	vec2 edge_fade = smoothstep(vec2(0.0), vec2(0.15), UV);
	edge_fade *= 1.0 - smoothstep(vec2(0.85), vec2(1.0), UV);
	ALBEDO = fog_color.rgb + vec3(0.14, 0.18, 0.23) * lightning;
	ALPHA = density * opacity * edge_fade.x * edge_fade.y;
}
