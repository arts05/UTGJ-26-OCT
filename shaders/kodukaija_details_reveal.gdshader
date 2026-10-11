shader_type canvas_item;
render_mode unshaded;

uniform float reveal_amount : hint_range(0.0, 1.0) = 0.0;
uniform float edge_softness : hint_range(0.001, 0.2) = 0.035;

void fragment() {
	float edge_position = mix(-edge_softness, 1.0 + edge_softness, reveal_amount);
	float reveal = 1.0 - smoothstep(edge_position - edge_softness, edge_position + edge_softness, UV.x);
	COLOR.a *= reveal;
}
