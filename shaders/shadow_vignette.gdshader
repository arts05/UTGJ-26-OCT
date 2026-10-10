shader_type canvas_item;
render_mode unshaded;

uniform sampler2D room_texture : hint_screen_texture, repeat_disable, filter_nearest;
uniform sampler2D shadow_noise : repeat_enable, filter_linear;
uniform float edge_darkness : hint_range(0.0, 0.5) = 0.18;
uniform float moving_shadow_strength : hint_range(0.0, 0.2) = 0.04;
uniform vec2 drift = vec2(0.006, -0.003);

void fragment() {
	vec3 room = textureLod(room_texture, SCREEN_UV, 0.0).rgb;
	float brightness = dot(room, vec3(0.2126, 0.7152, 0.0722));
	float shadow_mask = 1.0 - smoothstep(0.025, 0.16, brightness);
	float edge = smoothstep(0.45, 1.25, length((SCREEN_UV - 0.5) * 2.0));
	float moving_shadow = texture(shadow_noise, SCREEN_UV * vec2(1.6, 1.0) + TIME * drift).r;
	float darkness = edge * shadow_mask * (edge_darkness + moving_shadow * moving_shadow_strength);

	// Only deepen existing shadows: black stays black, and bright screen content stays clear.
	COLOR = vec4(room * (1.0 - darkness), 1.0);
}
