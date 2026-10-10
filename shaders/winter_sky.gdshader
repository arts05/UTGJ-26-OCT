shader_type spatial;
render_mode unshaded, cull_disabled, fog_disabled;

uniform vec4 night_color : source_color = vec4(0.008, 0.014, 0.025, 1.0);
uniform vec4 horizon_color : source_color = vec4(0.045, 0.065, 0.09, 1.0);
uniform sampler2D fog_noise : repeat_enable, filter_linear;
uniform float lightning : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	float horizon = smoothstep(0.0, 1.0, UV.y);
	vec3 sky_color = mix(night_color.rgb, horizon_color.rgb, horizon);
	float cloud_cover = texture(fog_noise, UV * vec2(4.0, 3.0) + vec2(TIME * 0.007, 0.0)).r;
	sky_color = mix(sky_color, vec3(0.1, 0.14, 0.2), 0.2 + smoothstep(0.2, 0.8, cloud_cover) * 0.7);
	ALBEDO = sky_color + vec3(0.18, 0.21, 0.26) * lightning;
}
