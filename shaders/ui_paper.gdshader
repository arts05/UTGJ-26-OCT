shader_type canvas_item;
render_mode unshaded;

uniform float grain_strength : hint_range(0.0, 0.15) = 0.045;

varying vec2 paper_position;

void vertex() {
	paper_position = VERTEX;
}

void fragment() {
	// Static grain stays attached to the paper. Text is a separate child node.
	vec2 grain_cell = floor(paper_position);
	float grain = fract(sin(dot(grain_cell, vec2(12.9898, 78.233))) * 43758.5453);
	COLOR.rgb *= 1.0 - grain * grain_strength;
}
