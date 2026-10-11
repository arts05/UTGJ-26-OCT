shader_type canvas_item;
render_mode unshaded;

uniform vec4 shadow_color : source_color = vec4(0.02, 0.025, 0.035, 0.48);
uniform float softness_pixels : hint_range(0.0, 8.0, 0.5) = 3.0;

varying vec4 item_tint;

void vertex() {
	item_tint = COLOR;
}

void fragment() {
	// Use the artwork's silhouette, including its uneven hand-drawn edges.
	vec2 offset = TEXTURE_PIXEL_SIZE * softness_pixels;
	float silhouette = texture(TEXTURE, UV).a;
	float soft_edge = texture(TEXTURE, UV + vec2(offset.x, offset.y)).a;
	soft_edge += texture(TEXTURE, UV + vec2(-offset.x, offset.y)).a;
	soft_edge += texture(TEXTURE, UV + vec2(offset.x, -offset.y)).a;
	soft_edge += texture(TEXTURE, UV - offset).a;
	// Keep the contact shadow solid, with a softer edge beyond the paper.
	float shadow = max(silhouette, soft_edge * 0.25 * 0.7);
	COLOR = vec4(shadow_color.rgb, shadow * shadow_color.a) * item_tint;
}
