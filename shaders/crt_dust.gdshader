shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled;

uniform float opacity : hint_range(0.0, 1.0) = 0.18;
uniform float drift_distance : hint_range(0.0, 0.1) = 0.025;

varying float camera_fade;

void vertex() {
	vec3 center = MODEL_MATRIX[3].xyz;
	float phase = INSTANCE_CUSTOM.x;
	center.x += sin(TIME * 0.25 + phase) * drift_distance;
	center.z += cos(TIME * 0.19 + phase) * drift_distance;
	VERTEX *= length(MODEL_MATRIX[0].xyz);
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(
		INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], vec4(center, 1.0)
	);

	// Fade nearby motes as the player leans into the screen, keeping the desktop readable.
	float camera_distance = length((VIEW_MATRIX * vec4(center, 1.0)).xyz);
	camera_fade = smoothstep(0.15, 0.4, camera_distance);
}

void fragment() {
	float radius = length((UV - 0.5) * 2.0);
	float soft_dot = 1.0 - smoothstep(0.05, 1.0, radius);
	// ScreenSpill supplies the current screen color and brightness through particle color.
	ALBEDO = COLOR.rgb;
	ALPHA = soft_dot * opacity * COLOR.a * camera_fade;
}
