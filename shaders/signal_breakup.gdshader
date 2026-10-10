shader_type canvas_item;
render_mode unshaded;

uniform float interference : hint_range(0.0, 1.0) = 0.0;
uniform float color_separation_pixels : hint_range(0.0, 12.0) = 5.0;

varying vec4 item_tint;

void vertex() {
	item_tint = COLOR;
}

float noise(vec2 point) {
	return fract(sin(dot(point, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	float frame = floor(TIME * 12.0);
	float row = floor(UV.y * 36.0);
	float displacement = (noise(vec2(row, frame)) - 0.5) * interference * 0.035;
	vec2 sample_uv = clamp(UV + vec2(displacement, 0.0), vec2(0.0), vec2(1.0));
	vec2 separation = vec2(TEXTURE_PIXEL_SIZE.x * color_separation_pixels * interference, 0.0);
	vec4 source = texture(TEXTURE, sample_uv);
	vec3 color = vec3(
		texture(TEXTURE, sample_uv + separation).r,
		source.g,
		texture(TEXTURE, sample_uv - separation).b
	);
	float dropout = step(0.86, noise(vec2(row, frame + 7.0)));
	color *= 1.0 - dropout * interference * 0.8;
	float static_grain = noise(vec2(floor(UV.x * 600.0), row + frame));
	color += (static_grain - 0.5) * interference * 0.07;
	COLOR = vec4(color, source.a) * item_tint;
}
