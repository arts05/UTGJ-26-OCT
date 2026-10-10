shader_type canvas_item;
render_mode unshaded;

uniform vec4 shadow_color : source_color = vec4(0.02, 0.025, 0.035, 0.48);

void fragment() {
	// Use the artwork's silhouette, including its uneven hand-drawn edges.
	COLOR = vec4(shadow_color.rgb, COLOR.a * shadow_color.a);
}
