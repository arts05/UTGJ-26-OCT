shader_type canvas_item;
render_mode unshaded;

uniform float interference : hint_range(0.0, 1.0) = 0.0;
uniform float brightness : hint_range(0.0, 1.5) = 0.72;
uniform float desaturation : hint_range(0.0, 1.0) = 0.88;
uniform float tear_width : hint_range(0.0, 0.15) = 0.065;
uniform float grain_strength : hint_range(0.0, 0.15) = 0.025;
uniform float scanline_strength : hint_range(0.0, 0.3) = 0.09;
uniform vec3 phosphor_tint : source_color = vec3(0.81, 0.86, 0.84);

varying vec4 item_tint;

void vertex() {
	item_tint = COLOR;
}

float random_value(vec2 point) {
	return fract(sin(dot(point, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	float frame = floor(TIME * 18.0);
	float row = floor(UV.y * 70.0);
	float row_noise = random_value(vec2(row, frame));
	float tear = step(0.72, row_noise) * (row_noise - 0.5) * tear_width * interference;
	vec2 sample_uv = clamp(UV + vec2(tear, 0.0), vec2(0.0), vec2(1.0));
	vec2 separation = vec2(0.004 * interference, 0.0);
	vec4 source = texture(TEXTURE, sample_uv);
	vec3 split_color = vec3(texture(TEXTURE, sample_uv + separation).r, source.g, texture(TEXTURE, sample_uv - separation).b);
	float luminance = dot(source.rgb, vec3(0.299, 0.587, 0.114));
	vec3 color = mix(source.rgb, vec3(luminance), desaturation);
	color += (split_color - source.rgb) * interference * 0.7;

	// A displaced remnant of the old signal appears inside the silhouette.
	vec4 echo = texture(TEXTURE, sample_uv + vec2(0.028, 0.0));
	color += max(echo.rgb * echo.a - source.rgb, vec3(0.0)) * interference * 0.25;
	float dropout = step(0.83, random_value(vec2(row, frame + 9.0)));
	color *= 1.0 - dropout * interference * 0.8;
	float grain = random_value(floor(FRAGCOORD.xy) + vec2(frame * 31.0, frame * 13.0));
	color += (grain - 0.5) * (grain_strength + interference * 0.08);
	color *= 1.0 - scanline_strength * (0.5 + 0.5 * cos(FRAGCOORD.y * PI));

	// Screen-space falloff keeps the left-hand menu clear, regardless of the portrait's crop.
	float left_shadow = smoothstep(0.32, 0.65, SCREEN_UV.x);
	float bottom_shadow = 1.0 - smoothstep(0.62, 1.06, SCREEN_UV.y);
	float edge_shadow = 1.0 - smoothstep(0.84, 1.12, SCREEN_UV.x);
	float flicker = 0.95 + 0.05 * sin(TIME * 7.0);
	color *= phosphor_tint * brightness * flicker;
	COLOR = vec4(color, source.a * left_shadow * bottom_shadow * edge_shadow) * item_tint;
}
