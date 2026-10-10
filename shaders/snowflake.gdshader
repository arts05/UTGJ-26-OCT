shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled;

uniform vec4 snow_color : source_color = vec4(0.72, 0.79, 0.88, 1.0);
uniform float opacity : hint_range(0.0, 1.0) = 0.75;
uniform float flutter_distance : hint_range(0.0, 0.3) = 0.16;
uniform float edge_softness : hint_range(0.05, 0.6) = 0.25;
uniform float fade_begin = 4.0;
uniform float fade_end = 9.0;

varying float flake_variation;
varying float distance_opacity;

void vertex() {
	vec3 center = MODEL_MATRIX[3].xyz;
	// Each emitter supplies a random starting angle, stable for the flake's lifetime.
	float phase = INSTANCE_CUSTOM.x;
	flake_variation = phase / 6.283185;
	float flutter_time = TIME * mix(0.65, 1.2, flake_variation);
	center.z += sin(flutter_time + phase) * flutter_distance;
	center.x += sin(flutter_time * 0.7 + phase) * flutter_distance * 0.3;
	center.y += sin(flutter_time * 1.3 + phase) * 0.025;

	float particle_scale = length(MODEL_MATRIX[0].xyz);
	float rotation = phase + TIME * mix(-0.45, 0.45, flake_variation);
	mat2 turn = mat2(vec2(cos(rotation), sin(rotation)), vec2(-sin(rotation), cos(rotation)));
	VERTEX.xy = turn * VERTEX.xy;
	VERTEX.x *= mix(0.55, 1.0, abs(sin(flutter_time + phase)));
	VERTEX *= particle_scale;

	// Face the camera while keeping the flake's own position, scale and tumble.
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(
		INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], vec4(center, 1.0)
	);
	float camera_distance = length((VIEW_MATRIX * vec4(center, 1.0)).xyz);
	distance_opacity = 1.0 - smoothstep(fade_begin, fade_end, camera_distance);
}

void fragment() {
	vec2 point = (UV - 0.5) * 2.0;
	float angle = atan(point.y, point.x);
	float radius = 0.65 + 0.07 * cos(angle * 2.0) + 0.05 * sin(angle * 3.0 + flake_variation * 6.283185);
	float distance_from_center = length(point);
	// Subpixel flakes need softer edges to avoid sparkling as they move.
	float softness = max(edge_softness, fwidth(distance_from_center));
	float shape = 1.0 - smoothstep(radius - softness, radius + softness, distance_from_center);
	ALBEDO = snow_color.rgb * mix(0.65, 1.0, flake_variation);
	ALPHA = shape * opacity * COLOR.a * distance_opacity;
}
