shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled;

uniform sampler2D fire_noise : repeat_enable, filter_linear;
uniform bool smoke = false;
uniform float opacity : hint_range(0.0, 1.0) = 0.8;
uniform float burn_strength : hint_range(0.0, 1.0) = 1.0;
uniform vec3 emitter_origin = vec3(0.0);

varying float particle_phase;

void vertex() {
	// Face the camera while preserving each particle's size and world position.
	particle_phase = INSTANCE_CUSTOM.x;
	VERTEX *= length(MODEL_MATRIX[0].xyz);
	// Small tongues grow into taller, wider flames throughout the recording.
	VERTEX.xy *= mix(vec2(0.2, 0.15), vec2(1.25, 1.7), burn_strength);
	// Keep the first small flames at the vents instead of floating above them.
	vec3 center = mix(emitter_origin, MODEL_MATRIX[3].xyz, mix(0.15, 1.0, burn_strength));
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(
		INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], vec4(center, 1.0)
	);
}

void fragment() {
	vec2 drift = vec2(particle_phase, TIME * (smoke ? 0.14 : 0.8));
	float noise = texture(fire_noise, UV * vec2(1.6, 2.2) + drift).r;
	float detail = texture(fire_noise, UV * 3.5 - drift * 0.4).r;
	vec2 centered = (UV - 0.5) * 2.0;
	if (smoke) {
		float edge = pow(max(0.0, 1.0 - dot(centered, centered)), 2.0);
		ALBEDO = mix(vec3(0.09, 0.08, 0.07), vec3(0.3, 0.24, 0.18), UV.y);
		ALPHA = edge * smoothstep(0.15, 0.75, noise * 0.7 + detail * 0.3) * opacity * COLOR.a;
	} else {
		// Narrow toward the tip; moving noise breaks the silhouette into tongues.
		float height = 1.0 - UV.y;
		float width = mix(0.42, 0.015, height) * (0.55 + noise);
		float sway = (detail - 0.5) * height * 0.35;
		float flame = 1.0 - smoothstep(width * 0.45, width, abs(UV.x - 0.5 + sway));
		float base_fade = smoothstep(0.0, 0.16, height);
		ALBEDO = mix(vec3(1.0, 0.14, 0.012), vec3(1.0, 0.8, 0.28), pow(UV.y, 2.0));
		ALPHA = flame * base_fade * opacity * COLOR.a;
	}
	ALPHA *= smoothstep(0.0, smoke ? 0.35 : 0.1, burn_strength);
}
