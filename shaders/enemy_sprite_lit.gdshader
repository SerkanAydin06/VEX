shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_disabled;

uniform sampler2D albedo_texture : source_color, filter_linear_mipmap;
uniform float normal_strength : hint_range(0.0, 4.0) = 1.35;
uniform float cavity_strength : hint_range(0.0, 1.0) = 0.24;
uniform float edge_darkening : hint_range(0.0, 1.0) = 0.12;
uniform float roughness_value : hint_range(0.0, 1.0) = 0.72;
uniform float specular_value : hint_range(0.0, 1.0) = 0.34;
uniform float rim_strength : hint_range(0.0, 1.0) = 0.24;
uniform float rim_tint_value : hint_range(0.0, 1.0) = 0.65;
uniform float ambient_lift : hint_range(0.0, 1.0) = 0.08;
uniform float contrast : hint_range(0.0, 2.0) = 1.08;
uniform float saturation : hint_range(0.0, 2.0) = 1.02;
uniform float bright_emission_strength : hint_range(0.0, 1.0) = 0.0;
uniform float bright_emission_threshold : hint_range(0.0, 1.0) = 0.78;
uniform vec4 emission_tint : source_color = vec4(1.0, 0.82, 0.62, 1.0);

float luminance(vec3 color) {
	return dot(color, vec3(0.2126, 0.7152, 0.0722));
}

void vertex() {
	float sx = max(length(MODEL_MATRIX[0].xyz), 0.0001);
	float sy = max(length(MODEL_MATRIX[1].xyz), 0.0001);
	float sz = max(length(MODEL_MATRIX[2].xyz), 0.0001);
	vec3 camera_right = normalize(vec3(INV_VIEW_MATRIX[0].x, 0.0, INV_VIEW_MATRIX[0].z));
	vec3 world_up = vec3(0.0, 1.0, 0.0);
	vec3 camera_forward = normalize(cross(camera_right, world_up));
	mat4 billboard_model = mat4(
		vec4(camera_right * sx, 0.0),
		vec4(world_up * sy, 0.0),
		vec4(camera_forward * sz, 0.0),
		MODEL_MATRIX[3]
	);
	MODELVIEW_MATRIX = VIEW_MATRIX * billboard_model;
}

void fragment() {
	vec4 tex = texture(albedo_texture, UV);
	ALPHA = tex.a;
	ALPHA_SCISSOR_THRESHOLD = 0.025;

	vec2 texel = 1.0 / vec2(textureSize(albedo_texture, 0));
	vec4 left_tex = texture(albedo_texture, UV - vec2(texel.x, 0.0));
	vec4 right_tex = texture(albedo_texture, UV + vec2(texel.x, 0.0));
	vec4 up_tex = texture(albedo_texture, UV - vec2(0.0, texel.y));
	vec4 down_tex = texture(albedo_texture, UV + vec2(0.0, texel.y));

	float left_height = luminance(left_tex.rgb) * left_tex.a;
	float right_height = luminance(right_tex.rgb) * right_tex.a;
	float up_height = luminance(up_tex.rgb) * up_tex.a;
	float down_height = luminance(down_tex.rgb) * down_tex.a;
	vec2 gradient = vec2(left_height - right_height, up_height - down_height);
	vec3 fake_normal = normalize(vec3(gradient * normal_strength, 1.0));
	NORMAL_MAP = fake_normal * 0.5 + 0.5;
	NORMAL_MAP_DEPTH = 1.0;

	float base_luma = luminance(tex.rgb);
	float neighbor_luma = 0.25 * (
		luminance(left_tex.rgb) + luminance(right_tex.rgb)
		+ luminance(up_tex.rgb) + luminance(down_tex.rgb)
	);
	float cavity = clamp((neighbor_luma - base_luma) * 2.5 + 0.5, 0.0, 1.0);
	float alpha_edge = clamp(abs(left_tex.a - right_tex.a) + abs(up_tex.a - down_tex.a), 0.0, 1.0);

	vec3 color = tex.rgb;
	float gray = luminance(color);
	color = mix(vec3(gray), color, saturation);
	color = (color - vec3(0.5)) * contrast + vec3(0.5);
	color *= 1.0 - cavity_strength * cavity * 0.28;
	color *= 1.0 - edge_darkening * alpha_edge * 0.55;
	ALBEDO = max(color, vec3(0.0));

	ROUGHNESS = roughness_value;
	SPECULAR = specular_value;
	RIM = rim_strength;
	RIM_TINT = rim_tint_value;
	AO = clamp(1.0 - cavity_strength * cavity, 0.0, 1.0);
	AO_LIGHT_AFFECT = 0.18;

	float emission_mask = smoothstep(bright_emission_threshold, 1.0, base_luma) * tex.a;
	EMISSION = ALBEDO * ambient_lift + emission_tint.rgb * emission_mask * bright_emission_strength;
}
