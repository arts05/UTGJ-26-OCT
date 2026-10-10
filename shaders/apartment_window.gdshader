shader_type spatial;
render_mode unshaded, cull_disabled;

uniform sampler2D building_texture : source_color, filter_nearest;
uniform vec4 light_color : source_color = vec4(1.0, 0.68, 0.34, 1.0);
uniform float brightness : hint_range(0.0, 1.0) = 0.6;

void fragment() {
	// Sprite3D regions supply the original pane's UVs, keeping its texture detail.
	vec3 pane = texture(building_texture, UV).rgb;
	float detail = dot(pane, vec3(0.2126, 0.7152, 0.0722));
	ALBEDO = light_color.rgb * brightness * (0.6 + detail * 0.4);
}
