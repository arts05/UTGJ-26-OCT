shader_type spatial;
render_mode unshaded, cull_back;

uniform sampler2D desktop_texture : source_color, filter_nearest, repeat_disable;
uniform bool effects_enabled = true;
uniform float border_pixels : hint_range(0.0, 80.0, 1.0) = 28.0;
uniform float brightness : hint_range(0.5, 1.5, 0.01) = 1.10;
uniform float scanline_strength : hint_range(0.0, 0.5, 0.01) = 0.18;
uniform float scanline_count : hint_range(120.0, 900.0, 1.0) = 450.0;
uniform float phosphor_strength : hint_range(0.0, 0.5, 0.01) = 0.18;
uniform float phosphor_columns : hint_range(80.0, 600.0, 1.0) = 300.0;
uniform float grain_strength : hint_range(0.0, 0.04, 0.001) = 0.006;
uniform float flicker_strength : hint_range(0.0, 0.04, 0.001) = 0.012;
uniform float vignette_strength : hint_range(0.0, 0.4, 0.01) = 0.24;
uniform float rolling_band_strength : hint_range(0.0, 0.3, 0.01) = 0.12;
uniform float rolling_band_speed : hint_range(0.0, 0.5, 0.01) = 0.08;
uniform float color_bleed_strength : hint_range(0.0, 0.4, 0.01) = 0.16;


float pattern_visibility(float cycles_per_pixel) {
	// Fade fine patterns at a distance to prevent moire and shimmer.
	return 1.0 - smoothstep(0.35, 0.5, cycles_per_pixel);
}


float sample_grain(vec2 pixel, float frame) {
	return fract(sin(dot(pixel, vec2(12.9898, 78.233)) + frame) * 43758.5453);
}


float phosphor_slot(vec2 cell, float center_x, float softness) {
	// A narrow vertical phosphor with rounded ends, separated by dark mask material.
	vec2 distance_from_center = abs(cell - vec2(center_x, 0.5));
	// Each mask cell is twice as tall as it is wide.
	vec2 rounded_end = vec2(distance_from_center.x, max(distance_from_center.y - 0.32, 0.0) * 2.0);
	return 1.0 - smoothstep(0.11 - softness, 0.11 + softness, length(rounded_end));
}


void fragment() {
	// Inset the whole desktop, leaving a thin unlit rim on the physically curved glass.
	vec2 desktop_size = vec2(textureSize(desktop_texture, 0));
	vec2 border = vec2(border_pixels) / desktop_size;
	vec2 desktop_uv = (UV - border) / (1.0 - border * 2.0);
	vec3 color = texture(desktop_texture, desktop_uv).rgb;
	vec2 distance_to_border = min(UV - border, 1.0 - border - UV);
	vec2 border_mask = smoothstep(vec2(0.0), fwidth(UV), distance_to_border);
	float row = UV.y * scanline_count;
	float visible_scanlines = pattern_visibility(fwidth(row));
	vec2 mask_position = UV * vec2(phosphor_columns, phosphor_columns * 0.375);
	float visible_phosphors = 1.0 - smoothstep(0.2, 0.4, fwidth(mask_position.x));
	float slot_softness = fwidth(mask_position.x) * 0.5;

	if (effects_enabled) {
		// A faint one-pixel color bleed, without displacing the desktop or its hitboxes.
		vec2 horizontal_pixel = vec2(1.0 / desktop_size.x, 0.0);
		vec3 separated_color = vec3(
			texture(desktop_texture, desktop_uv - horizontal_pixel).r,
			color.g,
			texture(desktop_texture, desktop_uv + horizontal_pixel).b
		);
		color = mix(color, separated_color, color_bleed_strength);

		float scanline = 0.5 + 0.5 * cos(row * TAU);
		color *= 1.0 - scanline * scanline_strength * visible_scanlines;

		// Offset neighboring columns so the gaps between slots don't form a square grid.
		mask_position.y += mod(floor(mask_position.x), 2.0) * 0.5;
		vec2 cell = fract(mask_position);
		vec3 phosphors = vec3(
			phosphor_slot(cell, 1.0 / 6.0, slot_softness),
			phosphor_slot(cell, 0.5, slot_softness),
			phosphor_slot(cell, 5.0 / 6.0, slot_softness)
		);
		color *= 1.0 - (1.0 - phosphors) * phosphor_strength * visible_phosphors;

		vec2 centered_uv = UV * 2.0 - 1.0;
		float edge_distance = dot(centered_uv, centered_uv) * 0.5;
		color *= 1.0 - vignette_strength * edge_distance;

		// A broad, slow band makes the refresh visible without shifting the picture.
		float band_distance = abs(fract(UV.y - TIME * rolling_band_speed + 0.5) - 0.5);
		float rolling_band = 1.0 - smoothstep(0.0, 0.12, band_distance);
		color *= 1.0 - rolling_band_strength * rolling_band;

		float flicker = 0.5 + 0.5 * sin(TIME * TAU * 9.0);
		color *= brightness * (1.0 - flicker_strength * flicker);

		vec2 pixel = floor(desktop_uv * desktop_size);
		float noise = sample_grain(pixel, floor(TIME * 24.0));
		color += (noise - 0.5) * grain_strength;
	}

	ALBEDO = clamp(color, vec3(0.0), vec3(1.0)) * border_mask.x * border_mask.y;
}
