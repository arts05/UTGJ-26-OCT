shader_type canvas_item;
render_mode unshaded;

uniform float highlight_amount : hint_range(0.0, 1.0) = 0.0;
uniform float flash_amount : hint_range(0.0, 1.0) = 0.0;
uniform float edge_width : hint_range(1.0, 6.0) = 3.0;

void fragment() {
	vec2 step_size = TEXTURE_PIXEL_SIZE * edge_width;
	float neighboring_alpha = min(
		texture(TEXTURE, UV + vec2(step_size.x, 0.0)).a,
		texture(TEXTURE, UV - vec2(step_size.x, 0.0)).a
	);
	neighboring_alpha = min(neighboring_alpha, texture(TEXTURE, UV + vec2(0.0, step_size.y)).a);
	neighboring_alpha = min(neighboring_alpha, texture(TEXTURE, UV - vec2(0.0, step_size.y)).a);
	float edge = max(texture(TEXTURE, UV).a - neighboring_alpha, 0.0);
	// Hover and dragging brighten only the outline; success still gives a brief flash.
	COLOR.rgb *= 1.0 + flash_amount * 0.09;
	COLOR.rgb += vec3(edge * highlight_amount * 0.16);
}
