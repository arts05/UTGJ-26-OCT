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

void fragment() {
	vec2 pixel = UV * view_size;
	float noise = texture(fog_noise, UV * 2.2 + vec2(fog_time * 0.017, -fog_time * 0.012)).r;
	float distance_to_player = length((UV - 0.5) * view_size);
	float uneven_edge = distance_to_player + (noise - 0.5) * 42.0;
	float darkness = smoothstep(max(0.0, radius - soft_edge), max(0.01, radius), uneven_edge);
	vec3 mist = vec3(0.014, 0.02, 0.023) * noise * (1.0 - smoothstep(radius, radius + 130.0, distance_to_player));
	vec3 light_color = escaping ? vec3(0.32, 0.9, 0.65) : vec3(1.0);
	float distance_to_objective = length(pixel - objective_position);
	float halo = pow(max(0.0, 1.0 - distance_to_objective / 260.0), 2.0);
	float core = pow(max(0.0, 1.0 - distance_to_objective / 65.0), 2.0);
	float pulse = 0.92 + 0.08 * sin(fog_time * 1.8);
	float glow = (halo * 0.45 + core * 0.4) * objective_strength * pulse * (0.75 + noise * 0.25);
	COLOR = vec4(mist + light_color * glow, max(darkness, glow));
}
