shader_type canvas_item;
render_mode unshaded;

uniform vec2 view_size = vec2(1200.0, 900.0);
uniform float radius = 300.0;
uniform float soft_edge = 65.0;
uniform sampler2D fog_noise : repeat_enable, filter_linear;
uniform float fog_time = 0.0;
uniform vec2 objective_position = vec2(600.0, 398.0);
uniform float objective_strength = 0.0;
uniform bool escaping = false;
uniform float wisp_strength : hint_range(0.0, 1.0, 0.05) = 0.65;
uniform float light_scatter_strength : hint_range(0.0, 0.4, 0.01) = 0.16;

void fragment() {
	vec2 pixel = UV * view_size;
	float noise = texture(fog_noise, UV * 2.2 + vec2(fog_time * 0.017, -fog_time * 0.012)).r;
	float distance_to_player = length((UV - 0.5) * view_size);
	float uneven_edge = distance_to_player + (noise - 0.5) * 42.0;
	float darkness = smoothstep(max(0.0, radius - soft_edge), max(0.01, radius), uneven_edge);
	vec3 mist = vec3(0.014, 0.02, 0.023) * noise * (1.0 - smoothstep(radius, radius + 130.0, distance_to_player));
	float deep_noise = texture(fog_noise, UV * vec2(3.4, 1.6) - vec2(fog_time * 0.01, fog_time * 0.016)).r;
	float wisps = smoothstep(0.12, 0.55, abs(noise - deep_noise));
	float mist_edge = darkness * (1.0 - smoothstep(radius + 30.0, radius + 220.0, distance_to_player));
	mist += vec3(0.032, 0.039, 0.046) * wisps * mist_edge * wisp_strength;
	vec3 light_color = escaping ? vec3(0.32, 0.9, 0.65) : vec3(1.0);
	float distance_to_objective = length(pixel - objective_position);
	float halo = pow(max(0.0, 1.0 - distance_to_objective / 260.0), 2.0);
	float core = pow(max(0.0, 1.0 - distance_to_objective / 65.0), 2.0);
	float pulse = 0.92 + 0.08 * sin(fog_time * 1.8);
	float glow = (halo * 0.45 + core * 0.4) * objective_strength * pulse * (0.75 + noise * 0.25);

	// Scatter light from the objective toward the player through the moving fog.
	vec2 to_player = view_size * 0.5 - objective_position;
	vec2 light_direction = to_player / max(length(to_player), 1.0);
	vec2 from_light = pixel - objective_position;
	float along_light = dot(from_light, light_direction);
	float across_light = length(from_light - light_direction * along_light);
	float shaft_width = 28.0 + max(along_light, 0.0) * 0.3;
	float shaft = exp(-pow(across_light / shaft_width, 2.0));
	shaft *= smoothstep(-35.0, 30.0, along_light) * (1.0 - smoothstep(80.0, 580.0, along_light));
	float scattered_light = shaft * (0.3 + wisps * 0.7) * darkness;
	glow += scattered_light * objective_strength * pulse * light_scatter_strength;
	COLOR = vec4(mist + light_color * glow, max(darkness, glow));
}
