shader_type canvas_item;
render_mode unshaded;

uniform float pressure : hint_range(0.0, 1.0) = 0.0;
uniform float success_amount : hint_range(0.0, 1.0) = 0.0;
uniform float activity_strength : hint_range(0.0, 1.0, 0.05) = 0.6;
uniform float success_strength : hint_range(0.0, 1.0, 0.05) = 0.5;
uniform vec4 grain_color : source_color = vec4(0.66, 0.48, 0.14, 1.0);

float random_row(float row) {
	return fract(sin(row * 127.1) * 43758.5453);
}

void fragment() {
	// Small trails of activity stay behind the file icons, inside the folder.
	float row = floor(UV.y * 18.0);
	float seed = random_row(row);
	float travel = TIME * mix(0.04, 0.16, pressure) + seed;
	float head = fract(travel) * 1.3 - 0.15;
	float trail_distance = head - UV.x;
	float trail = smoothstep(0.0, 0.015, trail_distance);
	trail *= 1.0 - smoothstep(0.015, 0.14, trail_distance);
	float row_center = abs(fract(UV.y * 18.0) - 0.5);
	float fine_line = 1.0 - smoothstep(0.04, 0.12, row_center);
	float active_row = smoothstep(seed * 0.7, seed * 0.7 + 0.3, pressure);
	float activity = trail * fine_line * active_row * pressure * activity_strength;

	// One pale sweep answers a completed line; the timer itself is unchanged.
	float progress = 1.0 - success_amount;
	float sweep_center = mix(-0.15, 1.15, progress);
	float sweep = 1.0 - smoothstep(0.0, 0.12, abs(UV.x - sweep_center));
	float success = sweep * sin(progress * PI) * success_strength;
	vec2 margin = min(UV, 1.0 - UV);
	float edge_fade = smoothstep(0.0, 0.04, margin.x) * smoothstep(0.0, 0.08, margin.y);
	vec3 color = mix(grain_color.rgb, vec3(0.75, 0.88, 0.95), step(activity, success));
	COLOR = vec4(color, max(activity, success) * edge_fade) * COLOR;
}
