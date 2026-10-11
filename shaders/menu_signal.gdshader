shader_type canvas_item;
render_mode unshaded;

uniform sampler2D signal_noise : repeat_enable, filter_linear;
uniform vec4 glow_color : source_color = vec4(0.1, 0.12, 0.115, 1.0);
uniform float glow_strength : hint_range(0.0, 1.0) = 0.28;
uniform float grain_strength : hint_range(0.0, 0.15) = 0.028;
uniform float scanline_strength : hint_range(0.0, 0.3) = 0.12;
uniform float rolling_band_strength : hint_range(0.0, 0.2) = 0.035;
uniform float interference : hint_range(0.0, 1.0) = 0.0;

float random_value(vec2 point) {
	return fract(sin(dot(point, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	vec2 drift = vec2(TIME * 0.012, -TIME * 0.007);
	float broad_noise = texture(signal_noise, UV * vec2(1.6, 1.0) + drift).r;
	float fine_noise = texture(signal_noise, UV * vec2(3.2, 1.8) - drift * 0.5).r;
	float mist = smoothstep(0.15, 0.85, mix(broad_noise, fine_noise, 0.25));
	vec2 center = (UV - vec2(0.74, 0.42)) * vec2(1.2, 1.0);
	float halo = exp(-dot(center, center) * 7.0);
	float band_distance = UV.y - (fract(TIME * 0.045) * 1.4 - 0.2);
	float rolling_band = exp(-band_distance * band_distance * 500.0);
	float scanlines = 1.0 - scanline_strength * (0.5 + 0.5 * cos(FRAGCOORD.y * PI));

	// Grain and tracking remain behind the controls and never displace their hit areas.
	vec3 glow = glow_color.rgb * halo * (mist * glow_strength + rolling_band * rolling_band_strength);
	float frame = floor(TIME * 16.0);
	float grain = random_value(floor(FRAGCOORD.xy) + vec2(frame * 17.0, frame * 29.0));
	float row = floor(FRAGCOORD.y / 3.0);
	float tracking = step(0.96, random_value(vec2(row, frame))) * interference;
	float left_fade = mix(0.35, 1.0, smoothstep(0.15, 0.7, UV.x));
	glow += vec3(grain * grain_strength + tracking * 0.1 + rolling_band * rolling_band_strength) * left_fade;
	float vignette = 1.0 - smoothstep(0.25, 0.82, length(UV - 0.5));
	COLOR = vec4((vec3(0.0015) + glow) * scanlines * vignette, 1.0);
}
