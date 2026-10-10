shader_type canvas_item;
render_mode unshaded;

uniform vec2 view_size = vec2(1200.0, 840.0);
uniform float radius = 300.0;
uniform float soft_edge = 45.0;

void fragment() {
	// The house camera follows the player, so the visible area stays at the center.
	float distance_to_player = length((UV - 0.5) * view_size);
	float darkness = smoothstep(max(0.0, radius - soft_edge), max(0.01, radius), distance_to_player);
	COLOR = vec4(0.0, 0.0, 0.0, darkness);
}
