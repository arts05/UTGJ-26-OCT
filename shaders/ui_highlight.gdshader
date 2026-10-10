shader_type canvas_item;
render_mode unshaded;

uniform float hover_amount : hint_range(0.0, 1.0) = 0.0;
uniform float flash_amount : hint_range(0.0, 1.0) = 0.0;
uniform vec4 highlight_color : source_color = vec4(1.0, 0.91, 0.63, 1.0);

varying vec2 surface_position;

void vertex() {
	surface_position = VERTEX;
}

void fragment() {
	float sweep = fract((surface_position.x - surface_position.y * 0.5) / 240.0 - TIME * 0.45);
	float shine = smoothstep(0.28, 0.43, sweep) * (1.0 - smoothstep(0.43, 0.58, sweep));
	// Only brighten the surface, keeping dark lettering readable.
	float light_surface = smoothstep(0.12, 0.65, dot(COLOR.rgb, vec3(0.299, 0.587, 0.114)));
	float amount = hover_amount * (0.06 + shine * 0.22) + flash_amount * 0.55;
	COLOR.rgb = mix(COLOR.rgb, highlight_color.rgb, amount * light_surface);
}
