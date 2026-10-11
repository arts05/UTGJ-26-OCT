shader_type spatial;
render_mode unshaded, blend_mix, cull_disabled, depth_draw_never, fog_disabled;

uniform sampler2D mist_noise : repeat_enable, filter_linear;
uniform vec4 mist_color : source_color = vec4(0.86, 0.95, 1.0, 1.0);
uniform float opacity : hint_range(0.0, 1.0) = 0.0;
uniform float filament_strength : hint_range(0.0, 0.6, 0.05) = 0.3;

void fragment() {
	// Two moving noise layers break up a soft oval into drifting wisps.
	vec2 drift = vec2(TIME * 0.035, TIME * 0.12);
	float broad_noise = texture(mist_noise, UV * vec2(1.6, 0.42) + drift).r;
	float fine_noise = texture(mist_noise, UV * vec2(3.4, 0.8) - drift * 0.6).r;
	float strands = smoothstep(0.25, 0.72, broad_noise * 0.7 + fine_noise * 0.3);
	vec2 centered = (UV - 0.5) * 2.0;
	float edge_fade = pow(max(0.0, 1.0 - dot(centered, centered)), 2.0);
	float filaments = 1.0 - smoothstep(0.015, 0.09, abs(broad_noise - fine_noise));
	filaments *= smoothstep(0.2, 0.6, broad_noise);
	ALBEDO = mist_color.rgb;
	ALPHA = clamp(strands + filaments * filament_strength, 0.0, 1.0) * edge_fade * opacity;
}
