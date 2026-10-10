shader_type canvas_item;
render_mode unshaded;

uniform sampler2D signal_noise : repeat_enable, filter_linear;
uniform vec4 glow_color : source_color = vec4(0.09, 0.2, 0.17, 1.0);
uniform float glow_strength : hint_range(0.0, 1.0) = 0.55;
uniform float scanline_strength : hint_range(0.0, 0.2) = 0.04;
uniform float rolling_band_strength : hint_range(0.0, 0.2) = 0.06;

void fragment() {
	vec2 drift = vec2(TIME * 0.012, -TIME * 0.007);
	float broad_noise = texture(signal_noise, UV * vec2(1.6, 1.0) + drift).r;
	float fine_noise = texture(signal_noise, UV * vec2(3.2, 1.8) - drift * 0.5).r;
	float mist = smoothstep(0.15, 0.85, mix(broad_noise, fine_noise, 0.25));
	vec2 center = (UV - vec2(0.5, 0.42)) * vec2(1.2, 1.0);
	float halo = exp(-dot(center, center) * 7.0);
	float band_distance = UV.y - (fract(TIME * 0.045) * 1.4 - 0.2);
	float rolling_band = exp(-band_distance * band_distance * 500.0);
	float scanlines = 1.0 - scanline_strength * (0.5 + 0.5 * cos(FRAGCOORD.y * PI));

	// The signal lives behind the menu, so text and buttons remain sharp and still.
	vec3 glow = glow_color.rgb * halo * (mist * glow_strength + rolling_band * rolling_band_strength);
	COLOR = vec4((vec3(0.002, 0.004, 0.004) + glow) * scanlines, 1.0);
}
