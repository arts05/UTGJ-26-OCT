shader_type canvas_item;
render_mode unshaded;

uniform float grain_strength : hint_range(0.0, 0.15) = 0.045;
uniform float fiber_strength : hint_range(0.0, 0.06, 0.005) = 0.02;

varying vec2 paper_position;

void vertex() {
	paper_position = VERTEX;
}

void fragment() {
	// Static grain stays attached to the paper. Text is a separate child node.
	vec2 grain_cell = floor(paper_position);
	float grain = fract(sin(dot(grain_cell, vec2(12.9898, 78.233))) * 43758.5453);
	COLOR.rgb *= 1.0 - grain * grain_strength;
	vec2 fiber_cell = floor(paper_position * vec2(0.12, 0.8));
	float fiber = fract(sin(dot(fiber_cell, vec2(39.346, 11.135))) * 47453.5453);
	COLOR.rgb *= 1.0 - smoothstep(0.65, 1.0, fiber) * fiber_strength;
}
