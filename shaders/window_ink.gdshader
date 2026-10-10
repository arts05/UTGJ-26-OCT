shader_type canvas_item;
render_mode unshaded;

uniform float highlight_amount : hint_range(0.0, 1.0) = 0.0;
uniform float flash_amount : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec3 color = COLOR.rgb;
	// Feedback changes brightness only, preserving the colors of the drawn frame.
	color *= 1.0 + highlight_amount * 0.07 + flash_amount * 0.09;
	COLOR.rgb = color;
}
