shader_type canvas_item;
render_mode unshaded;

uniform vec4 outline_color : source_color = vec4(0.03, 0.03, 0.03, 1.0);

varying vec4 item_tint;

void vertex() {
	item_tint = COLOR;
}

void fragment() {
	vec4 arrow = texture(TEXTURE, UV);
	float outline_alpha = 0.0;
	// One source pixel of outline stays sharp when the cursor is enlarged.
	for (int row = -1; row <= 1; row++) {
		for (int column = -1; column <= 1; column++) {
			vec2 offset = vec2(float(column), float(row)) * TEXTURE_PIXEL_SIZE;
			outline_alpha = max(outline_alpha, texture(TEXTURE, UV + offset).a);
		}
	}
	vec3 color = mix(outline_color.rgb, arrow.rgb, arrow.a);
	float alpha = max(arrow.a, outline_alpha * outline_color.a);
	COLOR = vec4(color, alpha) * item_tint;
}
