shader_type canvas_item;
render_mode unshaded;

uniform vec3 signal_color : source_color = vec3(0.68, 0.76, 0.72);
uniform float strength : hint_range(0.0, 0.3) = 0.1;

void fragment() {
	float edge_fade = 1.0 - smoothstep(0.0, 0.9, UV.x);
	float vertical_fade = smoothstep(0.0, 0.2, UV.y) * (1.0 - smoothstep(0.8, 1.0, UV.y));
	float scanlines = 0.6 + 0.4 * sin(FRAGCOORD.y * PI);
	float sweep = exp(-pow((UV.x - fract(TIME * 0.22)) * 8.0, 2.0));
	COLOR = vec4(signal_color, edge_fade * vertical_fade * (scanlines + sweep * 0.5) * strength);
}
