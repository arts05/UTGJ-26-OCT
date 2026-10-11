shader_type canvas_item;
render_mode unshaded;

uniform float travel = 0.0;
uniform vec4 blue : source_color = vec4(0.12, 0.3, 0.9, 1.0);
uniform float trail_strength : hint_range(0.0, 0.4, 0.01) = 0.18;

void fragment() {
	// A clipped group of three blue blocks travels through the empty track.
	float head = fract(travel) * 1.4 - 0.2;
	float block_width = 0.065;
	float block_gap = 0.018;
	float blocks = 0.0;
	for (int index = 0; index < 3; index++) {
		float start = head - float(index) * (block_width + block_gap);
		blocks += step(start, UV.x) * (1.0 - step(start + block_width, UV.x));
	}
	float bevel = 0.6 + 0.4 * sin(UV.y * PI);
	float distance_behind = max(head - UV.x, 0.0);
	float trail = exp(-distance_behind * 14.0) * step(UV.x, head) * trail_strength;
	COLOR = vec4(blue.rgb * bevel, max(blocks, trail)) * COLOR;
}
