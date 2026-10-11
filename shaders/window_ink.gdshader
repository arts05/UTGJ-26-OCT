shader_type canvas_item;
render_mode unshaded;

uniform float highlight_amount : hint_range(0.0, 1.0) = 0.0;
uniform float flash_amount : hint_range(0.0, 1.0) = 0.0;
uniform float edge_width : hint_range(1.0, 6.0) = 3.0;
uniform float sheen_strength : hint_range(0.0, 0.3, 0.01) = 0.12;
uniform float success_sweep_strength : hint_range(0.0, 0.4, 0.01) = 0.22;

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

	float top_edge = 1.0 - smoothstep(0.0, 0.32, UV.y);
	COLOR.rgb += vec3(edge * top_edge * highlight_amount * sheen_strength);
	// The existing success animation drives one sweep, rather than an idle sparkle.
	float sweep_center = mix(1.25, -0.25, flash_amount);
	float sweep_distance = abs(UV.x + UV.y * 0.15 - sweep_center);
	float sweep = 1.0 - smoothstep(0.0, 0.12, sweep_distance);
	float light_ink = smoothstep(0.2, 0.8, dot(COLOR.rgb, vec3(0.299, 0.587, 0.114)));
	COLOR.rgb += vec3(sweep * flash_amount * light_ink * success_sweep_strength);
}
