// Shared by opaque room props and glass. All room lights are omni or spot lights.
uniform vec4 surface_color : source_color = vec4(1.0);
uniform sampler2D surface_texture : source_color, hint_default_white, filter_nearest;
uniform float surface_roughness : hint_range(0.0, 1.0) = 0.5;
uniform float surface_specular : hint_range(0.0, 1.0) = 0.5;
uniform vec4 glow_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float glow_strength : hint_range(0.0, 4.0) = 0.0;

void light() {
	// Excluding unused area-light shading avoids a very expensive WebGL compile
	// in Godot 4.7. Point/spot lighting and Godot's shadow attenuation still apply.
	if (!LIGHT_IS_AREA) {
		vec3 halfway = normalize(VIEW + LIGHT);
		float normal_light = max(dot(NORMAL, LIGHT), 0.0);
		float normal_view = max(dot(NORMAL, VIEW), 0.0001);
		float normal_halfway = max(dot(NORMAL, halfway), 0.0);
		float light_halfway = max(dot(LIGHT, halfway), 0.0);
		float view_fresnel = pow(1.0 - normal_view, 5.0);
		float light_fresnel = pow(1.0 - normal_light, 5.0);
		// Burley diffuse response, matching the original StandardMaterial3D props.
		float grazing_diffuse = 2.0 * light_halfway * light_halfway * ROUGHNESS - 0.5;
		float diffuse = (1.0 + grazing_diffuse * view_fresnel)
			* (1.0 + grazing_diffuse * light_fresnel) * normal_light / PI;
		DIFFUSE_LIGHT += diffuse * LIGHT_COLOR * ATTENUATION;

		// GGX highlights retain the original roughness and specular controls.
		float roughness_squared = max(ROUGHNESS * ROUGHNESS, 0.0001);
		float distribution_denominator = 1.0 + normal_halfway * normal_halfway
			* (roughness_squared * roughness_squared - 1.0);
		float distribution = roughness_squared / distribution_denominator;
		distribution = distribution * distribution / PI;
		float visibility = 0.5 / mix(2.0 * normal_light * normal_view,
			normal_light + normal_view, roughness_squared);
		float reflectance = 0.16 * surface_specular * surface_specular;
		float fresnel = reflectance + (clamp(50.0 * reflectance, 0.0, 1.0) - reflectance)
			* pow(1.0 - light_halfway, 5.0);
		SPECULAR_LIGHT += normal_light * distribution * visibility * fresnel
			* LIGHT_COLOR * ATTENUATION * SPECULAR_AMOUNT;
	}
}
